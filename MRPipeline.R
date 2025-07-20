library(mrclust)
library(gprofiler2)
source("HandleApiRequest.R")
# clustering
gwas_data = mrclust::SBP_CAD
bx = gwas_data$bx
bxse = gwas_data$bxse
by = gwas_data$by
byse = gwas_data$byse
ratio_est = by/bx
ratio_est_se = byse/abs(bx)
variantNames = gwas_data$rsid
#res_em = mr_clust_em(theta = ratio_est, theta_se = ratio_est_se, bx = bx, by = by, bxse = bxse, byse = byse, obs_names = variantNames)
variantsByCluster =  split(res_em$results$best$observation,res_em$results$best$cluster_class)

#enrichment

getClusterEnrichment <- function(cluster){
  enrichmentResult <- list()
  enrichmentResult$terms <- gost(cluster)$result
  if (!is.null(enrichmentResult$terms))
  {
    enrichmentResult$cluster <- cluster
    enrichmentResult$terms <- enrichmentResult$terms[order(enrichmentResult$terms$p_value),] # order everything by lowest p_value
    return(enrichmentResult)
  }
  
  return(NULL)
}

#enrichmentPerCluster = lapply(variantsByCluster, getClusterEnrichment)


# LLM
exposure <- "diastolic blood pressure"
outcome <- "coronary artery disease risk"
llmSystemPrompt <- paste("You are a genetics expert with access to all literature in the area. I am looking for genetic variants that may be useful for Mendelian Randomization analysis of a potential causal effect of ", exposure, " on ", outcome, ". I will now list multiple clusters, clustered according to the causal effect of tested variants. Each cluster will contain the rsIDs of the genetic variants, as well as enriched biological functional terms found using enrichment analysis on the cluster.
Your job is to rank the clusters based on the relevancy of their variants to be used as instrumental variables in Mendelian Randomization analysis, using known biological information on the biological pathways found by the enrichment analysis as well as information known about the variants themselves.
While ranking, you will cite your sources for every claim of variant relevancy you make.")


llmUserPrompt <- "The clusters are:
"

clusterNum <- 1
for(clusterEnrichment in enrichmentPerCluster)
{
  if(!is.null(clusterEnrichment$terms))
  {
    clusterVariants <- paste(clusterEnrichment$cluster, collapse=",")
    functionalTerms <- paste(clusterEnrichment$terms$term_name, collapse=",")
    llmUserPrompt <- paste(llmUserPrompt, clusterNum,". variants:", clusterVariants, "\n", "functional terms:", functionalTerms, "\n")
    clusterNum <- clusterNum + 1
  }
}

sendGptApiRequest(llmSystemPrompt, llmUserPrompt)