

# gwas_diagnose.R settings   

# this file is sourced by  gwas_diagnose.R  

# genoid="MF" 					# genotype dataset; filtered for ethnicity, kinship, 27.212 samples

genofolder="/proj/sens2019016/GENOTYPES/BED"    # location of input genotype dataset

# phenofolder="/proj/sens2019016/PHENOTYPES"	# location of input phenotype and covariate files
phenofolder="."		      

covarfile="GWAS_covariates.txt"			# covariates file (located in phenofolder) 
covarname="PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"  # covariates
