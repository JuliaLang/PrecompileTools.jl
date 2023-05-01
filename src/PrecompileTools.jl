module PrecompileTools

if VERSION >= v"1.6"
    using Preferences
end
export @setup_workload, @compile_workload, @recompile_invalidations

const verbose = Ref(false)    # if true, prints all the precompiles
const have_inference_tracking = isdefined(Core.Compiler, :__set_measure_typeinf)
const have_force_compile = isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("#@force_compile"))

function precompile_mi(mi)
    precompile(mi.specTypes) # TODO: Julia should allow one to pass `mi` directly (would handle `invoke` properly)
    verbose[] && println(mi)
    return
end

include("workloads.jl")
if VERSION >= v"1.9.0-rc2"
    include("invalidations.jl")
else
    macro recompile_invalidations(ex::Expr)
        return esc(ex)
    end
end

end
