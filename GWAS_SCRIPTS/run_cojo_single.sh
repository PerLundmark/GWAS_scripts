#!/usr/bin/env bash
  

# uwe.menzel@medsci.uu.se  



## === LD pruning using GCTA-COJO for single, multiple (or all) phenonames of the current gwas run ===    
#      ... but for a SINGLE chromosome ONLY !!!   


## OBS!  Precondition: the *.ma file (summary statistics for all chromosomes) must be available ! (run_cojo with --keepma option or just run cojo_collect) 






## +++ Calling: 

#  run_cojo_single  --id LIV_MULT2  --chr 22    				     # all phenonames for this gwas run (read from paramfile)
#
#  run_cojo_single  --id LIV_MULT2  --chr 22  --phenoname liv1,liv2,liv3,liv4,liv5   # selected phenonames (subset of phenonames listed in paramfile)
#
#  with all command line parameters:
#
#  run_cojo_single  --id LIV_MULT2  --chr 22  --phenoname liv1,liv2,liv3,liv4,liv5 --pval 5e-8  --window 5000  --colline 0.5 --maf 0.01  --minutes 100 --ask y
#
# 	This script has to be started in the folder containing the gwas results:
#    	e.g. /proj/sens2019016/GWAS_TEST/liver10   (if identifier was "liver10")  







## +++ Hardcoded settings & and defaults 

shopt -s nullglob 

setfile=~/cojo_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings (but not all can be overwritten) 
else
  echo ""
  echo "  ERROR (run_cojo_single.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi



## +++ # GCTA-COJO settings (command line paramters overwrite these settings):  
# 
#
# # this file is sourced by  run_cojo, cojo_pheno,  cojo_chr,  cojo_convert, cojo_clean   
# 
# 
# # genofolder="/proj/sens2019016/GENOTYPES/PGEN" # .pgen does not work, see mail Zhili 19/02/2020 
# genofolder="/proj/sens2019016/GENOTYPES/BED"    # location of genotype files, (unique marker names)   .bed .bim .fam
# 
# window=5000					# (5MB) cojo assumes that markers outside this window are independent 
# pval=5.0e-8					# p-value threshold for genome-wide significance 
# collinearity=0.01				# --cojo-collinear parameter (gcta64 command), see https://cnsgenomics.com/software/gcta/#COJO
# maf=0.01  					# disabled in the script (gcta64 command) (can also be conducted by plink2 in run_gwas) 
# 
# skip_chrom=1					# skip chromosomes with none or only one sign. marker (above maf cutoff) (creates NA in the output)
# keepma=0					# keep the .ma file (summary statistics for all chromosomes, ~500 MB), intsead of deleting in cojo_clean
# 
# sleep_between_pheno=0             		# sleep that many minutes before a new phenotype is started (prevents from using too many nodes simultaneously) 
# 
# partition="node"    				# "node" or "core"  (rather not "core")
# minutes=100	    				# requested runtime for each chromosome in minutes (60 minutes where not enough for chr 2)
# minspace=100000000  				# 100 MByte    minimum required free disk space 
# ask="y"						# Ask the user for confirmation of the input parameters. We might start many jobs (25 nodes per phenoname)
# 
# cojo_convert_time="20:00" 			# runtime requested for "cojo_convert", used in cojo_pheno 
# cojo_collect_time="10:00"			# runtime requested for "cojo_collect" , used in cojo_pheno
# cojo_clean_time="10:00"				# runtime requested for "cojo_clean.sh", used in cojo_pheno   
# 
# 
# ## Alternative genotype dataset to be used as refence in cojo: 
# # Outcomment the following line if the default genotype files are to be used! 
# # Default = same genotype files as used in gwas. Default is read from parameter file. 
# alt_genoid="FTD_rand"				# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD  







 
## +++ Programs 
 
prog=$( which gcta64 )   
exit_code=$?  
if [ ${exit_code} -ne 0 ]
then
  echo "" 
  echo "  ERROR (run_cojo_single.sh): Did not find the script ' gcta64 '." 
  echo ""
fi 






## +++ Command line parameters:   

if [ "$#" -lt 4 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -c|--chr <int>                 no default"  
  echo "         -pn|--phenoname <string>       defaults to all gwas results"
  echo "         -p|--pval <real>               ${setfile}"
  echo "         -w|--window <integer>          ${setfile}" 
  echo "         -cl|--colline <real>           ${setfile}"
  echo "         --maf <real>                   ${setfile}"    
  echo "         -m|--minutes <int>             ${setfile}"
  echo "         --ask <y|n>                    ${setfile}"     # because 25 nodes per phenotype name are used
  echo "         --inter                        interactive mode"   
  echo ""
  exit 1
fi


inter=0   # default: run in SLURM, can only be overwritten on command line

while [ "$#" -gt 0 ]
do
  case $1 in
       -i|--id)
          ident=$2
          shift
          ;;
      -c|--chr)
          chrom=$2
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
      -w|--window)
          window=$2
          shift
          ;;
      -cl|--colline)
          collinearity=$2
          shift
          ;;
      --maf)
          maf=$2
          shift
          ;;	  	  	  
      -m|--minutes)
          minutes=$2
          shift
          ;;
      --ask)
          ask=$2
          shift
          ;;
      --inter)
	inter=1
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
  echo "  ERROR (run_cojo_single.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

genoid=$( awk '{if($1 == "genotype_id") print $2}' ${paramfile} )  
cstart=$chrom  	
cstop=$chrom  	








## +++ Check if the variables are defined  

to_test=(ident pval window collinearity maf partition minutes ask genoid chrom cstart cstop minspace sleep_between_pheno inter)

# "phenoname" can also be read from parameterfile, see below

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (run_cojo_single.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (run_cojo_single.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi








## +++ Check chromosome name  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then    # autosomes only!       
  echo ""
  echo  "  ERROR (run_cojo_single.sh): Chromosome name is not valid: " ${chrom} 
  echo  "  			       Correct syntax is e.g. --chr 22"
  echo ""
  exit 1 
fi   










## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  
spac1=$( df -h . | tail -1 | awk '{print $4}' )  
if [ ${space} -lt ${minspace} ]; then   
    echo "" 
    echo "  Less than ${minspace} disk space available, consider using a different location." 
    echo "" 
    exit 1 
fi 







## +++ If not provided on command line, read phenonames from the parameter file (created in "run_gwas.sh") :
#    in that case, all phenonames run through gwas will be considered (high workload!) 
 
if [ -z ${phenoname+x} ];then

  echo ""
  echo "  No phenotype names invoked on command line, reading from parameter file."
 
  # paramfile="${ident}_gwas_params.txt"  # defined above
  
  if [ ! -s "$paramfile" ]; then
    echo ""
    echo "  ERROR (run_cojo_single.sh): Missing parameter file ${paramfile}"
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

# has to be phenoname or a subset of it

paramfile_names=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} ) 
paramfile_names=$( echo $paramfile_names | tr -s ',' '\t' )              
paramfile_array=($paramfile_names)					 

# paramfile_array   # is what is available from gwas
# phenoarray        # is what has been invoked

for pheno in  ${phenoarray[*]} 
do
  nr_hits=$( printf '%s\n' ${paramfile_array[@]} | egrep "^[[:space:]]*${pheno}[[:space:]]*$" | wc -l )
  if [ "${nr_hits}" -ne 1 ];then
    echo "" 
    echo "  ERROR (run_cojo_single.sh): Invoked phenotype name \"${pheno}\" is not valid (check in \"${paramfile}\")"
    echo ""
    exit 1
  fi
done








## +++ Check if the global summary file is available for all phenonames provided (read from paramfile or given on command line)

# OBS!! If a single chromosome is run, the summary statistics must already be available - which is not necessary for run_cojo.sh) 

# see cojo_pheno.sh
# ${summary_file} = summary statistics for all chromosomes (*.ma), created in cojo_convert.sh
# summary_file="${ident}_${phenoname}_cojo.ma"   # output of "cojo_convert.sh", input for "cojo_chr.sh": summary statistics for all chromosomes 

# in this script, phenoname might be a comma-separated list, e.g. --phenoname liv1,liv2,liv3,liv4,liv5

# TEST:  phenoname="liv1,liv2,liv3"   		# /castor/project/proj/GWAS_DEV/LIV_MULT5
# TEST:  phenoname="liv1,liv2,liv3,liv4"   	# /castor/project/proj/GWAS_DEV/LIV_MULT5

phename_array=$( echo $phenoname | tr -s ',' '\t' )	# liv1 liv2 liv3 

echo "" 
for pheno in  ${phename_array[*]} 
do
  
  summary_file="${ident}_${pheno}_cojo.ma" 
  
  if [ -f ${summary_file} ]; then
    echo "  Summary statistics file for genotype ${pheno} (' ${summary_file} ') found."
    nr_entries=$( wc -l ${summary_file} | awk '{print $1}')
    nr_entries=$((${nr_entries} - 1))
    echo "    File contains ${nr_entries} markers." 
  else
    echo ""
    echo "  ERROR (run_cojo_single.sh): Summary statistics file for genotype ${pheno} (' ${summary_file} ') not available." 
    echo "        Did you run ' run_cojo ' with --keepma OR ' cojo_convert ' in standalone mode ?"
    echo ""
    exit 1 
  fi  
 
done
echo "" 








## +++ Check if alternative genotype files were provided (here, just for the logfile)

# in ~/cojo_settings.sh 
# alt_genoid="FTD_rand"		# alternative genotype dataset. FTD_rand: a random sample of 10.000 participants from FTD

if [ -z ${alt_genoid} ];then    # -z does NOT exist 
  echo ""
  echo "  No alternative genotype ID defined. Using \"${genoid}\" read from \"${paramfile}\""
  echo ""
else
  echo ""
  genoid=${alt_genoid}
  echo "  An alternative genotype ID was defined: \"${genoid}\" read from \"${paramfile}\""
  echo ""
fi    







## +++ Header:   no logfile here, cojo_pheno logfile is enough     

START=$(date +%s)  
echo "  Job identifier:  ${ident}" 
echo "  Genotype input folder: ${genofolder}" 
echo "  Genotype identifier: ${genoid}"  
echo "  Phenotype name(s): ${phenoname}" 
echo "  GCTA-COJO window (kB): ${window}" 
echo "  GCTA-COJO p-value: ${pval}" 
echo "  GCTA-COJO collinearity threshold: ${collinearity}"
echo "  GCTA-COJO minor allele freq threshold: ${maf}" 
echo "  Running on chromosom ${chrom}" 
echo "  Requested partition: ${partition}" 
echo "  Requested runtime per chromosome: ${minutes} minutes." 
echo "" 








## +++ Check availability of genotype files:


pgen_prefix=${genofolder}"/"${genoid}"_chr"$chrom       # name must fit to the genotype files listed above (.pgen files)

bed=${pgen_prefix}".bed"	
bim=${pgen_prefix}".bim"	 
fam=${pgen_prefix}".fam" 	   

if [ ! -f ${bed} ]; then
  echo "" 
  echo "  ERROR (run_cojo_single.sh): Input file '${bed}' not found." 
  echo "" 
  exit 1 
fi  

if [ ! -f ${bim} ]; then
  echo "" 
  echo "  ERROR (run_cojo_single.sh): Input file '${bim}' not found." 
  echo "" 
  exit 1 
fi  

if [ ! -f ${fam} ]; then
  echo "" 
  echo "  ERROR (run_cojo_single.sh): Input file '${fam}' not found." 
  echo "" 
  exit 1 
fi    

echo "  All required genotype files (.bed, .bim, .fam) are available."  









## +++ Let the user confirm the choice of parameters if $ask = "y"

if [[ "$ask" =~ ^y+ ]];then  
  nr_nodes=$(( 25*${nr_pnames} ))  # or cores, depending of $partition
  echo ""
  echo "  Pruning with ${nr_pnames} phenotype(s) will start ${nr_nodes} ${partition}s in parallel."  
  echo ""
  #read -p "  Do you want to proceed ? (y/n):" -n 1 -r 
  read -p "  Do you want to proceed ? (y/n):"     
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    echo "  Starting COJO"; echo
  else
    echo; echo "  Bye."; echo
    exit 0
  fi
fi








## +++ Start a cojo for each phenoname:

sleeptime="${sleep_between_pheno}m"


if [ "$inter" -eq 0 ];then   # A) SLURM: submit sbatch command 

  for pheno in  ${phenoarray[*]} 
  do
    echo "  cojo_pheno_single --id ${ident} --chr ${chrom} --phenoname  ${pheno} --pval ${pval}  --window ${window} --colline ${collinearity} --maf ${maf} --minutes ${minutes}"
    cojo_pheno_single --id ${ident} --chr ${chrom} --phenoname  ${pheno} --pval ${pval}  --window ${window} --colline ${collinearity} --maf ${maf} --minutes ${minutes}

    sleep ${sleeptime}
  done

else  # B) NO SLURM:    #  DO FIRST: interactive -n 16 -t 2:00:00 -A sens2019016  

  for pheno in  ${phenoarray[*]} 
  do
    echo "  cojo_pheno_single --id ${ident} --chr ${chrom} --phenoname  ${pheno} --pval ${pval}  --window ${window} --colline ${collinearity} --maf ${maf} --minutes ${minutes} --inter"
    cojo_pheno_single --id ${ident} --chr ${chrom} --phenoname  ${pheno} --pval ${pval}  --window ${window} --colline ${collinearity} --maf ${maf} --minutes ${minutes} --inter

    sleep ${sleeptime}
  done

fi

#   Starting COJO
# 
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv1 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv2 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv3 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100
# 
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv1 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv2 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter
#   cojo_pheno_single --id LIV_MULT5 --chr 3 --phenoname  liv3 --pval 5.0e-8  --window 5000 --colline 0.01 --maf 0.01 --minutes 100 --inter




## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo ""
echo "  Run time: $DIFF seconds"
echo "" 
echo -n "  " 
date 
echo "  Done." 
echo "" 
 
 
















