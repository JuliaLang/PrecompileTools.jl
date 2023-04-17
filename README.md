# Precompiler

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaLang.github.io/Precompiler.jl/stable/)
[![Build Status](https://github.com/JuliaLang/Precompiler.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaLang/Precompiler.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaLang/Precompiler.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaLang/Precompiler.jl)

Precompiler allows you to reduce the latency of the first execution of Julia code.
It is applicable both for package developers and "ordinary users"; for the latter, it can be viewed as an
alternative to [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl), particularly on Julia 1.9 and higher
where both can be used to cache "native code."
Nevertheless, the two are not identical: the primary differences between Precompiler and PackageCompiler are:

- only Precompiler can be used by *package developers* to ensure a better experience for your users
- only Precompiler allows you to update your packages without needing to rebuild Julia
- only PackageCompiler dramatically speeds up loading time (i.e., `using ...`) for all the packages

Precompiler started as [SnoopPrecompile](https://github.com/timholy/SnoopCompile.jl/tree/master/SnoopPrecompile), but
it differs in naming and in how one disables precompilation.
