

# GWAS settings (command line paramters overwrite these settings):  

# this file is sourced by run_gwas.sh and gwas_chr.sh

chrom="1-22"					# all autosomes (entering a single chromosome is possible, X and Y not possible)
# genoid="MF" 					# genotype dataset; filtered for ethnicity, kinship, 27.212 samples
genoid="ukb_imp_v3"				# use biggest db without loss of speed when phenotype is filtered, see commands_liver15.txt


genofolder="/proj/sens2019016/GENOTYPES/PGEN"   # location of input genotype dataset

# phenofolder="/proj/sens2019016/PHENOTYPES"	# location of input phenotype and covariate files
phenofolder="."		      
# covarfile="GWAS_covariates_PC40.txt"		# with 40 principal components
# covarfile="GWAS_covariates.txt"		# covariates file (located in phenofolder) 
covarfile="GWAS_covariates_PC40.txt"		# covariates file with 40 Principal Components 
#covarname="PC1-PC40,array,sex,age"  		# with 40 principal components
covarname="PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15,PC16,PC17,PC18,PC19,PC20,array,sex,age"  # covariates


# Quality control filter  https://www.cog-genomics.org/plink/2.0/filter
mac=30    					# minor allele count threshold  	
maf=0.00					# minor allele frequency threshold
vif=10						# max. variance inflation factor   
machr2="0.8 2.0"                        	# mach-r2 imputation quality range    
marker_max_miss=0.1				# --geno ; filters out all variants with missing call rates exceeding the provided value 
sample_max_miss=0.1				# --mind ; filters out all samples with missing call rates exceeding the provided value
hwe_pval=1.0e-6                                 # Hardy-Weinberg exact test p-value threshold (H0 = HWE) 

# admin
ask="n"						# ask the user for confirmation of the input parameters
plink2_version="plink2/2.00-alpha-2.3-20200124" # search for other versions using " module spider plink2 "
minutes=100					# requested runtime for each chromosome in minutes
partition="node"   				# partition , "core"  might run out of memory   
minspace=1000000000   				# 1 TByte  minimum required disk space for regression output  



			
## +++ Genotype identifiers ("genoid"):
#					
#   ukb_imp_v3   487.409 samples   complete genotype dataset 
# 	 FTD	 337.466 samples   filtered (ethnic background, kinship)
# 	 MRI	  39.219 samples   MRI samples, not filtered
# 	 MF	  28.146 samples   MRI & filtered  
 









