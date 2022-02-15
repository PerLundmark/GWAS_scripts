#!/usr/bin/env Rscript      


# uwe.menzel@medsci.uu.se  


## ===  Apply a filter on a phenotype file 

# R-version of filter_pheno.sh  



# filter_phenotype  <phenofile>  <filterfile>  <col1>  <col2> 
# filter_phenotype   pheno_faked.txt   pca_used_22020.txt  1   1  



## +++ Hardcoded settings & and defaults 

uniq_only = TRUE     # allow merging on columns with unique entries only.
vennplot = TRUE 






## +++ Libraries and functions

suppressMessages(suppressWarnings(library(data.table))) 	# fread
suppressMessages(suppressWarnings(library(VennDiagram)))  	# venn.diagram





## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) < 4) {
  cat("\n")
  cat("  Usage: filter_phenotype  <phenofile>  <filterfile>  <col1>  <col2> \n") 
  cat("         uwe.menzel@medsci.uu.se\n") 
  cat("\n")
  quit("no")
}

phenofile = args[1]		
filterfile = args[2]		    
col1 = as.integer(args[3])
col2 = as.integer(args[4]) 


# phenofile = "pheno_faked.txt"
# filterfile = "pca_used_22020.txt"
# col1 = 1
# col2 = 1



if(!file.exists(phenofile))  stop(paste("\n\n  File", phenofile, "not found. \n\n")) 
if(!file.exists(filterfile))  stop(paste("\n\n  File", filterfile, "not found. \n\n"))


pheno = as.data.frame(fread(phenofile, check.names = TRUE, showProgress = TRUE))

# head(pheno)
#        IID    pheno
# 1: 5954653 0.291066
# 2: 1737609 0.845814
# 3: 1427013 0.152208
# 4: 3443403 0.585537
# 5: 5807741 0.193475
# 6: 4188953 0.810623

filter = as.data.frame(fread(filterfile, check.names = TRUE, showProgress = TRUE))

# head(filter)
#        IID
# 1: 1000027
# 2: 1000039
# 3: 1000040
# 4: 1000053
# 5: 1000064
# 6: 1000071  


if (uniq_only) {
  if(sum(duplicated( pheno[,col1])) != 0) stop(paste("\n\n  File", phenofile, "contains duplicated entries in column", col1,". \n\n")) 
  if(sum(duplicated(filter[,col2])) != 0) stop(paste("\n\n  File", filterfile, "contains duplicated entries in column", col2,". \n\n")) 
}

if(col1 > ncol(pheno))  stop(paste("\n\n  Parameter col1 is", col1, "and therewith bigger than the number of columns in", phenofile,  ". \n\n"))
if(col2 > ncol(filter)) stop(paste("\n\n  Parameter col2 is", col2, "and therewith bigger than the number of columns in", filterfile, ". \n\n"))





# filtered_pheno = merge(pheno, filter, by.x = colnames(pheno)[col1], by.y = colnames(filter)[col2])  
# this might not preserve the structure of the input file

common_samples = intersect(pheno[,col1],filter[,col2])      # length(common_samples) # 407140

filtered_pheno = pheno[pheno[,col1] %in% common_samples,]

# dim(filtered_pheno)  #  407140      2


cat("\n\n")
cat(paste("  Number of samples in the phenotype file:", nrow(pheno), "\n"))
cat(paste("  Number of samples in the filter file:", nrow(filter), "\n"))
cat(paste("  Number of samples in the filtered phenotype file:", nrow(filtered_pheno), "\n\n"))





## +++ Venn diagram over samples in phenotype, filter, and filtered phenotype 
  
if(vennplot) {
  ids = list(pheno[,col1], filter[,col2], filtered_pheno[,col1]) 
  catnames = c("pheno", "filter", "filtered pheno")
  vplot = venn.diagram(ids, category.names = catnames, filename = NULL, output = FALSE)
  vennplot = paste0(phenofile,"_venn.png")
  png(vennplot, width = 600, height = 600)
  grid.draw(vplot)
  invisible(dev.off())
  cat(paste("  Venn diagram saved to '", vennplot, "'.\n\n")) 
}



## +++ Save filtered file:

colnames(filtered_pheno)[1] = "#FID"

outfilename = paste0(phenofile, ".filtered") 

write.table(filtered_pheno, file = outfilename, sep = "\t", quote = FALSE, row.names = FALSE) 

command = paste("ls -l", outfilename)
system(command)
cat("\n\n")







