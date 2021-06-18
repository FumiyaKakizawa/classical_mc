using HDF5
using PyPlot

h5file_name = "2d_out.h5"
J2 = -0.01
L = 36

function load_from_h5file(h5file_name)
    
    fid = h5open(h5file_name,"r")
    ene_hist = fid["energy_histogram/mean"][:,:]
    num_temps = length(fid["temperatures"][:])
    ene_hist, num_temps
end

ene_hist,num_temps = load_from_h5file(h5file_name)

function mk_hist(ene_hist,num_temps,J2_val,L_val)
    
    for it in 1:num_temps
        plt.figure()
        plt.xlabel("Energy")
        plt.ylabel("count of appearance")
        plt.title("Energy histogram at J2=$(J2_val),L=$(L_val)")
        plt.hist(ene_hist[:,it])
        plt.savefig("ene_hist_$(it)")
        plt.close()
    end
end

mk_hist(ene_hist,num_temps,J2,L)
