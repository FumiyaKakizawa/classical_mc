using BenchmarkTools
using Revise 
include("../classical_mc.jl")
include("../measure_mc.jl")

L = 300
num_spins = 3L^2
num_temps_local = 1
spins_local = [fill((1.,0.,0.),num_spins)   for _ in 1:num_temps_local]
spins_array = [zeros(Float64, 3, num_spins) for _ in 1:num_temps_local]

for it in 1:num_temps_local
    ClassicalMC.convert_spins_to_array!(spins_local[it], spins_array[it])
end

upward_triangles   = ClassicalMC.read_triangles("utriangles.txt", num_spins)
downward_triangles = ClassicalMC.read_triangles("dtriangles.txt", num_spins)

# iterative measurement in MC runs.

# measuring memory allocation.
compute_vector_chiralities($(spins_array[1]), $(upward_triangles), $(downward_triangles))

@benchmark begin 
    compute_vector_chiralities($(spins_array[1]), $(upward_triangles), $(downward_triangles))
end
