#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


## === Concatenate results of plink1.9 clumping   




# called by "clump_pheno.sh" :
#
#  sbatch --dependency=afterok:${liste} -A ${account} -p ${partition}  -t ${ctime}  -J ${c_ident} -o ${collect_log} -e ${collect_log} \
#        clump_collect --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --out ${signif_file} )  

 
 
  
 
## +++ Hardcoded settings & defaults  

shopt -s nullglob 

# no other parameters necessary 






## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 10 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id  <string>          no default" 
  echo "         -pn|--phenoname <string>   no default"  
  echo "         --cstart <chrom>           no default"
  echo "         --cstopt <chrom>           no default"
  echo "         -o|--out <file>            no default"   # output 
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
      --cstart)
          cstart=$2
          shift
          ;;
      --cstop)
          cstop=$2
          shift
          ;;
      -o|--out)
          signif_file=$2  
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

to_test=(ident phenoname cstart cstop signif_file)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (clump_collect.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done







## +++ Header:     output goes to "LIV_MULT4_liv2_clump_collect.log"

echo ""
START=$(date +%s) 
echo -n "  "
date 
echo "  Job identifier: " ${ident}
echo "  Phenotype namn: ${phenoname}"
echo "  Chromosomes:  ${cstart} to ${cstop}"
echo "  Outfile (independent markers): ${signif_file}"   
echo "" 

# signif_file="${ident}_${phenoname}_clump.jma"  # clump_pheno.sh 






## +++ Concatenate chromosomal clump results:

chromosomes=$( seq ${cstart} ${cstop} )

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "CHR" "POS" "OTHER" "A1" "A1_FREQ" "OBS_CT" "BETA" "SE" "P" > ${signif_file} 

for chrom in  ${chromosomes[*]}     
do

  clump_chr_results="${ident}_${phenoname}_chrom${chrom}_results.clumped"  # OBS!! also used in clump_chr.sh   

  if [ -s "${clump_chr_results}" ];then			# no file written if independent signif. markers missing, i.e. we can run through all chromosomes	
    tail -n +2 ${clump_chr_results} >> ${signif_file}  	
  fi
  
  rm -f $clump_chr_results  # new 4.4. 20:28 not tested
  
done








## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"
echo "" 
echo "  Table of independent markers: ${signif_file}" 
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 
 




