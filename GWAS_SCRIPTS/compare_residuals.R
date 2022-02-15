#!/usr/bin/env Rscript      


# uwe.menzel@medsci.uu.se  



 
## === Compare the residuals of 2 regression models  
#  


# residuals are saved by "gwas_diagnose" or "gwas_diagnose_nomarker"  



# Interactive:
#
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 3:00:00 -A sens2019016 
#   module load R_packages/3.6.1
#   . s2
#   which compare_residuals.R
#   cd /castor/project/proj/GWAS_DEV3/liver10 
#   compare_residuals  diagnose_residuals_rs188247550_T_C_allele_T.RData  diagnose_residuals_nomarker.RData  






## +++ Plot parameters 

plotwidth = 600
plotheight = 600







## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 2) {
  cat("\n")
  cat("  Usage: compare_residuals  <.RData-file 1>  <.RData-file 2> \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

res1 = args[1]		
res2 = args[2]


# res1 = "diagnose_residuals_rs188247550_T_C_allele_T.RData"   
# res2 = "diagnose_residuals_nomarker.RData"  







## +++ Libraries, Functions

cat("\n\n  Loading packages ...  ") 
start_time = Sys.time() 
suppressMessages(suppressWarnings(library(ggplot2)))  	
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





# Rmarkdown template :

rmd = paste(scripts, "compare_residuals.Rmd", sep="/")	

if(!file.exists(rmd)) stop(paste("\n\n  ERROR (compare_residuals.R): Rmarkdown template ",  rmd,  " not found.\n\n"))
rmd_copy = paste(getwd(), "gwas_diagnose.Rmd", sep="/")  	

# copy the .Rmd file to the current folder ==> working directory for knitr
if(!file.copy(rmd, rmd_copy, overwrite = TRUE)) stop(paste("\n\n  ERROR (compare_residuals.R): Could not copy file ",  rmd,  " to the current folder.\n\n"))
if(!file.exists(rmd_copy)) stop(paste("\n\n  ERROR (compare_residuals.R): Rmarkdown template ",  rmd,  " not copied to current location.\n\n"))


    



## +++ Get the residuals

if(!file.exists(res1)) {
  stop(paste("\n\n  ERROR (compare_residuals.R): RData file ",  res1,  " not found.\n\n"))
} else {
  resid1 = get(load(res1))
  resid1 = as.data.frame(resid1) 
}


if(!file.exists(res2)) {
  stop(paste("\n\n  ERROR (compare_residuals.R): RData file ",  res2,  " not found.\n\n"))
} else {
  resid2 = get(load(res2))
  resid2 = as.data.frame(resid2)  
}


# str(resid1)
# 'data.frame':	27243 obs. of  1 variable:
#  $ resid1: num  2.28 -0.93 5.3 -2.07 -2.93 ...

# str(resid2)
# 'data.frame':	27243 obs. of  1 variable:
#  $ resid2: num  2.242 -0.967 5.251 -2.111 -2.976 ...


# head(resid1) 
# 
#             resid1
# 1000435  2.2769541
# 1000493 -0.9295284
# 1000843  5.2951569
# 1001070 -2.0660076
# 1001146 -2.9295724
# 1001271 -1.7060130

# head(resid2) 
# 
#             resid2
# 1000435  2.2415717
# 1000493 -0.9665711
# 1000843  5.2510877
# 1001070 -2.1105923
# 1001146 -2.9761444
# 1001271 -1.7495621






		    

nr_samples_1 = nrow(resid1)
nr_samples_2 = nrow(resid2)
nr_common = length(intersect(rownames(resid1), rownames(resid2)))

cat(paste("  Number of samples for", res1,":", nr_samples_1, "\n")) 
cat(paste("  Number of samples for", res2,":", nr_samples_2, "\n")) 
cat(paste("  Number of common samples :", nr_common, "\n")) 

if(nr_common == nr_samples_1) {
  cat("  Both residual data sets arise from the same samples.\n\n")
} else {
  perc1 = signif(nr_common/nr_samples_1*100, 4)
  perc2 = signif(nr_common/nr_samples_2*100, 4) 
  cat("  The number of common samples is:\n")
  cat(paste("    ", perc1, "% of", res1, "\n"))
  cat(paste("    ", perc2, "% of", res2, "\n\n"))    
}





## +++ Summaries

summary.df = data.frame(file1 = prettyNum(summary(resid1$resid1), decimal.mark="."), 
                        file2 = prettyNum(summary(resid2$resid2), decimal.mark="."))

summaryfile = "compare_residuals_summary.RData"
save(summary.df, file = summaryfile)  
cat(paste("  Summary frame saved to '", summaryfile, "'.\n\n"))





## +++ Histogram 

resid1$id <- "file1"
resid2$id <- "file2"

# colnames(resid1)[1]  # resid1
colnames(resid1)[1] = "resid"

# colnames(resid2)[1]  # resid2
colnames(resid2)[1] = "resid"


# head(resid1)
#              resid    id
# 1000435  2.2769541 file1
# 1000493 -0.9295284 file1
# 1000843  5.2951569 file1
# 1001070 -2.0660076 file1
# 1001146 -2.9295724 file1
# 1001271 -1.7060130 file1

# head(resid2)
#              resid    id
# 1000435  2.2415717 file2
# 1000493 -0.9665711 file2
# 1000843  5.2510877 file2
# 1001070 -2.1105923 file2
# 1001146 -2.9761444 file2
# 1001271 -1.7495621 file2

residuals = rbind(resid1, resid2)  # need log form !

# str(residuals)
# 'data.frame':	54486 obs. of  2 variables:
#  $ resid: num  2.28 -0.93 5.3 -2.07 -2.93 ...
#  $ id   : chr  "file1" "file1" "file1" "file1" ...

# head(residuals) 
#              resid    id
# 1000435  2.2769541 file1
# 1000493 -0.9295284 file1
# 1000843  5.2951569 file1
# 1001070 -2.0660076 file1
# 1001146 -2.9295724 file1
# 1001271 -1.7060130 file1
# 
# tail(residuals) 
#              resid    id
# 60239001  1.063427 file2
# 60243211  7.599985 file2
# 60246131 -2.575407 file2
# 60246421 -2.173048 file2
# 60252991 -2.471352 file2
# 60254501  3.527001 file2



histplot = "compare_residuals_histogram.png"    
png(histplot, width = plotwidth, height = plotheight)

ggplot(residuals, aes(resid, fill = id)) + 
    geom_histogram(alpha = 0.5, aes(y = ..density..), position = 'identity', bins = 40)

invisible(dev.off())
cat(paste("  Histogram for residuals saved to '", histplot, "'\n\n")) 




## +++ Density plot  

densityplot = "compare_residuals_density.png"    
png(densityplot, width = plotwidth, height = plotheight)

ggplot(residuals, aes(resid, fill = id)) + geom_density(alpha = 0.2) 

invisible(dev.off())
cat(paste("  Kernel density plots for residuals saved to '", densityplot, "'\n\n")) 






## +++ QQ-plots  

qqplot = "compare_residuals_qqplot.png"
png(qqplot, width = plotwidth, height = plotheight*1.8)

par(mfrow = c(2, 1))

qqnorm(resid1$resid, col = "red", pch = ".", cex = 3, main = "QQ-plot file 1", frame = FALSE)
qqline(resid1$resid, col = "blue", lty = 2, cex = 2)

qqnorm(resid2$resid, col = "red", pch = ".", cex = 3, main = "QQ-plot file 2", frame = FALSE)
qqline(resid2$resid, col = "blue", lty = 2, cex = 2)

par(mfrow = c(1, 1))

invisible(dev.off())
cat(paste("  QQ-plots for residuals saved to '", qqplot, "'\n\n")) 






## +++ Empirical cumulative distribution functions

# head(resid1) 
# 
#              resid    id
# 1000435  2.2769541 file1
# 1000493 -0.9295284 file1
# 1000843  5.2951569 file1
# 1001070 -2.0660076 file1
# 1001146 -2.9295724 file1
# 1001271 -1.7060130 file1

xlim = c(min(min(resid1$resid), min(resid2$resid)), max(max(resid1$resid), max(resid2$resid)))  # -5.141262 30.936794


ecdfplot = "compare_residuals_ecdf.png"    
png(ecdfplot, width = plotwidth, height = plotheight)

plot(ecdf(resid1$resid), xlim = xlim, col = "red", main = "Comparison for CDF", font.main = 1, lwd = 2)
lines(ecdf(resid2$resid), col = "darkgreen", lwd = 2)
legend("bottomright", c("file1", "file2"), col = c("red", "darkgreen"), lty = 1, lwd = 3)

invisible(dev.off())
cat(paste("  ECDF plots for residuals saved to '", ecdfplot, "'\n\n")) 




## +++ Scatter

resid12 = merge(resid1, resid2, by = "row.names")  

# head(resid12)
#
#   Row.names    resid.x  id.x    resid.y  id.y
# 1   1000435  2.2769541 file1  2.2415717 file2
# 2   1000493 -0.9295284 file1 -0.9665711 file2
# 3   1000843  5.2951569 file1  5.2510877 file2
# 4   1001070 -2.0660076 file1 -2.1105923 file2
# 5   1001146 -2.9295724 file1 -2.9761444 file2
# 6   1001271 -1.7060130 file1 -1.7495621 file2

resid12$id.x <- NULL
resid12$id.y <- NULL

colnames(resid12) = c("IID", "resid1", "resid2")
rownames(resid12) = resid12$IID


# head(resid12)
# 
#             IID     resid1     resid2
# 1000435 1000435  2.2769541  2.2415717
# 1000493 1000493 -0.9295284 -0.9665711
# 1000843 1000843  5.2951569  5.2510877
# 1001070 1001070 -2.0660076 -2.1105923
# 1001146 1001146 -2.9295724 -2.9761444
# 1001271 1001271 -1.7060130 -1.7495621


scatterplot = "compare_residuals_scatter.png"    
png(scatterplot, width = plotwidth, height = plotheight)

plot(resid12$resid1, resid12$resid2, col = "blue", pch = ".", cex = 3, xlab = "file1", ylab = "file2", main = "Scatterplot for residuals", font.main = 1) 
abline(0,1, col = "red", cex = 2, lty = 2)

invisible(dev.off())
cat(paste("  Scatterplot for residuals saved to '", scatterplot, "'\n\n")) 




## +++ Kolmogorow-Smirnow, Anderson-Darling, ....







## +++ Creating html


plist = list()
plist["workfolder"] = getwd() 
plist["res1"] = res1
plist["res2"] = res2
plist["nr_samples_1"] = nr_samples_1 		
plist["nr_samples_2"] = nr_samples_2 	
plist["nr_common"] = nr_common  	
plist["summaryfile"] = summaryfile 
plist["histplot"] = histplot 		
plist["densityplot"] = densityplot
plist["qqplot"] = qqplot 	
plist["ecdfplot"] = ecdfplot 	
plist["scatterplot"] = scatterplot



cat(paste("  Rendering file", rmd_copy, " ..."))   
start_time = Sys.time()  

htmlfile = paste0("compare_residuals.html")  


rmarkdown::render(rmd_copy, params = plist, output_dir = getwd(), output_file = htmlfile, quiet = TRUE)  

stop_time = Sys.time()
diff_time = stop_time - start_time 
cat(paste("  Done in", round(diff_time,2), "seconds.\n"))

# if(!file.remove(rmd_copy)) stop(paste("\n\n  ERROR (gwas_diagnose.R): Could not remove file ",  rmd_copy,  ".\n\n"))





## +++ Finish

cat(paste("\n  Open '", htmlfile, "' with your favoured browser.\n"))
cat(paste("\n  ", date(),"\n\n"))
cat("  Done.\n\n")  





