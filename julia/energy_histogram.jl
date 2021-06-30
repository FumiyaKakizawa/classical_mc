using HDF5,PyPlot,PyCall
np = pyimport("numpy")


h5file_name = "2d_out.h5"
J1     = -1.0
J2     = -0.0075
L      = 36
n_bins = 100

function load_from_h5file(h5file_name)
    
    fid = h5open(h5file_name,"r")
    ene_hist = fid["energy_histogram/mean"][:,:]
    num_temps = length(fid["temperatures"][:])
    ene_hist, num_temps
end

ene_hist,num_temps = load_from_h5file(h5file_name)

function mk_hist_pic(ene_hist,num_temps,J2_val,L_val,n_bins)
    
    for it in 1:num_temps
        plt.figure()
        plt.xlabel("Energy")
        plt.ylabel("count of appearance")
        plt.title("Energy histogram at J2=$(J2_val),L=$(L_val)")
        plt.hist(ene_hist[:,it]/(3L_val^2),bins=n_bins)
        plt.savefig("ene_hist_$(it)")
        plt.close()
    end
end

mk_hist_pic(ene_hist,num_temps,J2,L,n_bins)

function mk_hist_txt(ene_hist,num_temps,J2,L,n_bins)

   for i in 1:num_temps
       ith_ene_hist = np.histogram(ene_hist[:,i]/(3L^2), bins=n_bins)
       open("ene_hist_$(i).txt","w") do fp
           println(fp,"# J2=$(J2),L=$(L)")
           for j in 1:n_bins-1
               println(fp,ith_ene_hist[2][j]," ",ith_ene_hist[1][j])
           end
       end
   end

end

mk_hist_txt(ene_hist,num_temps,J2,L,n_bins)






