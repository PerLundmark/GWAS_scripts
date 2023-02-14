
/*
 * Pipeline for running the MolEpi GWAS scripts.
 *
 * Per Lundmark, Molecular Epidemiology, Uppsala University
 * 
 * Based in part on shell code from Uwe Menzel, Molecular Epidemiology, Uppsala University
 *
 */


/*
 * Pipeline input defaults.
 * Specify on command line or give config file to override defaults.  TODO config templates for users
 * 
 */

nextflow.enable.dsl=2


params.base_runfolder = "/proj/sens2019512/nobackup/users/perl/gwas_test/testruns"

//Given on comand line, no defaults here
//params.id
//params.phenofile  
//params.phenoname 

//GWAS regression and globals
params.account = "sens2019512"

//params.chr = "1-22"
params.chr = "19,20"
//params.genoid = "scapis_test_chr1_dedup"
//params.genofolder = "/proj/sens2019512/nobackup/users/perl/gwas_test/GENOTYPES/PGEN"

//params.phenofolder = "/proj/sens2019512/nobackup/users/perl/gwas_test/PHENOTYPES"
//params.covarpath = "/proj/sens2019512/nobackup/users/perl/gwas_test/PHENOTYPES"
//params.covarfile = "phenotypes_for_plink_211015.txt"

params.assoc = "regenie" //Select regenie or plink2 for association testing
//params.assoc = "plink2" //Select regenie or plink2 for association testing
params.script_dir = "/home/per/source/GWAS_scripts/GWAS_SCRIPTS"


//General assoc / plink2 settings
params.covarnames = "AgeAtVisitOne"
params.maf = "0.00"
params.mac = "30"
params.vif = "10"
params.hwe = "1.0e-6"
params.mr2 = "0.8 2.0" //TODO: split this setting up and use lower for regenie as well, no so nice w space sep param?
params.geno = "0.1"
params.mind = "0.1"
params.plink2_version="plink2/2.00-alpha-2.3-20200124"
params.gwas_partition = "node"
params.minspace=1  //Old default 1 000 000 000

//regenie settings
params.bsize1 = '1000'
params.bsize2 = '400'
//params.step1_extract = "markerlist_for_inclusion.list" // List of markers from the full dataset to retain for step1 whole genome regression
params.trait_type = 'qt'   //qt / bt    //TODO: Could add automatic detection since running every phenotype separately, perhaps not worth the risk
//params.trait_type = 'bt'   //qt / bt
params.info = 0.7 //Info score cutoff for imputed data, use params.mr2 above for plink2
params.covarnames_cat = "" // Need to add categorical covars separately
params.regenie_step1_geno = "regenie_step1/scapis_regenie_step1_all" //Base name of whole genome genotype set to be used for regenie step 1


//cojo settings
params.cojo_ref_bed_genoid = "BED/test_data_pipeline_sorted"
params.cojo_pval = '5e-8'
params.cojo_window = '10000'
params.cojo_colline = '0.9'
params.cojo_maf = '' //Need this? Should be set at higher level in the script not specific to the cojo analysis?
params.run_cojo = true


//report settings
params.review_minutes = "90"


//Process chromosome list
clean_chr = params.chr.replaceAll("\\s","") //Remove any whitespace
chr_entries = clean_chr.split(',')
chromosomes = []
chr_entries.each{
    clean_chr_entry = it.replaceAll("\\s","")
    curr_entry = clean_chr_entry.split('-')
    if (curr_entry.size() == 1){
        chromosomes.addAll(curr_entry)
    }else if(curr_entry.size() == 2){
        chromosomes.addAll(curr_entry[0]..curr_entry[1])
    }else{
        println("Unable to parse chromosomes")
        system.exit(1)
    }
}
//Channel with specified chromosomes for analysis
chr_channel = Channel.fromList(chromosomes)


//Process phenotype name list
clean_phenoname = params.phenoname.replaceAll("\\s","") //Remove any whitespace
pn_entries = clean_phenoname.split(',')
phenonames = []
pn_entries.each{
    phenonames.add(it)
}

//Channel with phenotypes
pheno_channel = Channel.fromPath(params.phenofile) //Just use file() ? https://groups.google.com/g/nextflow/c/ifZZ6g7hCBo
phenoname_channel = Channel.fromList(phenonames)

/*
 * Run main GWAS script (regressions) 
 */

//process run_GWAS_wrapper{
//    label 'std_job_1_core'
//    
//    output:
//    path '*.glm.*'
//    path '*_gwas_signif.txt'
//    path '*_gwas_params.txt'
//    path '*.Rdata'
//
//    script:
//    """
//    cd ${params.base_runfolder}
//    run_gwas.sh --id ${params.id} --phenofile ${params.phenofile} --phenoname ${params.phenoname} --chr ${params.chr} \
//    --genoid ${params.genoid} --phenofolder ${params.phenofolder} --covarfile ${params.covarfile} --covarname ${params.covarnames} \
//    --maf ${params.maf} --mac ${params.mac} --vif ${params.vif} --hwe ${params.hwe} --mr2 "${params.mr2}" --geno ${params.geno} \
//    --mind ${params.mind} --minutes ${params.gwas_minutes} --ask ${params.ask}
//    """
//}

/*
 * Log init, etc. before regression,
 * moved here from master gwas shell script (run_gwas.sh)
 */

process init_log{
    label 'short_job_1_core'
    publishDir "./${params.id}/association" //Collect output into this dir

    output:
    path '*_gwas.log'

    script:

    """
    log="${params.id}_gwas.log"   # master logfile 
    echo ""  > \${log}
    echo ""   | tee -a \${log}
    echo -n "  "  | tee -a \${log}
    date | tee -a \${log}
    echo "  Account: \${params.account}" | tee -a \${log}
    echo -n "  Operated by: " | tee -a \${log} 
    whoami | tee -a \${log} 
    echo "  Job identifier: " ${params.id} | tee -a \${log}
    echo "  Master logfile: \${log}" | tee -a \${log}
    echo "" | tee -a \${log}
    echo "  Running on chromosomes ${chromosomes}" | tee -a \${log}  
    echo "  Genotype input folder: ${params.genofolder}"  | tee -a \${log}
    echo "  Genotype identifier: ${params.genoid}" | tee -a \${log}
    echo "  Phenotype input file: ${params.phenofile}"  | tee -a \${log} 
    echo "  Phenotype column name(s): ${params.phenoname}"  | tee -a \${log}
    echo "  Covariate input file: ${params.covarfile}"  | tee -a \${log} 
    echo "  Covariate column name(s): ${params.covarnames}"  | tee -a \${log}
    echo "" | tee -a \${log}
    echo "  Threshold for minor allele count (mac): ${params.mac}" | tee -a \${log}
    echo "  Threshold for minor allele frequency (maf): ${params.maf}" | tee -a \${log}
    echo "  Maximum variance inflation factor (vif): ${params.vif}" | tee -a \${log}
    echo "  Maximum missing call rate for markers: ${params.geno} " | tee -a \${log}
    echo "  Maximum missing call rate for samples: ${params.mind} " | tee -a \${log}
    echo "  Threshold for Hardy-Weinberg p-value: ${params.hwe}"  | tee -a \${log}
    echo "  Imputation quality range (mach-r2): ${params.mr2}" | tee -a \${log}
    echo "" | tee -a \${log}
    echo "  Requested partition: ${params.gwas_partition}" | tee -a \${log}
    echo "" | tee -a \${log}
    """
}




process test_redir{
    label 'short_job_16_core'
    publishDir "${params.id}/association" 

    output:
    path 'test_ut*'

    script:
    
    """
    {
      ls
      du -h
    } 2>&1 | tee -a test_ut_chr1.log
    """
}




/*
 * Run plink regressions for GWAS analysis on a single chr.
 */

process run_plink_regression{
    label 'long_job_16_core'
    label 'plink2'
    publishDir "${params.id}/association"

    input:
    val chr
    val params.phenofile

    output:
    path '*_gwas_chrom*.log', emit: assoc_log
    path '*.glm.*', emit: assoc_results //Association results from linear, or logistic/firth reg.
   

    script:
    pgen_prefix = "${params.genofolder}/${params.genoid}_chr${chr}"
    logchr      = "${params.id}_gwas_chrom${chr}.log"
    
    """
    ## Header for per chr log
    { echo ""
    START=\$(date +%s) 
    echo -n "  "
    date 
    echo "  Job identifier: " ${params.id}
    echo "  Starting job for chromosome ${chr}"
    echo "  Genotype input file prefix: ${pgen_prefix}"
    echo "  Phenotype file: ${params.phenofile}"
    echo "  Phenotype name(s): ${params.phenoname}"
    echo "  Covariate file: ${params.covarfile}"
    echo "  Covariate name(s): ${params.covarnames}"
    echo "  Threshold for minor allele frequency (mac): ${params.mac}"
    echo "  Threshold for Hardy-Weinberg p-value: ${params.hwe}"
    echo "  Mach-r2 imputation quality range: ${params.mr2}"
    echo "  Threshold for minor allele frequency (maf): ${params.maf}"
    echo "  Maximum variance inflation factor (vif): ${params.vif}" 
    echo "  Maximum missing call rate for markers: ${params.geno} " 
    echo "  Maximum missing call rate for samples: ${params.mind} " 
    echo ""
    
    # Check if phenofile, covarfile is available
    if [ ! -f ${params.phenofile} ]; then
        echo ""
        echo "  ERROR: Phenotype input file '${params.phenofile}' not found."
        echo ""
        exit 1
    else
        num_samples=\$( wc -l ${params.phenofile} | awk '{print \$1}' )
        num_samples=\$(( \${num_samples} - 1 ))
        echo "  Phenotype file available, with \${num_samples} samples."   
    fi

    if [ ! -f ${params.covarfile} ]; then
        echo ""
        echo "  ERROR (gwas_chr.sh): Covariate input file '${params.covarfile}' not found."
        echo ""
        exit 1
    else
        num_samples=\$( wc -l ${params.covarfile} | awk '{print \$1}' )
        num_samples=\$(( \${num_samples} - 1 ))
        echo "  Covariates file available, with \${num_samples} samples." 
        clist=\$( echo ${params.covarnames} | sed 's/,/ /g' )
        for name in  \${clist[*]}
        do
            indicator=\$( head -1 ${params.covarfile} | grep \${name} | wc -l )
            if [ \$indicator -ne 1 ]; then
                echo ""
                echo "  ERROR (gwas_chr.sh): Covariate file '${params.covarfile}' does not contain the column '\${name}'"
                echo ""
                exit 1
            fi
        done
    fi
    echo ""

    # TODO: Consider replacing with groovy code and avooid all the file creation below for the sets

    # Find the samples which are common to genotype, phenotype, and covariates
    # consider only these samples in the regression, so that QC is done on these samples only 

    rnum=\$(( 1 + RANDOM%10000 ))   # avoid interference with jobs running parallel

    geno_samples="geno_samples_chr${chr}_\${rnum}.txt"
    awk '{print \$2}' ${pgen_prefix}.psam | tail -n +2 | sort > \${geno_samples}

    covar_samples="covar_samples_chr${chr}_\${rnum}.txt"
    awk '{print \$2}' ${params.covarfile} | tail -n +2 | sort > \${covar_samples}

    pheno_samples="pheno_samples_chr${chr}_\${rnum}.txt"
    awk '{print \$2}' ${params.phenofile} | tail -n +2 | sort > \${pheno_samples}

    geno_covar_samples="geno_covar_samples_chr${chr}_\${rnum}.txt"
    comm -12 \${geno_samples} \${covar_samples} | sort > \${geno_covar_samples}

    files2keep="files2keep_chr${chr}_\${rnum}.txt"
    comm -12 \${geno_covar_samples} \${pheno_samples} | awk 'BEGIN{FS="\t"} {print \$1, \$1}' > \${files2keep}

    nr_common=\$( wc -l \${files2keep} | awk '{print \$1}' )

    echo "  We have \${nr_common} common samples in genotype, phenotype, and covariate files." 
    echo ""

    rm -f \${geno_samples} \${covar_samples} \${pheno_samples} \${geno_covar_samples} # for this chromosome


    # Run plink2 on a single chromosome for the regressions.
    outfile_prefix="${params.id}_gwas_chr"${chr} # OBS!! : Naming convention also used elsewhere!

    plink2 --glm hide-covar 'cols=chrom,pos,ref,alt1,a1freq,beta,se,p,nobs' \
        --pfile ${pgen_prefix} \
        --keep \${files2keep} \
        --pheno ${params.phenofile} --pheno-name ${params.phenoname} \
        --covar ${params.covarfile} --covar-name ${params.covarnames} \
        --no-psam-pheno \
        --covar-variance-standardize \
        --mac ${params.mac} \
        --maf ${params.maf} \
        --vif ${params.vif} \
        --mind ${params.mind} \
        --geno ${params.geno} \
        --hwe ${params.hwe} \
        --mach-r2-filter ${params.mr2} \
        --out \${outfile_prefix}

    # + Outfiles:   

    pname=\$( echo ${params.phenoname} | tr -s ',' '\t' )
    phenoarray=(\$pname)
    echo ""
    echo "  Number of elements in phenoname: \${#phenoarray[*]}" 
    echo ""
    echo "  Regression results: "

    for pname in  \${phenoarray[*]}
    do
        echo ""
        echo "  Phenoname: \$pname" 
        echo -n "    "
        out_glm_lin=\${outfile_prefix}"."\${pname}".glm.linear"    # linear regression
        out_glm_log=\${outfile_prefix}"."\${pname}".glm.logistic"  # logistic regression [ case/control ] 

        if [ ! -s "\${out_glm_lin}"  -a  ! -s "\${out_glm_log}"  ];then
            echo ""
            echo "  ERROR: No plink output file \"\${out_glm_lin}\" or \"\${out_glm_log}\" written."
            echo "                       See the error messages in the logfile ${params.id}_gwas_chrom${chr}_regression.log"   # logchr="${params.id}_gwas_chrom${chr}.log"
            echo "" 
            out_logf=\${outfile_prefix}".log"
            rm -f \${out_logf} \${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
            echo ""    
            exit 1
        fi

        if [ -s "\${out_glm_lin}" ];then
            ls -l \${out_glm_lin}
            entries=\$( wc -l \${out_glm_lin} | awk '{print \$1}' )
            entries=\$(( \${entries} - 1 ))
            echo "    Number of entries in output file (.glm.linear) for phenoname \"\${pname}\": \${entries}"
            num_NA=\$( cat \${out_glm_lin} | awk '{print \$NF}' | grep NA | wc -l )
            echo "    Number of entries with unassigned (NA) p-values: \${num_NA}"
            out_logf=\${outfile_prefix}".log"
        rm -f \${out_logf} \${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
        echo ""    
        fi

        if [ -s "\${out_glm_log}" ];then
            ls -l \${out_glm_log}
            entries=\$( wc -l \${out_glm_log} | awk '{print \$1}' )
            entries=\$(( \${entries} - 1 ))
            echo "    Number of entries in output file (.glm.logistic) for phenoname \"\${pname}\": \${entries}"
            num_NA=\$( cat \${out_glm_log} | awk '{print \$NF}' | grep NA | wc -l )
            echo "    Number of entries with unassigned (NA) p-values: \${num_NA}"
            out_logf=\${outfile_prefix}".log"
            rm -f \${out_logf} \${files2keep}  # OBS!: we delete the plink2 logfile because the batchlog is sufficient!  
            echo ""    
        fi

    done
    echo ""

    # Finish up logs 

    END=\$(date +%s)
    DIFF=\$(( \$END - \$START ))
    echo "  Run time: \$DIFF seconds" 
    echo "" 
    echo -n "  "  
    date
    echo "  Done." 
    echo "" 
    } 2>&1 | tee -a '${logchr}'
    """
}


process check_pheno_nonmissing{
    label 'short_job_1_core'
    label 'python3'
    publishDir "${params.id}/association"

    input:
    val phenotype_name

    output:
    tuple val(phenotype_name), path("nonmissing_*.list")

    script:

    """
    python3 ${params.script_dir}/list_no_NA_samples.py -i ${params.phenofile} -p ${phenotype_name} -o nonmissing_${phenotype_name}.list
    """
}



process run_regenie_step1{
    label 'long_job_16_core'
    publishDir "${params.id}/association"

    input:
    tuple val(phenotype_name), path(nonmiss_list)

    output:
    tuple val(phenotype_name), path('fit_out*')

    script:
    step1_pgen_prefix = "${params.genofolder}/${params.regenie_step1_geno}"

    //Check if covars set for options to allow skipping if unset
    if (params.covarnames){
        covarnames_checked = "--covarColList " + params.covarnames
    }else{
        covarnames_checked = ""
    }

    if (params.covarnames_cat){
        covarnames_cat_checked = "--catCovarList " + params.covarnames_cat
    }else{
        covarnames_cat_checked = ""
    }

    """
    #Skipping logging for now, pendig removal or not from plink2 implementation, should slim down shell code and adapt groovy solutions

    # regenie \
    #     --step 1 \
    #     --pgen ${step1_pgen_prefix} \
    #     --covarFile ${params.covarfile} ${covarnames_checked} ${covarnames_cat_checked} \
    #     --phenoFile ${params.phenofile} --phenoColList ${params.phenoname} \
    #     --${params.trait_type} \
    #     --bsize ${params.bsize1} \
    #     --lowmem \
    #     --lowmem-prefix tmp_rg \
    #     --out fit_out 

        regenie \
        --step 1 \
        --pgen ${step1_pgen_prefix} \
        --keep ${nonmiss_list} \
        --covarFile ${params.covarfile} ${covarnames_checked} ${covarnames_cat_checked} \
        --phenoFile ${params.phenofile} --phenoColList ${phenotype_name} \
        --${params.trait_type} \
        --bsize ${params.bsize1} \
        --lowmem \
        --lowmem-prefix tmp_rg \
        --out fit_out_${phenotype_name}

    """



}

process run_regenie_step2{
    label 'long_job_16_core'
    publishDir "${params.id}/association"

    input:
    each chr
    tuple val(phenotype_name), path(step1_fit_out)

    output:
    //path '*_gwas_chr*.log', emit: assoc_log
    //path '*.regenie', emit: assoc_results
    tuple val(phenotype_name), path('*.regenie'), path('*_gwas_chr*.log')

    script:
    pgen_prefix = "${params.genofolder}/${params.genoid}_chr${chr}"
    logchr      = "${params.id}_gwas_chrom${chr}.log"

    //Check if covars set for options to allow skipping if unset
    if (params.covarnames){
        covarnames_checked = "--covarColList " + params.covarnames
    }else{
        covarnames_checked = ""
    }

    if (params.covarnames_cat){
        covarnames_cat_checked = "--catCovarList " + params.covarnames_cat
    }else{
        covarnames_cat_checked = ""
    }

    """
    #Skipping logging for now, pendig removal or not from plink2 implementation, should slim down shell code and adapt groovy solutions

    #outfile_prefix="${params.id}_gwas_chr"${chr} # OBS!! : Naming convention also used elsewhere!
    outfile_prefix="${params.id}_gwas_chr${chr}_${phenotype_name}" # OBS!! : Naming convention also used elsewhere!

    regenie \
        --step 2 \
        --pgen ${pgen_prefix} \
        --covarFile ${params.covarfile} ${covarnames_checked} ${covarnames_cat_checked} \
        --phenoFile ${params.phenofile} --phenoColList ${phenotype_name} \
        --${params.trait_type} \
        --bsize ${params.bsize2} \
        --pred fit_out_${phenotype_name}_pred.list \
        --out \${outfile_prefix} \
        --minMAC ${params.mac} \
        --minINFO ${params.info}
    """

}


//Dropping cojo temporarily for testrun (error)

//Convert association test output to cojo input format
process convert_cojo_input_regenie{
    label 'std_job_1_core'
    label 'python3'
    publishDir "${params.id}/cojo"

    input:
    tuple val(phenotype_name), path(assoc_results), path(assoc_log)

    output:
    //tuple val(phenotype_name), path(assoc_results), path(assoc_log)
    tuple val(phenotype_name), path('*.ma')

    script:
    """
    #Combine regenie output for all chr into one file
    tail -n +2 -q *.regenie > sumstat_${phenotype_name}.regenie
    
    #Convert to cojo input format
    python3 ${params.script_dir}/convert_regenie_to_cojo.py -i sumstat_${phenotype_name}.regenie -o ${params.id}_cojo_input_${phenotype_name}.ma

    """

}

//Run cojo selection of independent associated variants
process run_cojo {
    label 'long_job_16_core'
    label 'gcta'

    input:
    each chr
    tuple val(phenotype_name), path(cojo_input_file)

    output:
    tuple val(phenotype_name), path('*.jma.cojo') 


    script:

    """
    gcta64  --bfile ${params.genofolder}/${params.cojo_ref_bed_genoid}_chr${chr}  --thread-num 16 --chr ${chr} --cojo-file ${cojo_input_file} --cojo-slct --cojo-p ${params.cojo_pval} --cojo-wind ${params.cojo_window} --cojo-collinear ${params.cojo_colline} --out ${params.id}_${phenotype_name}_chr${chr}
    """

//ref for dev from settings
//cojo settings
//params.cojo_pval = '5e-8'
//params.cojo_window = '10000'
//params.cojo_colline = '0.9'
//params.cojo_maf = '' //Need this? Should be set at higher level in the script not specific to the cojo analysis?
}




/*
 * Create a parameter file with information for the 
 * review script.
 */

process create_parameterfile{
    label 'short_job_1_core'
    publishDir "${params.id}/association"

    output:
    path '*_gwas_params.txt'

    script:

    """
    paramfile="${params.id}_gwas_params.txt"    # Naming convention is also used in "review-GWAS.R". Do NOT change here without changing there!  
    echo -n > \${paramfile}
    workfolder="${params.id}"
    echo "plink2_version ${params.plink2_version}" >> \${paramfile}
    echo "workfolder \${workfolder}" >> \${paramfile} 
    echo "ident ${params.id}" >> \${paramfile}
    echo "cstart ${chromosomes[0]}" >> \${paramfile} 
    echo "cstop ${chromosomes[-1]}" >> \${paramfile}
    echo "genotype_id ${params.genoid}" >> \${paramfile}
    echo "phenofile ${params.phenofile}" >> \${paramfile}
    echo "phenoname ${params.phenoname}" >> \${paramfile}
    echo "covarfile ${params.covarfile}" >> \${paramfile}
    echo "covarname ${params.covarnames}" >> \${paramfile}
    echo "mac ${params.mac}" >> \${paramfile}
    echo "maf ${params.maf}" >> \${paramfile}
    echo "vif ${params.vif}" >> \${paramfile}
    echo "sample_max_miss ${params.mind}" >> \${paramfile}
    echo "marker_max_miss ${params.geno}" >> \${paramfile}
    echo "hwe_pval ${params.hwe}" >> \${paramfile} 
    machr2_low=\$( echo ${params.mr2}|awk '{print \$1}' )
    machr2_high=\$( echo ${params.mr2}|awk '{print \$2}' )
    echo "machr2_low \${machr2_low}" >> \${paramfile}
    echo "machr2_high \${machr2_high}" >> \${paramfile}

    echo "regenie_bsize1 ${params.bsize1}" >> \${paramfile}
    echo "regenie_bsize2 ${params.bsize2}" >> \${paramfile}
    echo "regenie_trait_type ${params.trait_type}" >> \${paramfile}
    echo "regenie_info ${params.info}" >> \${paramfile}
    echo "regenie_covarnames_cat ${params.covarnames_cat}" >> \${paramfile}
    """
}


/*
 * Finish up logging from plink regression 
 */

process finish_log{
    label 'short_job_1_core'
    publishDir "${params.id}/association"

    input:
    path 'old.log' 

    output:
    path '*_gwas.log'

    script:
    newlog = params.id + "_gwas.log"
    //println(newlog)

    """
    cp old.log ${newlog}
    echo "" | tee -a ${newlog}
    echo -n "  "  | tee -a ${newlog}
    date | tee -a ${newlog}
    echo "  Done." | tee -a ${newlog}
    echo "" | tee -a ${newlog}
    """
}









/*
 * Run reporting script (creates a html report for GWAS results)
 */

//TODO: Get gwas_params from output of the process creating it.
// Stop using params file, just create variables for it nad pass it to the process and R script (expand parameters in both)

process create_report_plink {
    label 'long_job_16_core'
    label 'R_4_1_1'
    publishDir "${params.id}/association"
    
    input:
    path gwas_params
    val pname
    val chromosomes
    path assoc_results
    path assoc_log

    output:
    path '*.html'

    
    script:
    chrom_str = chromosomes.join(',')
    
    """
    echo "${chrom_str}"

    ${params.script_dir}/review_gwas_plink2.R ${params.id} ${pname} ${chrom_str} ${params.script_dir}
    """
}


process create_report_regenie {
    label 'long_job_16_core'
    label 'R_4_1_1'
    publishDir "${params.id}/report"

    input:
    path gwas_params
    //val pname
    val chromosomes
    //path assoc_results
    //path assoc_log

    tuple val(pname), path(assoc_results), path(assoc_log)
    //tuple val(phenotype_name), path('*.regenie'), path('*_gwas_chr*.log')

    output:
    path '*.html'
    
    
    //path gwas_signif
    //path gwas_sumstats
    //path gwas_data

    
    script:
    chrom_str = chromosomes.join(',')
    
    """
    #echo "${chrom_str}"

    ${params.script_dir}/review_gwas_regenie.R ${params.id} ${pname} ${chrom_str} ${params.script_dir}
    """
}


// Main workflow definition
workflow{
    init_log()
    
    if (params.assoc == "plink2"){
        run_plink_regression(chr_channel, pheno_channel)
    }else if (params.assoc == "regenie"){
        check_pheno_nonmissing(phenoname_channel)
        run_regenie_step1(check_pheno_nonmissing.out)
        run_regenie_step2(chr_channel, run_regenie_step1.out)
        if(params.run_cojo){
            convert_cojo_input_regenie(run_regenie_step2.out.groupTuple())
            run_cojo(chr_channel, convert_cojo_input_regenie.out.groupTuple())

        }
    }

    create_parameterfile()
    finish_log(init_log.out)

    if(params.assoc == 'plink2'){
        create_report_plink(create_parameterfile.out, phenoname_channel, chr_channel.collect(), run_plink_regression.out.assoc_results.collect(), run_plink_regression.out.assoc_log.collect())
    }
    else if(params.assoc == 'regenie'){
        //create_report_regenie(create_parameterfile.out, phenoname_channel, chr_channel.collect(), run_regenie_step2.out.assoc_results.collect(), run_regenie_step2.out.assoc_log.collect())
        create_report_regenie(create_parameterfile.out, chr_channel.collect(), run_regenie_step2.out.groupTuple())
    }
}


//Add check for consequences of variation for example the ensembl tool instead of just gene link and nearest gene stuff.
