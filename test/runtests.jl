using PrecompileTools
using Test
using Pkg
using UUIDs

@testset "PrecompileTools.jl" begin
    specializations(m::Method) = isdefined(Base, :specializations) ? Base.specializations(m) : m.specializations

    push!(LOAD_PATH, @__DIR__)

    using PC_A
    @test !isdefined(PC_A, :list)
    if VERSION >= v"1.8"
        # Check that calls inside @setup_workload are not precompiled
        m = which(Tuple{typeof(Base.vect), Vararg{T}} where T)
        have_mytype = false
        for mi in specializations(m)
            mi === nothing && continue
            have_mytype |= Base.unwrap_unionall(mi.specTypes).parameters[2] === PC_A.MyType
        end
        have_mytype && @warn "Code in setup_workload block was precompiled"
        # Check that calls inside @compile_workload are precompiled
        m = only(methods(PC_A.call_findfirst))
        count = 0
        for mi in specializations(m)
            mi === nothing && continue
            sig = Base.unwrap_unionall(mi.specTypes)
            @test sig.parameters[2] == PC_A.MyType
            @test sig.parameters[3] == Vector{PC_A.MyType}
            count += 1
        end
        @test count == 1
        # Even one that was runtime-dispatched
        m = which(Tuple{typeof(findfirst), Base.Fix2{typeof(==), T}, Vector{T}} where T)
        count = 0
        for mi in specializations(m)
            mi === nothing && continue
            sig = Base.unwrap_unionall(mi.specTypes)
            if sig.parameters[3] == Vector{PC_A.MyType}
                count += 1
            end
        end
        @test count == 1
    end

    if VERSION >= v"1.7"   # so we can use redirect_stderr(f, ::Pipe)
        pipe = Pipe()
        id = Base.PkgId(UUID("d38b61e7-59a2-4ef9-b4d3-320bdc69b817"), "PC_B")
        redirect_stderr(pipe) do
            @test_throws Exception Base.require(id)
        end
        close(pipe.in)
        str = read(pipe.out, String)
        @test occursin(r"UndefVarError: `?missing_function`? not defined", str)
    end

    if VERSION >= v"1.6"
        using PC_C
    end

    if VERSION >= v"1.6"
        script = """
        using PC_D
        exit(isdefined(PC_D, :workload_ran) === parse(Bool, ARGS[1]) ? 0 : 1)
        """

        projfile = Base.active_project()
        Pkg.activate("PC_D")
        using PC_D

        PrecompileTools.Preferences.set_preferences!(PC_D, "precompile_workload" => false)
        @test success(run(`$(Base.julia_cmd()) --project=$(joinpath(@__DIR__, "PC_D")) -e $script 0`))

        PrecompileTools.Preferences.delete_preferences!(PC_D, "precompile_workload"; force = true)
        @test success(run(`$(Base.julia_cmd()) --project=$(joinpath(@__DIR__, "PC_D")) -e $script 1`))
        Pkg.activate(projfile)
    end

    if VERSION >= v"1.6"
        oldval = PrecompileTools.verbose[]
        PrecompileTools.verbose[] = true
        mktemp() do path, io
            redirect_stdout(io) do
                include(joinpath(@__DIR__, "PC_E", "src", "PC_E.jl"))
            end
            close(io)
            str = read(path, String)
            @test occursin("MethodInstance for", str)
            @test occursin("PC_E.f(::$Int)", str)
            @test occursin("PC_E.f(::String)", str)
        end
        PrecompileTools.verbose[] = oldval
    end
end
