using Dates, HTTP
"""
    latest_beagle()
---
Return the latest beagle URL
"""
function latest_beagle()
    function later(a, b)
        mon = Dict("Jan" => 1, "Feb" => 2, "Mar" => 3,
                   "Apr" => 4, "May" => 5, "Jun" => 6,
                   "Jul" => 7, "Aug" => 8, "Sep" => 9,
                   "Oct" => 10, "Nov" => 11, "Dec" => 12, "mmm" => 0)
        da, db = a[8:9], b[8:9]
        ma, mb = mon[a[10:12]], mon[b[10:12]]
        ya, yb = a[13:14], b[13:14]
        if ya == yb
            if ma == mb
                return da > db ? a : b
            else
                return ma > mb ? a : b
            end
        else
            return ya > yb ? a : b
        end
    end

    BeagleURL = "https://faculty.washington.edu/browning/beagle/"
    # Note Beagle is not version controlled by git.
    # It seems that names for new versions are following the pattern like
    # beagle.ddMmmyy.xxx.jar
    # so I just grab all the file names in $BeagleURL
    # There also must be better way to get the URL.
    beagle = "beagle.00mmm00.xxx.jar"
    web = HTTP.request("GET", BeagleURL)
    txt = split(String(web.body), "\n")
    for line in txt
        r = match(r"beagle\.\d{2}\w{3}\d{2}.{5}jar", line)
        r == nothing || (beagle = later(beagle, r.match))
    end
    message("\tUpdating Beagle to $beagle.")
    return joinpath(BeagleURL, beagle)
end

"""
    latest_plink()
---
Return URL of the latest plink version 1 for Linux x86_64.
"""
function update_plink()
    message("\tUpdating plink to the latest")
    plinkURL = "http://s3.amazonaws.com/plink1-assets"
    latest = "plink_linux_x86_64_latest.zip"
    odir = pwd()
    cd(bin_dir)
    download(joinpath(plinkURL, latest), latest)
    run(`unzip -u $latest`)
    cd(odir)
    # using LightXML
    # Below uses "LightXML", may serve for future usage.
    # fxml = download("plinkURL")  # A tmp file store the XML result
    # xdoc = parse_file(fxml)
    # xroot = root(xdoc)
    # cnt = get_elements_by_tagname(xroot, "Contents")
    # for c in cnt
    #     t = find_element(c, "Key")
    #     f = content(t)
    # end
end

"""
    make_bins()
---
Compile Xijiang's C++ codes into binaries.
"""
function make_bins()
    bins = ["mrg2bgl"]
    for b in bins
        if !isfile(joinpath(bin_dir, b))
            print(lpad("g++ -O3 -Wall -std=c++17 $b.cpp -o $b", 60))
            run(`g++ -O3 -Wall -std=c++17 -o $bin_dir/$b $cpp_dir/$b.cpp`)
            done()
        end
    end
end

"""
    Update()
---
Every time one starts this package, the package will automatically check if `plink` and `beagle.jar` exist.
If not, the package will download the latest version of these two files.
The package will update, or download them on 17th every month anyway.
"""
function Update(force = false)
    title("Initialization")
    # Welcome and copyright message
    msg = begin
        w = 60
        a = "NSG Julia Package"
        b = repeat('=', length(a)+2)
        c = "Developed by Xijiang Yu @NMBU"
        d = "Copyright © 2020"
        join([lpad(a, w), lpad(b, w+1), lpad(c, w), lpad(d, w)], '\n')
    end
    message(msg)
    
    isdir(bin_dir) || mkdir(bin_dir)
    if Dates.day(now()) == 17 || force
        rm(beagle, force=true)
        rm(plink,  force=true)
    end
    
    subtitle("Updating the binaries")

    item("Beagle related")
    beagle2vcfURL = "https://faculty.washington.edu/browning/beagle_utilities/"
    beagle2vcf = "beagle2vcf.jar"
    
    isfile(beagle) || download(latest_beagle(), beagle)
    if !isfile(joinpath(bin_dir, beagle2vcf))
        message("\tDownloading beagle2vcf.jar")
        download(joinpath(beagle2vcfURL, beagle2vcf), joinpath(bin_dir, beagle2vcf))
    end
    done()
    
    item("plink")
    isfile(plink) || update_plink()
    done()
    
    item("C++ binaries")
    make_bins()
    done()
end
