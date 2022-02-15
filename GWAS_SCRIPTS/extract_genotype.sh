#!/usr/bin/env bash  





# uwe.menzel@medsci.uu.se  



   
   
## === Regression diagnostics after GWAS
#       this script extracts the genotype data for a single marker from .pgen using plink2 





# Mail  Christopher Chang:
#
# When your phenotype really is heavily driven by a single SNP, you can use "--snp <SNP ID> --export A" or "--snp <SNP ID> --export A-transpose" 
# to export the genotype values for just that SNP to a table that can be easily loaded in R/Python/etc.


  



# Call:
#
# called by gwas_diagnose.sh   
#
# account="sens2019016"
# partition="node"
# time=10
# c_ident="TEST"
# getgeno_log="test.log"
# marker="rs767276217_A_G"
# chrom=5
# genoid="ukb_imp_v3"
#
# sbatch  -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${getgeno_log} -e ${getgeno_log}  \
#         extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes}
#
#  ~/bin/extract_genotype --snp rs767276217_A_G  --chr 5







## +++ Hardcoded settings & and defaults 

setfile=~/linkage_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (extract_genotypes.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi








## +++ Command line parameters:   

if [ "$#" -lt 4 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        --snp <string>               no default"
  echo "        -c|--chr <int>               no default"  
  echo "        -g|--genoid <string>         ${setfile}"    
  echo "        -m|--minutes <int>           ${setfile}"
  echo ""
  exit 1
fi


while [ "$#" -gt 0 ]
do
  case $1 in
       --snp)
          marker=$2
          shift
          ;;
       -c|--chr)
          chrom=$2
          shift
          ;;
      -g|--genoid)
          genoid=$2    
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








## +++ Check if the variables are defined (including those defined in the settings file)    

to_test=(marker chrom genoid minutes partition plink2_version genofolder)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (extract_genotypes.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done


# marker="rs767276217_A_G"
# chrom=5
# genofolder="/proj/sens2019016/GENOTYPES/PGEN"
# genoid="ukb_imp_v3"






## +++ Chromosome  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then			# autosomes only!  
  echo ""
  echo  "  ERROR (extract_genotypes.sh): Chromosome identifier is not valid:  ${chrom}" 
  echo  "  			        Correct syntax is e.g. --chrom 16"
  echo ""
  exit 1 
fi   






 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
START=$(date +%s)      
echo -n "  "  
date 
echo "  Account: ${account}" 
echo -n "  Operated by: " 
whoami  
echo "  Logfile: ${log}" 
echo "" 
echo "  Marker: ${marker}" 
echo "  Chromosome $chrom"   
echo "  Genotype input folder: ${genofolder}"  
echo "  Genotype identifier: " ${genoid} 
echo "" 
echo "  Requested partition: ${partition}" 
echo "  Requested runtime: ${minutes} minutes." 
echo "" 









## +++ Check availability of input files and genotype files:


# check .pgen .pvar .psam for the chromosome chosen
  
pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5

psam=${pgen_prefix}".psam"  
pvar=${pgen_prefix}".pvar"	
pgen=${pgen_prefix}".pgen"	  

if [ ! -f ${psam} ]; then
  echo "" 
  echo "  ERROR (extract_genotypes.sh): Input file '${psam}' not found." 
  echo "" 
  exit 1 
fi  

if [ ! -f ${pvar} ]; then
  echo "" 
  echo "  ERROR (extract_genotypes.sh): Input file '${pvar}' not found." 
  echo "" 
  exit 1 
fi  

if [ ! -f ${pgen} ]; then
  echo "" 
  echo "  ERROR (extract_genotypes.sh): Input file '${pgen}' not found." 
  echo "" 
  exit 1 
fi	 

echo "  The genotype files for chromossome ${chrom} (.pgen, .pvar, .psam) are available."  
echo "" 


# check if the marker is included in the corresponding .pvar file

nr_hits=$( grep "\b${marker}\b" ${pvar} | wc -l )        
if [ "${nr_hits}" -ne 1 ];then
  echo "" 
  echo "  PROBELM (extract_genotypes.sh): The marker '${marker}' occurs ${nr_hits} times in ${pvar}." 
  echo "" 
  exit 1 
fi

 

 



## +++ Modules: 

answ=$( module list  2>&1 | grep plink2 )   
if [ -z "$answ" ];then
  echo "  Loadung modules ..."  
  module load bioinfo-tools
  module load ${plink2_version}
  prog=$( which plink2 ) 
  echo "  Using: $prog"     
fi
echo ""









## +++ Extract the genotype for the marker   

out_prefix="genotype_${marker}" 

plink2 --pfile ${pgen_prefix} --snp ${marker} --export A  --out ${out_prefix}

rawfile="${out_prefix}.raw"
logfile="${out_prefix}.log"



echo ""
rm -f ${logfile}  # we have the batch log and the master logfile already 
ls -l ${rawfile} 
echo ""



# head $rawfile
# FID		IID	PAT	MAT	SEX	PHENOTYPE	rs767276217_A_G_A
# 5954653	5954653	0	0	1	-9		0
# 1737609	1737609	0	0	2	-9		0
# 1427013	1427013	0	0	2	-9		0
# 3443403	3443403	0	0	2	-9		0
# 5807741	5807741	0	0	2	-9		0
# 4188953	4188953	0	0	1	-9		0
# 1821438	1821438	0	0	2	-9		0
# 3951387	3951387	0	0	2	-9		0
# 5670866	5670866	0	0	1	-9		0

# How is the genotype coded ? 

# https://www.cog-genomics.org/plink/2.0/data#export 
# 
# --export creates a new fileset, after sample/variant filters have been applied. The following output formats are currently supported:
# 
#     A: Sample-major additive (0/1/2) coding, suitable for loading from R. Dosages are now supported. 
#     Haploid genotypes are coded on a 0-2 scale. 
#     If you need uncounted alleles to be named in the header line, add the 'include-alt' modifier.
# 
# 
# https://www.cog-genomics.org/plink/2.0/formats :
# A1	(required)	Counted allele in regression
# 
# .raw (additive + dominant component file)
# 
# Produced by "--export {A,AD}"; suitable for loading from R. This format cannot be loaded by PLINK.
# 
# A text file with a header line, and then one line per sample with V+6 (for "--export A") or 2V+6 (for "--export AD") fields, 
# where V is the number of variants. The header line does not contain a preceding '#'. The first six fields are:
# 
# FID	Family ID
# IID	Individual ID
# PAT	Paternal individual ID
# MAT	Maternal individual ID
# SEX	Sex (1 = male, 2 = female, 0 = unknown)
# PHENOTYPE	First active non-categorical phenotype (missing value if none)
# 
# This is followed by one or two fields per variant:
# <Variant ID>_<counted allele>	Allelic dosage (missing = 'NA', haploid scaled to 0..2)
# <Variant ID>_HET	Dominant component (1 = het). Requires "--export AD".


rand=$(( 1 + RANDOM%10000 ))
tmpfile="temp.${rand}"    	# temp.9401
awk 'BEGIN{FS="\t"} {printf "%s\t%s\n", $2, $NF}' $rawfile > ${tmpfile} 
mv ${tmpfile} ${rawfile} 

# head $rawfile
# IID	rs767276217_A_G_A
# 5954653	0
# 1737609	0
# 1427013	0
# 3443403	0
# 5807741	0

# we see here that the counted allele is A ( "A" is appended to "rs767276217_A_G" ) 
# check if this is the A1 allele?: use plink summary file (main script) 

counted=$( head -1 $rawfile | awk '{print $2}' ) #  rs767276217_A_G_A  
cl=$( echo $counted | sed 's/_/ /g' )		 #  rs767276217 A G A
cl=($cl)
counted_allele=${cl[${#cl[@]}-1]}
echo "  The counted allele is: ${counted_allele}" 
echo "" 







## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 
 
 





# uwe.menzel@medsci.uu.se
