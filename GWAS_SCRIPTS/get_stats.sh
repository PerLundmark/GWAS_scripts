#!/usr/bin/env bash  





## +++ Get basic genotype statistics for a list of markers



# uwe.menzel@medsci.uu.se 



# Input:   no header but unique names (use get_alleles to get the unique names)  
# 
# rs55861089_G_A
# rs41271951_G_A
# rs6761276_C_T
# rs1024948_T_C
# rs74480769_G_A







## +++ Hardcoded settings & and defaults 

setfile=~/stats_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings  
else
  echo ""
  echo "  ERROR (get_stats): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi








## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Usage: ${prog} --snps <file>"                            
  echo ""
  exit 1
fi


while [ "$#" -gt 0 ]
do
  case $1 in
      --snps)
          sfile=$2
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


# sfile="SNPs_list_08SEP2020.txt"  #    /castor/project/proj/GWAS_DEV3/liver10
# sfile="test.txt"   # one marker on chr 11 






## +++ Check if the variables are defined  

to_test=(sfile chrom genofolder genoid plink2_version)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (get_stats): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done








## +++ Check availability of input file

if [ ! -s "${sfile}" ];then
  echo ""
  echo  "  ERROR (get_stats): Could not find file \"${sfile}\"" 
  echo ""
  exit 1  
fi







## +++ Chromosomes  

# chromosomes=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)  # all chromosomes
      
cstart=$( echo $chrom | cut -d'-' -f 1 )
cstop=$( echo $chrom | cut -d'-' -f 2 )

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (get_stats): Start chromosome is not valid: " ${cstart} 
  echo  "  		      Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (get_stats): Stop chromosome is not valid: " ${cstop} 
  echo  "  		      Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )






## +++ Header

echo ""
echo "  === Get basic genotype statistics for a number of markers ==="
echo ""
logfile="${sfile}_stats.log" 
echo > ${logfile}





## +++ Check availability of genotype files:

for chrom in  ${chromosomes[*]}     
do

  pgen_prefix=${genofolder}"/"${genoid}"_chr"$chrom   

  psam=${pgen_prefix}".psam"	
  pvar=${pgen_prefix}".pvar"	 
  pgen=${pgen_prefix}".pgen" 	   

  if [ ! -f ${psam} ]; then
    echo "" 
    echo "  ERROR (get_stats): Input file '${psam}' not found." 
    echo "" 
    exit 1 
  fi  

  if [ ! -f ${pvar} ]; then
    echo "" 
    echo "  ERROR (get_stats): Input file '${pvar}' not found." 
    echo "" 
    exit 1 
  fi  

  if [ ! -f ${pgen} ]; then
    echo "" 
    echo "  ERROR (get_stats): Input file '${pgen}' not found." 
    echo "" 
    exit 1 
  fi    

done   

echo "  All required genotype files (.pgen, .pvar, .psam) are available."  
echo ""

echo -n "  "
dos2unix ${sfile} 
echo ""




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





## +++ Get unique entries of the input file 

sort ${sfile} | uniq > ${sfile}.temp   # unique entries 
cp ${sfile} ${sfile}.orig 
mv ${sfile}.temp ${sfile}

nr1=$( wc -l ${sfile} | awk '{print $1}') 
nr2=$( wc -l ${sfile}.orig | awk '{print $1}') 





## +++ Clean folder 

rm -f ${sfile}_chr*.afreq  2>/dev/null  # that's important because of the cat's below!!
rm -f ${sfile}_chr*.hardy  2>/dev/null  # that's important because of the cat's below!! 





## +++ Loop through chromosomes, get stats

for chrom in  ${chromosomes[*]} 
do

  echo "" >> ${logfile}
  echo "" >> ${logfile}  
  echo "  *** Searching chromosome ${chrom} ***" | tee -a ${logfile}
  echo "" >> ${logfile}   

  pgen_prefix="${genofolder}/${genoid}_chr$chrom"   # /proj/sens2019016/GENOTYPES/PGEN/MF_chr5
  
  outfile_prefix="${sfile}_chr${chrom}" 
  
  plink2 --pfile ${pgen_prefix} --extract ${sfile} --freq 'cols=chrom,pos,ref,alt1,reffreq,alt1freq,nobs,machr2' \
         --hardy  --out ${outfile_prefix} >> ${logfile}  

  # many file won't contain any hit because the marker is not on this chromosome
  # delete files which are empty (except for the header immidiately)
  

  grep remaining ${outfile_prefix}.log
   
  nr_lines=$(wc -l ${outfile_prefix}.afreq | awk '{print $1}')
  
  if [ "$nr_lines" -gt "1" ];then
  
    ls -l ${outfile_prefix}.afreq  	# 2>/dev/null   
    ls -l ${outfile_prefix}.hardy 	# 2>/dev/null 
    # ls -l ${outfile_prefix}.log 	#  2>/dev/null     
  
  else
  
    rm -f ${outfile_prefix}.afreq
    rm -f ${outfile_prefix}.hardy
    
  fi

  echo "" 
  
done






## +++ Output files  

rm ${sfile}_chr*.log  

head -1 ${sfile}_chr*.afreq | tail -1 > ${sfile}.afreq
tail --quiet -n +2 ${sfile}_chr*.afreq >> ${sfile}.afreq
rm -f ${sfile}_chr*.afreq


head -1 ${sfile}_chr*.hardy | tail -1 > ${sfile}.hardy
tail --quiet -n +2 ${sfile}_chr*.hardy >> ${sfile}.hardy
rm -f ${sfile}_chr*.hardy


nr_entries=$(wc -l ${sfile} | awk '{print $1}')
echo "  Number of unique input markers: ${nr_entries}"  

nr_hits=$( wc -l ${sfile}.afreq | awk '{print $1}') 
nr_hits=$(( ${nr_hits} - 1 ))
echo "  Number of hits found (frequency): ${nr_hits}"

nr_hits=$( wc -l ${sfile}.hardy | awk '{print $1}') 
nr_hits=$(( ${nr_hits} - 1 ))
echo "  Number of hits found (HWE): ${nr_hits}"

# --missing  # too much output








## +++ Compare input and output markers

# input_markers == ${sfile}   
 
tail -n +2 ${sfile}.afreq  | awk '{print $3}' > ${sfile}_out.txt  # markers in output 
comm -23 <(sort ${sfile} | uniq ) <(sort ${sfile}_out.txt) | uniq > ${sfile}_diff.txt 
nr_not_found=$( wc -l ${sfile}_diff.txt | awk '{print $1}' )
echo "  Number of markers not found in the genotype files: ${nr_not_found}"
rm -f ${sfile}_out.txt

if [ "$nr_not_found" -gt "0" ];then
  echo ""
  echo "  See the file ' ${sfile}_diff.txt ' for the markers not found."
  echo ""
fi




# search for missing marker in all genotype files:
# 
# grep -swc  rs000000001  "${genofolder}/${genoid}_chr*.pvar"




## +++ Finish  

echo ""
ls -l ${logfile}
ls -l ${sfile}
ls -l ${sfile}.orig  
ls -l ${sfile}.afreq 
ls -l ${sfile}.hardy  
echo ""

if [ "$nr1" -ne "$nr2" ];then
  echo ""
  echo "  Duplicate entries have been found in the input file."
  echo ""
fi
echo ""



