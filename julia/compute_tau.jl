using HDF5
using PyPlot
using LsqFit

h5file = "2d_out.h5"
names = ["mq_sqrt3_corr", "mq_q0_corr", "afvc_corr", "fvc_corr","m_120degs_corr"]


function out_to_txt(h5file,names)
    fid = h5open(h5file,"r")
    temps = fid["temperatures"]
    num_temps = length(temps)
    for iname in names
        data = fid["$(iname)/mean"]
        name = split(iname,"_corr")[1]
        mc_steps = length(data[:,1])
        for it in 1:num_temps
            open("$(name)_$(it).dat","w") do fp
                for i in 1:mc_steps
                    println(fp,i," ",data[:,it][i])
                end
            end
        end
    end
    close(fid)
end
out_to_txt(h5file,names)


#=
function save_plot_corr(h5file,names)

    fid = h5open(h5file,"r")
    temps = fid["temperatures"]
    num_temps = length(temps)

    for name in names
        data = fid["$(name)/mean"]
        name = split(name,"_corr")[1]
        plt.figure()
        for it in 1:num_temps
            plt.plot(data[:,it],label="T=$(temps[it])")
        end
        plt.title("correlation function of $(name)")
        plt.xlabel("MC step")
        plt.ylabel("$(name)")
        plt.yscale("log")
        plt.legend(loc="upper right")
        savefig("$(name)")
    end
    close(fid)

end
#save_plot_corr("2d_out.h5",names)
=#


function compute_τ(tdatas,ydatas,p0)
    model(t,p) = p[1] .- (1/p[2])*t
    fit = curve_fit(model, tdatas, ydatas, p0)
    fit.param[2]
end


function compute_τ2(tdatas,ydatas,p0)
    model(t,p) = p[1]*exp.((-1/p[2])*t)
    fit = curve_fit(model, tdatas, ydatas, p0)
    fit.param[2]
end


function get_τs(h5file,names,p0,min_temp,max_temp,begin_idx,end_idx)
    fid = h5open(h5file,"r")
    temps = fid["temperatures"]
    num_temps = length(temps)
    @assert 1 <= min_temp <= max_temp <= num_temps
    τs = Dict()
    for iname in names
        data = fid["$(iname)/mean"]
        name = split(iname,"_corr")[1]
        mc_steps = length(data[:,1])
        time = [i for i in 1:mc_steps]
        τs[name] = Vector{Float64}(undef,num_temps)
        for it in min_temp:max_temp
            #data_log = log.(data[:,it][begin_idx:end_idx])
            data_raw = data[:,it][begin_idx:end_idx]
            #τs[name][it] = compute_τ(time[begin_idx:end_idx],data_log,p0)
            τs[name][it] = compute_τ2(time[begin_idx:end_idx],data_raw,p0)
        end
    end
    #close(fid)
    τs, temps
end
p0         = [1.0,1.0]
min_temp   = 0.5
max_temp   = 1.0
begin__idx = 10^1
end_idx    = 10^2
τs,temperatures = get_τs(h5file,names,p0,begin_idx,end_idx)
println("τs = $(τs)")


function out_to_txt(τs,temperatures)
    for key in keys(τs)
        open("tau_$(key).dat","w") do fp
            for it in 1:length(temperatures)
                println(fp,temperatures[it]," ",τs[key][it])
            end
        end
    end
end
out_to_txt(τs,temperatures)

#=
[HERE] 21.1.5
=#

function compute_Tc(tdatas,ydatas,p0)
    model(t,p) = p[1] .+ p[2] ./ sqrt.(t .- p[3])
    fit = curve_fit(model,tdatas,log.(ydatas),p0)
    fit.param[3]
end


function compute_Tc2(tdatas,ydatas,p0)
    model(t,p) = p[1]*exp.(p[2] ./ sqrt.(t .- p[3]))
    fit = curve_fit(model,tdatas,ydatas,p0)
    fit.param[3]
end


function get_Tc(temps,τs,p0)
    num_temps = length(temps)
    Tcs = Dict()
    println("DEBUG C: $(typeof(temps))")
    println("DEBUG D: $(typeof(temps[:]))")
    println("DEBUG E: $(num_temps)")
    for key in keys(τs)
        @assert length(τs[key]) == num_temps
        #Tcs[key] = 0.0
        println("DEBUG A: $(key) = $(τs[key])")
        println("DEBUG B: $(key) = $(typeof(τs[key]))")
        Tcs[key] = compute_Tc(temps[:],τs[key],p0)
    end
    Tcs
end
#=
a = 0.9
p0 = a * [1.0,1.0,1.0]
Tcs = get_Tc(temperatures,τs,p0)
println("Tcs = $(Tcs)")

function out_to_txt(Tcs)
    for key in keys(Tcs)
        open("Tc_$(key).dat","w") do fp
            println(fp,Tcs[key])
        end
    end
end
out_to_txt(Tcs)
=#


