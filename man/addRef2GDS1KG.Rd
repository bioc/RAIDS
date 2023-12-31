% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/process1KG.R
\encoding{UTF-8}
\name{addRef2GDS1KG}
\alias{addRef2GDS1KG}
\title{Add the information about the unrelated patients to the Reference
GDS file}
\usage{
addRef2GDS1KG(fileNameGDS, filePart)
}
\arguments{
\item{fileNameGDS}{a \code{character} string representing the path and file
name of the GDS file that contains the Reference information. The
Reference GDS file must contain the SNP information, the genotyping
information and the pedigree information from Reference dataset.
The extension of the file must be '.gds'.}

\item{filePart}{a \code{character} string representing the path and file
name of the RDS file that contains the
information about the Reference patients that are unrelated.
The extension of the file must be '.rds'. The file must exists.}
}
\value{
The integer \code{0L} when successful.
}
\description{
This function adds the information about the unrelated patients
to the Reference GDS file. More specifically, it creates the field
\code{sample.ref} which as the value \code{1} when the sample
is unrelated and the value \code{0} otherwise.
The \code{sample.ref} is filled based on the information present in the
input RDS file.
}
\examples{

## Locate RDS with unrelated/related status for 1KG samples
dataDir <- system.file("extdata", package="RAIDS")
rdsFilePath <- file.path(dataDir, "unrelatedPatientsInfo_Demo.rds")

## Create a temporary GDS file in an test directory
dataDir <- system.file("extdata/tests", package="RAIDS")
gdsFilePath <- file.path(dataDir, "GDS_TEMP_201.gds")

## Create and open the GDS file
tmpGDS  <- createfn.gds(filename=gdsFilePath)
## Create "sample.id" node (the node must be present)
sampleIDs <- c("HG00104", "HG00109", "HG00110")
add.gdsn(node=tmpGDS, name="sample.id", val=sampleIDs)

## Create "snp.id" node (the node must be present)
snpIDs <- c("s1", "s2", "s3", "s4", "s5", "s6")
add.gdsn(node=tmpGDS, name="snp.id", val=snpIDs)

## Create "snp.position" node (the node must be present)
snpPositions <- c(16102, 51478, 51897, 51927, 54489, 54707)
add.gdsn(node=tmpGDS, name="snp.position", val=snpPositions)

## Create "snp.chromosome" node (the node must be present)
snpPositions <- c(1, 1, 1, 1, 1, 1)
add.gdsn(node=tmpGDS, name="snp.chromosome", val=snpPositions)

## Create "genotype" node (the node must be present)
genotype <- matrix(rep(1, 18), ncol = 3)
add.gdsn(node=tmpGDS, name="genotype", val=genotype)

## Close GDS file
closefn.gds(tmpGDS)

## Create  "sample.ref" node in GDS file using RDS information
addRef2GDS1KG(fileNameGDS=gdsFilePath, filePart=rdsFilePath)

## Read sample reference data.frame
fileGDS <- openfn.gds(gdsFilePath, readonly=TRUE)
read.gdsn(index.gdsn(node=fileGDS, path="sample.ref"))
closefn.gds(gdsfile=fileGDS)

## Delete the temporary GDS file
unlink(x=gdsFilePath, force=TRUE)

}
\author{
Pascal Belleau, Astrid Deschênes and Alexander Krasnitz
}
