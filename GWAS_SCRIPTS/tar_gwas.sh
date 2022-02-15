#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  

 
## === tar gwas project (--> .tar.gz)






## +++ Calling:
#
# called by 'archive_gwas.sh' : 
#
# sbatch -A ${account} -p ${partition} -t ${time}  -J ${c_ident} -o ${logf} -e ${logf}  tar_gwas  --id ${ident}








## +++ Hardcoded settings & and defaults 

setfile=~/archive_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (archive_gwas.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi






 
## +++ Command line parameters (override the settings in $setfile):

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
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

to_test=(ident)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (tar_gwas.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done







## +++ Header:        

START=$(date +%s)
echo ""
echo -n "  "
date   
echo "  Job identifier:  ${ident}" 
echo "  Requested partition: ${partition}" 
echo "  Requested runtime: ${minutes} minutes." 
echo "  Delete-folder option: ${delete_folder}"
echo "" 








## +++ Compress

tar -czvf ${ident}.tar.gz ${ident}  
echo ""


if [ -s "${ident}.tar.gz" ];then
  echo ""
  ls -lh ${ident}.tar.gz 
  echo ""
  if [ "${delete_folder}" -eq 1 ];then
    rm -r ${ident}
    echo "  Folder ${ident} deleted."
    echo ""
  fi
else
  echo ""
  echo "  ERROR (tar_gwas.sh): No archive created."
  echo ""
  exit 1
fi  




## +++ Finish

echo ""
echo "  Uncompress with \" retrieve_gwas \""
echo ""
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"
echo ""
echo "  Done."
echo "" 








