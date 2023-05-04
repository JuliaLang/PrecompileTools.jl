using PrecompileTools
using Documenter

DocMeta.setdocmeta!(PrecompileTools, :DocTestSetup, :(using PrecompileTools); recursive=true)

makedocs(;
    modules=[PrecompileTools],
    authors="Tim Holy <tim.holy@gmail.com>, t-bltg <tf.bltg@gmail.com>, and contributors",
    repo="https://github.com/JuliaLang/PrecompileTools.jl/blob/{commit}{path}#{line}",
    sitename="PrecompileTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaLang.github.io/PrecompileTools.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Invalidations" => "invalidations.md",
        "How PrecompileTools works" => "explanations.md",
        "Reference" => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaLang/PrecompileTools.jl",
    push_preview=true,
    devbranch="main",
)
