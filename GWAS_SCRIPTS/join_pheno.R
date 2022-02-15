#!/usr/bin/env Rscript 



# uwe.menzel@medsci.uu.se  

  
   
## ===  Join two phenotype files (in plink format: #FID IID ....)  



# OBS!: requires the R module:
#
#    module load R_packages/3.6.1





## +++ Hardcoded settings & and defaults 
 
vennplot = TRUE





## +++ Libraries and functions

suppressMessages(suppressWarnings(library(data.table))) 	# fread
suppressMessages(suppressWarnings(library(VennDiagram)))  	# venn.diagram





## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     # print(args)

if(length(args) < 3) {
  cat("\n")
  cat("  Usage: join_pheno.R  <phenotype_file 1>  <phenotype_file 2>  <outfile> \n") 
  cat("         The phenotype files must be in the format requested by plink.\n") 
  cat("         The R modules must be loaded in advance.\n")   
  cat("\n")
  quit("no")
}

f1 = args[1]
f2 = args[2]
outfile = args[3]         
 
if(!file.exists(f1)) stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f1, "' not found. \n\n")) 
if(!file.exists(f2)) stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f2, "' not found. \n\n"))   

#  /proj/sens2019570/nobackup/GWAS_TEST/bmitest
# f1 = "BMI_21001_plink.txt"
# f2 = "IN_transformed_BMI_21001_plink.txt"
# outfile = "test_join.out" 





## +++ Input file format:

# head -4 BMI_21001_plink.txt IN_transformed_BMI_21001_plink.txt
#
# ==> BMI_21001_plink.txt <==
# #FID    IID     bmi
# 1000014 1000014 22.8061
# 1000023 1000023 25.3077
# 1000030 1000030 20.6106
# 
# ==> IN_transformed_BMI_21001_plink.txt <==
# #FID    IID     bmi_res_norm
# 1000030 1000030 -1.50957257325863
# 1000041 1000041 -0.15418930994864
# 1000059 1000059 2.48849650345673


pheno1 = as.data.frame(fread(f1, check.names = TRUE, showProgress = TRUE))
pheno2 = as.data.frame(fread(f2, check.names = TRUE, showProgress = TRUE))


# head(pheno1,4)
# 
#     X.FID     IID     bmi
# 1 1000014 1000014 22.8061
# 2 1000023 1000023 25.3077
# 3 1000030 1000030 20.6106
# 4 1000041 1000041 25.7659

# head(pheno2,4)
# 
#     X.FID     IID bmi_res_norm
# 1 1000030 1000030  -1.50957257
# 2 1000041 1000041  -0.15418931
# 3 1000059 1000059   2.48849650
# 4 1000062 1000062   0.07669399

if(colnames(pheno1)[1] != "X.FID") stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f1, "' has wrong header. \n\n"))  
if(colnames(pheno1)[2] != "IID")   stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f1, "' has wrong header. \n\n")) 
if(colnames(pheno2)[1] != "X.FID") stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f2, "' has wrong header. \n\n"))
if(colnames(pheno2)[2] != "IID")   stop(paste("\n\n  ERROR (join_pheno.R): Input file '", f2, "' has wrong header. \n\n"))







## +++ Merge  

#joined = merge(pheno1, pheno2, by.x = "IID", by.y = "IID") 
joined = merge(pheno1, pheno2, by = "IID")

joined$X.FID.y <- NULL  
joined = joined[,c(2,1,3:ncol(joined))]
colnames(joined)[1] = "#FID"

# head(joined)
# 
#      #FID     IID     bmi bmi_res_norm
# 1 1000030 1000030 20.6106  -1.50957257
# 2 1000041 1000041 25.7659  -0.15418931
# 3 1000059 1000059 43.3925   2.48849650
# 4 1000062 1000062 26.8848   0.07669399
# 5 1000077 1000077 26.5747  -0.23278405
# 6 1000100 1000100 29.4430   0.73789813




## +++ Save:

write.table(joined, file = outfile, quote = FALSE, sep = "\t", row.names = FALSE)

cat(paste("\n  Joined phenotypes written to '", outfile, "'\n"))







## +++ Venn diagram 
  
if(vennplot) {
  ids = list(pheno1$IID, pheno2$IID) 
  catnames = c("file1", "file2")
  vplot = venn.diagram(ids, category.names = catnames, filename = NULL, output = FALSE)
  vennplot = paste0(tools::file_path_sans_ext(outfile),"venn.png")
  png(vennplot, width = 600, height = 600)
  grid.draw(vplot)
  invisible(dev.off())
  cat(paste("  Venn diagram saved to '", vennplot, "'.\n\n")) 
}






## +++ Summary

cat(paste("  Number of entries in file1 (", f1, "):", nrow(pheno1), "\n"))
cat(paste("  Number of entries in file2 (", f1, "):", nrow(pheno2), "\n"))
cat(paste("  Number of entries in joined file (", outfile, "):", nrow(joined), "\n\n"))


# /proj/sens2019570/nobackup/GWAS_TEST/bmitest > head join_test.txt
# #FID    IID     bmi     bmi_res_norm
# 1000030 1000030 20.6106 -1.50957257325863
# 1000041 1000041 25.7659 -0.15418930994864
# 1000059 1000059 43.3925 2.48849650345673
# 1000062 1000062 26.8848 0.0766939909295717
# 1000077 1000077 26.5747 -0.232784050867891
# 1000100 1000100 29.443  0.737898130759926
# 1000124 1000124 23.1633 -0.784168841708856
# 1000138 1000138 29.4625 0.707669507579111
# 1000146 1000146 26.4668 0.148912832759893

# uwe.menzel@medsci.uu.se

   





