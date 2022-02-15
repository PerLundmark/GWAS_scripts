#!/usr/bin/env bash

# uwe.menzel@medsci.uu.se  



## === Check GWAS results for consistency    






## +++ Call   

# check_gwas --id liver21  --phenoname liver_volume 
# check_gwas --id liver21  # phenoname(s) read from paramfile 
# check_gwas --id liver21 --phenoname liver_volume --comp test.txt  
    # compare modification dates of the logfoiles with this files' modification date, defaults tp paramfile 
    # just enter a non-existing file if the date comparison shall be skipped!

# touch -m -t 10071135 test.txt  # set modification date to a file -t [YY]MMDDhhmm   ... which than can be used as comparison file 

# no sbatch, can also be run in login node







## +++ Hardcoded settings & and defaults 

number_warnings=0
checklog="gwas_check.log"




 
## +++ Command line parameters:

prog=$( basename "$0" )


if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>           mandatory"
  echo "         -p|--phenoname <string>    optional" 
  echo "         -c|--comp <filename>       optional" 
  echo ""
  echo "    If no phenoname is given, it will be inferred from the parameter file."
  echo "    Use '--comp 0' to compare modification date with the parameter file written by run_gwas."  
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

      -p|--phenoname)
          phenoname=$2
          shift
          ;;
      -c|--comp)
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


# TEST: /proj/sens2019016/GWAS_TEST/liver21
# phenoname="liver_volume" # there might be multiple phenonamnes in this folder 
# compfile="test.txt"   






## +++ Check if the variables are defined  

to_test=(ident number_warnings checklog)  

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (check_gwas.sh): Mandatory variable '$var' is not defined."
    echo ""
    exit 1
  fi    
done






## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
echo ""  > ${checklog}
echo ""   | tee -a ${checklog}
echo -n "  "  | tee -a ${checklog}
date | tee -a ${checklog}
echo "  Account: ${account}" | tee -a ${checklog}
echo -n "  Operated by: " | tee -a ${checklog} 
whoami | tee -a ${checklog} 
echo "  Master logfile: ${checklog}" | tee -a ${checklog}
echo "" | tee -a ${checklog}






## +++ Parameter file:

paramfile="${ident}_gwas_params.txt" # "${ident}_gwas_params.txt"  ; see "run_gwas.sh" 

if [ -s "${paramfile}" ];then   
  echo "  Parameterfile '${paramfile}' found." | tee -a ${checklog}
  echo "" | tee -a ${checklog}  
else
  echo "" | tee -a ${checklog}
  echo "  ERROR (check_gwas): No parameterifle '${paramfile}' found." | tee -a ${checklog} 
  echo "" | tee -a ${checklog}
  exit 1
fi





## +++ Phenotype names:

if [ -z ${phenoname+x} ];then 
  echo "  No phenotype name entered - reading from '${paramfile}'" | tee -a ${checklog}
  echo ""   | tee -a ${checklog}  
  phenoname=$( grep phenoname ${paramfile} | awk '{print $2}' )  # paramfile created in "run_gwas.sh"
  pname=$( echo $phenoname | tr -s ',' '\t' )  
  phenoarray=($pname)
  nr_pnames=${#phenoarray[*]} 
else
  allowed=$( grep phenoname ${paramfile} | awk '{print $2}' )  # paramfile created in "run_gwas.sh"
  all2=$( echo $allowed | tr -s ',' '\t' )
  allowed=($all2)
  pname=$( echo $phenoname | tr -s ',' '\t' )  # user input 
  phenoarray=($pname)
  
  for ptype in  ${phenoarray[*]} 
  do
    nr_hits=$( printf '%s\n' ${allowed[@]} | egrep "^[[:space:]]*${ptype}[[:space:]]*$" | wc -l ) 
    if [ "${nr_hits}" -gt 1 ];then
      echo ""
      echo "  ERROR (check_gwas.sh):  Multiple matches for \"${ptype}\" among the allowed phenotypes." 
      echo ""
      exit 1
    fi    

    if [ "${nr_hits}" -eq 0 ];then
      echo ""
      echo "  ERROR (check_gwas.sh): No match for \"${ptype}\" among the allowed phenotypes."
      echo "" 
      exit 1
    fi  
  done  
  
fi

echo "  Phenotype names:" | tee -a ${checklog}
printf '    - %s\n' ${phenoarray[@]} | tee -a ${checklog}
echo ""   | tee -a ${checklog} 






## +++ "Comparison file": 

if [ -z ${compfile+x} ];then 
  echo "  No date comparison will be conducted (no --comp option entered)." | tee -a ${checklog}
  compare=0 
else
  compare=1
  if [ "${compfile}" == "0" ];then 
    compfile="${paramfile}" 
    echo "  Date comparison will be conducted with parameter file '${compfile}'." | tee -a ${checklog}    
  else
     echo "  Date comparison will be conducted with user-defined file '${compfile}'." | tee -a ${checklog}
  fi
  cdate=$( date -r ${compfile})          # Wed Nov 11 14:50:23 CET 2020
  compdate=$( date -r ${compfile} +%s )  # 1604851390  seconds since Jan, 1 1970   
fi 

echo "" | tee -a ${checklog} 

# echo " compare = ${compare}"; exit  # Test







## +++ Chromosomes  

# chromosomes=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # all chromosomes

cstart=$( awk '{if($1 == "cstart") print $2}' ${paramfile} )  	
cstop=$( awk '{if($1 == "cstop") print $2}' ${paramfile} )  	

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo "" | tee -a ${checklog}
  echo  "  ERROR (check_gwas.sh): Start chromosome is not valid: " ${cstart} | tee -a ${checklog} 
  echo  "  			Correct syntax is e.g. --chrom 1-16" | tee -a ${checklog}
  echo "" | tee -a ${checklog}
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo "" | tee -a ${checklog}
  echo  "  ERROR (check_gwas.sh): Stop chromosome is not valid: " ${cstop} | tee -a ${checklog} 
  echo  "  			Correct syntax is e.g. --chrom 1-16" | tee -a ${checklog}
  echo "" | tee -a ${checklog}
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )

echo "  Checking chromosomes ${cstart} to ${cstop}" | tee -a ${checklog}
echo "" | tee -a ${checklog}






## +++ Loop through phenotypes (=phenoarray)   

echo "" | tee -a ${checklog}
echo "  *** Checking for completeness of regression results ***" | tee -a ${checklog}
echo "" | tee -a ${checklog}


for pheno in  ${phenoarray[*]} 
do

  for chrom in  ${chromosomes[*]}     
  do
    echo ""  | tee -a ${checklog}
    echo "  Phenotype: ${pheno}  Chromosome: ${chrom}" | tee -a ${checklog}
    logfile="${ident}_gwas_chrom${chrom}.log"  # "run_gwas.sh" : logchr="${ident}_gwas_chrom${chrom}.log" 
    outf1="${ident}_gwas_chr${chrom}.${pheno}.glm.linear"    
    outf2="${ident}_gwas_chr${chrom}.${pheno}.glm.logistic" 
    
    if [ ! -s "${logfile}" ];then
      echo "    *** WARNING: No logfile found, expecting '${logfile}'." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue
    else
      echo "    -- Logfile: ${logfile}"  | tee -a ${checklog}
    fi
    
    err=$( grep -i error ${logfile} )
    if [ ! -z "$err" ];then 
      echo "" | tee -a ${checklog}
      echo "    *** WARNING: Error messages found in the logfile '${logfile}'." | tee -a ${checklog}
      echo -n "        " | tee -a ${checklog}  
      echo "$err" | tee -a ${checklog}  
      number_warnings=$(( ${number_warnings} + 1 ))
      continue 
    fi
       
    warn=$( grep -i warning ${logfile} )
    if [ ! -z "$warn" ];then 
      echo "    *** WARNING: Warning messages found in the logfile '${logfile}'." | tee -a ${checklog}
      echo -n "        " | tee -a ${checklog}
      echo "$warn" | tee -a ${checklog}            
      number_warnings=$(( ${number_warnings} + 1 ))
      continue 
    fi
    
    if [ "${compare}" -eq "1" ];then
      ldate=$( date -r ${logfile} ) 		# Sun Nov 8 17:03:32 CET 2020
      logdate=$( date -r ${logfile} +%s ) 	# 1604851412
      if [ "$logdate" -lt "$compdate" ]; then 
	echo "    *** WARNING: Logfile (${ldate}) is older than '${compfile}' (${cdate})." | tee -a ${checklog}
	number_warnings=$(( ${number_warnings} + 1 ))
      else
	echo "    -- Logfile (${ldate}) is younger than '${compfile}' (${cdate})." | tee -a ${checklog}
      fi
    fi
    
    if [ -s "${outf1}" -a -s "${outf2}" ];then
      echo "    *** WARNING: Both '${outf1}' and '${outf2}' found." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue
    fi
    if [ ! -s "${outf1}" -a ! -s "${outf2}" ];then
      echo "    *** WARNING: Neither '${outf1}' nor '${outf2}' found." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue
    fi
    if [ -s "${outf1}" ];then
      outfile="${outf1}"
      regtype="linear"
    fi
    if [ -s "${outf2}" ];then
      outfile="${outf2}"
      regtype="logistic"
    fi
    
    # echo "    - Logfile is: ${logfile}" | tee -a ${checklog}
    echo "    -- Regression output: ${outfile}" | tee -a ${checklog}

    message=$( fgrep "variants remaining after" ${logfile} )
    
    if [ -z "$message" ];then
      echo "    *** WARNING: No information regarding number of variants in the logfile." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue 
    fi
    
    tag=$( echo $message | grep -i error )
    if [ ! -z "$tag" ];then 
      echo "    *** WARNING: Faulty information regarding number of variants in the logfile." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue 
    fi
    
    numv_log=$( echo $message | awk '{print $1}' ) 
    if [[ ! ${numv_log} =~ ^[0-9]*$ ]];then   
      echo "    *** WARNING: Missing information regarding number of variants in the logfile." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue 
    fi
            
    numv_out=$( wc -l ${outfile} | awk '{print $1}' )   
    numv_out=$(( ${numv_out} - 1 ))
    echo "    -- Logfile mentions ${numv_log} variants." | tee -a ${checklog}
    echo "    -- Outfile contains ${numv_out} variants." | tee -a ${checklog}
    
    if [ "$numv_log" -ne "$numv_out" ];then
      echo "    *** WARNING: Unequal number of variants in logfile and regression output file." | tee -a ${checklog}
      number_warnings=$(( ${number_warnings} + 1 ))
      continue
    fi

  done  
done    
 
 
 
 
 
## +++ Finish
    
echo ""  | tee -a ${checklog}  
echo "  Total number of warnings: ${number_warnings}"  | tee -a ${checklog}
echo "" | tee -a ${checklog} 
echo "  Logfile is: ${checklog}"
echo ""
echo "  Use 'fgrep WARNING gwas_check.log' to see all warnings." 
echo ""



# fgrep "variants remaining after" liver21_gwas_chrom14.log  # 451616 variants remaining after main filters.
# this works also when multiple phenotypes have been run (all get te same number of variants)











  









 




