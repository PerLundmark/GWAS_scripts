#load("XM_genes.RData")
#gt[1]


#> gt[1]
#[[1]]
#name        name2 chrom   txStart     txMid     txEnd
#1   XM_011541469.1     C1orf141     1  67092175  67100624  67109072
#2   XM_011541467.1     C1orf141     1  67092175  67111679  67131183
#3   XM_017001276.1     C1orf141     1  67092175  67111701  67131227


new <- read.delim("ucsc_refseq_b37_230123_edit.csv")
new $txMid <- round((new$txStart + new$txEnd)/2, 0)
new.ordered <- new[c("name","name2","chrom","txStart","txMid","txEnd")]

gt <- list()
for (i in c(1:22,'X')){
  gt <- c(gt, list(new.ordered[new.ordered$chrom %in% i,]))
}

save(gt,file="XM_genes.RData")
