#!/usr/bin/env bash



# uwe.menzel@medsci.uu.se  



## === LD clumping using plink1.9 for a single penotype name ===    
   



## +++ Calling: 

# called by run_clump.sh
#  
# called by run_clump.sh
# 
# 
#    clump_pheno  --id LIV_MULT4   --phenoname liv2  
#
# 	This script has to be started in the folder containing the gwas results:
#    	e.g. /proj/sens2019016/GWAS_TEST/LIV5   (if identifier was "LIV5")  







## +++ Hardcoded settings & defaults 

shopt -s nullglob 

setfile=~/clump_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings 
else
  echo ""
  echo "  ERROR (clump_pheno.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi







## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 4 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -pn|--phenoname <string>       no default" 
  echo "         -p1|--p1 <real>                ${setfile}"
  echo "         -p2|--p2 <real>                ${setfile}"
  echo "         -r2|--r2 <real>                ${setfile}"   # lower value yields fewer clumps  
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
       -pn|--phenoname)
          phenoname=$2
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








## +++ Files

paramfile="${ident}_gwas_params.txt" 		# Input. OBS!! Name convention from run_gwas
signif_file="${ident}_${phenoname}_clump.jma"   # clump output for this phenotype, independent markers, all chromosomes 
log="${ident}_${phenoname}_clump.log"   	# master logfile for clumping for this phenoname  








## +++ Read remaining parameters from the param files (created in "run_gwas.sh"):

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (clump_pheno.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

# may include clump results for multiple phenotypes 

genoid=$( awk '{if($1 == "genotype_id") print $2}' ${paramfile} )  	
cstart=$( awk '{if($1 == "cstart") print $2}' ${paramfile} )  		
cstop=$( awk '{if($1 == "cstop") print $2}' ${paramfile} )  		






## +++ Check if alternative genotype files were provided

# in ~/clump_settings.sh 
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

# ${signif_file} will be the final output of "clump_pheno.sh". Add the name to the parameterfile:
# remove possibly existing clump-entry for this phenotype: 
rnum=$(( 1 + RANDOM%10000 ))   # avoid interference with jobs running parallel
awk -v pheno=$phenoname '{if(!($1 == "clump_out" && $2 == pheno)) {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt 
mv temp_${phenoname}_${rnum}.txt ${paramfile}  
echo "clump_out ${phenoname} ${signif_file}" >> ${paramfile} 	# replace by current entry 


# clump_p1=5e-8 # significance threshold for index markers 
awk '{if($1 != "clump_p1") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "clump_p1 ${clump_p1}" >> ${paramfile} 	# replace by current entry 

# clump_p2=5e-6 # secondary significance threshold for clumped markers
awk '{if($1 != "clump_p2") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "clump_p2 ${clump_p2}" >> ${paramfile} 	# replace by current entry 

# clump_r2=0.01 # LD r2-threshold ; (lower value yields fewer clumps)
awk '{if($1 != "clump_r2") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "clump_r2 ${clump_r2}" >> ${paramfile} 	# replace by current entry 

# clump_kb=5000	# physical distance threshold for independency in Kb
awk '{if($1 != "clump_kb") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "clump_kb ${clump_kb}" >> ${paramfile} 	# replace by current entry 

# clump_refgen="FTD_rand"
awk '{if($1 != "clump_refgen") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "clump_refgen ${genoid}" >> ${paramfile} 	# replace by current entry reference genome (read from paramfile or alternative genoid, see settings file) 









## +++ Check if the variables are defined  

to_test=(ident phenoname clump_p1 clump_p2 clump_r2 clump_kb partition minutes genoid cstart cstop minspace)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (clump_pheno.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (clump_pheno.sh): It seems you are in the wrong location." 
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
  echo "  ERROR (clump_pheno.sh): You propably picked a wrong phenotype name."
  echo "  The word \"${phenoname}\" is not included as a phenoname entry in \"${paramfile}\""
  echo ""
  exit 1
fi







## +++ Check chromosomes:

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (clump_pheno.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (clump_pheno.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )







## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  
spac1=$( df -h . | tail -1 | awk '{print $4}' )  
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
echo "  Genotype ID: ${genoid}"  | tee -a ${log}
echo "  Phenotype namn: ${phenoname}" | tee -a ${log}
echo "  Significance threshold for index markers (p1): ${clump_p1}" | tee -a ${log}
echo "  Secondary significance threshold for clumped markers (p2): ${clump_p2}" | tee -a ${log}
echo "  LD threshold:  ${clump_r2}" | tee -a ${log}
echo "  Physical distance threshold (Kb): ${clump_kb}" | tee -a ${log}
echo "  Running on chromosomes ${cstart} to ${cstop}" | tee -a ${log}
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "  Requested runtime per chromosome: ${time}" | tee -a ${log}
echo "" | tee -a ${log}  






## +++ Call clump for the chromosomes:  

let i=0
for chrom in  ${chromosomes[*]}     
do
 
  let i++
  
  clump_log="${ident}_${phenoname}_clump_chrom${chrom}.log"	# sbatch log for clump_chr   
  c_ident="CLUMP-${chrom}"

  echo "  sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${clump_log} -e ${clump_log}  \ "  | tee -a ${log}
  echo "  clump_chr  --id ${ident} --chr ${chrom} --phenoname ${phenoname} --genoid ${genoid} --p1 ${clump_p1} --p2 ${clump_p2} --r2 ${clump_r2} --kb ${clump_kb}" | tee -a ${log} 
  
  jobid=$( sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${clump_log} -e ${clump_log}  \
         clump_chr  --id ${ident} --chr ${chrom} --phenoname ${phenoname} --genoid ${genoid} --p1 ${clump_p1} --p2 ${clump_p2} --r2 ${clump_r2} --kb ${clump_kb} )   

  jobid=$( echo $jobid | awk '{print $NF}' ) 
  echo "  JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo "" | tee -a ${log}

  if [ "$i" -eq 1 ]; then
    liste="${jobid}"
  else
    liste="${liste}:${jobid}"  # list of jobid's for all clump_chr.sh jobs
  fi

done   








## +++ Concatenate output files for individual chromosomes:  

# clump_collect_time="10:00"		# moved to ~/clump_settings.sh requested runtime for "clump_collect.sh" 
c_ident="CLMPCOLL"			# jobname SLURM  

collect_log="${ident}_${phenoname}_clump_collect.log"

collect_jobid=$( sbatch --dependency=afterok:${liste} -A ${account} -p ${partition}  -t ${clump_collect_time}  -J ${c_ident} -o ${collect_log} -e ${collect_log} \
       clump_collect --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --out ${signif_file} )  

collect_jobid=$( echo $collect_jobid | awk '{print $NF}' )





## +++ Finish  

echo "" | tee -a ${log} 
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log}
echo "  Table of independent markers being created: ${signif_file}" | tee -a ${log}   # this file is not available at this point (job still in queue)! 
echo "" | tee -a ${log} 
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 
 





