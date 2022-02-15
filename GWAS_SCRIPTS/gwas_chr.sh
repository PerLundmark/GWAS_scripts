#!/usr/bin/env bash 


# uwe.menzel@medsci.uu.se  


## === Run GWAS on a single chromosome   





## +++ Call:

# called by 'run_gwas.sh' : 
#
#    sbatch -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${logchr} -e ${logchr}  \
#    gwas_chr --gen ${pgen_prefix}  --chr ${chrom}  --id ${ident}  --pheno ${phenopath}  --pname ${phenoname}  \
#             --covar ${covarpath}  --cname ${covarname} --mac ${mac}  --maf ${maf} --vif ${vif}  --mr2 "${machr2}"  --hwe ${hwe_pval} \
# 	      --geno ${marker_max_miss} --mind ${sample_max_miss}  

# logchr="${ident}_gwas_chrom${chrom}.log"    	# see run_gwas.sh : logfile for a single chromosome (and for multiple phenotypes)






## +++ Hardcoded settings & and defaults 

setfile=~/gwas_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings (but not all can be overwritten) 
else
  echo ""
  echo "  ERROR (gwas_chr.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi




 
## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 14 ]; then
  echo ""
  echo "  Usage: ${prog}" 
  echo "         -i|--id <string>         	no default"   
  echo "         -g|--gen <string>        	no default" 
  echo "         -c|--chr <int>           	no default" 
  echo "         -p|--pheno <file>        	no default" 
  echo "         -pn|--pname <string>     	no default"
  echo "         -co|--covar <file>       	no default" 
  echo "         -cn|--cname <string>     	no default"
  echo "         -h|--hwe  <real>         	${setfile}"  
  echo "         --mac <int>              	${setfile}"
  echo "         --maf <int>              	${setfile}"
  echo "         --vif <int>                    ${setfile}"    
  echo "         --geno <real>                  ${setfile}" 
  echo "         --mind <real>                  ${setfile}"   
  echo "	 --mr2 <range>            	${setfile}"
  echo ""
  exit 1
fi


while [ "$#" -gt 0 ]
do
  case $1 in
      -g|--gen)
          pgen_prefix=$2   
          shift
          ;;  
      -c|--chr)
          chrom=$2
          shift
          ;;	  
      -i|--id)
          ident=$2
          shift
          ;;
      -p|--pheno)
          phenofile=$2
          shift
          ;;
      -pn|--pname)
          phenoname=$2
          shift
          ;;
      -co|--covar)
          covarfile=$2
          shift
          ;;
      -cn|--cname)
          covarname=$2
          shift
          ;;
      --mac)
          mac=$2
          shift
          ;;
      --maf)
          maf=$2
          shift
          ;;
      --vif)
          vif=$2
          shift
          ;;	  	  
      --mr2)
          machr2=$2
          shift
          ;;
      -h|--hwe)
          hwe_pval=$2
          shift
          ;;	  
      --geno)
          marker_max_miss=$2    
          shift
          ;;	  
      --mind)
          sample_max_miss=$2    
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

to_test=(pgen_prefix chrom ident phenofile phenoname covarfile covarname mac maf vif marker_max_miss sample_max_miss machr2 hwe_pval)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (gwas_chr.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done








## +++ Check chromosome name  

if [[ ! ${chrom} =~ ^[0-9]+$ ]];then    # autosomes only!       
  echo ""
  echo  "  ERROR (gwas_chr.sh): Chromosome name is not valid: " ${chrom} 
  echo  "  			Correct syntax is e.g. --chr 22"
  echo ""
  exit 1 
fi   





 
## +++ Header:

echo ""
START=$(date +%s) 
echo -n "  "
date 
echo "  Job identifier: " ${ident}
echo "  Starting job for chromosome ${chrom}"
echo "  Genotype input file prefix: ${pgen_prefix}"
echo "  Phenotype file: ${phenofile}"
echo "  Phenotype name(s): ${phenoname}"
echo "  Covariate file: ${covarfile}"
echo "  Covariate name(s): ${covarname}"
echo "  Threshold for minor allele frequency (mac): ${mac}"
echo "  Threshold for Hardy-Weinberg p-value: ${hwe_pval}"
echo "  Mach-r2 imputation quality range: ${machr2}"
echo "  Threshold for minor allele frequency (maf): ${maf}"
echo "  Maximum variance inflation factor (vif): ${vif}" 
echo "  Maximum missing call rate for markers: ${marker_max_miss} " 
echo "  Maximum missing call rate for samples: ${sample_max_miss} " 
echo ""







## +++ Modules: 

answ=$( module list  2>&1 | grep plink2 )   
if [ -z "$answ" ];then
  echo "  Loadung modules ..."  | tee -a ${log}
  module load bioinfo-tools
  module load ${plink2_version}
  prog=$( which plink2 ) 
  echo "  Using: $prog"  | tee -a ${log}   
fi







## +++ Check availability of input files and genotype files:

psam=${pgen_prefix}".psam"	# /proj/sens2019016/GENOTYPES/MF_chr16.psam 
pvar=${pgen_prefix}".pvar"	# /proj/sens2019016/GENOTYPES/MF_chr16.pvar
pgen=${pgen_prefix}".pgen" 	# /proj/sens2019016/GENOTYPES/MF_chr16.pgen   

if [ ! -f ${psam} ]; then
  echo ""
  echo "  ERROR (gwas_chr.sh): Input file '${psam}' not found."
  echo ""
  exit 1 
fi  

if [ ! -f ${pvar} ]; then
  echo ""
  echo "  ERROR (gwas_chr.sh): Input file '${pvar}' not found."
  echo ""
  exit 1 
fi  

if [ ! -f ${pgen} ]; then
  echo ""
  echo "  ERROR (gwas_chr.sh): Input file '${pgen}' not found."
  echo ""
  exit 1 
fi    

echo "  All required genotype files (.pgen, .pvar, .psam) are available." 

if [ ! -f ${phenofile} ]; then
  echo ""
  echo "  ERROR (gwas_chr.sh): Input file '${phenofile}' not found."
  echo ""
  exit 1 
else
  num_samples=$( wc -l ${phenofile} | awk '{print $1}' )
  num_samples=$(( ${num_samples} - 1 ))
  echo "  Phenotype file available, with ${num_samples} samples."   
fi 

if [ ! -f ${covarfile} ]; then
  echo ""
  echo "  ERROR (gwas_chr.sh): Input file '${covarfile}' not found."
  echo ""
  exit 1 
else
  num_samples=$( wc -l ${covarfile} | awk '{print $1}' )
  num_samples=$(( ${num_samples} - 1 ))
  echo "  Covariates file available, with ${num_samples} samples." 
  clist=$( echo $covarname | sed 's/,/ /g' )
  for name in  ${clist[*]}  
  do  
    indicator=$( head -1 ${covarfile} | grep ${name} | wc -l )
    if [ $indicator -ne 1 ]; then
      echo ""
      echo "  ERROR (gwas_chr.sh): Covariate file '${covarfile}' does not contain the column '${name}'"
      echo ""
      exit 1   
    fi      
  done
fi

echo "" 






## +++ Run plink2 (on a single chromosome)   

# find the samples which are common to genotype, phenotype, and covariates
# consider only these samples in the regression, so that QC is done on these samples only 

# ls -l ${pgen_prefix}*  # it's a prefix  
# ls -l ${covarfile}
# ls -l ${phenofile}
 
# -rwxr-x--- 1 umenzel sens2019016 101320043746 Apr 20 18:08 /proj/sens2019016/GENOTYPES/PGEN/FTD_chr5.pgen
# -rwxr-x--- 1 umenzel sens2019016      6074689 Apr 20 18:08 /proj/sens2019016/GENOTYPES/PGEN/FTD_chr5.psam
# -rw-rw-r-- 1 umenzel sens2019016    190623266 Apr 20 18:59 /proj/sens2019016/GENOTYPES/PGEN/FTD_chr5.pvar
# -rw-rw-r-- 1 drivas sens2019016 44306038 Apr 22 11:22 /proj/sens2019016/GWAS_TEST/GWAS_covariates.txt
# -rw-rw-r-- 1 shafqat sens2019016 1173832 May  6 11:40 /proj/sens2019016/GWAS_TEST/liver_fat_ext.txt 

rnum=$(( 1 + RANDOM%10000 ))   # avoid interference with jobs running paralle

geno_samples="geno_samples_chr${chrom}_${rnum}.txt"  	# geno_samples_chr5_310.txt
awk '{print $2}' ${pgen_prefix}.psam | tail -n +2 | sort > ${geno_samples}
# wc -l ${geno_samples}   	# 337482

covar_samples="covar_samples_chr${chrom}_${rnum}.txt"   # covar_samples_chr5_310.txt
awk '{print $2}' ${covarfile} | tail -n +2 | sort > ${covar_samples}
# wc -l  ${covar_samples}  	# 337482 

pheno_samples="pheno_samples_chr${chrom}_${rnum}.txt"	# pheno_samples_chr5_310.txt
awk '{print $2}' ${phenofile} | tail -n +2 | sort > ${pheno_samples}
# wc -l  ${pheno_samples}  	# 38948

geno_covar_samples="geno_covar_samples_chr${chrom}_${rnum}.txt"  #  geno_covar_samples_chr5_310.txt
comm -12 ${geno_samples} ${covar_samples} | sort > ${geno_covar_samples}
# wc -l ${geno_covar_samples}  	# 337482 geno_covar_samples_chr5_310.txt

files2keep="files2keep_chr${chrom}_${rnum}.txt"  # files2keep_chr5_310.txt
comm -12 ${geno_covar_samples} ${pheno_samples} | awk 'BEGIN{FS="\t"} {print $1, $1}' > ${files2keep} 
# wc -l ${files2keep}		# 27243 files2keep_chr5_310.txt

nr_common=$( wc -l ${files2keep} | awk '{print $1}' )   # 27243

echo "  We have ${nr_common} common samples in genotype, phenotype, and covariate files." 
echo ""

rm -f ${geno_samples} ${covar_samples} ${pheno_samples} ${geno_covar_samples} # for this chromosome


  
echo "  Genotype files for chromosome $chrom :"   # psam, pvar, pgen defined above    
ls -l ${psam}
ls -l ${pvar}  
ls -l ${pgen}  
echo ""

outfile_prefix="${ident}_gwas_chr"${chrom} # OBS!! : Naming convention also used elsewhere!   


plink2 --glm hide-covar 'cols=chrom,pos,ref,alt1,a1freq,beta,se,p,nobs' \
   --pfile ${pgen_prefix} \
   --keep ${files2keep} \
   --pheno ${phenofile} --pheno-name ${phenoname}\
   --covar ${covarfile} --covar-name ${covarname} \
   --no-psam-pheno \
   --covar-variance-standardize \
   --mac ${mac} \
   --maf ${maf} \
   --vif ${vif} \
   --mind ${sample_max_miss} \
   --geno ${marker_max_miss} \
   --hwe ${hwe_pval} \
   --mach-r2-filter ${machr2} \
   --out ${outfile_prefix}


# + Outfiles:   

pname=$( echo $phenoname | tr -s ',' '\t' )  
phenoarray=($pname)   
echo ""
echo "  Number of elements in phenoname: ${#phenoarray[*]}" 
echo ""
echo "  Regression results: "

for pname in  ${phenoarray[*]} 
do
  echo ""
  echo "  Phenoname: $pname" 
  echo -n "    "
  out_glm_lin=${outfile_prefix}"."${pname}".glm.linear"    # linear regression
  out_glm_log=${outfile_prefix}"."${pname}".glm.logistic"  # logistic regression [ case/control ] 
  
  if [ \( ! -s "${out_glm_lin}" \) -a \( ! -s "${out_glm_log}" \) ];then   
    echo ""
    echo "  ERROR (gwas_chr.sh): No plink output file \"${out_glm_lin}\" or \"${out_glm_log}\" written."
    echo "                       See the error messages in the logfile ${ident}_gwas_chrom${chrom}.log"   # logchr="${ident}_gwas_chrom${chrom}.log"
    echo "" 
    out_logf=${outfile_prefix}".log"
    rm -f ${out_logf} ${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
    echo ""    
    exit 1   
  fi  
  
  if [ -s "${out_glm_lin}" ];then   
    ls -l ${out_glm_lin}
    entries=$( wc -l ${out_glm_lin} | awk '{print $1}' )
    entries=$(( ${entries} - 1 ))
    echo "    Number of entries in output file (.glm.linear) for phenoname \"${pname}\": ${entries}"
    num_NA=$( cat ${out_glm_lin} | awk '{print $NF}' | grep NA | wc -l )
    echo "    Number of entries with unassigned (NA) p-values: ${num_NA}"
    out_logf=${outfile_prefix}".log"
    rm -f ${out_logf} ${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
    echo ""    
  fi
  
  if [ -s "${out_glm_log}" ];then   
    ls -l ${out_glm_log}
    entries=$( wc -l ${out_glm_log} | awk '{print $1}' )
    entries=$(( ${entries} - 1 ))
    echo "    Number of entries in output file (.glm.logistic) for phenoname \"${pname}\": ${entries}"
    num_NA=$( cat ${out_glm_log} | awk '{print $NF}' | grep NA | wc -l )
    echo "    Number of entries with unassigned (NA) p-values: ${num_NA}"
    out_logf=${outfile_prefix}".log"
    rm -f ${out_logf} ${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
    echo ""    
  fi
   
done
echo ""


 
 
 

## +++ Finish 
 
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds" 
echo "" 
echo -n "  "  
date 
echo "  Done." 
echo "" 
























