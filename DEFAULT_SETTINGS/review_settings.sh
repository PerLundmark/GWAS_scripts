

# review_gwas settings (command line paramters overwrite these settings):  

# this file is sourced by  review_gwas.sh 

minutes=90				# required runtime, whole genome   
partition="node"   			# "core"  might run out of memory 
chrom="1-22"				# all autosomes 
minspace=10000000  			# 10 MByte    minimum required disk space 


			
## +++ Genotype identifiers ("genoid"):
#					
#   ukb_imp_v3   487.409 samples   complete genotype dataset 
# 	 FTD	 337.466 samples   filtered (ethnic background, kinship)
# 	 MRI	  39.219 samples   MRI samples, not filtered
# 	 MF	  28.146 samples   MRI & filtered  
 
