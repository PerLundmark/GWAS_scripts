

# review_gwas.R settings   

# this file is sourced by  review_gwas.R 

p_threshold = 5e-8 		# significance threshold for p-values (Manhattan plot)  
bandwidth = 0.01		# bandwidth for kernel density plot 
annotation = FALSE      	# FTO and GNAT2 annotation in Manhattan plot (only makes sense for BMI) 
colvec = c("red","limegreen")	# Manhattan plot colors
max_xls = 500                   # max. number of significant hits in Excel file - no Excel if this number is exceeded! 


# Number of samples in the genotype data sets:

nr_geno_ukb_imp_v3 = 487409
nr_geno_FTD = 337466
nr_geno_MRI = 39219
nr_geno_MF = 28146


