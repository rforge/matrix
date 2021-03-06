\name{dsparseMatrix-class}
\docType{class}
\alias{dsparseMatrix-class}
\alias{cbind2,dsparseMatrix,dsparseMatrix-method}
\alias{cbind2,dsparseMatrix,matrix-method}
\alias{cbind2,matrix,dsparseMatrix-method}
\alias{cbind2,dsparseMatrix,numeric-method}
\alias{cbind2,numeric,dsparseMatrix-method}
\alias{rbind2,dsparseMatrix,dsparseMatrix-method}
\alias{rbind2,dsparseMatrix,matrix-method}
\alias{rbind2,matrix,dsparseMatrix-method}
\alias{rbind2,dsparseMatrix,numeric-method}
\alias{rbind2,numeric,dsparseMatrix-method}
%
\alias{coerce,denseMatrix,dsparseMatrix-method}
\alias{\%*\%,ddenseMatrix,dsparseMatrix-method}
\alias{\%*\%,dgeMatrix,dsparseMatrix-method}
\alias{\%*\%,dsparseMatrix,ddenseMatrix-method}
\alias{\%*\%,dsparseMatrix,dgeMatrix-method}
\alias{crossprod,ddenseMatrix,dsparseMatrix-method}
\alias{crossprod,dgeMatrix,dsparseMatrix-method}
\alias{crossprod,dsparseMatrix,ddenseMatrix-method}
\alias{crossprod,dsparseMatrix,dgeMatrix-method}
\alias{image,dsparseMatrix-method}
\alias{kronecker,dsparseMatrix,dsparseMatrix-method}
\alias{lu,dsparseMatrix-method}
%
\title{Virtual Class "dsparseMatrix" of Numeric Sparse Matrices}
\description{The Class \code{"dsparseMatrix"} is the virtual (super) class of
  all numeric sparse matrices.
}
\section{Slots}{
  \describe{
    \item{\code{Dim}:}{the matrix dimension, see class \linkS4class{Matrix}.}
    \item{\code{Dimnames}:}{see the "Matrix" class.}
    \item{\code{x}:}{a \code{\link{numeric}} vector containing the
      (non-zero) matrix entries.}
    \item{\code{factors}:}{Object of class \code{"list"} - a list
      of factorizations of the matrix. }
  }
}
\section{Extends}{
  Class \code{"dMatrix"} and \code{"sparseMatrix"}, directly.\cr
  Class \code{"Matrix"}, by the above classes.
}
% \section{Methods}{
% No methods defined with class "dsparseMatrix" in the signature.
% }
%%\author{Martin}
\seealso{
  the documentation of the (non virtual) sub classes, see
  \code{showClass("dsparseMatrix")}; in particular,
  \linkS4class{dgTMatrix}, \linkS4class{dgCMatrix}, and
  \linkS4class{dgRMatrix}.
}
\examples{
showClass("dsparseMatrix")
}
\keyword{classes}
