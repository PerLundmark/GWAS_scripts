

# Extract settings (command line paramters overwrite these settings):  

# this file is sourced by remove_samples.sh and by remove_samples_chr.sh

chrom="1-22"						# all autosomes (entering a single chromosome is ok, X,Y not working)
partition="node"   					# partition , "core"  might run out of memory 
minutes=30						# requested runtime for each chromosome in minutes
minspace=10000000   					# 10 MB  minimum required disk space for regression output
plink2_version="plink2/2.00-alpha-2-20190429"   	# search for other versions using " module spider plink2 "   
genofolder="/proj/sens2019016/GENOTYPES/PGEN" 		# location of input genotype dataset; .pgen location
#genofolder="/proj/sens2019016/GENOTYPES/BED" 		# location of input genotype dataset; .bed location
#genofolder="."   					# location of input genotype dataset. Here: folder where the script is started from 

