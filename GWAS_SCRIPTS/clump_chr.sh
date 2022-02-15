#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


 



## === LD-pruning using clumping in plink1.9 , for a single chromosome:
   
# https://www.cog-genomics.org/plink/1.9/postproc   
# http://zzz.bwh.harvard.edu/plink/clump.shtml






## +++ Calling:  

## called by clump_pheno.sh:   
#
#  sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${clump_log} -e ${clump_log}  \
#          clump_chr  --id ${ident} --chr ${chrom} --phenoname ${phenoname} --genoid ${genoid} \
#                     --p1 ${clump_p1} --p2 ${clump_p2} --r2 ${clump_r2} --kb ${clump_kb}    
#
# Standalone (minimum):
# 
# clump_chr  --id ${ident} --chr ${chrom} --phenoname ${phenoname} --genoid ${genoid}
# clump_chr  --id liver18 --chr 22 --phenoname liver_fat_a_res_norm --genoid FTD_rand  # ok /proj/sens2019016/nobackup/GWAS_TEST/liver18



## +++ Hardcoded settings & and defaults 

shopt -s nullglob  # see Douglas' mail Feb24  

setfile=~/clump_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (clump_chr.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi






## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 8 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -c|--chr <int>                 no default" 
  echo "         -pn|--phenoname <string>       no default" 
  echo "         -g|--genoid <string>           no default"
  echo "         -p1|--p1 <real>                ${setfile}"
  echo "         -p2|--p2 <real>                ${setfile}"
  echo "         -r2|--r2 <real>                ${setfile}"     
  echo "         -kb|--kb <integer>             ${setfile}"   
  echo "         -m|--minutes <int>             ${setfile}"
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
      -c|--chr)
          chrom=$2
          shift
          ;;
       -pn|--phenoname)
          phenoname=$2
          shift
          ;;	  	  
      -g|--genoid)
          genoid=$2    
          shift
          ;;	  
      -p1|--p1)
          clump_p1=$2
          shift
          ;;
      -p2|--p2)
          clump_p2=$2
          shift
          ;;	  
      -r2|--r2)
          clump_r2=$2
          shift
          ;;	  
      -kb|--kb)
          clump_kb=$2
          shift
          ;;	  	  	  
      -m|--minutes)
          minutes=$2
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

to_test=(ident chrom phenoname genoid clump_p1 clump_p2 clump_r2 clump_kb partition minutes)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (clump_chr.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done








## +++ Files

geno_prefix="${genofolder}/${genoid}_chr${chrom}"   		
out_prefix="${ident}_${phenoname}_chrom${chrom}"     		

# regression output files, linear or logistic regression:

out_glm_lin="${ident}_gwas_chr${chrom}.${phenoname}.glm.linear" 
out_glm_log="${ident}_gwas_chr${chrom}.${phenoname}.glm.logistic" 

files_found=0

if [ -s "${out_glm_lin}" ];then 
  echo "  Linear regression output file found for chromosome ${chrom}."
  echo ""
  out_glm=${out_glm_lin}
  files_found=$(( ${files_found} + 1 ))
  suffix="linear"
fi

if [ -s "${out_glm_log}" ];then 
  echo "  Logistic regression output file found for chromosome ${chrom}."
  echo ""
  out_glm=${out_glm_log}
  files_found=$(( ${files_found} + 1 ))
  suffix="logistic"
fi

if [ "${files_found}" -eq 0 ];then
  echo ""
  echo "  ERROR (clump_chr.sh): No regression output file found for chromosome ${chrom}."
  echo ""
  exit 1
fi

if [ "${files_found}" -eq 2 ];then
  echo "  ERROR (clump_chr.sh): Both linear and logistic regression output files found for chromosome ${chrom}."
  echo "                        Please check your results."  
  echo ""
  exit 1
fi






## +++ Check availability of input files and folders

if [ ! -s "${out_glm}" ];then
  echo ""
  echo  "  ERROR (clump_chr.sh): Could not find file \"${out_glm}\"" 
  echo ""
  exit 1  
fi

if [ ! -d "${genofolder}" ];then
  echo ""
  echo  "  ERROR (clump_chr.sh): Could not find folder \"${genofolder}\"" 
  echo ""
  exit 1  
fi








## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (clump_chr.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi






## +++ Check chromosome name  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then    # autosomes only!!         
  echo ""
  echo  "  ERROR (clump_chr.sh): Chromosome name is not valid: " ${chrom} 
  echo  "  			 Correct syntax is e.g. --chr 22"
  echo ""
  exit 1 
fi   





## +++ Header:

echo ""
START=$(date +%s) 
echo -n "  "
date 
echo "  Job identifier: " ${ident}
echo "  Genotype input folder: ${genofolder}"  
echo "  Genotype identifier: ${genoid}"

echo "  Starting job for chromosome ${chrom}"
echo "  p-value 1: $clump_p1 (significance threshold for index markers)"
echo "  p-value 2: $clump_p2 (secondary significance threshold for clumped markers)"
echo "  r2: $clump_r2 (LD threshold)"
echo "  Window: $clump_kb (physical distance threshold in Kb)"
echo "" 






## +++ Modules: 

answ=$( module list  2>&1 | grep plink )   
if [ -z "$answ" ];then
  echo "  Loadung modules ..."  | tee -a ${log}
  module load bioinfo-tools
  module load ${plink_version}
  prog=$( which plink ) 
  echo "  Using: $prog"  | tee -a ${log} 
  echo | tee -a ${log}  
fi









## +++ Clump the chromosome:



# plink -help
# 
#   --clump-p1 [pval] : Set --clump index var. p-value ceiling (default 1e-4).
#   --clump-p2 [pval] : Set --clump secondary p-value threshold (default 0.01).
#   --clump-r2 [r^2]  : Set --clump r^2 threshold (default 0.5).
#   --clump-kb [kbs]  : Set --clump kb radius (default 250).
#   --clump-snp-field [n...]  : Set --clump variant ID field name (default
#                               'SNP').  With multiple field names, earlier names
#                               take precedence over later ones.
#   --clump-field [name...]   : Set --clump p-value field name (default 'P').
#   --clump-allow-overlap     : Let --clump non-index vars. join multiple clumps.
#   --clump-verbose           : Request extended --clump report.
#   --clump-annotate [hdr...] : Include named extra fields in --clump-verbose and
#                               --clump-best reports.  (Field names can be
#                               separated with spaces or commas.)
#   --clump-range [filename]  : Report overlaps between clumps and regions.
#   --clump-range-border [kb] : Stretch regions in --clump-range file.
#   --clump-index-first       : Extract --clump index vars. from only first file.
#   --clump-replicate         : Exclude clumps which contain secondary results
#                               from only one file.
#   --clump-best              : Report best proxy for each --clump index var.  --> ${out_prefix}.clumped.best


echo "  plink --bfile ${geno_prefix} --clump ${out_glm} --clump-snp-field ID  --clump-p1 ${clump_p1} --clump-p2 ${clump_p2} \ "
echo "        --clump-r2 ${clump_r2}  --clump-kb ${clump_kb} --out ${out_prefix}"
echo ""

      plink --bfile ${geno_prefix} --clump ${out_glm} --clump-snp-field ID  --clump-p1 ${clump_p1} \
             --clump-p2 ${clump_p2} --clump-r2 ${clump_r2}  --clump-kb ${clump_kb} --out ${out_prefix}    

# output: ${out_prefix}.clumped  

# If no markers found: 
# Warning: No significant --clump results.  Skipping.
# ${out_prefix}.clumped does not exist in that case.

if [ -s "${out_prefix}.clumped" ]; then 
  # OBS!! ${out_prefix}.clumped might contain blank lines, making the files appear bigger than they are when using wc -l !
  rnum=$(( 1 + RANDOM%10000 ))   # avoid interference with jobs running in parallel
  grep -v '^$' ${out_prefix}.clumped > ${out_prefix}_${rnum}.temp
  mv ${out_prefix}_${rnum}.temp ${out_prefix}.clumped
else
  rm -f ${infile1} ${infile2} ${out_prefix}.log
  echo ""
  echo "  No significant markers on this chromosome."
  echo ""
  echo "" 
  echo -n "  "  
  date 
  echo "" 
  exit 0  
fi






## +++ Reformat clump output  (like *.jma in cojo) 

infile1="${ident}_${phenoname}_chrom${chrom}_inf1.txt"  # temporary
infile2="${ident}_${phenoname}_chrom${chrom}_inf2.txt"  # temporary

awk '{printf "%s\t%s\t%s\t%s\n", $3, $1, $4, $5}' ${out_prefix}.clumped > ${infile1} 

awk 'BEGIN{FS="\t"} {if($6 == $5) {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $3, $6, $4, $7, $9, $10, $8} \
                             else {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $3, $6, $5, $7, $9, $10, $8}}' ${out_glm} > ${infile2} 
			     
clump_chr_results="${ident}_${phenoname}_chrom${chrom}_results.clumped"
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "CHR" "POS" "OTHER" "A1" "A1_FREQ" "OBS_CT" "BETA" "SE" "P"  > ${clump_chr_results} 


LANG=en_EN sort -k1 ${infile1} > ${infile1}.temp
LANG=en_EN sort -k1 ${infile2} > ${infile2}.temp

LANG=en_EN join -j 1 -t $'\t' -o 1.1,1.2,1.3,2.3,2.2,2.4,2.7,2.5,2.6,1.4 ${infile1}.temp ${infile2}.temp >> ${clump_chr_results}

rm -f ${infile1}.temp ${infile2}.temp





## Issue: 
#
# logfile:
#
# join: /dev/fd/62:7682: is not sorted: 22:48181289_TCTCC_T	TCTCC	T	0.342803	-0.0867907	0.0490265	18771
# 
# 22:48181289_TCTCCTC_T	TCTCCTC	T	0.347567	-0.0828744	0.0491265	18771
# 22:48181289_TCTCC_T	TCTCC	T	0.342803	-0.0867907	0.0490265	18771
#
# join seems to expect another sorting mode of these two entries: underscore first?  sort -V gives 2 such error messages   







## +++ Finish 

rm -f ${infile1} ${infile2}  ${out_prefix}.clumped  ${out_prefix}.log

echo ""
echo "  File with independent markers: ${clump_chr_results}"
echo ""
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds" 
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 















