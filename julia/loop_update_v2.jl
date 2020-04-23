include("mcmc.jl")

using LinearAlgebra
using StaticArrays
using Random

struct LoopUpdater{T}
    num_spins::Int
    work::Array{Int}
    spins_on_loop::Array{UInt}
    new_spins::Array{T}
end

function LoopUpdater{T}(num_spins::Int64, max_loop_length::Int64) where T
    work   = zeros(Int,num_spins)
    spins_on_loop  = zeros(Int, max_loop_length)
    new_spins  = Array{T}(undef, max_loop_length)
    return LoopUpdater{T}(num_spins,work, spins_on_loop, new_spins)
end


# rewrite based on Sec.3,B of Stefan Schnabel and David P. Landau(2012)
function find_loop(spins,
                   spins_on_loop,
                   updater::SingleSpinFlipUpdater,
                   first_spin_idx,
                   second_spin_idx,
                   max_length::Int, 
                   work::Array{Int}, verbose::Bool=false,check_n_candidate::Bool=true)
    #=
    All elements of work must be initialized to zero.
    =#
    

    num_spins = updater.num_spins

    @assert length(work) >= num_spins

    work[first_spin_idx]  = 1
    spins_on_loop[1]      = first_spin_idx
    work[second_spin_idx] = 2
    spins_on_loop[2]      = second_spin_idx
    loop_length::Int64    = 2
    spin_before::Int64    = first_spin_idx
    current_spin_idx::Int64 = second_spin_idx

    max_coord_num = maximum(updater.nn_coord_num)
    candidate_spins = zeros(UInt, max_coord_num)
    
    #if verbose
       #println("colors_on_loop $(colors_on_loop)")
    #end

    success = false
    status = -1

    sum_boundary_spins::HeisenbergSpin = (0.,0.,0.)
    inner_prod = zeros(Float64, max_coord_num)
    while loop_length < max_length
        #if verbose
           #println("current_spin_idx $(current_spin_idx)")
        #end
        # Search connected spins
        n_candidate = 0
        for ins in 1:updater.nn_coord_num[current_spin_idx]
            # candidate must be either the first spin on the loop (work[ns]==1) or unvisited (work[ns]==0)
            ns::SpinIndex = updater.nn_sites[ins,current_spin_idx]
            if  work[ns] <= 1 && ns != spin_before
                n_candidate += 1
                candidate_spins[n_candidate] = ns
            end
        end

        if n_candidate == 0
            status = 1
            break
        end
        
        """
        println("DEBUG A': ",n_candidate)
        if check_n_candidate
            @assert n_candidate == 2
        end
        """
        # next spin index must be determined by value of inner product between one before spin.
        for idx in 1:n_candidate
            inner_prod[idx] = dot(spins[spin_before],spins[candidate_spins[idx]])
        end
        
        next_spin_idx = candidate_spins[1:n_candidate][findmax(inner_prod[1:n_candidate])[2]] # findmax() returns (max element,its index)

        for idx in 1:n_candidate
            if candidate_spins[idx] == next_spin_idx
                continue
            end
            sum_boundary_spins = sum_boundary_spins .+ spins[candidate_spins[idx]]
        end


        if work[next_spin_idx] == 1
            # OK, we've returned to the starting point.
            status = 0
            success = true
            break
        end

        spin_before = current_spin_idx
        current_spin_idx = next_spin_idx
        loop_length += 1
        work[current_spin_idx] = loop_length
        spins_on_loop[loop_length] = current_spin_idx
    end
    #if verbose
       #println("status $(status) $(loop_length)")
    #end

    # Reset all elements of work to 0
    for l=1:loop_length
        work[spins_on_loop[l]] = 0
    end

    if success
        return loop_length, sum_boundary_spins
    else
        # Return the 0-length array of the same for type-stability
        return 0, (0.,0.,0.)
    end
end

function reflect_spins_on_loop!(loop_length::Int64,
                                spins::Array{HeisenbergSpin},
                                new_spins_on_loop::Array{HeisenbergSpin},
                                spins_on_loop::Array{UInt},
                                updater::SingleSpinFlipUpdater,
                                sum_boundary_spins::HeisenbergSpin)
         
         #implement Equ.(9)
         @assert mod(loop_length,2) == 0 "loop_length must to be even."
         perpendicular_vec = zeros(Float64,3)
         for i in 1:loop_length
             perpendicular_vec .+= (-1)^i * collect(spins[spins_on_loop[i]])
         end

         #implement Equ.(10)
         sum_boundary_spins = collect(sum_boundary_spins)
         normal_vec = normalize(cross(sum_boundary_spins,cross(sum_boundary_spins,perpendicular_vec)))
         
         println("DEBUG A: ",normal_vec[1]," ",normal_vec[2]," ",normal_vec[3])
         println("DEBUG B: ",dot(normal_vec,sum_boundary_spins))
         #implement Equ.(11)
         for i in 1:loop_length
             spin_old = collect(spins[spins_on_loop[i]])
             new_spins_on_loop[i] = Tuple(normalize(spin_old - 2 * dot(spin_old,normal_vec) * normal_vec))
         end
end

function compute_dE_loop(updater::SingleSpinFlipUpdater,
                          loop_length::Int,
                          spin_idx_on_loop::Array{UInt},
                          spins::Array{HeisenbergSpin},
                          new_spins_on_loop::Array{HeisenbergSpin},
                          work::Array{Int},
                          verbose::Bool=false)
    #=
    Compute change in energy
    All elements of work must be initialized to zero.
    =#

    num_spins = updater.num_spins

    for isp_loop in 1:loop_length
        work[spin_idx_on_loop[isp_loop]] = isp_loop
    end

    dE = 0.0
    for isp_loop in 1:loop_length
        ispin = spin_idx_on_loop[isp_loop]
        si_old = spins[ispin]
        for ic in 1:updater.coord_num[ispin]
            c = updater.connection[ic, ispin]
            jspin, Jx, Jy, Jz = c

            si_old = spins[ispin]
            sj_old = spins[jspin]
            si_new = new_spins_on_loop[isp_loop]
            # If the connected site is on the loop
            if work[jspin] != 0
                sj_new = new_spins_on_loop[work[jspin]]
                dE_spin = (Jx * sj_old[1] * si_old[1] + Jy * sj_old[2] * si_old[2] + Jz * sj_old[3] * si_old[3])
                dE_spin -= (Jx * sj_new[1] * si_new[1] + Jy * sj_new[2] * si_new[2] + Jz * sj_new[3] * si_new[3])
                dE += 0.5 * dE_spin
            else
                d_si = si_new .- si_old
                dE -= (Jx * sj_old[1] * d_si[1] + Jy * sj_old[2] * d_si[2] + Jz * sj_old[3] * d_si[3])
            end
        end
    end

    for isp_loop in 1:loop_length
        work[spin_idx_on_loop[isp_loop]] = 0
    end

    return dE
end


function metropolis_method!(beta::Float64,dE::Float64,
                            spins::AbstractArray{HeisenbergSpin},
                            loop_length::Int,
                            spin_idx_on_loop::Array{UInt},
                            new_spins_on_loop::Array{HeisenbergSpin},
                            num_accept::Int64)::Float64
 
    temp_rn = rand(Random.GLOBAL_RNG)
    println("DEBUG C: ",temp_rn," ",beta," ",dE)

    if temp_rn < exp(-beta*dE)
        spins[spin_idx_on_loop[1:loop_length]] = new_spins_on_loop[1:loop_length]
        num_accept += 1
        return dE
    else
        #p = exp(-beta*dE)
        #println("update failed: $(dE) $(p) $(dE*beta)")
        return 0.0
    end
end

function multi_loop_update!(loop_updater::LoopUpdater, num_trial::Int64,
                            updater::SingleSpinFlipUpdater,beta::Float64,
                            max_length::Int,
                            spins::AbstractArray{HeisenbergSpin},
                            verbose::Bool=false)
    
    # No copy
    work = loop_updater.work
    spins_on_loop = loop_updater.spins_on_loop
    new_spins = loop_updater.new_spins

    num_spins = updater.num_spins
    max_coord_num = maximum(updater.coord_num)
    
    dE   = 0.
    num_accept = 0
    num_loop_found = 0
     
    for i=1:num_trial
        
        first_spin_idx = rand(1:num_spins) 
        candidate_second_spin_idx = zeros(UInt,max_coord_num)
        nn_coord_num = updater.nn_coord_num[first_spin_idx]
        for ins in 1:nn_coord_num
            candidate_second_spin_idx[ins] = updater.nn_sites[ins,first_spin_idx]
        end
        second_spin_idx = rand(candidate_second_spin_idx[1:nn_coord_num])

        loop_length,sum_boundary_spins = find_loop(spins,spins_on_loop,updater,first_spin_idx,
                                                   second_spin_idx,max_length,work,verbose)
        
        if loop_length == 0 || mod(loop_length,2) !== 0
            continue
        end
        num_loop_found += 1
        
        before_flipped_spins = copy(spins[spins_on_loop[1:loop_length]])
        reflect_spins_on_loop!(loop_length,spins,new_spins,spins_on_loop,updater,sum_boundary_spins)
        temp_dE_loop = compute_dE_loop(updater,loop_length,spins_on_loop,spins,new_spins,work,verbose)
        dE_loop =  metropolis_method!(beta,temp_dE_loop,spins,loop_length,spins_on_loop,new_spins,num_accept)
       
        if dE_loop == 0
            continue
        end

        # for check detailed balance condition satisfied,test if find_loop() could find inverse loop.
        cp_spins_on_loop = copy(spins_on_loop[1:loop_length])
        first_spin_idx_inv  = spins_on_loop[loop_length]
        second_spin_idx_inv = spins_on_loop[loop_length-1]
        loop_length_inv,sum_boundary_spins_inv = find_loop(spins,spins_on_loop,updater,first_spin_idx_inv,
                                                           second_spin_idx_inv,max_length,work,verbose)
   
        if !all(reverse(spins_on_loop[1:loop_length]) .== cp_spins_on_loop)
            num_loop_found -= 1  
            num_accept     -= 1  
            spins[cp_spins_on_loop] = before_flipped_spins    
            continue
        end
        
        println("DEBUG D: ",loop_length)

        for i in 1:loop_length
            sx,sy,sz = spins[spins_on_loop[i]]
            println("DEBUG E: ",sx," ",sy," ",sz)
        end

        # in metropolis_method!(),num_accept += 1 when update is accepted.
        """
        if dE_tmp != 0
            num_accept += 1
        end
        """
    end

    #if verbose
       #println("multi_loop: $(1/beta) $(timings)")
    #end

    return dE, num_loop_found/num_trial, num_accept/num_trial
end

