% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/processStudy_internal.R
\encoding{UTF-8}
\name{validateAddStudy1Kg}
\alias{validateAddStudy1Kg}
\title{Validate the parameters for the addStudy1Kg() function}
\usage{
validateAddStudy1Kg(gdsReference, fileProfileGDS, verbose)
}
\arguments{
\item{gdsReference}{an object of class
\link[gdsfmt]{gds.class} (a GDS file), the opened 1KG GDS file.}

\item{fileProfileGDS}{a \code{character} string representing the path and
file name of the GDS Sample file. The GDS Sample file must exist.}

\item{verbose}{a \code{logical} indicating if messages should be printed
to show how the different steps in the function.}
}
\value{
The integer \code{0L} when successful.
}
\description{
The function validates the input parameters for the
\code{\link{addStudy1Kg}} function. When a parameter is not as
expected, an error message is generated.
}
\examples{


## Path to the demo 1KG GDS file is located in this package
dataDir <- system.file("extdata", package="RAIDS")
fileReferenceGDS <- file.path(dataDir, "PopulationReferenceDemo.gds")
gds1KG <- snpgdsOpen(fileReferenceGDS)

## Path to demo Profile GDS file
fileProfileGDS  <- file.path(dataDir, "GDS_Sample_with_study_demo.gds")

## Returns OL when all parameters are valid
RAIDS:::validateAddStudy1Kg(gdsReference=gds1KG,
    fileProfileGDS=fileProfileGDS, verbose=TRUE)

## All GDS file must be closed
closefn.gds(gdsfile=gds1KG)

}
\author{
Pascal Belleau, Astrid Deschênes and Alexander Krasnitz
}
\keyword{internal}
