#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


## === Call recap_gwas.R  (the "lite" version of review_gwas ) ====  






## +++ Calling
 
# recap_gwas --id LIV_MULT5 --phenoname liv2,liv5,liv10,liv4 --pval 5e-8    #  /castor/project/proj/GWAS_DEV/PRESENTATION/C/LIV_MULT5
#
# does NOT run in SLURM  





## +++ Default settings

pval="5e-8" 	# only important id neither cojo nor clump was run  



 
## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then    
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -pn|--phenoname <string>       parameter file entry"
  echo "         -p|--pval <real>               5e-8"
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
      -p|--pval)
          pval=$2
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







## +++ Read remaining parameters from the param files (created in "run_gwas.sh"):
 
paramfile="${ident}_gwas_params.txt"

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (recap_gwas.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

cstart=$( awk '{if($1 == "cstart") print $2}' ${paramfile} )  	
cstop=$( awk '{if($1 == "cstop") print $2}' ${paramfile} )  	






## +++ Check if the variables are defined  

to_test=(ident pval cstart cstop)    

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (recap_gwas.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done





## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (recap_gwas.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi





## +++ Check chromosomes:    

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (recap_gwas.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (recap_gwas.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

# chromosomes=$( seq ${cstart} ${cstop} )






## +++ If not provided on command line, read phenonames from the parameter file (created in "run_gwas.sh") :
#    in that case, all phenonames run through gwas will be considered (high workload!) 
 
if [ -z ${phenoname+x} ];then

  echo ""
  echo "  No phenotype names invoked on command line, reading from parameter file."
 
  # paramfile="${ident}_gwas_params.txt"  # defined above
  
  if [ ! -s "$paramfile" ]; then
    echo ""
    echo "  ERROR (recap_gwas.sh): Missing parameter file ${paramfile}"
    echo ""
    exit 1
  fi

  phenoname=$( grep phenoname ${paramfile} | awk '{print $2}' )  

fi   

pname=$( echo $phenoname | tr -s ',' '\t' )  
phenoarray=($pname)
nr_pnames=${#phenoarray[*]} 
echo  
echo "  Number of phenotype names: ${nr_pnames}" 





## +++ Check if $phenoname is valid (user input)

paramfile_names=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} ) 
paramfile_names=$( echo $paramfile_names | tr -s ',' '\t' )              
paramfile_array=($paramfile_names)					 

for pheno in  ${phenoarray[*]} 
do
  nr_hits=$( printf '%s\n' ${paramfile_array[@]} | egrep "^[[:space:]]*${pheno}[[:space:]]*$" | wc -l )
  if [ "${nr_hits}" -ne 1 ];then
    echo "" 
    echo "  ERROR (recap_gwas.sh): Invoked phenotype name \"${pheno}\" is not valid (check in \"${paramfile}\")"
    echo ""
    exit 1
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





## +++ Start recap for each phenotype

for pheno in  ${phenoarray[*]} 
do
  file_list="${ident}_${pheno}_files.txt"  	
  recap_gwas.R ${ident}  ${pheno}  ${cstart}  ${cstop}  ${pval}  ${file_list}
done
echo ""





## +++ Finish

echo ""
echo "  Lists with important files:"
echo ""
for pheno in  ${phenoarray[*]} 
do
  file_list="${ident}_${pheno}_files.txt"  	
  ls -l ${file_list}
done
echo ""















