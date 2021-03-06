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
    run(`java -jar $beagle gt=$tmp/mid.vcf.gz ne=$nsNe out=$ref`)
    rm(tmp, recursive=true, force=true)
    done()

    item("Convert to plink format")
    run(`$plink --sheep --make-bed --vcf $ref.vcf.gz --out $ref`)
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
    if !isfile("$ref.vcf.gz")
        warning("Reference $ref.vcf.gz is not ready")
        return
    end
    pathto, target = splitdir(out)
    if(length(pathto) == 0)
        warning("Creating target in the current directory")
    else
        isdir(pathto) || mkdir(pathto)
    end
    done()

    item("Prepare $cur and remove extra SNP in $cur")
    tmp = mktempdir(".")
    snpset(file) = begin
        snp = String[]
        for line in eachline(file)
            s = split(line)[2]
            push!(snp, s)
        end
        Set(snp)
    end
    refsnp = snpset("$ref.bim")
    cursnp = snpset("$cur.bim")
    exclude = setdiff(cursnp, refsnp)
    write("$tmp/exclude.snp", join(exclude, '\n'), '\n')
    run(`$plink --sheep --bfile $cur --exclude $tmp/exclude.snp --recode vcf-iid bgz --out $tmp/mid`)
    done()

    item("Impute $cur with $ref")
    run(`java -jar $beagle ne=$nsNe ref=$ref.vcf.gz gt=$tmp/mid.vcf.gz out=$out`)
    done()

    item("Convert result to plink format")
    run(`$plink --sheep --make-bed --vcf $out.vcf.gz --out $out`)
    done()
    
    rm(tmp, recursive=true, force=true)
end
