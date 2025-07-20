library(mrclust)
gwas_data <- mrclust::SBP_CAD
exposure <- "diastolic blood pressure"
outcome <- "coronary artery disease risk"
llmSystemPrompt <- paste("You are a genetics expert with access to all literature in the area. I am looking for genetic variants that may be useful for Mendelian Randomization analysis of a potential causal effect of ", exposure, " on ", outcome, ". I will now list multiple clusters, clustered according to the causal effect of tested variants. Each cluster will contain the rsIDs of the genetic variants, as well as enriched biological functional terms found using enrichment analysis on the cluster.
Your job is to rank the clusters based on the relevancy of their variants to be used as instrumental variables in Mendelian Randomization analysis, using known biological information on the biological pathways found by the enrichment analysis as well as information known about the variants themselves.
While ranking, you will cite your sources for every claim of variant relevancy you make.")
