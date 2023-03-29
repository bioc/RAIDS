#' @title Find the pruned snv in 1KG by chr
#'
#' @description TODO
#'
#' @param gds an object of class
#' \code{\link[SNPRelate:SNPGDSFileClass]{SNPRelate::SNPGDSFileClass}}, a SNP
#' GDS file.
#'
#' @param method a \code{character string} TODO . Default: \code{"corr"}.
#'
#' @param listSamples TODO
#'
#' @param slide.max.bp.v TODO
#'
#' @param ld.threshold.v TODO
#'
#' @param np TODO . Default: \code{NULL}.
#'
#' @param verbose.v a \code{logical} specifying if the function must provide
#' more information about the process. Default: \code{FALSE}.
#'
#' @param chr TODO
#'
#' @param minAF TODO
#'
#' @param outPref TODO
#'
#' @param keepObj a \code{logical} specifying if the function must save the
#' the processed information into a RDS object. Default: \code{FALSE}.
#'
#' @return \code{NULL} invisibly.
#'
#' @examples
#'
#' ## Path to the demo pedigree file is located in this package
#' data.dir <- system.file("extdata", package="RAIDS")
#'
#' ## TODO
#'
#' @author Pascal Belleau, Astrid Deschênes and Alexander Krasnitz
#' @importFrom gdsfmt index.gdsn read.gdsn
#' @encoding UTF-8
#' @keywords internal
pruning1KG.Chr <- function(gds, method="corr",
                           listSamples=NULL,
                           slide.max.bp.v=5e5,
                           ld.threshold.v=sqrt(0.1),
                           np=1, verbose.v=FALSE,
                           chr=NULL,
                           minAF=NULL,
                           outPref="pruned_1KG",
                           keepObj=FALSE) {

    filePruned <- file.path(paste0(outPref, ".rds"))
    fileObj <- file.path(paste0(outPref, "Obj.rds"))
    snpGDS <- index.gdsn(gds, "snp.id")
    listKeep <- NULL
    if(is.null(minAF)){
        if(!is.null(chr)){
            snpGDS <- index.gdsn(gds, "snp.id")
            snpID <- read.gdsn(snpGDS)

            chrGDS <- index.gdsn(gds, "snp.chromosome")
            snpCHR <- read.gdsn(chrGDS)

            listKeep <- snpID[which(snpCHR == chr)]
        }
    } else{
        snpGDS <- index.gdsn(gds, "snp.id")
        snpID <- read.gdsn(snpGDS)
        afGDS <- index.gdsn(gds, "snp.AF")
        snpAF <- read.gdsn(afGDS)

        if(is.null(chr)){
            listKeep <- snpID[which(snpAF >= minAF & snpAF <= 1-minAF)]
        } else{
            chrGDS <- index.gdsn(gds, "snp.chromosome")
            snpCHR <- read.gdsn(chrGDS)

            listKeep <- snpID[which(snpCHR == chr & snpAF >= minAF &
                                        snpAF <= 1-minAF)]
        }
    }

    snpset <- runLDPruning(gds,
                           method,
                           listSamples=listSamples,
                           listKeep=listKeep,
                           slide.max.bp.v = slide.max.bp.v,
                           ld.threshold.v=ld.threshold.v)

    pruned <- unlist(snpset, use.names=FALSE)
    saveRDS(pruned, filePruned)
    if(keepObj){
        saveRDS(snpset, fileObj)
    }
}


#' @title Generate two indexes based on gene annotation for gdsAnnot1KG block
#'
#' @description TODO
#'
#' @param gds an object of class
#' \link[gdsfmt]{gds.class} (a GDS file), the opened 1KG GDS file (reference).
#'
#' @param winSize a single positive \code{integer} representing the
#' size of the window to use to group the SNVs when the SNVs are in a
#' non-coding region. Default: \code{10000}.
#'
#' @param EnsDb An object with the ensembl genome annotation
#' Default: \code{EnsDb.Hsapiens.v86}.
#'
#' @return  a \code{data.frame} with those columns:
#' "chr", "pos", "snp.allele", "Exon", "GName", "Gene", "GeneS"
#' Example for GName and the two indexes "Gene", "GeneS"
#' GName Gene GeneS
#' 470                                 ENSG00000230021   17  3820
#' 471                                 ENSG00000230021   17  3820
#' 472                 ENSG00000230021:ENSG00000228794   17  3825
#' 473                 ENSG00000230021:ENSG00000228794   17  3825
#' 481 ENSG00000230021:ENSG00000228794:ENSG00000225880   17  3826
#' 482 ENSG00000230021:ENSG00000228794:ENSG00000225880   17  3826
#' 483 ENSG00000230021:ENSG00000228794:ENSG00000225880   17  3826
#' 492                 ENSG00000230021:ENSG00000228794   17  3825
#' 493                 ENSG00000230021:ENSG00000228794   17  3825
#' @examples
#'
#' # TODO
#'
#' @author Pascal Belleau, Astrid Deschênes and Alex Krasnitz
#' @importFrom S4Vectors Rle
#' @importFrom BSgenome strand
#' @importFrom GenomicRanges GRanges reduce
#' @importFrom IRanges IRanges
#' @importFrom AnnotationDbi select
#' @importFrom ensembldb exonsBy toSAF genes
#' @importFrom AnnotationFilter GeneIdFilter
#' @encoding UTF-8
#' @keywords internal
generateGeneBlock <- function(gds, winSize=10000, EnsDb) {

    edb <- EnsDb
    listEnsId <- unique(names(genes(edb)))

    cols <- c("GENEID", "SYMBOL", "GENENAME", "GENESEQSTART",
              "GENESEQEND", "SEQNAME")

    annot <- select(edb, keys=listEnsId, columns=cols, keytype="GENEID")
    annot <- annot[which(annot$SEQNAME %in% c(seq_len(22), "X")),]

    # All the genes
    grGene <- GRanges(
        seqnames = annot$SEQNAME,
        ranges = IRanges(annot$GENESEQSTART, end = annot$GENESEQEND),
        strand = Rle(strand(rep("+", nrow(annot)))),
        mcols = annot[,c("GENEID", "GENENAME")])

    # Data frame of the all genes
    dfGenneAll <- as.data.frame(grGene)

    # group the overlapping gene
    grGeneReduce <- reduce(grGene)
    # data.frame version of grGeneReduce
    dfGene <- as.data.frame(grGeneReduce)

    # All exon
    allExon <- exonsBy(edb, by = "gene", filter = GeneIdFilter(listEnsId))
    # Transforming the GRangesList into a data.frame in SAF format
    dfExon <- toSAF(allExon)
    # remove the duplicate
    dfExon <- unique(dfExon)
    # Group the overlap
    exonReduce <- reduce(allExon)
    # Transforming the GRangesList into a data.frame in SAF format
    dfExonReduce <- toSAF(exonReduce)
    listMat <- list()

    matFreqAll <- data.frame(chr=read.gdsn(index.gdsn(gds, "snp.chromosome")),
                             pos=read.gdsn(index.gdsn(gds, "snp.position")),
                             snp.allele=read.gdsn(index.gdsn(gds, "snp.allele")),
                             stringsAsFactors=FALSE)
    offsetGene <- 0
    offsetGeneS <- 0
    offsetGene.O <- 0

    for(chr in seq_len(22))
    {
        dfExonChr <- dfExonReduce[which(dfExonReduce$Chr == chr),]
        dfGenneAllChr <- dfGenneAll[which(dfGenneAll$seqnames == chr),]
        dfGeneChr <- dfGene[which(dfGene$seqnames == chr),]
        # matFreq <- NULL
        #    matFreq <- read.csv2(fileSNV,
        #                         header=FALSE)


        # colnames(matFreq) <- c("chr", "pos", "ref", "alt", "af", "EAS_AF",
        #                        "EUR_AF","AFR_AF", "AMR_AF", "SAS_AF")
        message(system.time({
            # SNV in the GDS
            matFreq <- matFreqAll[which(matFreqAll$chr == chr),]
            # create two vector (one for the exon and one for the gene) of char
            # with 1 entry for each SNV in the GDS
            # I will keep the name of the gene and exon at this position
            listSNVExons <- character(nrow(matFreq))
            listSNVGenes <- character(nrow(matFreq))

            listPos <- seq_len(nrow(matFreq))
            listPos <- listPos[order(matFreq$pos)]
            # Create an index to accelerate the process
            startIndex <- seq(1, nrow(matFreq), 1000)
            # Add if the last entry is not the last position
            # is not the nb row of matFreq add the the last
            #position
            if(startIndex[length(startIndex)] < nrow(matFreq)){
                startIndex <- c(startIndex, nrow(matFreq))
            }
            # For gene in the chr
            # slow but acceptable
            #    user  system elapsed
            #    26.116   0.074  26.201
            # see blockAnnotation.R for slower alternatives
            for (genePos in seq_len(nrow(dfGenneAllChr))) {
                # the gene is where SNV exists
                if (dfGenneAllChr$end[genePos] >= matFreq$pos[listPos[1]] &
                    dfGenneAllChr$start[genePos] <=
                    matFreq$pos[nrow(matFreq)]) {
                    # In which partitions from the index the gene is located
                    vStart <- max(c(which(matFreq$pos[startIndex] <=
                                              dfGenneAllChr$start[genePos]), 1))
                    vEnd <- min(c(which(matFreq$pos[startIndex] >=
                                            dfGenneAllChr$end[genePos]),
                                  length(startIndex)))
                    # List of SNV in the gene
                    listP <- which(matFreq$pos[listPos[startIndex[vStart]:startIndex[vEnd]]] >= dfGenneAllChr$start[genePos] &
                                       matFreq$pos[listPos[startIndex[vStart]:startIndex[vEnd]]] <= dfGenneAllChr$end[genePos])

                    # if SNV in the gene
                    if (length(listP) > 0) {
                        # listPos in the gene
                        listP <-
                            listPos[startIndex[vStart]:startIndex[vEnd]][listP]

                        # Add the name of the gene of SNVs
                        listSNVGenes[listP] <- paste0(listSNVGenes[listP], ":",
                                                      dfGenneAllChr$mcols.GENEID[genePos])

                        # Allow run on all without check if the SNV have
                        # already gene name
                        listSNVGenes[listP] <- gsub("^:", "",
                                                    listSNVGenes[listP])

                        # Exon of the gene
                        dfExon <- dfExonChr[which(dfExonChr$GeneID ==
                                                      dfGenneAllChr$mcols.GENEID[genePos]),]
                        k <- 1

                        listE <- list()
                        for (pos in listP) {
                            if(length(which(dfExon$Start <= matFreq$pos[pos] &
                                            dfExon$End >= matFreq$pos[pos])) > 0) {
                                listE[[k]] <- pos
                                k <- k + 1
                            }
                        }

                        if (length(listE) > 0) {
                            listE <- do.call(c, listE)
                            listSNVExons[listE] <- paste0(listSNVExons[listE],
                                                          ":", dfGenneAllChr$mcols.GENEID[genePos])
                            listSNVExons[listE] <- gsub("^:", "",
                                                        listSNVExons[listE])
                        }
                    }
                }
            }
        }))


        # add the column Exon with the list of gene with an exon with the SNV
        matFreq$Exon <- listSNVExons
        # add the column GName with the list of gene with which include the SNV
        matFreq$GName <- listSNVGenes

        # dfGeneChr are reduced (merge all the overlap interval)
        z <- cbind(c(dfGeneChr$start, dfGeneChr$end, as.integer(matFreq$pos)),
                   c(seq_len(nrow(dfGeneChr)), -1 * seq_len(nrow(dfGeneChr)),
                     rep(0, nrow(matFreq))))
        z <- z[order(z[,1], -1 * z[,2]),]

        # group by interval which in overlap a gene
        matFreq$Gene[listPos] <- cumsum(z[,2])[z[,2] == 0]
        matFreq$Gene[matFreq$Gene > 0] <- matFreq$Gene[matFreq$Gene > 0] +
            offsetGene
        offsetGene <- max(offsetGene, max(matFreq$Gene))

        listD <- which(matFreq$Gene > 0)

        tmp <- paste0(matFreq[listD, "GName"], "_", matFreq[listD, "Gene"])
        listO <- order(tmp)


        # Create an index for each gene different if
        # two gene overlap the order don't have meaning.
        # gene ex: ENSG00000238009:ENSG00000239945_6 and ENSG00000238009_6
        # have a different number.
        # Note the order is base on the name not on position
        # Ex:
        #         GeneN                         indexNew
        # 135                 ENSG00000230021  4089
        # 136                 ENSG00000230021  4089
        # 148 ENSG00000230021:ENSG00000237973  4094
        # 149 ENSG00000230021:ENSG00000237973  4094
        # 159 ENSG00000229344:ENSG00000230021  4036
        # 160 ENSG00000229344:ENSG00000230021  4036
        # 161 ENSG00000230021:ENSG00000248527  4095
        # 162 ENSG00000198744:ENSG00000230021  3168
        # 163                 ENSG00000230021  4089
        # 164                 ENSG00000230021  4089
        # 165                 ENSG00000230021  4089
        #
        indexNew <- cumsum(!(duplicated(tmp[listO])))

        matFreq$GeneS <- rep(0, nrow(matFreq))
        matFreq$GeneS[listD][listO] <- indexNew + offsetGeneS
        offsetGeneS <- max(offsetGeneS, max(matFreq$GeneS))

        matFreq$GeneS[matFreq$GeneS < 0] <- 0
        matFreq$GeneS[matFreq$Gene < 0] <- 0
        listOrph <- which(matFreq$GeneS == 0)
        flag <- TRUE
        v <- offsetGene.O - 1
        i <- 1
        curZone <- "GeneS"
        curZone1 <- "Gene"
        winSize <- 10000

        if(length(listOrph) > 0){
            # Very slow can do better
            # but just run 1 time so less priority
            #    user  system elapsed
            # 517.595   7.035 524.658
            #    user  system elapsed
            # 558.526   2.274 561.043
            #
            while(flag){
                #use the index
                vStart <- min(c(which(matFreq$pos[startIndex] >
                                          (matFreq[listOrph[i], "pos"] + winSize)),
                                length(startIndex)))

                preList <- listOrph[i]:startIndex[vStart]
                listWin <- which(matFreq[preList, "pos"] >
                                     (matFreq[listOrph[i], "pos"] + winSize) |
                                     (matFreq[preList, "pos"] >
                                          matFreq[listOrph[i], "pos"] &
                                          matFreq[preList,"GeneS"] > 0))

                j <- ifelse(length(listWin) > 0, preList[listWin[1]] - 1,
                            listOrph[i])

                matFreq[listOrph[i]:j, curZone] <- v
                matFreq[listOrph[i]:j, curZone1] <- v
                v <- v - 1
                i <- which(listOrph == j) + 1
                flag <- ifelse(i <= length(listOrph), TRUE, FALSE)

            }
            offsetGene.O <- min(offsetGene.O, min(matFreq$Gene))
        }

        listMat[[chr]] <- matFreq

        # save the matrix for each chr
        # create the space at the begining
    }

    matGene.Block <- do.call(rbind, listMat)
    rm(listMat)
    return(matGene.Block)
}

