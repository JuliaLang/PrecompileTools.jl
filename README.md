# Precompiler

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaLang.github.io/Precompiler.jl/stable/)
[![Build Status](https://github.com/JuliaLang/Precompiler.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaLang/Precompiler.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaLang/Precompiler.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaLang/Precompiler.jl)

Precompiler allows you to reduce the latency of the first execution of Julia code.
**It is applicable for package developers and for "ordinary users" in their personal workflows.**

To learn how to use Precompiler, see the [documentation](https://JuliaLang.github.io/Precompiler.jl/stable/).

## Precompiler and PackageCompiler

Particularly on Julia 1.9 and higher, Precompiler allows dramatic reduction in "time to first execution" (TTFX).
In this respect, it shares goals with (and performs similarly to) [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl).
Nevertheless, the two are not identical:

- only Precompiler can be used by *package developers* to ensure a better out-of-box experience for your users
- only Precompiler allows you to update your packages without needing to rebuild Julia
- only PackageCompiler dramatically speeds up loading time (i.e., `using ...`) for all the packages

## History (origins as SnoopPrecompile)

Precompiler is the successor to [SnoopPrecompile](https://github.com/timholy/SnoopCompile.jl/tree/master/SnoopPrecompile).
Precompiler differs in naming and in how one disables precompilation, but is otherwise a drop-in replacement.
