#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 



# Don't forget  "> module load R_packages/3.6.1 "





## +++ Calculate correlation and variance inflation factors for covariates 

# thereby, avoid this plink2 warning:
# 
#   Warning: Skipping --glm regression on phenotype '????????', and
#   other(s) with identical missingness patterns, since variance inflation factor
#   for covariate '??????' is too high. You may want to remove redundant covariate and try again. 







## +++ Call

# examine_covariates   GWAS_covariates_TotalLeanTissueVolume.txt       # work folder /castor/project/proj_nobackup/drivas/kidney_size_lean_tissue_vol
# examine_covariates   GWAS_covariates_TotalLeanTissueVolume.txt  0.6  # different threshold 

# Note: only Pearson correlation examined
#   TODO add method/type here? 






## +++ Command line parameters

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 1) {
  cat("\n")
  cat("  Usage: examine_covariates.R  <covariate-file>  [<correlation threshold>] \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

covarfile = args[1]		 
if(length(args) == 2) {
  corthreshold = args[2]
} else {
   corthreshold = 0.5 
}







## +++ Libraries, Functions

if(!suppressMessages(suppressWarnings(require(gplots)))) stop("\n\n  Package 'gplots' not available. Module ' R_packages/3.6.1 ' loaded?\n\n")		# heatmap.2
if(!suppressMessages(suppressWarnings(require(Hmisc)))) stop("\n\n  Package 'Hmisc' not available. Module ' R_packages/3.6.1 ' loaded?\n\n")		# rcorr 
if(!suppressMessages(suppressWarnings(require(WriteXLS)))) stop("\n\n  Package 'WriteXLS' not available. Module ' R_packages/3.6.1 ' loaded?\n\n") 


flattenCorMat <- function(cormat) {
  uppertri <- upper.tri(cormat)
  data.frame(
    var1 = rownames(cormat)[row(cormat)[uppertri]],
    var2 = rownames(cormat)[col(cormat)[uppertri]],
    Pearson = (cormat)[uppertri]
    )
}







## +++ Load covariate file:


if(!file.exists(covarfile))  stop(paste("\n\n  ERROR (examine_covariates): File '", covarfile, "' not found\n\n"))

covars = read.table(covarfile, sep = "\t", header = TRUE, comment.char = "", stringsAsFactors = FALSE) 
rownames(covars) = covars$IID
covars = covars[,-c(1,2)]  # remove  X.FID     IID  OBS!! It is required that the first two columns are X.FID and IID, rerspectively

# head(covars)
#               PC1     PC2       PC3      PC4       PC5       PC6       PC7       PC8       PC9       PC10 array sex   age 
# 1000435  -7.99529 2.98206  1.897440 -4.33654   8.86341 -2.342750 -3.118760 -0.296383  1.915610 -0.4900740     3   0 51.21 
# 1000493 -11.61820 6.30782 -4.131040  3.38008   3.91680 -1.522880 -0.920577 -0.624074 -0.769152 -1.4455700     2   1 53.99 
# 1000843 -13.20730 1.52633 -1.437160  1.53112  -5.19869 -0.489964 -1.351520 -0.300059  1.129820 -0.2851930     3   1 58.45 
# 1001070 -12.11400 5.29836 -0.480804 -2.07305  -3.99894 -0.645587  4.589100 -1.998630 -1.794910 -0.0914199     3   0 52.17 
# 1001146 -11.06670 1.22650 -0.472677  1.72542 -12.05320 -2.383790  1.462470 -3.447000  2.393600  0.3356860     3   1 66.94 
# 1001271 -11.80260 2.91145  0.489881 -3.00130  -5.81333 -2.164130  3.011010 -0.999236  1.437660 -3.2000799     3   0 40.72 

nr_samples = nrow(covars)
nr_covariates = ncol(covars)

cat(paste("\n  The covariate file includes", nr_samples, "samples and", nr_covariates, "covariates.\n\n"))

cat("  The covariates are:\n\n")
print(colnames(covars))
cat("\n  (NOTE that we assumed the first two colums to be FID and IID !) \n\n")






## +++ Variability within columns  (with zero variability, correlation cannotr be calculated)

for (cv in names(covars)) {
  # cat(paste("  Checking range for phenoname '", cv, "':")) 
  if(length(unique(covars[cv][,1])) == 1) {
    cat(paste("  WARNING: Variable", cv, "has a single value only:", unique(covars[cv][,1]), "\n"))
    cat("  Correlation matrix will be calculated after removing this variable.\n\n")
    covars[cv] <- NULL
  } 
}
cat("\n")









## +++ Correlation and heatmap

cormat = cor(covars, method = "pearson") 

# str(cormat)
# 
#  num [1:15, 1:15] 1 -0.0894 0.1614 -0.2663 -0.1759 ...
#  - attr(*, "dimnames")=List of 2
#   ..$ : chr [1:15] "PC1" "PC2" "PC3" "PC4" ...
#   ..$ : chr [1:15] "PC1" "PC2" "PC3" "PC4" ...

 
maxcor = max(abs(cormat[upper.tri(cormat)]))  # 0.9976421   maximim absolute correlation


cat(paste("  The maximum absolute Pearson correlation is", round(maxcor,3), ".\n\n"))


heatplot = paste0("correlation_heatmap.png")	
cols = colorRampPalette(c("red", "yellow", "green"))(n = 299) 
png(heatplot, width = 800, height = 800)

# heatmap.2(cormat, Colv = FALSE, Rowv = FALSE, dendrogram = "none", col = cols,
#           cellnote = round(cormat,2), notecol = "black", trace = "none", main = "Correlation matrix", notecex = 0.8) 

heatmap.2(cormat, Colv = FALSE, Rowv = FALSE, dendrogram = "none", col = cols, margins = c(7,7), lwid = c(5,15), lhei = c(3,15), 
           cellnote = round(cormat,2), notecol = "black", trace = "none", main = "Correlation matrix", notecex = 0.95)	    

invisible(dev.off())
cat(paste("  Correlation heatmap saved to '", heatplot, "'\n\n"))


cortable = flattenCorMat(cormat)
cortable$Pearson = round(cortable$Pearson,3)
# print(cortable)


indx = which(abs(cortable$Pearson) > corthreshold) #  10  91 103
# print(indx)


cortab2 = cortable[indx,]

cat(paste("  Correlations bigger than", corthreshold, ":\n\n")) 
print(cortab2)
cat("\n\n")








## +++ Variance inflation factors     

# str(covars)

vif.df = data.frame(covar = character(), R2 = numeric(), vif = numeric())

for (cv in names(covars)) {
  # cat(paste("  Regressing '", cv, "' on other covariates\n")) 
  other_covars = covars
  other_covars[cv] <- NULL
  form = paste0(cv, " ~ ", paste(colnames(other_covars), collapse = " + "))
  formula = as.formula(form)  # "total_lean_tissue_volume ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age + age_squared"
  res = lm(formula, data = covars)
  R2 = summary(res)$r.squared  	# 0.6780489
  tolerance = 1 - R2		# 0.3219511
  vif = 1/tolerance		# 3.106062   variance inflation factor 
  line = data.frame(covar = cv, R2 = R2, vif = vif)
  vif.df = rbind(vif.df, line)
}


vif.df$R2 = round(vif.df$R2, 3)
vif.df$vif = round(vif.df$vif, 3)

# vif.df
#                       covar    R2     vif
# 1                       PC1 0.098   1.108
# 2                       PC2 0.035   1.036
# 3                       PC3 0.077   1.083
# 4                       PC4 0.498   1.993
# 5                       PC5 0.496   1.984
# 6                       PC6 0.063   1.067
# 7                       PC7 0.084   1.091
# 8                       PC8 0.194   1.241
# 9                       PC9 0.062   1.066
# 10                     PC10 0.195   1.243
# 11                    array 0.002   1.002
# 12                      sex 0.678   3.110
# 13                      age 0.995 212.900
# 14              age_squared 0.995 213.052
# 15 total_lean_tissue_volume 0.678   3.106





# save both correlation coefficients and variance inflation factors to Excel:

xlsname = "examine_covariates.xls"
WriteXLS(c("cortab2", "cortable", "vif.df"), ExcelFileName = xlsname, SheetNames = c("big_corr", "all_corr", "VIF"), row.names = FALSE)
cat(paste("  Excel sheet with correlation coefficients and variance inflation factors saved to file '", xlsname, "' \n\n"))


cat("  Variance inflation factors:\n\n")
print(vif.df)
cat("\n")
 
 
 
 
 

## +++ Finish:

cat("  Done.\n\n")





