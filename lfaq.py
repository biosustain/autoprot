#  Copyright(C) 2015-2022  all rights reserved
#  This program is a free software; you can redistribute it and / or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.gnu.org/Licenses/

import argparse
import pathlib
import os
import datetime
import subprocess

# example of use:
# lfaq.py "C:\\Users\\bertr\\LFAQ\\TestData\\MaxQuantTestData" "C:\\Users\\bertr\\LFAQ\\TestData\\MaxQuantTestData\\UPS_YEAST_uniprot_sp_Release201311.fasta" "C:\\Users\\bertr\\LFAQ\\result_dir"  "C:\\Users\\bertr\\LFAQ\\ExecutableFiles\\x64\\" --Number_of_trees 42 --alpha 0.5 --beta 1.5

parser = argparse.ArgumentParser(description='LFAQ, a novel algorithm for label-free absolute protein quantification, which can correct the biased MS intensities using the predicted peptide quantitative factors for all identified peptides.',
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)

# Required arguments
parser.add_argument('Input',
                    type=pathlib.Path,
                    help='Input data directory for maxquant type, .mzq file for mzQuantML type or .csv file for PeakView/SWATH 2.0 type')
parser.add_argument('Fastapath',
                    type=pathlib.Path,
                    help='The file path of proteins database (*.fasta)')
parser.add_argument('ResultPath',
                    type=pathlib.Path,
                    help='Result directory')
parser.add_argument('ExecutablesPath',
                    type=pathlib.Path,
                    help='LFAQ Executables path')

# optional arguments
parser.add_argument('--IdentificationFileType',
                    type=str,
                    choices=['maxquant', 'PeakView', 'mzQuantML'],
                    default="maxquant",
                    help='Software used to identify the proteins')
parser.add_argument('--IdentifierParsingRule',
                    type=str,
                    default='>(.*?)\s',
                    help='The regular expression used to extract protein identifiers from the fasta file.')
parser.add_argument('--IfExistDecoyProteins',
                    type=str,
                    default="true",
                    choices=('true','false'),
                    help='Set to true if input protein list contains decoy proteins')
parser.add_argument('--PrefixOfDecoyProtein',
                    type=str,
                    default="REV_",
                    help='Prefix of decoy proteins')
parser.add_argument('--IfExistContaminantProteins',
                    type=str,
                    default="true",
                    choices=('true','false'),
                    help='Set to true if input protein list contains contaminant proteins')
parser.add_argument('--PrefixOfContaminantProtein',
                    type=str,
                    default="CON_",
                    help='Prefix of contaminant protein')
parser.add_argument('--IfCalculateiBAQ',
                    type=str,
                    default="true",
                    choices=('true','false'),
                    help='If MaxQuant result is used as input, iBAQ values come from MaxQuant result. Otherwise, iBAQ is calculated by LFAQ.')
parser.add_argument('--IfCalculateTop3',
                    type=str,
                    default="true",
                    choices=('true','false'),
                    help='Calculate Top 3')
parser.add_argument('--RegressionMethod',
                    type=str,
                    choices=['BART', 'stepwise'],
                    default="BART",
                    help='Regression method for Q-factor learning.')
parser.add_argument('--MaxMissedCleavage',
                    type=int,
                    default=0,
                    help='The maximum number of missed cleavages of a peptide in the theoretical digestion.')
parser.add_argument('--PepShortestLen',
                    type=int,
                    default=6,
                    help='The allowed shortest length of a peptide in the theoretical digestion.')
parser.add_argument('--PepLongestLen',
                    type=int,
                    default=30,
                    help='The allowed longest length of a peptide in the theoretical digestion.')
parser.add_argument('--Enzyme',
                    type=str,
                    default="trypsin",
                    help='The enzyme used for theoretical digestion.')
parser.add_argument('--IfCotainStandardProtein',
                    type=str,
                    default="true",
                    choices=('true','false'),
                    help='Does the sample contain standard proteins')
parser.add_argument('--IdentifierOfStandardProtein',
                    type=str,
                    default="ups",
                    help='If the sample contains proteins, identifier of standard proteins')
parser.add_argument('--StandardProteinsFilePath',
                    type=pathlib.Path,
                    default="",
                    help='Standard proteins file path.')

# args for BART regression methods
bart_group = parser.add_argument_group('BART regression methods arguments')
bart_group.add_argument('--alpha',
                    type=float,
                    default=0.85,
                    help='The base parameter for the tree prior, ranging from 0 to 1.')
bart_group.add_argument('--beta',
                    type=float,
                    default=1.6,
                    help='The power parameter for the tree prior, ranging from 0 to positive infinite.')
bart_group.add_argument('--k',
                    type=int,
                    default=2,
                    help='The number of standard deviations of the dependent variables in the training set.')
bart_group.add_argument('--Number_of_trees',
                    type=int,
                    default=200,
                    help='The number of trees to train in the BART.')

# args for stepwise regression methods
stepwise_group = parser.add_argument_group('stepwise regression methods arguments')
stepwise_group.add_argument('--alpha1',
                    type=float,
                    default=0.95,
                    help='The alpha1 should be a numerical number between 0 and 1.')
stepwise_group.add_argument('--alpha2',
                    type=float,
                    default=0.95,
                    help='The alpha2 should be a numerical number between 0 and 1.')

args = parser.parse_args()

# summary message
print("Running LFAQ with the following parameters:")

# create parameter file
os.makedirs(args.ResultPath, exist_ok=True)
parameter_file_name =  "parameters_" + str(datetime.datetime.now()).replace(" ","_").replace(":","").replace("-","").replace(".","_") + ".params"
parameter_full_path = os.path.join(args.ResultPath, parameter_file_name)
parameter_file = open(parameter_full_path, 'w')
for arg in vars(args):
    parameter_name = arg.replace("_", " ")
    if parameter_name == "Input":
        if args.IdentificationFileType == "maxquant":
            parameter_name = "Input directory path"
        else: # "PeakView", "mzQuantML"
            parameter_name = "Input file path"
    value = getattr(args,arg)
    parameter_file.write("{0}=\"{1}\"\n".format(parameter_name,value))
    print("{0}=\"{1}\"".format(parameter_name,value))
parameter_file.close()
print("Parameters file created at {0}".format(parameter_full_path))

# execute workflow
executables_path = args.ExecutablesPath
os.chdir(executables_path)

# launch load.exe
Load_exe_path = os.path.join(executables_path, "Load.exe")
Load_exe_args = [Load_exe_path, parameter_full_path]
subprocess.check_call(Load_exe_args)

# launch ProteinAbsoluteQuan.exe
ProteinAbsoluteQuan_exe_path = os.path.join(executables_path, "ProteinAbsoluteQuan.exe")
ProteinAbsoluteQuan_exe_args = [ProteinAbsoluteQuan_exe_path, parameter_full_path]
subprocess.check_call(ProteinAbsoluteQuan_exe_args)