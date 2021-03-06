\name{wrld_1deg}
\alias{wrld_1deg}
\docType{data}
\title{World 1-degree grid contiguity matrix}
\description{
  This matrix represents the distance-based contiguities of 15260
  one-degree grid cells of land areas. The representation is as a
  row standardised spatial weights matrix transformed to a symmetric
  matrix (see Ord (1975), p. 125).
}
\usage{data(wrld_1deg)}
\format{
  A \eqn{15260 ^2} symmetric sparse matrix of class
  \code{\linkS4class{dsCMatrix}} with 55973 non-zero entries.
}
\details{
  The data were created into \R using the coordinates of a
  \sQuote{SpatialPixels} object containing approximately one-degree grid
  cells for land areas only (world excluding Antarctica), using
  \code{\link[spdep]{dnearneigh}} with a cutoff distance of \code{sqrt(2)},
  and row-standardised and transformed to symmetry using
  \code{\link[spdep]{nb2listw}} and \code{\link[spdep]{similar.listw}}.
  This spatial weights object was converted to a \code{\linkS4class{dsTMatrix}}
  using \code{\link[spdep]{as_dsTMatrix_listw}} and then coerced
  (column-compressed).
}
\source{
  The shoreline data was read into \R using \code{\link[maptools]{Rgshhs}}
  from the GSHHS coarse shoreline database distributed with the
  \pkg{maptools} package, omitting Antarctica.  A matching approximately
  one-degree grid was generated using
  \code{\link[maptools]{Sobj_SpatialGrid}}, and the grids on land were
  found using the appropriate \code{\link[sp]{overlay}}
  method for the \sQuote{SpatialPolygons} and \sQuote{SpatialGrid} objects,
  yielding a \sQuote{SpatialPixels} one containing only the grid cells with
  centres on land.
}
\references{
  Ord, J. K. (1975)
  Estimation methods for models of spatial interaction;
  \emph{Journal of the American Statistical Association} \bold{70}, 120--126.
}
\examples{
data(wrld_1deg)
(n <- ncol(wrld_1deg))
IM <- .symDiagonal(n)
nn <- 20
set.seed(1)
rho <- runif(nn, 0, 1)
system.time(MJ <- sapply(rho,
                   function(x) determinant(IM - x * wrld_1deg,
                                           logarithm = TRUE)$modulus))
nWC <- -wrld_1deg
C1 <- Cholesky(nWC, Imult = 2)
system.time(MJ1 <- n * log(rho) +
   sapply(rho, function(x) c(determinant(update(C1, nWC, 1/x))$modulus))
)
all.equal(MJ, MJ1)
C2 <- Cholesky(nWC, super = TRUE, Imult = 2)
system.time(MJ2 <- n * log(rho) +
   sapply(rho, function(x) c(determinant(update(C2, nWC, 1/x))$modulus))
)
all.equal(MJ, MJ2)
system.time(MJ3 <- n * log(rho) + Matrix:::ldetL2up(C1, nWC, 1/rho))
all.equal(MJ, MJ3)
system.time(MJ4 <- n * log(rho) + Matrix:::ldetL2up(C2, nWC, 1/rho))
all.equal(MJ, MJ4)
}
\keyword{datasets}
