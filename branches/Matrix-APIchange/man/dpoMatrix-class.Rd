\name{dpoMatrix-class}
\title{Positive Semi-definite Dense Numeric Matrices}
\docType{class}
\alias{dpoMatrix-class}
\alias{dppMatrix-class}
\alias{corMatrix-class}
%
\alias{coerce,dpoMatrix,dppMatrix-method}
\alias{coerce,dpoMatrix,corMatrix-method}
\alias{coerce,dppMatrix,dpoMatrix-method}
\alias{coerce,matrix,corMatrix-method}
\alias{coerce,Matrix,corMatrix-method}
\alias{coerce,matrix,dpoMatrix-method}
\alias{coerce,Matrix,dpoMatrix-method}
\alias{coerce,matrix,dppMatrix-method}
\alias{coerce,Matrix,dppMatrix-method}
\alias{coerce,corMatrix,lMatrix-method}
%
\alias{rcond,dpoMatrix,character-method}
\alias{rcond,dppMatrix,character-method}
\alias{rcond,dpoMatrix,missing-method}
\alias{rcond,dppMatrix,missing-method}
\alias{chol,dpoMatrix-method}
\alias{chol,dppMatrix-method}
\alias{chol,dpoMatrix,ANY-method}
\alias{chol,dppMatrix,ANY-method}
\alias{determinant,dpoMatrix,logical-method}
\alias{determinant,dppMatrix,logical-method}
\alias{solve,dpoMatrix,dgeMatrix-method}
\alias{solve,dppMatrix,dgeMatrix-method}
\alias{solve,dpoMatrix,matrix-method}
\alias{solve,dppMatrix,matrix-method}
\alias{solve,dpoMatrix,missing-method}
\alias{solve,dppMatrix,missing-method}
\alias{solve,dpoMatrix,numeric-method}
\alias{solve,dppMatrix,numeric-method}
\alias{solve,dppMatrix,integer-method}
\alias{t,dppMatrix-method}
\description{
  The \code{"dpoMatrix"} class is the class of
  positive-semidefinite symmetric matrices in nonpacked storage.
  The \code{"dppMatrix"} class is the same except in packed storage.
  Only the upper triangle or the lower triangle is required to be
  available.
  The \code{"corMatrix"} class extends \code{"dpoMatrix"} with a slot \code{sd}.

}
\section{Objects from the Class}{Objects can be created by calls of the
  form \code{new("dpoMatrix", ...)} or from \code{crossprod} applied to
  an \code{"dgeMatrix"} object.}
\section{Slots}{
  \describe{
    \item{\code{uplo}:}{Object of class \code{"character"}. Must be
      either "U", for upper triangular, and "L", for lower triangular.}
    \item{\code{x}:}{Object of class \code{"numeric"}. The numeric
      values that constitute the matrix, stored in column-major order.}
    \item{\code{Dim}:}{Object of class \code{"integer"}. The dimensions
      of the matrix which must be a two-element vector of non-negative
      integers.}
    \item{\code{Dimnames}:}{inherited from class \code{"Matrix"}}
    \item{\code{factors}:}{Object of class \code{"list"}.  A named
      list of factorizations that have been computed for the matrix.}

    \item{\code{sd}:}{(for \code{"corMatrix"}) a \code{\link{numeric}}
      vector of length \code{n} containing the (original)
      \eqn{\sqrt{var(.)}}{sqrt(var(.))} entries which allow
	reconstruction of a covariance matrix from the correlation matrix.}
  }
}
\section{Extends}{
  Class \code{"dsyMatrix"}, directly.\cr
  Classes \code{"dgeMatrix"}, \code{"symmetricMatrix"}, and many more
  by class \code{"dsyMatrix"}.
}
\section{Methods}{
  \describe{
    \item{chol}{\code{signature(x = "dpoMatrix")}:
      Returns (and stores) the Cholesky decomposition of the matrix
      \code{x}.}
    \item{rcond}{\code{signature(x = "dpoMatrix", type = "character")}:
      Returns (and stores) the reciprocal of the condition number of
      \code{x}.  The \code{type} can be \code{"O"} for the
      one-norm (the default) or \code{"I"} for the infinity-norm.  For
      symmetric matrices the result does not depend on the type.}
    \item{solve}{\code{signature(a = "dpoMatrix", b = "missing")}:
      Return the inverse of \code{a}.}
    \item{solve}{\code{signature(a = "dpoMatrix", b = "numeric")}:
      Solve the linear system defined by \code{a} and \code{b}, where
      \code{b} can be a numeric vector, or a matrix, or a dgeMatrix
      object.  The Cholesky decomposition of \code{a} is calculated (if
      needed) while solving the system.}
  }
}
%\references{}
%\author{}
\seealso{
  Classes \code{\linkS4class{dsyMatrix}} and \code{\linkS4class{dgeMatrix}};
  further, \code{\link{Matrix}}, \code{\link{rcond}},
  \code{\link[base]{chol}}, \code{\link[base]{solve}}, \code{\link{crossprod}}.
}
\examples{
h6 <- Hilbert(6)
rcond(h6)
str(h6)
solve(h6)
str(hp6 <- as(h6, "dppMatrix"))
%% FIXME: add interesting  "corMatrix" example !
}
\keyword{classes}
\keyword{algebra}
