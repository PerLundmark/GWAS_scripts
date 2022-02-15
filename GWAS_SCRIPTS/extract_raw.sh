#!/usr/bin/env bash  



# uwe.menzel@medsci.uu.se  

  
   
## ===  Extract the genotype data for a list of markers and a list of samples from .pgen using plink2 




# Call:
#
# pwd #/proj/sens2019016/GWAS_TEST/
#
# extract_raw  --samples sample_list.txt --markers marker_list.txt  --out test    		# searches the chromosomes given in settings file
# extract_raw  --samples sample_list.txt --markers marker_list.txt --out test --genoid  FTD    	# extracts from FTD dataset only 
# extract_raw  --samples sample_list.txt --markers marker_list.txt --out test  --chr 19        	# searches only chrom 19










## +++ Hardcoded settings & and defaults 

setfile=~/extract_raw_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (extract_raw.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi








## +++ Command line parameters:   

if [ "$#" -lt 6 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        -s|--samples <file>          no default"
  echo "        -m|--markers <file>          no default"
  echo "        -o|--out <file>              no default"
  echo "        -c|--chr <int>               ${setfile}"  
  echo "        -g|--genoid <string>         ${setfile}"    
  echo ""
  exit 1
fi


while [ "$#" -gt 0 ]
do
  case $1 in
       -s|--samples)
          samples=$2
          shift
          ;;
       -m|--markers)
          markers=$2
          shift
          ;;
       -o|--out)
          outfile=$2
          shift
          ;;
       -c|--chr)
          chrom=$2
          shift
          ;;
       -g|--genoid)
          genoid=$2    
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

to_test=(samples markers outfile chrom genoid plink2_version genofolder)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (extract_raw.sh): mandatory variable $var is not defined."
    echo ""
  fi    
done






## +++ Check if interactive

tag=$( echo $SLURM_JOB_NAME | grep interactive | wc -l )  

if [ "$tag" -eq "0" ];then
  echo ""
  echo "  Please start in interactive session only."
  echo
  exit 0
fi






## +++ Chromosomes  

# chromosomes=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # all chromosomes
      
cstart=$( echo $chrom | cut -d'-' -f 1 )
cstop=$( echo $chrom | cut -d'-' -f 2 )

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (extract_raw.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (extract_raw.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			   Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )






 
## +++ Header:

log="extract_raw.log" 
echo > ${log}
account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 
START=$(date +%s)
echo ""  | tee -a ${log}     
echo -n "  "  | tee -a ${log} 
date  | tee -a ${log}
echo "  Account: ${account}"  | tee -a ${log}
echo -n "  Operated by: "  | tee -a ${log}
whoami  | tee -a ${log}
echo "  Logfile: ${log}"  | tee -a ${log}
echo ""  | tee -a ${log}
echo "  Sample list: ${samples}" | tee -a ${log}
echo "  Marker list: ${markers}"  | tee -a ${log}
echo "  Output filename prefix: ${outfile}" | tee -a ${log}
echo "  Chromosome(s) to search: $chrom"  | tee -a ${log}  
echo "  Genotype input folder: ${genofolder}"  | tee -a ${log} 
echo "  Genotype identifier: " ${genoid}  | tee -a ${log}
echo ""  | tee -a ${log}








## +++ Check availability of input files and genotype files:

for chrom in  ${chromosomes[*]}     
do

  pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # name must fit to the genotype files listed above (.pgen files)

  psam=${pgen_prefix}".psam"	
  pvar=${pgen_prefix}".pvar"	 
  pgen=${pgen_prefix}".pgen" 	   

  if [ ! -f ${psam} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (extract_raw.sh): Input file '${psam}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pvar} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (extract_raw.sh): Input file '${pvar}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi  

  if [ ! -f ${pgen} ]; then
    echo "" | tee -a ${log}
    echo "  ERROR (extract_raw.sh): Input file '${pgen}' not found." | tee -a ${log}
    echo "" | tee -a ${log}
    exit 1 
  fi    

done   

echo "  All required genotype files (.pgen, .pvar, .psam) are available."  | tee -a ${log}
echo "" 



# Samplefile:
 
if [ ! -f ${samples} ]; then
  echo ""
  echo "  ERROR (extract_raw.sh): Input file '${samples}' not found." | tee -a ${log}
  echo ""
  exit 1
fi
 
# head -5 sample_list.txt
# 5954653 
# 1737609 
# 1427013 
# 3443403 
# 5807741 

echo "#FID    IID " > samples_temp.txt
grep -v "^#" ${samples} | awk '{printf "%s\t%s\n", $1,$1}' >> samples_temp.txt

# head -5 samples_temp.txt
# #FID    IID 
# 5954653 5954653
# 1737609 1737609
# 1427013 1427013
# 3443403 3443403



 
 
# Markerfile: 
 
if [ ! -f ${markers} ]; then
  echo ""
  echo "  ERROR (extract_raw.sh): Input file '${markers}' not found." | tee -a ${log}
  echo ""
  exit 1
fi


# head marker_list.txt  # works with genofolder="/proj/sens2019016/GENOTYPES/PGEN"   (unique names)
# 11:61395_CTT_C 
# rs2461547_G_A
# rs558785434_T_C
# rs575614128_A_G
# rs566764841_GT_G
# rs200634578_T_A
# rs560955407_T_G
# 11:87209_TA_T
# rs574324672_C_T

# head marker_list_2.txt  # works with genofolder="/proj/sens2019016/GENOTYPES/PGEN_ORIG"  (original names)    
# 11:61395
# rs2461547
# rs558785434
# rs575614128
# rs566764841
# rs200634578
# rs560955407
# 11:87209
# rs574324672

grep -v "^#" ${markers} | awk '{print $1}' > markers_temp.txt  

# head -3 markers_temp.txt  # when original marker names were used 
# 11:61395
# rs2461547
# rs558785434






## +++ Modules: 

answ=$( module list  2>&1 | grep plink2 )   
if [ -z "$answ" ];then
  echo "  Loadung modules ..."  
  module load bioinfo-tools
  module load ${plink2_version}
  prog=$( which plink2 ) 
  echo "  Using: $prog"     
fi
echo ""







## +++ Loop through the chromosomes and try to fetch the markers: 

for chrom in  ${chromosomes[*]} 
do

  pgen_prefix="${genofolder}/${genoid}_chr$chrom"      # as above 
  out_prefix="${outfile}_chrom${chrom}"
  
  plink2 --pfile ${pgen_prefix} --keep samples_temp.txt --extract  markers_temp.txt  --export A  --out ${out_prefix}  

  rawfile="${out_prefix}.raw"  # genotype_chrom_11.raw
  logfile="${out_prefix}.log"  # genotype_chrom_11.log
  
  if [ -s "$rawfile" ]; then   
    awk '{$1=$3=$4=$5=$6="";print}' ${rawfile}  | column -t > rawfile_temp.txt   # remove columns "FID" and "PAT   MAT   SEX  PHENOTYPE"
    mv rawfile_temp.txt ${rawfile}
  else
    rm  ${logfile}  # no hits for any marker on this chromosome 
  fi
    
done






## +++ List rawfiles for each chromosome 

echo "" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Rawfiles:" | tee -a ${log}
echo "" | tee -a ${log}

total=0

for chrom in  ${chromosomes[*]} 
do 
  echo "  *** Chromosome ${chrom} ***" | tee -a ${log}
  out_prefix="${outfile}_chrom${chrom}"  # as above 
  rawfile="${out_prefix}.raw"
  if [ -s "${rawfile}" ];then 
    echo "    Output file: ${rawfile}" | tee -a ${log}
    number_hits=$( awk '{print NF-1}' ${rawfile} | sort | uniq -c | awk '{print $2}' )
    echo "    Number of hits: ${number_hits}" | tee -a ${log}
    total=$(( ${total} + ${number_hits} ))
  else
    echo "    No hits on chromosome ${chrom}" | tee -a ${log}
  fi
  echo "" | tee -a ${log}
done




## +++ Finish 

rm  samples_temp.txt  markers_temp.txt

echo "" | tee -a ${log}
echo "  Total number of hits (all chromosomes): ${total}" | tee -a ${log} 
echo "" | tee -a ${log}
echo -n "  "  
date 
echo "  Done." 
echo "" 
 

# uwe.menzel@medsci.uu.se
