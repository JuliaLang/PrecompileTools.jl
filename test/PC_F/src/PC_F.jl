module PC_F
    using PrecompileTools

    @compile_workload begin
        throw(error("This is a very serious error during precompilaton"))
    end
end
