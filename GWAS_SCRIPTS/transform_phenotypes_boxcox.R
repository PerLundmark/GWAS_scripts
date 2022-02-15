#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 


## OOPS: Never tested for phenotype files with multiple phenotype entries !!!


## +++ Boxcox-transform phenotype 




## +++ Libraries, functions

library(MASS)



## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)    

if(length(args) < 3) {
  cat("\n")
  cat("  Usage: transform_phenotypes_boxcox  <phenotype_file>  <covariate file>  <covariate columns>\n") 
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
  
if(!file.exists(phenofile)) stop(paste("\n\n  ERROR (transform_phenotypes_boxcox.R): Input file '", phenofile, "' not found. \n\n")) 
if(!file.exists(covarfile)) stop(paste("\n\n  ERROR (transform_phenotypes_boxcox.R): Covariate file '", covarfile, "' not found. \n\n"))   





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

for (cov in covariates) {
  if(!cov %in% colnames(covar)) stop(paste("\n\n  Covariate '", cov, "' is not a column in '", covarfile, "'. \n\n"))
} 




## +++ Merge phenotype with covariates 

data = merge(pheno, covar, by = "X.FID") 
data$IID.y <- NULL 

# colnames(data)[2]  # "IID.x"
colnames(data)[2] = "IID"




## +++ Run the linear model

phenotrans = data[,c(1,2)]   

# head(phenotrans)
#
#     X.FID     IID
# 1 1000015 1000015
# 2 1000401 1000401
# 3 1000435 1000435
# 4 1000456 1000456
# 5 1000493 1000493
# 6 1000795 1000795


for (indx in 3:(2 + number_phenotypes)) {   

  yvar = colnames(data)[indx]   #  "liver_fat_a"
  cat(paste("\n  Variable:", yvar, "\n"))

  form = as.formula(paste(yvar, "~", paste(covariates, collapse = " + ")))      
  # liver_fat_a ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 + array + sex + age

  res = lm(form, data = data) 
  
  fn = paste0("lambda_", yvar, ".png")  # "lambda_liver_fat_a.png"
  png(filename = fn)

  bc = boxcox(res, lambda = seq(-2,2), plot = TRUE)
  
  dev.off()
  cat(paste("    Log likelihood over lambda for '", yvar, "' saved to '", fn, "'\n")) 

  lambda = bc$x[which(bc$y == max(bc$y))]  #  -0.5454545
  cat(paste("    Best lambda is", signif(lambda, 3), "\n"))

  # transform: 
  if(abs(lambda) > 0.0001) {
      ytrans = (data[[yvar]]^lambda - 1)/lambda  # most "practitioners" only use y^lambda ...
  } else {
      ytrans = log(data[[yvar]])   
  }

  phenotrans = cbind(phenotrans, ytrans)  

  # colnames(phenotrans)[ncol(phenotrans)] # "ytrans"
  colnames(phenotrans)[ncol(phenotrans)] = yvar

  # plots (before after)
  fn = paste0("boxcoxed_", yvar, ".png")  # "boxcoxed_liver_fat_a.png"
  pdf(NULL)  # otherwise, "Rplots.pdf" is created (!?) 
  png(filename = fn)
  par(mfrow=c(2,1))
  
  hist(pheno[,indx], col = "red", main = "Before trafo", breaks = 40, xlab = yvar, font.main = 1)
  mtext("original phenotype", side = 3, cex = 0.8, col = "black")   
  
  hist(phenotrans[,indx], col = "blue", main = "After trafo", breaks = 40, xlab = yvar, font.main = 1)
  mtext("boxcox-transformed", side = 3, cex = 0.8, col = "blue")

  dev.off() 
  cat(paste("    Image with distribution plots saved to '", fn, "'\n\n"))  
  par(mfrow = c(1,1))

}



## +++ Save output file

# colnames(phenotrans)[1]   # "X.FID"  
colnames(phenotrans)[1] = "#FID"

fn = paste0("boxcoxed_", phenofile)  # "boxcoxed_liver_fat_ext.txt"

write.table(phenotrans, file = fn, row.names = FALSE, quote = FALSE, sep = "\t")    
cat(paste("\n  Output phenotype file saved to:", fn, "\n\n"))


# uwe.menzel@medsci.uu.se 












































