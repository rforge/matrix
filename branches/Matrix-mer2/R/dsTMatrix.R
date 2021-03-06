  ### Coercion and Methods for Symmetric Triplet Matrices

setAs("dsTMatrix", "dsCMatrix",
      function(from)
      ## pre-Cholmod: .Call("dsTMatrix_as_dsCMatrix", from, PACKAGE = "Matrix")
      .Call("Tsparse_to_Csparse", from, PACKAGE = "Matrix")
      )

if(FALSE) # have C method below
setAs("dsTMatrix", "dgTMatrix",
      function(from) {
          d <- from@Dim
          new("dgTMatrix", Dim = d, Dimnames = from@Dimnames,
              i = c(from@i, from@j),
              j = c(from@j, from@i),
              x = c(from@x, from@x))
      })

setAs("dsTMatrix", "dgTMatrix",
      function(from) .Call("dsTMatrix_as_dgTMatrix", from, PACKAGE = "Matrix"))

setAs("dsTMatrix", "lsTMatrix",
      function(from) new("lsTMatrix", i = from@i, j = from@j, uplo = from@uplo,
                         Dim = from@Dim, Dimnames = from@Dimnames))


## Conversion to dense storage is first to a dsyMatrix
setAs("dsTMatrix", "dsyMatrix",
      function(from) .Call("dsTMatrix_as_dsyMatrix", from, PACKAGE = "Matrix"))

setAs("dsTMatrix", "dgeMatrix",
      function(from) as(as(from, "dsyMatrix"), "dgeMatrix"))

setAs("dsTMatrix", "matrix",
      function(from) as(as(from, "dsyMatrix"), "matrix"))

setMethod("t", signature(x = "dsTMatrix"),
          function(x)
          new("dsTMatrix", Dim = x@Dim,
              i = x@j, j = x@i, x = x@x,
              uplo = if (x@uplo == "U") "L" else "U"),
          valueClass = "dsTMatrix")

setMethod("writeHB", signature(obj = "dsTMatrix"),
          function(obj, file, ...)
          .Call("Matrix_writeHarwellBoeing",
                if (obj@uplo == "U") t(obj) else obj,
                as.character(file), "DST", PACKAGE = "Matrix"))

setMethod("writeMM", signature(obj = "dsTMatrix"),
          function(obj, file, ...)
          .Call("Matrix_writeMatrixMarket",
                if (obj@uplo == "U") t(obj) else obj,
                as.character(file), "DST", PACKAGE = "Matrix"))
