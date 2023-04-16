module PC_A

using Precompiler

struct MyType
    x::Int
end

if isdefined(Base, :inferencebarrier)
    inferencebarrier(@nospecialize(arg)) = Base.inferencebarrier(arg)
else
    inferencebarrier(@nospecialize(arg)) = Ref{Any}(arg)[]
end

function call_findfirst(x, list)
    # call a method defined in Base by runtime dispatch
    return findfirst(==(inferencebarrier(x)), inferencebarrier(list))
end

Precompiler.@setup begin
    list = [MyType(1), MyType(2), MyType(3)]
    Precompiler.@cache begin
        call_findfirst(MyType(2), list)
    end
end

end # module PC_A
