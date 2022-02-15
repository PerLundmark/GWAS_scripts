#!/usr/bin/env Rscript      


# uwe.menzel@medsci.uu.se  



 
## === Regression diagnostics for GWAS 
#      replicates also regression results from plink for the markers considered!





# TEST, command line:
#
#  pwd /proj/sens2019016/GWAS_DEV/LIV_MULT5
#  module load R_packages/3.6.1
#  gwas_diagnose.R    <marker>   <phenopath>  <phenoname>   <covarpath>   <covarname>   <rawfile>  <switch_allele> [<summaryfile>]
#  gwas_diagnose.R  rs767276217_A_G  ./liver_fat_faked.txt liv5  ./GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age  genotype_rs767276217_A_G.raw 0 LIV_MULT5_gwas_chr5.liv5.glm.linear

# SLURM command:
# sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  --wrap="module load R_packages/3.6.1; gwas_diagnose.R ...
# sbatch  -A sens2019016 -p node  -t 10:00  -J DIAG_2 -o diagnose_R_rs767276217_A_G.log -e diagnose_R_rs767276217_A_G.log --wrap="module load R_packages/3.6.1; gwas_diagnose.R ..."









## +++ Call:
#
# called by gwas_diagnose.sh
# 
# --wrap="module load R_packages/3.6.1; gwas_diagnose.R gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile}  ${switch} ${summaryfile}"
#
#
# switch is 0 or 1 indicating if allele should be switched 
#
# switch -eq 0   use allele counted
# switch -eq 1   use other allele 
#
# +++ Regression on allele counted (switch=0; as exported by plink):
# gwas_diagnose.R  rs767276217_A_G  ./liver_fat_faked.txt  liv2  ./GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age \
#                  genotype_rs767276217_A_G.raw  0 LIV_MULT5_gwas_chr5.liv5.glm.linear
#
# +++ Regression on other allele (switch=1) 
# gwas_diagnose.R  rs767276217_A_G  ./liver_fat_faked.txt  liv2  ./GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age \
#                  genotype_rs767276217_A_G.raw  1 LIV_MULT5_gwas_chr5.liv5.glm.linear
#
#




# to check without comparison, temporarily move: mv -i LIV_MULT5_gwas_chr5.liv5.glm.linear temp.linear



# "summaryfile" format:
#
# head LIV_MULT5_gwas_chr5.liv5.glm.linear
# #CHROM	POS	ID	REF	ALT1	A1	A1_FREQ	OBS_CT	BETA	SE	P
# 5	11882	rs376588128_A_T	A	T	T	0.266599	18771	0.0409518	0.0548738	0.455501
# 5	11883	rs370741740_C_G	C	G	G	0.266678	18771	0.0405081	0.054877	0.460425
# 5	11889	5:11889_CTTATAT_C	C	CTTATAT	CTTATAT	0.296017	18771	0.0153175	0.0527711	0.771618
# 5	12010	rs578095237_G_A	G	A	G	0.000735695	18771	0.667134	0.960382	0.48728
# 5	12041	rs55926606_T_A	T	A	A	0.276203	18771	0.0394798	0.0531723	0.457801
# 5	12225	rs28538767_A_G	A	G	G	0.275339	18771	0.0320767	0.0535808	0.549407
# 5	12398	rs527696348_G_C	G	C	G	0.00472043	18771	0.351275	0.37066	0.343294
# 5	13018	rs28769581_A_C	A	C	C	0.272438	18771	0.0227519	0.0538726	0.67279
# 5	13114	rs28824936_C_G	C	G	G	0.272442	18771	0.022577	0.0538706	0.67515







## +++ Plot parameters 

plotwidth = 600
plotheight = 600





## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 7) {
  cat("\n")
  cat("  Usage: gwas_diagnose  <marker>  <phenopath>  <phenoname>  <covarpath>  <covarname>  <rawfile>  <switch_allele> [<summaryfile>] \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

marker = args[1]		
phenopath = args[2]		    
phenoname = args[3]
covarpath = args[4]
covarname = args[5]
rawfile = args[6]     			# genotype extracted by "extract_genotype.sh" (called by main prog "gwas_diagnose.sh")
switch_allele = as.integer(args[7])  	# 0 or 1 
if(length(args) == 8) {
  summaryfile = args[8]
  comparison = TRUE
} else {
  comparison = FALSE
}



# TEST, R-console:
#
# getwd() 	# /castor/project/proj/GWAS_DEV3/liver10 
# marker = "rs188247550_T_C"
# phenopath = "liver_fat_ext.txt" 		     
# phenoname = "liver_fat_a" 
# covarpath = "GWAS_covariates.txt" 
# covarname = "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age" 
# rawfile = "genotype_rs767276217_A_G.raw" 
# switch_allele = 0   # or 1
# summaryfile = "liver10_gwas_chr19.liver_fat_a.glm.linear"
# comparison = TRUE
#
# ls()
#  [1] "comparison"    "covarname"     "covarpath"     "marker"        "phenoname"     "phenopath"     "plotheight"    "plotwidth"    
#  [9] "rawfile"       "scripts"       "summaryfile"   "switch_allele"






## +++ Check if summary file exists and if it conatind the marker:

# marker = "rs55926606_T_A"
# marker = "rs767276217_A_G"

if(comparison) {  
  if(!file.exists(summaryfile)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Comparison chosen but summary file '",  summaryfile,  "' not found.\n\n"))
  cmd = paste("grep -swc", marker, summaryfile) # "grep -swc rs767276217_A_G liver10_gwas_chr5.liver_fat_a.glm.linear"   just count
  num = as.integer(suppressWarnings(system(cmd, intern = TRUE)))    
  if(num == 0) stop(paste("\n\n  ERROR (gwas_diagnose.R): No entry for marker '", marker, "' in summary file '",  summaryfile,  "'.\n\n"))
  if(num > 1) stop(paste("\n\n  ERROR (gwas_diagnose.R): Multiple entries for marker '", marker, "' in summary file '",  summaryfile,  "'.\n\n"))
}







## +++ Libraries, Functions

cat("\n\n  Loading packages ...  ") 
start_time = Sys.time() 
suppressMessages(suppressWarnings(library(VennDiagram)))  	# venn.diagram
suppressMessages(suppressWarnings(library(car)))		# outlierTest and more 
suppressMessages(suppressWarnings(library(data.table)))		# fread
suppressMessages(suppressWarnings(library(gplots)))		# heatmap.2
stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))






## +++ Get environment variable 

# ~/.bashrc : 
# export SCRIPT_FOLDER="/proj/sens2019016/GWAS_SCRIPTS"  #  use ". s1"  and ". s2" to switch 

scripts = Sys.getenv("SCRIPT_FOLDER") 
if ( scripts == "" ) {
  stop(paste("\n\n  ERROR (gwas_diagnose.R): Environment variable 'SCRIPT_FOLDER' not set.\n\n"))  
} else {
  cat(paste("\n  Environment variable 'SCRIPT_FOLDER' is set to", scripts, "\n\n"))
}


# scripts = "/home/umenzel/bin/GWAS_SCRIPTS"




# Rmarkdown template :

# two templates: one with comparison to plink results, another one without comparison

if(comparison) {
  rmd = paste(scripts, "gwas_diagnose.Rmd", sep="/")	# "/proj/sens2019016/GWAS_SCRIPTS/gwas_diagnose.Rmd"   alt. "/home/umenzel/bin/GWAS_SCRIPTS/gwas_diagnose.Rmd"
} else {
  rmd = paste(scripts, "gwas_diagnose_nocomp.Rmd", sep="/")
}

if(!file.exists(rmd)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Rmarkdown template ",  rmd,  " not found.\n\n"))
rmd_copy = paste(getwd(), "gwas_diagnose.Rmd", sep="/")  	# /castor/project/proj/GWAS_DEV/LIV_MULT5/gwas_diagnose.Rmd

# copy the .Rmd file to the current folder ==> working directory for knitr
if(!file.copy(rmd, rmd_copy, overwrite = TRUE)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Could not copy file ",  rmd,  " to the current folder.\n\n"))
if(!file.exists(rmd_copy)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Rmarkdown template ",  rmd,  " not copied to current location.\n\n"))







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
cat(paste("  Marker:", marker, "\n"))
cat(paste("  Phenotype path:", phenopath, "\n"))
cat(paste("  Phenonames:", phenoname, "\n"))
cat(paste("  Covariates path:", covarpath, "\n"))
cat(paste("  Genotype rawfile:", rawfile, "\n"))
cat(paste("  Switch_allele:", switch_allele, "\n"))
if(comparison) {
  cat(paste("  Summary statistics:", summaryfile, "\n"))
} else {
  cat(paste("  Summary statistics: not invoked on command line.\n"))
}
cat("\n") 


#   Date: Tue Jul 21 14:20:29 2020 
#   Folder: /castor/project/proj/GWAS_DEV/LIV_MULT5 
#   Platform: x86_64-pc-linux-gnu 
#   R-version: R version  (2019-07-05) 
# 
#   Marker: rs767276217_A_G 
#   Phenotype path: ./liver_fat_faked.txt 
#   Phenonames: liv5 
#   Covariates path: ./GWAS_covariates.txt 
#   Genotype rawfile: genotype_rs767276217_A_G.raw 
#   Switch_allele: 0 
#   Summary statistics: LIV_MULT5_gwas_chr5.liv5.glm.linear



 




## +++ Load the files and find common samples:

cat("  Loading input files ...  ") 
start_time = Sys.time() 


## A) phenotype = dependent variable


# /proj/sens2019016/GWAS_DEV/LIV_MULT5 > head liver_fat_faked.txt
# #FID		    IID		liv1		liv2		liv3		liv4		liv5		liv6		liv7		liv8		liv9		liv10
# 1000401	1000401	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835	4.6117716835
# 1000435	1000435	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333	6.4229896333
# 1000456	1000456	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689	3.1423040689
# 1000493	1000493	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938	2.5408244938
# 1000843	1000843	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153	8.4709656153
# 1000885	1000885	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204	21.8226416204
# 1001146	1001146	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422	1.1720321422
# 1001215	1001215	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852	11.7379679852
# 1001310	1001310	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581	6.5725167581


if(file.exists(phenopath)) { 
  phenotype = read.table(phenopath, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)  
} else {
  stop(paste("\n\n  ERROR (gwas_diagnose.R) : Could not find the phenotype file: '", phenopath, "'.\n\n"))
}

# str(phenotype)
# 'data.frame':	38948 obs. of  3 variables:
#  $ X.FID      : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ IID        : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ liver_fat_a: num  2.6 5.53 5.39 3.66 3.61 ...


if(phenoname %in% colnames(phenotype)) {
  y = phenotype[,c("IID", phenoname)]   # dependent variable  
} else {
  stop(paste("\n\n  ERROR (gwas_diagnose.R) : The file '", phenopath, "' does not have a '", phenoname, "' column.\n\n"))
}

# str(y)   # dependent variable (qunatitative phenotype)
# 'data.frame':	38948 obs. of  2 variables:
#  $ IID        : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ liver_fat_a: num  2.6 5.53 5.39 3.66 3.61 ...


rownames(y) = y$IID


# head(y) 
# 
#             IID liver_fat_a
# 1000015 1000015    2.604362
# 1000401 1000401    5.534768
# 1000435 1000435    5.393000
# 1000456 1000456    3.660239
# 1000493 1000493    3.610108
# 1000795 1000795    1.443066





## B) genotype for the marker considered 

# /proj/sens2019016/GWAS_DEV/LIV_MULT5 > head genotype_rs767276217_A_G.raw
# IID	rs767276217_A_G_A
# 5954653	0
# 1737609	0
# 1427013	0
# 3443403	0
# 5807741	0

if(file.exists(rawfile)) { 
  genotype = read.table(rawfile, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)  
} else {
  stop(paste("\n\n  ERROR (gwas_diagnose.R) : Could not find the genotype raw file: '", rawfile, "'.\n\n"))
}

# str(genotype)
# 'data.frame':	487409 obs. of  2 variables:
#  $ IID              : int  5954653 1737609 1427013 3443403 5807741 4188953 1821438 3951387 5670866 1207760 ...
#  $ rs188247550_T_C_T: num  0 0 0 0 0 0 0 0 0 0 ...



# marker  # rs188247550_T_C  

label = colnames(genotype)[2]		# "rs767276217_A_G_A"    original marker name plus counted allele ("A")  
if(!grepl(marker, label, fixed = TRUE)) {
  cat(paste("  Marker is '", marker, "' but rawfile contains '", label, "'\n"))
  cat("  That ain't gonna work.\n\n")
  stop(paste("\n\n  ERROR (gwas_diagnose.R) : Inconsistent marker labels.\n\n"))
}

rownames(genotype) = genotype$IID

# head(genotype) 
#             IID rs767276217_A_G_A
# 5954653 5954653                 0
# 1737609 1737609                 0
# 1427013 1427013                 0
# 3443403 3443403                 0
# 5807741 5807741                 0
# 4188953 4188953                 0

lvec = unlist(strsplit(label, "_", fixed = TRUE))  
counted_allele = lvec[length(lvec)]  	# "A"  
c1 = lvec[length(lvec) - 1] 		# "G"
c2 = lvec[length(lvec) - 2] 		# "A"
other_allele = ifelse(counted_allele == c1, c2, c1) 	# "G"
# cat(paste("  Genotype file: counted allele is", counted_allele, ", other allele is", other_allele, "\n\n"))  # show below  





## C) covariates

# /proj/sens2019016/GWAS_DEV/LIV_MULT5 > head ./GWAS_covariates.txt
# #FID		IID	     PC1	     PC2	     PC3	    PC4	      PC5	PC6	PC7	PC8	PC9	PC10	array	sex	age	age_squared
# 1000027	1000027	-14.2063	4.8867602	-1.07742	1.49308	-4.7690301	-2.16763	0.50963002	-1.8023	5.2114401	1.91807	3	0	55.273054.38
# 1000039	1000039	-14.8784	5.4955301	-0.56426698	0.37241799	4.5937099	-0.52633101	-1.22482	1.4415801	1.5199701	-1.00027	20	62.26	3876.43
# 1000040	1000040	-9.3176804	3.14434	1.1791101	-0.76621598	-2.1361899	0.65800101	2.56144	-0.261769	-2.83988	-1.33204	3	0	60.07	3608.88
# 1000053	1000053	-13.2652	2.01425	-3.3197	1.18717	0.176755	0.063771904	0.42245901	0.75409698	4.7925401	0.30127701	3	0	64.074104.77
# 1000064	1000064	-11.9149	6.8852701	1.15753	-3.1140299	-5.6440401	-0.68515098	-0.237977	2.7376499	2.19642	-2.0873899	2	1	54.34	2953.3


if(file.exists(covarpath)) { 
  covariates = read.table(covarpath, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)  
} else {
  stop(paste("\n\n  ERROR (gwas_diagnose.R) : Could not find the covariate file: '", covarpath, "'.\n\n"))
}

# str(covariates)
# 'data.frame':	337482 obs. of  16 variables:
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

# covarname   #  "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"

covars = unlist(strsplit(covarname, ","))  # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"

# check covarname
for (cov in covars) {
  # print(cov)
  # print(cov %in% colnames(covariates))
  if(!cov %in% colnames(covariates)) stop(paste("\n\n  ERROR (gwas_diagnose.R) : The covariate '", cov, "' is not included in '", covarpath, "'.\n\n"))
}

covariates = covariates[,c("IID", covars)]   # keep only necessary lines; age_squared might not be used 
rownames(covariates) = covariates$IID

# head(covariates)

#             IID       PC1     PC2       PC3       PC4       PC5        PC6       PC7       PC8      PC9      PC10 array sex   age
# 1000027 1000027 -14.20630 4.88676 -1.077420  1.493080 -4.769030 -2.1676300  0.509630 -1.802300  5.21144  1.918070     3   0 55.27
# 1000039 1000039 -14.87840 5.49553 -0.564267  0.372418  4.593710 -0.5263310 -1.224820  1.441580  1.51997 -1.000270     2   0 62.26
# 1000040 1000040  -9.31768 3.14434  1.179110 -0.766216 -2.136190  0.6580010  2.561440 -0.261769 -2.83988 -1.332040     3   0 60.07
# 1000053 1000053 -13.26520 2.01425 -3.319700  1.187170  0.176755  0.0637719  0.422459  0.754097  4.79254  0.301277     3   0 64.07
# 1000064 1000064 -11.91490 6.88527  1.157530 -3.114030 -5.644040 -0.6851510 -0.237977  2.737650  2.19642 -2.087390     2   1 54.34
# 1000071 1000071 -10.44720 4.60355 -1.622490 -2.185330 -2.757930  0.5514320 -1.329740 -1.472890  1.92260  1.138680     3   0 61.17




## D) summary (if invoked on command line)

# /proj/sens2019016/GWAS_DEV/LIV_MULT5 > head LIV_MULT5_gwas_chr5.liv2.glm.linear
# #CHROM	POS	ID	REF	ALT1	A1	A1_FREQ	OBS_CT	BETA	SE	P
# 5	11882	rs376588128_A_T	A	T	T	0.266599	18771	0.0409518	0.0548738	0.455501
# 5	11883	rs370741740_C_G	C	G	G	0.266678	18771	0.0405081	0.054877	0.460425
# 5	11889	5:11889_CTTATAT_C	C	CTTATAT	CTTATAT	0.296017	18771	0.0153175	0.0527711	0.771618
# 5	12010	rs578095237_G_A	G	A	G	0.000735695	18771	0.667134	0.960382	0.48728
# 5	12041	rs55926606_T_A	T	A	A	0.276203	18771	0.0394798	0.0531723	0.457801
# 5	12225	rs28538767_A_G	A	G	G	0.275339	18771	0.0320767	0.0535808	0.549407
# 5	12398	rs527696348_G_C	G	C	G	0.00472043	18771	0.351275	0.37066	0.343294
# 5	13018	rs28769581_A_C	A	C	C	0.272438	18771	0.0227519	0.0538726	0.67279
# 5	13114	rs28824936_C_G	C	G	G	0.272442	18771	0.022577	0.0538706	0.67515



if(comparison) {

  cmd = paste("grep -Fw", marker , summaryfile)  # "grep -Fw rs767276217_A_G LIV_MULT5_gwas_chr5.liv2.glm.linear"
  sumstats = as.data.frame(fread(cmd = cmd, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE))  # nThread = 16, header = TRUE  

  # str(sumstats)
  #
  # 'data.frame':	1 obs. of  11 variables:
  #  $ V1 : int 5
  #  $ V2 : int 113761470
  #  $ V3 : chr "rs767276217_A_G"
  #  $ V4 : chr "A"
  #  $ V5 : chr "G"
  #  $ V6 : chr "A"
  #  $ V7 : num 0.000857
  #  $ V8 : int 18771
  #  $ V9 : num 5.41
  #  $ V10: num 0.812
  #  $ V11: num 2.7e-11
 
  # con <- file(summaryfile, "r")
  # header = readLines(con, n = 1)  # "#CHROM\tPOS\tID\tREF\tALT1\tA1\tA1_FREQ\tOBS_CT\tBETA\tSE\tP"
  # close(con)
  # header = unlist(strsplit(header, "\t"))  # "#CHROM"  "POS"     "ID"      "REF"     "ALT1"    "A1"      "A1_FREQ" "OBS_CT"  "BETA"    "SE"      "P"      
  # str(header)  # chr [1:11] "#CHROM" "POS" "ID" "REF" "ALT1" "A1" "A1_FREQ" "OBS_CT" "BETA" "SE" "P"
  
  header = as.character(read.table(summaryfile, header = FALSE, comment.char = "", nrows = 1, stringsAsFactors = FALSE))   
  # str(header)  # chr [1:11] "#CHROM" "POS" "ID" "REF" "ALT1" "A1" "A1_FREQ" "OBS_CT" "BETA" "SE" "P"

  if(length(colnames(sumstats)) != length(header)) { 
    stop(paste("\n\n  ERROR (gwas_diagnose.R) : Summary stats file has", length(colnames(sumstats)),"columns but header has", length(header),".\n\n")) 
  }  else {
    colnames(sumstats) = header 
  } 
  
  # colnames(sumstats)[1]  # "#CHROM"
  colnames(sumstats)[1] = "CHROM"
   
  # sumstats   # the plink results  
  #
  #  CHROM       POS              ID REF ALT1 A1     A1_FREQ OBS_CT   BETA       SE           P
  #  1     5 113761470 rs767276217_A_G   A    G  A 0.000857388  18771 5.4109 0.811706 2.70031e-11
  
  # which(sumstats$ID == marker)  # don't trust the grep ;-) 
  sumstats = sumstats[which(sumstats$ID == marker),] 
  if(nrow(sumstats) != 1) stop(paste("\n\n  ERROR (gwas_diagnose.R) : More than one entry of '", marker, "' in '", summaryfile, "'??\n\n"))

} #  if(comparison)

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n\n"))


cat(paste("  Genotype file: counted allele is", counted_allele, ", other allele is", other_allele, "\n\n"))

 








## +++ Venn diagram over samples in phenotype (y), genotype, and covariates  


ids = list(y$IID, genotype$IID, covariates$IID) 

# str(ids)
# List of 3
#  $ : int [1:26753] 1000401 1000435 1000456 1000493 1000843 1000885 1001146 1001215 1001310 1001399 ...
#  $ : int [1:487409] 5954653 1737609 1427013 3443403 5807741 4188953 1821438 3951387 5670866 1207760 ...
#  $ : int [1:337482] 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000125 1000154 ...

# myCol = c("turquoise2", "orange2", "red1")

catnames = c("phenotype", "genotype", "covariates")
vplot = venn.diagram(ids, category.names = catnames, filename = NULL, output = FALSE)  #  height = 500, width = 500, resolution = 100

# creates VennDiagram2020-07-29_09-40-54.log
logfile = list.files(pattern = "VennDiagram.+log")
if(file.exists(logfile)) invisible(file.remove(logfile))

vennplot = paste0("diagnose_venn_", marker, "_allele_", counted_allele, ".png")
png(vennplot, width = 600, height = 600)
grid.draw(vplot)
invisible(dev.off())
cat(paste("  Venn diagram saved to '", vennplot, "'.\n\n"))

# length(ids[[1]])  # 26753
# length(ids[[2]])  # 487409
# length(ids[[3]])  # 337482

nr_common = length(intersect(intersect(ids[[1]], ids[[2]]), ids[[3]]))     
cat(paste("  We have", nr_common, "common samples in the input files (phenotype, genotype, covariates).\n\n"))








## +++ Merge response, predictor, and covariates to dataframe 

data = merge(y, genotype, by = "row.names")   # response and predictor

# head(data)
#   Row.names   IID.x      liv5   IID.y rs767276217_A_G_A
# 1   1000435 1000435  6.422990 1000435                 0
# 2   1000493 1000493  2.540824 1000493                 0
# 3   1000843 1000843  8.470966 1000843                 0
# 4   1000885 1000885 21.822642 1000885                 0
# 5   1001146 1001146  1.172032 1001146                 0
# 6   1001215 1001215 11.737968 1001215                 0

data$IID.x <- NULL 
data$IID.y <- NULL

# colnames(data) #  "Row.names"     "liv2"     "rs767276217_A_G_A" 

# colnames(data)[1]  # Row.names
colnames(data)[1] = "IID"
# colnames(data)[3]  # rs188247550_T_C_T
colnames(data)[3] = "geno"

# colnames(data)  #  "IID"         "liver_fat_a" "geno"

 

if(switch_allele) data$geno = 2 - data$geno 

rownames(data) = data$IID

# head(data)
# 
#             IID liver_fat_a geno
# 1000015 1000015    2.604362    0
# 1000435 1000435    5.393000    0
# 1000493 1000493    3.610108    0
# 1000795 1000795    1.443066    0
# 1000843 1000843    9.580051    0
# 1000885 1000885   23.596000    0



data = merge(data, covariates, by = "row.names")  # add covariates 

# head(data)
# 
#   Row.names   IID.x liver_fat_a geno   IID.y       PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9
# 1   1000435 1000435    5.393000    0 1000435  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610
# 2   1000493 1000493    3.610108    0 1000493 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152
# 3   1000843 1000843    9.580051    0 1000843 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820
# 4   1001070 1001070    1.269000    0 1001070 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910
# 5   1001146 1001146    1.401959    0 1001146 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600
# 6   1001271 1001271    1.536000    0 1001271 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660
#         PC10 array sex   age
# 1 -0.4900740     3   0 51.21
# 2 -1.4455700     2   1 53.99
# 3 -0.2851930     3   1 58.45
# 4 -0.0914199     3   0 52.17
# 5  0.3356860     3   1 66.94
# 6 -3.2000799     3   0 40.72


data$IID.x <- NULL 
data$IID.y <- NULL

# colnames(data)[1]  # Row.names
colnames(data)[1] = "IID"

rownames(data) = data$IID

# head(data)
# 
#             IID liver_fat_a geno       PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9       PC10 array
# 1000435 1000435    5.393000    0  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610 -0.4900740     3
# 1000493 1000493    3.610108    0 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152 -1.4455700     2
# 1000843 1000843    9.580051    0 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820 -0.2851930     3
# 1001070 1001070    1.269000    0 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910 -0.0914199     3
# 1001146 1001146    1.401959    0 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600  0.3356860     3
# 1001271 1001271    1.536000    0 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660 -3.2000799     3
#         sex   age
# 1000435   0 51.21
# 1000493   1 53.99
# 1000843   1 58.45
# 1001070   0 52.17
# 1001146   1 66.94
# 1001271   0 40.72


datafile = paste0("diagnose_data_", marker, "_allele_", counted_allele, ".RData")  #  "diagnose_data_rs767276217_A_G_allele_A.RData"
save(data, file = datafile)  
cat(paste("  Regression input frame saved to '", datafile, "'.\n\n"))



## Range of genotype variable for the marker 
rd = range(data$geno)  #  0 1
cat(paste("  The genotype for this marker ranges between", rd[1],"and", rd[2], "\n"))
if(sum(rd == c(0,2)) != 2) cat("   ( which can be considered as somewhat unusual )\n") 
cat("\n")






## +++ Linear Regression with lm()  

# A) regress on counted allele

# covars # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"   defined above

cform = paste(covars, collapse = " + ")  # "PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"
form = paste(phenoname, "~ geno +", cform)
formula = as.formula(form)  #  liver_fat_a ~ geno + PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age
cat(paste("  Regression using: ", form, "\n\n"))

lmout = lm(formula, data = data)   

# summary(lmout)  
# 
# Residuals:
#     Min      1Q  Median      3Q     Max 
# -9.5782 -2.3338 -1.6371  0.0666 30.3653 
# 
# Coefficients:
#               Estimate Std. Error t value Pr(>|t|)    
# (Intercept)  4.5656964  0.3853443  11.848  < 2e-16 ***
# geno         5.4108808  0.8117073   6.666  2.7e-11 ***
# PC1          0.0171106  0.0214514   0.798  0.42509    
# PC2         -0.0001426  0.0220933  -0.006  0.99485    
# PC3          0.0273945  0.0215347   1.272  0.20335    
# PC4          0.0350439  0.0161080   2.176  0.02960 *  
# PC5          0.0078756  0.0071204   1.106  0.26871    
# PC6         -0.0036605  0.0202976  -0.180  0.85689    
# PC7          0.0217415  0.0184392   1.179  0.23838    
# PC8          0.0013879  0.0182367   0.076  0.93934    
# PC9          0.0085552  0.0084307   1.015  0.31023    
# PC10         0.0428591  0.0157036   2.729  0.00635 ** 
# array       -0.1317851  0.0497441  -2.649  0.00807 ** 
# sex          1.0848101  0.0660937  16.413  < 2e-16 ***
# age         -0.0131496  0.0044581  -2.950  0.00319 ** 
# 
# Residual standard error: 4.501 on 18756 degrees of freedom
# Multiple R-squared:  0.01828,	Adjusted R-squared:  0.01754 
# F-statistic: 24.94 on 14 and 18756 DF,  p-value: < 2.2e-16







## +++ Save the residuals

residuals = resid(lmout)

#  str(residuals)
#  Named num [1:27243] 2.242 -0.967 5.251 -2.111 -2.976 ...
#  - attr(*, "names")= chr [1:27243] "1000435" "1000493" "1000843" "1001070" ...


residfile = paste0("diagnose_residuals_", marker, "_allele_", counted_allele, ".RData") # diagnose_residuals_rs188247550_T_C_allele_T.RData
save(residuals, file = residfile)  
cat(paste("  Residuals saved to '", residfile, "'.\n\n"))






 
## +++ Some metrics: 
 
# str(lmout) 
# str(summary(lmout))


beta = summary(lmout)$coefficients["geno", "Estimate"]	# 5.410881
sigma = summary(lmout)$sigma 				# 4.501213  standard deviation of error term			
fstatistic = summary(lmout)$fstatistic[1]		# 24.9423	
r.squared = summary(lmout)$r.squared  			# 0.01827734		
adj.r.squared = summary(lmout)$adj.r.squared 		# 0.01754456	

ci_slope = confint(lmout)["geno",]			# confidence interval for beta (slope) 
#    2.5 %   97.5 % 
# 3.819861 7.001901

# extractAIC(lmout)  		# 15.00 56491.18
aic = extractAIC(lmout)[2] 	# 56491.18  Akaike information criterion 

metric = c("sigma", "Fstat", "Rsquared", "Rsq.adj", "CI_low", "beta", "CI_up", "AIC")
mvalue = c(sigma, fstatistic, r.squared, adj.r.squared, ci_slope[1], beta, ci_slope[2], aic) 

# mvalue = signif(mvalue, 4)     
metric.df = data.frame(value = mvalue) 
rownames(metric.df) = metric

# metric.df
#                 value
# sigma    4.501213e+00
# Fstat    2.494230e+01
# Rsquared 1.827734e-02
# Rsq.adj  1.754456e-02
# CI_low   3.819861e+00
# beta     5.410881e+00
# CI_up    7.001901e+00
# AIC      5.649118e+04

 
metricfile = paste0("diagnose_metric_", marker, "_allele_", counted_allele, ".RData")
save(metric.df, file = metricfile)  
cat(paste("  Regression metrics frame saved to '", metricfile, "'.\n\n"))




 


## +++ Regression results:

lm_table = as.data.frame(summary(lmout)$coefficients) 
lmfile = paste0("diagnose_lmtable_", marker, "_allele_", counted_allele, ".RData") 	#  diagnose_lmtable_rs767276217_A_G_allele_A.RData
save(lm_table, file = lmfile) 
cat(paste("  Regression results for allele", counted_allele, "saved to '", lmfile, "'\n\n"))







## +++ Heatmap for correlation matrix for the regressors

covmatrix = summary(lmout, correlation = TRUE)$correlation[-1,-1]  # skip intercept
# cols = colorRampPalette(c("red", "yellow", "green"))(n = 299)
cols = "heat.colors"   # which is the default
show.key = TRUE   # logical   show color key

heatplot = paste0("diagnose_heatmap_", marker, "_allele_", counted_allele, ".png")	# diagnose_heatmap_rs767276217_A_G_allele_A.png
png(heatplot, width = 1000, height = 1000)  # bigger than other plots because of cellnotes = correlation
heatmap.2(covmatrix, Colv = FALSE, Rowv = FALSE, dendrogram = "none", col = cols, margins = c(7,7), lwid = c(5,15), lhei = c(3,15), 
          cellnote = round(covmatrix,2), notecol = "black", trace = "none", main = "Correlation matrix", notecex = 0.95, key = show.key)   
invisible(dev.off())
cat(paste("  Correlation heatmap saved to '", heatplot, "'\n\n"))


  





## +++ Variance inflation factors     

inflation = vif(lmout)

# geno        PC1        PC2        PC3        PC4        PC5        PC6        PC7        PC8        PC9       PC10      array 
#   1.000899   1.108453   1.036331   1.081601   2.003667   2.011130   1.068473   1.087717   1.248596   1.062474   1.241270   1.002210 
#        sex        age 
#   1.011510   1.014997

# which(sqrt(inflation) > 2)    # can be empty

rating = ifelse(sqrt(inflation) > 2, "!!", "ok")
vif.df = data.frame(vif = inflation, rating = rating) 

viffile = paste0("diagnose_vif_", marker, "_allele_", counted_allele, ".RData")  # diagnose_vif_rs767276217_A_G_allele_A.RData 
save(vif.df, file = viffile)  
cat(paste("  Variance inflation factors saved to '", viffile, "'.\n\n"))








### +++ Comparison of plink results with R results:

if(comparison) {   

  # sumstats
  #    CHROM       POS              ID REF ALT1 A1     A1_FREQ OBS_CT   BETA       SE           P
  # 1      5 113761470 rs767276217_A_G   A    G  A 0.000857388  18771 5.4109 0.811706 2.70031e-11

  # str(sumstats)
  # 'data.frame':	1 obs. of  11 variables:
  #  $ CHROM  : int 5
  #  $ POS    : int 113761470
  #  $ ID     : chr "rs767276217_A_G"
  #  $ REF    : chr "A"
  #  $ ALT1   : chr "G"
  #  $ A1     : chr "A"
  #  $ A1_FREQ: num 0.000857
  #  $ OBS_CT : int 18771
  #  $ BETA   : num 5.41
  #  $ SE     : num 0.812
  #  $ P      : num 2.7e-11

  beta.R = signif(lm_table["geno","Estimate"],5)   	# 5.410881     same as slope above
  se.R = signif(lm_table["geno", "Std. Error"],6)  	# 0.8117073    Std. Error
  p.R = signif(lm_table["geno", "Pr(>|t|)"],6)     	# 2.70094e-11  Pr(>|t|)
  a1.R = counted_allele 		 		# "A"
  obs.R = nobs(lmout) 			 		# 18771    number of observations, see also Venn diagram 
  id.R = marker 			 		# "rs767276217_A_G"
  chrom.R = "-"
  pos.R = "-"
  ref.R = "-"
  alt1.R = "-" 
  a1_freq.R = "-" 
    
  Rvec = c(chrom.R, pos.R, id.R, ref.R, alt1.R, a1.R, a1_freq.R, obs.R, beta.R, se.R, p.R)   
  
  comp.df = rbind(sumstats, Rvec)
  rownames(comp.df) = c("plink2", "Rscript") 

  # comp.df
  #         CHROM       POS              ID REF ALT1 A1     A1_FREQ OBS_CT   BETA       SE           P
  # plink2      5 113761470 rs767276217_A_G   A    G  A 0.000857388  18771 5.4109 0.811706 2.70031e-11
  # Rscript     -         - rs767276217_A_G   -    -  A           -  18771 5.4109 0.811707 2.70094e-11

  comparisonfile = paste0("diagnose_comparison_", marker, "_allele_", counted_allele, ".RData")  # diagnose_comparison_rs767276217_A_G_allele_A.RData  
  save(comp.df, file = comparisonfile)  
  cat(paste("  Comparison PLINK vs. R results for allele", counted_allele, "saved to '", comparisonfile, "'.\n\n"))

} else {

  cat("  Cannot provide comparison with PLINK results - no summary statistics file for plink results available.\n\n") 
  comparisonfile = "none" 

} # if(comparison)outliers$bonf.p)








## +++ Outliers:

# outliers = outlierTest(lmout, cutoff = 0.05, n.max = nrow(data), labels = data$IID)

outliers = outlierTest(lmout, cutoff = 0.05, n.max = nrow(data))   

if(class(outliers) == "outlierTest") {   # outliers found

  outlier_indx = which(rownames(data) %in% names(outliers$bonf.p))  	# index of the outlier, for the scatter plot below!!
  nr_outliers = length(outliers$bonf.p)		     			# 133 
  cat(paste("  Number of hypopthetical outliers among observations:", nr_outliers, "\n\n"))

  outlier.df = data.frame(id = names(outliers$bonf.p), rstudent = outliers$rstudent, p.bonf = outliers$bonf.p)  
  rownames(outlier.df) = outlier.df$id 

  # head(outlier.df) 

  #              id rstudent       p.bonf
  # 1158510 1158510 6.756614 2.729336e-07
  # 4655246 4655246 6.642688 5.940419e-07
  # 5229099 5229099 6.615370 7.144849e-07
  # 2481699 2481699 6.598830 7.986968e-07
  # 1676124 1676124 6.582815 8.894593e-07
  # 4492282 4492282 6.499400 1.551819e-06

  outlierfile = paste0("diagnose_outlier_", marker, "_allele_", counted_allele, ".RData")  #  diagnose_outlier_rs767276217_A_G_allele_A.RData  
  save(outlier.df, file = outlierfile)  
  cat(paste("  Outlier list for allele", counted_allele, "saved to '", outlierfile, "'.\n\n"))

} else {

  cat("  No outliers identified in this dataset.\n\n")
  outlierfile = "none"
  nr_outliers = 0 
    
}






## +++ Influential variables:

# Cook's distance:

cook = cooks.distance(lmout)  	

names(cook) = names(lmout$residuals)

# str(cook) 
#  Named num [1:18771] 6.58e-05 6.83e-06 2.24e-05 2.86e-05 2.59e-05 ...
#  - attr(*, "names")= chr [1:18771] "1000435" "1000493" "1000843" "1001146" ...

nr_observations = nrow(data)       	# number of observations
nr_predictors = ncol(data) - 2  	# number of predictors (assume IID and phenoname column !!)

# cook.cutoff <- 4/((nrow(data)-length(lmout$coefficients)-2))
cook.cutoff = qf(0.5, df1 = nr_predictors, df2 = nr_observations - nr_predictors)  #  0.9528393

nr_influencer = length(cook[cook >= cook.cutoff])

# cook[cook >= 0.05]
#    3877730    4046379    5246412 
# 0.06086903 0.05083644 0.05504663 



# store all data points with Cooks distance > cutoff

if(nr_influencer > 0) {

  cook = cook[cook >= cook.cutoff]
  cook.df = data.frame(id = names(cook), Cook.D = cook)

  #             id     Cook.D
  # 3877730 3877730 0.06086903
  # 5246412 5246412 0.05504663
  # 4046379 4046379 0.05083644
  # 2720634 2720634 0.04314385
  # 4818841 4818841 0.03482840
  # 5472869 5472869 0.02914145

  influencer_indx = which(rownames(data) %in% names(cook[cook >= cook.cutoff]))  # for the scatterplot below  might be integer(0)
  # influencer_indx  6365 10629 11255 14184 15812 16650

  # save frame to .RData:
  cookfile = paste0("diagnose_cook_", marker, "_allele_", counted_allele, ".RData")	 
  save(cook.df, file = cookfile)  
  cat(paste("  Cook's distance data for allele", counted_allele, "saved to '", cookfile, "'.\n\n"))

} else {

   cat("  No observation identified with Cooks D above cutoff.\n\n")
   cookfile = "none"  
} 

# the corresponding plot: 

cooks_D_plot = paste0("diagnose_cook_", marker, "_allele_", counted_allele, ".png")
png(cooks_D_plot, width = plotwidth, height = plotheight)
plot(lmout, which = 4)
invisible(dev.off())
cat(paste("  Cook's-D plot saved to '", cooks_D_plot, "'\n\n")) 







## +++ Scatter plot of the counted allele, with regression line, marked outliers and influential observations: 

scatterplot = paste0("diagnose_scatter_", marker, "_allele_", counted_allele, ".png")
png(scatterplot, width = plotwidth, height = plotheight)   #  width = 800, height = 600      600 480

  xl = paste("genotype of", counted_allele)
  yl = paste("phenotype", phenoname) 
  main = paste("Phenotype vs. allele", counted_allele, "for", marker) 

  colvec = rep("black", nrow(data))
  if(nr_outliers > 0) colvec[outlier_indx] = "blue"
  if(nr_influencer > 0) colvec[influencer_indx] = "red"
     
  # outsider_indx = intersect(outlier_indx, influencer_indx)  # both outliers and influencers  
  # colvec[outsider_indx] = ""
 
  plot(jitter(data$geno, factor = 1, amount = 0), data[[phenoname]], xlab = xl, ylab = yl, main = main, font.main = 1, col = colvec, pch = 18)   
  mtext(side = 3, paste("Based on", nr_common, "individuals"), cex = 0.9, col = "blue")

  # abline(lmout)   
  intercept = summary(lmout)$coefficients["(Intercept)", "Estimate"]  #  4.565696
  slope = summary(lmout)$coefficients["geno", "Estimate"]   # 5.410881
  abline(intercept, slope, col = "blue", lty = 2, lwd = 1.7)

  p.value = summary(lmout)$coefficients["geno", "Pr(>|t|)"]    # for marker
  r.squared = summary(lmout)$adj.r.squared  # adjusted  

  l1 = paste("slope:", signif(slope,4)) 
  l2 = paste("p-value:", signif(p.value,4))
  l3 = paste("R-squared:", signif(r.squared, 4)) 
  leg = c(l1, l2,l3) 
  legend("top", col = c("red"), leg = leg, pch = 1)

invisible(dev.off())
cat(paste("  Scatterplot for allele", counted_allele, "saved to '", scatterplot, "' (x-axis jittered)\n\n"))    











## +++ Diagnostic plots:      https://data.library.virginia.edu/diagnostic-plots/



## ++ Histogram of the residuals

histplot = paste0("diagnose_histogram_", marker, "_allele_", counted_allele, ".png")
png(histplot, width = plotwidth, height = plotheight)
hist(resid(lmout), col = "red", breaks = 30, main = "Histogram over Residuals", font.main = 1, xlab = "Residuals")
invisible(dev.off())
cat(paste("  Histogram for residuals saved to '", histplot, "'\n\n")) 





## ++ Histogram of the phenotype

histplot_pheno = paste0("diagnose_histogram_pheno_", marker, "_allele_", counted_allele, ".png")
png(histplot_pheno, width = plotwidth, height = plotheight)
hist(y[[phenoname]], col = "red", breaks = 30, main = "Histogram for Phenotype", font.main = 1, xlab = "Phenotype")
invisible(dev.off())
cat(paste("  Histogram for the phenotype variable saved to '", histplot_pheno, "'\n\n")) 







## ++ 1. Residuals vs Fitted

vartest = ncvTest(lmout)

# Non-constant Variance Score Test 
# Variance formula: ~ fitted.values 
# Chisquare = 267.31, Df = 1, p = < 2.22e-16

# str(vartest)
# List of 6
#  $ formula     :Class 'formula'  language ~fitted.values
#   .. ..- attr(*, ".Environment")=<environment: 0x14065dd8> 
#  $ formula.name: chr "Variance"
#  $ ChiSquare   : num 267
#  $ Df          : num 1
#  $ p           : num 4.38e-60
#  $ test        : chr "Non-constant Variance Score Test"
#  - attr(*, "class")= chr "chisqTest"

ncv.p = vartest$p 


residplot = paste0("diagnose_residuals_", marker, "_allele_", counted_allele, ".png")
png(residplot, width = plotwidth, height = plotheight)
plot(lmout, which = 1)
# mtext(side = 1, paste("Non-constant Variance Score Test: p =", ncv.p), cex = 0.9, col = "blue") # interferes with title ...
# alternative: residualPlot(lmout)   # Residual plot  library(car)
invisible(dev.off())
cat(paste("  Residuals vs. Fitted plot saved to '", residplot, "'\n\n")) 





## ++ 2. Normal Q-Q plot of the residuals (NOT the p-values)

qqplot = paste0("diagnose_qqplot_", marker, "_allele_", counted_allele, ".png")
png(qqplot, width = plotwidth, height = plotheight)
plot(lmout, which = 2)
# alternative: qqPlot(resid(lmout), distribution = "norm", main = "QQPlot")   library(car)
invisible(dev.off())
cat(paste("  Normal QQ-plot for residuals saved to '", qqplot, "'\n\n")) 







## ++ 3. Scale-Location

scaleplot = paste0("diagnose_scaleplot_", marker, "_allele_", counted_allele, ".png")
png(scaleplot, width = plotwidth, height = plotheight)
plot(lmout, which = 3)
invisible(dev.off())
cat(paste("  Scale-Location plot for residuals saved to '", scaleplot, "'\n\n")) 





## ++ 4. Residuals vs Leverage

residuals_leverage_plot = paste0("diagnose_res_leverage_", marker, "_allele_", counted_allele, ".png")
png(residuals_leverage_plot, width = plotwidth, height = plotheight)
plot(lmout, which = 5)
invisible(dev.off())
cat(paste("  Residuals vs. leverage plot saved to '", residuals_leverage_plot, "'\n\n"))





 
## +++ Autocorrelation of the residuals:

durbin = durbinWatsonTest(lmout)  # takes some time

# str(durbin)
# List of 4
#  $ r          : num -0.00908
#  $ dw         : num 2.02
#  $ p          : num 0.212
#  $ alternative: chr "two.sided"
#  - attr(*, "class")= chr "durbinWatsonTest"

# durbin 
#  lag Autocorrelation D-W Statistic p-value
#    1    -0.009084928      2.018117    0.18
#  Alternative hypothesis: rho != 0

durbin.p = durbin$p  #  0.212

auto = acf(resid(lmout), plot = FALSE)  

n1 = dim(auto$acf)[1] 
auto$acf <- array(auto$acf[2:n1], dim = c(n1-1, 1, 1))  # remove lag 0 
auto$lag <- array(auto$lag[2:n1], dim = c(n1-1, 1, 1))  # remove lag 0  

acfplot = paste0("diagnose_acfplot_", marker, "_allele_", counted_allele, ".png")
png(acfplot, width = plotwidth, height = plotheight)
maintxt = "Autocorrelation of the residuals"
plot(auto, main = maintxt, font.main = 1)
mtext(side = 3, paste("Durbin-Watson: p =", durbin.p), cex = 0.9, col = "blue")
invisible(dev.off())
cat(paste("  Autocorrelation plot for allele", counted_allele, "saved to '", acfplot, "'\n\n"))    






## +++ Inverse response plot

responseplot = paste0("diagnose_response_", marker, "_allele_", counted_allele, ".png")
png(responseplot, width = plotwidth, height = plotheight)
invresp = try(inverseResponsePlot(lmout), silent = TRUE)  # often fails with "Error in bc1(out, lambda) : First argument must be strictly positive."

# class(invresp)  # "data.frame"   if succesful 
# class(invresp)  # "try-error" if failed 
  
invisible(dev.off())

if(class(invresp) == "data.frame") {

  irp_lambda = invresp$lambda[1]
  cat(paste("  Inverse response plot saved to '", responseplot, "'\n\n")) 

  # str(invresp)
  # 'data.frame':	4 obs. of  2 variables:
  #  $ lambda: num  -0.447 -1 0 1
  #  $ RSS   : num  6785 6831 6811 6946

  responsfile = paste0("diagnose_invresponse_", marker, "_allele_", counted_allele, ".RData")
  save(invresp, file = responsfile)  
  cat(paste("  Inverse response frame saved to '", responsfile, "'.\n\n"))

} else {

  responsfile = "none"
  responseplot = "none"
  irp_lambda = NA
  
}



if(FALSE) {

  ## Marginal/conditional plot of marker genotype 

  mcplot = paste0("diagnose_condplot_", marker, "_allele_", counted_allele, ".png")
  png(mcplot, width = plotwidth, height = plotheight)
  mcPlot(lmout, variable = "geno")
  invisible(dev.off())
  cat(paste("  Marginal/conditional plot saved to '", mcplot, "'\n\n")) 


  ## ++ Marginal model plot:

  mmpplot = paste0("diagnose_mmp_", marker, "_allele_", counted_allele, ".png")
  png(mmpplot, width = plotwidth, height = plotheight)
  mmp(lmout)
  invisible(dev.off())
  cat(paste("  MMP plot saved to '", mmpplot, "'\n\n")) 

}







## +++ Creating html


plist = list()
plist["workfolder"] = getwd() 
plist["marker"] = marker 
plist["nr_observations"] = nr_observations 
plist["nr_predictors"] = nr_predictors 		
plist["vennplot"] = vennplot
plist["nr_common"] = nr_common
plist["datafile"] = datafile
plist["form"] = form
plist["residfile"] = residfile
plist["metricfile"] = metricfile
plist["lmfile"] = lmfile
plist["heatplot"] = heatplot
plist["viffile"] = viffile
plist["comparisonfile"] = comparisonfile
plist["comparison"] = comparison
plist["outlierfile"] = outlierfile
plist["nr_outliers"] = nr_outliers
plist["nr_influencer"] = nr_influencer
plist["cookfile"] = cookfile
plist["scatterplot"] = scatterplot
plist["histplot"] = histplot
plist["histplot_pheno"] = histplot_pheno
plist["ncv.p"] = ncv.p
plist["residplot"] = residplot
plist["qqplot"] = qqplot
plist["scaleplot"] = scaleplot
plist["cooks_D_plot"] = cooks_D_plot
plist["cook.cutoff"] = cook.cutoff
plist["residuals_leverage_plot"] = residuals_leverage_plot  
plist["durbin.p"] = durbin.p
plist["acfplot"] = acfplot
plist["responseplot"] = responseplot
plist["responsfile"] = responsfile
plist["irp_lambda"] = irp_lambda



# save this list for debugging 
plistfile = "rmd_diagnose_params.RData"
save(plist, file = plistfile)   
cat(paste("  Parameter list for Rmarkdown saved to '", plistfile, "' \n\n"))



cat(paste("  Rendering file", rmd_copy, " ..."))   
start_time = Sys.time()  

if(comparison) {
  htmlfile = paste0("diagnose_", marker, "_allele_", counted_allele, ".html")
} else {
  htmlfile = paste0("diagnose_", marker, "_allele_", counted_allele, "_nocomp.html")  # diagnose_rs767276217_A_G_allele_A_nocomp.html
}

rmarkdown::render(rmd_copy, params = plist, output_dir = getwd(), output_file = htmlfile, quiet = TRUE)  

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("  Done in", round(diff_time,2), "seconds.\n"))

# if(!file.remove(rmd_copy)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Could not remove file ",  rmd_copy,  ".\n\n"))







## +++ Finish

cat(paste("\n  Open '", htmlfile, "' with your favoured browser.\n"))
cat(paste("\n  ", date(),"\n\n"))
cat("  Done.\n\n")  


 
## +++ KELLER

# uwe.menzel@medsci.uu.se  

# infl = influence(lmout)
# deviance(lmout)  		# 380013.7
# infIndexPlot(lmout)  		# four plots 
# leveneTest(lmout) 		# Levene's test is not appropriate with quantitative explanatory variables. 
# model.matrix(lmout)  
# qr(lmout)
















