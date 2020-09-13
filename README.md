# Manual to NSG Julia package

* By Xijiang Yu
* 2020, Aug. 11

## Introduction
This new package for NSG was switched to Julia.  It is now more data focused.  This is a manule by example.  I suppose that you are in a directory called data.  The directories in this folder is as described in this manual.  You may change the relevant folder structure later.

* **Note**: *This package is designed Only to run on a Linux system.*

## Installation
### Install Julia
Julia is available to most Linux distributions. The latest (to date) release is version 1.5.  If the default version on your system is older than this, you can add the `nalimilan/julia` repo. Or, you can install a 0-day version:

```bash
git clone https://github.com/JuliaLang/julia
cd julia
make
mkdir -p ~/.local/bin
ln -s $PWD/usr/bin/julia ~/.local/bin/Julia
```

* **NB**, *I named this 0-day version as `Julia` to distinguish it to the official release.*

### Install NSG

```bash
Julia
```

```julia
]  # to enter the Julia package environment
add https://github.com/xijiang/NSG.jl
```

Later, when you go back to the Julia REPL, or start Julia again,

```julia
using NSG
```

to load the package.  If it is the first run, the package will download the latest `plink` and `beagle.jar`.  It also compiles my C++ codes.

When you want to check if new `plink` or `beagle.jar` is available:

```julia
NSG.Update(true)
```

### To update `NSG`

Start the `julia` REPL first. Then run:

```julia
]
update NSG
```

## Data organization
Suppose your data folder structer is as below:

```
data/
├── idinfo
├── maps
└── raw
```
and you are in the `data` directory.  The above 3 sub-folders contain the follow information:

### idinfo
* id.info
This file contains a header line. The first 6 columns are:
  1. Herdbook_number
  2. AnimalID
  3. BirthYear
  4. BreedGroup
  5. Breed
  6. Gender

Currently, the rest of the columns are:

  7. SampleID_LD
  8. SampleID_HD
  9. SampleID_17Kbeta
  10. SampleID_17K
  11. SampleID_17Kgamma
  
Later, when a new platform comes, one can add another column named after this platform.  For the ID names in this column, name it `NA` if the ID is not genotyped with platform. Name it the `sample ID name` if so.

### maps

Contains the maps for each platform.  A map file has 3 columns with no header:

1. SNP name
2. chromosome
3. Base pair position.

It is agreed only autosomes (1-26) are included. The SNP are ordered on chromosome number and BP position.

**NB**: 

- *One can manually manipulate the map, e.g., to remove duplicates.*.
- *The duplicates in the newcomer map will be removed in the imputation procedure*.

#### Make a map
You can prepare a newcomer map with one pipeline. Suppose the map came along with the newcomers has 4 columns:

1. chromosome number
2. SNP name
3. Map distance
4. Base pair position

And the filename is `newcomer.map`, then below is the command:

```bash
cat newcomer.map |
    gawk '{if($1>0 && $1<27) print $2, $1, $4}' |
    sort -nk2 -nk3 >autosome.map
```

You may want to do some small adjustment as some SNP labeled with non-autosomal is on an autosome in the reference map.

**NB**: *The SNP name is most important. Their chromosome position can be updated with reference map. It is their names that matter*.

### raw

This folder can be structured as:

```
raw
├── 8k
├── a17k
├── b17k
└── c17k
```

Each folder contains, and only contains, result files from the same platform.  It was agreed that these files are of `GSGT` `Final report matrix design` format.

## Make a reference/training set

NSG is now using the 17k-$\alpha$ version as the training set.  Suppose you are in the `data` folder:

### Start the NSG package

```bash
Julia  # to enter the Julia REPL
```

Then

```julia
using NSG    # to load this package.
```

### Merge the raw data

```julia
NSG.make_bed("raw/a17k", "maps/a17k.map", "idinfo/id.info", 10, "plk/a17k")
```

This function will merge the files in `raw/a17k` into `plk/a17k.{bed,bim,fam}`.  The arguments for this function are:

- **raw/a17k**: the folder contains the result files from 17k-$\alpha$ platform.
- **maps/a17k.map**: the autosome SNP map for this platform.
- **idinfo/id.info**: see above about its description. 
- **10**: column number about whether an ID was genotyped with this plotform.
- **plk/a17k**: base name of the result files.

### Quality control of the merged data

```julia
NSG.QC("plk/a17k", "tmp/a17k")
```
The above function will do the quality control of dataset `plk/a17k` with the following 4 standards:

- **geno=0.1**: SNP with more than 10% missing
- **maf=0.01**: SNP with MAF less than 0.01
- **hwe=0.0001**: SNP with Hardy-Weinberg equillibrium $p$-value<1e-4.
- **mind=0.1**: ID with more than 10% genotypes missing

If you want to some other standard, you can run, for example:
```julia
NSG.QC("plk/a17k", "tmp/a17k", hwe=1e-10)
```

**NB**: folder `tmp` will be created if it is not there.

### Phase and impute the few missing genotypes to make a reference

```julia
NSG.make_ref("tmp/a17k", "ref/a17k")
```

- `ref/a17k.vcf.gz` will be made ready as a training set for future imputations.
- `ref/a17k.{bed,bim,fam}` will also be created for later merging purpose.

**NB**: 

- *In the future, if you want to make data from an other platform to serve as a training set, you can do similar as above.*
- *You can name `tmp` as `qcd`, i.e., quality controled, to make it more reasonable.*

## Dealing with newcomers
Make sure that newcomers fulfill the following conditions:

- They were from a same platform
- They, and only they, are in a same folder
- They should be of the same format: i.e., GSGT 2.0+.
- Their autosome linkage map of format mentioned above is ready.
  - Manual delete duplicates if necessary.
  - The shared SNP between maps should betterhave the same chromosome number and base pair position.  Or a warning message is shown. The new map will be updated with reference map.

Let's suppose the files are in `raw/c17k` of our current `data` folder.

```julia
NSG.check_map("maps/a17k.map", "maps/c17k.map")
# if the result is false
NSG.update_map("maps/c17k.map", "maps/a17k.map", "maps/c17k-new.map")

NSG.make_bed("raw/c17k", "maps/c17k-new.map", "idinfo/id.info", 11, "plk/c17k")
NSG.QC("plk/c17k", "tmp/c17k", hwe=1e-10)
NSG.impute("tmp/c17k", "ref/a17k", "new/c17k") #using a17k.vcf.gz as ref.
```

**NB**:

- One can insert other QC measures before `NSG.impute()`.
- In the `NSG.impute()` procedure, extra SNP in `tmp/c17k` were removed to make `beagle.jar` imputation possible.

## Calculate G-matrix from several datasets

Up to now, we have two file sets:

- `ref/a17k`
- `new/c17k`

Similarily, we can have

- `new/8k`
- `new/d17k`
- $\cdots$

We can calculate a matrix with these files.

```julia
NSG.compute_G("G/result.G", "ref/a17k", "new/c17k", add_diag=0.)
```
Above function will merge dataset `ref/a17k`, `new/c17k` and then calculate a **G** matrix into `G/result.G`. This is a 3-column file which can be used in `dmu`. No value, by default, is added to the diagonals. You can specify one by letting `add_diag=1e-6`, for example.

## Appendices

### Automation of above procedure
You can put some above functions in one `julia` file to automize a pipeline. For example, you can create file `ref.jl`:

```julia
# using NSG # if the package was not loaded
NSG.make_bed("raw/a17k", "maps/a17k.map", "idinfo/id.info", 10, "plk/a17k")
NSG.QC("plk/a17k", "tmp/a17k")
NSG.make_ref("tmp/a17k", "ref/a17k")
```

Then in the Julia REPL:

```julia
include("ref.jl")
```

All above commands will run in a pipe.

You can do similar on the **G** computation procedure.

### Speed up G calculation
This package use 8 threads by default to calculate **G**. If your computer has more threads availabe, e.g., 12, run:

```julia
NSG.set_nthreads(12)
```

before calling `NSG.compute_G`.

### $N_e$
Currently the $N_e$ for imputation is set as 100. You can change it to, say, 120:

```julia
NSG.set_ne(120)
```

before the imputation procedure.

### Other issues
- other quality control measures
  - maybe added later