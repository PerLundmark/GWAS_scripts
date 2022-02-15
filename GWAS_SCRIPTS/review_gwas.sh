#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


## === Call review_gwas.R  ====




## +++ Calling:    

# in the folder containing the gwas results, e.g. /proj/sens2019016/GWAS_TEST/IV_MULT4   
#
# review_gwas --id LIV_MULT4 --phenoname liv10
#
# input: cojoed data or clumped data or just gwas data that haven't been pruned






## +++ Hardcoded settings & and defaults 

setfile=~/review_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings (but not all can be overwritten) 
else
  echo ""
  echo "  ERROR (review_gwas.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi







 
## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 4 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -pn|--phenoname <string>       no default"
  echo "         -c|--chr <int>[-<int>]         ${setfile}"
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
      -pn|--phenoname)
          phenoname=$2
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






## +++ Check if phenoname is a single word (no comma-separated list here!, just ONE phenoname)  

nr=$( echo $phenoname | awk 'BEGIN{FS=","}{print NF}' )
if [ "${nr}" -ne 1 ]; then
  echo ""
  echo "  ERROR (review_gwas.sh): Phenotype name must be a single word, multiple phenotypes not allowed in \"review_gwas\"."
  echo ""
  exit 1
fi







## +++ Check if the variables are defined  

to_test=(ident phenoname chrom  minutes minspace)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (review_gwas.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done










## +++ Check for correct folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (review_gwas.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi







## +++ Check if $phenoname is valid (user input)

paramfile="${ident}_gwas_params.txt"

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (review_gwas.sh): Missing parameter file \"${paramfile}\""
  echo ""
  exit 1
fi

# possible entries in ${paramfile}:
#     phenoname liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10      # LIV_MULT    
#     phenoname vox1_exp   						# VOX1

pstring=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} )   	#  liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10  
pname=$( echo $pstring | tr -s ',' '\t' )  			   	#  liv1 liv2 liv3 liv4 liv5 liv6 liv7 liv8 liv9 liv10
parray=($pname)
# echo " Number of elements in parray: ${#parray[*]}"   	   	#  10 ok  
nr_hits=$( printf '%s\n' ${parray[@]} | egrep "^[[:space:]]*${phenoname}[[:space:]]*$" | wc -l )  # should exactly be 1
if [ "${nr_hits}" -ne 1 ];then
  echo ""
  echo "  ERROR (run_cojo.sh): You propably picked a wrong phenotype name."
  echo "  The word \"${phenoname}\" is not included as a phenoname entry in \"${paramfile}\""
  echo ""
  exit 1
fi







## +++ Chromosomes  
      
cstart=$( echo $chrom | cut -d'-' -f 1 )
cstop=$( echo $chrom | cut -d'-' -f 2 )    # entering a single chromosome is possible 

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (review_gwas.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (review_gwas.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )








## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
if [ ${space} -lt ${minspace} ]; then   
    echo "" 
    echo "  Less than ${minspace} disk space available, consider using a different location." 
    echo "" 
    exit 1 
fi 







## +++ Convert the time string for sbatch command below:

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"  # requested runtime for a single chromosome
fi  







## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 	
batchlog="${ident}_${phenoname}_review.log"   	

START=$(date +%s) 
echo ""    
echo -n "  "  
date 
echo "  Account: ${account}" 
echo -n "  Current working folder: "  
pwd  
echo "  Available disk space in this path: ${spac1}"  
echo "  Job identifier:  ${ident}" 
echo "  Running on chromosomes ${cstart} to ${cstop}" 
echo "" 
echo "  Requested partition: ${partition}" 
echo "  Requested runtime: ${minutes} minutes." 
echo "  Requested runtime: ${time}" 
echo "  sbatch logfile: ${batchlog}"
echo "" 







## +++ Send the R-script  to the sbatch   

echo "  sbatch -A ${account} -p ${partition}  -t ${time}  -J \"${ident}_REV\" -o ${batchlog} -e ${batchlog}  \ "
echo " 	--wrap=\"module load R_packages/3.6.1; review_gwas.R ${ident} ${phenoname}  ${cstart} ${cstop}\" "
                                           
jobID=$( sbatch -A ${account} -p ${partition}  -t ${time}  -J "${ident}_REV" -o ${batchlog} -e ${batchlog}  \
       --wrap="module load R_packages/3.6.1; review_gwas.R ${ident} ${phenoname} ${cstart} ${cstop}" )

jobID=$( echo $jobID | awk '{print $NF}' )

echo ""
echo "  JobID for phenotype ${phenoname} : ${jobID}"                                            






## +++ Finish  

# END=$(date +%s)
# DIFF=$(( $END - $START ))
# echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 


