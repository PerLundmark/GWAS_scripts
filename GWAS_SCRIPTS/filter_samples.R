#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Filter a file with sample ID's:





## +++ Call:


## PGEN:    
# filter_samples ukb_imp_v3_chr19.psam a,b        filtered.txt  
# filter_samples ukb_imp_v3_chr19.psam a,b,c,d    filtered2.txt  
# filter_samples ukb_imp_v3_chr19.psam a,b,c,d,e  filtered_female.txt    
# filter_samples ukb_imp_v3_chr19.psam a,b,c,d,f  filtered_male.txt      

# BED:
# filter_samples  FTD_chr22.fam  a filtered_relat.txt  

# RAW, 2 columns:
# filter_samples  filter_input.txt  c,f  filter_output_1.txt

# RAW, 1 column:
# filter_samples  filter_in_one.txt  c,e  filter_output_2.txt






## +++ Hardcoded settings & and defaults 

host = Sys.getenv("HOSTNAME")
account = unlist(strsplit(host, "-", fixed = TRUE))[1]    






## +++ Libraries, Functions

getExtension <- function(file){ 
    ex <- strsplit(basename(file), split="\\.")[[1]]
    return(ex[-1])
} 







## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)     

if(length(args) != 3) {
  cat("\n")
  cat("  Usage: filter_samples   <infile>   <options>  <outfile> \n\n") 
  cat("    Options: (comma-separated list): \n") 
  cat("      a: keep only unrelated participants \n")
  cat("      b: keep only caucasians \n")
  cat("      c: keep only MRI-scanned participants \n")    
  cat("      d: remove samples with sex chromosome aneuploidy \n")  
  cat("      e: keep females only \n")  
  cat("      f: keep males only \n")   
  cat("\n")
  quit("no")
}

infile = args[1]    
options = args[2]
outfile = args[3]  

# options == comma-separated list







## +++ Infiles & outfiles  

if(!file.exists(infile)) {
  cat(paste("\n  ERROR (filter_samples.R): File", infile, "not found.\n\n")) 
  quit("no")
} 


if(file.exists(outfile)) {
  cat(paste("\n  File", outfile, "already exists.\n")) 
  cat("  Delete the existing file or choose another outfile name.\n\n")
  quit("no")
} 








## +++ Options   

opvector = unlist(strsplit(options, split = ",")) 

if(class(opvector) != "character") {
 cat(paste("\n  ERROR (filter_samples.R): options '", options,  "' appear to have wrong format. \n  Use comma-separated list or a single character.\n\n"))
 quit("no")
}

for (op in opvector) {
   if(nchar(op) != 1) {
     cat(paste("\n  ERROR (filter_samples.R): Option '", op,  "' is not a single character.\n\n"))
     quit("no")
   }   
   if( ! op %in% c("a", "b", "c", "d", "e", "f")) {
     cat(paste("\n  ERROR (filter_samples.R): Option '", op,  "' is not valid. Must be a, b, c, d, e, or f.\n\n"))
     quit("no")
   }  
}

if(("e" %in% opvector) & ("f" %in% opvector)) {
  cat(paste("\n  ERROR (filter_samples.R): It does not make sense to filter for both female and male (options 'e' and 'f').\n\n"))
  quit("no")
}










## +++ Load infile  (to filter)   


# allow .psam, .fam format (PGEN or BED folders) , and raw data   


## BED:
#
# head FTD_chr22.fam
# 
# 5954653	5954653	0	0	1	-9
# 1737609	1737609	0	0	2	-9
# 1427013	1427013	0	0	2	-9
# 3443403	3443403	0	0	2	-9
# 5807741	5807741	0	0	2	-9
# 1821438	1821438	0	0	2	-9
# 3951387	3951387	0	0	2	-9


## PGEN:
# 
# head MF_chr15.psam
# 
# #FID	IID	SEX
# 1255400	1255400	2
# 3262895	3262895	2
# 1343405	1343405	1
# 3538003	3538003	1
# 4587215	4587215	1
# 2495030	2495030	1
# 4342109	4342109	2
# 2339751	2339751	2


## RAW:
# 
# head filter_input.txt  (or even with one column only) 
# 
# 5954653	5954653
# 1737609	1737609
# 1427013	1427013
# 3443403	3443403
# 5807741	5807741
# 4188953	4188953
# 1821438	1821438




# + Detect input file format:


## PGEN:
# 
# infile = "/proj/sens2019xxx/GWAS_TEST/ukb_imp_v3_chr19.psam"
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)  # commemt.char = "" NOT used, so that 1st line is stripped! 
# line1
#        V1      V2 V3
# 1 5954653 5954653  1


## BED:
#
# infile = "/proj/sens2019xxx/GWAS_TEST/FTD_chr22.fam" 
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)  
# line1
#        V1      V2 V3 V4 V5 V6
# 1 1001779 1001779  0  0  1 -9


## RAW, 2 columns:
#
# infile = "/proj/sens2019xxx/GWAS_TEST/filter_input.txt"
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)
#  line1
#        V1      V2
# 1 5954653 5954653



## RAW, 1 column: 
#
# infile = "/proj/sens2019xxx/GWAS_TEST/filter_in_one.txt" 
# line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)
#        V1
# 1 5954653


line1 = read.table(infile, header = FALSE, sep = "\t", nrow = 1)
found = 0


if(ncol(line1) == 3) {  # .psam ?  
  suffix = getExtension(infile) # must be "psam"
  if(suffix != "psam") {
    cat(paste("\n  ERROR (filter_samples.R): The input file should have the suffix ' psam ' not '", suffix, "'.\n\n"))
    quit("no")
  } else {
    cat("\n  Input file is probably a .psam file.\n\n")
  }
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  filtered_samples = indata[,2]  # IID
  if(class(filtered_samples) != "integer") {
    cat(paste("\n  ERROR (filter_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(filtered_samples)
    cat("\n\n")
    quit("no")
  } 
  found = found + 1 
}

if(ncol(line1) == 6) {  # .fam ?   
  suffix = getExtension(infile) # must be "fam"  
  if(suffix != "fam") {
    cat(paste("\n  ERROR (filter_samples.R): The input file should have the suffix ' fam ' not '", suffix, "'.\n\n"))
    quit("no")
  } else {
    cat("\n  Input file is probably a .fam file.\n\n")
  }
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  filtered_samples = indata[,2]  # V2
  if(class(filtered_samples) != "integer") {
    cat(paste("\n  ERROR (filter_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(filtered_samples)
    cat("\n\n")
    quit("no")
  } 
  found = found + 1
}

if(ncol(line1) == 2) {  #   RAW, 2 columns ?   
  cat("\n  Input file is probably a raw file with 2 columns.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  filtered_samples = indata[,2]  # V2
  if(class(filtered_samples) != "integer") {
    cat(paste("\n  ERROR (filter_samples.R): The 2nd column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(filtered_samples)
    cat("\n\n")
    quit("no")
  } 
  found = found + 1
}

if(ncol(line1) == 1) {  #   RAW, 1 column ?   
  cat("\n  Input file is probably a raw file with 1 column.\n\n")
  indata = read.table(infile, header = FALSE, sep = "\t", stringsAsFactors = FALSE)  # commemt.char = "" NOT used, so that 1st line is stripped!
  filtered_samples = indata[,1]  # V1
  if(class(filtered_samples) != "integer") {
    cat(paste("\n  ERROR (filter_samples.R): The 1st column in", infile, "does not seem to contain sample IDs.\n\n"))
    head(filtered_samples)
    cat("\n\n")
    quit("no")
  }
  found = found + 1 
}


if (found != 1) {
  cat("\n  ERROR (filter_samples.R): The input file type could not be identified.\n")
  cat("  Allowed are '.psam', '.fam', or text files with one or two columns, containing sample IDs.\n\n")
  quit("no")
} else {   
  cat(paste("  The input list contains", length(filtered_samples), "participants.\n\n"))
}











## +++ Load filters 

scripts = Sys.getenv("SCRIPT_FOLDER")  #  /proj/sens2019xxx/GWAS_SCRIPTS"


# OBS!: lists including all samples are needed, about 502.000 samples"






## ========== Sources ============



# +++ a) kinship:
#
# 	"Used in genetic principal components"     column_22020.csv
#         contains only participants without relatives in the databank (Tove)
#  
# OR: 
# search_fieldID principal
# 
#   Searching for keyword ' principal '
# 
#   Category 100313 	FieldID : 22009 	Field : Genetic principal components 
#   Category 100313 	FieldID : 22020 	Field : Used in genetic principal components 
#
# /proj/sens2019xxx/UKB_genetics/column_22020.csv
# /home/umenzel/DATA/column_22020.csv
#
# wc -l /proj/sens2019xxx/UKB_genetics/column_22020.csv  	# 502537  
# wc -l /home/umenzel/DATA/column_22020.csv  			# 502537 
# diff /proj/sens2019xxx/UKB_genetics/column_22020.csv /home/umenzel/DATA/column_22020.csv 
#  
# head /home/umenzel/DATA/column_22020.csv
# "eid","22020-0.0"
# "1000015",""
# "1000027","1"
# "1000039","1"
# "1000040","1"
# "1000053","1"
# "1000064","1"
# "1000071","1"
# "1000088","1"
# "1000096","1"
#
# kinship_file = "/home/umenzel/DATA/column_22020.csv"
# kinship = read.table(kinship_file, header = TRUE, sep = ",", stringsAsFactors = FALSE)
#
# str(kinship)
# 
# 'data.frame':	502536 obs. of  2 variables:
#  $ eid       : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ X22020.0.0: int  NA 1 1 1 1 1 1 1 1 NA ...
#
# table(kinship$X22020.0.0, useNA = "always")
#      1   <NA> 
# 407146  95390   ok    see "get_phenotype_data.R"
#
# save ID's to . RData : 
#
# sum(kinship$X22020.0.0 == 1, na.rm = TRUE)  # 407146  ok
# 
# indx = which(kinship$X22020.0.0 == 1)
# length(indx) # 407146  ok  
# 
# id_unrelated = kinship$eid[indx] 
# length(id_unrelated) # 407146  ok
# 
# str(id_unrelated)  # int [1:407146] 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000125 1000154 ...
# 
# save(id_unrelated, file = "IDs_unrelated.RData")  
# 
# file.info("IDs_unrelated.RData")[,c(1,4)]  # IDs_unrelated.RData 1064831 2020-05-08 16:39:55
#
# -rw-r--r-- 1 umenzel umenzel  1064831 May  8 16:44 IDs_unrelated.RData
#
# cp -i IDs_unrelated.RData ~/bin/GWAS_SCRIPTS/






# +++ b) ethnicity  

# causasian_22006
#   see "get_phenotype_data.R":  
# 
#     table(filtered$causasian_22006, useNA = "always")  
#     #      1   <NA> 
#     # 337484  69662
#
# search_fieldID ethnic
# 
#   Searching for keyword ' ethnic '
# 
#   Category 100065 	FieldID : 21000 	Field : Ethnic background 
#   Category 100313 	FieldID : 22006 	Field : Genetic ethnic grouping  
#
# wc -l /proj/sens2019xxx/UKB_genetics/column_22006.csv  # 502537 
#
# http://biobank.ctsu.ox.ac.uk/showcase/field.cgi?id=22006
#   ==> 409.616 caucasians
#
# [umenzel@sens2019xxx-bianca UKB_genetics]$ head column_22006.csv
# "eid","22006-0.0"
# "1000015",""
# "1000027","1"
# "1000039","1"
# "1000040","1"
# "1000053","1"
# "1000064","1"#
# "1000071","1"
# "1000088","1"
# "1000096","1"
#
# ethnic_file = "/home/umenzel/DATA/column_22006.csv"
# ethnic_file = "/proj/sens2019xxx/UKB_genetics/column_22006.csv"
# ethnic = read.table(ethnic_file, header = TRUE, sep = ",", stringsAsFactors = FALSE)

# str(ethnic)
# 'data.frame':	502536 obs. of  2 variables:
#  $ eid       : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ X22006.0.0: int  NA 1 1 1 1 1 1 1 1 1 ... 
# 
# table(ethnic$X22006.0.0, useNA = "always")
#      1   <NA> 
# 409629  92907        does not exactly agree with the http://biobank.ctsu.ox.ac.uk entry 
#
# sum(ethnic$X22006.0.0 == 1, na.rm = TRUE)  # 409629  does not exactly agree with the http://biobank.ctsu.ox.ac.uk entry
# 
# indx = which(ethnic$X22006.0.0 == 1)
# length(indx) # 409629  
# 
# id_caucasian = ethnic$eid[indx] 
# length(id_caucasian) # 409629  ok
# 
# str(id_caucasian)  # int [1:409629] 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 1000117 ...
# 
# save(id_caucasian, file = "IDs_caucasian.RData")  
# 
# file.info("IDs_caucasian.RData")[,c(1,4)]  # IDs_caucasian.RData 1071087 2020-05-11 13:50:56
#
# -rw-rw-r-- 1 umenzel umenzel       1071087 May 11 13:50 IDs_caucasian.RData
#
# cp -i IDs_caucasian.RData ~/bin/GWAS_SCRIPTS/







## +++ c) MRI scanned samples 

# Mail Taro, May 5, 2020 ids_checked.txt ==> ids_checked_26_02_2020.txt ==> reformatted MRI_IDs_26_02_2020.txt 
# 
# "On the 26.2.2020 we got access to a new UK Biobank refresh with a total of 40,264 imaged subjects, 
# of which we were able to download and convert 40,261. 
# I appended the resulting file, which is effectively an update to the one Filip shared with you before." 
# 
#  -rw-rw-r-- 1 umenzel umenzel 644176 May  5 09:10 MRI_IDs_26_02_2020.txt
#  
# wc -l MRI_IDs_26_02_2020.txt   # 40261 
#   
# head MRI_IDs_26_02_2020.txt
# 
# 1000015	1000015
# 1000180	1000180
# 1000401	1000401
# 1000435	1000435
# 1000456	1000456
# 1000493	1000493
# 1000795	1000795
# 1000843	1000843
# 1000885	1000885
# 1001070	1001070
# 
# 
# mri_file = "/home/umenzel/Desktop/R/MRI_IDs_26_02_2020.txt"
# mri = read.table(mri_file, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
# 
# str(mri)
# 'data.frame':	40261 obs. of  2 variables:
#  $ V1: int  1000015 1000180 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 ...
#  $ V2: int  1000015 1000180 1000401 1000435 1000456 1000493 1000795 1000843 1000885 1001070 ...
# 
# head(mri)
# 
#        V1      V2
# 1 1000015 1000015
# 2 1000180 1000180
# 3 1000401 1000401
# 4 1000435 1000435
# 5 1000456 1000456
# 6 1000493 1000493
# 
# id_mri = mri$V2
# 
# length(id_mri)   #  40261 
# 
# head(id_mri)  # 1000015 1000180 1000401 1000435 1000456 1000493  

# save(id_mri, file = "IDs_MRI.RData")  
# 
# file.info("IDs_MRI.RData")[,c(1,4)]  # IDs_MRI.RData 104335 2020-05-12 12:26:42
#
# -rw-rw-r-- 1 umenzel umenzel        104335 May 12 12:26 IDs_MRI.RData
#
# cp -i IDs_MRI.RData ~/bin/GWAS_SCRIPTS/
# cp -i IDs_MRI.RData /proj/sens2019xxx/GWAS_SCRIPTS
 




## +++ d) sex chromosome aneuploidy   

# Slack April 27 2020:
# Jenny Censin(opens in new tab)  3:07 PM
# Hi guys! Just spent the day cleaning samples :slightly_smiling_face: 
# Just FYI, it seems like there might be six samples with sex chromosome aneuploidy 
# (looking at the samples in the file /proj/sens2019xxx/GENOTYPES/MRI_Filtered_2.txt 
# and then comparing those IDs to the file /proj/sens2019xxx/UKB_baseline/ukb23907_long.txt 
# and the column n_22019_0_0, where 1 == yes...). Not sure if you want to keep those in the other imiomics analyses?
#
# search_fieldID   aneuploidy
#
# Searching for keyword ' aneuploidy '
# 
#   Category 100313 	FieldID : 22019 	Field : Sex chromosome aneuploidy  

# fetch_pheno --field 22019 --out field_22019.txt
# head field_22019.txt
# #FID	IID	field_22019
# 1000015	1000015	NA
# 1000027	1000027	NA
# 1000039	1000039	NA
# 1000040	1000040	NA
# 1000053	1000053	NA
#
# wc -l field_22019.txt  # 502544 field_22019.txt 
# cat field_22019.txt | awk 'BEGIN{FS="\t"} {print $3}' | sort | uniq -c
#     651 1
#       1 field_22019
#  501892 NA
# 651 is ok, see http://biobank.ctsu.ox.ac.uk/showcase/field.cgi?id=22019  
#
# OR:
#
# wc -l /proj/sens2019xxx/UKB_genetics/column_22019.csv  # 502537 
# 
# head /proj/sens2019xxx/UKB_genetics/colu28146mn_22019.csv
# "eid","22019-0.0"
# "1000015",""
# "1000027",""
# "1000039",""
# "1000040",""
# "1000053",""
# "1000064",""
# "1000071",""
# "1000088",""
# "1000096",""
# 
# cat /proj/sens2019xxx/UKB_genetics/column_22019.csv | awk 'BEGIN{FS=","} {print $2}' | sort | uniq -c 
#  501885 ""
#     651 "1"          # ok the same
#       1 "22019-0.0"
# 
# aneuploidy_file = "/home/umenzel/DATA/field_22019.txt"
# aneuploidy = read.table(aneuploidy_file, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)
# 
# str(aneuploidy)
# 'data.frame':	502543 obs. of  3 variables:
#  $ X.FID      : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ IID        : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ field_22019: int  NA NA NA NA NA NA NA NA NA NA ...
# 
# head(aneuploidy)   
# 
#     X.FID     IID field_22019
# 1 1000015 1000015          NA
# 2 1000027 1000027          NA
# 3 1000039 1000039          NA
# 4 1000040 1000040          NA
# 5 1000053 1000053          NA
# 6 1000064 1000064          NA
# 
# table(aneuploidy$field_22019, useNA = "ifany")   
#      1   <NA> 
#    651 501892 
# 
# sum(aneuploidy$field_22019 == 1, na.rm = TRUE) # 651
# 
# indx = which(aneuploidy$field_22019 == 1)
# 
# length(indx)  # 651  
# 
# head(aneuploidy[indx,]) 
#  
#        X.FID     IID field_22019
# 1434 1014349 1014349           1
# 2681 1026814 1026814           1
# 3416 1034169 1034169           1
# 3510 1035109 1035109           1
# 3527 1035277 1035277           1
# 3853 1038534 1038534           1
# 
# id_aneuploidy = aneuploidy$IID[indx] 
# 
# head(id_aneuploidy)  #  1014349 1026814 1034169 1035109 1035277 1038534
# 
# save(id_aneuploidy, file = "IDs_aneuploidy.RData")  
# 
# file.info("IDs_aneuploidy.RData")[,c(1,4)]  # IDs_aneuploidy.RData 2303 2020-05-12 11:04:06
#
# -rw-rw-r-- 1 umenzel umenzel          2303 May 12 11:04 IDs_aneuploidy.RData
#
# cp -i IDs_aneuploidy.RData ~/bin/GWAS_SCRIPTS/
# cp -i IDs_aneuploidy.RData /proj/sens2019xxx/GWAS_SCRIPTS




## +++ d und e)) female and male

# search_fieldID sex
# 
#   Category 100313 	FieldID : 22001 	Field : Genetic sex
#   
# fetch_pheno --field 22001 --out genetic_sex_22001.txt
# 
# wc -l genetic_sex_22001.txt  # 502544
# 
# head genetic_sex_22001.txt  
#   
# #FID	IID	field_22001
# 1000015	1000015	0
# 1000027	1000027	0
# 1000039	1000039	0
# 1000040	1000040	0
# 1000053	1000053	0
# 1000064	1000064	1
# 1000071	1000071	0
# 1000088	1000088	0
# 1000096	1000096	0
# 
# cat genetic_sex_22001.txt |  awk 'BEGIN{FS="\t"} {print $3}' | sort | uniq -c
#  264814 0
#  223481 1
#       1 field_22001
#   14248 NA
# 
# 0 == female
# 1 == male 
# 
# fn = "genetic_sex_22001.txt"
# gender = read.table(fn, header = TRUE, sep = "\t", comment.char = "", stringsAsFactors = FALSE)
# 
# str(gender)
# 'data.frame':	502543 obs. of  3 variables:
#  $ X.FID      : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ IID        : int  1000015 1000027 1000039 1000040 1000053 1000064 1000071 1000088 1000096 1000109 ...
#  $ field_22001: int  0 0 0 0 0 1 0 0 0 1 ...
# 
# head(gender)  
# 
#     X.FID     IID field_22001
# 1 1000015 1000015           0
# 2 1000027 1000027           0
# 3 1000039 1000039           0
# 4 1000040 1000040           0
# 5 1000053 1000053           0
# 6 1000064 1000064           1
# 
# table(gender$field_22001, useNA = "ifany") 
# 
#      0      1   <NA> 
# 264814 223481  14248 
# 
# sum(gender$field_22001 == 0, na.rm = TRUE)  # 264814 
# sum(gender$field_22001 == 1, na.rm = TRUE)  # 223481
# 
# indfemale = which(gender$field_22001 == 0) 
# length(indfemale)  # 264814
# id_female = gender$IID[indfemale]  
# length(id_female)  # 264814
# head(id_female) # 1000015 1000027 1000039 1000040 1000053 1000071
# 
# 
# indmale = which(gender$field_22001 == 1) 
# length(indmale)  # 223481
# id_male = gender$IID[indmale]  
# length(id_male)  # 223481
# head(id_male) #  1000064 1000109 1000132 1000154 1000176 1000180
# 
# save(id_female, file = "IDs_female.RData")  
# 
# file.info("IDs_female.RData")[,c(1,4)]  # IDs_female.RData 690509 2020-05-12 12:56:26
#
# -rw-rw-r-- 1 umenzel umenzel  690509 May 12 12:56 IDs_female.RData         
#
# cp -i IDs_female.RData ~/bin/GWAS_SCRIPTS/
# cp -i IDs_female.RData /proj/sens2019xxx/GWAS_SCRIPTS

# save(id_male, file = "IDs_male.RData")  
# 
# file.info("IDs_male.RData")[,c(1,4)]  # IDs_male.RData 581418 2020-05-12 12:58:44
#
# -rw-rw-r-- 1 umenzel umenzel    581418 May 12 12:58 IDs_male.RData         
#
# cp -i IDs_male.RData ~/bin/GWAS_SCRIPTS/
# cp -i IDs_male.RData /proj/sens2019xxx/GWAS_SCRIPTS









## ============================================================================================================


if( "a" %in% opvector) {
  fn = paste(scripts, "IDs_unrelated.RData", sep="/")  #  "/proj/sens2019xxx/GWAS_SCRIPTS/IDs_unrelated.RData"
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }
  id_unrelated = get(load(fn)) 
  cat("  Applying filter 'a': Keep only unrelated participants. \n")
  cat(paste("    We have", length(id_unrelated), "unrelated individuals available.\n"))   #   407146
  filtered_samples = intersect(filtered_samples, id_unrelated)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))     
} 



if( "b" %in% opvector) {
  fn = paste(scripts, "IDs_caucasian.RData", sep="/") 
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }  
  id_caucasian = get(load(fn)) 
  cat("  Applying filter 'b': Keep only caucasian participants. \n")  
  cat(paste("    We have", length(id_caucasian), "caucasian individuals available.\n"))   #  
  filtered_samples = intersect(filtered_samples, id_caucasian)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }  
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))        
}



if( "c" %in% opvector & account == "sens2019016") {  # MRI  
  fn = paste(scripts, "IDs_MRI.RData", sep="/") 
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }  
  id_mri = get(load(fn)) 
  cat("  Applying filter 'c': Keep only MRI-scanned participants. \n")  
  cat(paste("    We have", length(id_mri), "MRI-scanned individuals available.\n"))   #  
  filtered_samples = intersect(filtered_samples, id_mri)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }  
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))        
} 


if( "c" %in% opvector & account == "sens2019570") {  # MRI 
  cat("\n  Sorry, MRI is not yet implemented for project 570. Exiting ...\n\n")
  quit("no")
}


if( "d" %in% opvector & account == "sens2019016") {  # aneuploidy, the ID's have to be removed 
  fn = paste(scripts, "IDs_aneuploidy.RData", sep="/")
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }  
  id_aneuploidy = get(load(fn))
  cat("  Applying filter 'd': Remove samples with sex chromosome aneuploidy. \n")
  cat(paste("    We have", length(id_aneuploidy), "individuals with sex chromosome aneuploidy in the database.\n"))
  filtered_samples = setdiff(filtered_samples, id_aneuploidy)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }  
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))       
}


if( "d" %in% opvector & account == "sens2019570") {  # aneuploidy, the ID's have to be removed
  cat("\n  Sorry, aneuploidy is not yet implemented for project 570. Exiting ...\n\n")
  quit("no")
}




if( "e" %in% opvector) {    # female    
  fn = paste(scripts, "IDs_female.RData", sep="/") 
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }  
  id_female = get(load(fn)) 
  cat("  Applying filter 'e': Keep only female participants. \n")  
  cat(paste("    We have", length(id_female), "female participants available.\n"))   #  
  filtered_samples = intersect(filtered_samples, id_female)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }  
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))        
} 



if( "f" %in% opvector) {    # male    
  fn = paste(scripts, "IDs_male.RData", sep="/") 
  if(!file.exists(fn)) {
    cat(paste("\n  ERROR (filter_samples.R): File", fn, "not found.\n\n"))
    quit("no")
  }  
  id_male = get(load(fn)) 
  cat("  Applying filter 'f': Keep only male participants. \n")  
  cat(paste("    We have", length(id_male), "male participants available.\n"))   #  
  filtered_samples = intersect(filtered_samples, id_male)
  if(length(filtered_samples) == 0) {
    cat("  No samples left after this filter. Exiting ...\n\n")
    quit("no")
  }  
  cat(paste("    Applying that filter reduces the input list to", length(filtered_samples), "participants.\n\n"))        
} 





## +++ Save the filtered_samples :

outframe = data.frame(FID = filtered_samples, IID = filtered_samples)  

# str(outframe)
# 'data.frame':	27219 obs. of  2 variables:
#  $ FID: int  1000435 1000493 1000843 1001070 1001146 1001271 1001399 1001544 1001779 1001892 ...
#  $ IID: int  1000435 1000493 1000843 1001070 1001146 1001271 1001399 1001544 1001779 1001892 ... 
# 
# 
# head(outframe)
# 
#       FID     IID
# 1 1000435 1000435
# 2 1000493 1000493
# 3 1000843 1000843
# 4 1001070 1001070
# 5 1001146 1001146
# 6 1001271 1001271


write.table(outframe, file = outfile, col.names = FALSE, quote = FALSE, sep = "\t", row.names = FALSE)

# head filtered.txt
# 
# 1000435	1000435
# 1000493	1000493
# 1000843	1000843
# 1001070	1001070
# 1001146	1001146
# 1001271	1001271
# 1001399	1001399

cat(paste("  Output saved to:", outfile, "\n\n")) 
cat("  Use the program 'extract_samples' to obtain a genotype dataset based on the filtered samples.\n\n")
quit("no")  # uwe.menzel@medsci.uu.se   














