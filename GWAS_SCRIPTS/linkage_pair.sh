#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 




## === Calculate linkage for a pair of markers 




# Interactive:
#
#   linkage_pair --snp1 rs58542926_T_C --snp2 rs188247550_T_C  --chr 19 

    
# no SLURM, run in interactive mode only!




 

## +++ Hardcoded settings & and defaults 

setfile=~/linkage_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}   
else
  echo ""
  echo "  ERROR (linkage_pair.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi

 
 
 
 
 
 
 
## +++ Programs 
 
progs_to_test=( extract_genotype )

for p in  ${progs_to_test[*]}     
do
  prog=$( which ${p} )   
  exit_code=$?  
  if [ ${exit_code} -ne 0 ]
  then
    echo "" 
    echo "  ERROR (linkage_pair.sh): Did not find the program ' ${p} '." 
    echo ""
    exit 1
  fi      
done
 






## +++ Command line parameters:   

if [ "$#" -lt 6 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        --snp1 <string>              no default"
  echo "        --snp2 <string>              no default"  
  echo "        -c|--chr <int>               no default"
  echo "        -g|--genoid <string>         ${setfile}" 
  echo ""
  exit 1
fi



while [ "$#" -gt 0 ]
do
  case $1 in
	--snp1)
          snp1=$2
          shift
          ;;
	--snp2)
          snp2=$2
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

to_test=(snp1 snp2 chrom genofolder genoid)  

for var in  ${to_test[*]}     
do
  if [[ -z ${!var+x} ]];then
    echo ""
    echo "  ERROR (linkage_pair.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done






## +++ Chromosome  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (linkage_pair.sh): Chromosome identifier is not valid:  ${chrom}" 
  echo  "  			    Correct syntax is e.g. --chrom 16"
  echo ""
  exit 1 
fi   





 
## +++ Header:

log="linkage_${snp1}_${snp2}.log"    
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo "  Logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log} 
echo "  SNP1: ${snp1}" | tee -a ${log}
echo "  SNP2: ${snp2}" | tee -a ${log}
echo "  Chromosome: $chrom" | tee -a ${log} 
echo "  Genotype folder: ${genofolder}" | tee -a ${log} 
echo "  Reference genome identifier: ${genoid}"  | tee -a ${log}
echo ""   | tee -a ${log}








## +++ Check availability of genotype files:
  
pgen_prefix="${genofolder}/${genoid}_chr$chrom"   

psam=${pgen_prefix}".psam"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.psam 
pvar=${pgen_prefix}".pvar"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pvar	
pgen=${pgen_prefix}".pgen"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pgen	  

if [ ! -f ${psam} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (linkage_pair.sh): Input file '${psam}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pvar} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (linkage_pair.sh): Input file '${pvar}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pgen} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (linkage_pair.sh): Input file '${pgen}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi	 


nr_samples=$( wc -l $psam | awk '{print $1}' )
nr_samples=$(( ${nr_samples} - 1 ))

nr_snps=$( wc -l $pvar | awk '{print $1}' )
nr_snps=$(( ${nr_snps} - 1 ))

echo "  The genotype files for chromosome ${chrom} (.pgen, .pvar, .psam) are available."   | tee -a ${log} 
echo "  Number of samples: ${nr_samples} ; number of variants: ${nr_snps}" | tee -a ${log} 
echo ""  | tee -a ${log} 






## +++ Download genotype data for the marker under consideration:


# + SNP1: 

echo "  Extracting genotype information for marker ${snp1} :" | tee -a ${log} 

getgeno_log="linkage_extract_${snp1}.log"   

echo "    extract_genotype  --snp ${snp1} --chr ${chrom} --genoid  ${genoid}" | tee -a ${log} 

extract_genotype  --snp ${snp1} --chr ${chrom} --genoid  ${genoid} &> ${getgeno_log}   

out_prefix="genotype_${snp1}"   	
rawfile1="${out_prefix}.raw"		

if [ ! -s "$rawfile1" ];then
  echo ""
  echo "  ERROR (linkage_pair.sh): Missing file ${rawfile1}. Extraction of genotype not succesful."
  echo ""
  exit 1
else
  echo "    Genotype for marker ${snp1} succesfully extracted ==> ${rawfile1}."
fi 
echo ""



# + SNP2:  

echo "  Extracting genotype information for marker ${snp2} :" | tee -a ${log} 

getgeno_log="linkage_extract_${snp2}.log"   

echo "    extract_genotype  --snp ${snp2} --chr ${chrom} --genoid  ${genoid}" | tee -a ${log} 

extract_genotype  --snp ${snp2} --chr ${chrom} --genoid  ${genoid} &> ${getgeno_log}   

out_prefix="genotype_${snp2}"   	
rawfile2="${out_prefix}.raw"		

if [ ! -s "$rawfile2" ];then
  echo "  ERROR (linkage_pair.sh): Missing file ${rawfile2}. Extraction of genotype not succesful."
  echo ""
  exit 1
else
  echo "    Genotype for marker ${snp2} succesfully extracted ==> ${rawfile2}."
fi 
echo ""







## +++ Conduct linkage analysis (in R script):

rlog="linkage_R_${snp1}_${snp2}.log"

echo "  Calling linkage_pair.R with the following positional parameters:" | tee -a ${log}
echo "" | tee -a ${log}
echo "  linkage_pair.R  ${rawfile1}  ${rawfile2} ${genoid}"  | tee -a ${log} 
echo "" | tee -a ${log}
echo "  Logfile for linkage_pair.R: ${rlog}"  | tee -a ${log} 

module load R_packages/3.6.1

linkage_pair.R  ${rawfile1} ${rawfile2} ${genoid}    

echo ""





## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 












    

