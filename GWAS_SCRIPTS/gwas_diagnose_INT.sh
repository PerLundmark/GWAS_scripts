#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Regression diagnostics after GWAS with RINT, main script 
#      replicate also GWAS results from plink for the marker considered!    


#  two-stage RINT : https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0233847&type=printable.



## +++ Call:  
# 
# gwas_diagnose_INT --snp rs767276217_A_G --chr 5  --pname liv5
# gwas_diagnose_INT --snp rs767276217_A_G --chr 5  --pheno liver_fat_faked.txt  --pname liv2
# gwas_diagnose_INT --snp rs767276217_A_G --chr 5  --pheno liver_fat_faked.txt  --pname liv2 --switch 
# --pname = phenotype name. Must be a column of the file invoked by --pheno 
# --switch

# Interactive session:
#   interactive -n 16 -t 15:00 -A sens2019016 --qos=short
#   interactive -n 16 -t 3:00:00 -A sens2019016 
#   module load R_packages/3.6.1
#   . s2
#   which gwas_diagnose_INT
#   cd /castor/project/proj/GWAS_DEV3/liver10
#   gwas_diagnose_INT --snp rs188247550_T_C --chr 19 --pheno liver_fat_ext.txt --pname  liver_fat_a --inter 






## +++ Hardcoded settings & and defaults 

setfile=~/diagnose_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (gwas_diagnose_INT.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi


# genoid="ukb_imp_v3"							# full dataset  
# genofolder="/proj/sens2019016/GENOTYPES/PGEN"   			# location of input genotype dataset
# # phenofolder="/proj/sens2019016/PHENOTYPES"				# location of input phenotype and covariate files
# phenofolder="."		      
# minutes=10								# requested runtime for each chromosome in minutes
# partition="node"   							# partition , "core"  might run out of memory   







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
    echo "  ERROR (gwas_diagnose_INT.sh): Did not find the program ' ${p} '." 
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


# --minutes :  requested runtime for subroutine "extract_genotype.sh" 
# --rminutes : requested runtime for subroutine "gwas_diagnose_INT.R" 
# switch -eq 0   use allele counted
# switch -eq 1   use other allele  
# --summary : summary statistics file ; will be guessed by file name convention if not given on command line


switch=0
nocomp=0
inter=0   # default: run in SLURM, can only be overwritten on command line


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
	  shift
	  ;;
        --nocomp)
	  nocomp=1
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
    echo "  ERROR (gwas_diagnose_INT.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo ""
    exit 1
  fi  
  covarfile=$( awk '{if($1 == "covarfile") print $2}' ${paramfile} )   # covarfile GWAS_covariates.txt	
fi 

if [ -z "$covarname" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose_INT.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
    echo ""
    exit 1
  fi  
  covarname=$( awk '{if($1 == "covarname") print $2}' ${paramfile} )   # covarname PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,array,sex,age 
fi 


## +++ IF NOT GIVEN ON COMMAND LINE, read phenofile from paramfile (created in "run_gwas.sh"):

if [ -z "$phenofile" ];then 
  if [ ! -s "$paramfile" ];then
    echo ""
    echo "  ERROR (gwas_diagnose_INT.sh): Missing parameter file ${paramfile}. Are you in the wrong folder?"
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
    echo "  ERROR (gwas_diagnose_INT.sh): mandatory variable $var is not defined."
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
  echo "  NOTE (gwas_diagnose_INT.sh): Summary statistics ${summaryfile} not found." 
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
  echo  "  ERROR (gwas_diagnose_INT.sh): Chromosome identifier is not valid:  ${chrom}" 
  echo  "  			     Correct syntax is e.g. --chrom 16"
  echo ""
  exit 1 
fi   









 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
log="diagnose_INT_main_${marker}.log"     
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
  
pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5

psam=${pgen_prefix}".psam"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.psam 
pvar=${pgen_prefix}".pvar"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pvar	
pgen=${pgen_prefix}".pgen"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5.pgen	  

if [ ! -f ${psam} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_INT.sh): Input file '${psam}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pvar} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_INT.sh): Input file '${pvar}' not found."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi  

if [ ! -f ${pgen} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_INT.sh): Input file '${pgen}' not found."  | tee -a ${log} 
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
  echo "  PROBLEM (gwas_diagnose_INT.sh): The marker '${marker}' occurs ${nr_hits} times in ${pvar}."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi

 
 
## phenotype file: 
 
if [ ! -f ${phenopath} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_INT.sh): Input file '${phenopath}' not found."  | tee -a ${log} 
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
  echo "  ERROR (gwas_diagnose_INT.sh): The phenotype name must occur exactly one time in the phenotype file."  | tee -a ${log} 
  echo ""  | tee -a ${log} 
  exit 1 
fi




## covariate file: 

if [ ! -f ${covarpath} ]; then
  echo ""  | tee -a ${log} 
  echo "  ERROR (gwas_diagnose_INT.sh): Input file '${covarpath}' not found."  | tee -a ${log} 
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
    echo "  ERROR (gwas_diagnose_INT.sh): Covariate file '${covarpath}' does not contain the column '${name}'" | tee -a ${log}
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


## +++ Convert the time string for sbatch script gwas_diagnose_INT.R:

hours=$( expr $rminutes / 60 )  
min=$( expr $rminutes % 60 )    
if [ "$hours" -eq 0 ]; then
  rtime=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  rtime=${hours}":"${min}":00"  # requested runtime for gwas_diagnose_INT.R
fi  






## +++ Download genotype data for the marker under consideration:

if [ "$inter" -eq 0 ];then   # A) SLURM:

  echo "  Extracting genotype information for marker ${marker} in SLURM:" | tee -a ${log} 
  echo ""  | tee -a ${log}

  c_ident="DIAG_1"
  getgeno_log="diagnose_INT_extract_${marker}.log"   

  echo "  sbatch  -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${getgeno_log} -e ${getgeno_log}  \ " | tee -a ${log} 
  echo "          extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} " | tee -a ${log} 

  extract_jobid=$( sbatch  -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${getgeno_log} -e ${getgeno_log}  \
                   extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} )

  extract_jobid=$( echo ${extract_jobid} | awk '{print $NF}' ) 
  echo ""  | tee -a ${log}
  echo "  JobID for extract_genotype: ${extract_jobid}" | tee -a ${log}  
  echo ""  | tee -a ${log}
  
else  # B) NO SLURM:    #  DO FIRST:  interactive -n 16 -t 15:00 -A sens2019016 --qos=short

  echo "  Extracting genotype information for marker ${marker} in current node:" | tee -a ${log} 
  echo ""  | tee -a ${log}

  getgeno_log="diagnose_INT_extract_${marker}.log"   

  echo "  extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} " | tee -a ${log} 

  extract_genotype  --snp ${marker} --chr ${chrom} --genoid  ${genoid} --minutes ${minutes} &> ${getgeno_log}

fi


out_prefix="genotype_${marker}"   	# see extract_genotype.sh
rawfile="${out_prefix}.raw"		# genotype_rs767276217_A_G.raw  see extract_genotype.sh


if [ ! -s "$rawfile" ];then
  echo ""
  echo "  ERROR (gwas_diagnose_INT.sh): Missing file ${rawfile}. Extraction of genotype not succesful."
  echo ""
  exit 1
else
  echo ""
  echo "  Genotype for marker ${marker} succesfully extracted ==> ${rawfile}."
  echo ""    
fi 





# Files produced:

# diagnose_main_rs767276217_A_G.log     # master logfile, this script
# genotype_rs767276217_A_G.raw		# genotype data downloaded for the marker 
# diagnose_extract_rs767276217_A_G.log  # logfile for extract_genotype script called above





# Genotype raw file: 

# head $rawfile
# IID	rs767276217_A_G_A    # ==> we see here that the counted allele is A ( "A" is appended to "rs767276217_A_G" )
# 5954653	0
# 1737609	0
# 1427013	0
# 3443403	0
# 5807741	0



# check if this is the A1 allele: using the summary file



## Files so far:

# phenopath   
# (phenoname)
# covarpath   
# (covarname)
# rawfile   == genotype for counted allele (see above)
# summaryfile (optional)  (from plink regression) 







## +++ Conduct diagnose (in R script):    

if [ "$inter" -eq 0 ];then   # A) SLURM:

  rlog="diagnose_R_INT_${marker}.log"

  echo "  Calling gwas_diagnose_INT.R in sbatch with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  if [ "${compare}" -eq 1 ]; then 
    echo "  gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}"  | tee -a ${log}  
  else
    echo "  gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}"  | tee -a ${log} 
  fi
  echo "" | tee -a ${log}

  echo "  Logfile for gwas_diagnose_INT.R: ${rlog}"  | tee -a ${log} 

  if [ "${compare}" -eq 1 ]; then 
    jobID=$( sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  \
           --wrap="module load R_packages/3.6.1; gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}" )      
  else
    jobID=$( sbatch --dependency=afterok:${extract_jobid} -A ${account} -p ${partition}  -t ${rtime}  -J DIAG_2 -o ${rlog} -e ${rlog}  \
	 --wrap="module load R_packages/3.6.1; gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}" )    
  fi


  jobID=$( echo $jobID | awk '{print $NF}' )                                           
  echo ""
  echo "  JobID for gwas_diagnose_INT.R: ${jobID}"                                            
  echo ""

else   # B) NO  SLURM:

  rlog="diagnose_INT_R_${marker}.log"

  echo "  Calling gwas_diagnose_INT.R in current node with the following positional parameters:" | tee -a ${log}
  echo "" | tee -a ${log}
  if [ "${compare}" -eq 1 ]; then 
    echo "  gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}"  | tee -a ${log}  
  else
    echo "  gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}"  | tee -a ${log} 
  fi
  echo "" | tee -a ${log}

  echo "  Logfile for gwas_diagnose_INT.R: ${rlog}"  | tee -a ${log} 

  module load R_packages/3.6.1
  
  if [ "${compare}" -eq 1 ]; then 
    gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch} ${summaryfile}      
  else
    gwas_diagnose_INT.R  ${marker}  ${phenopath} ${phenoname}  ${covarpath}  ${covarname}  ${rawfile} ${switch}    
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
 
 



