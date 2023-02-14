#!/usr/bin/env python3

#Script to convert regenie association output to GCTA cojo input 

import argparse
from decimal import Decimal

arg_parser = argparse.ArgumentParser()

arg_parser.add_argument('-i', '--in_file', type=str, required=True, help='Input file name (Regenie association output, .regenie-file)')
arg_parser.add_argument('-o', '--out_file', type=str, required=True, help='Output file name (for use as a GCTA-cojo input file, .ma)')

args = arg_parser.parse_args()

input_path  = args.in_file
output_path = args.out_file

with open(input_path, 'r') as data_file:
    with open(output_path, 'w') as output_file:
        #header = data_file.readline()   #Removed: No header in concatenated result file
        output_file.write("\t".join(['ID', 'A1', 'A2', 'FREQ', 'B', 'SE', 'P', 'N']) + "\n")
        for row in data_file:
            fields = row.split(" ")
            snp_id = fields[2]
            allele_1 = fields[4]    #effect allele, allele1 in reg. output! 
            allele_2 = fields[3]    #other allele, allele0 in reg.
            freq_1 = fields[5]      #freq effect allele
            beta = fields[9]
            standard_error = fields[10]
            log_10_p = fields[12]
            sample_size = fields[7]

            #conv to p
            p_value = 10**-(float(log_10_p))
            output_file.write("\t".join([snp_id, allele_1, allele_2, freq_1, beta, standard_error, str(p_value), sample_size]) + "\n")

