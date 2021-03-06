\name{dgRMatrix-class}
\docType{class}
\alias{dgRMatrix-class}
\alias{coerce,matrix,dgRMatrix-method}
\alias{coerce,dgRMatrix,dgTMatrix-method}
\alias{coerce,dgRMatrix,matrix-method}
\alias{coerce,dgRMatrix,dgeMatrix-method}
\alias{diag,dgRMatrix-method}
\alias{dim,dgRMatrix-method}
\alias{image,dgRMatrix-method}
\alias{t,dgRMatrix-method}
\title{Compressed, sparse, row-oriented numeric matrices}
\description{The \code{dgRMatrix} class is a class of sparse numeric
  matrices in the compressed, sparse, column-oriented format.  In this
  implementation the non-zero elements in the columns are sorted into
  increasing row order.}
\section{Objects from the Class}{
  Objects can be created by calls of the form \code{new("dgRMatrix", ...)}.
}
\section{Slots}{
  \describe{
    \item{\code{p}:}{Object of class \code{"integer"} of pointers, one
      for each row, to the initial (zero-based) index of elements in
      the row.}
    \item{\code{j}:}{Object of class \code{"integer"} of length nnzero
      (number of non-zero elements).  These are the column numbers for
      each non-zero element in the matrix.}
    \item{\code{x}:}{Object of class \code{"numeric"} - the non-zero
      elements of the matrix.}
    \item{\code{Dim}:}{Object of class \code{"integer"} - the dimensions
      of the matrix.}
  }
}
\section{Methods}{
  \describe{
    \item{coerce}{\code{signature(from = "matrix", to = "dgRMatrix")}}
    \item{coerce}{\code{signature(from = "dgRMatrix", to = "matrix")}}
    \item{coerce}{\code{signature(from = "dgRMatrix", to = "dgBCMatrix")}}
    \item{coerce}{\code{signature(from = "dgRMatrix", to = "dgTMatrix")}}
    \item{diag}{\code{signature(x = "dgRMatrix")}: returns the diagonal
      of \code{x}}
    \item{dim}{\code{signature(x = "dgRMatrix")}: returns the dimensions
      of \code{x}}
    \item{image}{\code{signature(x = "dgRMatrix")}: plots an image of
      \code{x} using the \code{\link[lattice]{levelplot}} function}
  }
}
\seealso{
  \code{\link{dgCMatrix-class}}
}
\keyword{classes}
\keyword{algebra}
