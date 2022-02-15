
# Extract raw settings (command line paramters overwrite these settings):  

# this file is sourced by extract_raw.sh 


chrom="1-22"						# search all autosomes (entering a single chromosome is possible, X and Y not possible)
# genofolder="/proj/sens2019016/GENOTYPES/PGEN" 	# location of input genotype dataset; only .pgen format allowed!
genofolder="/proj/sens2019016/GENOTYPES/PGEN_ORIG" 	# for non-unique marker names 
genoid="ukb_imp_v3"					# source genotype dataset 
# genoid="MF"	
plink2_version="plink2/2.00-alpha-2.3-20200124"   	# search for other versions using " module spider plink2 "   
