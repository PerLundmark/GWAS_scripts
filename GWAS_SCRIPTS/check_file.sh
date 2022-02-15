#!/usr/bin/env bash    


# uwe.menzel@medsci.uu.se


## +++ Check consistency of a file (correct number of columns)






## +++ Call:

# check_file --file IN_transformed_liver_fat_ext.txt             # tab-separated
# check_file --file IN_transformed_liver_fat_ext.txt --sep " "   # blank-separated






## +++ Hardcoded settings & and defaults 

separator="\t"  
tempfile="tempisufsd88.txt"





 
## +++ Command line parameters:

prog=$( basename "$0" )


if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -f|--file <filename>      mandatory"
  echo "         -s|--sep <string>         default: tabulator" 
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
       -f|--file)
         file=$2
         shift
         ;;

      -s|--sep)
          separator=$2
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

to_test=(file separator)  

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (check_file): Mandatory variable '$var' is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check if this file can be checked!:

if [ `file ${file} | gawk '{print $2}'` != "ASCII" ];then
  echo ""
  echo "  Sorry, this file does not seem to be in ASCII format."
  echo "  Cannot check this file."
  echo ""
  exit 0
fi







## +++ Blank lines:

num_blank=$( grep -c "^\s*$" ${file})

if [ "$num_blank" -gt "0" ];then
  echo ""
  echo "  The file contains ${num_blank} blank lines."
  echo ""
   
  read -p "  Shall the blank lines be removed? (y/n): "   
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    echo ""
    cat ${file} | sed '/^[[:space:]]*$/d' > ${tempfile}
     mv ${tempfile} ${file}
    echo "  Okay, blank lines have been removed."
    echo ""
  else
    echo ""
    echo "  Okay, leave the file as it is."
    echo ""
  fi
else
  echo ""
  echo "  The file does not contain blank lines."
  echo ""  
fi








## +++ Number of columns

#gawk -v var="${separator}" 'BEGIN{FS=var} {print NF}' ${file} | sort | uniq -c > ${tempfile}
gawk -F"${separator}" '{print NF}' ${file} | sort | uniq -c > ${tempfile}
if [ `wc -l ${tempfile} | gawk '{print $1}'` -ne "1" ];then
  echo ""
  echo "  WARNING: The file seems to have unequal column numbers:"
  cat ${tempfile}
  echo ""
else
  echo ""
  rows=$(gawk '{print $1}' ${tempfile})
  cols=$(gawk '{print $2}' ${tempfile})
  echo "  The file has ${rows} row(s) with ${cols} column(s)."
  echo ""
fi 

rm ${tempfile}






## +++ Check if "plink-format"    #FID	 IID
	
# tag=$( head -1 ${file} | gawk -v var="${separator}" 'BEGIN{FS=var}{if($1 != "#FID" || $2 != "IID") print "nofid"}' )
tag=$( head -1 ${file} | gawk -F"${separator}" '{if($1 != "#FID" || $2 != "IID") print "nofid"}' )

if [ "${tag}" == "nofid" ];then
  echo ""
  echo "  NOTE: The file is not in phenotype/covariate file format (\"#FID   IID\") ... which might be okay."
  echo ""
else
  echo ""
  echo "  NOTE: The file is in phenotype/covariate file format (\"#FID   IID\")"
  echo ""

fi








## +++ Empty fields

if [ "${separator}" == " " ];then  # TODO: doesn't work if the separator os a blank
echo ""
echo "  SORRY: Cannot search for missing elements with this separator."
echo ""
else
  num_empty=$( gawk -F"${separator}" 'BEGIN{sum=0}{for(i=1; i<=NF; ++i) if($i == "") sum+=1} END{print sum}' ${file} ) 
  if [ "$num_empty" -gt "0" ];then
    echo ""
    echo "  WARNING: The file seems to contain ${num_empty} empty field(s)."
    echo ""
  else
    echo ""
    echo "  It seems that the file does not contain any empty fields."
    echo "" 
  fi 
fi 









## +++ Other file info:

size=$( du -h ${file} | gawk '{print $1}' )
echo ""
echo "  File size on disk:  ${size}"
echo "  Last modification:  `date -r ${file}`"
echo ""





