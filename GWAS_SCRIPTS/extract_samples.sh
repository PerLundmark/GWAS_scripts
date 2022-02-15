#!/usr/bin/env bash    



# uwe.menzel@medsci.uu.se 



## === Extract samples from the genotype files but keep all variants 





## +++ Call:
#
# extract_samples --genoid MF    --new_genoid MF2   --sfile MRI_IDs_21.txt





## +++ Hardcoded settings & and defaults 

setfile=~/extract_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (extract_samples.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi

# ~/extract_settings.sh :
#
# chrom="1-22"						# all autosomes (entering a single chromosome is ok, X,Y not working)
# partition="node"   					# partition , "core"  might run out of memory 
# minutes=20						# requested runtime for each chromosome in minutes
# minspace=10000000   					# 10 MB  minimum required disk space for regression output
# plink2_version="plink2/2.00-alpha-2-20190429"   	# search for other versions using " module spider plink2 "   
# #genofolder="/proj/sens2019016/GENOTYPES/PGEN" 	# location of input genotype dataset; .pgen location
# genofolder="/proj/sens2019016/GENOTYPES/BED" 		# location of input genotype dataset; .bed location
# #genofolder="."   					# location of input genotype dataset. Here: folder where the script is started from 







 
## +++ Command line parameters (override the settings in $setfile):

prog=$( basename "$0" )

if [ "$#" -lt 6 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -g|--genoid <string>           no default"
  echo "         -n|--new_genoid                no default"
  echo "         -s|--sfile <file>              no default"  
  echo "         -c|--chr <int>[-<int>]         ${setfile}"  
  echo "         -m|--minutes <int>             ${setfile}"
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
      -g|--genoid)
          genoid=$2    
          shift
          ;;
      -n|--new_genoid)
          new_genoid=$2    
          shift
          ;;	  
      -s|--sfile)
          sfile=$2    
          shift
          ;;	    
      -c|--chr)
          chrom=$2
          shift
          ;;
      -m|--minutes)
          minutes=$2
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






## +++ Check if the variables are defined (including those defined in the settings file)    

to_test=(genoid new_genoid sfile chrom minutes partition minspace plink2_version genofolder)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (extract_samples.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Chromosomes  

# chromosomes=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # all chromosomes
      
cstart=$( echo $chrom | cut -d'-' -f 1 )
cstop=$( echo $chrom | cut -d'-' -f 2 )

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (extract_samples.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			       Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (extract_samples.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			       Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )





 
## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
log="${genofolder}/${genoid}_${new_genoid}_extract.log"   # master logfile , saved in genofolder
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Running on chromosomes $cstart to $cstop" | tee -a ${log}  
echo "  Genotype input folder: ${genofolder}"  | tee -a ${log}
echo "  Genotype identifier: " ${genoid} | tee -a ${log}
echo "  New genotype identifier: " ${new_genoid} | tee -a ${log}
echo "  Samples to extract: ${sfile}"  | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "" | tee -a ${log}






## +++ Check available disk space:

echo -n "  Current working folder: " | tee -a ${log}
pwd | tee -a ${log}
space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
echo "  Available disk space in this path: ${spac1}" | tee -a ${log}
echo "" | tee -a ${log}
if [ ${space} -lt ${minspace} ]; then   # 1 TByte 
    echo "" | tee -a ${log}
    echo "  Less than ${minspace} free disk space, consider using a different location." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
fi 







## +++ Check availability of input files and genotype files:

#    Note that we might have .pgen or .bgen as input
#      genofolder="/proj/sens2019016/GENOTYPES/PGEN" 	# location of input genotype dataset; .pgen location
#      genofolder="/proj/sens2019016/GENOTYPES/BED" 	# location of input genotype dataset; .bed location
#      genofolder="."                                   # here, we expect .bgen or -bgen in the current folder 

nr_found=0

pgentag=$( ls ${genofolder}/${genoid}*.pgen 2>/dev/null )
if [ "${pgentag}" != "" ];then
  nr_found=$((${nr_found} + 1))
  gtype="PGEN"
fi

bedtag=$( ls ${genofolder}/${genoid}*.bed 2>/dev/null )
if [ "${bedtag}" != "" ];then
  nr_found=$((${nr_found} + 1))
  gtype="BED"
fi

if [ "${nr_found}" -eq 0 ];then
  echo "" | tee -a ${log} 
  echo "  ERROR (extract_samples.sh): The folder ${genofolder} contains neither appropiate .pgen nor .bed genotype data." | tee -a ${log}
  echo "" | tee -a ${log} 
  exit 1  
fi

if [ "${nr_found}" -eq 2 ];then
  echo ""
  echo "  ERROR (extract_samples.sh): The folder ${genofolder} contains both .pgen and .bed genotype data." | tee -a ${log}  
  echo "                              Don't know what to do." | tee -a ${log} 
  echo "" | tee -a ${log} 
  exit 1
fi
      
echo "  Detected genotype: ${gtype}"  | tee -a ${log}
echo
 


if [ "${gtype}" == "PGEN" ];then

  for chrom in  ${chromosomes[*]}     
  do

    pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # name must fit to the genotype files listed above (.pgen files)

    psam=${pgen_prefix}".psam"  
    pvar=${pgen_prefix}".pvar"	
    pgen=${pgen_prefix}".pgen"	  

    if [ ! -f ${psam} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${psam}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi  

    if [ ! -f ${pvar} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${pvar}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi  

    if [ ! -f ${pgen} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${pgen}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi	 

  done	

  echo "  All required genotype files (.pgen, .pvar, .psam) are available."  | tee -a ${log}
  
fi



if [ "${gtype}" == "BED" ];then

  for chrom in  ${chromosomes[*]}     
  do

    pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # name must fit to the genotype files listed above (.bed files)

    bed=${pgen_prefix}".bed"  
    bim=${pgen_prefix}".bim"	
    fam=${pgen_prefix}".fam"	  

    if [ ! -f ${bed} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${bed}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi  

    if [ ! -f ${bim} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${bim}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi  

    if [ ! -f ${fam} ]; then
      echo "" | tee -a ${log}
      echo "  ERROR (extract_samples.sh): Input file '${fam}' not found." | tee -a ${log}
      echo "" | tee -a ${log}
      exit 1 
    fi	 

  done	

  echo "  All required genotype files (.bed, .bim, .fam) are available."  | tee -a ${log}
  
fi

echo "" | tee -a ${log}

# sample file (${sfile})

if [ ! -f ${sfile} ]; then
  echo "" | tee -a ${log}   
  echo "  ERROR (extract_samples.sh): Input file '${sfile}' not found." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
else
  nr_entries=$( wc -l ${sfile} | awk '{print $1}' )
  echo "  The sample file has ${nr_entries} entries." | tee -a ${log}
fi  


# check sfile format (a little bit) 

# https://www.cog-genomics.org/plink/1.9/filter
# --keep accepts a space/tab-delimited text file with family IDs in the first column and within-family IDs in the second column, 
# and removes all unlisted samples from the current analysis. 
# --remove does the same for all listed samples.
# see MRI_IDs.txt 
# > head -3 MRI_IDs.txt
# 1000015 1000015
# 1000180 1000180
# 1000401 1000401

nr_fields=$( gawk 'BEGIN{FS="\t"}{print NF}' ${sfile} | sort | uniq -c | awk '{print $2}' )  
if [ "${nr_fields}" != "2" ];then
  echo "" | tee -a ${log}  
  echo "  ERROR (extract_samples.sh): Input file '${sfile}' must have two columns: FID and IID." | tee -a ${log}
  echo "" | tee -a ${log}
  exit 1 
fi

echo "" | tee -a ${log}







## +++ Convert the time string for sbatch command below:

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"    # time for a single chromosome to run
fi  
# echo "  Requested runtime for each chromosome: ${time}"     
# echo "" 








## +++ Run through chromosomes 

for chrom in  ${chromosomes[*]} 
do
     
  logchr="${genofolder}/${genoid}_${new_genoid}_extract_chrom${chrom}.log"   
  c_ident="XTRCT-${chrom}"  		# unique jobID for each batch job
  			
  echo "sbatch -A ${account} -p ${partition} -t ${time} -J ${c_ident} -o ${logchr} -e ${logchr} \ "  | tee -a ${log}    
  echo "        extract_samples_chr --genoid ${genoid} --new_genoid ${new_genoid} --gtype ${gtype} --sfile ${sfile} --chr ${chrom}"  | tee -a ${log} 
  
  jobid=$( sbatch -A ${account} -p ${partition} -t ${time} -J ${c_ident} -o ${logchr} -e ${logchr} \
        extract_samples_chr --genoid ${genoid} --new_genoid ${new_genoid} --gtype ${gtype} --sfile ${sfile} --chr ${chrom} )
  
  jobid=$( echo $jobid | awk '{print $NF}' )
  echo "         JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo "" | tee -a ${log}	  
   
done  

# extract_samples_chr.sh :
# 
#   echo "         -g|--genoid <string>           no default"
#   echo "         -n|--new_genoid <string>       no default"  
#   echo "         -t|--gtype                     no default"
#   echo "         -s|--sfile <file>              no default"  
#   echo "         -c|--chr <int>                 no default"  






## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
# echo "  Run time: $DIFF seconds"| tee -a ${log}  # the main script just submits jobs, takes only a few seconds
echo "" | tee -a ${log}
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 











