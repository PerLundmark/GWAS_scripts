#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  



## === LD clumping for single, multiple (or all) phenonames of the current gwas run ===   




## +++ Calling: 

#  run_clump  --id LIV_MULT4      				     # all available phenotypes for this gwas run (read from paramfile)
#
#  run_clump  --id LIV_MULT4  --phenoname liv1,liv2,liv3,liv4,liv5   # selected phenotypes (subset of phenotypes listed in paramfile)
#
#  complete set of command line parameters:
#
#  run_clump  --id LIV_MULT4  --phenoname liv1,liv2,liv3,liv4,liv5  --p1 5e-8  --p2 5e-6  --r2 0.7 --kb 1000  --minutes 10  
#
# 	This script has to be started in the folder containing the gwas results:
#    	e.g. /proj/sens2019016/GWAS_TEST/LIV_MULT2   (if identifier was "LIV_MULT2")  







## +++ Hardcoded settings & and defaults 

shopt -s nullglob 

setfile=~/clump_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings (but not all can be overwritten) 
else
  echo ""
  echo "  ERROR (run_clump.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi





## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -pn|--phenoname <string>       defaults to all gwas results" 
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





## +++ Read remaining parameters from the param file (created in "run_gwas.sh"):
 
paramfile="${ident}_gwas_params.txt"

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (run_clump.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

genoid=$( awk '{if($1 == "genotype_id") print $2}' ${paramfile} )  
cstart=$( awk '{if($1 == "cstart") print $2}' ${paramfile} )  	
cstop=$( awk '{if($1 == "cstop") print $2}' ${paramfile} )  	





## +++ Check if the variables are defined  

to_test=(ident clump_p1 clump_p2 clump_r2 clump_kb partition minutes genofolder genoid cstart cstop minspace sleep_between_pheno)

# "phenoname" is not in this list, can also be read from parameterfile, see below

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (run_clump.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (run_clump.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi





## +++ Get settings file:

cp ${setfile} . 







## +++ Check chromosomes:    

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (run_clump.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			 Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (run_clump.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			 Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

# chromosomes=$( seq ${cstart} ${cstop} )






## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
if [ ${space} -lt ${minspace} ]; then   
    echo "" 
    echo "  Less than ${minspace} disk space available, consider using a different location." 
    echo "" 
    exit 1 
fi 






## +++ If not provided on command line, read phenonames from the parameter file (created in "run_gwas.sh") :
#      in that case, all phenotypes run through gwas will be considered (high workload!) 
 
if [ -z ${phenoname+x} ];then

  echo ""
  echo "  No phenotype names invoked on command line, reading from parameter file."
 
  # paramfile="${ident}_gwas_params.txt"  defined above
  
  if [ ! -s "$paramfile" ]; then
    echo ""
    echo "  ERROR (run_clump.sh): Missing parameter file ${paramfile}"
    echo ""
    exit 1
  fi

  phenoname=$( grep phenoname ${paramfile} | awk '{print $2}' )  # liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10

fi   

pname=$( echo $phenoname | tr -s ',' '\t' ) # liv1 liv2 liv3 liv4 liv5 liv6 liv7 liv8 liv9 liv10 
phenoarray=($pname)
nr_pnames=${#phenoarray[*]}  
echo "" 
echo "  Number of phenotype names: ${nr_pnames}" 






## +++ Check if $phenoname is valid (user input)

# has to be phenoname or a subset of it

paramfile_names=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} ) 
paramfile_names=$( echo $paramfile_names | tr -s ',' '\t' )              
paramfile_array=($paramfile_names)					 

# paramfile_array   # is what is available from gwas
# phenoarray        # is what has been invoked

for pheno in  ${phenoarray[*]} 
do
  nr_hits=$( printf '%s\n' ${paramfile_array[@]} | egrep "^[[:space:]]*${pheno}[[:space:]]*$" | wc -l )
  if [ "${nr_hits}" -ne 1 ];then
    echo "" 
    echo "  ERROR (run_clump.sh): Invoked phenotype name \"${pheno}\" is not valid (check in \"${paramfile}\")"
    echo ""
    exit 1
  fi
done





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









## +++ Header:  no logfile here, clump_pheno logfile is enough 

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 	
echo ""   
START=$(date +%s)      
echo -n "  "  
date 
echo "  Account: ${account}" 
echo -n "  Current working folder: "  
pwd  
echo "  Available disk space in this path: ${spac1}"  
echo "  Job identifier:  ${ident}" 
echo "  Genotype ID: ${genoid}"  
echo "  Phenotype name(s): ${phenoname}" 
echo "  Significance threshold for index markers (p1): ${clump_p1}" 
echo "  Secondary significance threshold for clumped markers (p2): ${clump_p2}" 
echo "  LD threshold:  ${clump_r2}" 
echo "  Physical distance threshold (Kb): ${clump_kb}" 
echo "  Running on chromosomes ${cstart} to ${cstop}" 
echo "" 
echo "  Requested partition: ${partition}" 
echo "  Requested runtime per chromosome: ${minutes} minutes." 
echo ""   







## +++ Check availability of genotype files:

for chrom in  ${chromosomes[*]}     
do

  pgen_prefix=${genofolder}"/"${genoid}"_chr"$chrom   # name must fit to the genotype files listed above (.pgen files)

  psam=${pgen_prefix}".psam"	
  pvar=${pgen_prefix}".pvar"	 
  pgen=${pgen_prefix}".pgen" 	   

  if [ ! -f ${psam} ]; then
    echo "" 
    echo "  ERROR (run_cojo.sh): Input file '${psam}' not found." 
    echo "" 
    exit 1 
  fi  

  if [ ! -f ${pvar} ]; then
    echo "" 
    echo "  ERROR (run_cojo.sh): Input file '${pvar}' not found." 
    echo "" 
    exit 1 
  fi  

  if [ ! -f ${pgen} ]; then
    echo "" 
    echo "  ERROR (run_cojo.sh): Input file '${pgen}' not found." 
    echo "" 
    exit 1 
  fi    

done   

echo "  All required genotype files (.pgen, .pvar, .psam) are available." 
echo ""









## +++ Let the user confirm the choice of parameters if $ask = "y"

if [[ "$ask" =~ ^y+ ]];then  
  nr_nodes=$(( 22*${nr_pnames} ))  # or cores, depending of $partition
  echo ""
  echo "  Clumping with ${nr_pnames} phenotype(s) will start ${nr_nodes} ${partition}s in parallel."  
  echo ""
  # read -p "  Do you want to proceed ? (y/n):" -n 1 -r
  read -p "  Do you want to proceed ? (y/n):"     
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    echo "  Start clumping"; echo
  else
    echo; echo "  Bye."; echo
    exit 0
  fi
fi








## +++ Start a clump for each phenoname:


sleeptime="${sleep_between_pheno}m"

for pheno in  ${phenoarray[*]} 
do
  echo "  clump_pheno --id ${ident} --phenoname  ${pheno} --p1 ${clump_p1} --p2 ${clump_p2} --r2 ${clump_r2} --kb ${clump_kb} --minutes ${minutes}"
  clump_pheno --id ${ident} --phenoname  ${pheno} --p1 ${clump_p1} --p2 ${clump_p2} --r2 ${clump_r2} --kb ${clump_kb} --minutes ${minutes}

  sleep ${sleeptime}

done







## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo ""
echo "  Run time: $DIFF seconds (but we have sent a lot of jobs to the batch)"
echo "" 
echo -n "  " 
date 
echo "  Done." 
echo "" 
 






 

 







 
   

