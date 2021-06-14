num_insert  = 10
start_temps = 2e-2
end_temps   = 3e-2
input_file  = "temperatures.txt"
output_file = input_file

# Read a list of temperatures
function read_temps(temperature_file::String)
    temps = Vector{Float64}(undef, 0)
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


<<<<<<< HEAD
function insert_temps(temperatures,num_insert,start_temps,end_temps,input_file,output_file)
    
    original_temps = temperatures
    insert_temps = LinRange(start_temps,end_temps,num_insert)
    
    target_temps = union(original_temps, insert_temps)
=======
function insert_temps(temperatures,num_insert,start_temps,end_temps)
    insert_temps = LinRange(start_temps,end_temps,num_insert)
    target_temps = union(temperatures, insert_temps)
>>>>>>> ac82c1c9494af084fc652f36a0a5559b344624b9
    sort!(target_temps)
    target_temps
end


function write_temperatures(temperatures,output_file)
    num_temps = length(temperatures)
    open(output_file,"w") do fp
        println(fp,num_temps)
        for it in 1:num_temps
            println(fp," ",temperatures[it])
        end
    end
end

<<<<<<< HEAD
temperatures = read_temps(input_file)
insert_temps(num_insert,start_temps,end_temps,input_file,output_file)
=======

temperatures = read_temps(input_file)
temperatures = insert_temps(temperatures,num_insert,start_temps,end_temps)
write_temperatures(temperatures,output_file)
>>>>>>> ac82c1c9494af084fc652f36a0a5559b344624b9
