#!/usr/bin/env bash  



# uwe.menzel@medsci.uu.se  




## +++ Hardcoded settings & and defaults 

skip=0






## +++ Command line parameters:   

if [ "$#" -lt 4 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        -f|--file <file>     no default"
  echo "        -c|--col  <int>      no default"
  echo "        -s|--skip <int>               0"    
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
       -s|--skip)
          skip=$2
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

to_test=(file col skip)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (get_col.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done





## +++ Check availability of input file:

  if [ ! -f ${file} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (get_col.sh): Input file '${file}' not found." 
    echo "" | tee -a ${log}
    exit 1 
  fi    






## +++ Extract colum

outfile="${file}_col${col}"


skip=$(( ${skip} + 1 ))

tail -n +${skip} ${file} | awk -v c=${col} '{print $c}' > ${outfile}


# echo -e "\n  ${outfile} \n"

echo ""
ls -l ${outfile}
echo ""









