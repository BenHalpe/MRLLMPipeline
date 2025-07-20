library(gprofiler2)
source("HandleApiRequest.R")
source("config.R")
# clustering

bx = gwas_data$bx
bxse = gwas_data$bxse
by = gwas_data$by
byse = gwas_data$byse
ratio_est = by/bx
ratio_est_se = byse/abs(bx)
variantNames = gwas_data$rsid
res_em = mr_clust_em(theta = ratio_est, theta_se = ratio_est_se, bx = bx, by = by, bxse = bxse, byse = byse, obs_names = variantNames)
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

enrichmentPerCluster = lapply(variantsByCluster, getClusterEnrichment)


# LLM

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