library(mrclust)
sbp_cad = mrclust::SBP_CAD
bx = sbp_cad$bx
bxse = sbp_cad$bxse
by = sbp_cad$by
byse = sbp_cad$byse
ratio_est = by/bx
ratio_est_se = byse/abs(bx)
variantNames = sbp_cad$rsid
res_em = mr_clust_em(theta = ratio_est, theta_se = ratio_est_se, bx = bx, by = by, bxse = bxse, byse = byse, obs_names = variantNames)
variantsByCluster =  split(res_em$results$best$observation,res_em$results$best$cluster_class)

a = 3