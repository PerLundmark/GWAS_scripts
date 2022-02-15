#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Get a random sample of participants
#     parents: filter_samples.R 






## +++ Call:


## PGEN:    
# random_samples ukb_imp_v3_chr19.psam  10000  sampled.txt  

# BED:
# random_samples  FTD_chr22.fam  50000 s50000.txt  

# RAW, 2 columns:
# random_samples  filter_input.txt  1000  s1000.txt

# RAW, 1 column:
# random_samples  filter_in_one.txt  10000  choose10000.txt



 




## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)   # args = c("ukb_imp_v3_chr19.psam", 10000, "filtered.txt")   

if(length(args) != 3) {
  cat("\n")
  cat("  Usage: random_samples   <infile>   <number>  <outfile> \n\n") 
  cat("         <infile>:  Input file with sample ID's (.psam, .fam or raw text file with 1 or 2 columns)\n") 
  cat("         <number>:  Number of random participants to fetch \n")
  cat("         <outfile>: Output file name \n\n") 
  quit("no")
}

infile = args[1]    
number = as.integer(args[2]) 
outfile = args[3]  









## +++ Infiles & outfiles  

if(!file.exists(infile)) {
  cat(paste("\n  ERROR (random_samples.R): File", infile, "not found.\n\n")) 
  quit("no")
} 


if(file.exists(outfile)) {
  cat(paste("\n  File", outfile, "already exists.\n")) 
  cat("  Delete the existing file or choose another outfile name.\n\n")
  quit("no")
} 









## +++ Load infile  (to sample from)   


# allow .psam, .fam format (PGEN or BED folders) , and raw data   


## BED:
#
# head FTD_chr22.fam
# 
# 5954653	5954653	0	0	1	-9
# 1737609	1737609	0	0	2	-9
# 1427013	1427013	0	0	2	-9
# 3443403	3443403	0	0	2	-9
# 5807741	5807741	0	0	2	-9
# 1821438	1821438	0	0	2	-9
# 3951387	3951387	0	0	2	-9


## PGEN:
# 
# head MF_chr15.psam
# 
# #FID	IID	SEX
# 1255400	1255400	2
# 3262895	3262895	2
# 1343405	1343405	1
# 3538003	3538003	1
# 4587215	4587215	1
# 2495030	2495030	1
# 4342109	4342109	2
# 2339751	2339751	2


## RAW:
# 
# head filter_input.txt  (or even with one column only) 
# 
# 5954653	5954653
# 1737609	1737609
# 1427013	1427013
# 3443403	3443403
# 5807741	5807741
# 4188953	4188953
# 1821438	1821438




# + Detect input file format:


## PGEN:
# 
# infile = "/proj/sens2019016/GWAS_TEST/ukb_imp_v3_chr19.psam"
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)  # commemt.char = "" NOT used, so that 1st line is stripped! 
# line1
#        V1      V2 V3
# 1 5954653 5954653  1


## BED:
#
# infile = "/proj/sens2019016/GWAS_TEST/FTD_chr22.fam" 
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)  
# line1
#        V1      V2 V3 V4 V5 V6
# 1 1001779 1001779  0  0  1 -9


## RAW, 2 columns:
#
# infile = "/proj/sens2019016/GWAS_TEST/filter_input.txt"
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)
#  line1
#        V1      V2
# 1 5954653 5954653



## RAW, 1 column: 
#
# infile = "/proj/sens2019016/GWAS_TEST/filter_in_one.txt" 
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)
#        V1
# 1 5954653


line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)

if(ncol(line1) == 3) {  # .psam ?   
  cat("\n  Input file is probably a .psam file.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  input_samples = indata[,2]  # IID
  if(class(input_samples) != "integer") {
    cat(paste("\n  ERROR (random_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(input_samples)
    cat("\n\n")
    quit("no")
  } 
}

if(ncol(line1) == 6) {  # .fam ?   
  cat("\n  Input file is probably a .fam file.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  input_samples = indata[,2]  # V2
  if(class(input_samples) != "integer") {
    cat(paste("\n  ERROR (random_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(input_samples)
    cat("\n\n")
    quit("no")
  } 
}

if(ncol(line1) == 2) {  #   RAW, 2 columns ?   
  cat("\n  Input file is probably a raw file with 2 columns.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  input_samples = indata[,2]  # V2
  if(class(input_samples) != "integer") {
    cat(paste("\n  ERROR (random_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(input_samples)
    cat("\n\n")
    quit("no")
  } 
}

if(ncol(line1) == 1) {  #   RAW, 1 column ?   
  cat("\n  Input file is probably a raw file with 1 column.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  input_samples = indata[,1]  # V1
  if(class(input_samples) != "integer") {
    cat(paste("\n  ERROR (random_samples.R): The 1st column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(input_samples)
    cat("\n\n")
    quit("no")
  } 
}

  
cat(paste("  The input list contains", length(input_samples), "participants.\n\n"))
 
if(number >= length(input_samples)) {
  cat("  The number of samples to fetch is bigger than the number of samples in the input file.\n\n")  
  quit("no")
} 







## +++ Take random sample and save 

rsample = sample(input_samples, number)   # defaults to replace = FALSE

# str(rsample)   #   int [1:10000] 3241755 2710480 2899051 2513462 5607048 3721872 2111611 2279294 3049117 5532279 ...
# length(rsample) # 10000   


outframe = data.frame(FID = rsample, IID = rsample)  

# str(outframe)
# 'data.frame':	10000 obs. of  2 variables:
#  $ FID: int  3241755 2710480 2899051 2513462 5607048 3721872 2111611 2279294 3049117 5532279 ...
#  $ IID: int  3241755 2710480 2899051 2513462 5607048 3721872 2111611 2279294 3049117 5532279 ...


# head(outframe)
#
#       FID     IID
# 1 3241755 3241755
# 2 2710480 2710480
# 3 2899051 2899051
# 4 2513462 2513462
# 5 5607048 5607048
# 6 3721872 3721872


write.table(outframe, file = outfile, col.names = FALSE, quote = FALSE, sep = "\t", row.names = FALSE)

# head filtered.txt
# 
# 3241755	3241755
# 2710480	2710480
# 2899051	2899051
# 2513462	2513462
# 5607048	5607048
# 3721872	3721872
# 2111611	2111611


cat(paste("  Output saved to:", outfile, "\n\n")) 
cat("  Use the program 'extract_samples' to obtain a genotype dataset based on the obtained samples.\n\n")
quit("no")  # uwe.menzel@medsci.uu.se   









