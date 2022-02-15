#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Summarize the GWAS results (no html, lite version)    






# +++ Calling:
#
# this script is called by "recap_gwas.sh":   
#
#     recap_gwas.R   ${ident}  ${pheno}  ${cstart}  ${cstop}  ${pval}  ${file_list}
#
#  no SLURM 






## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     # print(args)


if(length(args) < 6) {
  cat("\n")
  cat("  Usage: recap_gwas.R  <jobid>  <phenoname>  <from_chr>  <to_chrom>  <pval>  <file> \n")  
  cat("  Example: recap_gwas.R  LIV6  1 22  5e-8  LIV_MULT5_liv2_liv8_liv7_files.txt\n")
  cat("\n")
  quit("no")
}

ident = args[1]   
phenoname = args[2]  
cstart = as.integer(args[3])      
cstop = as.integer(args[4]) 
pval = as.numeric(args[5])
file_list = as.character(args[6])   # create a list containing the names of all important output files for this phenotype

chromosomes = seq(cstart, cstop) 
important_files = list()  # write these files to "file_list"





## +++ Libraries, Functions, Auxiliary functions: 

suppressWarnings(library(WriteXLS))
suppressWarnings(library(data.table))






## +++ Read GWAS parameters: 

parfile = paste(ident, "_gwas_params.txt", sep="")   #  paramfile="${ident}_gwas_params.txt"  (run_gwas.sh)  
if(!file.exists(parfile)) stop(paste("\n\n  ERROR (recap_gwas.R) : Could not find the GWAS parameter file: '", parfile, "'.\n\n"))
system(paste("touch", parfile))
 
# > cat LIV_MULT3_gwas_params.txt
#
# plink2_version plink2/2.00-alpha-2-20190429
# workfolder /proj/sens2019xxx/GWAS_TEST/LIV_MULT3
# ident LIV_MULT3
# cstart 1
# cstop 22
# genotype_id  MF
# pgen_prefix /proj/sens2019xxx/GENOTYPES/PGEN/MF_chr22
# phenofile liver_fat_faked.txt
# phenoname liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10
# covarfile GWAS_covariates.txt
# covarname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age
# mac 30
# hwe_pval 1.0e-6
# machr2_low 0.8
# machr2_high 2.0
# cojo_out liv1 LIV_MULT3_liv1_cojo.jma
# cojo_out liv3 LIV_MULT3_liv3_cojo.jma
# clump_out liv2 LIV_MULT4_liv2_clump.jma
# clump_out liv3 LIV_MULT4_liv3_clump.jma
# clump_out liv9 LIV_MULT4_liv9_clump.jma


parameters = readLines(parfile)
parameters = strsplit(parameters, "\\s+") 

# entries with 3 columns:  OBS!: these variables might not exist!
to_assign = c("cojo_out", "clump_out")
for (var in to_assign) {
  rows = parameters[grep(var, parameters)]   # list that might be empty 
  if(length(rows) > 0) for (i in 1:length(rows)) if(rows[[i]][1] == var & rows[[i]][2] == phenoname) assign(var, rows[[i]][3])  
}

# cojo_out   # "LIV_MULT4_liv2_cojo.jma"   or non-existing  
# clump_out  # "LIV_MULT4_liv2_clump.jma"  or non-existing   



 


cat(paste("\n  Phenotype name:", phenoname, "\n"))


if(exists("cojo_out")) {
  # cat("    Cojo was conducted. Loading results ...\n")  # collect the files  ${ident}_${phenoname}_cojo.jma   e.g. LIV_MULT5_liv10_cojo.jma
  cojo_file = paste0(ident, "_", phenoname, "_cojo.jma")
  if(file.exists(cojo_file)) {
    cojo_frame = read.table(cojo_file, header = TRUE, stringsAsFactors = FALSE)
    cat(paste0("    Cojo results: ", cojo_file, " (", nrow(cojo_frame), " markers)\n"))
    system(paste("touch", cojo_file))
    important_files = append(important_files, cojo_file)   
  } else {
    stop(paste("\n\n  ERROR (recap_gwas.R) : Could not find cojo results: '", cojo_file, "'.\n\n")) 
  } 
} # if(exists("cojo_out"))


if(exists("clump_out")) {
  # cat("    Clump was conducted. Loading results ...\n")  # collect the files  ${ident}_${phenoname}_clump.jma  e.g. LIV_MULT5_liv5_clump.jma
  			  # ID	 CHR	POS	OTHER	A1	A1_FREQ	OBS_CT	BETA	SE	P
  clump_file = paste0(ident, "_", phenoname, "_clump.jma")
  if(file.exists(clump_file)) {
    clump_frame = read.table(clump_file, header = TRUE, stringsAsFactors = FALSE)
    cat(paste0("    Clump results: ", clump_file, " (", nrow(clump_frame), " markers)\n"))
    system(paste("touch", clump_file))
    important_files = append(important_files, clump_file)   
  } else {
    stop(paste("\n\n  ERROR (recap_gwas.R) : Could not find clump results: '", clump_file, "'.\n\n")) 
  } 
} # if(exists("clump_out"))


if(!exists("clump_out") & !exists("cojo_out")) { 
  cat("    No pruning was conducted. Collecting significant markers ...\n")  # extract sign. SNPs from ${ident}_gwas_chr*.${phenoname}.glm.linear
  signif_frame = data.frame(CHROM = integer(), POS = integer(), ID = character(), REF = character(), ALT1 = character(), A1 = character(), 
		    A1_FREQ = numeric(), OBS_CT = integer(),  BETA = numeric(), SE = numeric(), P = numeric(), stringsAsFactors = FALSE) 
  
  cat(paste("    Chromosome: "))
  for (chr in chromosomes)  {
    regression_output = paste0(ident, "_gwas_chr", chr, ".", phenoname, ".glm.linear" )  # name determined in "gwas_chr.sh"    
    if(!file.exists(regression_output)) stop(paste("\n\n  ERROR (recap_gwas.R) : Could not find the GWAS regression results: '", regression_output, "'.\n\n")) 
    # signif_frame_chr = fread(regression_output, nThread = 16, header = TRUE, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE)
    cmd = paste0("awk -v p=", pval, " '{if($NF <= p) {print $0}}' ", regression_output) # "awk -v p=5e-08 '{if($NF < p) {print $0}}'LIV_MULT5_gwas_chr22.liv10.glm.linear" 
    signif_frame_chr = suppressWarnings(fread(cmd = cmd, nThread = 16, header = TRUE, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE)) 
    signif_frame = rbind(signif_frame, signif_frame_chr, use.names = FALSE)  #  use.names = FALSE to avoid conflict between CHROM and #CHROM (1st element of column names) 
    # might be empty if no sign. markers on this chromosome 
    cat(paste(chr, " "))
  }
  
  other_allele = ifelse(signif_frame$A1 == signif_frame$REF, signif_frame$ALT1, signif_frame$REF) 
  signif_frame = cbind(signif_frame, other_allele)     
  signif_frame = as.data.frame(signif_frame[,c(3,1,2,12,6,7,8,9,10,11)])    
  colnames(signif_frame) = c("ID", "CHR", "POS", "OTHER", "A1", "A1_FREQ", "OBS_CT", "BETA", "SE", "P")    
  signif_file = paste0(ident, "_", phenoname, "_unpruned.jma")  # "LIV_MULT5_liv10_unpruned.jma"
  write.table(signif_frame, file = signif_file, quote = FALSE, sep = "\t", row.names = FALSE) # same format as cojo and clump results
  cat(paste0("\n    Significant markers: ", signif_file, " (", nrow(signif_frame), " markers)\n"))
  important_files = append(important_files, signif_file) 
  
} # if(!exists("clump_out") & !exists("cojo_out"))


# These warning messages have been suppressed in the fread command: 
#
# Warning messages:
# 1: In fread(cmd = cmd, nThread = 16, header = TRUE, check.names = FALSE,  :
#   File '/scratch/RtmpSdCvdR/file5a26713e0bba' has size 0. Returning a NULL data.table.
#
#    (warning because scratch file is empty if no sign. markers on the chromosome)  



# Output files should have the same format:
#
#  head -4 LIV_MULT5_liv7_unpruned.jma LIV_MULT5_liv2_cojo.jma LIV_MULT5_liv8_clump.jma
#
# ==> LIV_MULT5_liv7_unpruned.jma <==
# ID	CHR	POS	OTHER	A1	A1_FREQ	OBS_CT	BETA	SE	P
# rs577713064_G_C	2	46305393	C	G	0.000906995	18771	4.71597	0.788018	2.20863e-09
# rs185378124_A_C	2	46310348	C	A	0.00222024	18771	2.9526	0.51766	1.18963e-08
# rs189812465_T_C	2	46310816	C	T	0.00217458	18771	2.89132	0.521636	3.01687e-08
# 
# ==> LIV_MULT5_liv2_cojo.jma <==
# ID	CHR	POS	OTHER	A1	A1_FREQ	OBS_CT	BETA	SE	P
# rs532548475_G_A	2	13807712	A	G	0.000599056	17984.6	5.44971	0.980691	2.74435e-08
# rs577713064_G_C	2	46305393	C	G	0.000906995	18368.2	4.71597	0.788764	2.24604e-09
# rs555658286_A_T	2	77127642	T	A	0.000809429	16422.9	4.83488	0.882974	4.35836e-08
# 
# ==> LIV_MULT5_liv8_clump.jma <==
# ID	CHR	POS	OTHER	A1	A1_FREQ	OBS_CT	BETA	SE	P
# rs185378124_A_C	2	46310348	C	A	0.00222024	18771	2.9526	0.51766	1.19e-08
# rs193273071_T_C	2	236592939	C	T	0.000827696	18771	4.83546	0.864479	2.26e-08
# rs532548475_G_A	2	13807712	A	G	0.000599056	18771	5.44971	0.979876	2.71e-08






## +++ Excel with unpruned or pruned global significant markers     

  
if(exists("cojo_out") & exists("clump_out")) {   	# we have clump and cojo results  
  excel_file = paste(ident, phenoname, "clump_cojo.xls", sep = "_")
  if((nrow(cojo_frame) != 0) | (nrow(clump_frame) != 0)) { 
    WriteXLS(c("cojo_frame", "clump_frame"), ExcelFileName = excel_file, SheetNames = c("cojoed", "clumped"), row.names = FALSE)
    cat(paste("    Spreadsheet:", excel_file, "\n"))
    important_files = append(important_files, excel_file)
  }
}

if(exists("cojo_out") & !exists("clump_out")) { 	# we have cojo but no clump results 
  excel_file = paste(ident, phenoname, "cojo.xls", sep = "_")
  if(nrow(cojo_frame) != 0) { 
    WriteXLS(c("cojo_frame"), ExcelFileName = excel_file, SheetNames = c("cojoed"), row.names = FALSE)
    cat(paste("    Spreadsheet:", excel_file, "\n"))
    important_files = append(important_files, excel_file)  
  }
}

if(!exists("cojo_out") & exists("clump_out")) { 	# we have clump but no cojo results 
  excel_file = paste(ident, phenoname, "clump.xls", sep = "_")
  if(nrow(clump_frame) != 0) { 
    WriteXLS(c("clump_frame"), ExcelFileName = excel_file, SheetNames = c("clumped"), row.names = FALSE)
    cat(paste("    Spreadsheet:", excel_file, "\n"))
    important_files = append(important_files, excel_file)  
  }
}

if(!exists("cojo_out") & !exists("clump_out")) { 	# we have neither clump nor cojo results
  excel_file = paste(ident, phenoname, "unpruned.xls", sep = "_") 
  if(nrow(signif_frame) != 0) {
    WriteXLS(signif_frame, ExcelFileName = excel_file, SheetNames = ident, row.names = FALSE)
    cat(paste("    Spreadsheet:", excel_file, "\n"))
    important_files = append(important_files, excel_file)   
  }         
}





## +++ Write list with important files

sink(file_list) 
for (file in important_files) cat(file, sep="\n")
sink()








