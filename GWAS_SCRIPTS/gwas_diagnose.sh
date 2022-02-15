#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Regression diagnostics after GWAS, main script 
#      replicate also PLINK GWAS results with R for the marker considered (if --nocomp is not invoked)    





## +++ Call:  
# 
# ++ A) With comparison to PLINK results (in a folder gontaining the results of a GWAS session)
#
# Interactive session:
#
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short  OR: interactive -n 16 -t 3:00:00 -A sens2019016 
#   cd /proj/sens2019016/nobackup/GWAS_TEST/liver13
#   gwas_diagnose --snp rs188247550_T_C --chr 19 --pheno liver_fat_ext.txt --pname  liver_fat_a --inter 
#
# ++ B) Without comparison to PLINK results (in any location if the input files are available)
# 
# B.1) SLURM:
# /proj/sens2019016/nobackup/GWAS_TEST
# gwas_diagnose --snp rs188247550_T_C --chr 19 --pheno liver_fat_ext.txt --pname  liver_fat_a --nocomp  \
#            --covar GWAS_covariates_PC40.txt --cname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age
# 
# B.2) interactive 
# 
# /proj/sens2019016/nobackup/GWAS_TEST
# gwas_diagnose --snp rs188247550_T_C --chr 19 --pheno liver_fat_ext.txt --pname  liver_fat_a --nocomp  --covar GWAS_covariates_PC40.txt --cname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age --inter





## +++ Hardcoded settings & and defaults 

setfile=~/diagnose_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (gwas_diagnose.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi

switch=0     # use counted allele in regression (instead of alternate allele) 
nocomp=0     # compare with PLINK results
inter=0      # default: run in SLURM, can only be overwritten on command line






## +++ Files 

ident=$(basename $(pwd)) 		   # LIV_MULT5  This script must be started in the folder where the GWAS was run! 
paramfile="${ident}_gwas_params.txt" 	   # LIV_MULT5_gwas_params.txt   OBS!! Name convention from run_gwas 




 
## +++ Programs 
 
progs_to_test=( extract_genotype )

for p in  ${progs_to_test[*]}     
do
  prog=$( which ${p} )   
  exit_code=$?  
  if [ ${exit_code} -ne 0 ]
  then
    echo "" 
    echo "  ERROR (gwas_diagnose.sh): Did not find the program ' ${p} '." 
    echo ""
    exit 1
  fi      
done
 



 


## +++ Command line parameters:   

if [ "$#" -lt 6 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        --snp <string>               no default"
  echo "        -c|--chr <int>               no default" 
  echo "        -pn|--pname <string>         no default"  
  echo "        -p|--pheno <file>            ${paramfile}"   
  echo "        -co|--covar <file>           ${paramfile}" 
  echo "        -cn|--cname <string>         ${paramfile}"
  echo "        -g|--genoid <string>         ${setfile}" 
  echo "        -s|--summary <file>          gwas_chr.sh"  
  echo "        -m|--minutes <int>           ${setfile}"
  echo "        -rm|--rminutes <int>         ${setfile}" 
  echo "        --switch                     use other allele"
  echo "        --nocomp                     skip plink comparison"
  echo "        --inter                      interactive mode"     
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
	-g|--genoid)
           genoid=$2    
           shift
           ;;
	-s|--summary)  
           summaryfile=$2
           shift
           ;;	  
	-m|--minutes)
           minutes=$2
           shift
           ;;
	-rm|--rminutes)
           rminutes=$2
           shift
           ;;
        --switch)
	  switch=1
	  ;;
        --nocomp)
	  nocomp=1
	  ;;
        --inter)
	  inter=1
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



# --minutes :    requested runtime for subroutine "extract_genotype.sh" 
# --rminutes :   requested runtime for subroutine "gwas_diagnose.R" 
# switch -eq 0   use allele counted
# switch -eq 1   use other allele  
# --summary :     summary statistics file ; will be guessed by file name convention if not given on command line






## +++ IF NOT GIVEN ON COMMAND LINE, read covarfile and covarname from paramfile (created in "run_gwas.sh"):

if [ -z "$covarfile" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo "        (You might want to explicitly specify the covariate file (--covar) in order to bypass this problem.)"
    echo ""
    exit 1
  fi  
  covarfile=$( awk '{if($1 == "covarfile") print $2}' ${paramfile} )   	
fi 

if [ -z "$covarname" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo "        (You might want to explicitly specify the covariate names (--cname) in order to bypass this problem.)"
    echo ""
    exit 1
  fi  
  covarname=$( awk '{if($1 == "covarname") print $2}' ${paramfile} )   
fi 


## +++ IF NOT GIVEN ON COMMAND LINE, read phenofile from paramfile (created in "run_gwas.sh"):

if [ -z "$phenofile" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo "        (You might want to explicitly specify the phenofile (--pheno) in order to bypass this problem.)"
    echo ""
    exit 1
  fi  
  phenofile=$( awk '{if($1 == "phenofile") print $2}' ${paramfile} )   # phenofile liver_fat_faked.txt 	
fi 

# Path variables:
covarpath="${phenofolder}/${covarfile}"
phenopath="${phenofolder}/${phenofile}"







## +++ Check if the variables are defined (including those defined in the settings file)    

to_test=(marker chrom phenoname phenofile covarfile covarname genoid minutes rminutes switch genofolder phenofolder partition)

# summaryfile = summary statistics file ; will be guessed below by file name convention if not given on command line

for var in  ${to_test[*]}     
do
  if [[ -z ${!var+x} ]];then
    echo ""
    echo "  ERROR (gwas_diagnose.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done


# marker="rs767276217_A_G"
# chrom=5
# genofolder="/proj/sens2019016/GENOTYPES/PGEN"
# genoid="ukb_imp_v3"



 



## +++ Guess summary statistics filename IF NOT GIVEN ON COMMAND LINE !!:
#       OBS!! summary statistics file name not saved to paramfile in run_gwas.sh - change later?? (in gwas_chr.sh?)
#       need $chrom here, that's why we don't check for summary above


outfile_prefix="${ident}_gwas_chr"${chrom}           	# OBS!! : Naming convention originates from gwas_chr.sh    
out_glm=${outfile_prefix}"."${phenoname}".glm.linear"	# LIV_MULT5_gwas_chr1.liv9.glm.linear ; defined in gwas_chr.sh  

if [ -z "$summaryfile" ];then 
  summaryfile=${out_glm}  # LIV_MULT5_gwas_chr5.liv5.glm.linear	
fi 

# if the summary statistics file does not exist, we skip comparison with plink results
compare=1	# default = make comparison with plink regression results
if [ ! -s "$summaryfile" ];then	# -s : file is not zero size 
  echo ""
  echo "  NOTE (gwas_diagnose.sh): Summary statistics ${summaryfile} not found." 
  echo "  Comparison with plink results will be omitted. We do the regression anyway."
  echo ""
  compare=0	# don't make comparision with plink regression results
fi  

# if we wish by command line argument, we skip comparison with plink results
if [ "$nocomp" -eq 1 ];then
  echo ""
  echo "  Comparison with plink results suppressed by user intervention."
  echo ""
  compare=0	# don't make comparision with plink regression results
fi  




## +++ Chromosome  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (gwas_diagnose.sh): Chromosome identifier is not valid:  ${chrom}" 
  echo  "  			     Correct syntax is e.g. --chrom 16"
  echo ""
  exit 1 
fi   







## +++ Check if interactive, if this option was chosen

if [ "$inter" -eq "1" ];then  # interactive mode was declared

  tag=$( echo $SLURM_JOB_NAME | grep interactive | wc -l )  

  if [ "$tag" -eq "0" ];then
    echo ""
    echo "  ERROR: You have chosen to run this script in interactive mode, but you did not enter an interactive session."
    echo "         An interactive session can for instance be entered using one of the following commands:"
    echo "             interactive -A sens2019016 -n 16 -t 15:00 --qos=short"
    echo "             interactive -A sens2019016 -n 16 -t 3:00:00"
    # echo "             module load R_packages/3.6.1"
    echo "             uwe.menzel@medsci.uu.se"
    echo
    exit 0
  fi
  # interactive -n 16 -t 15:00 -A sens2019016 --qos=short  OR: interactive -n 16 -t 3:00:00 -A sens2019016 
  # modules are loaded from within the script
fi






 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
log="diagnose_main_${marker}.log"    
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
echo "  Marker: ${marker}" | tee -a ${log}
if [ "$switch" -eq 1 ];then
  echo "  Switch to other allele" | tee -a ${log}
else
  echo "  Use allele counted by plink" | tee -a ${log}
fi
echo "  Chromosome: $chrom" | tee -a ${log}  
echo "  Genotype input folder: ${genofolder}"  | tee -a ${log}
echo "  Genotype identifier: " ${genoid} | tee -a ${log}
echo "  Phenotype file: ${phenopath}" | tee -a ${log}
echo "  Phenotype name: ${phenoname}" | tee -a ${log}
echo "  Covariate file: ${covarpath}" | tee -a ${log}
echo "  Covariate name(s): ${covarname}" | tee -a ${log}
if [ "${compare}" -eq 1 ]; then 
  echo "  Summary statistics: ${summaryfile}"  | tee -a ${log}
else
  echo "  Summary statistics: skipped (by user intervention or missing file ' ${summaryfile} '."  | tee -a ${log}
fi
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime for extraction of genotype data: ${minutes} minutes." | tee -a ${log}
echo "  Requested runtime for regression and diagnostics: ${rminutes} minutes." | tee -a ${log}
echo "" | tee -a ${log}








## +++ Check availability of input files and genotype files:


# check .pgen .pvar .psam for the chromosome chosen
  
pgen_prefix="${genofolder}/${genoid}_chr$chrom"   

psam=${pgen_prefix}".psam"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.psam 
pvar=${pgen_prefix}".pvar"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pvar	
pgen=${pgen_prefix}".pgen"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pgen	  

if [ ! -f ${psam} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose.sh): Input file '${psam}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pvar} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose.sh): Input file '${pvar}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pgen} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose.sh): Input file '${pgen}' not found."  | tee -a ${log} 
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


# check if the marker is included in the corresponding .pvar file

nr_hits=$( grep "\b${marker}\b" ${pvar} | wc -l )        
if [ "${nr_hits}" -ne 1 ];then
  echo ""  | tee -a ${log} 
  echo "  PROBLEM (gwas_diagnose.sh): The marker '${marker}' occurs ${nr_hits} times in ${pvar}."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi

 
 
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
  echo "  ERROR (gwas_diagnose.sh): The phenotype name must occur exactly one time in the phenotype file."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi




## covariate file: 

if [ ! -f ${covarpath} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose.sh): Input file '${covarpath}' not found."  | tee -a ${log} 
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
    echo "  ERROR (gwas_diagnose.sh): Covariate file '${covarpath}' does not contain the column '${name}'" | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1   
  fi      
done

echo ""  | tee -a ${log}
echo ""  | tee -a ${log} 






 

## +++ Convert the time string for sbatch script extract_genotype.sh :

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"  # requested runtime for extract_genotype.sh
fi  


## +++ Convert the time string for sbatch script gwas_diagnose.R:

hours=$( expr $rminutes / 60 )  
min=$( expr $rminutes % 60 )    
if [ "$hours" -eq 0 ]; then
  rtime=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  rtime=${hours}":"${min}":00"  # requested runtime for gwas_diagnose.R
fi  








if [ "$inter" -eq 0 ];then   # A) SLURM:

  # Download genotype data for the marker under consideration:

  echo "  Extracting genotype information for marker ${marker} in SLURM:" | tee -a ${log} 
  echo ""  | tee -a ${log}

  c_ident="DIAG_1"
  getgeno_log="diagnose_extract_${marker}.log"   

  echo "  sbatch  -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${getgeno_log} -e ${getgeno_log}  \ " | tee -a ${log} 
  echo "          extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} " | tee -a ${log} 

  extract_jobid=$( sbatch  -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${getgeno_log} -e ${getgeno_log}  \
                   extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} )

  extract_jobid=$( echo ${extract_jobid} | awk '{print $NF}' )
   
  echo ""  | tee -a ${log}
  echo "  JobID for extract_genotype: ${extract_jobid}" | tee -a ${log}  
  echo ""  | tee -a ${log}

  out_prefix="genotype_${marker}"   	# see extract_genotype.sh
  rawfile="${out_prefix}.raw"		# genotype_rs767276217_A_G.raw  see extract_genotype.sh


  # Conduct diagnose (in R script):  

  rlog="diagnose_R_${marker}.log"

  echo "  Calling gwas_diagnose.R in sbatch with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  
  if [ "${compare}" -eq 1 ]; then 
    echo "  gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}"  | tee -a ${log}  
  else
    echo "  gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}"  | tee -a ${log} 
  fi
  echo "" | tee -a ${log}

  echo "  Logfile for gwas_diagnose.R: ${rlog}"  | tee -a ${log} 

  if [ "${compare}" -eq 1 ]; then 
    jobID=$( sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  \
           --wrap="module load R_packages/3.6.1; gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}" )      
  else
    jobID=$( sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  \
	 --wrap="module load R_packages/3.6.1; gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}" )    
  fi


  jobID=$( echo $jobID | awk '{print $NF}' )                                           
  echo ""
  echo "  JobID for gwas_diagnose.R: ${jobID}"                                            
  echo ""
  
  
else  # B) NO SLURM:    #  DO FIRST:  interactive -n 16 -t 15:00 -A sens2019016 --qos=short

  # Download genotype data for the marker under consideration:

  echo "  Extracting genotype information for marker ${marker} in current node:" | tee -a ${log} 
  echo ""  | tee -a ${log}

  getgeno_log="diagnose_extract_${marker}.log"   

  echo "  extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} " | tee -a ${log} 

  extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} &> ${getgeno_log}


  out_prefix="genotype_${marker}"   	# see extract_genotype.sh
  rawfile="${out_prefix}.raw"		# genotype_rs767276217_A_G.raw  see extract_genotype.sh


  if [ ! -s "$rawfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose.sh): Missing file ${rawfile}. Extraction of genotype not succesful."
    echo ""
    exit 1
  else
    echo ""
    echo "  Genotype for marker ${marker} succesfully extracted ==> ${rawfile}."
    echo ""    
  fi 
 
  # Conduct diagnose (in R script):  
  
  rlog="diagnose_R_${marker}.log"

  echo "  Calling gwas_diagnose.R in current node with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  if [ "${compare}" -eq 1 ]; then 
    echo "  gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}"  | tee -a ${log}  
  else
    echo "  gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}"  | tee -a ${log} 
  fi
  echo "" | tee -a ${log}

  echo "  Logfile for gwas_diagnose.R: ${rlog}"  | tee -a ${log} 

  module load R_packages/3.6.1
  
  if [ "${compare}" -eq 1 ]; then 
    gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}      
  else
    gwas_diagnose.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}    
  fi
  
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
 
 



