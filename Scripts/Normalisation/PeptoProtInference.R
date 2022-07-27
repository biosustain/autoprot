
args <- commandArgs(trailingOnly = TRUE)
work_dir <- args[1]
fasta_file <- args[2]

setwd(work_dir)

library(aLFQ)

data(APEXMS)
APEX_ORBI.af <- apexFeatures(APEX_ORBI)
APEX_ORBI.apex <- APEX(data=APEX_ORBI.af)

methods <- list("top", "all", "iBAQ", "APEX", "NSAF")

data <- import(ms_filenames = "Report_OpenSWATH.tsv", ms_filetype = "openswath",
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
  write.csv(results, file = gsub(" ","",paste("Ec_proteins_int_",i,".csv")), row.names = FALSE, quote = FALSE)
}
