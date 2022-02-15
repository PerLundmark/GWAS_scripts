#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Convert from .pgen to .bed   




## +++ Call:
#







## +++ Hardcoded settings & and defaults 

setfile=~/convert_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (convert_genotype.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi

# ~/convert_settings.sh :
#
# plink2_version="plink2/2.00-alpha-2-20190429"   	# search for other versions using " module spider plink2 " 
# partition="node"   					# partition , "core"  might run out of memory  
# minspace=10000000   					# 10 MB  minimum required disk space for regression output 
# minutes=180						# required runtime for each chromosome in minutes
# chrom="1-22"						# all autosomes (entering a single chromosome is ok, X,Y not working)
# infolder="/proj/sens2019016/GENOTYPES/PGEN"   	# location of input genotype files
# outfolder="/proj/sens2019016/GENOTYPES/BED"   	# location of output genotype files


 


 
## +++ Command line parameters (override the settings in $setfile):

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -g|--genoid <string>           no default"
  echo "         -c|--chr <int>[-<int>]         ${setfile}"  
  echo "         -m|--minutes <int>             ${setfile}"
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
      -g|--genoid)
          genoid=$2    
          shift
          ;;
      -c|--chr)
          chrom=$2
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

to_test=(genoid chrom minutes partition minspace plink2_version infolder outfolder)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (convert_genotype.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done






## +++ Chromosomes  

# chromosomes=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # all chromosomes
      
cstart=$( echo $chrom | cut -d'-' -f 1 )
cstop=$( echo $chrom | cut -d'-' -f 2 )

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (convert_genotype.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			        Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (convert_genotype.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			        Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )








 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
log="${outfolder}/${genoid}_pgen2bed_convert.log"   # master logfile 
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Running on chromosomes $cstart to $cstop" | tee -a ${log} 
echo "  Genotype identifier: " ${genoid} | tee -a ${log} 
echo "  Genotype input folder: ${infolder}"  | tee -a ${log}
echo "  Genotype output folder: ${outfolder}"  | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "" | tee -a ${log}











## +++ Check availability of input files and genotype files:

## infolder

if [ ! -d ${infolder} ]; then
  echo "" | tee -a ${log}
  echo "  ERROR (convert_genotype.sh): Input folder '${infolder}' does not exist." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
fi 


for chrom in  ${chromosomes[*]}     
do

  pgen_prefix="${infolder}/${genoid}_chr$chrom"     

  psam=${pgen_prefix}".psam"	
  pvar=${pgen_prefix}".pvar"	 
  pgen=${pgen_prefix}".pgen" 	   

  if [ ! -f ${psam} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (convert_genotype.sh): Input file '${psam}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pvar} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (convert_genotype.sh): Input file '${pvar}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pgen} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (convert_genotype.sh): Input file '${pgen}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi    

done   

echo "  All required genotype files (.pgen, .pvar, .psam) are available."  | tee -a ${log}



## outfolder:  

if [ ! -d ${outfolder} ]; then
  echo "" | tee -a ${log}
  echo "  ERROR (convert_genotype.sh): Target folder '${outfolder}' does not exist." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
fi 








## +++ Check available disk space:

echo ""
echo "  Target folder: ${outfolder}" | tee -a ${log}
space=$( df -k ${outfolder} | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h ${outfolder} | tail -1 | awk '{print $4}' )  # human readable  21T 
echo "  Available disk space in this path: ${spac1}" | tee -a ${log}
echo "" | tee -a ${log}
if [ ${space} -lt ${minspace} ]; then   
    echo "" | tee -a ${log}
    echo "  Less than ${minspace} free disk space in the target folder, consider using a different location." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
fi 








## +++ Convert the time string for sbatch command below:

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"    # time for a single chromosome to run
fi  
# echo "  Requested runtime for each chromosome: ${time}"     
# echo "" 








## +++ Run through chromosomes 

for chrom in  ${chromosomes[*]} 
do
     
  logchr="${outfolder}/${genoid}_pgen2bed_convert_chrom${chrom}.log"   
  c_ident="GCONV-${chrom}"  				   # unique jobID for each batch job
  pgen_prefix="${infolder}/${genoid}_chr$chrom"   	   # OBS! must be same as above  

  echo " sbatch -A ${account}  -p ${partition}  -t ${time}  -J ${c_ident} -o ${logchr} -e ${logchr} \ " | tee -a ${log}
  echo "         convert_genotype_chr  --genoid ${genoid}   --chr ${chrom}"  | tee -a ${log}

  jobid=$( sbatch -A ${account}  -p ${partition}  -t ${time}  -J ${c_ident} -o ${logchr} -e ${logchr} \
       convert_genotype_chr  --genoid ${genoid}   --chr ${chrom} )
	
  jobid=$( echo $jobid | awk '{print $NF}' ) 
  echo "         JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo "" | tee -a ${log}	  
   
done  







## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
# echo "  Run time: $DIFF seconds"| tee -a ${log}  # the main script just submits jobs, takes only a few seconds
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 





