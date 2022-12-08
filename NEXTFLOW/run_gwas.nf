
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
params.chr = "1"
params.genoid = "scapis_test_chr1_dedup"
params.genofolder = "/proj/sens2019512/nobackup/users/perl/gwas_test/GENOTYPES/PGEN" 

params.phenofolder = "/proj/sens2019512/nobackup/users/perl/gwas_test/testruns"
params.covarpath = "/proj/sens2019512/nobackup/users/perl/gwas_test/testruns"
params.covarfile = "phenotypes_for_plink_211015.txt"
params.covarname = "sex,bmi,plate.id"

params.maf = "0.00"
params.mac = "30"
params.vif = "10"
params.hwe = "1.0e-6"
params.mr2 = "0.8 2.0"
params.geno = "0.1"
params.mind = "0.1"
params.plink2_version="plink2/2.00-alpha-2.3-20200124"
params.gwas_partition = "node"
params.minspace=1  //Old default 1 000 000 000


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
pheno_channel = Channel.fromPath(params.phenofile)

/*
 * Run main GWAS script (regressions) TODO: Shift code from umbrella gwas script to nextflow scripts instead. Then run per chr from nextflow channel
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
//    --genoid ${params.genoid} --phenofolder ${params.phenofolder} --covarfile ${params.covarfile} --covarname ${params.covarname} \
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
    publishDir "./${params.id}/plink_regression" //Collect output into this dir

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
    echo "  Phenotype input folder: ${params.phenofolder}"  | tee -a \${log} 
    echo "  Phenotype input file: ${params.phenofile}"  | tee -a \${log} 
    echo "  Phenotype column name(s): ${params.phenoname}"  | tee -a \${log}
    echo "  Covariate input file: ${params.covarfile}"  | tee -a \${log} 
    echo "  Covariate column name(s): ${params.covarname}"  | tee -a \${log}
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
    publishDir "${params.id}/plink_regression" 

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
    label 'short_job_16_core'
    label 'plink2'
    publishDir "${params.id}/plink_regression"

    input:
    val chr
    path params.phenofile

    output:
    stdout
    path '*_gwas_chrom*.log'
    // Capture standard out from the shell block as output similar to the original script?

    script:
    pgen_prefix = "${params.genofolder}/${params.genoid}_chr${chr}"
    logchr      = "${params.id}_gwas_chrom${chr}.log"
    
    """
    ###### skipping gwas_chr.sh call, implementing in NF script instead
    # gwas_chr --gen ${pgen_prefix} --chr ${chr} --id ${params.id} --pheno ${params.phenofolder}/${params.phenofile} \
    #   --pname ${params.phenoname} --covar ${params.covarpath}/${params.covarfile} --cname ${params.covarname} \
    #   --mac ${params.mac} --maf ${params.maf} --vif ${params.vif} --mr2 ${params.mr2} --hwe ${params.hwe} --geno ${params.geno} \
    #   --mind ${params.mind} > $logchr 2>&1
    #####
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
    echo "  Covariate name(s): ${params.covarname}"
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
        echo "  ERROR: Input file '${params.phenofile}' not found."
        echo ""
        exit 1
    else
        num_samples=\$( wc -l ${params.phenofile} | awk '{print \$1}' )
        num_samples=\$(( \${num_samples} - 1 ))
        echo "  Phenotype file available, with \${num_samples} samples."   
    fi

    if [ ! -f ${params.covarfile} ]; then
        echo ""
        echo "  ERROR (gwas_chr.sh): Input file '${params.covarfile}' not found."
        echo ""
        exit 1
    else
        num_samples=\$( wc -l ${params.covarfile} | awk '{print \$1}' )
        num_samples=\$(( \${num_samples} - 1 ))
        echo "  Covariates file available, with \${num_samples} samples." 
        clist=\$( echo ${params.covarname} | sed 's/,/ /g' )
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
        --pheno ${params.phenofile} --pheno-name ${params.phenoname}\
        --covar ${params.covarfile} --covar-name ${params.covarname} \
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


/*
 * Create a parameter file with information for the 
 * review script.
 */

process create_parameterfile{
    label 'short_job_1_core'
    publishDir "${params.id}/plink_regression"

    output:
    path '*_gwas_params.txt'

    script:

    """
    paramfile="${params.id}_gwas_params.txt"    # Naming convention is also used in "review-GWAS.R". Do NOT change here without changing there!  
    echo -n > \${paramfile}
    workfolder="${params.id}/plink_regression"
    echo "plink2_version ${params.plink2_version}" >> \${paramfile}
    echo "workfolder \${workfolder}" >> \${paramfile} 
    echo "ident ${params.id}" >> \${paramfile}
    echo "cstart ${chromosomes[0]}" >> \${paramfile} 
    echo "cstop ${chromosomes[-1]}" >> \${paramfile}
    echo "genotype_id ${params.genoid}" >> \${paramfile}
    echo "phenofile ${params.phenofile}" >> \${paramfile}
    echo "phenoname ${params.phenoname}" >> \${paramfile}
    echo "covarfile ${params.covarfile}" >> \${paramfile}
    echo "covarname ${params.covarname}" >> \${paramfile}
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
    """
}


/*
 * Finish up logging from plink regression 
 */

process finish_log{
    label 'short_job_1_core'
    publishDir "${params.id}/plink_regression"

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

process create_report {
    label 'std_job_1_core'
    input:
    path gwas_params
    path gwas_signif
    path gwas_sumstats
    path gwas_data

    script:
    """
    cd ${params.base_runfolder}/${params.id}
    echo review_gwas.sh --id ${params.id} --phenoname ${params.phenoname} --chr ${params.chr} --minutes ${params.review_minutes}
    """
}


// Main workflow definition
workflow{
    init_log()
    run_plink_regression(chr_channel, pheno_channel)
    create_parameterfile()
    finish_log(init_log.out)
}

