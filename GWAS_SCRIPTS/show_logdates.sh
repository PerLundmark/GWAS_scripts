#!/usr/bin/env bash

# uwe.menzel@medsci.uu.se  



## === Show the modification dates of the logfiles, identify logfiles older than the file invoked (e.g. the paramfile)





## +++ Call

# show_logdates                                    # don't compare with modification date of file
# show_logdates --comp cats_gwas_params.txt  






## +++ Hardcoded settings & and defaults 

datelog="show_logdates.log"
echo > ${datelog}
 
 
 
 
## +++ Command line parameters:

prog=$( basename "$0" )

if [[ "$1" =~ ^-+h.*$ ]];then  # --hekp ; --h ; -help -h  works
  echo ""
  echo "  Usage: ${prog}  [--comp  <filename>]"
  echo ""
  exit 0
fi


echo ""
if [ "$#" -eq "0" ]; then
  compare=0
else
  compare=1   # compare with the modification date of some file to invoke 
  if [ "$#" -ne "2" ]; then
    echo "  Usage: ${prog}  [--comp  <filename>]"
    echo ""
    exit 1
  fi 
fi


while [ "$#" -gt 0 ]
do
  case $1 in
      --comp)
        compfile=$2
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


echo ""






## +++ Check file to compare with

if [ "$compare" -eq "1" ];then
  if [ ! -s "$compfile" ]; then
    echo ""  
    echo "  ERROR (show_logdates.sh): Missing file '${compfile}'." 
    echo "" 
    exit 1
  else
    echo "  Comparing with date of last modification of '${compfile}'." | tee -a ${datelog}
    compd=$( date -r ${compfile} )
    echo "       ( ${compd} )"  | tee -a ${datelog}
  fi
else
  echo "  No file to compare invoked - just showing modification dates." | tee -a ${datelog}   
fi

echo "" | tee -a ${datelog}





## +++ Loop through logfiles
   
logfiles=$( ls *.log )
logarray=($logfiles)     			
   		

for log in  ${logarray[*]} 
do
  if [ "$log" == "$datelog" ];then
    continue
  fi
  echo "  -- Logfile: ${log}"  | tee -a ${datelog} 
  dat=$( date -r ${log} )
  echo "       Last modification: ${dat}" | tee -a ${datelog}
  if [ "$compare" -eq "1" ];then
    cdate=$( date -r ${compfile} +%s )  # that's the number of seconds since JAn, 1 1970 
    ldate=$( date -r ${log} +%s )
    if [ "$ldate" -gt "$cdate" ];then
      echo "       The logfile is YOUNGER than '${compfile}'." | tee -a ${datelog}
    else
      echo "       The logfile is OLDER than '${compfile}'." | tee -a ${datelog}    
    fi
  fi 
  echo "" | tee -a ${datelog} 
done 





## +++ Summary 

if [ "$compare" -eq "1" ];then
  num_younger=$( fgrep YOUNGER ${datelog} | wc -l )
  num_older=$( fgrep OLDER ${datelog} | wc -l )

  echo ""  | tee -a ${datelog}
  echo "  Number of logfiles younger than ' ${compfile}': ${num_younger}" | tee -a ${datelog}
  echo "  Number of logfiles older than ' ${compfile}': ${num_older}" | tee -a ${datelog}
  echo "" | tee -a ${datelog}
fi
echo ""
echo "  Logfile is: '${datelog}'"
echo ""





