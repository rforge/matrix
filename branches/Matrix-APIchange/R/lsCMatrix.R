#### Logical Symmetric Sparse Matrices in Compressed column-oriented format

### contains = "lsparseMatrix"

setAs("lsCMatrix", "matrix",
      function(from) as(as(from, "lgCMatrix"), "matrix"))

setAs("lsCMatrix", "lgCMatrix",
      function(from) .Call(Csparse_symmetric_to_general, from))

## for indexing
setAs("lsCMatrix", "lgTMatrix",
      function(from) as(as(from, "lgCMatrix"), "lgTMatrix"))

setAs("lgCMatrix", "lsCMatrix",
      function(from) .Call(Csparse_general_to_symmetric, from, uplo = "U"))
## now use it:
aslsC.by.lgC <- function(from) as(as(from, "lgCMatrix"), "lsCMatrix")
setAs("lgTMatrix", "lsCMatrix", aslsC.by.lgC) # <-> needed for Matrix()
setAs("matrix",    "lsCMatrix", aslsC.by.lgC)

## Specific conversions, should they be necessary.  Better to convert as
## as(x, "TsparseMatrix") or as(x, "denseMatrix")
setAs("lsCMatrix", "lsTMatrix",
      function(from) .Call(Csparse_to_Tsparse, from, FALSE))

setAs("lsCMatrix", "dsCMatrix",
      function(from) new("dsCMatrix", i = from@i, p = from@p,
                         x = as.double(from@x), uplo = from@uplo,
                         Dim = from@Dim, Dimnames = from@Dimnames))

setAs("lsCMatrix", "dgTMatrix",
      function(from) as(as(from, "dsCMatrix"), "dgTMatrix"))


## have rather tril() and triu() methods than
## setAs("lsCMatrix", "ltCMatrix", ....)
setMethod("tril", "lsCMatrix",
	  function(x, k = 0, ...) {
	      if(x@uplo == "L" && k == 0)
		  ## same internal structure + diag
		  new("ltCMatrix", uplo = x@uplo, i = x@i, p = x@p,
		      x = x@x, Dim = x@Dim, Dimnames = x@Dimnames)
	      else tril(as(x, "lgCMatrix"), k = k, ...)
	  })
setMethod("triu", "lsCMatrix",
	  function(x, k = 0, ...) {
	      if(x@uplo == "U" && k == 0)
		  new("ltCMatrix", uplo = x@uplo, i = x@i, p = x@p,
		      x = x@x, Dim = x@Dim, Dimnames = x@Dimnames)
	      else triu(as(x, "lgCMatrix"), k = k, ...)
	  })

## FIXME: generalize to "lsparseMatrix" or (class union)  "symmetric sparse"
setMethod("image", "lsCMatrix",
          function(x, ...) {
              x <- as(as(x, "dsCMatrix"), "dgTMatrix")
              callGeneric()
          })

setMethod("chol", signature(x = "lsCMatrix", pivot = "missing"),
	  function(x, pivot, ...) chol(as(x, "dgCMatrix"), pivot = FALSE))
##          .Call(lsCMatrix_chol, x, FALSE))

setMethod("chol", signature(x = "lsCMatrix", pivot = "logical"),
	  function(x, pivot, ...) chol(as(x, "dgCMatrix"), pivot = pivot))
##	    .Call(lsCMatrix_chol, x, pivot))

## Use more general method from CsparseMatrix class
## setMethod("t", signature(x = "lsCMatrix"),
##           function(x)
##           .Call(lsCMatrix_trans, x),
##           valueClass = "lsCMatrix")
