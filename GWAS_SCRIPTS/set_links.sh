#!/usr/bin/env bash

# uwe.menzel@medsci.uu.se  



## === Set soflinks to executable programs


echo ""
echo "  Setting som links ..."
echo ""


ln -s review_gwas.sh  review_gwas
ln -s gwas_chr.sh  gwas_chr
ln -s run_gwas.sh  run_gwas
ln -s run_cojo.sh  run_cojo
ln -s cojo_pheno.sh  cojo_pheno
ln -s cojo_convert.sh cojo_convert 
ln -s cojo_chr.sh  cojo_chr
ln -s cojo_collect.sh cojo_collect 
ln -s cojo_clean.sh cojo_clean 
ln -s clump_chr.sh  clump_chr
ln -s clump_pheno.sh clump_pheno 
ln -s run_clump.sh  run_clump 
ln -s clump_collect.sh clump_collect  
ln -s cojo_allele.R cojo_allele  
ln -s archive_gwas.sh archive_gwas   
ln -s retrieve_gwas.sh retrieve_gwas  
ln -s tar_gwas.sh  tar_gwas 
ln -s untar_gwas.sh untar_gwas   
ln -s recap_gwas.sh recap_gwas  
ln -s convert_phenofile.R convert_phenofile  
ln -s transform_phenotypes.R transform_phenotypes 

echo ""
echo " Done."
echo ""

