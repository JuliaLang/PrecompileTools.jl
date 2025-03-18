module PrecompileTools

using Preferences

export @setup_workload, @compile_workload, @recompile_invalidations

const verbose = Ref(false)    # if true, prints all the precompiles

function precompile_mi(mi::Core.MethodInstance)
    precompile(mi.specTypes) # TODO: Julia should allow one to pass `mi` directly (would handle `invoke` properly)
    verbose[] && println(mi)
    return
end

include("workloads.jl")
include("invalidations.jl")

end
