"""
    @recompile_invalidations begin
        using PkgA
        ⋮
    end

Recompile any invalidations that occur within the given expression. This is generally intended to be used
by users in creating "Startup" packages to ensure that the code compiled by package authors is not invalidated.
"""
macro recompile_invalidations(expr)
    # use QuoteNode instead of esc(Expr(:quote)) so that $ is not permitted as usual (instead of having this macro work like `@eval`)
    return :(recompile_invalidations($__module__, $(QuoteNode(expr))))
end

function recompile_invalidations(__module__::Module, @nospecialize expr)
    list = ccall(:jl_debug_method_invalidation, Any, (Cint,), 1)
    try
        Core.eval(__module__, expr)
    finally
        ccall(:jl_debug_method_invalidation, Any, (Cint,), 0)
    end
    if ccall(:jl_generating_output, Cint, ()) == 1
        foreach(precompile_mi, invalidation_leaves(list))
    end
    nothing
end

function invalidation_leaves(invlist)
    umis = Set{Core.MethodInstance}()
    # `queued` is a queue of length 0 or 1 of invalidated MethodInstances.
    # We wait to read the `depth` to find out if it's a leaf.
    queued, depth = nothing, 0
    function cachequeued(item, nextdepth)
        if queued !== nothing && nextdepth <= depth
            push!(umis, queued)
        end
        queued, depth = item, nextdepth
    end

    i, ilast = firstindex(invlist), lastindex(invlist)
    while i <= ilast
        item = invlist[i]
        if isa(item, Core.MethodInstance)
            if i < lastindex(invlist)
                nextitem = invlist[i+1]
                if nextitem == "invalidate_mt_cache"
                    cachequeued(nothing, 0)
                    i += 2
                    continue
                end
                if nextitem ∈ ("jl_method_table_disable", "jl_method_table_insert", "verify_methods")
                    cachequeued(nothing, 0)
                    push!(umis, item)
                end
                if isa(nextitem, Integer)
                    cachequeued(item, nextitem)
                    i += 2
                    continue
                end
            end
        end
        if (isa(item, Method) || isa(item, Type)) && queued !== nothing
            push!(umis, queued)
            queued, depth = nothing, 0
        end
        i += 1
    end
    return umis
end
