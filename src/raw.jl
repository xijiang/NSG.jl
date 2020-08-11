"""
    make_bed(dir, lmap, sid, nf, target)
---
# Description
This function will merge the genotypes files of GSGT ver-2 format in `dir` into one
`vcf` file according linkage map `lmap`.  The sample ID in `dir` will be replaced
with animal ID according to file `sid`.  The animal ID is in the 2nd column of `sid`.
The sample ID is in `nf`th field, and not a `NA`.

# dir
In the future, put all the files from a same platform in the same folder.  This
folder should contains the genotype files of GSGT ver-2 format.  Nothing else.

# lmap
This file contains 3 columns:
1. SNP name
2. Chromsome number.  Here they 1-26 autosomes only.
3. Base pair position.

The SNP are ordered on their chromosome numbers and bp positions.

# sid
ID info file is partial flexible.  But the first six columns are fixed, namely:
1. Herdbook_number
2. AnimalID
3. BirthYear
4. BreedGroup
5. Breed
6. Gender

In the future, when new platform arrives, just append another column, indicating
which ID are genotyped on this platform.  The current platforms are:
7. SampleID_LD
8. SampleID_HD
9. SampleID_17Kbeta
10. SampleID_17K
11. SampleID_17Kgamma

# Example
    NSG.make_bed("dat/raw/a17k", "dat/maps/a17k.map", "dat/idinfo/id.info", 10, "dat/plink/a17k")

Above will merge all the files in `dat/raw/a17k` into `dat/plink/a17k.{bed,bim,fam}`.
"""
function make_bed(dir, lmap, sid, nf, target)
    title("Merge files in $dir into $target.bed")
    item("Check parameters")
    if !isdir(dir)
        warning("$dir doesn't exist")
        return
    end

    dir = abspath(dir)
    files = readdir(dir, join=true)
    if length(files) == 0
        warning("No file in $dir")
    end
    
    if !isfile(lmap)
        warning("Map $lmap doesn't exist")
        return
    end
    lmap = abspath(lmap)

    if !isfile(sid)
        warning("ID description $sid doesn't exist")
        return
    end

    target =  begin
        pt, target = splitdir(target)
        if length(pt) == 0
            warning("You are saving the bed files in the current dir")
            pt = pwd()
        else
            pt = abspath(pt)
            isdir(pt) || mkpath(pt)
        end
        joinpath(pt, target)
    end

    done("OK")
    
    item("Create an ID reference")
    tmp = mktempdir(".")
    open(joinpath(tmp, "id.txt"), "w") do io
        buffer = readlines(sid)[2:end] # read in all ID descriptions and skip header
        for line in buffer
            id, nm, yr, brd = split(line)[[2, nf, 3, 5]]
            yr = parse(Int, yr)
            if nm ≠ "NA" && brd=="10" && yr > 1999
                println(io, "$nm $id")
            end
        end
    end
    done()

    item("Create beagle files")
    cd(tmp)
    run(`$bin_dir/mrg2bgl id.txt $lmap $files`)
    done()

    item("Create VCF files")
    for chr in 1:26
        run(pipeline(`java -jar $bin_dir/beagle2vcf.jar $chr $chr.mrk $chr.bgl -`,
                     "$chr.vcf"))
    end

    mv("1.vcf", "ori.vcf")
    open("ori.vcf", "a") do io
        for chr in 2:26
            for line in eachline("$chr.vcf")
                line[1] ≠ '#' && println(io, line)
            end
        end
    end
    done()

    item("Make $target.bed")
    _ = read(run(`$plink --sheep --vcf ori.vcf --const-fid --out $target`), String)
    cd("..")
    rm(tmp, recursive=true, force=true)
    done()
end


"""
    id_desc(raw, tgt)
---
This funciton is to simplify ID descriptions in `raw` to `tgt`.

# Descriptions

## Originally, the genotyped ID were described as below:
  1. Herdbook_number
  2. AnimalID
  3. SampleID_LD
  4. SampleID_HD
  5. SampleID_17Kbeta
  6. SampleID_17K
  7. BirthYear
  8. BreedGroup
  9. Breed
  10. Gender
  11. SampleID_17Kgamma

## New descriptions will be:

  1. `HBN` => Herdbook_number
  2. `ID` => AnimalID
  3. `SID` => SampleID
  4. `PF` => Platform, e.g, LD, a17k, b17k, c17k and so on
  5. `YoB` => BirthYear
  6. `Group` => BreedGroup
  7. `Breed` => Breed
  8. `Sex` => Gender

In the future, descriptions of new genotyped ID will just simply append to the previous one.
If an ID were genotyped on more than one platforms, then the PF field can be "LDHD".

**OBS!: dropped, as an ID may have more than one `SID`, as well as more than one `PF`.**
"""
function id_desc(raw, tgt)
    # dic = Dict(3=>"LD", 4=>"HD", 5=>"b17k", 6=>"a17k", 11=>"c17k")
    # open(tgt, "w") do oo
    #     println(oo, "HBN ID SID PF YoB Group Breed Sex")
    #     open(raw, "r") do ii
    #         _ = readline(raw)   # skip the header
    #         for line in eachline(ii)
    #             rcd = split(line)
    #             pf = ""
    #             for i in [3, 4, 5, 6, 11]
    #                 rcd[i] ≠ "NA" && (pf*=dic[i])
    #             end
    #             println(oo, join([rcd[1, 2], 
end
