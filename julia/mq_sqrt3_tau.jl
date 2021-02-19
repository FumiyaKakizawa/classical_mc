using HDF5
using PyPlot
using LsqFit

h5file       = "2d_out.h5"
fid          = h5open(h5file,"r")
temperatures = fid["temperatures"][:]
obs_name     = "mq_sqrt3_corr"


function out_to_txt(h5file,name)
    fid = h5open(h5file,"r")
    temps = fid["temperatures"][:]
    num_temps = length(temps)
    data = fid["$(name)/mean"]
    name = split(name,"_corr")[1]
    mc_steps = length(data[:,1])
    for it in 1:num_temps
        open("$(name)_$(it).dat","w") do fp
            for i in 1:mc_steps
                println(fp,i," ",data[:,it][i])
            end
        end
    end
    close(fid)
end
out_to_txt(h5file,obs_name)

#[HERE:21.1.21]

function compute_τ(tdatas,ydatas,p0)
    model(t,p) = p[1] .- (1/p[2])*t
    fit = curve_fit(model, tdatas, ydatas, p0)
    fit.param
end

function compute_τ2(tdatas,ydatas,p0)
    model(t,p) = p[1]*exp.((-1/p[2])*t)
    fit = curve_fit(model, tdatas, ydatas, p0)
    fit.param
end


function get_τ_w_fitcurve(h5file,name,min_temp,max_temp,p0,idx_arrays)
    fid = h5open(h5file,"r")
    temps = fid["temperatures"][:]
    num_temps = length(temps)
    @assert 1 <= min_temp <= max_temp <= num_temps
    @assert length(idx_arrays) == max_temp-min_temp+1
    data = fid["$(name)/mean"]
    max_time = length(data[:,1])
    full_time  = [i for i in 1:max_time]

    model(t,p) = p[1]*exp.((-1/p[2])*t)
    fitcurve   = Array{Float64}(undef,max_time,num_temps)
    params     = Array{Float64}(undef,2,num_temps)
    for it in min_temp:max_temp
        begin_idx,end_idx = idx_arrays[it-min_temp+1]
        @assert 1 <= begin_idx <= end_idx <= max_time
        
        times = full_time[begin_idx:end_idx]
        #data_log = log.(data[:,it][begin_idx:end_idx])
        #τs[name][it] = compute_τ(time[begin_idx:end_idx],data_log,p0)

        data_raw = data[:,it][begin_idx:end_idx]
        params[:,it] = collect(compute_τ2(times,data_raw,p0))
        fitcurve[begin_idx:end_idx,it] = model(times,params[:,it])

    end
    params,fitcurve
end
min_temp   = 13
#min_temp   = 17
max_temp   = 21
p0         = [1.0,10.0]
idx_arrays = [(30,60),(30,60),(30,60),(30,60),(30,60),(25,45),(20,40),(20,35),(20,30)]
#idx_arrays = [(10,50),(10,40),(10,30),(10,30),(10,30)]

params,fitcurve = get_τ_w_fitcurve(h5file,obs_name,min_temp,max_temp,p0,idx_arrays)
τ = params[2,:]

function out_to_txt(fid,name,fitcurve,min_temp,max_temp,idx_arrays)
    temps = fid["temperatures"][:]
    num_temps = length(temps)
    @assert 1 <= min_temp <= max_temp <= num_temps
    data = fid["$(name)/mean"]
    name = split(name,"_corr")[1]
    mc_steps = length(data[:,1])
    for it in min_temp:max_temp
        begin_idx,end_idx = idx_arrays[it-min_temp+1]
        open("$(name)_w_fc_$(it).dat","w") do fp
            for i in begin_idx:end_idx
                println(fp,i," ",data[:,it][i]," ",fitcurve[:,it][i])
            end
        end
    end
    close(fid)
end
out_to_txt(fid,obs_name,fitcurve,min_temp,max_temp,idx_arrays)

function out_to_txt(output_file,τ,temperatures,min_temp,max_temp)
    open(output_file,"w") do fp
         for it in min_temp:max_temp
             println(fp,temperatures[it]," ",τ[it])
         end
    end
end
name   = split(obs_name,"_corr")[1]
o_file = "$(name)_tau.dat"
out_to_txt(o_file,τ,temperatures,min_temp,max_temp)

#=
function get_Tc(temperaures,τs,min_temp,max_temp,p1)
    model(t,p) = p[1]*(t .- p[3]).^(p[2])
    #model(t,p) = p[1] .- p[2]*log.((t .+ p[3]))
    T = temperatures[min_temp:max_temp]
    τ = τs[min_temp:max_temp]
    fit = curve_fit(model,T,τ,p1)
    #fit = curve_fit(model,T,log.(τ),p1)
    fit.param
end
p1 = [0.1,0.1,0.01]
Tc_params = get_Tc(temperatures,τ,min_temp,max_temp,p1)
println("DEBUG:params=$(Tc_params)")
println("DEBUG:Tc=$(Tc_params[3])")

function out_to_txt(ofile,temperatures,τ,params)
    model(t,p) = p[1]*(t .- p[3]).^(p[2])
    println("DEBUG:T=$(temperatures[min_temp:max_temp])")
    println("DEBUG B:fitcurve=$(model(temperatures[min_temp:max_temp],params))")
    fitcurve = model(temperatures[min_temp:max_temp],params)
    open(ofile,"w") do fp
        for it in min_temp:max_temp
            println(fp,temperatures[it]," ",τ[it]," ",fitcurve[it-min_temp+1])
        end
    end

end

ofile = "$(name)_tau_w_fc.dat"
out_to_txt(ofile,temperatures,τ,Tc_params)
=#
