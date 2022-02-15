#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  


 

## === Get effect allele and other allele for a given marker 


#  get_alleles --snp rs9909966    # non-unique marker name (2 hits)
#  get_alleles --snp rs78839237   # non-unique marker name (3 hits)
#  get_alleles --snp rs113220767  # non-unique marker name (6 hits)
#  get_alleles --snp rs552421489  # unique marker name 



account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' )

account_set=0

if [ "$account" == "sens2019016" ]; then
  genotype_prefix="ukb_imp_v3_chr"
  account_set=1
fi

if [ "$account" == "sens2019570" ]; then
  genotype_prefix="ukb_570_chr"
  account_set=1  
fi

if [ "$account_set" -eq "0" ];then
  echo ""
  echo "  Sorry, we are not prepared for account '${account}'." 
  echo ""
  exit 1 
fi



if [ ! -d "/proj/${account}/GENOTYPES/PGEN_ORIG" ]; then  
  echo ""
  echo "  Sorry, we need the folder ' /proj/${account}/GENOTYPES/PGEN_ORIG '." 
  echo ""
  exit 1 
fi


num=$( ls /proj/${account}/GENOTYPES/PGEN_ORIG/${genotype_prefix}*.pvar | wc -l )

if [[ "$num" != 22 ]]; then
  echo ""
  echo "  Sorry, the .pvar files in /proj/${account}/GENOTYPES/PGEN_ORIG are missing."
  echo ""
  exit 1
fi





## +++ Command line parameter:

prog=$( basename "$0" )

if [ "$#" -lt 1 ]; then
  echo ""
  echo "  Usage: ${prog}  --snp <string>"
  echo ""
  exit 1
fi




while [ "$#" -gt 0 ]
do
  case $1 in
      -s|--snp)
          snp=$2
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



echo ""
echo "  Marker: ${snp}"
echo ""




## +++ Find alleles

# /proj/${account}/GENOTYPES/PGEN_ORIG > head FTD_chr4.pvar
# #CHROM	POS	ID	REF	ALT
# 4	10005	rs531254437	TA	T
# 4	10202	rs552421489	T	A
# 4	10227	rs570570911	G	C
# 4	10229	rs754928884	C	T
# 4	10234	rs538005321	A	G
# 4	10237	rs376249745	C	G
# 4	10253	rs575854682	T	G
# 4	10287	rs536728663	T	G
# 4	10300	rs555030267	C	T


result=$( grep -h "\b${snp}\b"   /proj/${account}/GENOTYPES/PGEN_ORIG/${genotype_prefix}*.pvar ) 
  
if [ -z "$result" ]; then
  echo "  Sorry, nothing found in chr 1 - 22"
  echo ""
  exit 0
fi



array=($result)

length=$( echo "${#array[@]}" )   # multiples of 5 are okay (e.g. 10 would mean two entries for this marker)  


rem=$((${length}%5))

if [[ "$rem" != 0 ]]; then
  echo ""
  echo "  The result seems to be incorrect (should include multiples of 5 entries):"
  echo ""
  echo "  ${result}"
  echo ""
  exit 1
fi 


hits=$(( ${length} / 5 ))

echo "  Number of markers found: ${hits}"
echo ""



for i in $(seq 1 $hits);do
  echo "  Hit-nr: $i"
  offset=$(($i-1))
  offset=$(($offset * 5))  
  uname=$( echo "${array[2+$offset]}_${array[3+$offset]}_${array[4+$offset]}"  )  
  
  echo "  Chromosome: ${array[0+$offset]}"   
  echo "  Position: ${array[1+$offset]}"
  echo "  Reference allele: ${array[3+$offset]}"
  echo "  Alternate allele: ${array[4+$offset]}"
  echo "  Unique name: ${uname}"
  echo ""
   
done



exit 0











