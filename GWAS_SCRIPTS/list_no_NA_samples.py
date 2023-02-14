#!/usr/bin/env python3

#Script to extract individuals for a specific phenotype (in plink/regenie input) without NA, for filtering purposes

import argparse

arg_parser = argparse.ArgumentParser()

arg_parser.add_argument('-i', '--in_file', type=str, required=True, help='The phenotype file')
arg_parser.add_argument('-p', '--pheno', type=str, required=True, help='The phenotype name to scan for and count NAs in')
arg_parser.add_argument('-o', '--out_file', type=str, required=True, help='The list of individuals without NA for the given phenotype')

args = arg_parser.parse_args()

input_path  = args.in_file
pheno_name  = args.pheno
output_path = args.out_file

no_na_inds = []

with open(input_path, 'r') as data_file:
    header = data_file.readline()

    #Find index of phenotype of interest
    headers = header.strip().split("\t")
    pheno_index = headers.index(pheno_name)

    for row in data_file:
        fields = row.split("\t")
        fam_id = fields[0]
        ind_id = fields[1]
        pheno = fields[pheno_index]
        if (pheno != "NA"):
            no_na_inds.append(fam_id + "\t" + ind_id)
        

with open(output_path, 'w') as output_file:
    for id_row in no_na_inds:
        output_file.write(id_row + "\n")

