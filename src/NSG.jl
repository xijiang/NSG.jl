"""
    Pkg NSG
---
# Objectives
This package is to organize genotypes of NSG sheep on various platforms.
The functions include:

1. Management of raw genotypes
2. Data QC to filter out low quality ID and/or loci
3. Imputation of sparser platforms to denser ones.
4. Calculation of a **G** matrix with imputed genotypes

This package was written only for Linux OS
"""
module NSG

work_dir = pwd()                # all data and results are relative to work_dir
bin_dir, cpp_dir = begin
    t = splitdir(pathof(NSG))[1]
    l = findlast('/', t) - 1
    joinpath(t[1:l], "bin"), joinpath(t[1:l], "src")
end
beagle = joinpath(bin_dir, "beagle.jar")
plink = joinpath(bin_dir, "plink")
global nsNe = 100
set_ne(ne) = (global nsNe=ne)
global _nthreads = 8
set_nthreads(n) = (global _nthreads=n)

include("styled-messages.jl")
include("update.jl")
include("raw.jl")
include("misc.jl")
include("QC.jl")
include("imputation.jl")
include("gmatrix.jl")
include("genotypes.jl")

NSG.title("Updating binaries")
NSG.Update()
end # module
