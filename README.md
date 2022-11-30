# BibtexDOI.jl

Get a well-formatted, journal-abbreviated BibTeX string from a DOI:

```jl
julia> using BibtexDOI

julia> doi = "10.1103/PhysRevLett.45.494"

julia> print_doi2bib(doi) # or `doi2bib(doi) |> print`
@article{klitzing1980new,
  doi = {10.1103/physrevlett.45.494},
  year = 1980,
  volume = {45},
  number = {6},
  pages = {494--497},
  author = {K. v. Klitzing and G. Dorda and M. Pepper},
  title = {New Method for High-Accuracy Determination of the Fine-Structure Constant Based on Quantized Hall Resistance},
  journal = {Phys. Rev. Lett.}
}
```
Journal titles are automatically abbreviated using the [List of Title Word Abbreviations](https://www.issn.org/services/online-services/access-to-the-ltwa/) (disable by setting the `abbreviate` keyword argument to `false`).

## Installation

The package is currently not registered. Install directly from the URL:
```jl
julia> import Pkg
julia> Pkg.add("https://github.com/thchr/BibtexDOI.jl")
```