
# BOLT-LMM settings (command line paramters overwrite these settings):  

# this file is sourced by     


genofolder="/proj/sens2019016/GENOTYPES/BED"    # location of genotype files, (unique marker names)   .bed .bim .fam
genoid="FTD" 				        # biggest BED file available


partition="node"    				# "node" or "core"  (rather not "core")
minutes=100	    				# requested runtime for each chromosome in minutes (60 minutes where not enough for chr 2)
minspace=100000000  				# 100 MByte    minimum required free disk space 
ask="y"						# Ask the user for confirmation of the input parameters. We might start many jobs (25 nodes per phenoname)



## Alternative genotype dataset to be used as refence  
# Outcomment the following line if the default genotype files are to be used! 
# Default = same genotype files as used in gwas. Default is read from parameter file. 
# alt_genoid="FTD_rand"				# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD  
