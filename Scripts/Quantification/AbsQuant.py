
import os
import argparse
import numpy as np
import pandas as pd
import statsmodels.api as sm
import matplotlib.pyplot as plt
from Bio import SeqIO
from Bio.SeqUtils.ProtParam import ProteinAnalysis

def get_stan_prot_conc(stan_int,IS_conc,sample_ids):
    stan_conc = IS_conc[["FullPeptideName","ProteinName"]].copy()

    for id in sample_ids:
        for pep in IS_conc["FullPeptideName"].unique():
            IS_int = stan_int.loc[(stan_int["FullPeptideName"] == pep) & (stan_int["labelled"] == "yes"), id].dropna()
            endo_int = stan_int.loc[(stan_int["FullPeptideName"] == pep) & (stan_int["labelled"] == "no"), id].dropna()
            if IS_int.any() and endo_int.any():
                if pep in IS_conc["FullPeptideName"].unique():
                    ratio = endo_int.values[0]/IS_int.values[0]
                    conc = IS_conc.loc[(IS_conc["FullPeptideName"] == pep), "Concentration"].values[0]
                    stan_conc.loc[(stan_conc["FullPeptideName"] == pep), "pepconc_"+id] = ratio * conc
            else:
                stan_conc = stan_conc[stan_conc["FullPeptideName"] != pep]

        for prot in stan_conc["ProteinName"].unique():
            temp = stan_conc.loc[(stan_conc["ProteinName"] == prot), "pepconc_"+id].dropna()
            if temp.any():
                stan_conc.loc[(stan_conc["ProteinName"] == prot), "protconc_"+id] = sum(temp)/len(temp)
    return stan_conc

def get_invivo_prot_conc_label(exp,m,workpath,sample_ids,stan_conc,plotpath,total_protein,cont_ids):
    fullpath = os.path.join(workpath,exp+"_prot_int_"+m+".csv")
    intensities = pd.read_csv(fullpath, sep=",", header=0)
    
    if m == "xTop":
        protid = "Protein ID"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        prot_labconc = intensities[protid].to_frame()
        prot_labconc.columns = ["ProteinName"]
    else:
        protid = "protein_id"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        intensities = intensities.pivot_table("response_"+m,protid, "run_id").reset_index()
        prot_labconc = intensities[protid].to_frame()
        prot_labconc.columns = ["ProteinName"]

    intensities.rename(columns={protid : "ProteinName"}, inplace=True)
    for id in sample_ids:
        sample = intensities.loc[(intensities[id] != np.inf) & (intensities[id] != np.nan) & (intensities[id] > 0), ["ProteinName",id]]
        ISprotconc = stan_conc[["ProteinName","protconc_"+id]].copy().dropna()

    # labelled absolute quantification
        xdata, ydata = [], []
        for prot in ISprotconc["ProteinName"].unique():
            if prot in sample["ProteinName"].tolist():
                xdata.append(sample.loc[(sample["ProteinName"] == prot), id].values[0])
                ydata.append(ISprotconc.loc[(ISprotconc["ProteinName"] == prot), "protconc_"+id].values[0])

    # linear regression using standard proteins (QconCATs or AQUA peptides)
        xdata, ydata = np.log10(xdata), np.log10(ydata)
        res = sm.OLS(ydata,sm.add_constant(xdata)).fit()
        for prot in sample["ProteinName"].tolist():
            if prot in ISprotconc.ProteinName.unique():
                prot_labconc.loc[(prot_labconc["ProteinName"] == prot), "sample_conc(fmol/µg)_"+id] = ISprotconc.loc[(ISprotconc["ProteinName"] == prot), "protconc_"+id].values[0]
            else:
                sample_int = sample.loc[(sample["ProteinName"] == prot), id]
                prot_labconc.loc[(prot_labconc["ProteinName"] == prot), "sample_conc(fmol/µg)_"+id] = 10**(res.params[0]+np.log10(sample_int)*res.params[1])

        points = np.array([xdata.min()-0.1*xdata.min(),xdata.max()+0.1*xdata.max()])
        plt.clf()
        plt.scatter(xdata,ydata,label="Data")
        plt.plot(points,res.params[0]+points*res.params[1],'k-',label="LR")
        plt.xlabel("Log10 normalised protein intensity")
        plt.ylabel("Log10 absolute protein concentration (fmol/µg)")
        plt.legend(loc="lower right")
        plt.title("%1.2f * log10(int) + %1.2f with $R^{2}$ of %1.2f" %(res.params[1],res.params[0],res.rsquared))
        plt.savefig(os.path.join(plotpath,"LR_"+m+"_"+id+".png"),bbox_inches="tight")

        # calculate intracellular proteins concentrations
        CPD = total_protein.loc[(total_protein["Sample"] == id), "CPD"].values[0]
        prot_labconc["invivo_conc(mM)_"+id] = prot_labconc["sample_conc(fmol/µg)_"+id]*CPD*1e-6

    return prot_labconc

def get_invivo_prot_conc_unlabel(exp,m,workpath,sample_ids,stan_conc,plotpath,total_protein,cont_ids):
    fullpath = os.path.join(workpath,exp+"_prot_int_"+m+".csv")
    intensities = pd.read_csv(fullpath, sep=",", header=0)
    
    if m == "xTop":
        protid = "Protein ID"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        prot_unlabconc = intensities[protid].to_frame()
        prot_unlabconc.columns = ["ProteinName"]
    else:
        protid = "protein_id"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        intensities = intensities.pivot_table("response_"+m,protid, "run_id").reset_index()
        prot_unlabconc = intensities[protid].to_frame()
        prot_unlabconc.columns = ["ProteinName"]

    intensities.rename(columns={protid : "ProteinName"}, inplace=True)
    for id in sample_ids:
        sample = intensities.loc[(intensities[id] != np.inf) & (intensities[id] != np.nan) & (intensities[id] > 0), ["ProteinName",id]]

    # unlabelled absolute quantification
        xdata, ydata = [], []
        for prot in stan_conc["ProteinName"].unique():
            if prot in sample["ProteinName"].tolist():
                xdata.append(sample.loc[(sample["ProteinName"] == prot), id].values[0])
                ydata.append(stan_conc.loc[(stan_conc["ProteinName"] == prot), "Concentration"].values[0])

    # linear regression using standard proteins (UPS2)
        xdata, ydata = np.log10(xdata), np.log10(ydata)
        res = sm.OLS(ydata,sm.add_constant(xdata)).fit()
        for prot in sample["ProteinName"].tolist():
            if prot in stan_conc["ProteinName"].unique():
                prot_unlabconc.loc[(prot_unlabconc["ProteinName"] == prot), "sample_conc(fmol/µg)_"+id] = stan_conc.loc[(stan_conc["ProteinName"] == prot), "Concentration"].values[0]
            else:
                sample_int = sample.loc[(sample["ProteinName"] == prot), id]
                prot_unlabconc.loc[(prot_unlabconc["ProteinName"] == prot), "sample_conc(fmol/µg)_"+id] = 10**(res.params[0]+np.log10(sample_int)*res.params[1])

        points = np.array([xdata.min()-0.1*xdata.min(),xdata.max()+0.1*xdata.max()])
        plt.clf()
        plt.scatter(xdata,ydata,label="Data")
        plt.plot(points,res.params[0]+points*res.params[1],'k-',label="LR")
        plt.xlabel("Log10 normalised protein intensity")
        plt.ylabel("Log10 absolute protein concentration (fmol/µg)")
        plt.legend(loc="lower right")
        plt.title("%1.2f * log10(int) + %1.2f with $R^{2}$ of %1.2f" %(res.params[1],res.params[0],res.rsquared))
        plt.savefig(os.path.join(plotpath,"LR_"+m+"_"+id+".png"),bbox_inches="tight")

        # calculate intracellular proteins concentrations
        CPD = total_protein.loc[(total_protein["Sample"] == id), "CPD"].values[0]
        prot_unlabconc["invivo_conc(mM)_"+id] = prot_unlabconc["sample_conc(fmol/µg)_"+id]*CPD*1e-6

    return prot_unlabconc

def get_invivo_prot_conc_free(exp,m,workpath,sample_ids,prot_seq,total_protein,cont_ids):
    fullpath = os.path.join(workpath,exp+"_prot_int_"+m+".csv")
    intensities = pd.read_csv(fullpath, sep=",", header=0)
    
    if m == "xTop":
        protid = "Protein ID"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        prot_freeconc = intensities[protid].to_frame()
        prot_freeconc.columns = ["ProteinName"]
    else:
        protid = "protein_id"
        for prot in intensities[protid].tolist():
            if ";" in prot:
                intensities = intensities[intensities[protid] != prot]
            for id in cont_ids:
                if prot == id:
                    intensities = intensities[intensities[protid] != prot]
        intensities = intensities.pivot_table("response_"+m,protid, "run_id").reset_index()
        prot_freeconc = intensities[protid].to_frame()
        prot_freeconc.columns = ["ProteinName"]

    intensities.rename(columns={protid : "ProteinName"}, inplace=True)
    for id in sample_ids:
        sample = intensities.loc[(intensities[id] != np.inf) & (intensities[id] != np.nan) & (intensities[id] > 0), ["ProteinName",id]]

    # standardfree absolute quantification using total protein approach
        tot_mass = 0
        for prot in sample["ProteinName"].tolist():
            seq = str(prot_seq[prot].seq)
            if "X" in seq:
                x_count = seq.count("X")
                seq = seq.replace("X","")
            else:
                x_count = 0
            MW = ProteinAnalysis(seq).molecular_weight()+x_count*110 # 110 g/mol is the average MW of an amino acid residue in a protein
            p_int = sample.loc[sample["ProteinName"] == prot, id].values[0]
            tot_mass += MW*p_int
        for prot in sample["ProteinName"].tolist():
            p_int = sample.loc[sample["ProteinName"] == prot, id].values[0]
            prot_freeconc.loc[prot_freeconc["ProteinName"] == prot, "sample_conc(fmol/µg)_"+id] = p_int*(1e9/tot_mass)

        # calculate intracellular proteins concentrations
        CPD = total_protein.loc[(total_protein["Sample"] == id), "CPD"].values[0]
        prot_freeconc["invivo_conc(mM)_"+id] = prot_freeconc["sample_conc(fmol/µg)_"+id]*CPD*1e-6

    return prot_freeconc

def main():
    parser = argparse.ArgumentParser(description="Full proteome quantification with either labelled or label-free approach")
    parser.add_argument("--label", dest="label", type=str, required=True, help="Labelled or label-free approach with the following options: 'label', 'unlabel', 'free'")
    parser.add_argument("--name", dest="expname", type=str, required=True, help="Name of the experiment")
    parser.add_argument("--inDir", dest="input_directory", required=True, type=str, help="Full path of input directory")
    parser.add_argument("--sam", dest="samples", nargs="+", required=True, help="String of spaced-out samples names as in the input files, e.g. '1 2 3'")
    parser.add_argument("--met", dest="methods", nargs="+", required=True, help="String of spaced-out methods with the following options: 'top', 'all', 'iBAQ', 'APEX', 'NSAF', 'LFAQ', 'xTop'")
    parser.add_argument("--tot", dest="total_protein", type=str, required=True, help="Input file with total protein (cellular protein density) per sample")
    parser.add_argument("--Sint", dest="standard_intensities", type=str, default=argparse.SUPPRESS, help="Input file with standard intensities")
    parser.add_argument("--Sconc", dest="IS_concentrations", type=str, default=argparse.SUPPRESS, help="Input file with IS concentrations")
    parser.add_argument("--fasta", dest="protein_sequences", type=str, default=argparse.SUPPRESS, help="Input file with protein sequences in FASTA format")
    args = parser.parse_args()

    approach = args.label
    experiment_name = args.expname
    workpath = args.input_directory
    resultspath = os.path.join(workpath,"Absolute_quantification")
    if not os.path.exists(resultspath):
        os.makedirs(resultspath)
    total_protein = pd.read_csv(args.total_protein, sep=",", header=0) # g/L
    # determine sample names and methods
    sample_ids = args.samples
    methods = args.methods

    # load contaminants
    location = os.path.dirname(os.path.realpath(__file__))
    cont_seq = SeqIO.index(os.path.join(location,"Contaminants_onlyIDs.fasta"), "fasta")
    cont_ids = []
    for id in cont_seq:
        cont_ids.append(id)
    cont_ids.append(["Biogno","","0"])

    if approach == "label":
        plotpath = os.path.join(resultspath,"LR_plots")
        if not os.path.exists(plotpath):
            os.makedirs(plotpath)
        stan_int = pd.read_csv(args.standard_intensities, sep=",", header=0)
        IS_conc = pd.read_csv(args.IS_concentrations, sep=",", header=0) # should be in fmol/µg

        # calculate standard endogenous protein concentrations per sample
        stan_conc = get_stan_prot_conc(stan_int,IS_conc,sample_ids)
        # export standard protein concentrations per sample
        stan_conc.to_csv(os.path.join(resultspath,experiment_name+"_QconCATprot_conc.csv"), sep=',', index=False)

        # calculate all in vivo protein concentrations per sample
        for m in methods:
            prot_labconc = get_invivo_prot_conc_label(experiment_name,m,workpath,sample_ids,stan_conc,plotpath,total_protein,cont_ids)
        # export concentrations per method
            prot_labconc.to_csv(os.path.join(resultspath,experiment_name+"_prot_conc_"+m+".csv"), sep=',',index=False)

    elif approach == "unlabel":
        plotpath = os.path.join(resultspath,"LR_plots")
        if not os.path.exists(plotpath):
            os.makedirs(plotpath)
        stan_conc = pd.read_csv(args.IS_concentrations, sep=",", header=0) # should be in fmol/µg

        # calculate all in vivo protein concentrations per sample
        for m in methods:
            prot_unlabelconc = get_invivo_prot_conc_unlabel(experiment_name,m,workpath,sample_ids,stan_conc,plotpath,total_protein,cont_ids)
        # export concentrations per method
            prot_unlabelconc.to_csv(os.path.join(resultspath,experiment_name+"_prot_conc_"+m+".csv"), sep=',',index=False)

    elif approach == "free":
        prot_seq = SeqIO.index(args.protein_sequences, "fasta")

        # calculate all in vivo protein concentrations per sample
        for m in methods:
            prot_freeconc = get_invivo_prot_conc_free(experiment_name,m,workpath,sample_ids,prot_seq,total_protein,cont_ids)
        # export concentrations per method
            prot_freeconc.to_csv(os.path.join(resultspath,experiment_name+"_prot_conc_"+m+".csv"), sep=',',index=False)

if __name__ == "__main__":
    main()
