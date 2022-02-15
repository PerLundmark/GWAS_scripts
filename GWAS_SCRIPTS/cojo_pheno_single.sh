#!/usr/bin/env bash




# uwe.menzel@medsci.uu.se  



## === LD pruning using GCTA-COJO for a single penotype AND a single chromosome ===    
   





## +++ Calling: 

# called by run_cojo_single.sh
#  
#    cojo_pheno_single  --id LIV6  --chr 22 --phenoname vox1_exp  --pval 5.0e-8  --window 5000  --colline 0.01 --maf 0.01 --part node  --minutes 120 
#    cojo_pheno_single  --id LIV6  --chr 22 --phenoname vox1_exp  --pval 5.0e-8  --window 5000  --colline 0.01 --maf 0.01 --part node  --minutes 120 
#
# 	This script has to be started in the folder containing the gwas results:
#    	e.g. /proj/sens2019016/GWAS_TEST/LIV5   (if identifier was "LIV5")  
#
#
# see "run_cojo_single" - phenotype names are called in a loop, for the current chromosome
#   Starting COJO
# 
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv1 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv2 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv3 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
# 
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv1 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv2 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv3 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter






## +++ Hardcoded settings & defaults 

shopt -s nullglob 

setfile=~/cojo_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings 
else
  echo ""
  echo "  ERROR (cojo_pheno_single.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi






 
## +++ Programs 
 
prog=$( which gcta64 )   
exit_code=$?  
if [ ${exit_code} -ne 0 ]
then
  echo "" 
  echo "  ERROR (cojo_pheno_single.sh): Did not find the gcta64 program." 
  echo ""
fi 






## +++ Command line parameters:   

if [ "$#" -lt 6 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -c|--chr <int>                 no default"  
  echo "         -pn|--phenoname <string>       no default"
  echo "         -p|--pval <real>               ${setfile}"
  echo "         -w|--window <integer>          ${setfile}" 
  echo "         -cl|--colline <real>           ${setfile}"
  echo "         --maf <real>                   ${setfile}"    
  echo "         -m|--minutes <int>             ${setfile}"
  echo "         --inter                        interactive mode"     
  echo ""
  exit 1
fi


inter=0   # default: run in SLURM, can only be overwritten on command line (by handover from "run_cojo_single.sh")

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
      -p|--pval)
          pval=$2
          shift
          ;;	  
      -w|--window)
          window=$2
          shift
          ;;
      -cl|--colline)
          collinearity=$2
          shift
          ;;
      --maf)
          maf=$2
          shift
          ;;	  	  	  
      -m|--minutes)
          minutes=$2
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







## +++ Files

paramfile="${ident}_gwas_params.txt" 				# OBS!! Name convention from run_gwas
signif_file="${ident}_${phenoname}_cojo.jma"   			# cojo output for this phenotype, independent markers 
log="${ident}_${phenoname}_cojo.log"   				# master logfile for cojo pruning for this phenoname  
convert_log="${ident}_${phenoname}_cojo_convert.log"  		# sbatch log for cojo_convert.sh		  		 
collect_log="${ident}_${phenoname}_cojo_collect.log"		# sbatch log for cojo_collect.sh    
clean_log="${ident}_${phenoname}_cojo_clean.log"      		# sbatch log for cojo_clean.sh   
summary_file="${ident}_${phenoname}_cojo.ma"   			# output of "cojo_convert.sh", input for "cojo_chr.sh": summary statistics for all chromosomes 
signif_list="${ident}_${phenoname}_gwas_signif.txt"  		# output of "cojo_convert.sh", list with significant markers across the genome , used in cojo_chr to decide if the chrom should be analyzed 	







## +++ Read remaining parameters from the param files (created in "run_gwas.sh"):

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (cojo_pheno_single.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

# may include cojo results for multiple phenotypes
# may include clump results for multiple phenotypes 

genoid=$( awk '{if($1 == "genotype_id") print $2}' ${paramfile} )  
cstart=$chrom  	
cstop=$chrom  	






## +++ Check if alternative genotype files were provided 

# in ~/cojo_settings.sh 
# alt_genoid="FTD_rand"		# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD

if [ -z ${alt_genoid} ];then    # -z does NOT exist 
  echo ""
  echo "  No alternative genotype ID defined. Using \"${genoid}\" read from \"${paramfile}\""
  echo ""
else
  echo ""
  genoid=${alt_genoid}
  echo "  An alternative genotype ID was defined: \"${genoid}\" read from \"${paramfile}\""
  echo ""
fi    






## +++ Make new entries in ${paramfile}

# cannot be done. The single chr should be run with the same parameters as the other chromosomes
# Possible: use extra file ...





## +++ Check if the variables are defined  

to_test=(ident phenoname pval window collinearity maf partition minutes genoid chrom minspace inter)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (cojo_pheno_single.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (cojo_pheno_single): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi






## +++ Check if $phenoname is valid (user input)

# possible entries in ${paramfile}:
#     phenoname liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10      # LIV_MULT    
#     phenoname vox1_exp   						# VOX1

pname=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} )      
pname=$( echo $pname | tr -s ',' '\t' )  			   
parray=($pname)
# echo " Number of elements in parray: ${#parray[*]}"   		#  10 ok  
nr_hits=$( printf '%s\n' ${parray[@]} | egrep "^[[:space:]]*${phenoname}[[:space:]]*$" | wc -l )  # should exactly be 1
if [ "${nr_hits}" -ne 1 ];then
  echo ""
  echo "  ERROR (cojo_pheno_single.sh): You propably picked a wrong phenotype name."
  echo "  The word \"${phenoname}\" is not included as a phenoname entry in \"${paramfile}\""
  echo ""
  exit 1
fi








## +++ Check if the global summary file is available for this phenoname

# summary_file="${ident}_${phenoname}_cojo.ma"   # output of "cojo_convert.sh", input for "cojo_chr.sh": summary statistics for all chromosomes 

# in this script, phenoname is a single word, e.g. liv1

# TEST:  phenoname="liv1"   	# /castor/project/proj/GWAS_DEV/LIV_MULT5
# TEST:  phenoname="liv4"   	# /castor/project/proj/GWAS_DEV/LIV_MULT5

pheno=${phenoname}  		# compatibility
  
summary_file="${ident}_${pheno}_cojo.ma" 

if [ -f ${summary_file} ]; then
  echo "  Summary statistics file for genotype ${pheno} (' ${summary_file} ') found."
  nr_entries=$( wc -l ${summary_file} | awk '{print $1}')
  nr_entries=$((${nr_entries} - 1))
  echo "    File contains ${nr_entries} markers." 
else
  echo ""
  echo "  ERROR (run_cojo_single.sh): Summary statistics file for genotype ${pheno} (' ${summary_file} ') not available." 
  echo "        Did you run ' run_cojo ' with --keepma OR ' cojo_convert ' in standalone mode ?"
  echo ""
  exit 1 
fi  
echo "" 








## +++ Check chromosome name  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then    # autosomes only!       
  echo ""
  echo  "  ERROR (run_cojo_single.sh): Chromosome name is not valid: " ${chrom} 
  echo  "  			       Correct syntax is e.g. --chr 22"
  echo ""
  exit 1 
fi   








## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
if [ ${space} -lt ${minspace} ]; then	
    echo "" 
    echo "  Less than ${minspace} disk space available, consider using a different location." 
    echo "" 
    exit 1 
fi 

# also done in run_cojo.sh but this can also be run standalone ...





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

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 	# sens2019016
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      #  1574946757
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo -n "  Current working folder: "  | tee -a ${log}
pwd  | tee -a ${log}
echo "  Available disk space in this path: ${spac1}"  | tee -a ${log}
echo "  Job identifier:  ${ident}" | tee -a ${log}
echo "  Phenotype namn: ${phenoname}" | tee -a ${log}
echo "  GCTA-COJO window: ${window}" | tee -a ${log}
echo "  GCTA-COJO p-value: ${pval}" | tee -a ${log}
echo "  GCTA-COJO collinearity (r2) threshold: ${collinearity}" | tee -a ${log}
echo "  GCTA-COJO minor allele freq threshold: ${maf}" | tee -a ${log}
echo "  Genotype identifier: ${genoid}" | tee -a ${log}
echo "  Running on chromosome ${chrom}" | tee -a ${log}
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "  Requested runtime per chromosome: ${time}" | tee -a ${log}
echo "" | tee -a ${log}  







## +++ Create COJO input file
#
# The ${summary_file} must exist if this script is run  (cojo_collect or run_cojo with --keepma)


# outputs the file ${summary_file} which is cojo-input # *.ma  (OBS!: this file is not available at this point, job is in the queue!)   
# head -4 LIV6_cojo.ma
# 	  ID	A1	OTHER	A1_FREQ		    BETA	     SE		       P	OBS_CT
# rs183305313	A	G	0.00490037	-0.29715	0.364161	0.414519	18771
# rs12260013	G	A	0.0271634	0.112443	0.156766	0.473222	18771
# rs61838967	T	C	0.186952	-0.04485	0.064733	0.488359	18771







 
## +++ Run through chromosomes having significant hits with cojo:
#
# The chromosome is run as a whole:  ( see Mail_Zhili_March12.txt)  
# 
#   From: Zhili Zheng <zhili.zheng@uq.edu.au> 
#   Sent: Thursday, 12 March 2020 06:38
#   To: Uwe Menzel <uwe.menzel@medsci.uu.se>
#   Subject: Re: Question regarding GCTA-COJO (LInkage disequilibrium)
# 
#   Hi Uwe,
# 
#   Run as a whole shall be a best approach.  
#   Run in each region will not speed it up [...],  
#   and also the region is not large enough, as the COJO run in 10Mb window. 
# 
#   Regards,
#   Zhili


if [ "$inter" -eq 0 ];then   # A) SLURM: submit sbatch command

  prune_log="${ident}_${phenoname}_cojo_chrom${chrom}.log"	# sbatch log for cojo_chr   
  c_ident="COJO-${chrom}"  
  out_prefix="${ident}_${phenoname}_cojo_chr${chrom}"  		# OBS! also used in "cojo_collect.sh" called  afterwards  

  echo "" | tee -a ${log}
  echo "  sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \  "  | tee -a ${log} 
  echo "  cojo_chr --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} --colline ${collinearity} --maf ${maf} \  "  | tee -a ${log} 
  echo "           --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix}" | tee -a ${log} 

  # 512 GB job: only 3 nodes available on Bianca !! long queue times   # -C mem256GB  -C mem512GB
  # jobid=$( sbatch -A ${account} -p ${partition} -C mem512GB -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \
  # cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} \
  # 	    --colline ${collinearity} --maf ${maf} --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix} ) 
  
  jobid=$( sbatch -A ${account} -p ${partition} -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \
  cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} \
  	    --colline ${collinearity} --maf ${maf} --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix} ) 
   
  jobid=$( echo $jobid | awk '{print $NF}' ) 
  echo "  JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo ""  | tee -a ${log} 

else # B) NO SLURM:    #  DO FIRST: interactive -n 16 -t 2:00:00 -A sens2019016

  prune_log="${ident}_${phenoname}_cojo_chrom${chrom}.log"	# sbatch log for cojo_chr   
  out_prefix="${ident}_${phenoname}_cojo_chr${chrom}"  		# OBS! also used in "cojo_collect.sh" called  afterwards  

  echo "" | tee -a ${log}
  echo "  cojo_chr --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} --colline ${collinearity} --maf ${maf} \  "  | tee -a ${log} 
  echo "           --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix}" | tee -a ${log} 

  cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} \
            --colline ${collinearity} --maf ${maf} --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix} | tee -a ${prune_log} 
  
  echo ""  | tee -a ${log} 

fi


# ${summary_file} = summary statistics for all chromosomes (*.ma), created in cojo_convert.sh  
  
echo "" | tee -a ${log} 
echo "" | tee -a ${log} 





## +++ Concatenate output files for individual chromosomes: 

# run cojo_collect when all chromosomes are done
 






## +++ Clean 

# run cojo_clean when all chromosomes are done


# What about signif_file?  will be created by cojo_collect 



## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log} 
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 






 
 
 
 
 
 
