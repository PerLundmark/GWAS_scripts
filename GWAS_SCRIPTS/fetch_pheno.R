#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Fetch a phenotype by UKBB field ID:
#     (possibly use search_filedID first)  
#      parents: fetch_phenotypes.R  fetch_phenotypes_WHR.R  





## +++ Call:
#
# called by fetch_pheno.sh 
#
# fetch_pheno.R  ${phenofile}  ${headerfile}  ${field}  ${outfile}




## +++ Libraries, functions

library(data.table) # fread 

# don't forget "module load R_packages/3.6.1" before calling this script






## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 4) {
  cat("\n")
  cat("  Usage: fetch_pheno.R  <phenofile>   <headerfile>   <fieldID>   <outfile>\n") 
  cat("      uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

phenofile = args[1]	
headerfile = args[2]	
fieldID  = args[3]	
outfile = args[4]  	


# headerfile = "ukbheader_5114.txt"
# fieldID = 22009
# outfile = "PCs.txt"




## +++ Load file containing the header of the phenotype file 
#  (small in contrast to the whole phenotype file) 

if(!file.exists(phenofile)) {
  cat(paste("\n  ERROR (fetch_pheno.R): File", phenofile, "not found.\n\n")) 
  quit("no")
}

if(!file.exists(headerfile)) {
  cat(paste("\n  ERROR (fetch_pheno.R): File", headerfile, "not found.\n\n")) 
  quit("no")
} else {
  fields = scan(headerfile, character(), quiet = TRUE)
} 

# str(fields)	  # chr [1:6219] "n_eid" "n_21_0_0" "n_21_1_0" "n_21_2_0" "n_21_3_0" ...	
# length(fields)  # 6219


cat(paste("\n  Header with", length(fields), "entries read.\n\n"))








## +++ Get column numbers for the field ID 

searchterm = paste("_", fieldID, "_", sep = "")  # "_22009_"
ind = which(grepl(searchterm, fields))

# ind
#  [1] 2722 2723 2724 2725 2726 2727 2728 2729 2730 2731 2732 2733 2734 2735 2736
# [16] 2737 2738 2739 2740 2741 2742 2743 2744 2745 2746 2747 2748 2749 2750 2751
# [31] 2752 2753 2754 2755 2756 2757 2758 2759 2760 2761
#
# 40 PC's

  	
nr_found = length(ind)	 # 40  			

if(nr_found == 0) {
  cat(paste("\n  PROBLEM (fetch_pheno.R): No entries for the field ID", fieldID, "found in", phenofile, ".\n\n")) 
  quit("no")
} else {
  cat(paste("  Fields found:\n", paste(fields[ind], collapse = "  "), "\n\n"))   
}

# fields[ind] 		 
colsToKeep = c(1,ind)  	







## +++ Fetch the phenotypes for this field ID:  

cat("  Fetching phenotype: \n\n") 

pheno1 = as.data.frame(fread(phenofile, check.names = TRUE, sep = "\t", showProgress = TRUE, select = colsToKeep)) 
 
# str(pheno1) 	# 'data.frame':	502543 obs. of  4 variables:  
cat("\n  Done. \n\n") 

# str(pheno1)
#
# 'data.frame':   502520 obs. of  41 variables:
#  $ n_eid       : int  1000014 1000023 1000030 1000041 1000059 1000062 1000077 1000086 1000095 1000100 ...
#  $ n_22009_0_1 : num  202 -11.5 -11.2 -14.2 -14.5 ...
#  $ n_22009_0_2 : num  43.13 2.63 4.58 2.14 2.25 ...
#  $ n_22009_0_3 : num  -4.6 -3.103 -0.386 -2.247 1.077 ...
#  $ n_22009_0_4 : num  3.177 12.901 1.077 0.746 -3.073 ...
#  $ n_22009_0_5 : num  -0.395 30.154 -5.343 7.225 0.518 ...
#  $ n_22009_0_6 : num  -2.632 -0.392 -1.714 -0.28 0.192 ...
#  $ n_22009_0_7 : num  -2.914 -0.523 -0.357 1.723 4.096 ...
#  $ n_22009_0_8 : num  0.56 1.43 1.92 3.17 3.81 ...
#  $ n_22009_0_9 : num  3.72 2.5 -1.23 5.99 -5.99 ...
#  $ n_22009_0_10: num  0.000286 -0.511716 0.511481 -5.83977 1.5739 ...
#  $ n_22009_0_11: num  -0.632 4.74 -0.944 -3.126 -0.758 ...
#  $ n_22009_0_12: num  -3.7505 -1.8952 0.0558 0.898 0.1245 ...
#  $ n_22009_0_13: num  0.949 -2.163 -1.709 3.722 -3.155 ...
#  $ n_22009_0_14: num  1.55 -9.18 -3.88 5.4 0.27 ...
#  $ n_22009_0_15: num  9.95 6.1 -3.67 2.74 1.16 ...
#  $ n_22009_0_16: num  -0.649 -0.639 0.206 -0.664 -0.908 ...
#  $ n_22009_0_17: num  0.149 -0.477 -3.405 2.661 0.242 ...
#  $ n_22009_0_18: num  -0.695 4.21 -1.977 -3.373 -0.317 ...
#  $ n_22009_0_19: num  0.78 2.43 -1.54 -2.15 2.03 ...
#  $ n_22009_0_20: num  -0.158 1.785 0.463 0.422 -1.693 ...
#  $ n_22009_0_21: num  -1.08 1.52 -2.61 2.11 5.79 ...
#  $ n_22009_0_22: num  3.668 -5.402 -0.686 0.519 -2.579 ...
#  $ n_22009_0_23: num  1.194 -0.935 -4.658 1.919 2.774 ...
#  $ n_22009_0_24: num  2.703 -3.283 0.107 1.649 -3.53 ...
#  $ n_22009_0_25: num  2.455 -0.873 0.626 -0.603 0.918 ...
#  $ n_22009_0_26: num  0.972 -0.491 -1.77 -3.066 4.238 ...
#  $ n_22009_0_27: num  -3.12 0.49 -3.3 1.12 3.62 ...
#  $ n_22009_0_28: num  1.708 3.969 0.405 -0.395 -1.56 ...
#  $ n_22009_0_29: num  -2.087 -2.581 0.821 -1.573 1.076 ...
#  $ n_22009_0_30: num  0.309 5.606 1.019 5.312 4.324 ...
#  $ n_22009_0_31: num  0.58 1.6 -4.49 -3.12 -1.26 ...
#  $ n_22009_0_32: num  3.04 -2.56 3.57 1.76 -0.93 ...
#  $ n_22009_0_33: num  -2.11 -2.39 -1.94 1.74 -1.59 ...
#  $ n_22009_0_34: num  1.554 -3.072 3.786 0.229 -2.665 ...
#  $ n_22009_0_35: num  -1.57 -2.21 3.39 1.75 -2.83 ...
#  $ n_22009_0_36: num  -0.365 3.723 -2.578 0.753 -2.663 ...
#  $ n_22009_0_37: num  -0.659 -0.868 3.402 3.213 2.309 ...
#  $ n_22009_0_38: num  0.362 -0.173 -4.533 0.639 0.238 ...
#  $ n_22009_0_39: num  -0.114 5.294 0.306 3.019 -1.662 ...
#  $ n_22009_0_40: num  -1.605 -1.282 4.153 0.563 0.94 ...






## +++ Reformat to format requested by plink and save 
  
sampleIDs = pheno1[,1]   # OBS!: requires ID's in the 1st column    

cat("  ID's look like that:\n\n")   
head(sampleIDs)
cat("\n\n")


# pheno1[1:5, 1:11]  
# 
#     n_eid n_22009_0_1 n_22009_0_2 n_22009_0_3 n_22009_0_4 n_22009_0_5 n_22009_0_6 n_22009_0_7 n_22009_0_8 n_22009_0_9 n_22009_0_10
# 1 1000014    202.0420    43.13180   -4.600200    3.176640   -0.394758   -2.632230   -2.914410    0.559626     3.71637  0.000286181
# 2 1000023    -11.5464     2.63475   -3.103320   12.901400   30.154300   -0.391849   -0.523238    1.428600     2.50337 -0.511716000
# 3 1000030    -11.1576     4.58264   -0.386166    1.076740   -5.343250   -1.714280   -0.356501    1.920580    -1.23019  0.511481000
# 4 1000041    -14.1774     2.13654   -2.246830    0.746411    7.225140   -0.280186    1.723380    3.171350     5.98717 -5.839770000
# 5 1000059    -14.4595     2.25252    1.076750   -3.073490    0.518150    0.191503    4.096200    3.805000    -5.98618  1.573900000

pheno1 = cbind(sampleIDs, pheno1)  
colnames(pheno1)[1] = "#FID" 
colnames(pheno1)[2] = "IID" 
  
# pheno1[1:5, 1:12]
# 
#     #FID     IID n_22009_0_1 n_22009_0_2 n_22009_0_3 n_22009_0_4 n_22009_0_5 n_22009_0_6 n_22009_0_7 n_22009_0_8 n_22009_0_9 n_22009_0_10
# 1 1000014 1000014    202.0420    43.13180   -4.600200    3.176640   -0.394758   -2.632230   -2.914410    0.559626     3.71637  0.000286181
# 2 1000023 1000023    -11.5464     2.63475   -3.103320   12.901400   30.154300   -0.391849   -0.523238    1.428600     2.50337 -0.511716000
# 3 1000030 1000030    -11.1576     4.58264   -0.386166    1.076740   -5.343250   -1.714280   -0.356501    1.920580    -1.23019  0.511481000
# 4 1000041 1000041    -14.1774     2.13654   -2.246830    0.746411    7.225140   -0.280186    1.723380    3.171350     5.98717 -5.839770000
# 5 1000059 1000059    -14.4595     2.25252    1.076750   -3.073490    0.518150    0.191503    4.096200    3.805000    -5.98618  1.573900000



cat(paste("  Saving to:", outfile, "\n"))  
write.table(pheno1, file = outfile, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")  
cat("  Done. \n\n") 







