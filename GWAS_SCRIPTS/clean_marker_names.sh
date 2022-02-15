#!/usr/bin/env bash 


# uwe.menzel@medsci.uu.se  


## === Clean marker names in a file, e.g. rs578081284_A_G ==> rs578081284   




## +++ Calling:

# /castor/project/proj_nobackup/GWAS_TEST/liver18
# interactive -n 16 -t 6:00:00 -A sens2019016
# clean_marker_names   --file  test.linear --col 3 



## +++ Hardcoded settings & and defaults   

# none




   

 
## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 4 ]; then
  echo ""
  echo "  Usage: ${prog}" 
  echo "         -f|--file <filename>  no default"   
  echo "         -c|--col  <integer>   no default" 
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
      -c|--col)
          col=$2
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

to_test=(file col)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (clean_marker_names): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check column number  

if [[ ! ${col} =~ ^[1-9]+$ ]];then    # two-digit number       
  echo ""
  echo  "  ERROR (clean_marker_names): Column number is not valid: ${col}" 
  echo  "  			      Correct syntax is e.g. --col 3"
  echo ""
  exit 1 
fi   





## +++ Check availability of input file:

if [ ! -s ${file} ]; then
  echo ""
  echo "  ERROR (clean_marker_names): Input file '${file}' not found."
  echo ""
  exit 1 
fi 







## +++ Remove alleles in column $col:

outfile="${file}.mod"

head -1 ${file} > temp9255.txt

tail -n +2  $file | awk -v c=${col} '{$c = substr($c,1,match($c,"_")-1); print}' >> temp9255.txt

cat temp9255.txt | tr -s ' ' '\t' > ${outfile}

rm temp9255.txt

echo ""
ls -l ${outfile}
echo ""



















