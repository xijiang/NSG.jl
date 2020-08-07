"""
    make_ref(from, to)
---
With plink file `from.{bed,bim,fam}`, this function:
1. imputes the few missing genotypes in this dataset
2. phasing is also done by `beagle.jar`
"""
function make_ref(src, ref)
    title("Make imputation reference")
    item("Check parameters")
    if !isfile(src * ".bed")
        warning("!!! Warning: $src.bed doesn't exist")
        return
    end
    pathto, target = splitdir(ref)
    if length(pathto) == 0
        warning("!!! Warning: create training dataset in current directory")
    else
        isdir(pathto) || mkdir(pathto)
    end
    done()

    item("Create reference")
    tmp = mktempdir(".")
    run(`java -jar $bin_dir/beagle.jar`)
    rm(tmp, recursive=true, force=true)
    done()
end


"""
    impute(cur, ref, out)
---
Impute `cur`.{bed,bim,fam} with reference/training set `ref`.{bed,bim,fam}, and put
the result to `out`.{bed,bim,fam}.

**Note**: SNP only in `cur` will be removed.
"""
function impute(cur, ref, out)
    message("Under construction")
end


"""
    combine(target, src...)
---
This funciton utilizes Julia splatting.  You can put as many datasets as you have to
feed the funciton.  The first argument `target` will be the target to merge into.
The rest `src` will serve as sources.  They should have the same number of SNP.

The `impute` function guarantees the newly imputed dataset has the same number of SNP
as the ref.
"""
function combine(target, src...)
    for i in src
        println(i)
    end
end
