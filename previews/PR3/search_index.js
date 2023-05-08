var documenterSearchIndex = {"docs":
[{"location":"reference/","page":"Reference","title":"Reference","text":"CurrentModule = Precompiler","category":"page"},{"location":"reference/#Reference-(API)","page":"Reference","title":"Reference (API)","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"API documentation for Precompiler.","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"Modules = [Precompiler]","category":"page"},{"location":"reference/#Precompiler.@cache-Tuple{Expr}","page":"Reference","title":"Precompiler.@cache","text":"Precompiler.@cache f(args...)\n\nprecompile (and save in the cache file) any method-calls that occur inside the expression. All calls (direct or indirect) inside a Precompiler.@cache block will be cached.\n\nPrecompiler.@cache has three key features:\n\ncode inside runs only when the package is being precompiled (i.e., a *.ji precompile cache file is being written)\nthe interpreter is disabled, ensuring your calls will be compiled\nboth direct and indirect callees will be precompiled, even for methods defined in other packages and even for runtime-dispatched callees (requires Julia 1.8 and above).\n\nnote: Note\nFor comprehensive precompilation, ensure the first usage of a given method/argument-type combination occurs inside Precompiler.@cache.In detail: runtime-dispatched callees are captured only when type-inference is executed, and they are inferred only on first usage. Inferrable calls that trace back to a method defined in your package, and their inferrable callees, will be precompiled regardless of \"ownership\" of the callees (Julia 1.8 and higher).Consequently, this recommendation matters only for:- direct calls to methods defined in Base or other packages OR\n- indirect runtime-dispatched calls to such methods.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Precompiler.@setup-Tuple{Expr}","page":"Reference","title":"Precompiler.@setup","text":"Precompiler.@setup begin\n    vars = ...\n    ⋮\nend\n\nRun the code block only during package precompilation. Precompiler.@setup is often used in combination with Precompiler.@cache, for example:\n\nPrecompiler.@setup begin\n    vars = ...\n    @cache begin\n        y = f(vars...)\n        g(y)\n        ⋮\n    end\nend\n\nPrecompiler.@setup does not force compilation (though it may happen anyway) nor intentionally capture runtime dispatches (though they will be precompiled anyway if the runtime-callee is for a method belonging to your package).\n\n\n\n\n\n","category":"macro"},{"location":"#Precompiler","page":"Home","title":"Precompiler","text":"","category":"section"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Precompiler is designed to help reduce delay on first usage of Julia code. It can force precompilation of specific workloads; particularly with Julia 1.9 and higher, the precompiled code can be saved to disk, so that it doesn't need to be compiled freshly in each Julia session. You can use Precompiler as a package developer, to reduce the latency experienced by users of your package for \"typical\" workloads; you can also use Precompiler as a user, creating custom \"Startup\" package(s) that precompile workloads important for your work.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The main tool in Precompiler is a macro, Precompiler.@cache, which precompiles every call on its first usage. It also includes a second macro, Precompiler.@setup, which can be used to \"mark\" a block of code as being relevant only for precompilation but which does not itself force compilation of setup code. (@setup is typically used to generate test data using functions that you don't need to precompile in your package.)","category":"page"},{"location":"#Tutorial","page":"Home","title":"Tutorial","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"No matter whether you're a package developer or a user looking to make your own workloads start faster, the basic workflow of Precompiler is the same. Here's an illustration of how you might use Precompiler.@cache and Precompiler.@setup:","category":"page"},{"location":"","page":"Home","title":"Home","text":"module MyPackage\n\nusing Precompiler    # this is a small dependency\n\nstruct MyType\n    x::Int\nend\nstruct OtherType\n    str::String\nend\n\nPrecompiler.@setup begin\n    # Putting some things in `@setup` instead of `@cache` can reduce the size of the\n    # precompile file and potentially make loading faster.\n    list = [OtherType(\"hello\"), OtherType(\"world!\")]\n    Precompiler.@cache begin\n        # all calls in this block will be precompiled, regardless of whether\n        # they belong to your package or not (on Julia 1.8 and higher)\n        d = Dict(MyType(1) => list)\n        x = get(d, MyType(2), nothing)\n        last(d[MyType(1)])\n    end\nend\n\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"When you build MyPackage, it will precompile the following, including all their callees:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Pair(::MyPackage.MyType, ::Vector{MyPackage.OtherType})\nDict(::Pair{MyPackage.MyType, Vector{MyPackage.OtherType}})\nget(::Dict{MyPackage.MyType, Vector{MyPackage.OtherType}}, ::MyPackage.MyType, ::Nothing)\ngetindex(::Dict{MyPackage.MyType, Vector{MyPackage.OtherType}}, ::MyPackage.MyType)\nlast(::Vector{MyPackage.OtherType})","category":"page"},{"location":"","page":"Home","title":"Home","text":"In this case, the \"top level\" calls were fully inferrable, so there are no entries on this list that were called by runtime dispatch. Thus, here you could have gotten the same result with manual precompile directives. The key advantage of Precompiler.@cache is that it works even if the functions you're calling have runtime dispatch.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Once you set up a block using Precompiler, try your package and see if it reduces the time to first execution, using the same workload you put inside the Precompiler.@cache block.","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you're happy with the results, you're done! If you want deeper verification of whether it worked as expected, or if you suspect problems, the SnoopCompile package provides diagnostic tools. Potential sources of trouble include invalidation (diagnosed with SnoopCompileCore.@snoopr and related tools) and omission of intended calls from inside the Precompiler.@cache block (diagnosed with SnoopCompileCore.@snoopi_deep and related tools).","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nPrecompiler.@cache works by monitoring type-inference. If the code was already inferred prior to Precompiler.@cache (e.g., from prior usage), you might omit any external methods that were called via runtime dispatch.You can use multiple Precompiler.@cache blocks if you need to interleave \"setup\" code with code that you want precompiled. You can use @snoopi_deep to check for any (re)inference when you use the code in your package. To fix any specific problems, you can combine Precompiler.@cache with manual precompile directives.","category":"page"},{"location":"#Tutorial:-local-\"Startup\"-packages","page":"Home","title":"Tutorial: local \"Startup\" packages","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Users who want to precompile workloads that have not been precompiled by the packages they use can follow the recipe above, creating custom \"Startup\" packages for each project. Imagine that you have three different kinds of analyses you do: you could have a folder","category":"page"},{"location":"","page":"Home","title":"Home","text":"MyData/\n  Project1/\n  Project2/\n  Project3/","category":"page"},{"location":"","page":"Home","title":"Home","text":"From each one of those Project folders you could do the following:","category":"page"},{"location":"","page":"Home","title":"Home","text":"(@v1.9) pkg> activate .\n  Activating new project at `/tmp/Project1`\n\n(Project1) pkg> generate Startup\n  Generating  project Startup:\n    Startup/Project.toml\n    Startup/src/Startup.jl\n\n(Project1) pkg> dev ./Startup\n   Resolving package versions...\n    Updating `/tmp/Project1/Project.toml`\n  [e9c42744] + Startup v0.1.0 `Startup`\n    Updating `/tmp/Project1/Manifest.toml`\n  [e9c42744] + Startup v0.1.0 `Startup`\n\n(Project1) pkg> activate Startup/\n  Activating project at `/tmp/Project1/Startup`\n\n(Startup) pkg> add Precompiler LotsOfPackages...","category":"page"},{"location":"","page":"Home","title":"Home","text":"In the last step, you add Precompiler and all the package you'll need for your work on Project1 as dependencies of Startup. Then edit the Startup/src/Startup.jl file to look similar to the tutorial previous section, e.g.,","category":"page"},{"location":"","page":"Home","title":"Home","text":"module Startup\n\nusing LotsOfPackages...\nusing Precompiler\n\nPrecompiler.@cache begin\n    # inside here, put a \"toy example\" of everything you want to be fast\nend\n\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"Then when you're ready to start work, from the Project1 environment just say using Startup. All the packages will be loaded, together with their precompiled code.","category":"page"},{"location":"","page":"Home","title":"Home","text":"tip: Tip\nIf desired, the Reexport package can be used to ensure these packages are also exported by Startup.","category":"page"},{"location":"#When-you-can't-run-a-workload","page":"Home","title":"When you can't run a workload","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"There are cases where you might want to precompile code but cannot safely execute that code: for example, you may need to connect to a database, or perhaps this is a plotting package but you may be currently on a headless server lacking a display, etc. In that case, your best option is to fall back on Julia's own precompile function. However, as explained in How Precompiler works, there are some differences between precompile and Precompiler.@cache; most likely, you may need multiple precompile directives. Analysis with SnoopCompile may be required to obtain the results you want.","category":"page"},{"location":"#Package-developers:-reducing-the-cost-of-precompilation-during-development","page":"Home","title":"Package developers: reducing the cost of precompilation during development","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"If you're frequently modifying one or more packages, you may not want to spend the extra time precompiling the full set of workloads that you've chosen to make fast for your \"shipped\" releases. One can locally reduce the cost of precompilation for selected packages using the Preferences.jl-based mechanism and the skip_precompile key: from within your development environment, use","category":"page"},{"location":"","page":"Home","title":"Home","text":"using MyPackage, Preferences\nset_preferences!(MyPackage, \"skip_precompile\" => true; force=true)","category":"page"},{"location":"","page":"Home","title":"Home","text":"After restarting julia, the Precompiler.@cache and Precompiler.@setup workloads will be disabled (locally) for MyPackage. You can also specify additional packages (e.g., dependencies of MyPackage) if you're co-developing a suite of packages.","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nChanging skip_precompile will result in a one-time recompilation of all packages that use the package(s) from the current environment. Package developers may wish to set this preference locally within the \"main\" package's environment; precompilation will be skipped while you're actively developing the project, but not if you use the package from an external environment. This will also keep the skip_precompile setting independent and avoid needless recompilation of large environments.","category":"page"},{"location":"#Seeing-what-got-precompiled","page":"Home","title":"Seeing what got precompiled","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"If you want to see the list of calls that will be precompiled, navigate to the MyPackage folder and use","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using Precompiler\n\njulia> Precompiler.verbose[] = true   # runs the block even if you're not precompiling, and print precompiled calls\n\njulia> include(\"src/MyPackage.jl\");","category":"page"},{"location":"","page":"Home","title":"Home","text":"This will only show the direct- or runtime-dispatched method instances that got precompiled (omitting their inferrable callees). For a more comprehensive list of all items stored in the cache file, see PkgCacheInspector.","category":"page"},{"location":"#How-Precompiler-works","page":"Home","title":"How Precompiler works","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Julia itself has a function precompile, to which you can pass specific signatures to force precompilation. For example, precompile(foo, (ArgType1, ArgType2)) will precompile foo(::ArgType1, ::ArgType2) and all of its inferrable callees. Alternatively, you can just execute some code at \"top level\" within the module, and during precompilation any method or signature \"owned\" by your package will also be precompiled. Thus, base Julia itself has substantial facilities for precompiling code.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Precompiler.@cache adds one key feature: the non-inferrable callees (i.e., those called via runtime dispatch) that get made inside the @cache block will also be cached, regardless of module ownership. In essence, it's like you're adding an explicit precompile(noninferrable_callee, (OtherArgType1, ...)) for every runtime-dispatched call made inside Precompiler.@cache.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Precompiler adds other features as well:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Statements that occur inside a Precompiler.@cache block are executed only if the package is being actively precompiled; it does not run when the package is loaded, nor if you're running Julia with --compiled-modules=no.\nCompared to just running some workload at top-level, Precompiler.@cache ensures that your code will be compiled (it disables the interpreter inside the block)\nPrecompiler also defines Precompiler.@setup, which you can use to create data for use inside a Precompiler.@cache block. Like Precompiler.@cache, this code only runs when you are precompiling the package, but it does not necessarily result in the \"setup\" code being stored in the package precompile file.","category":"page"}]
}