#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  



## === Convert plink2 gwas output files (*.glm.linear or *.glm.logistic) to GCTA-COJO input file (*.ma)   
   
# 	https://cnsgenomics.com/software/gcta/#COJO






## +++ Main output:

# 1) ${ident}_${phenoname}_cojo.ma          input file for cojo for this phenotype
# 2) ${ident}_${phenoname}_gwas_signif.txt  list with significant markers for this phenotype name, all chromosomes



## +++ Call:
#
# called by "cojo_pheno.sh" :
#
# convert_jobid=$( sbatch -A ${account} -p ${partition}  -t ${cojo_convert_time}  -J ${c_ident} -o ${convert_log} -e ${convert_log} \
#        cojo_convert  --id ${ident}  --phenoname ${phenoname} --summary ${summary_file} --pval ${pval}  --siglist ${signif_list
#
# Interactive:
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 2:00:00 -A sens2019016 
#   cojo_convert  --id LIV_MULT5  --phenoname liv1  --summary LIV_MULT5_liv1_cojo.ma --siglist LIV_MULT5_liv1_gwas_signif.txt
#   cojo_convert  --id LIV_MULT5  --phenoname liv1  --summary LIV_MULT5_liv1_cojo.ma --pval 5e-8  --siglist LIV_MULT5_liv1_gwas_signif.txt
#
# phenoname must be a single word --> only one phenotype is run here 
# --summary and --siglist denote output files




# +++ Testing

# pwd /proj/sens2019016/nobackup/GWAS_TEST/liver18
#
# ~/bin/GWAS_SCRIPTS/cojo_convert.sh  --id liver18  --phenoname liver_fat_a_res_norm  --summary out.ma --pval 5e-8  --siglist signif.txt




 
## +++ Hardcoded settings & defaults  

shopt -s nullglob   # see the comment after the regress_out_lin=... command below   

setfile=~/cojo_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (cojo_convert.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi









## +++ Get command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 8 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"  
  echo "         -pn|--phenoname <string>       no default"        
  echo "         -s|--summary <file>            no default"   # output file  (.ma)
  echo "         -p|--pval <real>               ${setfile}"
  echo "         -sl|--siglist <file>           no default"   # output file (signif. markers across the genome)  
  echo ""
  exit 1
fi


while [ "$#" -gt 0 ]
do
  case $1 in
      -i|--id)
          ident=$2
          shift
          ;;
     -pn|--phenoname)
          phenoname=$2
          shift
          ;;	  	  	  
      -s|--summary)
          summary_file=$2
          shift
          ;;
      -p|--pval)
          pval=$2
          shift
          ;;
      -sl|--siglist)
          signif_list=$2
          shift
          ;;	  	   	   	  	  	  	    	  	  
      *)
          echo ""
	  echo "  Invalid argument: $1"
	  echo ""
	  exit 1
          ;;
  esac
  shift
done







## +++ Check if the variables are defined  

to_test=(ident phenoname  summary_file  signif_list pval  partition)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (cojo_convert.sh): Mandatory variable '$var' is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Header:      (all ouput in batchlog, defined in cojo_pheno.sh") 

echo ""
START=$(date +%s) 
echo -n "  "
date 
echo "  Job identifier: ${ident}"
echo "  Phenotype namn: ${phenoname}"
echo "  Summary statistics to create: ${summary_file}" 
echo "  p-value threshold (for creating list of signif. markers): ${pval}" 
echo "  List with significant markers (whole genome): ${signif_list}  (to create)"
echo "" 







## +++  Regression output files:   

# *linear and *.logistic have the same format!:
#
# /proj/sens2019016/nobackup/GWAS_TEST/liver18 > 
# 
# head -1 liver18_gwas_allchr.liver_fat_a_res_norm.glm.linear liver18_gwas_chr10.smoke.glm.logistic
# 
# ==> liver18_gwas_allchr.liver_fat_a_res_norm.glm.linear <==
# #CHROM	POS	ID	REF	ALT1	A1	A1_FREQ	OBS_CT	BETA	SE	P
# 
# ==> liver18_gwas_chr10.smoke.glm.logistic <==
# #CHROM	POS	ID	REF	ALT1	A1	A1_FREQ	OBS_CT	BETA	SE	P


#  the nullglob command above causes the array to be empty if there are no matches : 
regress_out_lin=(${ident}_gwas_chr*${phenoname}.glm.linear)    # linear regression      
regress_out_log=(${ident}_gwas_chr*${phenoname}.glm.logistic)  # logistic regression [ case/control ]

nr_regress_lin=${#regress_out_lin[*]} 
nr_regress_log=${#regress_out_log[*]}      

files_found=0

if [ "${nr_regress_lin}" -gt 0 ];then
  echo "  ${nr_regress_lin} linear regression output file(s) found."
  echo ""
  files_found=$(( ${files_found} + 1 ))
  regress_out=("${regress_out_lin[@]}")
  suffix="linear"
fi

if [ "${nr_regress_log}" -gt 0 ];then
  echo "  ${nr_regress_log} logistic regression output file(s) found."
  echo ""
  files_found=$(( ${files_found} + 1 ))
  regress_out=("${regress_out_log[@]}")
  suffix="logistic"
fi

if [ "${files_found}" -eq 0 ];then
  echo ""
  echo "  ERROR (cojo_convert.sh): No regression output files found."
  echo ""
  exit 1
fi

if [ "${files_found}" -eq 2 ];then
  echo "  ERROR (cojo_convert.sh): Both linear and logistic regression output files found for phenoname ${phenoname}."
  echo "                           Please check your results."  
  echo ""
  exit 1
fi

echo "" 
echo "  GWAS results in this folder:" 
echo "" 

let i=0
for glm in  ${regress_out[*]} 
do
  let i++
  ls -l $glm 
done
echo "" 






## +++ Concatenate the summary statistics of all chromosomes: 
#
#     "Please always input the summary statistics of all SNPs even if your analysis only focuses on a subset of SNPs" 

sumstat_all_chrom="${ident}_${phenoname}.glm.${suffix}"  # temporary

echo -n "  Merging gwas files ..."  	# following file name convention from plink2 --glm (gwas_chr.sh) 
tail -n +2 -q ${ident}_gwas_chr*${phenoname}.glm.${suffix} > ${sumstat_all_chrom}     
echo  "  Done."
echo ""  

# head ${sumstat_all_chrom}
# 10	61334	rs183305313	A	G	A	0.00490037	18771	-0.29715	0.364161	0.414519
# 10	66326	rs12260013	G	A	G	0.0271634	18771	0.112443	0.156766	0.473222
# 10	71776	rs61838967	C	T	T	0.186952	18771	-0.0448559	0.0647333	0.488359
# 10	76294	rs61839042	C	T	C	0.361963	18771	0.0200542	0.0509056	0.693623
# 10	76352	rs546162654	A	G	A	0.0739644	18771	0.0399546	0.096359	0.678408
# 10	76471	rs199903180	A	G	A	0.282271	18771	-0.0490766	0.0567596	0.387247

 





## +++ Convert plink2 gwas output file to the format requested by gcta:  see https://cnsgenomics.com/software/gcta/#COJO  

# Required format:
#
#    SNP A1 A2    freq      b     se      p      N 
# rs1001 A   G  0.8493 0.0024 0.0055 0.6653 129850 
# rs1002 C   G  0.0306 0.0034 0.0115 0.7659 129799 
# rs1003 A   C  0.5128 0.0045 0.0038 0.2319 129830    
# 
# Columns are:
#  SNP, 
#  the effect allele, 
#  the other allele, 
#  frequency of the effect allele, 
#  effect size, 
#  standard error, 
#  p-value  
#  sample size. 
#
#  The headers are not keywords and will be omitted by the program. 
#  Important: "A1" needs to be the effect allele with "A2" being the other allele and "freq" should be the frequency of "A1".
#  
#  Please always input the summary statistics of all SNPs even if your analysis only focuses on a subset of SNPs 
#  because the program needs the summary data of all SNPs to calculate the phenotypic variance.

echo -n "  Reformatting gwas files for GCTA-COJO ..."  
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "A1" "OTHER" "A1_FREQ" "BETA" "SE" "P" "OBS_CT" > ${summary_file} # ${ident}_cojo.ma (run_cojo.sh)


# Format of ${sumstat_all_chrom} (from "run_gwas.sh") 
#
# #CHROM	POS		ID	REF	ALT1	A1	A1_FREQ		OBS_CT	    BETA	      SE	       P
# 10		61334	rs183305313	A	G	A	0.00490037	18771	-0.29715	0.364161	0.414519
# 10		66326	rs12260013	G	A	G	0.0271634	18771	0.112443	0.156766	0.473222
# 10		71776	rs61838967	C	T	T	0.186952	18771	-0.0448559	0.0647333	0.488359
# 10		76294	rs61839042	C	T	C	0.361963	18771	0.0200542	0.0509056	0.693623
# 10		76352	rs546162654	A	G	A	0.0739644	18771	0.0399546	0.096359	0.678408
# 10		76471	rs199903180	A	G	A	0.282271	18771	-0.0490766	0.0567596	0.387247
#
#  1              2         3           4       5       6          7              8         9               10             11

# A1 = effect allele (in regression), see "plink2_regression_details.txt" 
# "other allele" has to be detected: 

# https://www.cog-genomics.org/plink/2.0/assoc#glm  
# For biallelic variants, G normally contains a single column with minor allele dosages. 
# This allele is listed in the A1 column of the main report.   

awk 'BEGIN{FS="\t"} {if($6 == $5) {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $3, $6, $4, $7, $9, $10, $11, $8} \
                             else {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $3, $6, $5, $7, $9, $10, $11, $8}}' ${sumstat_all_chrom} >> ${summary_file} 


echo "  Done." 

# head -4 ${summary_file}   #  head -4  LIV6_cojo.ma
# 	   ID	A1	OTHER	  A1_FREQ	   BETA		      SE	       P       OBS_CT
# rs183305313	A	G	0.00490037	-0.29715	0.364161	0.414519	18771
# rs12260013	G	A	0.0271634	0.112443	0.156766	0.473222	18771
# rs61838967	T	C	0.186952	-0.044855	0.0647333	0.488359	18771
# rs61839042	C	T	0.361963	0.0200542	0.0509056	0.693623	18771






# + Check the header (this is critical !, depends on settings in "gwas_chr.sh" : plink2 --glm hide-covar 'cols=chrom,pos,ref,alt1,a1freq,beta,se,p,nobs')     

header=$( head -1 ${summary_file} ) #  *.ma
echo "" 

arr=($header)
nr_cols=${#arr[@]}

if [ "$nr_cols" -ne 8 ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Need 8 columns in the cojo input file ( \"${summary_file}\" ), not ${nr_cols}." 
  echo "" 
  exit 1
fi

if [ ${arr[0]} != "ID" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 1 in summary statstistics file: ${arr[0]}" 
  echo "" 
  exit 1
fi

if [ ${arr[1]} != "A1" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 2 in summary statstistics file: ${arr[1]}" 
  echo "" 
  exit 1
fi

if [ ${arr[2]} != "OTHER" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 3 in summary statstistics file: ${arr[2]}"  
  echo "" 
  exit 1
fi

if [ ${arr[3]} != "A1_FREQ" ];then
  echo ""
  echo "  ERROR (cojo_convert.sh): Wrong column 4 in summary statstistics file: ${arr[3]}" 
  echo ""
  exit 1
fi

if [ ${arr[4]} != "BETA" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 5 in summary statstistics file: ${arr[4]}" 
  echo "" 
  exit 1
fi

if [ ${arr[5]} != "SE" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 6 in summary statstistics file: ${arr[5]}" 
  echo ""
  exit 1
fi

if [ ${arr[6]} != "P" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 7 in summary statstistics file: ${arr[6]}"  
  echo "" 
  exit 1
fi

if [ ${arr[7]} != "OBS_CT" ];then
  echo "" 
  echo "  ERROR (cojo_convert.sh): Wrong column 8 in summary statstistics file: ${arr[7]}"  
  echo "" 
  exit 1
fi







## +++ Create a list including chromosomes with significant markers (to exclude those chromosomes with no signif. markers from analysis in "cojo_chr.sh")

# OBS!!  no header in ${sumstat_all_chrom}
#
# 10		61334	rs183305313	A	G	A	0.00490037	18771	-0.29715	0.364161	0.414519
# 10		66326	rs12260013	G	A	G	0.0271634	18771	0.112443	0.156766	0.473222
# 10		71776	rs61838967	C	T	T	0.186952	18771	-0.0448559	0.0647333	0.488359
# 10		76294	rs61839042	C	T	C	0.361963	18771	0.0200542	0.0509056	0.693623
#
#  1              2         3           4       5       6          7              8         9               10             11
# #CHROM	 POS	   ID	       REF    ALT1	A1	A1_FREQ		OBS_CT	   BETA	            SE	            P


echo -n "  Extracting significant markers ..."
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "CHR" "POS" "A1" "A1_FREQ" "BETA" "SE" "P" > ${signif_list}
awk -v pval=${pval} 'BEGIN{FS="\t"}{if($NF <= pval) printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $3,$1,$2,$6,$7,$9,$10,$11}' ${sumstat_all_chrom} >> ${signif_list}
nr_signif=$( wc -l ${signif_list} | awk '{print $1}' )
nr_signif=$(( ${nr_signif} - 1 ))
echo "  Done (${nr_signif} markers across the genome, saved to ${signif_list})." 

# head ${signif_list}
#
#    ID			CHR	    POS		A1	A1_FREQ		   BETA		SE			P
# rs146155542_T_C	10	7584321		T	0.00106437	3.65261		0.586105	4.67266e-10
# rs182239226_C_T	10	7585610		C	0.00105696	3.73868		0.590452	2.45955e-10
# rs182243134_C_T	10	7587603		C	0.00110519	3.32922		0.570756	5.50556e-09
# rs77411694_C_T	10	7588079		C	0.00110443	3.54626		0.58388		1.26724e-09
# rs188031153_A_G	10	7588195		A	0.00103794	3.45791		0.61136		1.56399e-08
# rs371272412_G_T	10	7590218		G	0.000652296	4.88179		0.741275	4.61123e-11
# rs760326718_G_C	10	12865140	G	0.000815172	3.82626		0.688337	2.74337e-08
# rs34820178_T_C	10	113901194	T	0.244546	0.234147	0.0420012	2.50192e-08
# rs58175211_C_T	10	113901637	C	0.244817	0.232486	0.0419736	3.07253e-08





## +++ gzip the gwas files again:

# Abandoned March 13 
# echo -n "  Zipping the gwas regression output ..."  
# gzip -f ${ident}_gwas_chr*.glm.${suffix}
# echo "  Done."  





## +++ Finish 

rm -f ${sumstat_all_chrom}   		# this file is quite big, and we have ${summary_file} (${ident}_cojo.ma)  now .. 
echo "" 
echo "  Output file: ${summary_file}"   # input for gcta64 
echo ""
echo -n "  "  
date 
echo ""
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"
echo "" 
echo "  Done." 
echo "" 







