
using LinearAlgebra
using PyPlot


function read_file(file::String)
    s = Vector{Tuple{Float64,Float64,Float64}}(undef,0)
    open(file,"r") do fp
        num_s = parse(Int64,readline(fp))
        for _ in 1:num_s
            str = split(readline(fp))
            idx = parse(Int64,str[1])
            x   = parse(Float64,str[2])
            y   = parse(Float64,str[3])
            z   = parse(Float64,str[4])
            push!(s,(x,y,z))
        end
    end
    s
end

kagome = read_file("kagome.txt")
#println(kagome)
spins_1  = read_file("spin_config_1.txt")
#println(spins_1)

function test(s,test_file)
    num_s = length(s)
    open(test_file,"w") do fp
        println(fp,num_s)
        for i in 1:num_s
            println(fp,i," ",s[i][1]," ",s[i][2]," ",s[i][3])
        end
    end
end

#test(spins_1,"test_spin_config_1.txt")

function site_to_coord(kagome,a1,a2)

    #(Float64,Float64,Float64)->(Int64,Int64,Int64)
    num_sites = length(kagome)
    sites = Vector{Tuple{Int64,Int64,Int64}}(undef,num_sites)
    for is in 1:num_sites
        sites[is] = Int.(kagome[is])
    end
    
    coord = Vector{Tuple{Float64,Float64,Float64}}(undef,num_sites)
    for is in 1:num_sites
        temp = sites[is][1].*a1 .+ sites[is].*a2
        push!(coord,temp)
    end
    #println(coord)
    coord
end

a1 = (1.0,0.0,0.0)
a2 = (-1/2,sqrt(3)/2,0.0)
kagome = site_to_coord(kagome,a1,a2)
#test(kagome,"test_kagome.txt") #temporary test

function plot_spin_direction(kagome,spins)
    c = "red"
    lw = 0.5
    ls = :dash
    
    num_sites = length(kagome)
    @assert length(spins) == num_sites
    site_x = [kagome[i][1] for i in 1:num_sites]
    site_y = [kagome[i][2] for i in 1:num_sites]
    spin_x = [spins[i][2]  for i in 1:num_sites]
    spin_y = [spins[i][2]  for i in 1:num_sites]
    
    PyPlot.quiver(site_x,site_y,spin_x,spin_y,pivot=:middle)
    
    for i in 1:length(lattx)
        for j in 1:length(latty)
            if i < j && abs(1-norm(lattice[i].-lattice[j])) < 1e-5
            
                PyPlot.plot([lattx[i],lattx[j]],[latty[i],latty[j]],color=c)
                
            end
        end
    end
    
end
#=
# pull numerical date from h5 file.

fp = h5open("L9.h5","r") 
gp = read(fp,"spin_config")

num_spins = gp["num_spins"]
L = Int(sqrt(num_spins/3))

temp = gp["temp"]

sx = gp["sx"]
sy = gp["sy"]
sz = gp["sz"]

kagome = mk_stacked_structure(L,num_stack,lat_vec1,lat_vec2,lat_vec3,num_spins)
plot_spin_direction(kagome,sx,sy,num_spins)
PyPlot.title("spin configuration at $(L"T=0.001") and $(L"J_2=0.005")")

savefig("spin_config")

close(fp)
=#
