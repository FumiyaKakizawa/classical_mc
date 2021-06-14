using HDF5
using PyPlot

h5file_name = "2d_out.h5"

function load_from_h5file(h5file_name)
    
    fid = h5open(h5file_name,"r")
    ene_hist = fid["energy_histogram/mean"][:,:]
    num_temps = length(fid["temperatures"][:])
    ene_hist, num_temps
end

ene_hist,num_temps = load_from_h5file(h5file_name)

function mk_hist(ene_hist,num_temps)
    
    for it in 1:num_temps
        plt.figure()
        plt.hist(ene_hist[:,it])
        plt.savefig("ene_hist_$(it)")
    end
end

mk_hist(ene_hist,num_temps)
