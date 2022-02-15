#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 



# this script is called by "cojo_collect.sh": 

# cojo_allele   ${summary_file}   ${signif_file}  ${signif_fixed} 
#  
# #                  input            input           output
# 
# # summary_file="${ident}_${phenoname}_cojo.ma"  (cojo_pheno.sh) 
# # signif_file="${ident}_${phenoname}_cojo.jma" (cojo_pheno.sh) 
# # cojo_allele  LIV_MULT5_liv10_cojo.ma  LIV_MULT5_liv10_ojo.jma  LIV_MULT5_liv10_ojo.jma.fixed



 



## +++ Libraries, Functions, Auxiliary Files: 

library(data.table)  # fread





## +++ Gommand line arguments    

args = commandArgs(trailingOnly = TRUE)

if(length(args) < 3) {
  cat("\n")
  cat("  Usage:   cojo_allele.R   <infile1>       <infile2>         <outfile> \n")  
  cat("  Example: cojo_allele.R  LIV6_cojo.ma   LIV6_cojo.jma   LIV6_cojo.ma.fixeded \n")
  cat("\n")
  quit("no")
}

cojo_input  = args[1]   # input   	huge, 14 million rows (markers)         "${ident}_${phenoname}_cojo.ma"  
cojo_output = args[2]   # input   	small   37 rows (independent markers)   "${ident}_${phenoname}_cojo.jma"  
cojo_fixed  = args[3]   # output file   small   37 rows (independent markers with "other" allele entered) 







## +++ Check input files:

if(!file.exists(cojo_input))  stop(paste("\n\n  ERROR (cojo_allele.R): File '", cojo_input, "' not found.\n\n"))
if(!file.exists(cojo_output)) stop(paste("\n\n  ERROR (cojo_allele.R): File '", cojo_output, "' not found.\n\n"))






## +++ Read input files:


# + cojo-output file:  see "cojo_collect.sh"
# 
# head -5 LIV_MULT5_liv2_cojo.jma

# ID			CHR	    POS	    OTHER	A1	A1_FREQ		 OBS_CT	  BETA		     SE	      		P
# rs532548475_G_A	2	13807712	-	G	0.000599056	17984.6	  5.44971	0.980691	2.74435e-08
# rs577713064_G_C	2	46305393	-	G	0.000906995	18368.2	  4.71597	0.788764	2.24604e-09
# rs555658286_A_T	2	77127642	-	A	0.000809429	16422.9	  4.83488	0.882974	4.35836e-08
# rs559097503_G_A	2	113003928	-	G	0.000913064	16673.7	  4.57242	0.82512		2.9986e-08


#  "OTHER" is still missing: that's what we fix here : 

cojo_out = read.table(cojo_output, header = TRUE, sep = "\t", stringsAsFactors = FALSE)  # read .jma file 

# str(cojo_out)

# 'data.frame':	36 obs. of  10 variables:
#  $ ID     : chr  "rs532548475" "rs577713064" "rs555658286" "rs559097503" ...
#  $ CHR    : int  2 2 2 2 2 2 2 3 3 3 ...
#  $ POS    : int  13807712 46305393 77127642 113003928 174472518 189415103 236592939 53460492 74071228 110806600 ...
#  $ OTHER  : chr  "-" "-" "-" "-" ...
#  $ A1     : chr  "G" "G" "A" "G" ...
#  $ A1_FREQ: num  0.000599 0.000907 0.000809 0.000913 0.000702 ...
#  $ OBS_CT : num  17985 18368 16423 16674 16823 ...
#  $ BETA   : num  5.45 4.72 4.83 4.57 5.14 ...
#  $ SE     : num  0.981 0.789 0.883 0.825 0.937 ...
#  $ P      : num  2.74e-08 2.25e-09 4.36e-08 3.00e-08 4.03e-08 ...






# + cojo-input file:  see "cojo_collect.sh"   

# input file format (.ma): "${ident}_${phenoname}_cojo.ma"    (approx. 14 million rows)    
#      created in cojo_convert.sh : ${summary_file}  contains already the correct "other" allele by awk command 
# 

# head LIV_MULT5_liv2_cojo.ma
# ID			A1	OTHER	A1_FREQ		BETA		     SE		       P	OBS_CT
# rs183305313_A_G	A	G	0.00490037	-0.29715	0.364161	0.414519	18771
# rs12260013_G_A	G	A	0.0271634	0.112443	0.156766	0.473222	18771
# rs61838967_C_T	T	C	0.186952	-0.0448559	0.0647333	0.488359	18771
# rs61839042_C_T	C	T	0.361963	0.0200542	0.0509056	0.693623	18771
# rs546162654_A_G	A	G	0.0739644	0.0399546	0.096359	0.678408	18771


# cojo_in = fread(cojo_input, nThread = 16, header = TRUE, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE)   
# better read with cmd= 
# test: cojo_input = "/proj/sens2019016/GWAS_TEST/test.ma"  # small 364   contains all independent markers, a duplicate rs name and 300 more ..          

marker_ids = c("ID", cojo_out$ID)  # ID to get the header in the output 
mark_temp = paste("markers", sample(1:10000,1), "temp.txt", sep = "_")   # "markers_8215_temp.txt"
write.table(marker_ids, file = mark_temp, quote = FALSE, col.names = FALSE, row.names = FALSE)   
cmd = paste("fgrep -f", mark_temp , cojo_input)    #  "fgrep -f markers_8215_temp.txt liver18_smoke_cojo.ma"
cojo_in = fread(cmd = cmd, nThread = 16, header = TRUE, check.names = FALSE, sep = "\t", showProgress = FALSE, stringsAsFactors = FALSE)

# str(cojo_in)  # reads a little bit more than marker_ids because fgrep is used (markers longer names than the pattern included) 
# Classes \u2018data.table\u2019 and 'data.frame':	53 obs. of  8 variables:
#  $ ID     : chr  "rs371272412" "rs77059475" "rs181401293" "rs780311289" ...
#  $ A1     : chr  "G" "G" "C" "T" ...
#  $ OTHER  : chr  "T" "A" "A" "C" ...
#  $ A1_FREQ: num  0.000651 0.000544 0.003456 0.00059 0.000824 ...
#  $ BETA   : num  5.31 6.19 2.28 6.01 4.83 ...
#  $ SE     : num  0.937 1.121 0.412 1 0.876 ...
#  $ P      : num  1.50e-08 3.38e-08 3.19e-08 1.92e-09 3.48e-08 ...
#  $ OBS_CT : int  18771 18771 18771 18771 18771 18771 18771 18771 18771 18771 ...
#  - attr(*, ".internal.selfref")=<externalptr> 

invisible(file.remove(mark_temp))

merged = merge(cojo_in, cojo_out, by.x = c("ID", "A1"), by.y = c("ID", "A1"))  


# head(merged)  
#              1  2   3        4        5          6            7     8      9        10     11     12         13      14         15
#
#             ID A1 OTHER   A1_FREQ.x  BETA.x     SE.x         P.x OBS_CT.x CHR       POS   REF   A1_FREQ.y OBS_CT.y  BETA.y     SE.y
# 1: rs112174250  T     C 0.000658793 5.87351 0.989098 2.93155e-09    18771   7  49830436     - 0.000658793  16043.7 5.87351 0.990154
# 2: rs140017316  A     G 0.008357300 1.59288 0.278380 1.06896e-08    18771   8  60100426     - 0.008357300  16092.3 1.59288 0.278654
# 3: rs181401293  C     A 0.003456050 2.27961 0.412009 3.19155e-08    18771  13  55341955     - 0.003456050  17683.0 2.27961 0.412354
# 4: rs184010787  G     C 0.003965930 2.16206 0.375473 8.63303e-09    18771   3  74071228     - 0.003965930  18562.8 2.16206 0.375798
# 5: rs185506578  G     C 0.000528139 5.87894 1.050080 2.19166e-08    18771   7 136648805     - 0.000528139  17761.0 5.87894 1.050980
# 6: rs185933617  T     A 0.001228840 4.27057 0.695039 8.19012e-10    18771  15  65526256     - 0.001228840  17429.2 4.27057 0.695771
#            P.y
# 1: 2.99416e-09
# 2: 1.08851e-08
# 3: 3.23375e-08
# 4: 8.75443e-09
# 5: 2.22169e-08
# 6: 8.36236e-10

 

# cojo_out contains the NEW "BETA" "SE" "P" "OBS_CT" calculated by cojo !!  ( see "cojo_collect.sh" )

# "bC"		effect size from a joint analysis of all the selected SNPs;
# "bC_se"	standard error from a joint analysis of all the selected SNPs;
# "pC"		p-value from a joint analysis of all the selected SNPs; 
#
# Therefore, "BETA", "SE", "P" do not agree between cojo_in and cojo_out !!!

# sum(merged$A1_FREQ.x != merged$A1_FREQ.y)  # 0

# keep same colums as in cojo_out    keep *.y fields when duplicated 
# colnames(cojo_out)  # "ID"   "CHR"   "POS"   "OTHER"   "A1"   "A1_FREQ"  "OBS_CT"  "BETA"   "SE"   "P"


merged = merged[,c(1,9,10,3,2,12,13,14,15,16)]

# head(merged)  

#             ID CHR       POS OTHER A1   A1_FREQ.y OBS_CT.y  BETA.y     SE.y         P.y
# 1: rs112174250   7  49830436     C  T 0.000658793  16043.7 5.87351 0.990154 2.99416e-09
# 2: rs140017316   8  60100426     G  A 0.008357300  16092.3 1.59288 0.278654 1.08851e-08
# 3: rs181401293  13  55341955     A  C 0.003456050  17683.0 2.27961 0.412354 3.23375e-08
# 4: rs184010787   3  74071228     C  G 0.003965930  18562.8 2.16206 0.375798 8.75443e-09
# 5: rs185506578   7 136648805     C  G 0.000528139  17761.0 5.87894 1.050980 2.22169e-08
# 6: rs185933617  15  65526256     A  T 0.001228840  17429.2 4.27057 0.695771 8.36236e-10

  
merged = merged[order(merged$CHR, merged$POS),]  # sort for chr, then pos   

# head(merged) 

#             ID CHR       POS OTHER.x A1   A1_FREQ.y OBS_CT.y  BETA.y     SE.y         P.y
# 1: rs532548475   2  13807712       A  G 0.000599056  17984.6 5.44971 0.980691 2.74435e-08
# 2: rs577713064   2  46305393       C  G 0.000906995  18368.2 4.71597 0.788764 2.24604e-09
# 3: rs555658286   2  77127642       T  A 0.000809429  16422.9 4.83488 0.882974 4.35836e-08
# 4: rs559097503   2 113003928       A  G 0.000913064  16673.7 4.57242 0.825120 2.99860e-08
# 5: rs539575470   2 174472518       C  T 0.000702046  16823.4 5.14191 0.936694 4.03254e-08
# 6: rs760790704   2 189415103       A  G 0.000588085  16416.1 6.11306 1.036000 3.62072e-09



# compare with original cojo_out

# head(cojo_out) 

#            ID CHR       POS REF A1     A1_FREQ  OBS_CT    BETA       SE           P
# 1 rs532548475   2  13807712   -  G 0.000599056 17984.6 5.44971 0.980691 2.74435e-08
# 2 rs577713064   2  46305393   -  G 0.000906995 18368.2 4.71597 0.788764 2.24604e-09
# 3 rs555658286   2  77127642   -  A 0.000809429 16422.9 4.83488 0.882974 4.35836e-08
# 4 rs559097503   2 113003928   -  G 0.000913064 16673.7 4.57242 0.825120 2.99860e-08
# 5 rs539575470   2 174472518   -  T 0.000702046 16823.4 5.14191 0.936694 4.03254e-08
# 6 rs760790704   2 189415103   -  G 0.000588085 16416.1 6.11306 1.036000 3.62072e-09

# ok


colnames(merged) = c("ID", "CHR", "POS", "OTHER", "A1",	"A1_FREQ", "OBS_CT", "BETA", "SE", "P")


## +++ Save to cojo_fixed (output file)

write.table(merged, file = cojo_fixed, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")

if(!file.exists(cojo_fixed)) {
  stop(paste("\n\n  cojo_allele.R:  File '", cojo_fixed, "' not written.\n\n"))
} else {
   cat(paste("\n\n  cojo_allele.R:  File '", cojo_fixed, "' succesfully created.\n\n"))
}  











