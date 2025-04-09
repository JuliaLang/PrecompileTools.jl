module NotToplevel

using NotPrecompiled
using PrecompileTools: @setup_workload, @compile_workload

hello(who::AbstractString) = "Hello, $who"

@setup_workload begin
    withenv() do
        @compile_workload begin
            hello("x")
            NotPrecompiled.call_isa_bool('x')
        end
    end
end

end # module NotToplevel
