using PyPlot,LinearAlgebra

temperature_idx = 1
L = 3
num_s = 3*L^2
kagome_file = "kagome.txt"
spin_config_file = "spin_config_$(temperature_idx).txt"

function load_from_file(file,num_s)
    s = fill((0.,0.,0.),num_s)
    open(file,"r") do fp
        @assert num_s == parse(Int64, readline(fp))
        for i in 1:num_s
            str = split(readline(fp))
            sx = parse(Float64, str[1])
            sy = parse(Float64, str[2])
            sz = parse(Float64, str[3])
            s[i] = (sx,sy,sz)
        end
    end
    return s
end

kagome = load_from_file(kagome_file,num_s)
site_pos = [kagome[i] ./ 2 for i in 1:num_s]

# a1 and a2 are lattice vectors.
function site_to_coord(kagome,a1,a2)
    num_sites = length(kagome)
    sites = kagome
    coord = fill((0.,0.,0.),num_sites)
    for isite in 1:num_sites
        coord[isite] = kagome[isite][1].* a1 .+ kagome[isite][2].* a2
    end
    return coord
end

a1 = (1.0,0.0,0.0)
a2 = (-1/2,sqrt(3)/2,0.0)
kagome_coord = site_to_coord(site_pos,a1,a2)

function plot_spin_config(kagome,spins,temperature_idx)
    c = "red"
    lw = 0.5
    ls = :dash

    num_sites = length(kagome)
    @assert length(spins) == num_sites
    site_x = [kagome[i][1] for i in 1:num_sites]
    site_y = [kagome[i][2] for i in 1:num_sites]
    spin_x = [spins[i][1]  for i in 1:num_sites]
    spin_y = [spins[i][2]  for i in 1:num_sites]

    plt.figure()
    plt.axes().set_aspect("equal")
    #Plot spin config on a kagome lattice as a vector field.
    plt.quiver(site_x,site_y,spin_x,spin_y,pivot=:middle)

    for i in 1:length(site_x),j in 1:length(site_x)
        if i < j && abs(0.5-norm(kagome[i].-kagome[j])) < 1e-2
            plt.plot([site_x[i],site_x[j]],[site_y[i],site_y[j]],color=c)
        end
    end

    plt.savefig("spin_config_$(temperature_idx)")
end

spin_config = load_from_file(spin_config_file,num_s)
plot_spin_config(kagome_coord,spin_config,temperature_idx)
