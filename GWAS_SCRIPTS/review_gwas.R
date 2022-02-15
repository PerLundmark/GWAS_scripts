#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 


## +++ View GWAS results (html) 




## +++ Calling:
#
# this script is called by "review_gwas.sh":   
#
#   sbatch -A ${account} -p ${partition}  -t ${time}  -J ${ident} -o ${batchlog} -e ${batchlog}  \
# 	   --wrap="module load R_packages/3.6.1; review_gwas.R  ${ident}  ${phenoname}  ${cstart}  ${cstop}" 
                                        





## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)    

if(length(args) < 4) {
  cat("\n")
  cat("  Usage: review_GWAS  <jobid>  <phenoname>  <from_chr>  <to_chrom> \n")  
  cat("\n")
  quit("no")
}

ident = args[1]   
phenoname = args[2]  
cstart = as.integer(args[3])      
cstop = as.integer(args[4]) 

chromosomes = seq(cstart, cstop)  








## +++ Hardcoded settings & defaults 

setfile = "~/review_settings.R"
if(file.exists(setfile))   {
  source(setfile) 
} else {
  stop(paste("\n\n  ERROR (review_gwas.R): Settings file", setfile, "not found.\n\n"))
}







## +++ Environment variable 

scripts = Sys.getenv("SCRIPT_FOLDER") 
if ( scripts == "" ) {
  stop(paste("\n\n  ERROR (review_gwas.R): Environment variable 'SCRIPT_FOLDER' not set.\n\n"))  
} else {
  cat(paste("\n  Environment variable 'SCRIPT_FOLDER' is set to", scripts, "\n"))
}

# scripts = "/home/umenzel/bin/GWAS_SCRIPTS"






## +++ Libraries

suppressMessages(suppressWarnings(library(data.table)))   
suppressWarnings(library(WriteXLS))
suppressWarnings(library(rmarkdown))
suppressMessages(suppressWarnings(library(car)))  	# vif  
suppressMessages(suppressWarnings(library(CMplot))) 	# CMplot
# library(qqman)  # alternative for Manhattan and QQ-plot 
# setDTthreads(threads = 0)   






## +++ Auxiliary functions

review_functions = paste(scripts, "review_functions.R", sep="/")   
if(file.exists(review_functions)) {
  source(review_functions)
} else {
  stop(paste("\n\n  ERROR (review_gwas.R): File with auxiliary functions '", review_functions, "' not found.\n\n"))
}

# Gene data  derived from "UCSC_hgTables_Refseq.txt"  at https://genome.ucsc.edu/cgi-bin/hgTables   
#     used to find the nearest gene for each significant marker;  see link_nearest_gene function

gentab_file = paste(scripts, "XM_genes.RData", sep="/")
if(!file.exists(gentab_file)) stop(paste("\n\n  ERROR (review_gwas.R): File", gentab_file, "not found.\n\n"))
if(file.access(gentab_file, 4) != 0) stop(paste("\n\n  ERROR (review_gwas.R): You do not have the permissions to read the file", gentab_file, ".\n\n"))

 
get_nr_from_sentence <- function(sentence) {   # extract a number from a character vector
  if(class(sentence) != "character") stop("ERROR (get_nr_from_sentence): Sentence must be of type character.")
  if(length(sentence) != 1) {
    nr = NA 
  } else {
    vec = unlist(strsplit(sentence, " ", fixed = TRUE))   # "0" "samples"   "removed"   "due"   "to" "missing"   "genotype"  "data"  "(--mind)."
    nr = suppressWarnings(as.numeric(vec))  # contains NA
    nr = nr[!is.na(nr)]
    if(length(nr) != 1) nr = NA  # returns NA if the vector doesn't contain exactly one number
  }  
  return(nr)
}

 
 
 
 


## +++ Read GWAS parameters: 

parfile = paste(ident, "_gwas_params.txt", sep="")   #  paramfile="${ident}_gwas_params.txt"  (run_gwas.sh)  
if(!file.exists(parfile)) stop(paste("\n\n  ERROR (review_gwas.R) : Could not find the GWAS parameter file: '", parfile, "'.\n\n"))

# > cat liver10_gwas_params.txt
#
# plink2_version plink2/2.00-alpha-2-20190429
# workfolder /proj/sens2019xxx/GWAS_DEV3/liver10
# ident liver10
# cstart 1
# cstop 22
# genotype_id FTD
# phenofile liver_fat_ext.txt
# phenoname liver_fat_a
# covarfile GWAS_covariates.txt
# covarname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age
# mac 30
# maf 0.01
# vif 50
# sample_max_miss 0.1
# marker_max_miss 0.1
# hwe_pval 1.0e-6
# machr2_low 0.8
# machr2_high 2.0
# cojo_out liver_fat_a liver10_liver_fat_a_cojo.jma
# cojo_window 5000
# cojo_pval 5.0e-8
# cojo_coline 0.01    # see cojo_pheno
# cojo_refgen FTD_rand
# cojo_maf 0.01
# clump_out liver_fat_a liver10_liver_fat_a_clump.jma
# clump_p1 5e-8
# clump_p2 5e-6
# clump_r2 0.01
# clump_kb 5000
# clump_refgen FTD_rand

parameters = readLines(parfile)
parameters = strsplit(parameters, "\\s+") 





# mandatory entries with 2 columns:
to_assign = c("plink2_version", "genotype_id", "phenofile", "covarfile", "covarname", "mac", "maf", "vif", "sample_max_miss", "marker_max_miss", "hwe_pval", "machr2_low", "machr2_high")
for (var in to_assign) {
  row = unlist(parameters[grep(var, parameters)]) 
  if(length(row) == 0) stop(paste("\n\n  ERROR (review_gwas.R): The mandatory entry '", var, "' is missing in the parameter file '", parfile, "'.\n\n")) 
  assign(row[1], row[2])
}

# optional entries with 3 columns:  OBS!: these variables might not exist (if cojo or clump hasn't been run)!
to_assign = c("cojo_out", "clump_out")
for (var in to_assign) {
  rows = parameters[grep(var, parameters)]   # list that might be empty 
  if(length(rows) > 0) for (i in 1:length(rows)) if(rows[[i]][1] == var & rows[[i]][2] == phenoname) assign(var, rows[[i]][3])  
}

# optional entries with 2 columns:  OBS!: these variables might not exist (if cojo or clump hasn't been run)!
to_assign = c("clump_p1", "clump_p2", "clump_r2", "clump_kb", "cojo_window", "cojo_pval", "cojo_coline", "cojo_refgen", "cojo_maf", "clump_refgen")
for (var in to_assign) {
  row = unlist(parameters[grep(var, parameters)])   # list might be empty 
  if(length(row) > 0) assign(row[1], row[2])  
}

 



# Rmarkdown templates :

rmd = "gwas_report.Rmd"
rmd_source = paste(scripts, rmd, sep = "/")
rmd_main = paste(getwd(), rmd, sep = "/")
if(!file.exists(rmd_source)) stop(paste("\n\n  ERROR (review_gwas.R): Rmarkdown template",  rmd_source,  "not found.\n\n"))
cat(paste("  Copying", rmd, "\n")) 
if(!file.copy(rmd_source, rmd_main, overwrite = TRUE)) stop(paste("\n\n  ERROR (review_gwas.R): Could not copy file", rmd, "to the current folder.\n\n"))

rmdfiles = c("table_signif.Rmd", "table_cojoed.Rmd", "table_clumped.Rmd", "comparison_plink_clump.Rmd", "table_unpruned.Rmd")
for (rmd in rmdfiles) {
  rmd_source = paste(scripts, rmd, sep = "/")
  rmd_target = paste(getwd(), rmd, sep = "/")
  if(!file.exists(rmd_source)) stop(paste("\n\n  ERROR (review_gwas.R): Rmarkdown template", rmd_source, "not found.\n\n"))
  cat(paste("  Copying", rmd, "\n")) 
  if(!file.copy(rmd_source, rmd_target, overwrite = TRUE)) stop(paste("\n\n  ERROR (review_gwas.R): Could not copy file", rmd, "to the current folder.\n\n"))
}
cat("\n")





## Check if the variables are defined:

vars = c("p_threshold", "bandwidth", "annotation", "colvec", "max_xls", "ident", "phenoname", "cstart", "cstop") 
for (variable in vars) {
  if(!exists(variable)) stop(paste("\n\n  ERROR (review_gwas.R): Mandatory variable '", variable, "' not defined.\n\n"))  
}








## +++ Header for sbatch logfile:  ( ${log} in -e and -o option in sbatch call above )  

cat("\n")			
d = date()
cat(paste("  Date:", d, "\n"))
wd = getwd()
cat(paste("  Folder:", wd, "\n"))
pf = R.Version()$platform
cat(paste("  Platform:", pf, "\n"))
rw = R.Version()$version.string
cat(paste("  R-version:", rw, "\n\n"))
cat(paste("  GWAS JobID:", ident, "\n"))
cat(paste("  Phenotype name:", phenoname, "\n"))
cat(paste("  Considering chromosomes", cstart, "to", cstop, "\n"))
cat(paste("  Bandwidth for kernel density plot of beta:", bandwidth, "\n"))
cat(paste("  Significance threshold (p-values):", p_threshold, "\n"))
if(exists("cojo_out")) cat(paste("  GCTA-COJO output file:", cojo_out, "\n")) else cat(paste("\n  GCTA-COJO has not been conducted for phenoname", phenoname, ".\n"))
if(exists("clump_out")) cat(paste("  Clump output file:", clump_out, "\n\n")) else cat(paste("\n  Clump has not been conducted for phenoname", phenoname, ".\n\n"))
cat("\n") 




                                             
                                          
                         


## +++ Concatenate regression results for the chromosomes (all markers needed for the Manhattan plot) 

# *.glm.linear  or *.glm.logistic  
#
# #CHROM     POS	        ID	REF	ALT1	A1	A1_FREQ	       OBS_CT	    BETA	      SE	       P
# 22	16051249	rs62224609	C	T	C	0.100558	18771	-0.109309	0.0790723	0.166866
# 22	16052962	rs376238049	T	C	T	0.0897731	18771	-0.116753	0.089877	0.193948
# 22	16053862	rs62224614	T	C	T	0.101845	18771	-0.107253	0.0784808	0.171765
# 22	16054454	rs7286962	T	C	T	0.105547	18771	-0.0953407	0.0782874	0.223304
# 22	16057417	rs62224618	C	T	T	0.10154	        18771	-0.109463	0.0776205	0.158487
# 22	16439593	rs199989910	A	G	A	0.0437326	18771	-0.13938	0.125273	0.265891
#
# A1 is the minor allele used in regression, see "plink2_regression_details.txt"
# OTHER is determined in cojo_convert.sh 

# OBS!! autosomes only! chrom X,Y won't work ! 


pattern = paste0(ident, "_gwas_chr[[:digit:]]{1,2}\\.", phenoname, "\\.glm\\.(linear|logistic)$")
files_available = list.files(pattern = pattern)
if(length(files_available) != length(chromosomes)) 
	stop(paste("\n\n  ERROR (review_gwas.R) : It seems we do not have exactly one output file (.linear or .logistic) for each chromosome.\n\n")) 
regtype = ifelse(length(grep("logistic$", files_available)) == 0, "linear", "logistic")  


gwas = data.frame(CHROM = integer(), POS = integer(), ID = character(), REF = character(), ALT1 = character(), A1 = character(), 
		  A1_FREQ = numeric(), OBS_CT = integer(),  BETA = numeric(), SE = numeric(), P = numeric(), stringsAsFactors = FALSE) 
		  		  
for (chr in chromosomes)  {			      
  
  cat(paste("\n  === Collecting results for chromosome", chr, "===\n"))    
  regression_output = paste0(ident, "_gwas_chr", chr, ".", phenoname, ".glm.", regtype)   # name defined in "gwas_chr.sh" 
    
  if(!file.exists(regression_output)) stop(paste("\n\n  ERROR (review_gwas.R) : Could not find the regression results: '", regression_output, "'.\n\n")) 
  gwas_chr = fread(regression_output, nThread = 16, header = TRUE, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE)
  	
  # head(gwas_chr)  
  #
  #    #CHROM      POS          ID REF ALT1 A1   A1_FREQ OBS_CT       BETA        SE        P
  # 1      22 16051249  rs62224609   C    T  C 0.1005580  18771 -0.1093090 0.0790723 0.166866
  # 2      22 16052962 rs376238049   T    C  T 0.0897731  18771 -0.1167530 0.0898770 0.193948
  # 3      22 16053862  rs62224614   T    C  T 0.1018450  18771 -0.1072530 0.0784808 0.171765
  # 4      22 16054454   rs7286962   T    C  T 0.1055470  18771 -0.0953407 0.0782874 0.223304
  # 5      22 16057417  rs62224618   C    T  T 0.1015400  18771 -0.1094630 0.0776205 0.158487
  # 6      22 16439593 rs199989910   A    G  A 0.0437326  18771 -0.1393800 0.1252730 0.265891

  gwas = rbind(gwas, gwas_chr, use.names = FALSE)  #  use.names = FALSE to avoid conflict between CHROM and #CHROM (1st element of column names) 
     
  ## Logfile info:
  cat(paste("  Regression output:", regression_output, "\n"))  		 
  cat(paste("  Number of markers in the regression output:", nrow(gwas_chr), "\n"))
  num_NA = sum(is.na(gwas_chr$P))
  cat(paste("  Number of unassigned p-values in the regression output:", num_NA, "\n"))
  num_signif = sum(gwas_chr$P < 5.0e-8, na.rm = TRUE)	
  cat(paste("  Number of significant markers (5.0e-8) in the regression output:", num_signif, "\n")) 
}

rm(gwas_chr) 
  
# str(gwas)   #  regression results for all chromosomes, with fread (here chr22 only) 

# Classes "data.table" and 'data.frame':	193281 obs. of  11 variables:
#  $ CHROM  : int  22 22 22 22 22 22 22 22 22 22 ...
#  $ POS    : int  16051249 16052962 16053862 16054454 16057417 16439593 16440500 16441330 16441441 16442005 ...
#  $ ID     : chr  "rs62224609" "rs376238049" "rs62224614" "rs7286962" ...
#  $ REF    : chr  "C" "T" "T" "T" ...
#  $ ALT1   : chr  "T" "C" "C" "C" ...
#  $ A1     : chr  "C" "T" "T" "T" ...
#  $ A1_FREQ: num  0.1006 0.0898 0.1018 0.1055 0.1015 ...
#  $ OBS_CT : int  18771 18771 18771 18771 18771 18771 18771 18771 18771 18771 ...
#  $ BETA   : num  -0.1093 -0.1168 -0.1073 -0.0953 -0.1095 ...
#  $ SE     : num  0.0791 0.0899 0.0785 0.0783 0.0776 ...
#  $ P      : num  0.167 0.194 0.172 0.223 0.158 ...
#  - attr(*, ".internal.selfref")=<externalptr> 

# dim(gwas)     	#  14605760        8     14.6 million markers in global regression output (chromosomes 1-22)  

colnames(gwas) = c("CHROM", "POS", "ID", "REF", "ALT1", "A1", "A1_FREQ", "OBS_CT", "BETA", "SE", "P")

nr_samples = unique(gwas$OBS_CT)

cat(paste("\n\n  Total number of markers in the global regression output:", nrow(gwas), "(all chromosomes)\n"))

gwas_results = "gwas_results.RData"
save(gwas, file = gwas_results)   # debugging   use "render_review.R" 
cat(paste("  GWAS results saved to '", gwas_results, "' \n\n")) 
# du -h gwas_results.RData  #  686M	gwas_results.RData   # TOO big to save 







## +++ Find out how many samples/variants were filtered out for what reason, on each chromosome and  # see parse_logfile.R 


# SGENO   Samples removed due to missing genotype  
# VGENO   Variants removed due to missing genotype
# VHWE    Variants removed due to Hardy-Weinberg exact test
# VFREQ   Variants removed due to allele frequency threshold(s)
# VIMP    Variants removed due to imputation quality filter (mach-r2)       
       
filtered = data.frame(CHROM = integer(), SGENO = integer(), P1 = numeric(), VGENO = integer(), P2 = numeric(), VHWE = integer(), P3 = numeric(), VFREQ = integer(), P4 = numeric(),  VIMP = integer(), P5 = numeric())

for (chrom in cstart:cstop)  {
  
  cat(paste("  Identifying removed samples/variants on chromosome", chrom, "\n")) 
  
  # + Load logfile
  log = paste0(ident, "_gwas_chrom", chrom, ".log")  #   "liver10_gwas_chrom21.log"
  if(!file.exists(log)) stop(paste("\n\n  ERROR (review_gwas.R): Logfile", log, "not found.\n\n")) 
  lines <- readLines(log)  # 
  nr_lines = length(lines) 
   
  # + Find out how many variants are on this chromsome:
  variants = grep("variants loaded", lines, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  nr_variants_chrom = get_nr_from_sentence(variants)
  cat(paste("    Number of variants on this chromosome:", nr_variants_chrom, "\n"))  # 1261158 
    
  #  + Extract all lines containing "removed" from logfile
  removed = grep("removed", lines, ignore.case = FALSE, value = TRUE, fixed = TRUE) 
  # [1] "0 samples removed due to missing genotype data (--mind)."                      "--geno: 12143 variants removed due to missing genotype data."                 
  # [3] "--hwe: 354 variants removed due to Hardy-Weinberg exact test (founders only)." "2320771 variants removed due to allele frequency threshold(s)"                
  # [5] "--mach-r2-filter: 3947 variants removed."
  nr_removed = length(removed) 
   
  # + Samples:
  removed_samples = grep("samples", removed, ignore.case = FALSE, value = TRUE, fixed = TRUE)   # [1] "0 samples removed due to missing genotype data (--mind)."
  nr_removed_samples = get_nr_from_sentence(removed_samples)
  perc_removed_samples = signif(nr_removed_samples*100/nr_samples, 2)  # nr_samples known in "review_gwas.R" 
   
  # + Variants:
  removed_variants = grep("variants", removed, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  # [1] "--geno: 12143 variants removed due to missing genotype data."                  "--hwe: 354 variants removed due to Hardy-Weinberg exact test (founders only)."
  # [3] "2320771 variants removed due to allele frequency threshold(s)"                 "--mach-r2-filter: 3947 variants removed."
  
  missing_genotype = grep("genotype", removed_variants, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  # "--geno: 12143 variants removed due to missing genotype data."
  nr_missing_genotype = get_nr_from_sentence(missing_genotype)
  perc_missing_genotype = signif(nr_missing_genotype*100/nr_variants_chrom, 2)
  # cat(paste("    Variants removed due to missing genotype:", nr_missing_genotype, " (", perc_missing_genotype ,"%)\n"))     # 12143   ok 
  
  hwe_removed = grep("Weinberg", removed_variants, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  # "--hwe: 354 variants removed due to Hardy-Weinberg exact test (founders only)."
  nr_hwe_removed = get_nr_from_sentence(hwe_removed)
  perc_hwe_removed = signif(nr_hwe_removed*100/nr_variants_chrom, 2)
  # cat(paste("    Variants removed due to Hardy-Weinberg exact test:", nr_hwe_removed, " (", perc_hwe_removed ,"%)\n"))     # 354 ok  
  
  freq_removed = grep("frequency", removed_variants, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  # "2320771 variants removed due to allele frequency threshold(s)"
  nr_freq_removed = get_nr_from_sentence(freq_removed)
  perc_freq_removed = signif(nr_freq_removed*100/nr_variants_chrom, 2)
  # cat(paste("    Variants removed due to allele frequency threshold(s):", nr_freq_removed, " (", perc_freq_removed ,"%)\n"))     # 2320771  ok   
  
  machr2_removed = grep("mach-r2", removed_variants, ignore.case = FALSE, value = TRUE, fixed = TRUE)
  # "--mach-r2-filter: 3947 variants removed."  
  nr_machr2_removed = get_nr_from_sentence(machr2_removed)
  perc_machr2_removed = signif(nr_machr2_removed*100/nr_variants_chrom, 2)
  # cat(paste("    Variants removed due to mach-r2-filter:", nr_machr2_removed, " (", perc_machr2_removed ,"%)\n"))     # 3947   ok 
  
  # + add to frame
  # new_row = data.frame(CHROM = chrom, SGENO = nr_removed_samples, VGENO = nr_missing_genotype, VHWE = nr_hwe_removed, VFREQ = nr_freq_removed,  VIMP = nr_machr2_removed)
  new_row = data.frame(CHROM = chrom, SGENO = nr_removed_samples, P1 = perc_removed_samples, VGENO = nr_missing_genotype, P2 = perc_missing_genotype, 
                       VHWE = nr_hwe_removed, P3 = perc_hwe_removed, VFREQ = nr_freq_removed, P4 = perc_freq_removed,  VIMP = nr_machr2_removed, P5 = perc_machr2_removed)  
  filtered = rbind(filtered, new_row)                     
}

cat("\n")
cat(paste("  Samples removed due to missing genotype:", sum(filtered$SGENO), " (", signif(mean(filtered$P1),3) ,"%)\n")) 
cat(paste("  Variants removed due to missing genotype:", sum(filtered$VGENO), " (", signif(mean(filtered$P2),3) ,"%)\n"))     
cat(paste("  Variants removed due to Hardy-Weinberg exact test:", sum(filtered$VHWE), " (", signif(mean(filtered$P3),3) ,"%)\n"))     
cat(paste("  Variants removed due to allele frequency threshold(s):", sum(filtered$VFREQ), " (", signif(mean(filtered$P4),3) ,"%)\n"))       
cat(paste("  Variants removed due to mach-r2-filter:", sum(filtered$VIMP), " (", signif(mean(filtered$P5),3) ,"%)\n"))    
cat("\n")

new_row = data.frame(CHROM = "ALL", SGENO = sum(filtered$SGENO), P1 = signif(mean(filtered$P1),3), VGENO = sum(filtered$VGENO), 
                     P2 = signif(mean(filtered$P2),3), VHWE = sum(filtered$VHWE), P3 = signif(mean(filtered$P3),3), VFREQ = sum(filtered$VFREQ), 
                     P4 = signif(mean(filtered$P4),3), VIMP = sum(filtered$VIMP), P5 = signif(mean(filtered$P5),3))
filtered = rbind(filtered, new_row)
colnames(filtered) = c("CHROM", "SGENO", "%", "VGENO", "%", "VHWE", "%", "VFREQ", "%", "VIMP", "%")

# filtered 
#
#    CHROM SGENO %  VGENO     % VHWE      %    VFREQ    %    VIMP    %
# 1      1     0 0  41844 0.570  407 0.0055  6224102 84.0  165251 2.20
# 2      2     0 0  36201 0.450  513 0.0063  6869018 84.0  162023 2.00
# 3      3     0 0  28394 0.420  130 0.0019  5644571 84.0  127037 1.90
# 4      4     0 0  32440 0.490  238 0.0036  5478476 84.0  132561 2.00
# 5      5     0 0  24909 0.410  183 0.0030  5112167 84.0  112849 1.90
# 6      6     0 0  32246 0.560  628 0.0110  4770400 83.0  111664 1.90
# 7      7     0 0  29358 0.540  128 0.0024  4529077 84.0  112459 2.10
# 8      8     0 0  21824 0.410  349 0.0066  4458466 84.0  102422 1.90
# 9      9     0 0  23404 0.580  243 0.0060  3414677 84.0   85127 2.10
# 10    10     0 0  23667 0.520  477 0.0100  3810072 84.0   91822 2.00
# 11    11     0 0  20706 0.450  173 0.0037  3894904 84.0   91753 2.00
# 12    12     0 0  22024 0.500  129 0.0029  3718121 84.0   97036 2.20
# 13    13     0 0  14659 0.450   77 0.0024  2732451 84.0   68956 2.10
# 14    14     0 0  17857 0.590  116 0.0038  2547410 84.0   67617 2.20
# 15    15     0 0  17713 0.640   82 0.0030  2332799 84.0   63707 2.30
# 16    16     0 0  18247 0.590  141 0.0046  2615850 85.0   69461 2.20
# 17    17     0 0  18498 0.700   76 0.0029  2245950 84.0   64204 2.40
# 18    18     0 0  12133 0.470   90 0.0035  2178735 84.0   54559 2.10
# 19    19     0 0  18604 0.890  251 0.0120  1736713 83.0   51478 2.50
# 20    20     0 0   9982 0.480   69 0.0033  1752759 84.0   43084 2.10
# 21    21     0 0   9768 0.770   78 0.0062  1052772 83.0   31054 2.50
# 22    22     0 0  12168 0.970   95 0.0076  1045626 83.0   31712 2.50
# 23   ALL     0 0 486646 0.566 4673 0.0051 78165116 83.9 1937836 2.14


filtered_file = paste0("Filtered_", ident, "_", phenoname,".RData")  #  "Filtered_liver10_liver_fat_a .RData"
save(filtered, file = filtered_file)
cat(paste("  Filter statistics saved to '", filtered_file, "'. \n\n"))






## +++ To get the residuals, run a linear/logistic regression with the same model as in GWAS before
#
#      see also "gwas_diagnose.sh", better "gwas_diagnose_nomarker.sh
#
# phenofile = "liver_fat_ext.txt" ; covarfile = "GWAS_covariates.txt" 
# phenoname = "liver_fat_a" 
# covarname="PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"


cat("  Running regression on covariates ...  ") 
start_time = Sys.time() 


# + Load phenotype file:

if(file.exists(phenofile)) { 
  phenotype = read.table(phenofile, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)  
} else {
  stop(paste("\n\n  ERROR (review_gwas.R): Phenotype file '", phenofile, "' not found.\n\n"))
}

# str(phenotype)
# 'data.frame':   38948 obs. of  3 variables:
#  $ X.FID      : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ IID        : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ liver_fat_a: num  2.6 5.53 5.39 3.66 3.61 ...


if(phenoname %in% colnames(phenotype)) {
  y = phenotype[,c("IID", phenoname)]   # dependent variable  
} else {
  stop(paste("\n\n  ERROR (review_gwas.R) : The file '", phenofile, "' does not have a '", phenoname, "' column.\n\n"))
}

# str(y)
# 'data.frame':   38948 obs. of  2 variables:
#  $ IID        : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ liver_fat_a: num  2.6 5.53 5.39 3.66 3.61 ...

rownames(y) = y$IID

# head(y)
#             IID liver_fat_a
# 1000015 1000015    2.604362
# 1000401 1000401    5.534768
# 1000435 1000435    5.393000
# 1000456 1000456    3.660239
# 1000493 1000493    3.610108
# 1000795 1000795    1.443066



# + Load covariate file:

if(file.exists(covarfile)) { 
  covariates = read.table(covarfile, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)  
} else {
  stop(paste("\n\n  ERROR (review_gwas.R) : Could not find the covariate file: '", covarfile, "'.\n\n"))
}

# str(covariates)
# 'data.frame':   337482 obs. of  16 variables:
#  $ X.FID      : int  1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000125 1000154 ...
#  $ IID        : int  1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000125 1000154 ...
#  $ PC1        : num  -14.21 -14.88 -9.32 -13.27 -11.91 ...
#  $ PC2        : num  4.89 5.5 3.14 2.01 6.89 ...
#  $ PC3        : num  -1.077 -0.564 1.179 -3.32 1.158 ...
#  $ PC4        : num  1.493 0.372 -0.766 1.187 -3.114 ...
#  $ PC5        : num  -4.769 4.594 -2.136 0.177 -5.644 ...
#  $ PC6        : num  -2.1676 -0.5263 0.658 0.0638 -0.6852 ...
#  $ PC7        : num  0.51 -1.225 2.561 0.422 -0.238 ...
#  $ PC8        : num  -1.802 1.442 -0.262 0.754 2.738 ...
#  $ PC9        : num  5.21 1.52 -2.84 4.79 2.2 ...
#  $ PC10       : num  1.918 -1 -1.332 0.301 -2.087 ...
#  $ array      : int  3 2 3 3 2 3 1 1 3 2 ...
#  $ sex        : int  0 0 0 0 1 0 0 0 0 1 ...
#  $ age        : num  55.3 62.3 60.1 64.1 54.3 ...
#  $ age_squared: num  3054 3876 3609 4105 2953 ...

covars = unlist(strsplit(covarname, ","))  # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"

# check covarname
for (cov in covars) {
  # print(cov)
  # print(cov %in% colnames(covariates))
  if(!cov %in% colnames(covariates)) stop(paste("\n\n  ERROR (review_gwas.R) : The covariate '", cov, "' is not included in '", covarfile, "'.\n\n"))
}

covariates = covariates[,c("IID", covars)]   # keep only necessary lines; age_squared might not be used 
rownames(covariates) = covariates$IID

# head(covariates)
#
#             IID       PC1     PC2       PC3       PC4       PC5        PC6       PC7       PC8      PC9      PC10 array sex   age
# 1000027 1000027 -14.20630 4.88676 -1.077420  1.493080 -4.769030 -2.1676300  0.509630 -1.802300  5.21144  1.918070     3   0 55.27
# 1000039 1000039 -14.87840 5.49553 -0.564267  0.372418  4.593710 -0.5263310 -1.224820  1.441580  1.51997 -1.000270     2   0 62.26
# 1000040 1000040  -9.31768 3.14434  1.179110 -0.766216 -2.136190  0.6580010  2.561440 -0.261769 -2.83988 -1.332040     3   0 60.07
# 1000053 1000053 -13.26520 2.01425 -3.319700  1.187170  0.176755  0.0637719  0.422459  0.754097  4.79254  0.301277     3   0 64.07
# 1000064 1000064 -11.91490 6.88527  1.157530 -3.114030 -5.644040 -0.6851510 -0.237977  2.737650  2.19642 -2.087390     2   1 54.34
# 1000071 1000071 -10.44720 4.60355 -1.622490 -2.185330 -2.757930  0.5514320 -1.329740 -1.472890  1.92260  1.138680     3   0 61.17


stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))





## +++ Merge response (y) and covariates to dataframe 

data = merge(y, covariates, by = "row.names")  # see "gwas_diagnose_nomarker.R"

data$IID.x <- NULL 
data$IID.y <- NULL

# colnames(data)[1]  # Row.names
colnames(data)[1] = "IID"
rownames(data) = data$IID

# head(data)
#             IID liver_fat_a       PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9       PC10 array sex
# 1000435 1000435    5.393000  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610 -0.4900740     3   0
# 1000493 1000493    3.610108 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152 -1.4455700     2   1
# 1000843 1000843    9.580051 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820 -0.2851930     3   1
# 1001070 1001070    1.269000 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910 -0.0914199     3   0
# 1001146 1001146    1.401959 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600  0.3356860     3   1
# 1001271 1001271    1.536000 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660 -3.2000799     3   0
#           age
# 1000435 51.21
# 1000493 53.99
# 1000843 58.45
# 1001070 52.17
# 1001146 66.94
# 1001271 40.72



# OBS!: vif (below) does not work if one or more variables are constant:  "Error in vif.default(lmout) : there are aliased coefficients in the model"   
#   remove constant variables:    

logarr = apply(data, 2, function(x) { var(x, na.rm = TRUE) == 0} )
nr_zero = sum(logarr)

if(nr_zero > 0)  {
  zerovars = colnames(data)[logarr] 
  cat(paste0("\n  WARNING: You have ", nr_zero, " constant variable(s) in the data: '", paste(zerovars, collapse = " "), "'. The variable(s) will be removed.\n\n"))
  data = data[, !logarr]
  if(ncol(data) < 3) stop(paste("\n\n  ERROR (review_gwas.R) : It seems you have no independent variables left.\n\n"))
  covars = setdiff(covars, zerovars) # remove from covars
}


datafile = paste(ident, phenoname, "regression_frame.RData", sep = "_")  
save(data, file = datafile)  
cat(paste("  Regression input frame saved to '", datafile, "'.\n"))




# + Linear/Logistic Regression with lm()/glm()

# covars # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"   defined above

cform = paste(covars, collapse = " + ")  # "PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"
form = paste(phenoname, "~", cform)  # WITHOUT marker
formula = as.formula(form) # liver_fat_a ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age 
cat(paste("\n  Regression using:\n ", form, "\n\n"))


if(regtype == "linear")  {
  lmout = lm(formula, data = data) 
}
if(regtype == "logistic")  { 
  data[phenoname] = data[phenoname] - 1  # plink2 uses 1 and 2 but glm limits to 0..1 
  lmout = glm(formula, data = data, family = "binomial")
}

# summary(lmout)



# Save the residuals

if(regtype == "linear") residuals = residuals(lmout)
if(regtype == "logistic") residuals = residuals(lmout, type = "pearson")  # type = "deviance"

#  str(residuals)
#  Named num [1:27243] 2.242 -0.967 5.251 -2.111 -2.976 ...
#  - attr(*, "names")= chr [1:27243] "1000435" "1000493" "1000843" "1001070" ...

residfile = paste(ident, phenoname, "regression_resid.RData", sep = "_")  
save(residuals, file = residfile)  
cat(paste("  Residuals saved to '", residfile, "'.\n"))


 
# + Some metrics for the linear regression: 

if(regtype == "linear")  { 
  sigma = summary(lmout)$sigma 				# standard deviation of error term		      
  fstatistic = summary(lmout)$fstatistic[1]		# 
  r.squared = summary(lmout)$r.squared  			# 	      
  adj.r.squared = summary(lmout)$adj.r.squared 		#     
  aic = extractAIC(lmout)[2] 				# Akaike information criterion 

  metric = c("sigma", "Fstat", "Rsquared", "Rsq.adj", "AIC")
  mvalue = c(sigma, fstatistic, r.squared, adj.r.squared, aic) 

  # mvalue = signif(mvalue, 4)     
  metric.df = data.frame(value = mvalue) 
  rownames(metric.df) = metric

  # metric.df
  #                 value
  # sigma    4.215789e+00
  # Fstat    4.161848e+01
  # Rsquared 1.948288e-02
  # Rsq.adj  1.901474e-02
  # AIC      7.841046e+04

  metricfile = paste(ident, phenoname, "regression_metric.RData", sep = "_")
  save(metric.df, file = metricfile)  
  cat(paste("  Regression metrics frame saved to '", metricfile, "'.\n"))
} else {
  metricfile = "none"
}



# + Regression results:

lm_table = as.data.frame(summary(lmout)$coefficients) 
lmfile = paste(ident, phenoname, "regression_lmtab.RData", sep = "_") 	
save(lm_table, file = lmfile) 
cat(paste("  Regression results saved to '", lmfile, "'\n"))






## +++ Variance inflation factors 

inflation = vif(lmout)

#      PC1      PC2      PC3      PC4      PC5      PC6      PC7      PC8      PC9     PC10    array      sex      age 
# 1.109465 1.036303 1.083822 1.995148 1.980776 1.067407 1.091136 1.241724 1.066883 1.243557 1.001764 1.010945 1.014016


# which(sqrt(inflation) > 2)    # possibly empty

rating = ifelse(sqrt(inflation) > 2, "!!", "ok")
vif.df = data.frame(vif = inflation, rating = rating) 

viffile = paste(ident, phenoname, "regression_vif.RData", sep = "_")  
save(vif.df, file = viffile)  
cat(paste("  Variance inflation factors saved to '", viffile, "'.\n"))




# + Histogram of the residuals   
 
if(regtype == "linear")  { # (logistic regression does not make assumptions on the distribution of the residuals)
  histplot = paste(ident, phenoname, "resid_hist.png", sep = "_")
  png(histplot, width = 600, height = 600)
  hist(residuals, col = "red", breaks = 30, main = "Histogram over Residuals", font.main = 1, xlab = "Residuals")
  invisible(dev.off())
  cat(paste("  Histogram for residuals saved to '", histplot, "'\n")) 
} else {
  histplot = "none"
}



# + Linearity assumption for logistic regression:

if(FALSE) {  # if(regtype == "logistic")  {
  probabilities = predict(lmout, type = "response")
  logit = log(probabilities/(1 - probabilities))
  # linear relationship between the logit and a quantitative predictor could be checked 
}



# +  Normal Q-Q plot of the residuals (NOT the p-values)

if(regtype == "linear")  {   # logistic regression does not make assumptions on the distribution of the residuals)
  qqplotres = paste(ident, phenoname, "resid_qq.png", sep = "_")
  png(qqplotres, width = 600, height = 600)
  plot(lmout, which = 2, id.n = 0)
  # alternative: qqPlot(resid(lmout), distribution = "norm", main = "QQPlot")   library(car)
  invisible(dev.off())
  cat(paste("  Normal QQ-plot for residuals saved to '", qqplotres, "'\n\n")) 
} else {
  qqplotres = "none"  
}



# + Plot of Cooks distance (influential values) 

cookplot = paste(ident, phenoname, "cook_dist.png", sep = "_")
png(cookplot, width = 600, height = 600)
plot(lmout, which = 4, id.n = 5)
invisible(dev.off())
cat(paste("  Plot of Cook's distance saved to '", cookplot, "'\n\n")) 




## +++ Store whole-genome significant markers:

sigmarkers = gwas[which(gwas$P <= p_threshold),]   # signif. markers for all chromosomes 

if(nrow(sigmarkers) == 0) {
  cat("  No genome-wide significant markers found.\n") 
  nr_sigmarkers = 0 
  signif_file = "none"  
} else {
  signif_file = paste(ident, phenoname, "signif_markers.RData", sep = "_")
  other_allele = ifelse(sigmarkers$A1 == sigmarkers$REF, sigmarkers$ALT1, sigmarkers$REF) 
  sigmarkers = cbind(sigmarkers, other_allele)     
  sigmarkers = as.data.frame(sigmarkers[,c(3,1,2,12,6,7,8,9,10,11)])    
  colnames(sigmarkers) = c("ID", "CHR", "POS", "OTHER", "A1", "A1_FREQ", "OBS_CT", "BETA", "SE", "P")
  nr_sigmarkers = nrow(sigmarkers)
  save(sigmarkers, file = signif_file)
  cat(paste("  Significant (unpruned) markers saved to", signif_file, "\n"))
}




## +++ Store all cojoed markers in .RData object (if cojo was conducted):


if(exists("cojo_out")) {   
  cojoed_markers = read.table(cojo_out, header = TRUE, stringsAsFactors = FALSE)  # possibly empty (header only) 
  if(nrow(cojoed_markers) == 0) {
    cat("  No independent markers identified by GCTA cojo.\n")
    cojo_file = "none"
    cojo_orig_file = "none"
  } else { 
    cojo_file = paste(ident, phenoname, "cojoed_markers.RData", sep = "_")   	    
    cojo_orig_file = paste(ident, phenoname, "cojoed_orig_markers.RData", sep = "_")  
    save(cojoed_markers, file = cojo_file)  
    cat(paste("\n  Cojoed markers saved to", cojo_file, "\n"))    
    # add the "original" values of the pruned markers, too (original beta, se, obs_ct, p value etc)  	  
    cojoed_markers_orig = gwas[which(gwas$ID %in% cojoed_markers$ID),]  			
    other_allele = ifelse(cojoed_markers_orig$A1 == cojoed_markers_orig$REF, cojoed_markers_orig$ALT1, cojoed_markers_orig$REF) 
    cojoed_markers_orig = cbind(cojoed_markers_orig, other_allele)     
    cojoed_markers_orig = as.data.frame(cojoed_markers_orig[,c(3,1,2,12,6,7,8,9,10,11)])    
    colnames(cojoed_markers_orig) = c("ID", "CHR", "POS", "OTHER", "A1", "A1_FREQ", "OBS_CT", "BETA", "SE", "P") 
    save(cojoed_markers_orig, file = cojo_orig_file)
    cat(paste("  Cojoed markers with original results saved to", cojo_orig_file, "\n"))
  }
} else {
  cat(paste("\n  It seems that GCTA-COJO was not run for phenoname '", phenoname,"'.\n"))
  cojo_file = "none"
  cojo_orig_file = "none"
}




## +++ Store all clumped markers in .RData object (if clumping was conducted):

if(exists("clump_out")) {   
  clumped_markers = read.table(clump_out, header = TRUE, stringsAsFactors = FALSE)   
  if(nrow(clumped_markers) == 0) {
    cat("  No independent markers identified by plink clump.\n")
    clump_file = "none"    
  } else {
    clump_file = paste(ident, phenoname, "clumped_markers.RData", sep = "_") 
    save(clumped_markers, file = clump_file)  
    cat(paste("  Clumped markers saved to", clump_file,"\n")) 
  } 
} else {
  cat(paste("\n  It seems that clump was not run for phenoname '", phenoname,"'.\n"))
  clump_file = "none" 
}

cat("\n")



## +++ Adjust for multiple testing (does only make sense when all chromosomes have been invoked) 

# p.adj = p.adjust(gwas$P, method = "fdr")  
# gwas = cbind(gwas, p.adj)  
# num_signif_adj = sum(gwas$p.adj < 0.05, na.rm = TRUE)
# cat(paste("  Number of significant markers (FDR, 0.05) in the global regression output:", num_signif_adj, "\n"))
  
  
  
 
  
  
## +++ Genomic inflation factor, lambda

p = length(gwas$P)								# no. of variants 
expect.stats = qchisq(ppoints(p), df = 1, lower.tail = FALSE)			# expected  
obs.stats = qchisq(gwas$P, df = 1, lower.tail = FALSE)				# observed 
lambda = median(obs.stats, na.rm = TRUE)/median(expect.stats, na.rm = TRUE) 	# GC lambda = ratio of medians

# shorter, just as good as above if p big enough, ses GC_lambda.R
# obs.stats = qchisq(gwas$P, df = 1, lower.tail = FALSE)		# observed
# lambda = median(obs.stats)/qchisq(0.5, 1) # tiny difference for small numbers of p-values  p < 20000 
 
 





## +++ Excel with unpruned or pruned global significant markers     

if((nrow(sigmarkers) != 0) & (nrow(sigmarkers) < max_xls)) {  # max. is about 65.000 

  excel_file = paste(ident, phenoname, "signif_markers.xls", sep = "_")

  if(exists("cojo_out") & exists("clump_out")) {   	# we have clump and cojo results  
    if((nrow(cojoed_markers) != 0) | (nrow(clumped_markers) != 0)) { 
      WriteXLS(c("cojoed_markers", "cojoed_markers_orig", "clumped_markers"), ExcelFileName = excel_file, SheetNames = c("cojoed", "orig_cojo", "clumped"), row.names = FALSE)
      cat(paste("  Spreadsheet with cojoed and clumped markers saved to", excel_file, ".\n\n"))
    }
  }

  if(exists("cojo_out") & !exists("clump_out")) { 	# we have cojo but no clump results 
    if(nrow(cojoed_markers) != 0) { 
      WriteXLS(c("cojoed_markers", "cojoed_markers_orig"), ExcelFileName = excel_file, SheetNames = c("cojoed", "orig_cojo"), row.names = FALSE)
      cat(paste("  Spreadsheet with cojoed markers saved to", excel_file, ".\n\n"))
    }
  }

  if(!exists("cojo_out") & exists("clump_out")) { 	# we have clump but no cojo results 
    if(nrow(clumped_markers) != 0) { 
      WriteXLS(c("clumped_markers"), ExcelFileName = excel_file, SheetNames = c("clumped"), row.names = FALSE)
      cat(paste("  Spreadsheet with clumped markers saved to", excel_file, ".\n\n"))
    }
  }

  if(!exists("cojo_out") & !exists("clump_out")) { 	# we have neither clump nor cojo results 
    WriteXLS(sigmarkers, ExcelFileName = excel_file, SheetNames = ident, row.names = FALSE)
    cat(paste("  Spreadsheet with significant (unpruned) markers saved to", excel_file, ".\n\n"))           
  }

} else {

  excel_file = "none" 
  if(nrow(sigmarkers) == 0)   cat("  No significant markers - no spreadsheet saved.\n\n")
  if(nrow(sigmarkers) >= max_xls) cat(paste("  More than", max_xls, "significant markers - no spreadsheet saved.\n\n"))   
  
}





## +++ Nearest genes for the significant markers:   see  "link_nearest_gene.R"

if(nrow(sigmarkers) != 0) {

  cojo_neargene_file = paste(ident, phenoname, "cojo_nearest_genes.RData", sep = "_")
  clump_neargene_file = paste(ident, phenoname, "clump_nearest_genes.RData", sep = "_")
  signif_neargene_file = paste(ident, phenoname, "signif_nearest_genes.RData", sep = "_")

  cat("  Looking for nearest genes ...  ") 
  start_time = Sys.time()  
  gentab = get(load(gentab_file))   # see link_nearest_gene.R ; list with 22 frames, one for each chr;  gentab[[1]] for chromosome 1

  if(exists("cojo_out")) {
    cojo_near_genes = apply(cojoed_markers, 1, link_nearest_gene)
    save(cojo_near_genes, file = cojo_neargene_file)
  }

  if(exists("clump_out")) {
    clump_near_genes = apply(clumped_markers, 1, link_nearest_gene)
    save(clump_near_genes, file = clump_neargene_file) 
  }

  if(!exists("cojo_out") & !exists("clump_out")) {  # only if both cojo_out and clump_out do not exist
    signif_near_genes = apply(sigmarkers, 1, link_nearest_gene)
    save(signif_near_genes, file = signif_neargene_file)   
  }

  # OBS!! "link_nearest_gene" function is sensitive regarding to the format of sigmarkers!
  #     marker_chrom = as.integer(row[2])  # 22          chromosome is expected in 2nd column! 
  #     marker_posit = as.integer(row[3])  # 44324727    position is expected in 3rd column!

  stop_time = Sys.time()
  diff_time = stop_time - start_time 
  cat(paste("Done in", round(diff_time,2), "seconds.\n"))
 
} else {

  cat("  No significant markers ... not looking for nearest genes.\n\n")
  cojo_neargene_file = "none"
  clump_neargene_file = "none"
  signif_neargene_file = "none"
   
}



 
 
 

 
## +++ Global Manhattan plot (all chromosomes)       

cat("  Creating Manhattan plot ...  ") 
start_time = Sys.time()  

# head(gwas)
#   CHROM      POS          ID REF ALT1 A1   A1_FREQ OBS_CT       BETA        SE        P
# 1    22 16051249  rs62224609   C    T  C 0.1005580  18771 -0.1093090 0.0790723 0.166866
# 2    22 16052962 rs376238049   T    C  T 0.0897731  18771 -0.1167530 0.0898770 0.193948
# 3    22 16053862  rs62224614   T    C  T 0.1018450  18771 -0.1072530 0.0784808 0.171765
# 4    22 16054454   rs7286962   T    C  T 0.1055470  18771 -0.0953407 0.0782874 0.223304
# 5    22 16057417  rs62224618   C    T  T 0.1015400  18771 -0.1094630 0.0776205 0.158487
# 6    22 16439593 rs199989910   A    G  A 0.0437326  18771 -0.1393800 0.1252730 0.265891

manhat = gwas[,c(3,1,2,11)]   # input frame for function manhattan.plot 
colnames(manhat) = c("marker", "chr", "pos", "pvalue") 

# head(manhat) 
#        marker chr      pos   pvalue
# 1  rs62224609  22 16051249 0.166866
# 2 rs376238049  22 16052962 0.193948
# 3  rs62224614  22 16053862 0.171765


txt = paste("Manhattan plot for jobid", ident) 
man_plot = paste(ident, phenoname, "Manhattan.png", sep = "_") 
png(man_plot, width = 1024, height = 768)

if (annotation) {
  ann = annotateSNPRegions(manhat$marker, manhat$chr, manhat$pos, manhat$pvalue,
	snplist =c("rs1558902","rs17024393"),
	labels = c("FTO","GNAT2"),
	col = c("red","green"), kbaway=50)
  print(manhattan.plot(manhat$chr, manhat$pos, manhat$pvalue, sig.level = 5e-8, col = colvec, should.thin = F, main = txt, annotate = ann)) 
} else {  
  print(manhattan.plot(manhat$chr, manhat$pos, manhat$pvalue, sig.level = 5e-8, col = colvec, should.thin = F, main = txt)) 
}
invisible(dev.off())

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))








## +++ SNP density plot

# can use the "manhat" frame, see CMplot_chunk.R 
# gwas = get(load("gwas_results.RData"))   # /castor/project/proj/GWAS_DEV/liver9

cat("  Creating SNP density plot ...  ") 
start_time = Sys.time()  

snp_density_plot = paste(ident, phenoname, "snp_density.png", sep = "_")  # liver9_liver_fat_a_snp_density.png
png(snp_density_plot, width = 1024, height = 768)
CMplot(manhat, plot.type = "d", bin.size = 1e6, chr.den.col = c("darkgreen", "yellow", "red"), file = "png", memo="", dpi = 300,
       file.output = TRUE, verbose = FALSE, width = 12, height = 8)
# invisible(dev.off())  ???? that causes an error: Error in dev.off() : cannot shut down device 1 (the null device) 

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))






## +++ Global QQ-plot for p-values (all chrom) ( p-values are U(0,1) under H0 ... which would mean there are no sign. markers)    

cat("  Creating QQ-plot ...  ") 
start_time = Sys.time()  

txt = paste("Job", ident, ": QQ-plot for -log10 of p-values") 
qq_plot = paste(ident, phenoname, "QQplot.png", sep = "_") 
png(qq_plot, width = 1024, height = 768)
qqplot(-log10(ppoints(nrow(gwas))),-log10(gwas$P), xlab = "theoretical", ylab = "observed", main = "Q-Q Plot for -log10 Pval") 
abline(0, 1, col = "red") 
invisible(dev.off())
 
stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))





 
## +++ Global histogram of beta-values

cat("  Creating histogram for regression slopes ...  ") 
start_time = Sys.time()  
  
txt = paste(ident, ": Histogram of beta-values") 
histo_plot = paste(ident, phenoname, "beta_hist.png", sep = "_") 
png(histo_plot, width = 1024, height = 768)
hist(gwas$BETA, col = "red", breaks = 50, xlab = "beta", main = txt, font.main = 1) 
invisible(dev.off())
  
stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))

 

 
 
## +++ Global kernel density plot of beta-values 
 
cat("  Creating kernel density plot for regression slopes ...  ") 
start_time = Sys.time()  
 
d = density(gwas$BETA, na.rm = TRUE)
txt = paste(ident, ": Kernel density plot for beta")
kernel_plot = paste(ident, phenoname, "beta_kernel.png", sep = "_")
png(kernel_plot, width = 1024, height = 768)
plot(d, main = txt, col = "red", font.main = 1)
polygon(d, col="red", border="darkgrey")  # fill 
rug(jitter(gwas$BETA))
invisible(dev.off())
  
stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))

 
 
 
 
 
 
## +++ Get number of samples in the genotype dataset  
 
# see "review_settings.sh" :  these variables are loaded by source(setfile) above
#   nr_geno_ukb_imp_v3=487409
#   nr_geno_FTD=337482
#   nr_geno_MRI=39219
#   nr_geno_MF=28146

nr_geno = NA 

# if(genotype_id == "ukb_imp_v3") nr_geno = nr_geno_ukb_imp_v3  
# if(genotype_id == "FTD") nr_geno = nr_geno_FTD
# if(genotype_id == "MRI") nr_geno = nr_geno_MRI
# if(genotype_id == "MF") nr_geno = nr_geno_MF
# if(is.na(nr_geno)) stop(paste("\n\n  ERROR (review_gwas.R): Illegal genotype identifier '", genotype_id, "' used.\n\n"))

# removed for compatibility with 570 project
 
 
 
 
 

## +++ Create output html from rmarkdown template:  


# required files:

if(!file.exists(filtered_file)) stop(paste("\n\n  ERROR (review_gwas.R): File", filtered_file, "not found.\n\n"))  
if(!file.exists(qq_plot)) stop(paste("\n\n  ERROR (review_gwas.R): File", qq_plot, "not found.\n\n"))      
if(!file.exists(man_plot)) stop(paste("\n\n  ERROR (review_gwas.R): File", man_plot, "not found.\n\n"))        
if(!file.exists(histo_plot)) stop(paste("\n\n  ERROR (review_gwas.R): File", histo_plot, "not found.\n\n"))     
if(!file.exists(kernel_plot)) stop(paste("\n\n  ERROR (review_gwas.R): File", kernel_plot, "not found.\n\n"))
if(!file.exists(snp_density_plot)) stop(paste("\n\n  ERROR (review_gwas.R): File", snp_density_plot, "not found.\n\n"))
if(!file.exists(cookplot)) stop(paste("\n\n  ERROR (review_gwas.R): File", cookplot, "not found.\n\n"))    
# regarding residuals:
if(!file.exists(datafile)) stop(paste("\n\n  ERROR (review_gwas.R): File", datafile, "not found.\n\n"))
if(!file.exists(residfile)) stop(paste("\n\n  ERROR (review_gwas.R): File", residfile, "not found.\n\n"))
if(!file.exists(lmfile)) stop(paste("\n\n  ERROR (review_gwas.R): File", lmfile, "not found.\n\n"))
if(!file.exists(viffile)) stop(paste("\n\n  ERROR (review_gwas.R): File", viffile, "not found.\n\n"))
# linear regression only:
if(regtype == "linear") {
  if(!file.exists(histplot)) stop(paste("\n\n  ERROR (review_gwas.R): File", histplot, "not found.\n\n"))
  if(!file.exists(metricfile)) stop(paste("\n\n  ERROR (review_gwas.R): File", metricfile, "not found.\n\n"))
  if(!file.exists(qqplotres)) stop(paste("\n\n  ERROR (review_gwas.R): File", qqplotres, "not found.\n\n"))
} 


# get lm_call
# covarname  # "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"  # from paramfile
covar = unlist(strsplit(covarname, ","))   # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"   
covar = paste(covar, collapse = " + ")     
lm_call = paste(phenoname , "~ marker +", covar)    # "liver_fat ~ marker + PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"


plist = list()

# mandatory parameters:

plist["workfolder"] = getwd() 
plist["regtype"] = regtype    		
plist["ident"] = ident 
plist["nr_samples"] = nr_samples      
plist["nr_markers"] = nrow(gwas) 
plist["nr_sigmarkers"] = nr_sigmarkers 
plist["genoid"] = genotype_id
plist["nr_geno"] = nr_geno
plist["lm_call"] = lm_call      
plist["phenoname"] = phenoname
plist["plink"] = plink2_version  		  
plist["lambda"] = lambda 
plist["mac"] = mac 
plist["maf"] = maf				
plist["vif"] = vif				
plist["sample_max_miss"] = sample_max_miss	
plist["marker_max_miss"] = marker_max_miss	
plist["machr2_low"] = machr2_low 
plist["machr2_high"] = machr2_high 
plist["hwe_pval"] = hwe_pval   
plist["form"] = form   

# optional parameters:

plist["cojo_done"] = ifelse(exists("cojo_out"), TRUE, FALSE)
plist["clump_done"] = ifelse(exists("clump_out"), TRUE, FALSE)
plist["clump_p1"] = ifelse(exists("clump_out"), clump_p1, NA)
plist["clump_p2"] = ifelse(exists("clump_out"), clump_p2, NA)
plist["clump_r2"] = ifelse(exists("clump_out"), clump_r2, NA)
plist["clump_kb"] = ifelse(exists("clump_out"), clump_kb, NA)
plist["cojo_window"] = ifelse(exists("cojo_out"), cojo_window, NA)
plist["cojo_pval"] = ifelse(exists("cojo_out"), cojo_pval, NA)
plist["cojo_coline"] = ifelse(exists("cojo_out"), cojo_coline, NA)
plist["cojo_refgen"] = ifelse(exists("cojo_out"), cojo_refgen, NA)
plist["clump_refgen"] = ifelse(exists("clump_out"), clump_refgen, NA) 
plist["cojo_maf"] = ifelse(exists("cojo_out"), cojo_maf, NA)

# files:

plist["excel_file"] = excel_file
plist["signif_file"] = signif_file
plist["filtered_file"] = filtered_file
plist["clump_file"] = clump_file
plist["cojo_file"] = cojo_file
plist["cojo_orig_file"] = cojo_orig_file
plist["cojo_neargene_file"] = cojo_neargene_file
plist["clump_neargene_file"] = clump_neargene_file
plist["signif_neargene_file"] = signif_neargene_file
plist["qq_plot"] = qq_plot
plist["man_plot"] = man_plot
plist["snp_density_plot"] = snp_density_plot
plist["histo_plot"] = histo_plot
plist["kernel_plot"] = kernel_plot
plist["datafile"] = datafile
plist["residfile"] = residfile
plist["metricfile"] = metricfile
plist["lmfile"] = lmfile
plist["viffile"] = viffile
plist["histplot"] = histplot
plist["qqplotres"] = qqplotres
plist["cookplot"] = cookplot

        

htmlfile = paste(ident, phenoname, "report.html", sep = "_")    

plist_file = paste(ident, phenoname, "rmd_review_params.RData", sep = "_")  
save(plist, file = plist_file)
cat(paste("  Parameter list for Rmarkdown saved to '", plist_file, "' \n\n"))

cat(paste("  Rendering file", rmd_main, " ..."))   
start_time = Sys.time()  

rmarkdown::render(rmd_main, params = plist, output_dir = getwd(), output_file = htmlfile, quiet = TRUE)  

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("  Done in", round(diff_time,2), "seconds.\n"))




## +++ Finish

cat(paste("\n  Open '", htmlfile, "' with your favoured browser.\n"))
cat(paste("\n  ", date(),"\n\n"))
cat("  Done.\n\n")  


 
 

















 
