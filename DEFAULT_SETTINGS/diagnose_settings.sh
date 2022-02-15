

# gwas_diagnose settings (command line paramters overwrite these settings):  

# this file is sourced by gwas_diagnose.sh and by extract_genotype.sh   



# genoid="MF" 					# genotype dataset; filtered for ethnicity, kinship, 27.212 samples
genoid="ukb_imp_v3"				# full genotype dataset  

genofolder="/proj/sens2019016/GENOTYPES/PGEN"   # location of input genotype dataset

# phenofolder="/proj/sens2019016/PHENOTYPES"	# location of input phenotype and covariate files
phenofolder="."		      

# do NOT enter covarfile or covarname! Both are read from paramfile if not entered on command line

minutes=10					# requested runtime for subroutine "extract_genotype.sh" 
rminutes=20					# requested runtime for subroutine "gwas_diagnose.R" 
partition="node"   				# partition , "core"  might run out of memory   


			
## +++ Genotype identifiers ("genoid"):
#					
#   ukb_imp_v3   487.409 samples   complete genotype dataset 
# 	 FTD	 337.466 samples   filtered (ethnic background, kinship)
# 	 MRI	  39.219 samples   MRI samples, not filtered
# 	 MF	  28.146 samples   MRI & filtered  
			









