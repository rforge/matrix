#### Logical Symmetric Sparse Matrices in Compressed column-oriented format

### contains = "lsparseMatrix"

setAs("lsCMatrix", "matrix",
      function(from) as(as(from, "lgCMatrix"), "matrix"))

setAs("lsCMatrix", "lgCMatrix",
      function(from) .Call("sCMatrix_to_gCMatrix", from, PACKAGE = "Matrix"))

setAs("lsCMatrix", "lsTMatrix",
      function(from) .Call("Csparse_to_Tsparse", from, PACKAGE = "Matrix"))

setAs("lsCMatrix", "dsCMatrix",
      function(from) new("dsCMatrix", i = from@i, p = from@p,
                         x = rep(1, length(from@i)), uplo = from@uplo,
                         Dim = from@Dim, Dimnames = from@Dimnames))

setAs("lsCMatrix", "dgTMatrix",
      function(from) callGeneric(as(x, "dsCMatrix")))

## FIXME: should be superfluous now:
setMethod("image", "lsCMatrix",
          function(x, ...) {
              x <- as(as(x, "dsCMatrix"), "dgTMatrix")
              callGeneric()
          })

setMethod("chol", signature(x = "lsCMatrix", pivot = "missing"),
          function(x, pivot, LINPACK)
          .Call("lsCMatrix_chol", x, TRUE, PACKAGE = "Matrix"))

setMethod("chol", signature(x = "lsCMatrix", pivot = "logical"),
          function(x, pivot, LINPACK)
          .Call("lsCMatrix_chol", x, pivot, PACKAGE = "Matrix"))

setMethod("t", signature(x = "lsCMatrix"),
          function(x)
          .Call("lsCMatrix_trans", x, PACKAGE = "Matrix"),
          valueClass = "lsCMatrix")
