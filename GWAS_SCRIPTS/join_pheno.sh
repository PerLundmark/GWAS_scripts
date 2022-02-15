#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## ===  Join two phenotype files (in plink format: #FID IID ....) 





## +++ Check if interactive

tag=$( echo $SLURM_JOB_NAME | grep interactive | wc -l )  

if [ "$tag" -eq "0" ];then
  echo ""
  echo "  Please start in interactive session only."
  echo
  exit 0
fi





## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 6 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -f1|--file1 <filename>    no default"
  echo "         -f2|--file2 <filename>    no default"  
  echo "         -o|--out <filename>       no default"
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
      -f1|--file1)
          f1=$2    
          shift
          ;;
      -f2|--file2)
          f2=$2    
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





## +++ Check if the variables are defined  

to_test=(f1 f2 outfile)    

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (join_pheno.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done






## +++ Modules: 

answ=$( module list  2>&1 | grep R_packages )   
if [ -z "$answ" ];then
  echo -n "  Loadung R modules ..."  
  module load R_packages/3.6.1 
  echo "  Done."
  echo ""
fi




if [ ! -f ${f1} ]; then
  echo ""    
  echo "  ERROR (join_pheno.sh): Phenotype file '${f1}' not found." 
  echo "" 
  exit 1 
fi



if [ ! -f ${f2} ]; then
  echo ""    
  echo "  ERROR (join_pheno.sh): Phenotype file '${f2}' not found." 
  echo "" 
  exit 1 
fi



 
## +++ Programs 
 
prog=$( which join_pheno.R )   
exit_code=$?  
if [ ${exit_code} -ne 0 ]
then
  echo "" 
  echo "  ERROR (join_pheno.sh): Did not find script 'join_pheno.R'." 
  echo ""
fi 




## +++ join_pheno.R
 
echo ""
echo "  join_pheno.R  $f1  $f2  $outfile"  
echo ""

join_pheno.R  $f1  $f2  $outfile


if [ ! -f ${outfile} ]; then
  echo ""    
  echo "  ERROR (join_pheno.sh): No output written. sorry." 
  echo "" 
  exit 1 
fi








## +++ Finish  

echo -n "  Colums: "
gawk 'BEGIN{FS="\t"}{print NF}' $outfile | sort | uniq -c

echo "" 
ls -l $outfile
echo ""
echo "  Done." 
echo "" 
 
 



