"""
    output_gt(target, src...)
---
This is a temporary function to output the 012 genotypes and ID
names in two separate files for other programs.

The result files are `target.id` and `target.gt`.
"""
function output_gt(target, src...)
    title("Output G with $src")
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
    open("$target.id", "w") do io
        for line in eachline("$tmp/plink.fam")
            println(io, split(line)[2])
        end
    end
    run(`$plink --sheep --bfile $tmp/plink --recode A --out $tmp/plink`)
    open("$tmp/plink.raw", "r") do io
        _  = readline(io)       # skip the line of SNP names
        buffer = IOBuffer()
        nid = 0
        for line in eachline(io)
            nid += 1
            t = 1
            for _ in 1:6
                t = findnext(' ', line, t) + 1
            end
            write(buffer, replace(line[t:end], ' '=>""))
        end
        open("$target.gt", "w") do gt
            GT = reshape(take!(buffer), nid, :)
            for i in 1:size(GT)[1]
                println(gt, String(GT[i, :]))
            end
        end
    end
    rm(tmp, recursive=true, force=true)
    done()
end
