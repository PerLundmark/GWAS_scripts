#!/usr/bin/env bash  



# uwe.menzel@medsci.uu.se  

  
   
## ===  Apply a filter on a phenotype file 



# filter_pheno --pheno pheno_faked.txt --filter caucasian_22006.txt --c1 1  --c2 1
  







## +++ Hardcoded settings & and defaults 

# uniq_only=0
uniq_only=1    # allow joining on columns with unique entries only.






## +++ Command line parameters:   

if [ "$#" -lt 8 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog}"
  echo "        --pheno <pheno_file>     no default"
  echo "        --filter <filter_file>   no default"
  echo "        --c1 <column1>       	 no default"  
  echo "        --c2 <column2>           no default"      
  echo ""
  if [ "$uniq_only" -eq "1" ];then
    echo "  Joining is only possible on columns with unique entries."
    echo ""
  fi
  exit 1
fi



# pheno_file="pheno_faked.txt"  # /proj/sens2019016/GWAS_TEST
# 
# head ${pheno_file}
# 
# IID pheno
# 5954653 0.291066
# 1737609 0.845814
# 1427013 0.152208
# 3443403 0.585537
# 5807741 0.193475
# 4188953 0.810623
# 1821438 0.173531
# 3951387 0.484983
# 5670866 0.151863



# ls /proj/sens2019016/FILTER  # caucasian_22006.txt  female.txt  male.txt  pca_used_22020.txt
#
# filter_file="/proj/sens2019016/FILTER/caucasian_22006.txt"
# 
# head ${filter_file}
# 
# IID
# 1000027
# 1000039
# 1000040
# 1000053
# 1000064
# 1000071
# 1000088
# 1000096
# 1000109



while [ "$#" -gt 0 ]
do
  case $1 in
       --pheno)
       pheno_file=$2
       shift
       ;;
       --filter)
       filter_file=$2
       shift
       ;;      
       --c1)
       col1=$2
       shift
       ;; 
       --c2)
       col2=$2
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

to_test=(pheno_file filter_file col1 col2)

for var in  ${to_test[*]}     
do
  if [ -z ${!var+x} ];then
    echo ""
    echo "  ERROR (filter_pheno.sh): mandatory variable ' $var ' is not defined."
    echo ""
  fi    
done







## +++ Check input:

if [ ! -s ${pheno_file} ]; then
  echo ""
  echo "  ERROR (filter_pheno.sh): Input file '${pheno_file}' not found." 
  echo ""
  exit 1
fi
 

if [ ! -s ${filter_file} ]; then
  echo ""
  echo "  ERROR (filter_pheno.sh): Input file '${filter_file}' not found." 
  echo ""
  exit 1
fi


if [[ ! ${col1} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (filter_pheno.sh): col1 must be an integer, not ${col1}." 
  echo ""
  exit 1  
fi   


if [[ ! ${col2} =~ ^[0-9]+$ ]];then
  echo ""
  echo  "  ERROR (filter_pheno.sh): col2 must be an integer, not ${col2}." 
  echo ""
  exit 1  
fi   





sed '/^[[:space:]]*$/d' ${pheno_file} > f1_temp.txt
mv f1_temp.txt ${pheno_file}

sed '/^[[:space:]]*$/d' ${filter_file} > f2_temp.txt
mv f2_temp.txt ${filter_file}



if [ "$uniq_only" -eq "1" ];then   # allow columns with unique identifiers only

  rep1=$( awk -v c=${col1} '{print $c}' ${pheno_file} | sort | uniq -D | wc -l ) 
  if [ "$rep1" -ne "0" ]; then
    echo ""
    echo "  ERROR (filter_pheno.sh): You try to join on a column with non-unique entries in ' ${pheno_file}."
    echo ""
    exit 1
  fi  

  rep2=$( awk -v c=${col2} '{print $c}' ${filter_file} | sort | uniq -D | wc -l )
  if [ "$rep2" -ne "0" ]; then
    echo ""
    echo "  ERROR (filter_pheno.sh): You try to join on a column with non-unique entries in ' ${filter_file}."
    echo ""
    exit 1
  fi  

fi



ind1=$( gawk 'BEGIN{FS="\t"}{print NF}' ${pheno_file} | sort | uniq -c | wc -l | awk '{print $1}' )
if [ "$ind1" -ne "1" ];then 
  echo ""
  echo "  ERROR (filter_pheno.sh): File ' ${pheno_file} ' has unequal number of columns."
  echo ""
  exit 1
fi 

ind2=$( gawk 'BEGIN{FS="\t"}{print NF}' ${filter_file} | sort | uniq -c | wc -l | awk '{print $1}' )
if [ "$ind2" -ne "1" ];then 
  echo ""
  echo "  ERROR (filter_pheno.sh): File ' ${filter_file} ' has unequal number of columns."
  echo ""
  exit 1
fi 



nr_cols_1=$( gawk 'BEGIN{FS="\t"}{print NF}' ${pheno_file} | sort | uniq -c | awk '{print $2}' )

if [ "$col1" -gt "$nr_cols_1" ]; then
  echo ""
  echo "  ERROR (join_files.sh): File ' ${pheno_file} ' has only ${nr_cols_1} columns but you entered ${col1}."
  echo ""
  exit 1
fi  
 

nr_cols_2=$( gawk 'BEGIN{FS="\t"}{print NF}' ${filter_file} | sort | uniq -c | awk '{print $2}' )

if [ "$col2" -gt "$nr_cols_2" ]; then
  echo ""
  echo "  ERROR (join_files.sh): File ' ${filter_file} ' has only ${nr_cols_2} columns but you entered ${col2}."
  echo ""
  exit 1
fi  






## +++ Sort and join:

LANG=en_EN sort -k ${col1} ${pheno_file}  > ${pheno_file}.sorted
LANG=en_EN sort -k ${col2} ${filter_file} > ${filter_file}.sorted


f1=$(basename -- "$pheno_file")
f1="${f1%.*}"


outfile="${f1}.filtered"

# echo ${outfile}  # pheno_faked.filtered 



echo ""
echo "join -1 ${col1} -2 ${col2} --check-order ${pheno_file}.sorted ${filter_file}.sorted > ${outfile}"


head -1 ${pheno_file} | column -t > ${outfile}

LANG=en_EN join -1 ${col1} -2 ${col2} --check-order ${pheno_file}.sorted ${filter_file}.sorted | column -t >> ${outfile}    


nr_pheno=$( wc -l ${pheno_file} | awk '{print $1}' )
nr_pheno=$(( ${nr_pheno} - 1 ))

nr_filter=$( wc -l ${filter_file} | awk '{print $1}' )
nr_filter=$(( ${nr_filter} - 1 ))

nr_pheno_filtered=$( wc -l ${outfile} | awk '{print $1}' )
nr_pheno_filtered=$(( ${nr_pheno_filtered} - 1 ))

echo ""
echo "  Number of samples in phenotype file ' ${pheno_file} ': ${nr_pheno}"
echo "  Number of samples in filter file ' ${filter_file} ': ${nr_filter}"
echo "  Number of samples in filtered phenotype file ' ${outfile} ': ${nr_pheno_filtered}"
echo ""
ls -l ${outfile}
echo ""


rm ${pheno_file}.sorted ${filter_file}.sorted  

# uwe.menzel@medsci.uu.se

   












