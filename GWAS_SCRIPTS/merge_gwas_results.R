#!/usr/bin/env Rscript





## +++ Concatenate all GWAS output files (*.glm.linear or *.glm.logistic) in the current folder 


# uwe.menzel@medsci.uu.se



# TEST:
# getwd()  #  "/castor/project/proj_nobackup/GWAS_TEST/liver14"
# merge_gwas_results liver_fat_a






## +++ Libraries, functions, default values 

options(stringsAsFactors = FALSE)  

library(data.table)  






## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 1) {
  cat(paste("\n\n  Usage: merge_gwas_results <phenotype name>\n\n"))    
  quit("no")
}

phenoname = args[1]	






## +++ Load output files for chromosomes

pattern = paste0(".+_gwas_chr[[:digit:]]{1,2}\\.", phenoname, "\\.glm\\.(linear|logistic)$")
gwas_results = list.files(pattern = pattern)

nr_gwas = length(gwas_results)

if(nr_gwas == 0) {
  cat(paste0("\n  ERROR: No GWAS output files for phenotype name '", phenoname, "' found.\n\n")) 
  quit("no")
} else {
  cat(paste0("\n  Number of GWAS output files for phenotype '", phenoname, "' : ", nr_gwas, "\n\n"))
}

data <- lapply(gwas_results, function(file) {fread(file, check.names = TRUE, nThread = 16, sep = "\t", showProgress = TRUE)}) 

if(length(data) != nr_gwas) {
  cat(paste("\n  ERROR: Only", length(data), "out of", nr_gwas, "chromosomes imported.\n\n")) 
  quit("no")
}






## +++ Concatenate

data <- data.table::rbindlist(data)

colnames(data)[1] = "#CHROM" 

cat(paste("\n  The merged file contains", prettyNum(nrow(data), big.mark=".", decimal.mark=","), "variants.\n\n"))   






## +++ Export merged file

sufx = ifelse(length(grep("logistic", gwas_results[1])) == 0, "linear", "logistic")  

outfile = paste0(unlist(strsplit(gwas_results[1], split = "_"))[1], "_gwas_allchr.", phenoname, ".glm.", sufx)  

fwrite(data, file = outfile, quote = FALSE, nThread = 16, showProgress = TRUE, sep = "\t")

cat(paste("  Merged file written to", outfile, ".\n\n"))   







