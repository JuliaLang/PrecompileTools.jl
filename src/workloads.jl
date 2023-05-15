
function workload_enabled(mod::Module)
    try
        load_preference(mod, "precompile_workload", true)
    catch
        true
    end
end

function throw_workload_error(mod::Module)
    try
        load_preference(mod, "throw_precompile_workload_error", false)
    catch
        false
    end
end

function show_precompile_errors(mod::Module)
    if isdefined(mod, :__PrecompileTools_setup_workload_error) && mod.__PrecompileTools_setup_workload_error !== nothing
        @error "An error occurred while precompiling $mod with PrecompileTools.@setup_workload" exception=mod.__PrecompileTools_setup_workload_error
    end
    if isdefined(mod, :__PrecompileTools_compile_workload_error) && mod.__PrecompileTools_compile_workload_error !== nothing
        @error "An error occurred while precompiling $mod with PrecompileTools.@compile_workload" exception=mod.__PrecompileTools_compile_workload_error
    end
end

"""
    check_edges(node)

Recursively ensure that all callees of `node` are precompiled. This is (rarely) necessary
because sometimes there is no backedge from callee to caller (xref https://github.com/JuliaLang/julia/issues/49617),
and `staticdata.c` relies on the backedge to trace back to a MethodInstance that is tagged `mi.precompiled`.
"""
function check_edges(node)
    parentmi = node.mi_info.mi
    for child in node.children
        childmi = child.mi_info.mi
        if !(isdefined(childmi, :backedges) && parentmi ∈ childmi.backedges)
            precompile_mi(childmi)
        end
        check_edges(child)
    end
end

function precompile_roots(roots)
    @assert have_inference_tracking
    for child in roots
        precompile_mi(child.mi_info.mi)
        check_edges(child)
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
        :((ccall(:jl_generating_output, Cint, ()) == 1 && $PrecompileTools.workload_enabled(@__MODULE__)))
    end
    local throw_error = :($PrecompileTools.throw_workload_error(@__MODULE__))
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
        const __PrecompileTools_setup_workload_error = if $iscompiling || $PrecompileTools.verbose[]
            try
                $ex
                 nothing
            catch err
                if $throw_error
                    throw(err)
                else
                    bt = catch_backtrace()
                    @error """
                    An error occurred while precompiling $(@__MODULE__) during `PrecompileTools.@compile_workload`.
                    Please resolve the errors and run `touch(pathof($(@__MODULE__))); Pkg.precompile(\"$(@__MODULE__)\")`."
                    """ exception=(err,bt)
                    err
                end
            end
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
        :((ccall(:jl_generating_output, Cint, ()) == 1 && $PrecompileTools.workload_enabled(@__MODULE__)))
    end
    local throw_error = :($PrecompileTools.throw_workload_error(@__MODULE__))
    # Ideally we'd like a `let` around this to prevent namespace pollution, but that seem to
    # trigger inference & codegen in undesirable ways (see #16).
    return esc(quote
        const __PrecompileTools_setup_workload_error = if $iscompiling || $PrecompileTools.verbose[]
            try
                $ex
                 nothing
            catch err
                if $throw_error
                    throw(err)
                else
                    bt = catch_backtrace()
                    @error """
                    An error occurred while precompiling $(@__MODULE__) during `PrecompileTools.@setup_workload`.
                    Please resolve the errors and run `touch(pathof($(@__MODULE__))); Pkg.precompile(\"$(@__MODULE__)\")`."
                    """ exception=(err,bt)
                    err
                end
            end
        end
    end)
end