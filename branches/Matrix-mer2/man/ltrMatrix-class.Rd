\name{ltrMatrix-class}
\docType{class}
\alias{ltpMatrix-class}
\alias{ltrMatrix-class}
%
\alias{!,ltpMatrix-method}
\alias{!,ltrMatrix-method}
\alias{coerce,ltpMatrix,dtpMatrix-method}
\alias{coerce,ltpMatrix,ltrMatrix-method}
\alias{coerce,ltrMatrix,dtrMatrix-method}
\alias{coerce,ltrMatrix,ltpMatrix-method}
\alias{t,ltpMatrix-method}
\alias{t,ltrMatrix-method}
%
\title{Triangular Dense Logical Matrices}
\description{
  The \code{"ltrMatrix"} class is the class of triangular, dense,
  logical matrices in nonpacked storage.  The \code{"ltpMatrix"} class
  is the same except in packed storage.
}
\section{Slots}{
  \describe{
    \item{\code{x}:}{Object of class \code{"logical"}. The logical
      values that constitute the matrix, stored in column-major order.}
    \item{\code{uplo}:}{Object of class \code{"character"}. Must be
      either "U", for upper triangular, and "L", for lower triangular.}
    \item{\code{diag}:}{Object of class \code{"character"}. Must be
      either \code{"U"}, for unit triangular (diagonal is all ones), or
      \code{"N"}; see \code{\link{triangularMatrix-class}}.}
    \item{\code{Dim},\code{Dimnames}:}{The dimension (a length-2
      \code{"integer"}) and corresponding names (or \code{NULL}), see the
      \code{\link{Matrix-class}}.}
    \item{\code{factors}:}{Object of class \code{"list"}.  A named
      list of factorizations that have been computed for the matrix.}
  }
}
\section{Extends}{
  \code{"ltrMatrix"} extends class \code{"lgeMatrix"}, directly, whereas\cr
  \code{"ltpMatrix"} extends class \code{"ldenseMatrix"}, directly.

  Both extend Class \code{"triangularMatrix"}, directly,
  and class \code{"denseMatrix"}, \code{"lMatrix"} and others,
  \emph{in}directly, use \code{\link{showClass}("lsyMatrix")}, e.g., for
  details.
}
\section{Methods}{
  Currently, mainly \code{\link{t}()} and coercion methods (for
  \code{\link{as}(.)}; use, e.g.,
  \code{\link{showMethods}(class="lsyMatrix")} for details.
}
\seealso{
  \code{\link{lgeMatrix-class}}, \code{\link{Matrix-class}},
  \code{\link[base]{t}}
}
\examples{
showClass("ltrMatrix")

str(new("ltpMatrix"))
}
\keyword{classes}
