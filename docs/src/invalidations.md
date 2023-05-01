# Why does Julia invalidate code?

Julia may be unique among computer languages in supporting all four of the following features:

1. interactive development
2. "method overloading" by packages that don't own the function
3. aggressive compilation
4. consistent compilation: same result no matter how you got there

The combination of these features *requires* that you sometimes "throw away" code that you have previously compiled.

To illustrate: suppose you have a function `f` with one method,

```
f(::Any) = 1
```

and then write

```
g(list) = sum(f.(list))
```

Now let `list` be a `Vector{Any}`. You can compile a fast `g(::Vector{Any})` (*aggressive compilation*) by leveraging the fact that you know there's only one possible method of `f`, and you know that it returns 1
for every input. Thus, `g(list)` gives you just `length(list)`, which would indeed be a very highly-optimized implementation!

But now suppose you add a second method (*interactive development* + *method overloading*)

```
f(::MyObj) = 2
```

where `MyObj` is some new type you've defined (so it's not type-piracy). If you want to get the right answer (*consistent compilation*) from an arbitrary `list::Vector{Any}`, there are only two options:

> **Option A**: plan for this eventuality from the beginning, by making every `f(::Any)` be called by runtime dispatch. But when there is only one method of `f`, forcing runtime dispatch makes the code vastly slower. Thus, this option at least partly violates *aggressive compilation*.

> **Option B**: throw away the code for `g` that you created when there was only one method of `f`, and recompile it in this new world where there are two.

Julia does a mix of these: it does **B** up to 3 methods, and then **A** thereafter. (Recent versions of Julia have experimental support for customizing this behavior with `Base.Experimental.@max_methods`.)

This example was framed as an experiment at the REPL, but it is also relevant if you load two packages: `PkgX` might define `f` and `g`, and `PkgY` might load `PkgX` and define a second method of `PkgX.f`.
Any precompilation that occurs in `PkgX` doesn't know what's going to happen in `PkgY`.
Therefore, unless you want to defer *all* compilation (including for `Base`) until the entire session is loaded and then closed to further extension, you have to make the same choice between **A** and **B**.
