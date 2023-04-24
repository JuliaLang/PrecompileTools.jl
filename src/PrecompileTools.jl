module PrecompileTools

if VERSION >= v"1.6"
    using Preferences
end
export @setup_workload, @compile_workload

const verbose = Ref(false)    # if true, prints all the precompiles
const have_inference_tracking = isdefined(Core.Compiler, :__set_measure_typeinf)
const have_force_compile = isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("#@force_compile"))

function precompile_roots(roots)
    @assert have_inference_tracking
    for child in roots
        mi = child.mi_info.mi
        precompile(mi.specTypes) # TODO: Julia should allow one to pass `mi` directly (would handle `invoke` properly)
        verbose[] && println(mi)
    end
end

"""
    @compile_workload f(args...)

`precompile` (and save in the compile_workload file) any method-calls that occur inside the expression. All calls (direct or indirect) inside a
`@compile_workload` block will be cached.

`@compile_workload` has three key features:

1. code inside runs only when the package is being precompiled (i.e., a `*.ji`
   precompile compile_workload file is being written)
2. the interpreter is disabled, ensuring your calls will be compiled
3. both direct and indirect callees will be precompiled, even for methods defined in other packages
   and even for runtime-dispatched callees (requires Julia 1.8 and above).

!!! note
    For comprehensive precompilation, ensure the first usage of a given method/argument-type combination
    occurs inside `@compile_workload`.

    In detail: runtime-dispatched callees are captured only when type-inference is executed, and they
    are inferred only on first usage. Inferrable calls that trace back to a method defined in your package,
    and their *inferrable* callees, will be precompiled regardless of "ownership" of the callees
    (Julia 1.8 and higher).

    Consequently, this recommendation matters only for:

        - direct calls to methods defined in Base or other packages OR
        - indirect runtime-dispatched calls to such methods.
"""
macro compile_workload(ex::Expr)
    local iscompiling = if Base.VERSION < v"1.6"
        :(ccall(:jl_generating_output, Cint, ()) == 1)
    else
        :((ccall(:jl_generating_output, Cint, ()) == 1 && $PrecompileTools.@load_preference("precompile_workload", true)))
    end
    if have_force_compile
        ex = quote
            begin
                Base.Experimental.@force_compile
                $ex
            end
        end
    else
        # Use the hack on earlier Julia versions that blocks the interpreter
        ex = quote
            while false end
            $ex
        end
    end
    if have_inference_tracking
        ex = quote
            Core.Compiler.Timings.reset_timings()
            Core.Compiler.__set_measure_typeinf(true)
            try
                $ex
            finally
                Core.Compiler.__set_measure_typeinf(false)
                Core.Compiler.Timings.close_current_timer()
            end
            $PrecompileTools.precompile_roots(Core.Compiler.Timings._timings[1].children)
        end
    end
    return esc(quote
        if $iscompiling || $PrecompileTools.verbose[]
            $ex
        end
    end)
end

"""
    @setup_workload begin
        vars = ...
        ⋮
    end

Run the code block only during package precompilation. `@setup_workload` is often used in combination
with [`@compile_workload`](@ref), for example:

    @setup_workload begin
        vars = ...
        @compile_workload begin
            y = f(vars...)
            g(y)
            ⋮
        end
    end

`@setup_workload` does not force compilation (though it may happen anyway) nor intentionally capture
runtime dispatches (though they will be precompiled anyway if the runtime-callee is for a method belonging
to your package).
"""
macro setup_workload(ex::Expr)
    local iscompiling = if Base.VERSION < v"1.6"
        :(ccall(:jl_generating_output, Cint, ()) == 1)
    else
        :((ccall(:jl_generating_output, Cint, ()) == 1 && $PrecompileTools.@load_preference("precompile_workload", true)))
    end
    return esc(quote
        let
            if $iscompiling || $PrecompileTools.verbose[]
                $ex
            end
        end
    end)
end

end
