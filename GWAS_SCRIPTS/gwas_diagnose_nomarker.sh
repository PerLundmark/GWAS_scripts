#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Regression diagnostics after GWAS, main script 
#         
#      WITHOUT marker, just the phenotype vs. the covariates





## +++ Call: 
# 
# this script calls:
# gwas_diagnose_nomarker.R   liver_fat_ext.txt  liver_fat_a  GWAS_covariates.txt  PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age
#
# /castor/project/proj/GWAS_DEV3/liver10
#
# gwas_diagnose_nomarker  --pname liver_fat_a
# gwas_diagnose_nomarker  --pheno liver_fat_ext.txt  --pname liver_fat_a
#
# Interactive session:
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 3:00:00 -A sens2019016 
#   module load R_packages/3.6.1
#   . s2
#   which gwas_diagnose_nomarker
#   cd /castor/project/proj/GWAS_DEV3/liver10
#   gwas_diagnose_nomarker --pheno liver_fat_ext.txt --pname  liver_fat_a --inter 


# --pname = phenotype name. Must be a column of the file invoked by --pheno 






## +++ Hardcoded settings & and defaults 

setfile=~/diagnose_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (gwas_diagnose_nomarker.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi


# # phenofolder="/proj/sens2019016/PHENOTYPES"				# location of input phenotype and covariate files
# phenofolder="."		      
# partition="node"   							# partition , "core"  might run out of memory   







## +++ Files 

ident=$(basename $(pwd)) 		   # LIV_MULT5  This script must be started in the folder where the GWAS was run! 
paramfile="${ident}_gwas_params.txt" 	   # LIV_MULT5_gwas_params.txt   OBS!! Name convention from run_gwas 




 
## +++ Programs 
 
# progs_to_test=( extract_genotype )
# 
# for p in  ${progs_to_test[*]}     
# do
#   prog=$( which ${p} )   
#   exit_code=$?  
#   if [ ${exit_code} -ne 0 ]
#   then
#     echo "" 
#     echo "  ERROR (gwas_diagnose_nomarker.sh): Did not find the program ' ${p} '." 
#     echo ""
#     exit 1
#   fi      
# done
 



 
 



## +++ Command line parameters:   

if [ "$#" -lt 2 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        -pn|--pname <string>         no default"  
  echo "        -p|--pheno <file>            ${paramfile}"   
  echo "        -co|--covar <file>           ${paramfile}" 
  echo "        -cn|--cname <string>         ${paramfile}"
  echo "        -rm|--rminutes <int>         ${setfile}" 
  echo "        --inter                      interactive mode"     
  echo ""
  exit 1
fi


# --rminutes : requested runtime for subroutine "gwas_diagnose_nomarker.R" 



inter=0   # default: run in SLURM, can only be overwritten on command line


while [ "$#" -gt 0 ]
do
  case $1 in
	-pn|--pname)
           phenoname=$2
           shift
           ;;
	-p|--pheno)
           phenofile=$2
           shift
           ;;	  
	-co|--covar)
           covarfile=$2
           shift
           ;;
	-cn|--cname)
           covarname=$2
           shift
           ;;	  	    
	-rm|--rminutes)
           rminutes=$2
           shift
           ;;
        --inter)
	  inter=1
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








## +++ IF NOT GIVEN ON COMMAND LINE, read covarfile and covarname from paramfile (created in "run_gwas.sh"):

if [ -z "$covarfile" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose_nomarker.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo ""
    exit 1
  fi  
  covarfile=$( awk '{if($1 == "covarfile") print $2}' ${paramfile} )   # covarfile GWAS_covariates.txt	
fi 

if [ -z "$covarname" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose_nomarker.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo ""
    exit 1
  fi  
  covarname=$( awk '{if($1 == "covarname") print $2}' ${paramfile} )   # covarname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age 
fi 


## +++ IF NOT GIVEN ON COMMAND LINE, read phenofile from paramfile (created in "run_gwas.sh"):

if [ -z "$phenofile" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose_nomarker.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo ""
    exit 1
  fi  
  phenofile=$( awk '{if($1 == "phenofile") print $2}' ${paramfile} )   # phenofile liver_fat_faked.txt 	
fi 

# Path variables:
covarpath="${phenofolder}/${covarfile}"
phenopath="${phenofolder}/${phenofile}"







## +++ Check if the variables are defined (including those defined in the settings file)    

to_test=(phenoname phenofile covarfile covarname rminutes  phenofolder partition)


for var in  ${to_test[*]}     
do
  if [[ -z ${!var+x} ]];then
    echo ""
    echo "  ERROR (gwas_diagnose_nomarker.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done




 


 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
log="diagnose_main_nomarker.log"   # master logfile for diagnose  
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo "  Logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log} 
echo "  Phenotype file: ${phenopath}" | tee -a ${log}
echo "  Phenotype name: ${phenoname}" | tee -a ${log}
echo "  Covariate file: ${covarpath}" | tee -a ${log}
echo "  Covariate name(s): ${covarname}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime for regression and diagnostics: ${rminutes} minutes." | tee -a ${log}
echo "" | tee -a ${log}








## +++ Check availability of input files and genotype files:
 
## phenotype file: 
 
if [ ! -f ${phenopath} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose.sh): Input file '${phenopath}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
else	 
  entries=$( wc -l $phenopath | awk '{print $1}' )
  entries=$(( ${entries} - 1 ))
  echo "  The phenotype file includes ${entries} samples." | tee -a ${log}
fi
 

# check if phenoname is valid - must be a column name in phenofile

phenoheader=$( head -1 $phenopath )  #  #FID IID liv1 liv2 liv3 liv4 liv5 liv6 liv7 liv8 liv9 liv10
phenoheader=($phenoheader) 

nr_hits=0
for ptype in  ${phenoheader[*]} 
do
  if [[ "$ptype" == "$phenoname" ]];then
    nr_hits=$(( ${nr_hits} + 1 ))
  fi
done

if [ "${nr_hits}" -ne 1 ];then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_nomarker.sh): The phenotype name must occur exactly one time in the phenotype file."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi




## covariate file: 

if [ ! -f ${covarpath} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_nomarker.sh): Input file '${covarpath}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
else	 
  nr_samples=$( wc -l $covarpath | awk '{print $1}' )
  nr_samples=$(( ${nr_samples} - 1 ))
  echo "  The covariate file includes ${nr_samples} samples." | tee -a ${log}
fi

# are the covarnames chosen/inferred included in the covariates file?:

clist=$( echo $covarname | sed 's/,/ /g' )   # PC1 PC2 PC3 PC4 PC5 PC6 PC7 PC8 PC9 PC10 array sex age
for name in  ${clist[*]}  
do  
  indicator=$( head -1 ${covarpath} | grep "\b${name}\b" | wc -l )
  if [ $indicator -ne 1 ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (gwas_diagnose_nomarker.sh): Covariate file '${covarpath}' does not contain the column '${name}'" | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1   
  fi      
done

echo ""  | tee -a ${log}
echo ""  | tee -a ${log} 






 



## +++ Convert the time string for sbatch script gwas_diagnose_nomarker.R:

hours=$( expr $rminutes / 60 )  
min=$( expr $rminutes % 60 )    
if [ "$hours" -eq 0 ]; then
  rtime=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  rtime=${hours}":"${min}":00"  # requested runtime for gwas_diagnose_nomarker.R
fi  





## Files so far:

# phenopath   
# (phenoname)
# covarpath   
# (covarname)






## +++ Conduct diagnose (in R script):    

if [ "$inter" -eq 0 ];then   # A) SLURM:

  rlog="diagnose_R_no_marker.log"

  echo "  Calling gwas_diagnose.R in sbatch with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  echo "  gwas_diagnose_nomarker.R   ${phenopath} ${phenoname}  ${covarpath}  ${covarname}"  | tee -a ${log}   
  echo "" | tee -a ${log}
  echo "  Logfile for gwas_diagnose.R: ${rlog}"  | tee -a ${log} 


  jobID=$( sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  \
	--wrap="module load R_packages/3.6.1; gwas_diagnose_nomarker.R  ${phenopath} ${phenoname}  ${covarpath} ${covarname}" )    

  jobID=$( echo $jobID | awk '{print $NF}' )                                           
  echo ""
  echo "  JobID for gwas_diagnose_nomarker.R: ${jobID}"                                            
  echo ""

else   # B) NO  SLURM:

  rlog="diagnose_R_no_marker.log"
  
  echo "  Calling gwas_diagnose.R in current node with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  echo "  gwas_diagnose_nomarker.R  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}"  | tee -a ${log} 
  echo "" | tee -a ${log}
  echo "  Logfile for gwas_diagnose.R: ${rlog}"  | tee -a ${log} 

  module load R_packages/3.6.1
  gwas_diagnose_nomarker.R  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}    
     
  echo ""

fi

  



## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 



