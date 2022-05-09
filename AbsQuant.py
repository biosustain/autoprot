
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
    stan_int["occurence"] = stan_int.count(axis="columns") # optional
    length = len(sample_ids)+2 # optional, total samples number - 1

    for id in sample_ids:
        for pep in IS_conc.FullPeptideName.unique():
            try:
                IS_int = stan_int.loc[(stan_int.FullPeptideName == pep) & (stan_int.labelled == "yes"), id].values[0]
                endo_int = stan_int.loc[(stan_int.FullPeptideName == pep) & (stan_int.labelled == "no"), id].values[0]
            except KeyError and IndexError:
                IS_int, endo_int = [],[]
                stan_conc = stan_conc[stan_conc.FullPeptideName != pep]
            if IS_int and endo_int:
    # optional filtering
                if stan_int.loc[(stan_int.FullPeptideName == pep) & (stan_int.labelled == "yes"), "occurence"].values[0] >= length:
    # end
                    if IS_conc.loc[(IS_conc.FullPeptideName == pep), "Concentration"].values.size > 0:
                        conc = IS_conc.loc[(IS_conc.FullPeptideName == pep), "Concentration"].values[0]
                        stan_conc.loc[(stan_conc.FullPeptideName == pep), "pepconc_"+id] = (endo_int/IS_int)*conc

        for prot in stan_conc.ProteinName.unique():
            temp = stan_conc.loc[(stan_conc.ProteinName == prot), "pepconc_"+id].dropna()
            if temp.any():
                stan_conc.loc[(stan_conc.ProteinName == prot), "protconc_"+id] = sum(temp)/len(temp)
    return stan_conc

def get_invivo_prot_conc(m,workpath,sample_ids,stan_conc,plotpath,prot_seq,total_protein,Vc):
    fullpath = os.path.join(workpath,"Ec_proteins_int_"+m+".csv")
    intensities = pd.read_csv(fullpath, sep=",", header= 0)

    if m == "xTop":
        protid = "Protein ID"
        intensities = intensities[intensities[protid] != "Biogno"]
        intensities = intensities[intensities[protid] != ""]
        intensities = intensities[intensities[protid] != "0"]
        prot_labconc = intensities[protid].to_frame()
    else:
        protid = "protein_id"
        intensities = intensities[intensities[protid] != "Biogno"]
        intensities = intensities[intensities[protid] != ""]
        intensities = intensities[intensities[protid] != "0"]
        intensities = intensities.pivot_table("response_"+m,protid, "run_id").reset_index()
        prot_labconc = intensities[protid].to_frame()
    prot_unlabconc = prot_labconc.copy()

    for id in sample_ids:
        sample = intensities.loc[(intensities[id] != np.inf) & (intensities[id] != np.nan), [protid,id]]
        ISprotconc = stan_conc[["ProteinName","protconc_"+id]].copy().dropna()

    # labelled absolute quantification
        xdata, ydata = [], []
        for prot in ISprotconc.ProteinName.unique():
            if prot in sample[protid].tolist():
                xdata.append(sample.loc[(sample[protid] == prot), id].values[0])
                ydata.append(ISprotconc.loc[(ISprotconc.ProteinName == prot), "protconc_"+id].values[0])

    # linear regression using standard proteins (QconCATs or AQUA peptides)
        xdata, ydata = np.log10(xdata), np.log10(ydata)
        res = sm.OLS(ydata,sm.add_constant(xdata)).fit()
        for prot in sample[protid].tolist():
            if prot in stan_conc.ProteinName.unique():
                prot_labconc.loc[(prot_labconc[protid] == prot), "sample_conc(fmol/µg)_"+id] = stan_conc.loc[(stan_conc.ProteinName == prot), "protconc_"+id].values[0]
            else:
                sample_int = sample.loc[(sample[protid] == prot), id]
                prot_labconc.loc[(prot_labconc[protid] == prot), "sample_conc(fmol/µg)_"+id] = 10**(res.params[0]+np.log10(sample_int)*res.params[1])

        points = np.array([xdata.min()-0.1*xdata.min(),xdata.max()+0.1*xdata.max()])
        plt.clf()
        plt.scatter(xdata,ydata,label="Data")
        plt.plot(points,res.params[0]+points*res.params[1],'k-',label="LR")
        plt.xlabel("Log10 normalised protein intensity")
        plt.ylabel("Log10 absolute protein concentration (fmol/µg)")
        plt.legend(loc="lower right")
        plt.title("%1.2f * log10(int) + %1.2f with $R^{2}$ of %1.2f" %(res.params[1],res.params[0],res.rsquared))
        plt.savefig(os.path.join(plotpath,"LR_"+m+"_"+id+".png"),bbox_inches="tight")

    # unlabelled absolute quantification using total protein approach
        for prot in sample[protid].tolist():
            if ";" in prot:
                mwprot = prot[:prot.find(";")]
            else:
                mwprot = prot
            MW = ProteinAnalysis(str(prot_seq[mwprot].seq)).molecular_weight()
            ratio = sample.loc[sample[protid] == prot, id].values[0]/sample[id].sum()
            prot_unlabconc.loc[prot_unlabconc[protid] == prot, "sample_conc(fmol/µg)_"+id] = ratio*(1e9/MW)

    # calculate in vivo proteins concentrations
        TPA = total_protein.loc[(total_protein["Sample"] == id), "TPA"].values[0]
        prot_labconc["invivo_conc(mM)_"+id] = prot_labconc["sample_conc(fmol/µg)_"+id]*TPA*(1e-12/Vc)
        prot_unlabconc["invivo_conc(mM)"+id] = prot_unlabconc["sample_conc(fmol/µg)_"+id]*TPA*(1e-12/Vc)
    return prot_labconc, prot_unlabconc

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_directory", type=str, nargs=1, help="Full path of input directory")
    parser.add_argument("standard_intensities", type=str, nargs=1, help="file name of standard intensities")
    parser.add_argument("IS_concentrations", type=str, nargs=1, help="file name of IS concentrations")
    parser.add_argument("protein_sequences", type=str, nargs=1, help="file name of protein sequences in FASTA format")
    parser.add_argument("total_protein", type=str, nargs=1, help="file name of total protein per sample")
    # write two optional arguments: one for Vc and one for dry weight
    args = parser.parse_args()

    workpath = args.input_directory[0]
    resultspath = os.path.join(workpath,"Absolute_quantification")
    if not os.path.exists(resultspath):
        os.makedirs(resultspath)
    plotpath = os.path.join(resultspath,"LR_plots")
    if not os.path.exists(plotpath):
        os.makedirs(plotpath)

    # import internal standards and sequence files
    stan_int = pd.read_csv(os.path.join(workpath,args.standard_intensities[0]), sep=",", header=0)
    IS_conc = pd.read_csv(os.path.join(workpath,args.IS_concentrations[0]), sep=",", header=0) # should be in fmol/µg
    prot_seq = SeqIO.index(os.path.join(workpath,args.protein_sequences[0]), "fasta")
    total_protein = pd.read_csv(os.path.join(workpath,args.total_protein[0]), sep=",", header=0) # µg/cell

    # determine sample names and other variables
    sample_ids = stan_int.columns.values.tolist()[2:-1]
    methods = ["top", "all", "iBAQ", "APEX", "NSAF","LFAQ","xTop"]
    Vc = 3.9e-15 # L/cell

    # calculate standard endogenous protein concentrations per sample
    stan_conc = get_stan_prot_conc(stan_int,IS_conc,sample_ids)
    # export standard protein concentrations per sample
    stan_conc.to_csv(os.path.join(resultspath,"QconCATprot_conc.csv"), sep=',', index=False)

    # calculate all in vivo protein concentrations per sample
    for m in methods:
        prot_labconc, prot_unlabconc = get_invivo_prot_conc(m,workpath,sample_ids,stan_conc,plotpath,prot_seq,total_protein,Vc)
    # export concentrations per method
        prot_labconc.to_csv(os.path.join(resultspath,"prot_labconc_"+m+".csv"), sep=',',index=False)
        prot_unlabconc.to_csv(os.path.join(resultspath,"prot_unlabconc_"+m+".csv"), sep=',',index=False)

if __name__ == "__main__":
    main()
