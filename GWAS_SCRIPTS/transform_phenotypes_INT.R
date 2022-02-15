#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Create the IN-transformed residuals after the 1st step of fully adjusted two-stage INT
#
#      these residuals should then be used as dependent variable in a regression on the genotype and the covariates
#      see also  "gwas_diagnose_INT.R"
#      article https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0233847&type=printable   



# TEST:      /castor/project/proj/GWAS_DEV3/liver10
#
# covarnames="PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"
# transform_phenotypes_INT  liver_fat_ext.txt  GWAS_covariates.txt  ${covarnames}
  

# OBS!!: never tested with multiple phenonames in the phenotype file !!!







## +++ Libraries, functions

quant_normal <- function(x, k = 3/8) {
  if (!is.vector(x)) stop("A numeric vector is expected for x.")   
  if ((k < 0) || (k > 0.5)) stop("Select the offset within the interval (0,0.5).")   
  n <- length(na.omit(x))
  rank.x <- rank(x, na.last = "keep")
  normalized = qnorm((rank.x - k)/(n - 2*k + 1))
  return(normalized)
}







## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     # print(args)

if(length(args) < 3) {
  cat("\n")
  cat("  Usage: transform_phenotypes_INT  <phenotype_file>  <covariate file>  <covariate columns>\n") 
  cat("         The phenotype file must be in the format requested by plink.\n") 
  cat("\n")
  quit("no")
}

phenofile = args[1]
covarfile = args[2]         
covarnames = args[3] 


# TEST:  
#   phenofile = "liver_fat_ext.txt"  
#   covarfile = "GWAS_covariates.txt"  
#   covarnames = "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"           		   

# phenofile = "BMI_21001_plink.txt"
# covarfile = "Covariates_filtered.txt"
# covarnames = "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15,PC16,PC17,PC18,PC19,PC20,array,sex,age"

   
if(!file.exists(phenofile)) stop(paste("\n\n  ERROR (transform_phenotypes_INT.R): Input file '", phenofile, "' not found. \n\n")) 
if(!file.exists(covarfile)) stop(paste("\n\n  ERROR (transform_phenotypes_INT.R): Covariate file '", covarfile, "' not found. \n\n"))   








## +++ Read input phenotype file 

pheno = read.table(phenofile, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)

# str(pheno)
# 
# 'data.frame':   38948 obs. of  3 variables:
#  $ X.FID      : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ IID        : int  1000015 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 1001146 ...
#  $ liver_fat_a: num  2.6 5.53 5.39 3.66 3.61 ...

# OR: (multiple phenonames in the file)
#
# str(pheno)
# 'data.frame':	29054 obs. of  5 variables:
#  $ X.FID                : int  1000015 1000401 1000456 1000493 1000795 1000843 1001146 1001215 1001310 1001399 ...
#  $ IID                  : int  1000015 1000401 1000456 1000493 1000795 1000843 1001146 1001215 1001310 1001399 ...
#  $ predicted_liver_fat_c: num  2.6 5.53 3.66 3.61 1.44 ...
#  $ predicted_liver_fat_e: num  2.6 5.53 3.66 3.61 1.44 ...
#  $ predicted_liver_fat_d: num  2.6 5.53 3.66 3.61 1.44 ...


if(ncol(pheno) < 3) { 
  stop(paste("\n\n  The file", phenofile, "does not seem to be a proper phenotype file.\n  Must at least have 3 columns.\n\n"))  
}

if(colnames(pheno)[1] != "X.FID" | colnames(pheno)[2] != "IID") {
  stop(paste("\n\n  The file", phenofile, "does not seem to be a proper phenotype file.\n  Must start with #FID  IID\n\n"))  
}

number_phenotypes = ncol(pheno) - 2
if(number_phenotypes == 1) {
  cat(paste("\n  We have", number_phenotypes, "phenotype in '", phenofile, "'.\n\n"))
} else {
  cat(paste("\n  We have", number_phenotypes, "phenotypes in '", phenofile, "'.\n\n"))
}







## +++ Read covariate file

covar = read.table(covarfile, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)

# str(covar)
# 
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


covariates = unlist(strsplit(covarnames, split = ","))

# str(covariates)  # chr [1:13] "PC1" "PC2" "PC3" "PC4" "PC5" "PC6" "PC7" "PC8" "PC9" "PC10"
#  colnames(covar)  #  "X.FID"       "IID"         "PC1"         "PC2"         "PC3"         "PC4"         "PC5"         "PC6"         "PC7"

for (cov in covariates) {
  # cat(paste("  cov =", cov, "\n"))
  if(!cov %in% colnames(covar)) stop(paste("\n\n  Covariate '", cov, "' is not a column in '", covarfile, "'. \n\n"))
} 








## +++ Merge phenotype with covariates 

# head(covar)
#
#     X.FID     IID       PC1     PC2       PC3       PC4       PC5        PC6       PC7       PC8      PC9      PC10 array sex   age
# 1 1000027 1000027 -14.20630 4.88676 -1.077420  1.493080 -4.769030 -2.1676300  0.509630 -1.802300  5.21144  1.918070     3   0 55.27
# 2 1000039 1000039 -14.87840 5.49553 -0.564267  0.372418  4.593710 -0.5263310 -1.224820  1.441580  1.51997 -1.000270     2   0 62.26
# 3 1000040 1000040  -9.31768 3.14434  1.179110 -0.766216 -2.136190  0.6580010  2.561440 -0.261769 -2.83988 -1.332040     3   0 60.07
# 4 1000053 1000053 -13.26520 2.01425 -3.319700  1.187170  0.176755  0.0637719  0.422459  0.754097  4.79254  0.301277     3   0 64.07
# 5 1000064 1000064 -11.91490 6.88527  1.157530 -3.114030 -5.644040 -0.6851510 -0.237977  2.737650  2.19642 -2.087390     2   1 54.34
# 6 1000071 1000071 -10.44720 4.60355 -1.622490 -2.185330 -2.757930  0.5514320 -1.329740 -1.472890  1.92260  1.138680     3   0 61.17
# 
# 
# head(pheno)
#
#     X.FID     IID liver_fat_a
# 1 1000015 1000015    2.604362
# 2 1000401 1000401    5.534768
# 3 1000435 1000435    5.393000
# 4 1000456 1000456    3.660239
# 5 1000493 1000493    3.610108
# 6 1000795 1000795    1.443066

# dim(covar)    # 337482     16
# dim(pheno)    # 38948     3


data = merge(pheno, covar, by = "X.FID") 
data$IID.y <- NULL 

# colnames(data)[2]  # "IID.x"
colnames(data)[2] = "IID"


# dim(data)   # 27243    17     covar relies on FTD dataset (filtered)  

# head(data)
# 
#     X.FID     IID liver_fat_a       PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9       PC10 array sex
# 1 1000435 1000435    5.393000  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610 -0.4900740     3   0
# 2 1000493 1000493    3.610108 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152 -1.4455700     2   1
# 3 1000843 1000843    9.580051 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820 -0.2851930     3   1
# 4 1001070 1001070    1.269000 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910 -0.0914199     3   0
# 5 1001146 1001146    1.401959 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600  0.3356860     3   1
# 6 1001271 1001271    1.536000 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660 -3.2000799     3   0
#     age age_squared
# 1 51.21     2622.52
# 2 53.99     2914.40
# 3 58.45     3416.03
# 4 52.17     2721.65
# 5 66.94     4481.51
# 6 40.72     1658.24


nr_total = nrow(data)
data = data[complete.cases(data),]
cat(paste("  Regression data contains", nrow(data), "complete observations (compared", nr_total, "total observations)\n\n"))


## +++ Run the 1st step of the fully adjusted two-stage INT linear model


phenotrans = data[,c(1,2)]   # initialize transformed phenotype   

# head(phenotrans)
#
#     X.FID     IID
# 1 1000015 1000015
# 2 1000401 1000401
# 3 1000435 1000435
# 4 1000456 1000456
# 5 1000493 1000493
# 6 1000795 1000795


for (indx in 3:(2 + number_phenotypes)) {   # phenotypes column numbers:  3 - (2 + number_phenotypes)

  phenoname = colnames(data)[indx]   #  "liver_fat_a"   "bmi"

  # cat(paste("\n  Variable:", phenoname, "\n"))
  
  # Here, follow the fully adjusted two-stage INT described in 
  #   https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0233847&type=printable


  # ** 1. Regress phenotype on covariates only (no genotype here)

  cform = paste(covariates, collapse = " + ")  	# "PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"
  form_reg1 = paste(phenoname, "~", cform)  	# "liver_fat_a ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age"
  formula = as.formula(form_reg1)  		#  liver_fat_a ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 +  PC9 + PC10 + array + sex + age
  cat(paste("  Step 1 conducts regression using:", form_reg1, "\n\n"))   

  lmout_reg1 = lm(formula, data = data, na.action = na.exclude)  
  
  # summary(lmout_reg1) 
  
   

  # ** 2. Get the residuals from the first regression 

  resid_reg1 = resid(lmout_reg1)
  
  if(length(resid_reg1) != nrow(data)) 
    stop(paste("\n\n  Residual vector shorter that number of observations:", length(resid_reg1), "<==>", nrow(data), "\n\n")) 

 

  # ** 3. Inverse Normal transformation (quantile normalization) on the residuals

  resid_reg1_norm = quant_normal(resid_reg1)
  
  if(length(resid_reg1_norm) != nrow(data)) 
    stop(paste("\n\n  Normalised residual vector shorter that number of observations:", length(resid_reg1_norm), "<==>", nrow(data), "\n\n")) 
 
  # str(resid_reg1_norm)
  #  Named num [1:27243] 0.979 0.354 1.304 -0.568 -1.561 ...
  #  - attr(*, "names")= chr [1:27243] "1000435" "1000493" "1000843" "1001070" ...

  
  # ** 4. Save the transformed residuals    
  # step2 of fully adjusted two-stage INT skipped - do in PLINK-GWAS - 
  # instead save the IN-transformed residuals and some histograms  
  
  
  phenotrans = cbind(phenotrans, resid_reg1_norm)  # resid_reg1_norm is the new indepemdemt variable 
  varname = paste0(phenoname, "_res_norm")
  colnames(phenotrans)[length(colnames(phenotrans))] = varname
  

  # Plots
  fn = paste0("IN_trans_", phenoname, ".pdf")  # "IN_trans_liver_fat_a.pdf"
  pdf(fn)
  
  par(mfrow=c(2,2))
  
    # phenotype histogram 
    hist(pheno[,indx], col = "red", main = "Phenotype", breaks = 40, xlab = phenoname, font.main = 1)

    # residuals after first regression:  
    hist(resid_reg1, col = "red", main = "Residuals after 1st regression", breaks = 40, xlab = "Residuals", font.main = 1)

    # residuals after INT:   
    hist(resid_reg1_norm, col = "red", main = "Residuals after 1st regression and INT", breaks = 40, xlab = "Normalized residuals", font.main = 1)

    # QQ-plot of the resuiduals after INT: 
    qqnorm(resid_reg1_norm, col = "blue", pch = 1, cex = 1, main = "QQ-plot of IN-transformed residuals", font.main = 1)
    qqline(resid_reg1_norm, col = "red", lty = 2, lwd = 1.5)
 
  par(mfrow=c(1,1))
  
  dev.off() 
  cat(paste("  Image with distribution plots for phenoname '", phenoname, "' saved to '", fn, "'\n\n"))  
  
}


# head(pheno)
# 
#     X.FID     IID liver_fat_a
# 1 1000015 1000015    2.604362
# 2 1000401 1000401    5.534768
# 3 1000435 1000435    5.393000
# 4 1000456 1000456    3.660239
# 5 1000493 1000493    3.610108
# 6 1000795 1000795    1.443066
# 
#
# head(phenotrans)
#
#     X.FID     IID liver_fat_a
# 1 1000015 1000015   0.7456682
# 2 1000401 1000401   1.1123678
# 3 1000435 1000435   1.1020912
# 4 1000456 1000456   0.9299488
# 5 1000493 1000493   0.9231278
# 6 1000795 1000795   0.3324115






## +++ Save output file

# colnames(phenotrans)[1]   # "X.FID"  
colnames(phenotrans)[1] = "#FID"

fn = paste0("IN_transformed_", phenofile)  # "IN_transformed_liver_fat_ext.txt"

write.table(phenotrans, file = fn, row.names = FALSE, quote = FALSE, sep = "\t")    
cat(paste("\n  Output phenotype file saved to:", fn, "\n\n"))















































