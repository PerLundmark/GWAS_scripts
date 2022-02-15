
# plink1.9 clump settings (command line paramters overwrite these settings):  

# this file is sourced by run_clump.sh, clump_pheno.sh, clump_chr.sh   

genofolder="/proj/sens2019016/GENOTYPES/BED"   	# location of genotype files, (unique marker names)   .bed .bim .fam
# genoid="FTD"                                  # changed! - genoid is read from paramfile (run_clump, clump_pheno)
clump_p1=5e-8 					# significance threshold for index markers 
clump_p2=5e-6 					# secondary significance threshold for clumped markers
clump_r2=0.01 					# LD r2-threshold ; (lower value yields fewer clumps)
# clump_r2=0.7 					# LD r2-threshold ; (lower value yields fewer clumps)
#clump_r2=0.5 					# LD r2-threshold ; (lower value yields fewer clumps)
clump_kb=5000					# physical distance threshold for independency in Kb

plink_version="plink/1.90b4.9"			# clump only with plink1.9  ("module spider plink")  
minutes=120					# requested runtime for each chromosome
partition="node"
sleep_between_pheno=0             		# sleep that many minutes between a new phenotype is started (prevents from using too many nodes simultaneously) 
minspace=100000000  				# 100 MByte    minimum required free disk space 
ask="y"						# Ask the user for confirmation of the input parameters. We might start many jobs (23 nodes per phenoname)

clump_collect_time="10:00"			# requested runtime for "clump_collect", used in clump_pheno.sh  


## Alternative genotype dataset to be used as refence in clump: 
# Outcomment the following line if the default genotype files are to be used! 
# Default = same genotype files as used in gwas. Default is read from parameter file. 
alt_genoid="FTD_rand"				# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD  





