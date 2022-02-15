#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


 

## === LD-pruning using GCTA-COJO , for a single chromosome:
   
# 	https://cnsgenomics.com/software/gcta/#COJO
# 	see GCTA_COJO.txt 






## +++ Calling:

# called by cojo_pheno.sh:

# sbatch --dependency=afterok:${convert_jobid} -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \
#         cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --summary ${summary_file} --pval ${pval} --window ${cojo_window}  \
#                   --colline ${collinearity} --maf ${maf} --siglist ${signif_list} --out ${out_prefix}  
#
# Interactive:
# pwd # /castor/project/proj/GWAS_TEST/liver10
#  cojo_chr  --id liver10  --genoid  FTD_rand --chr 3 --pval 5.0e-8 --window 5000 --colline 0.01  --maf 0.01 \  
#                  --summary liver10_liver_fat_a_cojo.ma --siglist liver10_liver_fat_a_gwas_signif.txt --out liver10_liver_fat_a_cojo_chr3




 
## +++ Hardcoded settings & defaults  

shopt -s nullglob 

setfile=~/cojo_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}   
else
  echo ""
  echo "  ERROR (cojo_chr.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi






## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 10 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"        
  echo "         -g|--genoid <string>           ${setfile}"
  echo "         -c|--chr <int>                 no default" 
  echo "         -s|--summary <file>            no default"    
  echo "         -p|--pval                      ${setfile}"
  echo "         -w|--window <integer>          ${setfile}"
  echo "         -cl|--colline <real>           ${setfile}"
  echo "         --maf <real>                   ${setfile}"    
  echo "         -sl|--siglist <file>           no default"  
  echo "         -o|--out                       no default"                    
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
      -g|--genoid)
          genoid=$2
          shift
          ;;	  
      -c|--chr)
          chrom=$2
          shift
          ;;	  	  
      -s|--summary)
          summary_file=$2
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
      -sl|--siglist)
          signif_list=$2
          shift
          ;;	  
      -o|--out)
          out_prefix=$2
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

to_test=(ident genoid chrom summary_file pval window collinearity maf signif_list out_prefix )

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (cojo_chr.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done






## +++ Check for correct folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (cojo_chr.sh): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi





## +++ Files  


bad_snps="${out_prefix}.badsnps" 	# output of gcta64, text file   	
freq_bad="${out_prefix}.freq.badsnps"   # output of gcta64, text file   
gcta_log="${out_prefix}.log"       	# log for gcta64 
jma_file="${out_prefix}.jma.cojo"       # output of gcta64, file with genome-wide significant markers     
ldr_file="${out_prefix}.ldr.cojo"  	# output of gcta64, text file
cma_file="${out_prefix}.cma.cojo" 	# output of gcta64, text file






## +++ Check availability of input file

if [ ! -s "${signif_list}" ];then
  echo ""
  echo  "  ERROR (cojo_chr.sh): Could not find file \"${signif_list}\"" 
  echo ""
  exit 1  
fi








## +++ Check chromosome name  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then    # autosomes only!       
  echo ""
  echo  "  ERROR (cojo_chr.sh): Chromosome name is not valid: " ${chrom} 
  echo  "  			Correct syntax is e.g. --chr 22"
  echo ""
  exit 1 
fi   





## +++ Header:

echo ""
START=$(date +%s) #  1574946757
echo -n "  "
date 
echo "  Job identifier: " ${ident}
echo "  Genotype identifier: ${genoid}"
echo "  Genotype input folder: ${genofolder}" 
echo "  Starting job for chromosome ${chrom}"
echo "  Summary statistics: ${summary_file}" 
echo "  GCTA-COJO p-value: ${pval}"
echo "  GCTA-COJO window: ${window}"
echo "  GCTA-COJO collinearity (r2) threshold: ${collinearity}" 
echo "  GCTA-COJO minor allele freq threshold: ${maf}"
echo "  List of sign. markers loaded: ${signif_list}"
echo "  Output file prefix: ${out_prefix}" 
echo  






## +++ Based on the ${signif_list}, decide if this chromsome should be run through gcta-cojo:

# head ${signif_list}
#
#      ID		CHR	    POS		A1	A1_FREQ		   BETA		SE			P
# rs146155542_T_C	10	7584321		T	0.00106437	3.65261		0.586105	4.67266e-10
# rs182239226_C_T	10	7585610		C	0.00105696	3.73868		0.590452	2.45955e-10
# rs182243134_C_T	10	7587603		C	0.00110519	3.32922		0.570756	5.50556e-09
# rs77411694_C_T	10	7588079		C	0.00110443	3.54626		0.58388		1.26724e-09
# rs188031153_A_G	10	7588195		A	0.00103794	3.45791		0.61136		1.56399e-08
# rs371272412_G_T	10	7590218		G	0.000652296	4.88179		0.741275	4.61123e-11
# rs760326718_G_C	10	12865140	G	0.000815172	3.82626		0.688337	2.74337e-08
# rs34820178_T_C	10	113901194	T	0.244546	0.234147	0.0420012	2.50192e-08
# rs58175211_C_T	10	113901637	C	0.244817	0.232486	0.0419736	3.07253e-08




# + Check how many signif. markers above maf cutoff are on the current chromosome ($chrom)  

chr_signif=$( tail -n +2  ${signif_list} | awk 'BEGIN{FS="\t"} {print $2}' )  
nr_signif_chr=$( printf '%s\n' ${chr_signif[@]} | egrep "^[[:space:]]*${chrom}[[:space:]]*$" | wc -l )   	# number of sign. markers for $chrom  
nr_above_maf=$( awk -v c=${chrom} -v m=${maf} '{if($2 == c && $5 >= m) print $0}' ${signif_list} | wc -l ) 	# no. of markers on this chrom above maf cutoff 

# skip chromosomes with none or only one sign. marker (above maf cutoff) (creates NA in the output)

if [ "${skip_chrom}" -eq 1 ];then

  if [ "${nr_signif_chr}" -eq 0 ];then    	# no hits for this chromosome 
    echo ""  
    echo "  No significant marker on chromosome ${chrom} according to the list ${signif_list}." 
    echo "  Cancelling analysis of this chromosome." 
    echo "" 
    echo -n "  "  
    date 
    echo "" 
    exit 0
  fi

  if [ "${nr_signif_chr}" -eq 1 ];then    	# just one hit for this chromosome ==> this hit is independent    
    echo ""   
    echo "  Just one significant marker on chromosome ${chrom} according to the list ${signif_list}." 
    echo "  This marker is independent and being added to the output list \"${jma_file}\" " 
    echo "" 
    # save the marker to ${jma_file} (defined above), in the same format as gcta64 would do: (gcta64 saves to ${ident}_cojo_chr${chrom}.jma.cojo)  
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "Chr" "SNP" "bp" "refA" "freq" "b" "se" "p" "n" "freq_geno" "bJ" "bJ_se" "pJ" "LD_r" > ${jma_file} 
    awk -v c=${chrom} 'BEGIN{FS="\t"}{if($2 == c) printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $2,$1,$3,$4,"NA",$6,$7,$8,"NA","NA","NA","NA","NA","NA"}' ${signif_list} >> ${jma_file} 
    echo -n "  "  
    date 
    echo "" 
    exit 0   
  fi 
  
  if [ "${nr_above_maf}" -eq 0 ];then    	# no markers with A1_FREQ >= maf cutoff 
    echo ""  
    echo "  No significant marker on chromosome ${chrom} above minor allele frequency cutoff ($maf)." 
    echo "  Cancelling analysis of this chromosome." 
    echo "" 
    echo -n "  "  
    date 
    echo "" 
    exit 0
  fi
 
fi  







## +++ Run gcta64 (if the chrom has more than 1 sign. marker)   


# Input file format (*.ma) (see cojo manual / GWAS analysis / COJO :
#
#    SNP A1 A2    freq      b     se      p      N 
# rs1001 A   G  0.8493 0.0024 0.0055 0.6653 129850 
# rs1002 C   G  0.0306 0.0034 0.0115 0.7659 129799 
# rs1003 A   C  0.5128 0.0045 0.0038 0.2319 129830    
# 
# Columns are:
#  SNP, 
#  the effect allele, 
#  the other allele, 
#  frequency of the effect allele, 
#  effect size, 
#  standard error, 
#  p-value  
#  sample size. 
#
#  The headers are not keywords and will be omitted by the program. 
#  Important: "A1" needs to be the effect allele with "A2" being the other allele and "freq" should be the frequency of "A1".
#  
#  Please always input the summary statistics of all SNPs even if your analysis only focuses on a subset of SNPs 
#  because the program needs the summary data of all SNPs to calculate the phenotypic variance.



geno_prefix="${genofolder}/${genoid}_chr${chrom}"   # /proj/sens2019016/GENOTYPES/BED/FTD_rand_chr22  (10.000 randomly selected from FTD)

gcta64  --bfile ${geno_prefix}  --thread-num 16 --chr ${chrom} --cojo-file ${summary_file} --cojo-slct --cojo-p ${pval} --maf ${maf} --cojo-wind ${window} --cojo-collinear ${collinearity} --out ${out_prefix} 

# --bfile	read .bed .fam. .bim  --> cojo_settings.sh: genofolder="/proj/sens2019016/GENOTYPES/BED"
# --cojo-slct   find independent markers (iteratively)   
# --cojo-file   input; the summary statistics (*.ma), converted and merged for all chromosomes in cojo_convert.sh from .glm.linear   
# --maf         minor allele frequency minimum  maf=0.01 in cojo_settings.sh 
# --pfile       .pgen does not work for cojo, see mail Zhili 19/02/2020









## +++ Finish 

# OBS! If no independent signif. marker have been found, the files jma_file, ldr_file, and cma_file won't exist! 

if [ -s "$jma_file" ]; then   # independent markers have been identified 

  echo "" 
  echo "  Output files:"
  echo "" 
  ls -l ${bad_snps} 2>/dev/null
  ls -l ${freq_bad} 2>/dev/null
  ls -l ${jma_file} 2>/dev/null   
  ls -l ${ldr_file} 2>/dev/null   
  ls -l ${cma_file} 2>/dev/null
  #ls -l ${gcta_log}  
  echo ; echo 

  nr_total=$(  wc -l ${summary_file} | awk '{print $1}' )
  nr_total=$(( ${nr_total} - 1 ))
  echo "  Total number of SNPs in summary file: ${nr_total}" 

  nr_jma=$(  wc -l ${jma_file} | awk '{print $1}' )
  nr_jma=$(( ${nr_jma} - 1 ))
  echo "  Number of independent SNPs: ${nr_jma}" 

  if [ -s "$bad_snps" ]; then
    nr_bad=$(  wc -l ${bad_snps} | awk '{print $1}' )   
    nr_bad=$(( ${nr_bad} - 1 ))
    echo "  Number of \"bad\" SNPs: ${nr_bad}" 
  fi

else

  echo "" 
  echo "  WARNING (cojo_chr): No independent markers identified."   
  # this can actually not happen if everything works fine, because chromosomes without sign. markers have been sorted out above
  
fi


# OBS!!: It seems cojo runs gcta64 FIRST and THEN checks for maf 





## +++ Check cma file (Jenny)   $cma_file will be deleted in cojo_clean  

# check pC - effective p-value 

if [ -s "$cma_file" ]; then    
  nr_sec_hits=$(awk -v pval=${pval} '{if($NF <= pval) print $NF}' ${cma_file} | wc -l)
  echo ""
  echo "  File ' $cma_file ': Number of hits with pC < $pval = $nr_sec_hits"
  echo ""
fi




rm -f ${gcta_log}  # batchlog is sufficient 

echo ""
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds" 
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 






