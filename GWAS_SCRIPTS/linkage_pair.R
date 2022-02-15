#!/usr/bin/env Rscript 


# uwe.menzel@medsci.uu.se 



## === Calculate linkage for a pair of markers 


# called by linkage_pair.sh

# Test, Interactive:
#
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 3:00:00 -A sens2019016 
#
#   module load R_packages/3.6.1
#   . s2
#   which linkage_pair.R
#   cd /castor/project/proj/GWAS_DEV3/liver10
# 
#   linkage_pair.R  genotype_rs58542926_T_C.raw  genotype_rs188247550_T_C.raw  FTD    

  




## +++ Plot parameters 

plotwidth = 600
plotheight = 600






## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 3) {
  cat("\n")
  cat("  Usage: linkage_pair  <rawfile1>  <rawfile2>  <genoid> \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

rawfile1 = args[1]		
rawfile2 = args[2]
genoid = args[3]

# rawfile1 = "genotype_rs58542926_T_C.raw"   
# rawfile2 = "genotype_rs188247550_T_C.raw"  
# genoid = "FTD"





## +++ Libraries, Functions

cat("\n\n  Loading packages ...  ") 
start_time = Sys.time() 
# suppressMessages(suppressWarnings(library(ggplot2)))  	
stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("Done in", round(diff_time,2), "seconds.\n"))











## +++ Get environment variable 

# ~/.bashrc : 
# export SCRIPT_FOLDER="/proj/sens2019016/GWAS_SCRIPTS"  #  use ". s1"  and ". s2" to switch 

scripts = Sys.getenv("SCRIPT_FOLDER") 
if ( scripts == "" ) {
  stop(paste("\n\n  ERROR (linkage_pair.R): Environment variable 'SCRIPT_FOLDER' not set.\n\n"))  
} else {
  cat(paste("\n  Environment variable 'SCRIPT_FOLDER' is set to", scripts, "\n\n"))
}




## +++ Rmarkdown template :

rmd = paste(scripts, "linkage_pair.Rmd", sep="/")	

if(!file.exists(rmd)) stop(paste("\n\n  ERROR (linkage_pair.R): Rmarkdown template ",  rmd,  " not found.\n\n"))
rmd_copy = paste(getwd(), "linkage_pair.Rmd", sep="/")  	

# copy the .Rmd file to the current folder ==> working directory for knitr
if(!file.copy(rmd, rmd_copy, overwrite = TRUE)) stop(paste("\n\n  ERROR (linkage_pair.R): Could not copy file ",  rmd,  " to the current folder.\n\n"))
if(!file.exists(rmd_copy)) stop(paste("\n\n  ERROR (linkage_pair.R): Rmarkdown template ",  rmd,  " not copied to current location.\n\n"))






## +++ Load genotype files for the markers considered 

# head genotype_rs58542926_T_C.raw
# IID     rs58542926_T_C_T
# 5954653 0
# 1737609 0
# 1427013 1
# 3443403 0
# 5807741 0
# 1821438 0
# 3951387 1
# 5670866 1
# 1207760 0


if(file.exists(rawfile1)) { 
  genotype1 = read.table(rawfile1, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE) 
  cat(paste("  Genotype rawfile", rawfile1, "loaded\n")) 
} else {
  stop(paste("\n\n  ERROR (linkage_pair.R) : Could not find the genotype raw file: '", rawfile1, "'.\n\n"))
}

if(file.exists(rawfile2)) { 
  genotype2 = read.table(rawfile2, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE) 
  cat(paste("  Genotype rawfile", rawfile2, "loaded\n\n")) 
} else {
  stop(paste("\n\n  ERROR (linkage_pair.R) : Could not find the genotype raw file: '", rawfile2, "'.\n\n"))
}


#   Genotype rawfile genotype_rs58542926_T_C.raw loaded
#   Genotype rawfile genotype_rs188247550_T_C.raw loaded



# get marker names (see linkage_par.sh how the rawfile names are derived from the marker names 

# SNP1:

snp1 = sub("genotype_", "", rawfile1) 	# "rs58542926_T_C.raw" 
snp1 = sub(".raw", "", snp1) 		# "rs58542926_T_C" 

label = colnames(genotype1)[2]		# "rs58542926_T_C_T"    original marker name plus counted (minor!) allele ("T") check with GWAS_report A1 allele!   
if(!grepl(snp1, label, fixed = TRUE)) {
  cat(paste("  Marker is '", snp1, "' but rawfile contains '", label, "'\n"))
  cat("  That ain't gonna work.\n\n")
  stop(paste("\n\n  ERROR (linkage_pair.R) : Inconsistent marker labels.\n\n"))
}

rownames(genotype1) = genotype1$IID

# str(genotype1)
# 'data.frame':	337482 obs. of  2 variables:
#  $ IID             : int  5954653 1737609 1427013 3443403 5807741 1821438 3951387 5670866 1207760 3452123 ...
#  $ rs58542926_T_C_T: int  0 0 1 0 0 0 1 1 0 0 ...

# head(genotype1)
#       IID rs58542926_T_C_T
# 1 5954653                0
# 2 1737609                0
# 3 1427013                1
# 4 3443403                0
# 5 5807741                0
# 6 1821438                0

lvec = unlist(strsplit(label, "_", fixed = TRUE)) #  chr [1:4] "rs58542926" "T" "C" "T"
counted_allele1 = lvec[length(lvec)]  	# "T"  
c1 = lvec[length(lvec) - 1] 		# "C"
c2 = lvec[length(lvec) - 2] 		# "T"
other_allele1 = ifelse(counted_allele1 == c1, c2, c1) 	# "C"
# cat(paste("  Genotype file1 (", snp1, "): counted allele is", counted_allele1, ", other allele is", other_allele1, "\n\n"))  # show below  
# Genotype file1 ( rs58542926_T_C ): counted allele is T , other allele is C 




# SNP2:

snp2 = sub("genotype_", "", rawfile2) 	# rs188247550_T_C.raw 
snp2 = sub(".raw", "", snp2) 		# rs188247550_T_C 

label = colnames(genotype2)[2]		# rs188247550_T_C_T   original marker name plus counted (minor!) allele ("T") check with GWAS_report A1 allele!   
if(!grepl(snp2, label, fixed = TRUE)) {
  cat(paste("  Marker is '", snp2, "' but rawfile contains '", label, "'\n"))
  cat("  That ain't gonna work.\n\n")
  stop(paste("\n\n  ERROR (linkage_pair.R) : Inconsistent marker labels.\n\n"))
}

rownames(genotype2) = genotype2$IID

# str(genotype2)
# 'data.frame':	337482 obs. of  2 variables:
#  $ IID              : int  5954653 1737609 1427013 3443403 5807741 1821438 3951387 5670866 1207760 3452123 ...
#  $ rs188247550_T_C_T: num  0 0 0 0 0 0 0 0 0 0 ...
 
# head(genotype2)
#             IID rs188247550_T_C_T
# 5954653 5954653                 0
# 1737609 1737609                 0
# 1427013 1427013                 0
# 3443403 3443403                 0
# 5807741 5807741                 0
# 1821438 1821438                 0


lvec = unlist(strsplit(label, "_", fixed = TRUE)) #  chr [1:4] "rs188247550" "T" "C" "T"chr [1:4] "rs188247550" "T" "C" "T"
counted_allele2 = lvec[length(lvec)]  	# "T"  
c1 = lvec[length(lvec) - 1] 		# "C"
c2 = lvec[length(lvec) - 2] 		# "T"
other_allele2 = ifelse(counted_allele2 == c1, c2, c1) 	# "C"
# cat(paste("  Genotype file2 (", snp2, "): counted allele is", counted_allele2, ", other allele is", other_allele2, "\n\n"))  # show below  
#  Genotype file2 ( rs188247550_T_C ): counted allele is T , other allele is C 






## +++ Merge genotype files:  

genotypes = merge(genotype1, genotype2, by = "row.names")

genotypes$IID.x <- NULL 
genotypes$IID.y <- NULL

# head(genotypes)    

# colnames(genotypes)[1]   # Row.names
colnames(genotypes)[1] = "IID"
rownames(genotypes) = genotypes$IID

# head(genotypes)
#             IID rs58542926_T_C_T rs188247550_T_C_T
# 1000027 1000027                0                 0
# 1000039 1000039                0                 0
# 1000040 1000040                2                 0
# 1000053 1000053                1                 0
# 1000064 1000064                0                 0
# 1000071 1000071                0                 0

cat(paste("  SNP1 has", nrow(genotype1), "samples, SNP2 has", nrow(genotype2), "samples, both have", nrow(genotypes), "common samples.\n\n"))

rm(genotype1, genotype2)





 




## +++ Histograms for imputed values 

tol = 1.0e-6

if(is.integer(genotypes[,2])) {
  cat(paste("  Genotype file of", snp1, "does not contain imputed genotype values.\n\n"))
  imput1 = FALSE
  nr_imputed1 = 0
} else {
  imput1 = TRUE
  ind_imputed = which(genotypes[,2]%%1 > tol)
  nr_imputed1 = length(ind_imputed) # 
  
  histplot_imp1 = paste0("linkage_hist_imp_", snp1, ".png")	# linkage_hist_imp_rs58542926_T_C.png
  png(histplot_imp1, width = plotwidth, height = plotheight)
    
  hist(genotypes[,2][ind_imputed], col = "red", xlim = c(tol, 2-tol), xlab = "genotype", main = "Histogram for imputed values", font.main = 1)
  mtext(paste(snp1, "   nr imputed:", nr_imputed1), side = 3, col = "blue", cex = 0.9)

  invisible(dev.off())
  cat(paste("  Histogram for the imputed values of", snp1, "saved to '", histplot_imp1, "'\n"))  
}


if(is.integer(genotypes[,3])) {
  cat(paste("  Genotype file of", snp2, "does not contain imputed genotype values.\n\n"))  
  imput2 = FALSE
  nr_imputed2 = 0
} else {
  imput2 = TRUE 
  ind_imputed = which(genotypes[,3]%%1 > tol)
  nr_imputed2 = length(ind_imputed) #  13166
  
  histplot_imp2 = paste0("linkage_hist_imp_", snp2, ".png")	
  png(histplot_imp2, width = plotwidth, height = plotheight)
   
  hist(genotypes[,3][ind_imputed], col = "red", xlim = c(tol, 2-tol), xlab = "genotype", main = "Histogram for imputed values", font.main = 1)
  mtext(paste(snp2, "   nr imputed:", nr_imputed2), side = 3, col = "blue", cex = 0.9)
  
  invisible(dev.off())
  cat(paste("  Histogram for the imputed values of", snp2, "saved to '", histplot_imp2, "'\n"))  
}




## +++ Histograms for all genotype values (surely covering the imputed values)    

# SNP1:
nr_obs1 = length(genotypes[,2])  # 337482
histplot1 = paste0("linkage_hist_", snp1, ".png")	# linkage_hist_rs58542926_T_C.png
png(histplot1, width = plotwidth, height = plotheight)
hist(genotypes[,2], col = "red", xlab = "genotype", main = "Histogram for genotype values", font.main = 1)
mtext(paste(snp1, "   nr observations:", nr_obs1), side = 3, col = "blue", cex = 0.9)
invisible(dev.off())
cat(paste("  Histogram for the genotype values of", snp1, "saved to '", histplot1, "'\n"))  


# SNP2:
nr_obs2 = length(genotypes[,3])  # 337482
histplot2 = paste0("linkage_hist_", snp2, ".png")	
png(histplot2, width = plotwidth, height = plotheight)
hist(genotypes[,3], col = "red", xlab = "genotype", main = "Histogram for genotype values", font.main = 1)
mtext(paste(snp2, "   nr observations:", nr_obs2), side = 3, col = "blue", cex = 0.9)
invisible(dev.off())
cat(paste("  Histogram for the genotype values of", snp2, "saved to '", histplot2, "'\n"))  


cat("\n")



## Range of genotype variable for the markers 

rd = range(genotypes[,2])  
cat(paste("  The genotype for marker", snp1, "ranges between", rd[1],"and", rd[2], "\n"))
if(sum(rd == c(0,2)) != 2) cat("   ( which can be considered as somewhat unusual )\n") 

rd = range(genotypes[,3])  
cat(paste("  The genotype for marker", snp2, "ranges between", rd[1],"and", rd[2], "\n"))
if(sum(rd == c(0,2)) != 2) cat("   ( which can be considered as somewhat unusual )\n") 

cat("\n")







## +++ Regression  (make regression before scatterplot to get intercept and slope)  


# head(genotypes)  
# 
#             IID rs58542926_T_C_T rs188247550_T_C_T
# 1000027 1000027                0                 0
# 1000039 1000039                0                 0
# 1000040 1000040                2                 0
# 1000053 1000053                1                 0
# 1000064 1000064                0                 0
# 1000071 1000071                0                 0


form = paste(colnames(genotypes)[3], "~", colnames(genotypes)[2])
formula = as.formula(form)  # "rs188247550_T_C ~ rs58542926_T_C" 
cat(paste("  Regression using: ", form, "\n\n"))   #  Wilkinson-Rogers 

lmout = lm(formula, data = genotypes)   

# summary(lmout)
# 
# Residuals:
#      Min       1Q   Median       3Q      Max 
# -0.02914 -0.02914 -0.02914 -0.02914  1.97086 
# 
# Coefficients:
#                    Estimate Std. Error t value Pr(>|t|)    
# (Intercept)       0.0291394  0.0002894  100.70   <2e-16 ***
# rs58542926_T_C_T -0.0147494  0.0007172  -20.56   <2e-16 ***
# ---
# 
# Residual standard error: 0.1558 on 337480 degrees of freedom
# Multiple R-squared:  0.001252,	Adjusted R-squared:  0.001249 
# F-statistic: 422.9 on 1 and 337480 DF,  p-value: < 2.2e-16




 
## +++ Some metrics: 
 
# str(lmout) 
# str(summary(lmout))

alpha = summary(lmout)$coefficients[1,1]
beta = summary(lmout)$coefficients[2,1]	
sigma = summary(lmout)$sigma 			        	       
fstatistic = summary(lmout)$fstatistic[1]	
r.squared = summary(lmout)$r.squared  		
# adj.r.squared = summary(lmout)$adj.r.squared	# this is simple linear regression: adj.r.squared == r.squared 	
ci_slope = confint(lmout)[2,]			# confidence interval for beta (slope) 
#       2.5 %      97.5 % 
# -0.01615519 -0.01334367


metric = c("sigma", "Fstat", "Rsquared", "alpha", "CI_low", "beta", "CI_up")
mvalue = c(sigma, fstatistic, r.squared, alpha, ci_slope[1], beta, ci_slope[2]) 

# mvalue = signif(mvalue, 4)     
metric.df = data.frame(value = mvalue) 
rownames(metric.df) = metric

# metric.df
#                  value
# sigma      0.155791649
# Fstat    422.890899598
# Rsquared   0.001251516
# Rsq.adj    0.001248557
# alpha      0.029139357
# CI_low    -0.016155186
# beta      -0.014749428
# CI_up     -0.013343670

metricfile = paste0("linkage_metric_", snp1, "__", snp2, ".RData")  # linkage_metric_rs58542926_T_C__rs188247550_T_C.RData
save(metric.df, file = metricfile)  
cat(paste("  Regression metrics frame saved to '", metricfile, "'.\n"))


# check correlation:

# r = cor(genotypes[,2], genotypes[,3])  # Pearson correlation
# r^2  		# 0.001251516
# r.squared	# 0.001251516    ok






## +++ Scatterplot marker vs. marker 

# head(genotypes[,2])  # colnames(genotypes)[2]
# head(genotypes[,3])  # colnames(genotypes)[3]

# snp1			# rs58542926_T_C
# colnames(genotypes)[2]	# rs58542926_T_C_T
# counted_allele1		# T
# other_allele1		# C   
# 
# snp2			# rs188247550_T_C
# colnames(genotypes)[3]	# rs188247550_T_C_T
# counted_allele2		# T
# other_allele2		# C  


scatterplot = paste0("linkage_scatter_", snp1, "_", snp2, ".png")  # linkage_scatter_rs58542926_T_C_rs188247550_T_C.png	
png(scatterplot, width = plotwidth, height = plotheight)

plot(genotypes[,2], genotypes[,3], xaxt = "n", yaxt = "n", xlab = colnames(genotypes)[2], ylab = colnames(genotypes)[3], main = "Genotype vs. genotype", font.main = 1)   
axis(1, at = 0:2, labels = c(paste0(other_allele1, other_allele1), paste0(counted_allele1, other_allele1), paste0(counted_allele1, counted_allele1)))  
axis(2, at = 0:2, labels = c(paste0(other_allele2, other_allele2), paste0(counted_allele2, other_allele2), paste0(counted_allele2, counted_allele2)))  
abline(alpha, beta, col = "red", lty = 2, lwd = 1.5) 
mtext(paste0("R2=", signif(r.squared, 3), "   beta=", signif(beta, 3)), side = 3, col = "blue", cex = 0.9)

invisible(dev.off())
cat(paste("  Scatterplot genotype vs. genotype saved to '", scatterplot, "'\n"))  



# other marker on x:

# plot(genotypes[,3], genotypes[,2], xaxt = "n", yaxt = "n", xlab = colnames(genotypes)[3], ylab = colnames(genotypes)[2], main = "Genotype vs. genotype", font.main = 1)   
# axis(1, at = 0:2, labels = c(paste0(other_allele2, other_allele2), paste0(counted_allele2, other_allele2), paste0(counted_allele2, counted_allele2)))  
# axis(2, at = 0:2, labels = c(paste0(other_allele1, other_allele1), paste0(counted_allele1, other_allele1), paste0(counted_allele1, counted_allele1)))  

# both plots are not really nice because one marker has no imputed values






## +++ Residuals 

residuals = resid(lmout)  



# + Histogram of the residuals

histplotres = paste0("linkage_hist_resid_", snp1, "_", snp2, ".png")  #  linkage_hist_resid_rs58542926_T_C_rs188247550_T_C.png
png(histplotres, width = plotwidth, height = plotheight)
hist(residuals, col = "red", breaks = 30, main = "Histogram over Residuals", font.main = 1, xlab = "Residuals")
invisible(dev.off())
cat(paste("  Histogram for residuals saved to '", histplotres, "'\n")) 



# +  Normal Q-Q plot of the residuals 

qqplot = paste0("linkage_qq_resid_", snp1, "_", snp2, ".png")   # linkage_qq_resid_rs58542926_T_C_rs188247550_T_C.png
png(qqplot, width = plotwidth, height = plotheight)
plot(lmout, which = 2)
# alternative: qqPlot(resid(lmout), distribution = "norm", main = "QQPlot")   library(car)
invisible(dev.off())
cat(paste("  Normal QQ-plot for residuals saved to '", qqplot, "'\n\n")) 






## +++ Creating html


plist = list()
plist["workfolder"] = getwd() 
plist["genoid"] = genoid
plist["rawfile1"] = rawfile1
plist["rawfile2"] = rawfile2
plist["snp1"] = snp1
plist["snp2"] = snp2
plist["nr_obs1"] = nr_obs1
plist["nr_obs2"] = nr_obs2
plist["imput1"] = imput1
plist["imput2"] = imput2
plist["nr_imputed1"] = nr_imputed1
plist["nr_imputed2"] = nr_imputed2
plist["histplot_imp1"] = ifelse(imput1, histplot_imp1, "")
plist["histplot_imp2"] = ifelse(imput2, histplot_imp2, "")
plist["histplot1"] = histplot1
plist["histplot2"] = histplot2
plist["form"] = form
plist["metricfile"] = metricfile
plist["scatterplot"] = scatterplot
plist["histplotres"] =histplotres
plist["qqplot"] =qqplot
 
 
 
# save this list for debugging 
# plistfile = "rmd_linkage_params.RData"
# save(plist, file = plistfile)   
# cat(paste("  Parameter list for Rmarkdown saved to '", plistfile, "' \n\n"))



cat(paste("  Rendering file", rmd_copy, " ..."))   
start_time = Sys.time()  


htmlfile = paste0("linkage_", snp1, "_", snp2, ".html")  # linkage_rs58542926_T_C_rs188247550_T_C.html


rmarkdown::render(rmd_copy, params = plist, output_dir = getwd(), output_file = htmlfile, quiet = TRUE)  

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("  Done in", round(diff_time,2), "seconds.\n"))

# if(!file.remove(rmd_copy)) stop(paste("\n\n  ERROR (linkage_pair.R): Could not remove file ",  rmd_copy,  ".\n\n"))






## +++ Finish

cat(paste("\n  Open '", htmlfile, "' with your favoured browser.\n"))
cat(paste("\n  ", date(),"\n\n"))
cat("  Done.\n\n")  


















    

