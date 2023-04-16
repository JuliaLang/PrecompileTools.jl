# Precompiler

## Overview

`Precompiler` is designed to help reduce delay on first usage of Julia code.
It can force *precompilation* of specific workloads; particularly with Julia 1.9 and higher,
the precompiled code can be saved to disk, so that it doesn't need to be compiled freshly in each Julia session.
You can use `Precompiler` as a package developer, to reduce the latency experienced by users of your package for "typical" workloads;
you can also use `Precompiler` as a user, creating custom "Startup" package(s) that precompile workloads important for your work.

The main tool in `Precompiler` is a macro, `Precompiler.@cache`, which precompiles every call on its first usage.
It also includes a second macro, `Precompiler.@setup`, which can be used to "mark" a block of code as being relevant only
for precompilation but which does not itself force compilation of setup code. (`@setup` is typically used to generate
test data using functions that you don't need to precompile in your package.)

## Tutorial

No matter whether you're a package developer or a user looking to make your own workloads start faster,
the basic workflow of `Precompiler` is the same.
Here's an illustration of how you might use `Precompiler.@cache` and `Precompiler.@setup`:

```julia
module MyPackage

using Precompiler    # this is a small dependency

struct MyType
    x::Int
end
struct OtherType
    str::String
end

Precompiler.@setup begin
    # Putting some things in `@setup` instead of `@cache` can reduce the size of the
    # precompile file and potentially make loading faster.
    list = [OtherType("hello"), OtherType("world!")]
    Precompiler.@cache begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        d = Dict(MyType(1) => list)
        x = get(d, MyType(2), nothing)
        last(d[MyType(1)])
    end
end

end
```

When you build `MyPackage`, it will precompile the following, *including all their callees*:

- `Pair(::MyPackage.MyType, ::Vector{MyPackage.OtherType})`
- `Dict(::Pair{MyPackage.MyType, Vector{MyPackage.OtherType}})`
- `get(::Dict{MyPackage.MyType, Vector{MyPackage.OtherType}}, ::MyPackage.MyType, ::Nothing)`
- `getindex(::Dict{MyPackage.MyType, Vector{MyPackage.OtherType}}, ::MyPackage.MyType)`
- `last(::Vector{MyPackage.OtherType})`

In this case, the "top level" calls were fully inferrable, so there are no entries on this list
that were called by runtime dispatch. Thus, here you could have gotten the same result with manual
`precompile` directives.
The key advantage of `Precompiler.@cache` is that it works even if the functions you're calling
have runtime dispatch.

Once you set up a block using `Precompiler`, try your package and see if it reduces the time to first execution,
using the same workload you put inside the `Precompiler.@cache` block.

If you're happy with the results, you're done! If you want deeper verification of whether it worked as
expected, or if you suspect problems, the [SnoopCompile package](https://github.com/timholy/SnoopCompile.jl) provides diagnostic tools.
Potential sources of trouble include invalidation (diagnosed with `SnoopCompileCore.@snoopr` and related tools)
and omission of intended calls from inside the `Precompiler.@cache` block (diagnosed with `SnoopCompileCore.@snoopi_deep` and related tools).

!!! note
    `Precompiler.@cache` works by monitoring type-inference. If the code was already inferred
    prior to `Precompiler.@cache` (e.g., from prior usage), you might omit any external
    methods that were called via runtime dispatch.

    You can use multiple `Precompiler.@cache` blocks if you need to interleave "setup" code with
    code that you want precompiled.
    You can use `@snoopi_deep` to check for any (re)inference when you use the code in your package.
    To fix any specific problems, you can combine `Precompiler.@cache` with manual `precompile` directives.

## Tutorial: local "Startup" packages

Users who want to precompile workloads that have not been precompiled by the packages they use can follow the recipe
above, creating custom "Startup" packages for each project.
Imagine that you have three different kinds of analyses you do: you could have a folder

```
MyData/
  Project1/
  Project2/
  Project3/
```

From each one of those `Project` folders you could do the following:

```
(@v1.9) pkg> activate .
  Activating new project at `/tmp/Project1`

(Project1) pkg> generate Startup
  Generating  project Startup:
    Startup/Project.toml
    Startup/src/Startup.jl

(Project1) pkg> dev ./Startup
   Resolving package versions...
    Updating `/tmp/Project1/Project.toml`
  [e9c42744] + Startup v0.1.0 `Startup`
    Updating `/tmp/Project1/Manifest.toml`
  [e9c42744] + Startup v0.1.0 `Startup`

(Project1) pkg> activate Startup/
  Activating project at `/tmp/Project1/Startup`

(Startup) pkg> add Precompiler LotsOfPackages...
```

In the last step, you add `Precompiler` and all the package you'll need for your work on `Project1`
as dependencies of `Startup`.
Then edit the `Startup/src/Startup.jl` file to look similar to the tutorial previous section, e.g.,

```julia
module Startup

using LotsOfPackages...
using Precompiler

Precompiler.@cache begin
    # inside here, put a "toy example" of everything you want to be fast
end

end
```

Then when you're ready to start work, from the `Project1` environment just say `using Startup`.
All the packages will be loaded, together with their precompiled code.

!!! tip
    If desired, the [Reexport package](https://github.com/simonster/Reexport.jl) can be used to ensure these packages are also exported by `Startup`.

## When you can't run a workload

There are cases where you might want to precompile code but cannot safely *execute* that code: for example, you may need to connect to a database, or perhaps this is a plotting package but you may be currently on a headless server lacking a display, etc.
In that case, your best option is to fall back on Julia's own `precompile` function.
However, as explained in [How Precompiler works](@ref), there are some differences between `precompile` and `Precompiler.@cache`;
most likely, you may need multiple `precompile` directives.
Analysis with [SnoopCompile](https://github.com/timholy/SnoopCompile.jl) may be required to obtain the results you want.

## Package developers: reducing the cost of precompilation during development

If you're frequently modifying one or more packages, you may not want to spend the extra time precompiling the full set of workloads that you've chosen to make fast for your "shipped" releases.
One can *locally* reduce the cost of precompilation for selected packages using the `Preferences.jl`-based mechanism and the `skip_precompile` key: from within your development environment, use

```julia
using MyPackage, Preferences
set_preferences!(MyPackage, "skip_precompile" => true; force=true)
```

After restarting julia, the `Precompiler.@cache` and `Precompiler.@setup` workloads will be disabled (locally) for `MyPackage`.
You can also specify additional packages (e.g., dependencies of `MyPackage`) if you're co-developing a suite of packages.

!!! note
    Changing `skip_precompile` will result in a one-time recompilation of all packages that use the package(s) from the current environment.
    Package developers may wish to set this preference locally within the "main" package's environment;
    precompilation will be skipped while you're actively developing the project, but not if you use the package
    from an external environment. This will also keep the `skip_precompile` setting independent and avoid needless recompilation
    of large environments.

## Seeing what got precompiled

If you want to see the list of calls that will be precompiled, navigate to the `MyPackage` folder and use

```julia
julia> using Precompiler

julia> Precompiler.verbose[] = true   # runs the block even if you're not precompiling, and print precompiled calls

julia> include("src/MyPackage.jl");
```

This will only show the direct- or runtime-dispatched method instances that got precompiled (omitting their inferrable callees).
For a more comprehensive list of all items stored in the cache file, see
[PkgCacheInspector](https://github.com/timholy/PkgCacheInspector.jl).

## How Precompiler works

Julia itself has a function `precompile`, to which you can pass specific signatures to force precompilation.
For example, `precompile(foo, (ArgType1, ArgType2))` will precompile `foo(::ArgType1, ::ArgType2)` *and all of its inferrable callees*.
Alternatively, you can just execute some code at "top level" within the module, and during precompilation any method or signature "owned" by your package will also be precompiled.
Thus, base Julia itself has substantial facilities for precompiling code.

`Precompiler.@cache` adds one key feature: the *non-inferrable callees* (i.e., those called via runtime dispatch) that get
made inside the `@cache` block will also be cached, *regardless of module ownership*. In essence, it's like you're adding
an explicit `precompile(noninferrable_callee, (OtherArgType1, ...))` for every runtime-dispatched call made inside `Precompiler.@cache`.

`Precompiler` adds other features as well:

- Statements that occur inside a `Precompiler.@cache` block are executed only if the package is being actively precompiled; it does not run when the package is loaded, nor if you're running Julia with `--compiled-modules=no`.
- Compared to just running some workload at top-level, `Precompiler.@cache` ensures that your code will be compiled (it disables the interpreter inside the block)
- Precompiler also defines `Precompiler.@setup`, which you can use to create data for use inside a `Precompiler.@cache` block. Like `Precompiler.@cache`, this code only runs when you are precompiling the package, but it does not necessarily result in the "setup" code being stored in the package precompile file.
