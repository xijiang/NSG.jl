"""
    make_ref(src, ref)
---
With plink file `src.{bed,bim,fam}`, this function:
1. imputes the few missing genotypes in this dataset
2. phasing is also done by `beagle.jar`
3. write results to `ref.{bed,bim,fam}`
"""
function make_ref(src, ref)
    title("Make imputation reference")
    item("Check parameters")
    if !isfile(src * ".bed")
        warning("$src.bed doesn't exist")
        return
    end
    pathto, target = splitdir(ref)
    if length(pathto) == 0
        warning("Creating training dataset in the current directory")
    else
        isdir(pathto) || mkdir(pathto)
    end
    done()

    item("Create reference")
    tmp = mktempdir(".")
    run(`$plink --sheep --bfile $src --recode vcf-iid bgz --out $tmp/mid`)
    run(`java -jar $beagle gt=$tmp/mid.vcf.gz ne=$nsne out=$ref`)
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
    title("Impute $cur.{bed,bim,fam} with training set $ref")
    item("Check parameters")
    if !isfile(cur * ".bed")
        warning("$cur.bed doesn't exist")
        return
    end
    pathto, target = splitdir(out)
    if(length(pathto) == 0)
        warning("Creating target in the current directory")
    else
        isdir(pathto) || mkdir(pathto)
    end
    done()

    item("Imputeing $cur")
    tmp = mktempdir(".")
    run(`$plink --sheep --bfile $cur --recode vcf-iid bgz --out $tmp/mid`)
    run(`java -jar $beagle ne=nsne ref=$ref gt=$tmp/mid/mid.vcf.gz out=$out`)
    rm(tmp, recursive=true, force=true)
    done()
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
