# Use tximport to convert stringtie transcript counts to gene counts 
# and to store counts as single matrix
setwd("/scratch/mjpete11/GTEx/Count_Matrices/Hisat/")

# Constants
PATHS <- c('/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Amygdala/Hisat_Stringtie/gene_count_matrix.csv', 
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Anterior/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Caudate/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Cerebellar/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Cerebellum/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Cortex/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Frontal_Cortex/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Hippocampus/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Hypothalamus/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Nucleus_Accumbens/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Putamen/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Spinal_Cord/Hisat_Stringtie/gene_count_matrix.csv',
           '/mnt/storage/SAYRES/Mollie/GTEx_Brains/GTEx_Brains_092719/GTEx/Substantia_Nigra/Hisat_Stringtie/gene_count_matrix.csv')

GENE_MATRIX <- c("Amygdala_CountMatrix.tsv", "Anterior_CountMatrix.tsv",
           "Caudate_CountMatrix.tsv", "Cerebellar_CountMatrix.tsv",
           "Cerebellum_CountMatrix.tsv", "Cortex_CountMatrix.tsv",
           "Frontal_Cortex_CountMatrix.tsv", "Hippocampus_CountMatrix.tsv",
           "Hypothalamus_CountMatrix.tsv", "Nucleus_Accumbens_CountMatrix.tsv",
           "Putamen_CountMatrix.tsv", "Spinal_Cord_CountMatrix.tsv",
           "Substantia_Nigra_CountMatrix.tsv")

TRANS_MATRIX <- c("Amygdala_CountMatrix.tsv", "Anterior_CountMatrix.tsv", 
             "Caudate_CountMatrix.tsv", "Cerebellar_CountMatrix.tsv",
             "Cerebellum_CountMatrix.tsv", "Cortex_CountMatrix.tsv",
             "Frontal_Cortex_CountMatrix.tsv", "Hippocampus_CountMatrix.tsv",
             "Hypothalamus_CountMatrix.tsv", "Nucleus_Accumbens_CountMatrix.tsv",
             "Putamen_CountMatrix.tsv", "Spinal_Cord_CountMatrix.tsv",
             "Substantia_Nigra_CountMatrix.tsv")

# Load packages                                                                 
library(tximport)                                                               
library(GenomicFeatures) 
library(AnnotationDbi)
library(edgeR)   
library(readr)

# Read Metadata CSV.                                                            
samples = read.csv(file.path("/scratch/mjpete11/GTEx/Metadata/", "Metadata.csv"), header = TRUE)

# Samples missing t_data.ctab file
# Drop GTEX-ZAB4-0011-R4a-SM-4SOKB; Amydgala male (53) 
# Drop GTEX-13N2G-0011-R2a-SM-5MR4Q Substantia_Nigra Male (1288)
samples <- samples[-c(53, 1288),]

# Set rownames of metadata object equal to sample names.                        
rownames(samples) <- samples$Sample      

# List of samples by tissue type
Tissues <- as.character(unique(samples$Tissue))

Tissue_Lst <- list()
for (i in Tissues){
  Tissue_Lst[[i]] <- as.character(samples$Sample[samples$Tissue==i])
}

# Set path to dirs with t_data.ctab files and check that all files are there.   
Paths <- lapply(Tissue_Lst, function(x) file.path('/scratch/mjpete11/GTEx/All_Hisat_Quants', x, "t_data.ctab") )
all(lapply(Paths, function(x) all(file.exists(x)))==TRUE) # TRUE

# Set the names of the file paths object equal to the sample names.   
# Note: This renames obj in global env; Return var must have same name as original var (e.g. obj <- setNames(obj, x))
Name_Vec <- function(w, x){
  names(w) <- samples$Sample[samples$Tissue==x]
  return(w)
}
Paths <- Map(Name_Vec, w=Paths, x=Tissues)

# Read transcript ID and gene ID cols from one tsv from one sample from each tissue type.
# Map of transcript to gene IDs will be diff for each tissue since they were run seperately.
# e.g. different novel transcripts/diff number of transcripts will be detected in diff tissues.
tmp <- lapply(Paths, function(x) read_tsv(x[[1]]))
# tx2gene <- lapply(tmp, function(x) x[, c("t_name", "gene_name")]) # to write output with gene name/trans name (MSTRG)
tx2gene <- lapply(tmp, function(x) x[, c("t_name", "gene_id")]) # to write output with gene ID/ trans ID (if one exits)
head(tx2gene)

# Import Hisat output files.
# If you want the list of genes, add: txOut = FALSE. To get list of isoforms, add: txOut = TRUE
Tximport_Gene <- function(w, x){
  res <- tximport(w, type = "stringtie", tx2gene = x, txOut = FALSE)
  return(res)
}
Txi_Gene <- Map(w=Paths, x=tx2gene, Tximport_Gene)

Tximport_Trans <- function(w, x){
  res <- tximport(w, type = "stringtie", tx2gene = x, txOut = TRUE)
  return(res)
}
Txi_Trans <- Map(w=Paths, x=tx2gene, Tximport_Trans)

Counts_Gene <- lapply(Txi_Gene, function(x) x$counts)
df_Gene <- lapply(Counts_Gene, function(x) data.frame(x, check.names=FALSE))

Counts_Trans <- lapply(Txi_Trans, function(x) x$counts)
df_Trans <- lapply(Counts_Trans, function(x) data.frame(x, check.names=FALSE))

# Write to TSV
Write_Func <- function(w, x){
  write.table(w, file=x, sep = "\t", row.names = TRUE, quote = FALSE)
}
Map(Write_Func, w=df_Gene, x=GENE_MATRIX)
Map(Write_Func, w=df_Trans, x=TRANS_MATRIX)
