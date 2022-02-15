

# Convert settings (command line paramters overwrite these settings):  

# this file is sourced by convert_genotypes.sh   



plink2_version="plink2/2.00-alpha-2-20190429"   # search for other versions using " module spider plink2 " 
partition="node"   				# partition , "core"  might run out of memory  
minspace=10000000   				# 10 MB  minimum required disk space for regression output 
minutes=180					# required runtime for each chromosome in minutes
chrom="1-22"					# all autosomes (entering a single chromosome is ok, X,Y not working)
infolder="/proj/sens2019016/GENOTYPES/PGEN"   	# location of input genotype files
outfolder="/proj/sens2019016/GENOTYPES/BED"   	# location of output genotype files





