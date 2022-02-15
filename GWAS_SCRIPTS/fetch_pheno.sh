#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Fetch a phenotype by UKBB field ID:





## +++ Call:
#
# fetch_pheno --field  <fieldID>  --out  <outfile>
#   
# fetch_pheno --field 22009 --out pr_comp.txt     
#
# use search_fieldID first!








## +++ Hardcoded settings & and defaults 

setfile=~/fetch_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (fetch_pheno.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi




 
## +++ Command line parameters (override the settings in $setfile):

prog=$( basename "$0" )

if [ "$#" -lt 4 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -f|--field <integer>     no default"
  echo "         -o|--out   <filename>    no default"  
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
      -i|--field)
          field=$2    
          shift
          ;;
      -o|--out)
          outfile=$2    
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


to_test=(phenofile field  outfile)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (fetch_pheno.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done








## +++ Check field ID 

if [[ ! ${field} =~ ^[0-9]+$ ]];then    # integer number      
  echo ""
  echo  "  ERROR (fetch_pheno.sh): Field identifier is not valid: " ${field} 
  echo  "  	                   Must be integer number"
  echo ""
  exit 1 
fi   







## +++ Check availability of input file, and if the outfile already exists:

if [ ! -f ${phenofile} ]; then
  echo ""    
  echo "  ERROR (fetch_pheno.sh): Phenotype file '${phenofile}' not found." 
  echo "" 
  exit 1 
fi



if [ -f ${outfile} ]; then
  echo ""    
  echo "  WARNING (fetch_pheno.sh): File '${outfile}' already exists. Please choose another filename." 
  echo "" 
  exit 1 
fi








## +++ Modules: 

answ=$( module list  2>&1 | grep R_packages )   
if [ -z "$answ" ];then
  echo ""
  echo -n "  Loadung R modules ..."  
  module load R_packages/3.6.1 
  echo "  Done."
  echo ""
fi






## +++ Get header of the phenotype file: 

rnum=$(( 1 + RANDOM%10000 ))
headerfile="ukbheader_${rnum}.txt"
head -1 ${phenofile} > ${headerfile}  






# Look which column contains the desired field number. Use the corresponding phenofile in fetch_pheno.R then.    

nr_found=0

tag=$( grep _${field}_ ${headerfile} ) 
if [ "${tag}" != "" ];then
  nr_found=$((${nr_found} + 1))
fi


if [ "${nr_found}" -eq 0 ];then
  echo "" 
  echo "  ERROR (fetch_pheno.sh): The field ID ${field} could not be found." 
  echo ""  
  exit 1  
fi

      
echo ""








## +++ Call Rscript 

echo "  fetch_pheno.R  ${phenofile}  ${headerfile}  ${field}  ${outfile}"

fetch_pheno.R  ${phenofile}  ${headerfile}  ${field}  ${outfile}  

echo ""





## +++ Finish 

rm -f  ${headerfile}  ${headerfile2}  ${headerfile3}       

if [ -f ${outfile} ]; then
  ls -l ${outfile}
fi
echo ""
 





















