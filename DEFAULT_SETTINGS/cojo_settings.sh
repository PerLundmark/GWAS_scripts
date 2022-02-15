
# GCTA-COJO settings (command line paramters overwrite these settings):  

# this file is sourced by  run_cojo, cojo_pheno,  cojo_chr,  cojo_convert, cojo_clean   


# genofolder="/proj/sens2019016/GENOTYPES/PGEN" # .pgen does not work, see mail Zhili 19/02/2020 
genofolder="/proj/sens2019016/GENOTYPES/BED"    # location of genotype files, (unique marker names)   .bed .bim .fam

window=5000					# (5MB) cojo assumes that markers outside this window are independent 
pval=5.0e-8					# p-value threshold for genome-wide significance 
collinearity=0.9				# --cojo-collinear parameter (gcta64 command), see https://cnsgenomics.com/software/gcta/#COJO
maf=0  						# minor allele frequency   

skip_chrom=1					# skip chromosomes with none or only one sign. marker (above maf cutoff) (creates NA in the output)
keepma=0					# keep the .ma file (summary statistics for all chromosomes, ~500 MB), intsead of deleting in cojo_clean

sleep_between_pheno=0             		# sleep that many minutes before a new phenotype is started (prevents from using too many nodes simultaneously) 

partition="node"    				# "node" or "core"  (rather not "core")
minutes=100	    				# requested runtime for each chromosome in minutes (60 minutes where not enough for chr 2)
minspace=100000000  				# 100 GByte    minimum required free disk space 
ask="y"						# Ask the user for confirmation of the input parameters. We might start many jobs (25 nodes per phenoname)

cojo_convert_time="20:00" 			# runtime requested for "cojo_convert", used in cojo_pheno 
cojo_collect_time="10:00"			# runtime requested for "cojo_collect" , used in cojo_pheno
cojo_clean_time="10:00"				# runtime requested for "cojo_clean.sh", used in cojo_pheno   


## Alternative genotype dataset to be used as refence in cojo: 
# Outcomment the following line if the default genotype files are to be used! 
# Default = same genotype files as used in gwas. Default is read from parameter file. 
alt_genoid="FTD_rand"				# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD  
