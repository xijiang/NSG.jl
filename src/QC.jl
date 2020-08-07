"""
    QC(from, to; geno = 0.1, maf = 0.01, hwe = 0.0001, mind = 0.1)
---
Quality control of a genotype dataset in `plink` format.

# Example
    QC("pathfrom/from", "pathto/to")
This function will do a quality control of genotypes in file `from.bed`, `from.bim`,
`from.fam` in path `pathfrom`.  It will save the results in `pathto`, with stem file name as `to`.  By default, the function will remove:
- loci who has more than 10% genotypes missing
- loci of maf ≤ 0.01
- loci of P-value ≤ 0.0001
- ID who has ≥ 10% genotypes missing
"""
function QC(from, to; geno = 0.1, maf = 0.01, hwe = 0.0001, mind = 0.1)
    title("Quality control of genotype set $from")
    item("Parameter check")
    if !isfile(from * ".bed")
        warning("!!! Warning: $from files don't exist")
        return
    end
    pathto, target = splitdir(to)
    if length(pathto) == 0
        warning("!!! Warning: target file in current folder")
    else
        isdir(pathto) || mkdir(pathto)
    end

    item("Filter ID and SNP")
    _ = read(`plink  --sheep
			--bfile $from
			--geno $geno
			--maf $maf
			--hwe $hwe
			--mind $mind
			--make-bed
			--out $to`,
                String)
    done()

    item("Summary")
    obtain_set(file) = begin
        tv = String[]
        for line in eachline(file)
            str = split(line)[2]
            push!(tv, str)
        end
        Set(tv)
    end
    fsnp, tsnp = obtain_set("$from.bim"), obtain_set("$to.bim")
    diff = setdiff(fsnp, tsnp)
    if length(diff) > 0
        println(join(diff, ' '))
        msg = "Above " * string(length(diff)) * " SNP were removed"
        warning("!!! Warning: $msg")
    else
        message("No SNP were removed")
    end
    fid, tid = obtain_set("$from.fam"), obtain_set("$to.fam")
    diff = setdiff(fid, tid)
    if length(diff) > 0
        println(join(diff, ' '))
        msg = "Above " * string(length(diff)) * " ID were removed"
        warning("!!! Warning: $msg")
    else
        message("No ID were removed")
    end
    done()
end
