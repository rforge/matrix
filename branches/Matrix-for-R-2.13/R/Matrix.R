#### Toplevel ``virtual'' class "Matrix"


### Virtual coercions -- via smart "helpers" (-> ./Auxiliaries.R)

setAs("Matrix", "sparseMatrix", function(from) as(from, "CsparseMatrix"))
setAs("Matrix", "CsparseMatrix", function(from) as_Csparse(from))
setAs("Matrix", "denseMatrix",  function(from) as_dense(from))

## Maybe TODO:
## setAs("Matrix", "nMatrix", function(from) ....)

## Most of these work; this is a last resort:
setAs(from = "Matrix", to = "matrix", # do *not* call base::as.matrix() here:
      function(from) .bail.out.2("coerce", class(from), class(to)))
setAs(from = "matrix", to = "Matrix", function(from) Matrix(from))

## ## probably not needed eventually:
## setAs(from = "ddenseMatrix", to = "matrix",
##       function(from) {
## 	  if(length(d <- dim(from)) != 2) stop("dim(.) has not length 2")
## 	  array(from@x, dim = d, dimnames = dimnames(from))
##       })

## should propagate to all subclasses:
setMethod("as.matrix", signature(x = "Matrix"), function(x) as(x, "matrix"))
## for 'Matrix' objects, as.array() should be equivalent:
setMethod("as.array",  signature(x = "Matrix"), function(x) as(x, "matrix"))

## head and tail apply to all Matrix objects for which subscripting is allowed:
setMethod("head", signature(x = "Matrix"), utils::head.matrix)
setMethod("tail", signature(x = "Matrix"), utils::tail.matrix)

setMethod("drop", signature(x = "Matrix"),
	  function(x) if(all(dim(x) != 1)) x else drop(as(x, "matrix")))

## slow "fall back" method {subclasses should have faster ones}:
setMethod("as.vector", signature(x = "Matrix", mode = "missing"),
	  function(x, mode) as.vector(as(x, "matrix"), mode))

setAs("Matrix", "vector",  function(from) as.vector (as(from, "matrix")))
setAs("Matrix", "numeric", function(from) as.numeric(as(from, "matrix")))
setAs("Matrix", "logical", function(from) as.logical(as(from, "matrix")))
setAs("Matrix", "integer", function(from) as.integer(as(from, "matrix")))
setAs("Matrix", "complex", function(from) as.complex(as(from, "matrix")))

## mainly need these for "dMatrix" or "lMatrix" respectively, but why not general:
setMethod("as.numeric", signature(x = "Matrix"),
	  function(x, ...) as.numeric(as.vector(x)))
setMethod("as.logical", signature(x = "Matrix"),
	  function(x, ...) as.logical(as.vector(x)))

setMethod("mean", signature(x = "sparseMatrix"),
	  function(x, ...) mean(as(x,"sparseVector"), ...))
setMethod("mean", signature(x = "sparseVector"),
	  function(x, trim = 0, na.rm = FALSE, ...)
      {
	  if (na.rm) # remove NAs such that new length() is ok
	      x <- x[!is.na(x)] # remains sparse!
	  if(is0(trim)) sum(x) / length(x)
	  else {
	      ## fast trimmed mean for sparseVector:
	      ## ---> we'd need fast & sparse  sort(<sparseV>).
	      ##      Normally this means to define a xtfrm() method;
	      ##      however, that plus  x[order(x, ..)]  will NOT be sparse
	      ## TODO: sortSparseVector(.)
	      warning("trimmed mean of 'sparseVector' -- suboptimally using as.numeric(.)")
	      mean(as.numeric(x), trim=trim)
	  }
      })
## for the non-"sparseMatrix" ones:
setMethod("mean", signature(x = "Matrix"),
	  function(x, trim = 0, na.rm = FALSE, ...)
      {
	  if (na.rm)
	      x <- x[!is.na(x)]
	  if(is0(trim)) sum(x) / length(x)
	  else mean(as.numeric(x), trim=trim)
      })


setMethod("cov2cor", signature(V = "Matrix"),
	  function(V) { ## was as(cov2cor(as(V, "matrix")), "dpoMatrix"))
	      r <- V
	      p <- (d <- dim(V))[1]
	      if(p != d[2]) stop("'V' is not a square matrix")
	      Is <- sqrt(1/diag(V)) # diag( 1/sigma_i )
	      if(any(!is.finite(Is)))
		  warning("diag(.) had 0 or NA entries; non-finite result is doubtful")
              Is <- Diagonal(x = Is)
              r <- Is %*% V %*% Is
	      r[cbind(1:p,1:p)] <- 1 # exact in diagonal
	      as(forceSymmetric(r), "dpoMatrix")
          })

## "base" has an isSymmetric() S3-generic since R 2.3.0
setMethod("isSymmetric", signature(object = "symmetricMatrix"),
	  function(object, ...) TRUE)
setMethod("isSymmetric", signature(object = "triangularMatrix"),
	  ## TRUE iff diagonal:
	  function(object, ...) isDiagonal(object))

setMethod("isTriangular", signature(object = "matrix"), isTriMat)

setMethod("isDiagonal", signature(object = "matrix"), .is.diagonal)

## The "catch all" methods -- far from optimal:
setMethod("symmpart", signature(x = "Matrix"),
	  function(x) as((x + t(x))/2, "symmetricMatrix"))
setMethod("skewpart", signature(x = "Matrix"),
	  function(x) (x - t(x))/2)

## FIXME: do this (similarly as for "ddense.." in C
setMethod("symmpart", signature(x = "matrix"), function(x) (x + t(x))/2)
setMethod("skewpart", signature(x = "matrix"), function(x) (x - t(x))/2)




setMethod("dim", signature(x = "Matrix"),
	  function(x) x@Dim, valueClass = "integer")

setMethod("length", "Matrix", function(x) prod(dim(x)))

setMethod("dimnames", signature(x = "Matrix"), function(x) x@Dimnames)


## not exported but used more than once for "dimnames<-" method :
## -- or do only once for all "Matrix" classes ??
dimnamesGets <- function (x, value) {
    d <- dim(x)
    if (!is.list(value) || length(value) != 2 ||
	!(is.null(v1 <- value[[1]]) || length(v1) == d[1]) ||
	!(is.null(v2 <- value[[2]]) || length(v2) == d[2]))
	stop(gettextf("invalid dimnames given for '%s' object", class(x)))
    x@Dimnames <- list(if(!is.null(v1)) as.character(v1),
		       if(!is.null(v2)) as.character(v2))
    x
}
setMethod("dimnames<-", signature(x = "Matrix", value = "list"),
	  dimnamesGets)

setMethod("dimnames<-", signature(x = "Matrix", value = "NULL"),
	  function(x, value) {
	      message("dimnames(.) <- NULL:  translated to \n",
		      "dimnames(.) <- list(NULL,NULL)  <==>  unname(.)")
	      x@Dimnames <- list(NULL,NULL)
	      x
	  })

setMethod("unname", signature("Matrix", force="missing"),
	  function(obj) { obj@Dimnames <- list(NULL,NULL); obj})


Matrix <- function (data = NA, nrow = 1, ncol = 1, byrow = FALSE,
                    dimnames = NULL, sparse = NULL, forceCheck = FALSE)
{
    sparseDefault <- function(m) prod(dim(m)) > 2*sum(isN0(as(m, "matrix")))

    i.M <- is(data, "Matrix")
    sM <- FALSE
    if(i.M) {
	if(is(data, "diagonalMatrix")) return(data) # in all cases
	sV <- FALSE
    } else if(inherits(data, "table")) # special treatment
	class(data) <- "matrix" # "matrix" first for S4 dispatch
    else if(is(data, "sparseVector")) {
	data <- spV2M(data, nrow, ncol, byrow=byrow)
	i.M <- sparse <- forceCheck <- sM <- sV <- TRUE
    }
    if(is.null(sparse1 <- sparse) && (i.M || is(data, "matrix")))
	sparse <- sparseDefault(data)
    doDN <- TRUE
    if (i.M) {
	if (!sV) {
	    if(!missing(nrow) || !missing(ncol)|| !missing(byrow))
		warning("'nrow', 'ncol', etc, are disregarded when 'data' is \"Matrix\" already")
	    sM <- is(data,"sparseMatrix")
	    if(!forceCheck && ((sparse && sM) || (!sparse && !sM)))
		return(data)
	    ## else : convert  dense <-> sparse -> at end
	}
    }
    else if (!is.matrix(data)) { ## cut & paste from "base::matrix" :
	## avoid copying to strip attributes in simple cases
	if (is.object(data) || !is.atomic(data)) data <- as.vector(data)
	if(length(data) == 1 && is0(data) && !identical(sparse, FALSE)) {
	    ## Matrix(0, ...) : always sparse unless "sparse = FALSE":
	    if(is.null(sparse)) sparse1 <- sparse <- TRUE
	    i.M <- sM <- TRUE
	    if (missing(nrow)) nrow <- ceiling(1/ncol) else
	    if (missing(ncol)) ncol <- ceiling(1/nrow)
            isSym <- nrow == ncol
	    ## will be sparse: do NOT construct full matrix!
	    data <- new(paste(if(is.numeric(data)) "d" else
			      if(is.logical(data)) "l" else
			      stop("invalid 'data'"),
			      if(isSym) "s" else "g", "CMatrix", sep=''),
			p = rep.int(0L, ncol+1L),
			Dim = as.integer(c(nrow,ncol)),
			Dimnames = if(is.null(dimnames)) list(NULL,NULL)
			else dimnames)
	} else { ## normal case - using .Internal() to avoid more copying
	    if(getRversion() >= "2.13")
		data <- .Internal(matrix(data, nrow, ncol, byrow, dimnames,
					 missing(nrow), missing(ncol)))
	    else {
		if (missing(nrow)) nrow <- ceiling(length(data)/ncol) else
		if (missing(ncol)) ncol <- ceiling(length(data)/nrow)
		data <- .Internal(matrix(data, nrow, ncol, byrow, dimnames))
	    }
	    if(is.null(sparse))
		sparse <- sparseDefault(data)
	}
        doDN <- FALSE
    } else if(!missing(nrow) || !missing(ncol)|| !missing(byrow))
	warning("'nrow', 'ncol', etc, are disregarded for matrix 'data'")

    ## 'data' is now a "matrix" or "Matrix"
    if (doDN && !is.null(dimnames))
	dimnames(data) <- dimnames

    ## check for symmetric / triangular / diagonal :
    isSym <- isSymmetric(data)
    if((isTri <- !isSym))
	isTri <- isTriangular(data)
    isDiag <- isSym # cannot be diagonal if it isn't symmetric
    if(isDiag) # do not *build*  1 x 1 diagonalMatrix
	isDiag <- !isTRUE(sparse1) && nrow(data) > 1 && isDiagonal(data)

    ## try to coerce ``via'' virtual classes
    if(isDiag) { ## diagonal is preferred to sparse !
	data <- as(data, "diagonalMatrix")
	isSym <- FALSE
    } else if(sparse && !sM)
	data <- as(data, "sparseMatrix")
    else if(!sparse) {
	if(i.M) { ## data is 'Matrix'
	    if(!is(data, "denseMatrix"))
		data <- as(data, "denseMatrix")
	} else { ## data is "matrix" (and result "dense" -> go via "general"
	    ctype <- typeof(data)
	    if (ctype == "complex")
		stop("complex matrices not yet implemented in Matrix package")
	    if (ctype == "integer") ## integer Matrices not yet implemented
		storage.mode(data) <- "double"
	    data <- new(paste(.M.kind(data), "geMatrix", sep=''),
			Dim = dim(data),
			Dimnames = .M.DN(data),
			x = c(data))
	}
    }

    if(isTri && !is(data, "triangularMatrix")) {
	data <- if(attr(isTri,"kind") == "L") tril(data) else triu(data)
					#was as(data, "triangularMatrix")
    } else if(isSym && !is(data, "symmetricMatrix"))
	data <- forceSymmetric(data) #was as(data, "symmetricMatrix")

    data
}

## Methods for operations where one argument is numeric

## maybe not 100% optimal, but elegant:
setMethod("solve", signature(a = "Matrix", b = "missing"),
	  function(a, b, ...) solve(a, Diagonal(nrow(a))))

setMethod("solve", signature(a = "Matrix", b = "numeric"),
	  function(a, b, ...) callGeneric(a, Matrix(b)))
setMethod("solve", signature(a = "Matrix", b = "matrix"),
	  function(a, b, ...) callGeneric(a, Matrix(b)))
setMethod("solve", signature(a = "matrix", b = "Matrix"),
	  function(a, b, ...) callGeneric(Matrix(a), b))

setMethod("solve", signature(a = "Matrix", b = "diagonalMatrix"),
	  function(a, b, ...) callGeneric(a, as(b,"CsparseMatrix")))

## when no sub-class method is found, bail out
setMethod("solve", signature(a = "Matrix", b = "ANY"),
	  function(a, b, ...) .bail.out.2("solve", class(a), class(b)))
setMethod("solve", signature(a = "ANY", b = "Matrix"),
	  function(a, b, ...) .bail.out.2("solve", class(a), class(b)))

setMethod("chol2inv", signature(x = "denseMatrix"),
	  function (x, ...) chol2inv(as(as(x, "dMatrix"), "dtrMatrix"), ...))
setMethod("chol2inv", signature(x = "sparseMatrix"),
	  function (x, ...) {
	      if(length(list(...)))
		  warning("arguments in ",deparse(list(...))," are disregarded")
	      ## for now:
	      tcrossprod(solve(as(x,"triangularMatrix")))
	  })

## There are special sparse methods; this is a "fall back":
setMethod("kronecker", signature(X = "Matrix", Y = "ANY",
				 FUN = "ANY", make.dimnames = "ANY"),
	  function(X, Y, FUN, make.dimnames, ...) {
	      if(is(X, "sparseMatrix"))
		  warning("using slow kronecker() method")
	      X <- as(X, "matrix") ; Matrix(callGeneric()) })

setMethod("kronecker", signature(X = "ANY", Y = "Matrix",
				 FUN = "ANY", make.dimnames = "ANY"),
	  function(X, Y, FUN, make.dimnames, ...) {
	      if(is(Y, "sparseMatrix"))
		  warning("using slow kronecker() method")
	      Y <- as(Y, "matrix") ; Matrix(callGeneric()) })


setMethod("determinant", signature(x = "Matrix", logarithm = "missing"),
          function(x, logarithm, ...)
          determinant(x, logarithm = TRUE, ...))

## Gives  "The following object(s) are masked from package:base :   det"
## but is still ``the Right Thing'' to do :
## base::det() calls [base::]determinant();
## our det() should call our determinant() :
det <- base::det
environment(det) <- environment()## == asNamespace("Matrix")

setMethod("Cholesky", signature(A = "Matrix"),
	  function(A, perm = TRUE, LDL = !super, super = FALSE, Imult = 0, ...)
	  stop(gettextf("Cholesky(A) called for 'A' of class \"%s\";\n\t it is currently defined for sparseMatrix only; consider using chol() instead",
			class(A)), call. = FALSE))

## FIXME: All of these should never be called
setMethod("chol", signature(x = "Matrix"),
	  function(x, pivot, ...) .bail.out.1("chol", class(x)))
setMethod("determinant", signature(x = "Matrix", logarithm = "logical"),
	  function(x, logarithm, ...)
	  determinant(as(x,"dMatrix"), logarithm=logarithm, ...))

setMethod("diag", signature(x = "Matrix"),
	  function(x, nrow, ncol) .bail.out.1("diag", class(x)))
setMethod("t", signature(x = "Matrix"),
	  function(x) .bail.out.1(.Generic, class(x)))

setMethod("norm", signature(x = "Matrix", type = "character"),
	  function(x, type, ...) .bail.out.1("norm", class(x)))
setMethod("rcond", signature(x = "Matrix", norm = "character"),
	  function(x, norm, ...) .bail.out.1("rcond", class(x)))


## for all :
setMethod("norm", signature(x = "ANY", type = "missing"),
	  function(x, type, ...) norm(x, type = "O", ...))
setMethod("rcond", signature(x = "ANY", norm = "missing"),
	  function(x, norm, ...) rcond(x, norm = "O", ...))

setMethod("lu", "matrix", function(x, warnSing = TRUE, ...)
	  lu(as(x, "dgeMatrix"), warnSing=warnSing, ...))



## We want to use all.equal.numeric() *and* make sure that uses
## not just base::as.vector but the generic with our methods:
all.equal_num <- base::all.equal.numeric ## from <R>/src/library/base/R/all.equal.R
environment(all.equal_num) <- environment()## == as.environment("Matrix")

all.equal_Mat <- function(target, current, check.attributes = TRUE,
                          factorsCheck = FALSE, ...)
{
    msg <- attr.all_Mat(target, current, check.attributes=check.attributes,
                        factorsCheck=factorsCheck, ...)
    if(is.list(msg)) return(msg[[1]])
    ## else
    r <- all.equal_num(as.vector(target), as.vector(current),
                       check.attributes=check.attributes, ...)
    if(is.null(msg) & (r.ok <- isTRUE(r))) TRUE else c(msg, if(!r.ok) r)
}
## The all.equal() methods for dense matrices (and fallback):
setMethod("all.equal", c(target = "Matrix", current = "Matrix"),
	  all.equal_Mat)
setMethod("all.equal", c(target = "Matrix", current = "ANY"),
	  all.equal_Mat)
setMethod("all.equal", c(target = "ANY", current = "Matrix"),
	  all.equal_Mat)
## -> ./sparseMatrix.R, ./sparseVector.R  have specific methods



## MM: More or less "Cut & paste" from
## --- diff.default() from  R/src/library/base/R/diff.R :
setMethod("diff", signature(x = "Matrix"),
	  function(x, lag = 1, differences = 1, ...) {
	      if (length(lag) > 1 || length(differences) > 1 ||
		  lag < 1 || differences < 1)
		  stop("'lag' and 'differences' must be integers >= 1")
	      xlen <- nrow(x)
	      if (lag * differences >= xlen)
		  return(x[,FALSE][0])	# empty of proper mode

	      i1 <- -1:-lag
	      for (i in 1:differences)
		  x <- x[i1, , drop = FALSE] -
		      x[-nrow(x):-(nrow(x)-lag+1), , drop = FALSE]
	      x
	  })

setMethod("image", "Matrix",
	  function(x, ...) { # coercing to sparse is not inefficient,
	      ##	       since we need 'i' and 'j' for levelplot()
	      x <- as(as(x, "sparseMatrix"), "dsparseMatrix")
              ## note that "ddiMatrix" is "sparse*" and "d*", but *not* dsparse
	      callGeneric()
	  })


## Group Methods

## --- "Summary" ------- have "ddense*" and "dsparse*" ones in ---> ./dMatrix.R <---
##      -------          "diagMatrix" --> ./diagMatrix.R            ~~~~~~~~~~~
## For all other Matrix objects {and note that  "all" and "any" have their own}:

setMethod("all", signature(x = "Matrix"),
	  function(x, ..., na.rm)
	  callGeneric(as(x, "lMatrix"), ..., na.rm=na.rm))

setMethod("any", signature(x = "Matrix"),
	  function(x, ..., na.rm)
	  callGeneric(as(x, "lMatrix"), ..., na.rm=na.rm))

setMethod("Summary", signature(x = "Matrix", na.rm = "ANY"),
	  function(x, ..., na.rm)
	  callGeneric(as(x,"dMatrix"), ..., na.rm = na.rm))

Summary.l <- function(x, ..., na.rm) { ## must be method directly
    if(.Generic %in% c("all", "any"))
	callGeneric(x@x, ..., na.rm = na.rm)
    else {
	r <- callGeneric(as(x,"dMatrix"), ..., na.rm = na.rm)
	if(!is.infinite(r) && .Generic != "prod") as.integer(r) else r
    }
}
## almost identical:
Summary.np <- function(x, ..., na.rm) {
    if(.Generic %in% c("all", "any"))
	callGeneric(as(x, "lMatrix"), ..., na.rm = na.rm)
    else {
	r <- callGeneric(as(x,"dMatrix"), ..., na.rm = na.rm)
	if(!is.infinite(r) && .Generic != "prod") as.integer(r) else r
    }
}
##
setMethod("Summary", signature(x = "lMatrix", na.rm = "ANY"), Summary.l)
setMethod("Summary", signature(x = "nMatrix", na.rm = "ANY"), Summary.np)
setMethod("Summary", signature(x = "pMatrix", na.rm = "ANY"), Summary.np)

## NOTE:  "&" and "|"  are now in group "Logic" c "Ops" --> ./Ops.R
##        "!" is in ./not.R

## Further, see ./Ops.R
##                ~~~~~


### --------------------------------------------------------------------------
###
### Subsetting "["  and
### SubAssign  "[<-" : The "missing" cases can be dealt with here, "at the top":

## Using "index" for indices should allow
## integer (numeric), logical, or character (names!) indices :

## "x[]":
setMethod("[", signature(x = "Matrix",
			 i = "missing", j = "missing", drop = "ANY"),
	  function (x, i, j, ..., drop) x)

## missing 'drop' --> 'drop = TRUE'
##                     -----------
## select rows __ or __ vector indexing:
setMethod("[", signature(x = "Matrix", i = "index", j = "missing",
			 drop = "missing"),
	  function(x,i,j, ..., drop) {
	      Matrix.msg("M[i,m,m] : nargs()=",nargs(), .M.level = 2)
	      if(nargs() == 2) { ## e.g. M[0] , M[TRUE],  M[1:2]
                  .M.vectorSub(x,i)
	      } else {
		  callGeneric(x, i=i, , drop=TRUE)
		  ##		      ^^
	      }
	  })

## select columns
setMethod("[", signature(x = "Matrix", i = "missing", j = "index",
			 drop = "missing"),
	  function(x,i,j, ..., drop) {
	      Matrix.msg("M[m,i,m] : nargs()=",nargs(), .M.level = 2)
	      callGeneric(x, j=j, drop= TRUE)
	  })
setMethod("[", signature(x = "Matrix", i = "index", j = "index",
			 drop = "missing"),
	  function(x,i,j, ..., drop) {
	      Matrix.msg("M[i,i,m] : nargs()=",nargs(), .M.level = 2)
	      callGeneric(x, i=i, j=j, drop= TRUE)
	  })

## bail out if any of (i,j,drop) is "non-sense"
setMethod("[", signature(x = "Matrix", i = "ANY", j = "ANY", drop = "ANY"),
	  function(x,i,j, ..., drop)
	  stop("invalid or not-yet-implemented 'Matrix' subsetting"))

## logical indexing, such as M[ M >= 7 ] *BUT* also M[ M[,1] >= 3,],
## The following is *both* for    M [ <logical>   ]
##                 and also for   M [ <logical> , ]
.M.sub.i.logical <- function (x, i, j, ..., drop)
{
    nA <- nargs() # counts 'M[i]' as 2 arguments,  'M[i,]' as 3
    if(nA == 2) { ##  M [ M >= 7 ]
	## FIXME: when both 'x' and 'i' are sparse, this can be very inefficient
	if(is(x, "sparseMatrix"))
	    message("<sparse>[ <logic> ] : .M.sub.i.logical() maybe inefficient")
	toC <- geClass(x)
	if(canCoerce(x, toC)) as(x, toC)@x[as.vector(i)]
	else as(as(as(x, "generalMatrix"), "denseMatrix"), toC)@x[as.vector(i)]
	## -> error when lengths don't match
    }
    else if(nA == 3) { ## M[i, ]  e.g.,  M [ M[,1, drop=FALSE] >= 7, ]

	## Note: current method dispatch seems not to call this ever

	if(!any(is.na(i)) && all(i)) ## select everything
	    x
	else ## not selecting all -> result is *NOT* diagonal/triangular/symmetric/..
	    ## keep j missing, but  drop = "logical"
	    callGeneric(as(x,"generalMatrix"), i = i, , drop = TRUE)

    } else stop(gettextf(
		"nargs() = %d.  Extraneous illegal arguments inside '[ .. ]' (i.logical)?",
			 nA))
}

## instead of using 'drop = "ANY"' {against ambiguity notices}:
for(ii in c("lMatrix", "logical"))
    setMethod("[", signature(x = "Matrix", i = ii, j = "missing", drop = "missing"),
	      .M.sub.i.logical)


subset.ij <- function(x, ij) {
    ## x[ ij ]  where ij is (i,j) 2-column matrix
    m <- nrow(ij)
    if(m > 3) {
        cld <- getClassDef(class(x))
	sym.x <- extends(cld, "symmetricMatrix")
	if(sym.x) {
	    W <- if(x@uplo == "U") # stored only [i,j] with i <= j
		ij[,1] > ij[,2] else ij[,1] < ij[,2]
	    if(any(W))
		ij[W,] <- ij[W, 2:1]
        }
        if(extends(cld, "sparseMatrix")) {
	    ## do something smarter:
	    di <- dim(x)
	    if(!extends(cld, "CsparseMatrix")) {
		x <- as(x, "CsparseMatrix") # simpler; our standard
		cld <- getClassDef(class(x))
	    }
	    tri.x <- extends(cld, "triangularMatrix")
	    if(tri.x) {
		## need these for the 'x' slot in any case
		if (x@diag == "U") x <- .Call(Csparse_diagU2N, x)
		## slightly more efficient than non0.i() or non0ind():
		ij.x <- .Call(compressed_non_0_ij, x, isC=TRUE)
	    } else { ## symmetric / general : for symmetric, only "existing" part
		ij.x <- non0.i(x, cld)
	    }

	    m1 <- .Call(m_encodeInd, ij.x, di, checkBounds = FALSE)
            m2 <- .Call(m_encodeInd, ij -1L, di, checkBounds = TRUE)
	    mi <- match(m1, m2, nomatch=0)
	    mmi <- mi != 0
	    ## Result:
	    ans <- vector(mode = .type.kind[.M.kindC(cld)], length = m)
	    ## those that are *not* zero:
	    ans[mi[mmi]] <-
		if(extends(cld, "nsparseMatrix")) TRUE else x@x[mmi]
	    if(any(ina <- is.na(m2))) # has one or two NA in that (i,j) row
		is.na(ans) <- ina
	    ans

        } else { ## non-sparse : dense
            ##---- NEVER happens:  'denseMatrix' has its own setMethod(.) !
            message("m[ <ij-matrix> ]: inefficiently indexing single elements")
            i1 <- ij[,1]
            i2 <- ij[,2]
            ## very inefficient for large m
            unlist(lapply(seq_len(m), function(j) x[i1[j], i2[j]]))
        }
    } else { # 1 <= m <= 3
        i1 <- ij[,1]
        i2 <- ij[,2]
        unlist(lapply(seq_len(m), function(j) x[i1[j], i2[j]]))
    }
}

## A[ ij ]  where ij is (i,j) 2-column matrix -- but also when that is logical mat!
.M.sub.i.2col <- function (x, i, j, ..., drop)
{
    nA <- nargs()
    if(nA == 2) { ##  M [ cbind(ii,jj) ] or M [ <logical matrix> ]
	if(!is.integer(nc <- ncol(i)))
	    stop(".M.sub.i.2col(): 'i' has no integer column number;\n",
		 "should never happen; please report")
	if(is.logical(i))
	    return(.M.sub.i.logical(x, i=i)) # call with 2 args!
	else if(!is.numeric(i) || nc != 2)
	    stop("such indexing must be by logical or 2-column numeric matrix")
	m <- nrow(i)
        if(m == 0) return(vector(mode = .type.kind[.M.kind(x)]))
        ## else
        subset.ij(x, i)

    } else stop(gettextf(
		"nargs() = %d.  Extraneous illegal arguments inside '[ .. ]' (i.2col)?",
			 nA))
}
setMethod("[", signature(x = "Matrix", i = "matrix", j = "missing"),# drop="ANY"
	  .M.sub.i.2col)
## just against ambiguity notices :
setMethod("[", signature(x = "Matrix", i = "matrix", j = "missing", drop="missing"),
	  .M.sub.i.2col)


### "[<-" : -----------------

## A[ ij ] <- value,  where ij is (i,j) 2-column matrix :
## ----------------
## The cheap general method --- FIXME: provide special ones; done for Tsparse..
## NOTE:  need '...' below such that setMethod() does
##	  not use .local() such that nargs() will work correctly:
.M.repl.i.2col <- function (x, i, j, ..., value)
{
    nA <- nargs()
    if(nA == 3) { ##  M [ cbind(ii,jj) ] <- value  or M [ Lmat ] <- value
	if(!is.integer(nc <- ncol(i)))
	    stop(".M.repl.i.2col(): 'i' has no integer column number;\n",
		 "should never happen; please report")
	else if(!is.numeric(i) || nc != 2)
	    stop("such indexing must be by logical or 2-column numeric matrix")
	if(is.logical(i)) {
	    message(".M.repl.i.2col(): drop 'matrix' case ...")
	    ## c(i) : drop "matrix" to logical vector
	    return( callGeneric(x, i=c(i), value=value) )
	}
	if(!is.integer(i)) storage.mode(i) <- "integer"
	if(any(i < 0))
	    stop("negative values are not allowed in a matrix subscript")
	if(any(is.na(i)))
	    stop("NAs are not allowed in subscripted assignments")
	if(any(i0 <- (i == 0))) # remove them
            i <- i[ - which(i0, arr.ind = TRUE)[,"row"], ]
        ## now have integer i >= 1
	m <- nrow(i)
	## mod.x <- .type.kind[.M.kind(x)]
	if(length(value) > 0 && m %% length(value) != 0)
	    warning("number of items to replace is not a multiple of replacement length")
	## recycle:
	value <- rep(value, length = m)
	i1 <- i[,1]
	i2 <- i[,2]
	if(m > 2)
	    message("m[ <ij-matrix> ] <- v: inefficiently treating single elements")
	## inefficient -- FIXME -- (also loses "symmetry" unnecessarily)
	for(k in seq_len(m))
	    x[i1[k], i2[k]] <- value[k]

	x
    } else stop(gettextf(
		"nargs() = %d.  Extraneous illegal arguments inside '[ .. ]' ?",
			 nA))
}

setReplaceMethod("[", signature(x = "Matrix", i = "matrix", j = "missing",
				value = "replValue"),
		 .M.repl.i.2col)

## Three catch-all methods ... would be very inefficient for sparse*
## --> extra methods in ./sparseMatrix.R
setReplaceMethod("[", signature(x = "Matrix", i = "missing", j = "ANY",
				value = "Matrix"),
		 function (x, i, j, ..., value)
		 callGeneric(x=x, , j=j, value = as.vector(value)))

setReplaceMethod("[", signature(x = "Matrix", i = "ANY", j = "missing",
				value = "Matrix"),
		 function (x, i, j, ..., value)
		 callGeneric(x=x, i=i, , value = as.vector(value)))

setReplaceMethod("[", signature(x = "Matrix", i = "ANY", j = "ANY",
				value = "Matrix"),
		 function (x, i, j, ..., value)
		 callGeneric(x=x, i=i, j=j, value = as.vector(value)))


setReplaceMethod("[", signature(x = "Matrix", i = "missing", j = "ANY",
				value = "matrix"),
		 function (x, i, j, ..., value)
		 callGeneric(x=x, , j=j, value = c(value)))

setReplaceMethod("[", signature(x = "Matrix", i = "ANY", j = "missing",
				value = "matrix"),
		 function (x, i, j, ..., value)
		 callGeneric(x=x, i=i, , value = c(value)))

setReplaceMethod("[", signature(x = "Matrix", i = "ANY", j = "ANY",
				value = "matrix"),
		 function (x, i, j, value)
		 callGeneric(x=x, i=i, j=j, value = c(value)))

##  M [ <lMatrix> ] <- value; used notably for x = "CsparseMatrix"  -------------------
.repl.i.lDMat <- function (x, i, j, ..., value)
{
    ## nA <- nargs()
    ## if(nA != 3) stop(gettextf("nargs() = %d should never happen; please report.", nA))
    ## else: nA == 3  i.e.,  M [ Lmat ] <- value
    ## x[i] <- value ; return(x)
    `[<-`(x, i=which(as.vector(i)), value=value)
}
setReplaceMethod("[", signature(x = "Matrix", i = "ldenseMatrix", j = "missing",
				value = "replValue"), .repl.i.lDMat)
setReplaceMethod("[", signature(x = "Matrix", i = "ndenseMatrix", j = "missing",
				value = "replValue"), .repl.i.lDMat)
.repl.i.lSMat <- function (x, i, j, ..., value)
{
    ## nA <- nargs()
    ## if(nA != 3) stop(gettextf("nargs() = %d should never happen; please report.", nA))
    ## else: nA == 3  i.e.,  M [ Lmat ] <- value
    ## x[i] <- value ; return(x)
    `[<-`(x, i=which(as(i, "sparseVector")), value=value)
}
setReplaceMethod("[", signature(x = "Matrix", i = "lsparseMatrix", j = "missing",
				value = "replValue"), .repl.i.lSMat)
setReplaceMethod("[", signature(x = "Matrix", i = "nsparseMatrix", j = "missing",
				value = "replValue"), .repl.i.lSMat)

## (ANY,ANY,ANY) is used when no `real method' is implemented :
setReplaceMethod("[", signature(x = "Matrix", i = "ANY", j = "ANY",
                                value = "ANY"),
	  function (x, i, j, value) {
              if(!is.atomic(value))
		  stop(gettextf(
		"RHS 'value' (class %s) matches 'ANY', but must match matrix class %s",
			       class(value), class(x)))
              else stop("not-yet-implemented 'Matrix[<-' method")
          })
