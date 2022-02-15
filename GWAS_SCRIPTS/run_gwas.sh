#!/usr/bin/env bash

# uwe.menzel@medsci.uu.se  



## === Run a GWAS on multiple chromosomes and multiple phenotypes in parallel   


  
  
  
 
## +++ Calling:   
#
# run_gwas --id ${ident}  --phenofile ${phenofile}  --phenoname ${phenoname}  --genoid ${genoid}  --chr ${chrom}   \
#          --phenofolder .  --covarfile ${covarfile}  -m ${minutes} --hwe 1.0e-6 
#
#           uses defaults --covarname "PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age"   --mac 20  --mr2 "0.8 2.0"
#
# + Mandatory input (when all defaults apply):
#
#   ident="LIV5"
#   phenofile="liver_fat_1.txt"
#   phenoname="liver_1"
#
# run_gwas  --id ${ident}   --phenofile ${phenofile}  --phenoname ${phenoname}  







## +++ Hardcoded settings & and defaults 

setfile=~/gwas_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (run_gwas.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi





 
## +++ Command line parameters (override the settings in $setfile):

prog=$( basename "$0" )

if [ "$#" -lt 6 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -p|--phenofile <file>          no default"
  echo "         -pn|--phenoname <string>       no default"  
  echo "         -c|--chr <int>[-<int>]         ${setfile}"  
  echo "         -g|--genoid <string>           ${setfile}"
  echo "         -pf|--phenofolder <folder>     ${setfile}"    
  echo "         -cf|--covarfile <file>         ${setfile}"
  echo "         -cn|--covarname <string>       ${setfile}"
  echo "         --maf <real>                   ${setfile}"
  echo "         --mac <int>                    ${setfile}"
  echo "         --vif <int>                    ${setfile}"      
  echo "         --hwe <real>                   ${setfile}"
  echo "         --mr2 <range>                  ${setfile}"
  echo "         --geno <real>                  ${setfile}" 
  echo "         --mind <real>                  ${setfile}"     
  echo "         -m|--minutes <int>             ${setfile}"
  echo "         --ask <y|n>                    ${setfile}"
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
      -p|--phenofile)
          phenofile=$2
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
      -g|--genoid)
          genoid=$2    
          shift
          ;; 
      -pf|--phenofolder)
          phenofolder=$2
          shift
          ;;
      -cf|--covarfile)
          covarfile=$2
          shift
          ;;
      -cn|--covarname)
          covarname=$2
          shift
          ;;	  
      --maf)
          maf=$2
          shift
          ;;	  
      --mac)
          mac=$2
          shift
          ;;
      --vif)
          vif=$2
          shift
          ;;	  	  	  	   
      --hwe)
          hwe_pval=$2
          shift
          ;;	  	  
      --mr2)
          machr2=$2
          shift
          ;;	  
      --geno)
          marker_max_miss=$2    
          shift
          ;;	  
      --mind)
          sample_max_miss=$2    
          shift
          ;;	  
      -m|--minutes)
          minutes=$2
          shift
          ;; 
      --ask)
          ask=$2
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

to_test=(ident phenofile  phenoname genoid chrom hwe_pval phenofolder covarfile covarname mac maf vif marker_max_miss sample_max_miss machr2 partition minutes minspace ask)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (run_gwas.sh): mandatory variable $var is not defined."
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
  echo  "  ERROR (run_gwas.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (run_gwas.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )







## +++ Change to work folder ( .. but check if a folder with the same name already exists):

if [ -d "${ident}" ]; then
  echo ""
  echo "  WARNING (run_gwas.sh): A folder '${ident}' already exists in the current location." 
  echo "  Delete this folder to renew previous results, use another identifier, or rename the existing folder."
  echo ""
  exit 1
else 
  orig_location=$( pwd )
  mkdir ${ident}   # create output folder named after job identifier 
  if [ "$phenofolder" = "." ]; then 
    phenofolder=$( pwd )    
  fi
  cd ${ident}	  
fi






 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' )
log="${ident}_gwas.log"   # master logfile 
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      #  1574946757
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo "  Job identifier: " ${ident} | tee -a ${log}
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Running on chromosomes $cstart to $cstop" | tee -a ${log}  
echo "  Genotype input folder: ${genofolder}"  | tee -a ${log}
echo "  Genotype identifier: ${genoid}" | tee -a ${log}
echo "  Phenotype input folder: ${phenofolder}"  | tee -a ${log} 
echo "  Phenotype input file: ${phenofile}"  | tee -a ${log} 
echo "  Phenotype column name(s): ${phenoname}"  | tee -a ${log}
echo "  Covariate input file: ${covarfile}"  | tee -a ${log} 
echo "  Covariate column name(s): ${covarname}"  | tee -a ${log}
echo "" | tee -a ${log}
echo "  Threshold for minor allele count (mac): ${mac}" | tee -a ${log}
echo "  Threshold for minor allele frequency (maf): ${maf}" | tee -a ${log}
echo "  Maximum variance inflation factor (vif): ${vif}" | tee -a ${log}
echo "  Maximum missing call rate for markers: ${marker_max_miss} " | tee -a ${log}
echo "  Maximum missing call rate for samples: ${sample_max_miss} " | tee -a ${log}
echo "  Threshold for Hardy-Weinberg p-value: ${hwe_pval}"  | tee -a ${log}
echo "  Imputation quality range (mach-r2): ${machr2}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "" | tee -a ${log}






## +++ Let the user confirm the choice of parameters if $ask = "y"

if [[ "$ask" =~ ^y+ ]];then  # ask for confirmation  
  # read -p "  Do you want to proceed using these values? (y/n):" -n 1 -r
  read -p "  Do you want to proceed using these values? (y/n):"     
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    echo "  Starting GWAS"; echo
  else
    echo; echo "  Bye."; echo
    exit 0
  fi
fi







## +++ Check available disk space:

echo "  Original start folder: ${orig_location}" | tee -a ${log}
echo -n "  Current working folder: " | tee -a ${log}
pwd | tee -a ${log}
space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
echo "  Available disk space in this path: ${spac1}" | tee -a ${log}
echo "" | tee -a ${log}
if [ ${space} -lt ${minspace} ]; then   # 1 TByte 
    echo "" | tee -a ${log}
    echo "  Less than ${minspace} free disk space, consider using a different location." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
fi 








## +++ Check availability of input files and genotype files:

for chrom in  ${chromosomes[*]}     
do

  pgen_prefix=${genofolder}"/"${genoid}"_chr"$chrom   # name must fit to the genotype files listed above (.pgen files)

  psam=${pgen_prefix}".psam"	
  pvar=${pgen_prefix}".pvar"	 
  pgen=${pgen_prefix}".pgen" 	   

  if [ ! -f ${psam} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (run_gwas.sh): Input file '${psam}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pvar} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (run_gwas.sh): Input file '${pvar}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pgen} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (run_gwas.sh): Input file '${pgen}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi    

done   

echo "  All required genotype files (.pgen, .pvar, .psam) are available."  | tee -a ${log}

## Phenotype file

phenopath=${phenofolder}"/"${phenofile}
covarpath=${phenofolder}"/"${covarfile}

if [ ! -f ${phenopath} ]; then
  echo "" | tee -a ${log}
  echo "  ERROR (run_gwas.sh): Phenotype file '${phenopath}' not found." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
fi


# check number of columns
indic=$( gawk 'BEGIN{FS="\t"}{print NF}' $phenopath | sort | uniq -c | wc -l )  
if [ "$indic" -ne "1" ];then
  echo "" | tee -a ${log}
  echo "  ERROR (run_gwas.sh): Phenotype file '${phenopath}' seems to have unequal number of columns." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1   
fi

# check #FID	 IID	liv1	liv2	liv3	liv4  ...
tag=$( head -1 ${phenopath} | gawk 'BEGIN{FS="\t"}{if($1 != "#FID" || $2 != "IID") print "error"}' )
if [ "${tag}" == "error" ];then
  echo ""
  echo "  ERROR (run_gwas.sh): Format of phenofile \"${phenopath}\" not correct."
  echo "                       Must start with \"#FID   IID\""
  echo ""
  exit 1
fi

num_samples=$( wc -l ${phenopath} | awk '{print $1}' )
num_samples=$(( ${num_samples} - 1 ))
echo "  Phenotype file available, with ${num_samples} samples."  | tee -a ${log}

echo "  Checking the phenotype names with phenotype file ${phenopath}:" | tee -a ${log}
echo "" | tee -a ${log}  

pn=$( echo $phenoname | tr -s ',' '\t' )  
phenoarray=($pn)     			
header=$( head -1 ${phenopath} )
headarray=($header)   		

for ptype in  ${phenoarray[*]} 
do
  # echo "${ptype}" 
  nr_hits=$( printf '%s\n' ${headarray[@]} | egrep "^[[:space:]]*${ptype}[[:space:]]*$" | wc -l ) 
  if [ "${nr_hits}" -gt 1 ];then
    echo ""
    echo "  ERROR (run_gwas.sh):  Multiple matches for \"${ptype}\" in the header of the phenotype file ${phenopath}." 
    echo ""
    exit 1
  fi    

  if [ "${nr_hits}" -eq 0 ];then
    echo ""
    echo "  ERROR (run_gwas.sh): No match for \"${ptype}\" in the header of the phenotype file ${phenopath}."
    echo "" 
    exit 1
  fi  
  echo "    \"${ptype}\" ok." | tee -a ${log}

done
echo "" | tee -a ${log}



## Covariate file:

if [ ! -f ${covarpath} ]; then
  echo "" | tee -a ${log}
  echo "  ERROR (run_gwas.sh): Covariate file '${covarpath}' not found." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
fi


# check number of columns
indic=$( gawk 'BEGIN{FS="\t"}{print NF}' $covarpath | sort | uniq -c | wc -l )  
if [ "$indic" -ne "1" ];then
  echo "" | tee -a ${log}
  echo "  ERROR (run_gwas.sh): Covariate file '${covarpath}' seems to have unequal number of columns." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1   
fi


num_samples=$( wc -l ${covarpath} | awk '{print $1}' )
num_samples=$(( ${num_samples} - 1 ))
echo "  Covariates file available, with ${num_samples} samples." | tee -a ${log} 
clist=$( echo $covarname | sed 's/,/ /g' )
for name in  ${clist[*]}  
do  
  indicator=$( head -1 ${covarpath} | grep "\b${name}\b" | wc -l )
  if [ $indicator -ne 1 ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (run_gwas.sh): Covariate file '${covarpath}' does not contain the column '${name}'" | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1   
  fi      
done


# copy phenotype file, covariate file and settings file to current location ( ${ident} )
cp ${covarpath} .
cp ${phenopath} .
cp ${setfile} .  
echo "" 






## +++ Convert the time string for sbatch command below:

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"    # this is the time for a single chromosome to run
fi  
echo "  Requested runtime for each chromosome: ${time}" | tee -a ${log}
echo "" | tee -a ${log}; echo "" | tee -a ${log}






## +++ Call "gwas_chr" for each chromosome in sbatch

for chrom in  ${chromosomes[*]} 
do
 
  pgen_prefix=${genofolder}"/"${genoid}"_chr"$chrom   	# OBS! must be same as above  e.g.  /proj/sens2019016/UKB_PGEN/MF_chr16  
  logchr="${ident}_gwas_chrom${chrom}.log"    		# logfile for a single chromosome (and for multiple phenotypes)   
  c_ident="GWAS-${chrom}"  
  
  echo "  sbatch -A ${account}  -p ${partition}  -t ${time}  -J ${c_ident} -o ${logchr} -e ${logchr}  \ "  | tee -a ${log}
  echo "  gwas_chr --gen ${pgen_prefix}  --chr ${chrom}  --id ${ident} \ " | tee -a ${log}  
  echo "           --pheno ${phenopath}  --pname ${phenoname} \ " | tee -a ${log} 
  echo "           --covar ${covarpath}  --cname ${covarname} \ " | tee -a ${log}
  echo "           --mac ${mac} --maf ${maf} --vif ${vif} --geno ${marker_max_miss} --mind ${sample_max_miss} \ " | tee -a ${log}
  echo "           --mr2 ${machr2} --hwe ${hwe_pval}" | tee -a ${log}

  jobid=$( sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${logchr} -e ${logchr}  \
	 gwas_chr --gen ${pgen_prefix}  --chr ${chrom}  --id ${ident}  --pheno ${phenopath}  --pname ${phenoname}  \
                  --covar ${covarpath}  --cname ${covarname} --mac ${mac}  --maf ${maf} --vif ${vif} --mr2 "${machr2}"  --hwe ${hwe_pval} \
		  --geno ${marker_max_miss} --mind ${sample_max_miss} ) 
    
  jobid=$( echo $jobid | awk '{print $NF}' )
  echo "  JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo ""  | tee -a ${log}
  
  # -C mem256GB  -C mem512GB
   
done  





## Create a parameterfile of chromosome-independent params for the reviewing (R-)script :

paramfile="${ident}_gwas_params.txt"    # OBS!! Naming convention is also used in "review-GWAS.R". Do NOT change here without changing there!  
echo -n > ${paramfile}
workfolder=$( pwd )
echo "plink2_version ${plink2_version}" >> ${paramfile}
echo "workfolder ${workfolder}" >> ${paramfile} 
echo "ident ${ident}" >> ${paramfile}
echo "cstart ${cstart}" >> ${paramfile} 
echo "cstop ${cstop}" >> ${paramfile}
echo "genotype_id ${genoid}" >> ${paramfile}
echo "phenofile ${phenofile}" >> ${paramfile}
echo "phenoname ${phenoname}" >> ${paramfile}
echo "covarfile ${covarfile}" >> ${paramfile}
echo "covarname ${covarname}" >> ${paramfile}
echo "mac ${mac}" >> ${paramfile}
echo "maf ${maf}" >> ${paramfile}
echo "vif ${vif}" >> ${paramfile}
echo "sample_max_miss ${sample_max_miss}" >> ${paramfile}
echo "marker_max_miss ${marker_max_miss}" >> ${paramfile}
echo "hwe_pval ${hwe_pval}" >> ${paramfile} 
machr2_low=$( echo $machr2 | awk '{print $1}' )
machr2_high=$( echo $machr2 | awk '{print $2}' )
echo "machr2_low ${machr2_low}" >> ${paramfile}
echo "machr2_high ${machr2_high}" >> ${paramfile} 






## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
# echo "  Run time: $DIFF seconds"| tee -a ${log}  # the main script just submits jobs, takes only a few seconds
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
cd ${orig_location}  











