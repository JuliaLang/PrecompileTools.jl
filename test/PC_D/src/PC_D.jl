module PC_D

using Precompiler
using Precompiler.Preferences

Precompiler.@setup begin
    Precompiler.@cache begin
        global workload_ran = true
    end
end

end # module PC_D
