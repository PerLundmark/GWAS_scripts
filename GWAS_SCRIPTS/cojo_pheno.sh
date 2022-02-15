#!/usr/bin/env bash




# uwe.menzel@medsci.uu.se  



## === LD pruning using GCTA-COJO for a single penotype and multiple (all) chromosomes ===    
   





## +++ Calling: 

# called by run_cojo.sh
#  
#    cojo_pheno  --id LIV6   --phenoname vox1_exp  --pval 5.0e-8  --window 5000  --colline 0.01 --maf 0.01 --part node  --minutes 120 
#    cojo_pheno  --id LIV6   --phenoname vox1_exp  --pval 5.0e-8  --window 5000  --colline 0.01 --maf 0.01 --part node  --minutes 120 --keepma
#
# 	This script has to be started in the folder containing the gwas results:
#    	e.g. /proj/sens2019016/GWAS_TEST/LIV5   (if identifier was "LIV5")  








## +++ Hardcoded settings & defaults 

shopt -s nullglob 

setfile=~/cojo_settings.sh
if [ -s "${setfile}" ];then
  source ${setfile}  # command line paramters overwrite these settings 
else
  echo ""
  echo "  ERROR (cojo_pheno.sh): Could not find the settings file \"${setfile}\"."
  echo ""
  exit 1  
fi






 
## +++ Programs 
 
prog=$( which gcta64 )   
exit_code=$?  
if [ ${exit_code} -ne 0 ]
then
  echo "" 
  echo "  ERROR (cojo_pheno.sh): Did not find the gcta64 program." 
  echo ""
fi 






## +++ Command line parameters:   

if [ "$#" -lt 4 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "         -i|--id <string>               no default"
  echo "         -pn|--phenoname <string>       no default"
  echo "         -p|--pval <real>               ${setfile}"
  echo "         -w|--window <integer>          ${setfile}" 
  echo "         -cl|--colline <real>           ${setfile}"
  echo "         --maf <real>                   ${setfile}"    
  echo "         -m|--minutes <int>             ${setfile}"
  echo "         --keepma                       keep summary file"  
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
      --keepma)
          keepma=1
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







## +++ Files

paramfile="${ident}_gwas_params.txt" 				# OBS!! Name convention from run_gwas
signif_file="${ident}_${phenoname}_cojo.jma"   			# cojo output for this phenotype, independent markers 
log="${ident}_${phenoname}_cojo.log"   				# master logfile for cojo pruning for this phenoname  
convert_log="${ident}_${phenoname}_cojo_convert.log"  		# sbatch log for cojo_convert.sh		  		 
collect_log="${ident}_${phenoname}_cojo_collect.log"		# sbatch log for cojo_collect.sh    
clean_log="${ident}_${phenoname}_cojo_clean.log"      		# sbatch log for cojo_clean.sh   
summary_file="${ident}_${phenoname}_cojo.ma"   			# output of "cojo_convert.sh", input for "cojo_chr.sh": summary statistics for all chromosomes 
signif_list="${ident}_${phenoname}_gwas_signif.txt"  		# output of "cojo_convert.sh", list with significant markers across the genome , used in cojo_chr to decide if the chrom should be analyzed 	







## +++ Read remaining parameters from the param files (created in "run_gwas.sh"):

if [ ! -s "$paramfile" ]; then
  echo ""
  echo "  ERROR (cojo_pheno.sh): Missing parameter file ${paramfile}"
  echo ""
  exit 1
fi

# may include cojo results for multiple phenotypes
# may include clump results for multiple phenotypes 

genoid=$( awk '{if($1 == "genotype_id") print $2}' ${paramfile} )  
cstart=$( awk '{if($1 == "cstart") print $2}' ${paramfile} )  	
cstop=$( awk '{if($1 == "cstop") print $2}' ${paramfile} )  	






## +++ Check if alternative genotype files were provided 

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






## +++ Make new entries in ${paramfile}

# ${signif_file} will be the final output of "cojo_pheno.sh". Add the name to the parameterfile:
# remove possibly existing cojo-entry for this phenotype: 
rnum=$(( 1 + RANDOM%10000 ))   # avoid interference with jobs running parallel
awk -v pheno=$phenoname '{if(!($1 == "cojo_out" && $2 == pheno)) {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt 
mv temp_${phenoname}_${rnum}.txt ${paramfile}  
echo "cojo_out ${phenoname} ${signif_file}" >> ${paramfile} 	# replace by current entry 


# window=5000	# (5MB) cojo assumes that markers outside this window are independent 
awk '{if($1 != "cojo_window") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "cojo_window ${window}" >> ${paramfile} 	# replace by current entry 

# pval=5.0e-8	# p-value threshold for genome-wide significance 
awk '{if($1 != "cojo_pval") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "cojo_pval ${pval}" >> ${paramfile} 	# replace by current entry 

# collinearity=0.01
awk '{if($1 != "cojo_coline") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "cojo_coline ${collinearity}" >> ${paramfile} 	# replace by current entry 

# cojo_refgen="FTD_rand"
awk '{if($1 != "cojo_refgen") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "cojo_refgen ${genoid}" >> ${paramfile} 	# replace by current entry reference genome (read from paramfile or alternative genoid, see settings file) 

# cojo_maf=0.01
awk '{if($1 != "cojo_maf") {print $0}}' ${paramfile} > temp_${phenoname}_${rnum}.txt  # remove possibly existing entry
mv temp_${phenoname}_${rnum}.txt ${paramfile}
echo "cojo_maf ${maf}" >> ${paramfile} 	# replace by current entry reference genome (read from paramfile or alternative genoid, see settings file) 






## +++ Check if the variables are defined  

to_test=(ident phenoname pval window collinearity maf partition minutes genoid cstart cstop minspace keepma)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (cojo_pheno.sh): mandatory variable $var is not defined."
    echo ""
    exit 1
  fi    
done







## +++ Check folder:

folder=$( basename "`pwd`" ) 

if [ "${folder}" != "${ident}" ];then
  echo "" 
  echo "  ERROR (cojo_pheno): It seems you are in the wrong location." 
  echo "         Current folder is: ${folder}"
  echo "         Identifier is: ${ident}"
  echo "" 
  exit 1 
fi






## +++ Check if $phenoname is valid (user input)

# possible entries in ${paramfile}:
#     phenoname liv1,liv2,liv3,liv4,liv5,liv6,liv7,liv8,liv9,liv10      # LIV_MULT    
#     phenoname vox1_exp   						# VOX1

pname=$( awk '{if($1 == "phenoname") print $2}' ${paramfile} )      
pname=$( echo $pname | tr -s ',' '\t' )  			   
parray=($pname)
# echo " Number of elements in parray: ${#parray[*]}"   		#  10 ok  
nr_hits=$( printf '%s\n' ${parray[@]} | egrep "^[[:space:]]*${phenoname}[[:space:]]*$" | wc -l )  # should exactly be 1
if [ "${nr_hits}" -ne 1 ];then
  echo ""
  echo "  ERROR (cojo_pheno.sh): You propably picked a wrong phenotype name."
  echo "  The word \"${phenoname}\" is not included as a phenoname entry in \"${paramfile}\""
  echo ""
  exit 1
fi










## +++ Check chromosomes:

if [[ ! ${cstart} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (cojo_pheno.sh): Start chromosome is not valid: " ${cstart} 
  echo  "  			  Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

if [[ ! ${cstop} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (cojo_pheno.sh): Stop chromosome is not valid: " ${cstop} 
  echo  "  			  Correct syntax is e.g. --chrom 1-16"
  echo ""
  exit 1 
fi   

chromosomes=$( seq ${cstart} ${cstop} )







## +++ Check available disk space:

space=$( df -k . | tail -1 | awk '{print $4}' )  # kb  22430291840    
spac1=$( df -h . | tail -1 | awk '{print $4}' )  # human readable  21T 
if [ ${space} -lt ${minspace} ]; then	
    echo "" 
    echo "  Less than ${minspace} disk space available, consider using a different location." 
    echo "" 
    exit 1 
fi 

# also done in run_cojo.sh but this can also be run standalone ...





## +++ Convert the time string for sbatch command below:

hours=$( expr $minutes / 60 )  
min=$( expr $minutes % 60 )    
if [ "$hours" -eq 0 ]; then
  time=${min}":00"
else
  if [ "${#min}" -eq 1 ]; then min="0"${min}; fi  
  time=${hours}":"${min}":00"  # requested runtime for a single chromosome
fi  








## +++ Header:

account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' ) 	# sens2019016
echo ""  > ${log}
echo ""   | tee -a ${log}
START=$(date +%s)      #  1574946757
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Account: ${account}" | tee -a ${log}
echo -n "  Operated by: " | tee -a ${log} 
whoami | tee -a ${log} 
echo -n "  Current working folder: "  | tee -a ${log}
pwd  | tee -a ${log}
echo "  Available disk space in this path: ${spac1}"  | tee -a ${log}
echo "  Job identifier:  ${ident}" | tee -a ${log}
echo "  Phenotype namn: ${phenoname}" | tee -a ${log}
echo "  GCTA-COJO window: ${window}" | tee -a ${log}
echo "  GCTA-COJO p-value: ${pval}" | tee -a ${log}
echo "  GCTA-COJO collinearity (r2) threshold: ${collinearity}" | tee -a ${log}
echo "  GCTA-COJO minor allele freq threshold: ${maf}" | tee -a ${log}
echo "  Genotype identifier: ${genoid}" | tee -a ${log}
echo "  Running on chromosomes ${cstart} to ${cstop}" | tee -a ${log}
echo "  Master logfile: ${log}" | tee -a ${log}
echo "" | tee -a ${log}
echo "  Requested partition: ${partition}" | tee -a ${log}
echo "  Requested runtime per chromosome: ${minutes} minutes." | tee -a ${log}
echo "  Requested runtime per chromosome: ${time}" | tee -a ${log}
echo "" | tee -a ${log}  







## +++ Create COJO input file
#
#     In an extra sbatch job, do the following:
#        merge gwas output files for the chromosomes 
#        reformat gwas summary files for GCTA-COJO    

c_ident="CONVERT"
# cojo_convert_time="20:00" 			# moved to ~/cojo_settings.sh   time requested for "cojo_convert.sh" 

echo "  sbatch -A ${account} -p ${partition}  -t ${cojo_convert_time}  -J ${c_ident} -o ${convert_log} -e ${convert_log} \  " | tee -a ${log}
echo "  cojo_convert  --id ${ident}  --phenoname ${phenoname} --summary ${summary_file} --pval ${pval}  --siglist ${signif_list}"  | tee -a ${log} 

convert_jobid=$( sbatch -A ${account} -p ${partition}  -t ${cojo_convert_time}  -J ${c_ident} -o ${convert_log} -e ${convert_log} \
       cojo_convert  --id ${ident}  --phenoname ${phenoname} --summary ${summary_file} --pval ${pval}  --siglist ${signif_list} )

convert_jobid=$( echo $convert_jobid | awk '{print $NF}' )
echo "  JobID for cojo-convert : ${convert_jobid}" | tee -a ${log}   

echo "" | tee -a ${log}

# outputs the file ${summary_file} which is gcta64-input # *.ma  (OBS!: this file is not available at this point, job is in the queue!)   
# head -4 LIV_MULT5_liv3_cojo.ma
# 	  ID	A1	OTHER	A1_FREQ		    BETA	     SE		       P	OBS_CT
# rs183305313	A	G	0.00490037	-0.29715	0.364161	0.414519	18771
# rs12260013	G	A	0.0271634	0.112443	0.156766	0.473222	18771
# rs61838967	T	C	0.186952	-0.04485	0.064733	0.488359	18771

 
# outputs the file ${signif_list} e.g. "LIV_MULT5_liv3_gwas_signif.txt" : genome-wide significant markers : 
#        goes to cojo_chr to decide if the chromosome should be analyzed (if there are markers with p <= pval && maf >= cutoff)
#
# head ${signif_list}
#
#    ID			CHR	    POS		A1	A1_FREQ		   BETA		SE			P
# rs146155542_T_C	10	7584321		T	0.00106437	3.65261		0.586105	4.67266e-10
# rs182239226_C_T	10	7585610		C	0.00105696	3.73868		0.590452	2.45955e-10
# rs182243134_C_T	10	7587603		C	0.00110519	3.32922		0.570756	5.50556e-09
# rs77411694_C_T	10	7588079		C	0.00110443	3.54626		0.58388		1.26724e-09
# rs188031153_A_G	10	7588195		A	0.00103794	3.45791		0.61136		1.56399e-08
# rs371272412_G_T	10	7590218		G	0.000652296	4.88179		0.741275	4.61123e-11
# rs760326718_G_C	10	12865140	G	0.000815172	3.82626		0.688337	2.74337e-08
# rs34820178_T_C	10	113901194	T	0.244546	0.234147	0.0420012	2.50192e-08
# rs58175211_C_T	10	113901637	C	0.244817	0.232486	0.0419736	3.07253e-08






 
## +++ Run through chromosomes having significant hits with cojo:
#
# Each chromosome is run as a whole:  ( see Mail_Zhili_March12.txt)  
# 
#   From: Zhili Zheng <zhili.zheng@uq.edu.au> 
#   Sent: Thursday, 12 March 2020 06:38
#   To: Uwe Menzel <uwe.menzel@medsci.uu.se>
#   Subject: Re: Question regarding GCTA-COJO (LInkage disequilibrium)
# 
#   Hi Uwe,
# 
#   Run as a whole shall be a best approach.  
#   Run in each region will not speed it up [...],  
#   and also the region is not large enough, as the COJO run in 10Mb window. 
# 
#   Regards,
#   Zhili


let i=0
for chrom in  ${chromosomes[*]}     
do

  let i++
  
  prune_log="${ident}_${phenoname}_cojo_chrom${chrom}.log"	# sbatch log for cojo_chr   
  # c_ident=${ident}"-"${chrom}
  c_ident="COJO-${chrom}"  
  out_prefix="${ident}_${phenoname}_cojo_chr${chrom}"  		# OBS! also used in "cojo_collect.sh" called  below  

  echo "" | tee -a ${log}
  echo "  sbatch --dependency=afterok:${convert_jobid} -A ${account} -p ${partition}  -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \  "  | tee -a ${log} 
  echo "  cojo_chr --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} --colline ${collinearity}  --maf ${maf} \  "  | tee -a ${log} 
  echo "           --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix}" | tee -a ${log} 
  
  # 512 GB job: only 3 nodes available on Bianca !! long queue times   # -C mem256GB  -C mem512GB
  # jobid=$( sbatch --dependency=afterok:${convert_jobid} -A ${account} -p ${partition} -C mem512GB -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \
  #          cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} --colline ${collinearity} --maf ${maf} --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix} ) 

  jobid=$( sbatch --dependency=afterok:${convert_jobid} -A ${account} -p ${partition} -t ${time}  -J ${c_ident} -o ${prune_log} -e ${prune_log}  \
          cojo_chr  --id ${ident}  --genoid  ${genoid} --chr ${chrom} --pval ${pval} --window ${window} --colline ${collinearity} --maf ${maf} --summary ${summary_file} --siglist ${signif_list} --out ${out_prefix} ) 

  jobid=$( echo $jobid | awk '{print $NF}' ) 
  echo "  JobID for chromosome ${chrom} : ${jobid}" | tee -a ${log}
  echo ""  | tee -a ${log} 
   
  # ${summary_file} = summary statistics for all chromosomes (*.ma), created in cojo_convert.sh  
  
  if [ "$i" -eq 1 ]; then
    liste="${jobid}"
  else
    liste="${liste}:${jobid}"  # list of jobid's for all cojo_chr.sh jobs
  fi
 
done   
 
echo "" | tee -a ${log} 
echo "" | tee -a ${log} 





## +++ Concatenate output files for individual chromosomes:  

# cojo_collect_time="10:00"		#  moved to ~/cojo_settings.sh requested runtime for "cojo_collect.sh" 
c_ident="COLLECT"			# jobname SLURM  

echo "  sbatch --dependency=afterok:${liste} -A ${account} -p ${partition}  -t ${cojo_collect_time}  -J ${c_ident} -o ${collect_log} -e ${collect_log} \ " | tee -a ${log} 
echo "  cojo_collect  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --summary ${summary_file} --out ${signif_file} "  | tee -a ${log} 

collect_jobid=$( sbatch --dependency=afterok:${liste} -A ${account} -p ${partition}  -t ${cojo_collect_time}  -J ${c_ident} -o ${collect_log} -e ${collect_log} \
       cojo_collect  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --summary ${summary_file} --out ${signif_file} )  
collect_jobid=$( echo $collect_jobid | awk '{print $NF}' )
echo "  JobID for cojo-collect : ${collect_jobid}" | tee -a ${log} 
echo "" | tee -a ${log} 







## +++ Clean 

# cojo_clean_time="10:00"					#  moved to ~/cojo_settings.sh requested runtime for "cojo_clean.sh" 
c_ident="CLEAN"							# jobname SLURM  

if [ "$keepma" -eq 1 ];then  # add command line parameter --keepma  : keep summary statistics file (*.ma) istead of deleting it in cojo_clean 

  echo "  sbatch --dependency=afterok:${collect_jobid} -A ${account} -p ${partition}  -t ${cojo_clean_time}  -J ${c_ident} -o ${clean_log} -e ${clean_log}  \ " | tee -a ${log} 
  echo "  cojo_clean  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --keepma" | tee -a ${log} 

  clean_jobid=$( sbatch --dependency=afterok:${collect_jobid} -A ${account} -p ${partition}  -t ${cojo_clean_time}  -J ${c_ident} -o ${clean_log} -e ${clean_log}  \
	  cojo_clean  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} --keepma )   

else

  echo "  sbatch --dependency=afterok:${collect_jobid} -A ${account} -p ${partition}  -t ${cojo_clean_time}  -J ${c_ident} -o ${clean_log} -e ${clean_log}  \ " | tee -a ${log} 
  echo "  cojo_clean  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop}" | tee -a ${log} 

  clean_jobid=$( sbatch --dependency=afterok:${collect_jobid} -A ${account} -p ${partition}  -t ${cojo_clean_time}  -J ${c_ident} -o ${clean_log} -e ${clean_log}  \
	  cojo_clean  --id ${ident} --phenoname ${phenoname} --cstart ${cstart}  --cstop ${cstop} )   

fi

clean_jobid=$( echo $clean_jobid | awk '{print $NF}' )
echo "  JobID for cojo-clean : ${clean_jobid}" | tee -a ${log}
echo "" | tee -a ${log} 







## +++ Finish  

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "  Run time: $DIFF seconds"| tee -a ${log}
echo "" | tee -a ${log}
echo "  Table of independent markers being created: ${signif_file}" | tee -a ${log}   # this file is not available at this point (job still in queue)! 
echo "" | tee -a ${log} 
echo -n "  "  | tee -a ${log}
date | tee -a ${log}
echo "  Done." | tee -a ${log}
echo "" | tee -a ${log}
 
 






 
 
 
 
 
 
