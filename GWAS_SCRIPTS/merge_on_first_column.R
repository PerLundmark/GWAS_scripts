#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Merge  files on first column, e.g. genotype raw files






# parents: scores_Dec2020.R


# Get the genotypes data:   (bash)
#    interactive -n 16 -t 6:00:00 -A sens2019016
#    extract_raw --samples samples_337482.txt --markers snps_tab1.txt --out tab1

# getwd()   #  "/castor/project/home/umenzel/Desktop/R/SCORES_DEC2020"

# list.files(pattern = ".raw")

#  [1] "extract_raw.log"  "tab1_chrom1.raw"  "tab1_chrom10.raw" "tab1_chrom11.raw" "tab1_chrom12.raw" "tab1_chrom13.raw" "tab1_chrom14.raw"
#  [8] "tab1_chrom15.raw" "tab1_chrom16.raw" "tab1_chrom17.raw" "tab1_chrom18.raw" "tab1_chrom19.raw" "tab1_chrom2.raw"  "tab1_chrom20.raw"
# [15] "tab1_chrom22.raw" "tab1_chrom3.raw"  "tab1_chrom4.raw"  "tab1_chrom5.raw"  "tab1_chrom6.raw"  "tab1_chrom7.raw"  "tab1_chrom8.raw" 
# [22] "tab1_chrom9.raw"

# ~/Desktop/R/SCORES_DEC2020 > head tab1_chrom16.raw
#
# IID      rs6600191_C  rs3751837_T  rs11642430_G  rs1421085_C  rs72802342_A  rs2925979_C  rs12920022_A
# 1255400  0            0            0             1            1             1            0
# 3262895  2            0            1             1            0             1            0
# 1343405  0            1            1             0            0             2            0
# 3538003  0            0            0             1            0             2            0
# 2597138  0.898        0            1             0            0             2            0
# 4587215  0            0            0             0            0             1            1








## +++ Call:

# pwd   #  /home/umenzel/Desktop/R/SCORES_DEC2020
# ls *.raw > test.fofn
# merge_on_first_column  test.fofn  test






## +++ Command line parameters

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 2) {
  cat("\n")
  cat("  Usage: merge_on_first_column.R  <fofn>  <outfile>\n") 
  cat("\n")
  quit("no")
}

fofn = args[1]	     # 	fofn = "test.fofn" 
outfile = args[2]    #  outfile = "test"





## +++ Load fofn

if(!file.exists(fofn))  {
  stop(paste("\n\n  ERROR (merge_on_first_column): File '", fofn, "' not found.\n\n"))
} else {
  files = read.table(fofn, header = FALSE, stringsAsFactors = FALSE)
}

files = files$V1








tag = 1

cat("\n")  
for (file in files) {

  cat(paste("  File: ", file))
  if(!file.exists(file))  {
    cat(paste("    File", file, "not found.\n")); next
  }
  df = read.table(file, header = TRUE, stringsAsFactors = FALSE)
  cat(paste("    Rows:", nrow(df), "   Columns:", ncol(df), "\n"))
   
  if(tag == 1) {  
    bigdf = df
    tag = 0	   
  } else {
    bigdf = merge(bigdf, df, by.x = 1, by.y = 1) 
  }     
}  
  
cat("\n")    
cat(paste("  Number of columns in merged array:", ncol(bigdf), "\n\n")) 
  

write.table(bigdf, file = outfile, quote = FALSE, sep = "\t", row.names = FALSE)
   
cat(paste("  Merged array saved to:", outfile, "\n\n"))



