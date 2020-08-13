using LinearAlgebra
"""
    function read_gt_n_frq(gt::AbstractString, frq::AbstractString)
---
Read genotypes and their frequencies from file `gt` and `frq`.
Note gt can be prepared like below:
```
plink --species --bfile source --recode A --out target
cat target.raw | pathto/raw2gt target.frq > target.gt
```
See also the function `prepare_gt_from_plink_files`.
"""
function read_gt_n_frq(gt, frq)
    subtitle("Read genotypes and frequencies")
    item("Frequency related")
    # Frequency related
    p = Float64[]
    for x in eachline(frq)
        push!(p, parse(Float64, x))
    end
    twop = p.*2.
    done()

    item("Genotypes")
    nlc = length(readline(gt))
    fsz = stat(gt).size
    lsz = nlc + 1               # assuming Unix text format
    nid = Int(fsz/lsz)
    if(nid*lsz ≠ fsz)
        warning("Not a square file")
        return
    end
    message("NID: $nid;\tN_loci: $nlc")
    z = Array{Float64, 2}(undef, nlc, nid) # one column per ID
    fgt = open(gt, "r")
    for j in 1:nid
        t = read(fgt, lsz)
        for i in 1:nlc
            z[i, j] = Float64(t[i] - 0x30) # 0x30 == '0'
        end
    end
    close(fgt)
    return p, twop, z
end


"""
    vanRaden(Z::Array{Float64, 2}, twop)
---
This function calculate **`G`** with van Raden 2008 on genotype **`Z`**.
method I.  Note **`Z`** here is ID column majored.

`G = Z`Z/2Σp_i(1-p_i)`

where **`Z`** contains the marker genotypes for all animals at all loci, corrected for 
the allele frequency per locus, and `p_i` is the frequency of the allele at locus 
*i* coded with the highest integer value.  **`Z`** is derived from the genotypes of the 
animals by subtracting 2 times the allele frequency, that is `2p_i`, from matrix 
**`X`**, which specifies the marker genotypes for each individual as 0, 1 or 2. Values 
for `p_i` are calculated from the data (default), or can be specified in a file by 
the user.

Pass copy(GT) to this function to avoid GT matrix modification.
"""
function vanRaden(Z::Array{Float64, 2}, twop::Array{Float64, 1})
    title("Calculate G with vanRaden method I")
    BLAS.set_num_threads(_nthreads)
    Z .-= twop
    s2pq = (1 .- .5 .* twop)'twop
    r2pq = 1. / s2pq
    G = Z'Z .* r2pq
end


"""
    compute_G(target, src...)
---
Given the `plink` file sets `src`.{bed,bim,fam}, this function calculate a **G**
matrix in 3 columns, i.e.,

- `raw col element-value`

and store the elements in `target`

This funciton utilizes Julia splatting.  You can input as many datasets as you have to
feed the funciton.
"""
function compute_G(target, src...; add_diag=0.)
    title("Compute G with $src")
    item("Check if files available and qualified")
    nlc = Int[]
    for i in src
        if !isfile("$i.bim")
            warning("$i not available")
            return
        end
        push!(nlc, countlines("$i.bim"))
    end
    for n in nlc[2:end]
        if n ≠ nlc[1]
            warning("Files are different")
            return
        end
    end
    pathto, out = splitdir(target)
    if length(pathto) == 0
        warning("Writing G matrix in the current directory")
    else
        isdir(pathto) || mkdir(pathto)
    end
    done()

    item("Merging $src")
    tmp = mktempdir(".")
    write("$tmp/merge.lst", join(src, '\n'), '\n')
    run(`$plink --sheep --merge-list $tmp/merge.lst --out $tmp/plink`)
    ID = begin
        tv = String[]
        for line in eachline("$tmp/plink.fam")
            id = split(line)[2]
            push!(tv, id)
        end
        tv
    end
    run(`$plink --sheep --bfile $tmp/plink --recode A --out $tmp/plink`)
    run(pipeline("$tmp/plink.raw", `$bin_dir/raw2gt $tmp/plink.frq`, "$tmp/plink.gt"))
    _, twop, z = read_gt_n_frq("$tmp/plink.gt", "$tmp/plink.frq")
    
    done()
    
    item("Calculate $target")
    message("Using $_nthreads threads")
    G = vanRaden(z, vec(twop))
    open(target, "w") do io
        for i in 1:length(ID)
            for j in 1:i-1
                println(io, ID[i], ' ', ID[j], ' ', G[i, j])
            end
            println(io, ID[i], ' ', ID[i], ' ', G[i, i] + add_diag)
        end
    end
    done()
    
    rm(tmp, recursive=true, force=true)
end
