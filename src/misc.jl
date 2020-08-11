"""
    check_map(ref, cur)
---
Check the SNP in map `cur` have the same chromosome and base pair position.
"""
function check_map(ref, cur)
    title("Check maps if same")
    if !isfile(ref) || !isfile(cur)
        warning("File $ref or $cur doesn't exist")
        return
    end
    dic = Dict()
    for line in eachline(ref)
        snp, chr, bp = split(line)
        push!(dic, snp=>(chr, bp))
    end
    for line in eachline(cur)
        snp, chr, bp = split(line)
        if haskey(dic, snp)
            if dic[snp] != (chr, bp)
                warning("The two maps are different")
                return false
            end
        end
    end
    
    return true
end

"""
    update_map(cur, ref)
---
Update SNP map locate in `cur` with info from `ref`.  If a SNP is only in `cur`, keep its info.  Results are written to `out`.
"""
function update_map(cur, ref, out)
    title("Update map $cur with $ref")
    if !isfile(ref) || !isfile(cur)
        warning("File $ref or $cur doesn't exist")
        return
    end

    dic = Dict()
    for line in eachline(ref)
        snp, chr, bp = split(line)
        push!(dic, snp=>(chr, bp))
    end

    tmp = mktempdir(".")
    open("$tmp/t.map", "w") do io
        for line in eachline(cur)
            snp, chr, bp = split(line)
            if haskey(dic, snp)
                chr, bp = dic[snp]
            end
            println(io, join([snp, chr, bp], '\t'))
        end
    end
    run(pipeline("$tmp/t.map", `sort -nk2 -nk3`, out))
    done()
end

