using Documenter

include("custom-block.jl")

# Simple site build with just index.md building into HTML
makedocs(
    sitename="Custom Image",
    pages=["index.md"],
)
