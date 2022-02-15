#!/usr/bin/env Rscript      


# uwe.menzel@medsci.uu.se  



 
## === Regression diagnostics for GWAS 
#
#      WITHOUT marker, just the phenotype vs. the covariates





# TEST, command line:
#
#  pwd # /proj/sens2019016/GWAS_DEV3/liver10
#  module load R_packages/3.6.1
#  gwas_diagnose_nomarker.R   <phenopath>  <phenoname>   <covarpath>   <covarname>   
#  gwas_diagnose_nomarker.R   liver_fat_ext.txt  liver_fat_a  GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age   


# SLURM command:
# sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  --wrap="module load R_packages/3.6.1; gwas_diagnose_nomarker.R ...
# sbatch  -A sens2019016 -p node  -t 10:00  -J DIAG_NM -o diagnose_R_nomarker.log -e diagnose_R_nomarker.log --wrap="module load R_packages/3.6.1; gwas_diagnose_nomarker.R ..."


# TESTING:
#
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 3:00:00 -A sens2019016 
#   module load R_packages/3.6.1
#   . s2
#   which review_gwas.R
#   gwas_diagnose_nomarker.R   liver_fat_ext.txt  liver_fat_a  GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age







## +++ Plot parameters 

plotwidth = 600
plotheight = 600





## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 4) {
  cat("\n")
  cat("  Usage: gwas_diagnose_nomarker   <phenopath>  <phenoname>  <covarpath>  <covarname> \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

		
phenopath = args[1]		    
phenoname = args[2]
covarpath = args[3]
covarname = args[4]



# TEST, R-console:
# getwd() 	# /proj/sens2019016/GWAS_DEV3/liver10		
# phenopath = "liver_fat_ext.txt" 		     
# phenoname = "liver_fat_a" 
# covarpath = "GWAS_covariates.txt" 
# covarname = "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age" 









## +++ Libraries, Functions

cat("\n\n  Loading packages ...  ") 
start_time = Sys.time() 
suppressMessages(suppressWarnings(library(VennDiagram)))  	# venn.diagram
suppressMessages(suppressWarnings(library(car)))		# vif, outlierTest and more 
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
  stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R): Environment variable 'SCRIPT_FOLDER' not set.\n\n"))  
} else {
  cat(paste("\n  Environment variable 'SCRIPT_FOLDER' is set to", scripts, "\n\n"))
}







# Rmarkdown template :

rmd = paste(scripts, "gwas_diagnose_nomarker.Rmd", sep="/")

if(!file.exists(rmd)) stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R): Rmarkdown template ",  rmd,  " not found.\n\n"))
rmd_copy = paste(getwd(), "gwas_diagnose.Rmd", sep="/")  	# /castor/project/proj/GWAS_DEV/LIV_MULT5/gwas_diagnose.Rmd

# copy the .Rmd file to the current folder ==> working directory for knitr
if(!file.copy(rmd, rmd_copy, overwrite = TRUE)) stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R): Could not copy file ",  rmd,  " to the current folder.\n\n"))
if(!file.exists(rmd_copy)) stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R): Rmarkdown template ",  rmd,  " not copied to current location.\n\n"))







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
cat(paste("  Phenotype path:", phenopath, "\n"))
cat(paste("  Phenonames:", phenoname, "\n"))
cat(paste("  Covariates path:", covarpath, "\n"))
cat("\n") 



 




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
  stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R) : Could not find the phenotype file: '", phenopath, "'.\n\n"))
}

# str(phenotype)
# 'data.frame':	26753 obs. of  12 variables:
#  $ X.FID: int  1000401 1000435 1000456 1000493 1000843 1000885 1001146 1001215 1001310 1001399 ...
#  $ IID  : int  1000401 1000435 1000456 1000493 1000843 1000885 1001146 1001215 1001310 1001399 ...
#  $ liv1 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv2 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv3 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv4 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv5 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv6 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv7 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv8 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv9 : num  4.61 6.42 3.14 2.54 8.47 ...
#  $ liv10: num  4.61 6.42 3.14 2.54 8.47 ...


if(phenoname %in% colnames(phenotype)) {
  y = phenotype[,c("IID", phenoname)]   # dependent variable  
} else {
  stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R) : The file '", phenopath, "' does not have a '", phenoname, "' column.\n\n"))
}

# str(y)
# 'data.frame':	26753 obs. of  2 variables:
#  $ IID : int  1000401 1000435 1000456 1000493 1000843 1000885 1001146 1001215 1001310 1001399 ...
#  $ liv5: num  4.61 6.42 3.14 2.54 8.47 ...

rownames(y) = y$IID


# head(y) 
#             IID      liv5
# 1000401 1000401  4.611772
# 1000435 1000435  6.422990
# 1000456 1000456  3.142304
# 1000493 1000493  2.540824
# 1000843 1000843  8.470966
# 1000885 1000885 21.822642








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
  stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R) : Could not find the covariate file: '", covarpath, "'.\n\n"))
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
  if(!cov %in% colnames(covariates)) stop(paste("\n\n  ERROR (gwas_diagnose_nomarker.R) : The covariate '", cov, "' is not included in '", covarpath, "'.\n\n"))
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



stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n\n"))


 








## +++ Venn diagram over samples in phenotype (y), genotype, and covariates  


ids = list(y$IID, covariates$IID) 

# str(ids)
# List of 2
#  $ : int [1:38948] 1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ : int [1:337482] 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000125 1000154 ...



# myCol = c("turquoise2", "orange2", "red1")

catnames = c("phenotype", "covariates")
vplot = venn.diagram(ids, category.names = catnames, filename = NULL, output = FALSE)  #  height = 500, width = 500, resolution = 100

# creates VennDiagram2020-07-29_09-40-54.log
logfile = list.files(pattern = "VennDiagram.+log")
if(file.exists(logfile)) invisible(file.remove(logfile))

vennplot = paste0("diagnose_venn_nomarker.png")
png(vennplot, width = 600, height = 600)
grid.draw(vplot)
invisible(dev.off())
cat(paste("  Venn diagram saved to '", vennplot, "'.\n\n"))

# length(ids[[1]])  # 26753
# length(ids[[2]])  # 487409
# length(ids[[3]])  # 337482

nr_common = length(intersect(ids[[1]], ids[[2]]))        
cat(paste("  We have", nr_common, "common samples in the input files (phenotype and covariates).\n\n"))








## +++ Merge response (y) and covariates to dataframe 

data = merge(y, covariates, by = "row.names")  

# head(data)

#   Row.names   IID.x liver_fat_a   IID.y       PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9       PC10
# 1   1000435 1000435    5.393000 1000435  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610 -0.4900740
# 2   1000493 1000493    3.610108 1000493 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152 -1.4455700
# 3   1000843 1000843    9.580051 1000843 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820 -0.2851930
# 4   1001070 1001070    1.269000 1001070 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910 -0.0914199
# 5   1001146 1001146    1.401959 1001146 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600  0.3356860
# 6   1001271 1001271    1.536000 1001271 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660 -3.2000799
#   array sex   age
# 1     3   0 51.21
# 2     2   1 53.99
# 3     3   1 58.45
# 4     3   0 52.17
# 5     3   1 66.94
# 6     3   0 40.72


data$IID.x <- NULL 
data$IID.y <- NULL

# colnames(data)[1]  # Row.names
colnames(data)[1] = "IID"

rownames(data) = data$IID

# head(data)
#
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


datafile = paste0("diagnose_data_nomarker.RData")  
save(data, file = datafile)  
cat(paste("  Regression input frame saved to '", datafile, "'.\n\n"))







## +++ Linear Regression with lm()  


# covars # "PC1"   "PC2"   "PC3"   "PC4"   "PC5"   "PC6"   "PC7"   "PC8"   "PC9"   "PC10"  "array" "sex"   "age"   defined above

cform = paste(covars, collapse = " + ")  # "PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"
form = paste(phenoname, "~", cform)  # WITHOUT marker
formula = as.formula(form) # liver_fat_a ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age 
cat(paste("  Regression using: ", form, "\n\n"))

lmout = lm(formula, data = data)   

# summary(lmout)  
# 
# Residuals:
#     Min      1Q  Median      3Q     Max 
# -4.2711 -2.2045 -1.5356  0.1795 30.8919 
# 
# Coefficients:
#               Estimate Std. Error t value Pr(>|t|)    
# (Intercept)  4.3253140  0.3002979  14.403  < 2e-16 ***
# PC1          0.0105954  0.0166804   0.635 0.525304    
# PC2          0.0100367  0.0172965   0.580 0.561736    
# PC3          0.0258195  0.0168422   1.533 0.125283    
# PC4          0.0385088  0.0125020   3.080 0.002071 ** 
# PC5          0.0030886  0.0055407   0.557 0.577235    
# PC6          0.0105742  0.0158458   0.667 0.504574    
# PC7          0.0298296  0.0143178   2.083 0.037225 *  
# PC8         -0.0049414  0.0141303  -0.350 0.726566    
# PC9         -0.0008966  0.0065653  -0.137 0.891375    
# PC10         0.0295603  0.0122263   2.418 0.015623 *  
# array       -0.1409512  0.0386284  -3.649 0.000264 ***
# sex          1.1387387  0.0513756  22.165  < 2e-16 ***
# age         -0.0092380  0.0034633  -2.667 0.007649 ** 
# ---
# 
# Residual standard error: 4.216 on 27229 degrees of freedom
# Multiple R-squared:  0.01948,	Adjusted R-squared:  0.01901 
# F-statistic: 41.62 on 13 and 27229 DF,  p-value: < 2.2e-16








## +++ Save the residuals

residuals = resid(lmout)

#  str(residuals)
#  Named num [1:27243] 2.242 -0.967 5.251 -2.111 -2.976 ...
#  - attr(*, "names")= chr [1:27243] "1000435" "1000493" "1000843" "1001070" ...

residfile = paste0("diagnose_residuals_nomarker.RData")  
save(residuals, file = residfile)  
cat(paste("  Residuals saved to '", residfile, "'.\n\n"))






 
## +++ Some metrics: 
 
# str(lmout) 
# str(summary(lmout))

sigma = summary(lmout)$sigma 				# 4.501213  standard deviation of error term			
fstatistic = summary(lmout)$fstatistic[1]		# 24.9423	
r.squared = summary(lmout)$r.squared  			# 0.01827734		
adj.r.squared = summary(lmout)$adj.r.squared 		# 0.01754456	
aic = extractAIC(lmout)[2] 				# 56491.18  Akaike information criterion 

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

metricfile = paste0("diagnose_metric_nomarker.RData")
save(metric.df, file = metricfile)  
cat(paste("  Regression metrics frame saved to '", metricfile, "'.\n\n"))




 


## +++ Regression results:

lm_table = as.data.frame(summary(lmout)$coefficients) 
lmfile = paste0("diagnose_lmtable_nomarker.RData") 	
save(lm_table, file = lmfile) 
cat(paste("  Regression results saved to '", lmfile, "'\n\n"))







## +++ Heatmap for correlation matrix for the regressors

covmatrix = summary(lmout, correlation = TRUE)$correlation[-1,-1]  # skip intercept
# cols = colorRampPalette(c("red", "yellow", "green"))(n = 299)
cols = "heat.colors"   # which is the default
show.key = TRUE   # logical   show color key

heatplot = paste0("diagnose_heatmap_nomarker.png")	
png(heatplot, width = 1000, height = 1000)  # bigger than other plots because of cellnotes = correlation
heatmap.2(covmatrix, Colv = FALSE, Rowv = FALSE, dendrogram = "none", col = cols, margins = c(7,7), lwid = c(5,15), lhei = c(3,15), 
          cellnote = round(covmatrix,2), notecol = "black", trace = "none", main = "Correlation matrix", notecex = 0.95, key = show.key)   
invisible(dev.off())
cat(paste("  Correlation heatmap saved to '", heatplot, "'\n\n"))


  





## +++ Variance inflation factors     

inflation = vif(lmout)

#      PC1      PC2      PC3      PC4      PC5      PC6      PC7      PC8      PC9     PC10    array      sex      age 
# 1.109465 1.036303 1.083822 1.995148 1.980776 1.067407 1.091136 1.241724 1.066883 1.243557 1.001764 1.010945 1.014016



# which(sqrt(inflation) > 2)    # can be empty

rating = ifelse(sqrt(inflation) > 2, "!!", "ok")
vif.df = data.frame(vif = inflation, rating = rating) 

viffile = paste0("diagnose_vif_nomarker.RData")  
save(vif.df, file = viffile)  
cat(paste("  Variance inflation factors saved to '", viffile, "'.\n\n"))








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

  outlierfile = paste0("diagnose_outlier_nomarker.RData")   
  save(outlier.df, file = outlierfile)  
  cat(paste("  Outlier list saved to '", outlierfile, "'.\n\n"))

} else {

  cat("  No outliers identified in this dataset.\n\n")
  
}






## +++ Influential variables:

# Cook's distance:

cook = cooks.distance(lmout)  	

names(cook) = names(lmout$residuals)

# str(cook) 
#  Named num [1:18771] 6.58e-05 6.83e-06 2.24e-05 2.86e-05 2.59e-05 ...
#  - attr(*, "names")= chr [1:18771] "1000435" "1000493" "1000843" "1001146" ...

nr_observations = nrow(data)       	# number of observations
nr_predictors = ncol(data) - 2  	# number of predictors (assume IID and pheno column !!)

# cook.cutoff <- 4/((nrow(data)-length(lmout$coefficients)-2))
cook.cutoff = qf(0.5, df1 = nr_predictors, df2 = nr_observations - nr_predictors)  #  0.9528393

nr_influencer = length(cook[cook >= cook.cutoff])

# cook[cook >= 0.05]
#    3877730    4046379    5246412 
# 0.06086903 0.05083644 0.05504663 

# cook = cook[cook >= cook.cutoff]

# store all data points with Cooks distance > cutoff, but at least six !!

if(length(cook[cook >= cook.cutoff]) > 6) {
  cook = cook[cook >= cook.cutoff]
} else {
  cook = head(sort(cook, decreasing = TRUE),6)
}

cook.df = data.frame(id = names(cook), Cook.D = cook)

#             id     Cook.D
# 3877730 3877730 0.06086903
# 5246412 5246412 0.05504663
# 4046379 4046379 0.05083644
# 2720634 2720634 0.04314385
# 4818841 4818841 0.03482840
# 5472869 5472869 0.02914145

influencer_indx = which(rownames(data) %in% cook.df$id)  # for the scatterplot below 

# influencer_indx  6365 10629 11255 14184 15812 16650


# save frame to .RData:

cookfile = paste0("diagnose_cook_nomarker.RData")	 
save(cook.df, file = cookfile)  
cat(paste("  Cook's distance data saved to '", cookfile, "'.\n\n"))

# the corresponding plot: 

cooks_D_plot = paste0("diagnose_cook_nomarker.png")
png(cooks_D_plot, width = plotwidth, height = plotheight)
plot(lmout, which = 4)
invisible(dev.off())
cat(paste("  Cook's-D plot saved to '", cooks_D_plot, "'\n\n")) 








## +++ Diagnostic plots:      https://data.library.virginia.edu/diagnostic-plots/



## ++ Histogram of the residuals

histplot = paste0("diagnose_histogram_nomarker.png")
png(histplot, width = plotwidth, height = plotheight)
hist(resid(lmout), col = "red", breaks = 30, main = "Histogram over Residuals", font.main = 1, xlab = "Residuals")
invisible(dev.off())
cat(paste("  Histogram for residuals saved to '", histplot, "'\n\n")) 



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


residplot = paste0("diagnose_residuals_nomarker.png")
png(residplot, width = plotwidth, height = plotheight)
plot(lmout, which = 1)
# mtext(side = 1, paste("Non-constant Variance Score Test: p =", ncv.p), cex = 0.9, col = "blue") # interferes with title ...
# alternative: residualPlot(lmout)   # Residual plot  library(car)
invisible(dev.off())
cat(paste("  Residuals vs. Fitted plot saved to '", residplot, "'\n\n")) 





## ++ 2. Normal Q-Q plot of the residuals (NOT the p-values)

qqplot = paste0("diagnose_qqplot_nomarker.png")
png(qqplot, width = plotwidth, height = plotheight)
plot(lmout, which = 2)
# alternative: qqPlot(resid(lmout), distribution = "norm", main = "QQPlot")   library(car)
invisible(dev.off())
cat(paste("  Normal QQ-plot for residuals saved to '", qqplot, "'\n\n")) 







## ++ 3. Scale-Location

scaleplot = paste0("diagnose_scaleplot_nomarker.png")
png(scaleplot, width = plotwidth, height = plotheight)
plot(lmout, which = 3)
invisible(dev.off())
cat(paste("  Scale-Location plot for residuals saved to '", scaleplot, "'\n\n")) 





## ++ 4. Residuals vs Leverage

residuals_leverage_plot = paste0("diagnose_res_leverage_nomarker.png")
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

acfplot = paste0("diagnose_acfplot_nomarker.png")
png(acfplot, width = plotwidth, height = plotheight)
maintxt = "Autocorrelation of the residuals"
plot(auto, main = maintxt, font.main = 1)
mtext(side = 3, paste("Durbin-Watson: p =", durbin.p), cex = 0.9, col = "blue")
invisible(dev.off())
cat(paste("  Autocorrelation plot saved to '", acfplot, "'\n\n"))    






## +++ Inverse response plot

responseplot = paste0("diagnose_response_nomarker.png")
png(responseplot, width = plotwidth, height = plotheight)
invresp = inverseResponsePlot(lmout) 
irp_lambda = invresp$lambda[1]
invisible(dev.off())
cat(paste("  Inverse response plot saved to '", responseplot, "'\n\n")) 

# str(invresp)
# 'data.frame':	4 obs. of  2 variables:
#  $ lambda: num  -0.447 -1 0 1
#  $ RSS   : num  6785 6831 6811 6946

responsfile = paste0("diagnose_invresponse_nomarker.RData")
save(invresp, file = responsfile)  
cat(paste("  Inverse response frame saved to '", responsfile, "'.\n\n"))





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
plist["outlierfile"] = outlierfile
plist["nr_outliers"] = nr_outliers
plist["nr_influencer"] = nr_influencer
plist["cookfile"] = cookfile
plist["histplot"] = histplot
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


htmlfile = paste0("diagnose_nomarker.html")


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
















