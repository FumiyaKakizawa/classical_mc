using HDF5

obs_name1 = "mq_sqrt3_corr"
obs_name2 = "afvc_corr"
L = 900
num_temps  = 21
num_sample = 4
num_sweeps = 20000
interval_meas = 10
num_meas = num_sweeps ÷ interval_meas + 1

function ave(name,L,num_temps,num_sample,num_meas)

    total = zeros(Float64,num_meas,num_temps)
    for isample in 1:num_sample
        h5file = "L$(L)_$(isample)/2d_out.h5"
        fid = h5open(h5file,"r")
        @assert length(fid["temperatures"][:]) == num_temps
        obs = fid["$(name)/mean"]
        @assert size(obs) == (num_meas,num_temps)
        for it in 1:num_temps
            total[:,it] .+= obs[:,it]
        end
    end
    total ./= num_sample
end

function out_to_txt(name,ave,num_temps,num_meas)

    for it in 1:num_temps
        open("$(name)_$(it)_ave.dat","w") do fp
            for i in 1:num_meas
                println(fp,i," ",ave[i,it])
            end
        end
    end

end

ave1   = ave(obs_name1,L,num_temps,num_sample,num_meas)
name1 = split(obs_name1,"_corr")[1]
out_to_txt(name1,ave1,num_temps,num_meas)






