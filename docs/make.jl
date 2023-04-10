using Precompiler
using Documenter

DocMeta.setdocmeta!(Precompiler, :DocTestSetup, :(using Precompiler); recursive=true)

makedocs(;
    modules=[Precompiler],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/JuliaLang/Precompiler.jl/blob/{commit}{path}#{line}",
    sitename="Precompiler.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaLang.github.io/Precompiler.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaLang/Precompiler.jl",
    devbranch="main",
)
