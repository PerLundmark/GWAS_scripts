#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  




## === Concatenate results of gcta-cojo pruning   





# called by "cojo_pheno.sh" :
   
# sbatch --dependency=afterok:${liste} -A ${account} -p ${partition}  -t ${ctime}  -J ${c_ident} -o ${sbatch_log} -e ${sbatch_log} \
#        cojo_collect.sh  --id ${ident}  --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --summary ${summary_file} --out ${signif_file}  

# /proj/sens2019016/GWAS_TEST/LIV6 :
# sbatch -A  sens2019016 -p node -t 20:00 -J COLLECT -o test.log -e test.log \
#           cojo_collect.sh --id LIV6  --phenoname ${phenoname} --cstart 1 --cstop 22 --summary LIV6_cojo.ma   --out LIV6_cojo.jma   

# sbatch -A sens2019016 -p node -t 20:00 -J COLLECT -e collect.test -o collect.test cojo_collect  --id  LIV_MULT5 --phenoname liv10 --cstart 1 --cstop 22 --summary LIV_MULT5_liv10__cojo.ma --out LIV_MULT5_liv10__cojo.jma







 
## +++ Hardcoded settings & defaults  

shopt -s nullglob 

# no other parameters necessary 






## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 12 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id  <string>          no default" 
  echo "         -pn|--phenoname <string>   no default"  
  echo "         --cstart <chrom>           no default"
  echo "         --cstop <chrom>           no default"
  echo "         -s|--summary <file>        no default"   # input       
  echo "         -o|--out <file>            no default"   # output 
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
      --cstart)
          cstart=$2
          shift
          ;;
      --cstop)
          cstop=$2
          shift
          ;;
      -s|--summary)
          summary_file=$2 
          shift
          ;;	  	  
      -o|--out)
          signif_file=$2  
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

# ${summary_file} is only needed to find the "other" allele in cojo_allele.R (called below)
# summary_file="${ident}_${phenoname}_cojo.ma"  e.g. LIV_MULT5_liv2_cojo.ma    handed over by calling cojo_pheno.sh
 
# signif_file="${ident}_${phenoname}_cojo.jma (cojo_pheno.sh) 







## +++ Check if the variables are defined  

to_test=(ident  phenoname cstart cstop summary_file signif_file)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (cojo_collect.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done










## +++ Header:     

echo ""
START=$(date +%s) 
echo -n "  "
date 
echo "  Job identifier: " ${ident}
echo "  Phenotype namn: ${phenoname}"
echo "  Chromosomes:  ${cstart} to ${cstop}"
echo "  Infile (summary statistics): ${summary_file}"  
echo "  Outfile (independent markers): ${signif_file}"   
echo "" 

# signif_file="${ident}_${phenoname}_cojo.jma"  # cojo_pheno.sh 







## +++ Concatenate chromosomal cojo results:

chromosomes=$( seq ${cstart} ${cstop} )

orig="${signif_file}.orig"   	#  a merged (over chromosomes) file based on the original gcta-cojo output		 
echo -n > ${orig}		


for chrom in  ${chromosomes[*]}     
do
  out_prefix="${ident}_${phenoname}_cojo_chr${chrom}"	# OBS!! also in cojo_pheno.sh: out_prefix="${ident}_${phenoname}_cojo_chr${chrom}"  
  jma_file="${out_prefix}.jma.cojo"             	# LIV_MULT3_liv3_cojo_chr2.jma.cojo   OBS! also used in cojo_chr.sh  
  if [ -s "${jma_file}" ];then				# no file written if idependent signif. markers missing, i.e. we can run through all chromosomes	
    tail -n +2 ${jma_file} >> ${orig}  			# ${out_prefix}.jma.cojo is for a single chromosome, without header
  fi
done

# head ${orig}
#
# 2	rs532548475	13807712	G	0.000599056	5.44971	0.979876	2.67263e-08	17984.6	0.000661667	5.44971	0.980691	2.74435e-08	0
# 2	rs577713064	46305393	G	0.000906995	4.71597	0.788018	2.16927e-09	18368.2	0.000588517	4.71597	0.788764	2.24604e-09	0
# 2	rs555658286	77127642	A	0.000809429	4.83488	0.882194	4.24083e-08	16422.9	0.000459795	4.83488	0.882974	4.35836e-08	0
# 2	rs559097503	113003928	G	0.000913064	4.57242	0.824385	2.91508e-08	16673.7	0.000643903	4.57242	0.82512		2.9986e-08	0
#
# original header (removed):
# "Chr"   "SNP"            "bp"        "refA"        "freq"         "b"     "se"             "p"           "n"     "freq_geno"     "bC"    "bC_se"         "pC"







## +++ Reformat for final ouput table (fitting to DT command in gwas_report.Rmd)

# in review_gwas: 
#  data frame "sigmarkers" is constructed in review_gwas.R from all glm.linear files :
#      sigmarkers = gwas[which(gwas$P <= p_threshold),]   # signif. markers for this chromosome 
# head(sigmarkers) 

#                ID CHR      POS OTHER  A1  A1_FREQ OBS_CT     BETA        SE           P
# 145408   rs738409  22 44324727     C   G 0.213121  18771 0.828519 0.0564185 1.49139e-48
# 145409   rs738408  22 44324730     C   T 0.213095  18771 0.828438 0.0564293 1.58658e-48
# 145411  rs3747207  22 44324855     C   A 0.211246  18771 0.812102 0.0566134 2.02479e-46
# 145515  rs2294915  22 44340904     C   T 0.228970  18771 0.767400 0.0551465 8.40103e-44
# 145716  rs2294922  22 44379565     A   C 0.206249  18771 0.712838 0.0574396 3.16315e-35
# 145426 rs16991158  22 44327179     T   A 0.154732  18771 0.725923 0.0643496 2.02820e-29  

# signif_file="${ident}_${phenoname}_cojo.jma"  # cojo_pheno.sh 

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "CHR" "POS" "OTHER" "A1" "A1_FREQ" "OBS_CT" "BETA" "SE" "P" > ${signif_file} 
awk 'BEGIN{FS="\t"} {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $2,$1,$3,"-",$4,$5,$9,$11,$12,$13}' ${orig} >> ${signif_file}  # final output 

# we have in ${orig}: 
#  "Chr" "SNP" "bp" "refA" "freq" "b" "se" "p" "n" "freq_geno" "bC" "bC_se" "pC"
#
# "Chr"	 	chromosome; 
# "SNP"  	SNP; 
# "bp"	 	physical position; 
# "freq"	 frequency of the effect allele in the original data; 
# "refA"	the effect allele; 
# "b"		effect size from the original GWAS or meta-analysis; 
# "se"		standard error from the original GWAS or meta-analysis;  
# "p"		p-value from the original GWAS or meta-analysis; 
# "n"		estimated effective sample size; 
# "freq_geno"	frequency of the effect allele in the reference sample; 
# "bC"		effect size from a joint analysis of all the selected SNPs;
# "bC_se"	standard error from a joint analysis of all the selected SNPs;
# "pC"		p-value from a joint analysis of all the selected SNPs; 







## +++ Add the "other" allele (by combining the input file with the output file of cojo)  

# input file format (.ma):    (approx. 14 million rows)  ${summary_file}  
#      created in cojo_convert.sh : ${summary_file}  contains already the correct (by awk) "other" allele   
#
# ID	  	A1	OTHER	A1_FREQ		BETA		SE		       P	OBS_CT
# rs183305313	A	G	0.00490037	-0.29715	0.364161	0.414519	18771
# rs12260013	G	A	0.0271634	0.112443	0.156766	0.473222	18771
# rs61838967	T	C	0.186952	-0.0448559	0.0647333	0.488359	18771
# rs61839042	C	T	0.361963	0.0200542	0.0509056	0.693623	18771

# signif file format (created above, ${signif_file} ):   37 lines (just the independent markers) 

#                ID CHR      POS OTHER  A1  A1_FREQ OBS_CT     BETA        SE           P
# 145408   rs738409  22 44324727     -   G 0.213121  18771 0.828519 0.0564185 1.49139e-48
# 145409   rs738408  22 44324730     -   T 0.213095  18771 0.828438 0.0564293 1.58658e-48
# 145411  rs3747207  22 44324855     -   A 0.211246  18771 0.812102 0.0566134 2.02479e-46
# 145515  rs2294915  22 44340904     -   T 0.228970  18771 0.767400 0.0551465 8.40103e-44
# 145716  rs2294922  22 44379565     -   C 0.206249  18771 0.712838 0.0574396 3.16315e-35
# 145426 rs16991158  22 44327179     -   A 0.154732  18771 0.725923 0.0643496 2.02820e-
#
#  OTHER is still missing: that's what cojo_allele.R is going to fix: 


signif_fixed="${signif_file}.fixed"   	# output of "cojo_allele.R" 

module load R_packages/3.6.1  		# need data.table 
 
cojo_allele   ${summary_file}   ${signif_file}  ${signif_fixed} 
 
#                  input            input           output

# summary_file="${ident}_${phenoname}_cojo.ma"  (cojo_pheno.sh) 
# signif_file="${ident}_${phenoname}_cojo.jma (cojo_pheno.sh) 
# cojo_allele  LIV_MULT5_liv10_cojo.ma  LIV_MULT5_liv10_ojo.jma  LIV_MULT5_liv10_ojo.jma.fixed

# replace ${signif_file} by ${signif_fixed} (after some checks):

if [ -s "${signif_fixed}" ];then  # file exists and is not empty
  nr1=$( wc -l ${signif_file}  | awk '{print $1}' )
  nr2=$( wc -l ${signif_fixed} | awk '{print $1}' )   
  if [ "$nr1" -ne "$nr2" ];then
    echo ""
    echo  "  ERROR (cojo_collect.sh): File \"${signif_file}\" could not be fixed by \"cojo_allele.R\" (unequal nr of rows)." 
    echo ""
    exit 1
  else      
    mv -f ${signif_fixed} ${signif_file}   # overwrite!
  fi 
else 
  echo ""
  echo  "  ERROR (cojo_collect.sh): File \"${signif_file}\" could not be fixed by \"cojo_allele\"." 
  echo ""
  exit 1   
fi







## +++ Finish  

rm -f ${orig}
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"
echo "" 
echo "  Table of independent markers: ${signif_file}" 
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 
 
















