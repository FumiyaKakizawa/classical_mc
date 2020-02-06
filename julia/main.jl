using Random
using ConfParser
using ArgParse
using MPI
using Test
using CPUTime
using HDF5

include("mcmc.jl")
include("accumulator.jl")
include("replica_exchange.jl")

# Read a list of temperatures
function read_temps(temperature_file::String)
    temps = Array{Float64}(undef, 0)
    num_temps = 0
    open(temperature_file) do file
        num_temps = parse(Int64, readline(file))
        for l in 1:num_temps
            temp = parse(Float64, readline(file))
            push!(temps, temp)
        end
    end

    # Check if temperatures are in ascending order or descending order
    if !all(temps[1:num_temps-1] .< temps[2:num_temps]) && !all(temps[1:num_temps-1] .> temps[2:num_temps])
        error("Temperatures must be given either in ascending order or in descending order!")
    end

    return temps
end

# Distribute temperature over MPI processes
function distribute_temps(rank, num_temps, num_proc)
    num_temps_local = fill(trunc(Int, num_temps/num_proc), (num_proc,))
    left_over = mod(num_temps, num_proc)
    num_temps_local[1:left_over] .+= 1
    @test sum(num_temps_local) == num_temps
    start_idx = sum(num_temps_local[1:rank]) + 1
    end_idx = start_idx + num_temps_local[rank+1] - 1

    return start_idx, end_idx
end

# Read non-zero elements in the right-upper triangle part of Jij
function read_Jij(Jij_file::String, num_spins)
    Jij = Array{Tuple{SpinIndex,SpinIndex,Float64,Float64,Float64}}(undef, 0)
    open(Jij_file, "r" ) do fp
        num_Jij_elems = parse(Int64, readline(fp))
        for i in 1:num_Jij_elems
            str = split(readline(fp))
            i = parse(SpinIndex, str[1])
            j = parse(SpinIndex, str[2])
            val_x = parse(Float64, str[3])
            val_y = parse(Float64, str[4])
            val_z = parse(Float64, str[5])
            if i >= j
                error("Only right-upper triangle part must be given.")
            end
            if i > num_spins || i < 0  || j > num_spins || j < 0
                error("i or j is out of the range [1, num_spins].")
            end
            push!(Jij, (i, j, val_x, val_y, val_z))
        end
    end
    return Jij
end

function compute_magnetization(acc::Accumulator,num_spins::Int64,spins::Array{Array{Tuple{Float64,Float64,Float64},1},1},num_temps::Int64)
    
    mx = zeros(Float64, num_temps)
    my = zeros(Float64, num_temps)
    mz = zeros(Float64, num_temps)
    m2 = zeros(Float64, num_temps)

    for i in 1:num_temps
      temp_mx = 0.0    
      temp_my = 0.0    
      temp_mz = 0.0    
      for j in 1:num_spins
        temp_mx += spins[i][j][1]
        temp_my += spins[i][j][2]
        temp_mz += spins[i][j][3]
      end
      mx[i] = temp_mx
      my[i] = temp_my
      mz[i] = temp_mz
      m2[i] = float(mx[i]^2 + my[i]^2+ mz[i]^2)
    end
    
    add!(acc, "Mx2",mx.^2)    
    add!(acc, "My2",my.^2)    
    add!(acc, "Mz2",mz.^2)
    #add!(acc, "M2", m2)
    #add!(acc, "M4", m2.^2)
   
 
end

function latest_spin_direction(acc::Accumulator,spins::Array{Array{Tuple{Float64,Float64,Float64},1},1},num_spins::Int64,num_temps::Int64)
    
    spins_x = [[spins[i][j][1] for j in 1:num_spins] for i in 1:num_temps]
    spins_y = [[spins[i][j][2] for j in 1:num_spins] for i in 1:num_temps]
    spins_z = [[spins[i][j][3] for j in 1:num_spins] for i in 1:num_temps]
    """    
    @assert begin
        for it in 1:num_temps
            for spin in 1:num_spins
                temp = spins_x[it][spins]^2 + spins_y[it][spins]^2 + spins_z[it][spins]^2
                abs(1-temp) < 1e-2
            end
        end
    end         
    """ 
    add!(acc, "sx", spins_x) 
    add!(acc, "sy", spins_y)
    add!(acc, "sz", spins_z)
    
end

function make_kagome(num_spins)
    a1 = 2 .* (1.,0.)
    a2 = 2 .* (cos(pi/3),sin(pi/3))

    L = Int(sqrt(num_spins/3))
    unit_cell_position = fill((0.,0.),L^2)
    index = 1

    # complexity O(L^2~N)
    for (i,j) in Iterators.product(1:L,1:L)

        unit_cell_position[index] = (i-1) .* a1 .+ (j-1) .* a2 
        index += 1
    end 
    
    return unit_cell_position
end

function order_parameter(spins::Array{Array{Tuple{Float64,Float64,Float64},1},1},num_spins::Int64,num_temps::Int64,q::Tuple{Float64,Float64})
    
    unit_cell = make_kagome(num_spins) 

    M2_AF = zeros(num_temps) 

    for temp in 1:num_temps
        gp1 = spins[temp][1:3:num_spins] 
        gp2 = spins[temp][2:3:num_spins] 
        gp3 = spins[temp][3:3:num_spins] 
        

        within_unit_cell = (0.,0.,0.)

        for i in 1:Int(num_spins/3)

            phase_iqr = -im*dot(q,unit_cell[i])
            within_unit_cell = within_unit_cell .+ (gp1[i] .+ gp2[i] .+ gp3[i]) .* exp(phase_iqr) 
        end

        M2_AF[temp] = norm(within_unit_cell)^2
    end
    
    return M2_AF
end

function octopolar_orderparameter(spins::Array{Array{Tuple{Float64,Float64,Float64},1},1},num_spins::Int64,num_temps::Int64)
    
    op = zeros(num_temps)
    
    for temp in 1:num_temps
        
        total_vec = (0.,0.,0.)
        for i in 1:num_spins
            total_vec = total_vec .+ spins[temp][i]
        end

        op[temp] = dot(total_vec,total_vec)^3 - (3/5)dot(total_vec,total_vec) 
    end
    
    return op
end

function solve(input_file::String, comm)
    if !isfile(input_file)
        error("$input_file does not exists!")
    end
    conf = ConfParse(input_file)
    parse_conf!(conf)

    rank = MPI.Comm_rank(comm)
    num_proc = MPI.Comm_size(comm)

    num_spins = parse(Int64, retrieve(conf, "model", "num_spins"))
    Jij_file = retrieve(conf, "model", "Jij")
    temperature_file = retrieve(conf, "model", "temperatures")

    num_sweeps = parse(Int64, retrieve(conf, "simulation", "num_sweeps"))
    num_therm_sweeps = parse(Int64, retrieve(conf, "simulation", "num_therm_sweeps"))
    meas_interval = parse(Int64, retrieve(conf, "simulation", "meas_interval"))
    ex_interval = parse(Int64, retrieve(conf, "simulation", "ex_interval"))
    seed = parse(Int64, retrieve(conf, "simulation", "seed"))

    # Read a list of temperatures
    temps = read_temps(temperature_file)
    num_temps = length(temps)
    if num_temps < num_proc
        error("Number of processes > num_temps")
    end
    if rank == 0
       println("num of temperatures = ", num_temps)
    end

    # Decide which temperatures are computed on this process
    start_idx, end_idx = distribute_temps(rank, num_temps, num_proc)
    num_temps_local = end_idx - start_idx + 1

    # Read non-zero elements in the right-upper triangle part of Jij
    Jij = read_Jij(Jij_file, num_spins)

    # Create single-spin flip updater
    model = JModel(num_spins, Jij)
    updater = SingleSpinFlipUpdater(model)

    # Init random number generator
    Random.seed!(seed + rank)

    # Create accumulator
    acc = Accumulator(num_temps_local)

    # Create accumulator for collecting stat for every process
    acc_proc = Accumulator(1)

    # Init spins
    spins_local  = [fill((0.,0.,1.),num_spins) for it in 1:num_temps_local]
    energy_local = [compute_energy(model, spins_local[it]) for it in 1:num_temps_local]

    # Replica exchange
    rex = ReplicaExchange(temps, start_idx, end_idx)

    # Perform MC
    last_output_time = time_ns()
    if rank == 0
        println("Starting simulation...")
    end
    for sweep in 1:num_sweeps
        # Output roughtly every 10 sececonds
        if rank == 0 && time_ns() - last_output_time > 1e+10
            println("Done $sweep sweeps")
            last_output_time = time_ns()
            flush(stdout)
        end

        elpsCPUtime = []
 
        # Single spin flips
        ts_start = CPUtime_us()
        
        for it in 1:num_temps_local
            energy_local[it] += one_sweep(updater, 1/temps[it+start_idx-1], model, spins_local[it])
        end
        #println("one_sweep", " ",ts_end - ts_start)
        push!(elpsCPUtime, CPUtime_us() - ts_start)

        # Check if energy is correct
        if mod(sweep, 100) == 0
            energy_local = [compute_energy(model, spins_local[it]) for it in 1:num_temps_local]
            for it in 1:num_temps_local
                @assert abs(energy_local[it] - compute_energy(model, spins_local[it])) < 1e-5
            end
        end
        
        # Replica exchange
        ts_start = CPUtime_us()
        if mod(sweep, ex_interval) == 0
            perform!(rex, spins_local, energy_local, comm)
        end
        push!(elpsCPUtime, CPUtime_us() - ts_start)

        # Measurement
        ts_start = CPUtime_us()
        if sweep >= num_therm_sweeps && mod(sweep, meas_interval) == 0
            add!(acc, "E", energy_local)
            add!(acc, "E2", energy_local.^2)

            ss= Array{Array{ComplexF64}}(undef, num_temps_local)
            num_q = 2
            for it in 1:num_temps_local
                ss[it] = (it + 100*rank) * ones(Float64, num_q)
            end
            add!(acc, "ss", ss)
   
            #compute_magnetization(acc, num_spins, spins_local, num_temps_local)
            add!(acc,"M2_AF",order_parameter(spins_local,num_spins,num_temps_local,(0.,0.)))
            add!(acc,"op",octopolar_orderparameter(spins_local,num_spins,num_temps_local))
  
        end
        push!(elpsCPUtime, CPUtime_us() - ts_start)

        # How long does it take to execute one sweep or replica exchange, measuremnt?
        if sweep > num_therm_sweeps
            add!(acc_proc, "CPUtime", [Array{Float64}(elpsCPUtime)])
        end
    end        
    
    latest_spin_direction(acc,spins_local,num_spins,num_temps_local)


    # Output results
    E = mean_gather(acc, "E", comm)
    E2 = mean_gather(acc, "E2", comm)
    ss = mean_gather_array(acc, "ss", comm)
    #Mz2 = mean_gather(acc, "Mz2", comm)
    #M2 = mean_gather(acc, "M2", comm)
    #M4 = mean_gather(acc, "M4", comm)
    CPUtime = mean_gather_array(acc_proc, "CPUtime", comm)
    #sx = mean_gather_array(acc, "sx", comm)
    #sy = mean_gather_array(acc, "sy", comm)
    #sz = mean_gather_array(acc, "sz", comm)
    #M1 = mean_gather_array(acc, "M1", comm)
    #M2 = mean_gather_array(acc, "M2", comm)
    #M3 = mean_gather_array(acc, "M3", comm)
    op = mean_gather(acc, "op", comm)
    M2_AF = mean_gather(acc,"M2_AF",comm)
    if rank == 0
        for it in 1:num_temps
            println(it, " ", ss[it])
        end
        println("<E> ", E)
        println("<E^2> ", E2)
        for i in 1:num_temps
            println(temps[i], "  ", ((E2[i]  - E[i]^2) / (temps[i]^2)) / num_spins)
        end

        println("octopolar: ",op/num_spins^2)
        """
        open("g.dat", "w") do fp
            for i in 1:num_temps
                g = (3 - (M4[i]/(M2[i]^2))) / 2
                println(fp, temps[i], " ", g)
            end
        end
        """  
        println("<CPUtime> ")
        for (i, t) in enumerate(CPUtime)
            println(" rank=", i-1, " : $t")
        end
        
        println("M2_AF: ",M2_AF)    
        h5open("L12.h5","w") do fp
            write(fp,"num_spins",num_spins)
            write(fp,"temps"    ,temps    )
            write(fp,"E"        ,E        )
            write(fp,"E2"       ,E2       )
            write(fp,"op"       ,op      )
            write(fp,"M2_AF"       ,M2_AF      )
             
            """
            write(fp,"M1"       ,M1       ) 
            write(fp,"M2"       ,M2       ) 
            write(fp,"M3"       ,M3       ) 
            write(fp,"op"       ,op/(num_spins^2))
            grp = g_create(fp,"spin_config")            
            grp["num_spins"] = num_spins
            grp["temp"] = temps[1]
            grp["sx"] = sx[1]            
            grp["sy"] = sy[1]            
            grp["sz"] = sz[1]            
            """
        end

    end

    # Stat of Replica Exchange MC
    print_stat(rex)

end

s = ArgParseSettings()
@add_arg_table s begin
    "input"
        help = "input file"
        required = true
end
args = parse_args(ARGS, s)

# Initialize MPI environment
MPI.Init()
comm = MPI.COMM_WORLD

@time solve(args["input"], comm)
