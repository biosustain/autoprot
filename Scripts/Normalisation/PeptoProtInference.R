
args <- commandArgs(trailingOnly = TRUE)
workdir <- args[1]
expname <- args[2]
fasta_file <- args[3]

setwd(workdir)

library(aLFQ)

data(APEXMS)
APEX_ORBI.af <- apexFeatures(APEX_ORBI)
APEX_ORBI.apex <- APEX(data=APEX_ORBI.af)

methods <- list("top", "all", "iBAQ", "APEX", "NSAF")
OSreport <- gsub(" ","",paste(expname,"_OpenSWATH.tsv"))

data <- import(ms_filenames = OSreport, ms_filetype = "openswath",
               mprophet_cutoff = 0.01, openswath_removedecoys = TRUE)

for (i in methods) {
  results <- ProteinInference(data, peptide_method = i, peptide_topx = 3,
                              peptide_strictness = "loose", peptide_summary = "mean",
                              transition_topx = 5, transition_strictness = "loose",
                              transition_summary = "sum", combine_precursors = TRUE,
                              combine_peptide_sequences = TRUE, apex_model = APEX_ORBI.apex,
                              fasta = fasta_file)
  names(results)[names(results) == "response"] <- gsub(" ","",paste("response_",i))
  results <- subset(results,select = -c(concentration))
  write.csv(results, file = gsub(" ","",paste(expname,"_prot_int_",i,".csv")), row.names = FALSE, quote = FALSE)
}
