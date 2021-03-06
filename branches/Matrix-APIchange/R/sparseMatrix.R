### Define Methods that can be inherited for all subclasses

### Idea: Coercion between *VIRTUAL* classes -- as() chooses "closest" classes
### ----  should also work e.g. for  dense-triangular --> sparse-triangular !

##-> see als ./dMatrix.R, ./ddenseMatrix.R  and  ./lMatrix.R

setAs("ANY", "sparseMatrix", function(from) as(from, "CsparseMatrix"))

setAs("sparseMatrix", "generalMatrix", as_gSparse)

setAs("sparseMatrix", "symmetricMatrix", as_sSparse)

setAs("sparseMatrix", "triangularMatrix", as_tSparse)

spMatrix <- function(nrow, ncol,
                     i = integer(), j = integer(), x = numeric())
{
    dim <- c(as.integer(nrow), as.integer(ncol))
    ## The conformability of (i,j,x) with itself and with 'dim'
    ## is checked automatically by internal "validObject()" inside new(.):
    kind <- .M.kind(x)
    new(paste(kind, "gTMatrix", sep=''), Dim = dim,
        x = if(kind == "d") as.double(x) else x,
        ## our "Tsparse" Matrices use  0-based indices :
        i = as.integer(i - 1L),
        j = as.integer(j - 1L))
}


## "graph" coercions -- this needs the graph package which is currently
##  -----               *not* required on purpose
## Note: 'undirected' graph <==> 'symmetric' matrix

## Add some utils that may no longer be needed in future versions of the 'graph' package
graph.has.weights <- function(g) "weight" %in% names(edgeDataDefaults(g))

graph.wgtMatrix <- function(g)
{
    ## Purpose: work around "graph" package's  as(g, "matrix") bug
    ## ----------------------------------------------------------------------
    ## Arguments: g: an object inheriting from (S4) class "graph"
    ## ----------------------------------------------------------------------
    ## Author: Martin Maechler, based on Seth Falcon's code;  Date: 12 May 2006

    ## MM: another buglet for the case of  "no edges":
    if(numEdges(g) == 0) {
      p <- length(nd <- nodes(g))
      return( matrix(0, p,p, dimnames = list(nd, nd)) )
    }
    ## Usual case, when there are edges:
    has.w <- "weight" %in% names(edgeDataDefaults(g))
    if(has.w) {
        w <- unlist(edgeData(g, attr = "weight"))
        has.w <- any(w != 1)
    } ## now 'has.w' is TRUE  iff  there are weights != 1
    m <- as(g, "matrix")
    ## now is a 0/1 - matrix (instead of 0/wgts) with the 'graph' bug
    if(has.w) { ## fix it if needed
        tm <- t(m)
        tm[tm != 0] <- w
        t(tm)
    }
    else m
}


setAs("graphAM", "sparseMatrix",
      function(from) {
	  symm <- edgemode(from) == "undirected" && isSymmetric(from@adjMat)
	  ## This is only ok if there are no weights...
	  if(graph.has.weights(from)) {
	      as(graph.wgtMatrix(from),
		 if(symm) "dsTMatrix" else "dgTMatrix")
	  }
	  else { ## no weights: 0/1 matrix -> logical
	      as(as(from, "matrix"),
		 if(symm) "nsTMatrix" else "ngTMatrix")
	  }
      })

setAs("graph", "CsparseMatrix",
      function(from) as(as(from, "graphNEL"), "CsparseMatrix"))

setAs("graphNEL", "CsparseMatrix",
      function(from) as(as(from, "TsparseMatrix"), "CsparseMatrix"))

setAs("graphNEL", "TsparseMatrix",
      function(from) {
          nd <- nodes(from)
          dm <- rep.int(length(nd), 2)
	  symm <- edgemode(from) == "undirected"

 	  if(graph.has.weights(from)) {
	      eWts <- edgeWeights(from)
	      lens <- unlist(lapply(eWts, length))
	      i <- rep.int(0:(dm[1]-1), lens) # column indices (0-based)
	      To <- unlist(lapply(eWts, names))
	      j <- as.integer(match(To,nd) - 1L) # row indices (0-based)
	      ## symm <- symm && <weights must also be symmetric>: improbable
	      ## if(symm) new("dsTMatrix", .....) else
	      new("dgTMatrix", i = i, j = j, x = unlist(eWts),
		  Dim = dm, Dimnames = list(nd, nd))
	  }
 	  else { ## no weights: 0/1 matrix -> logical
              edges <- lapply(from@edgeL[nd], "[[", "edges")
              lens <- unlist(lapply(edges, length))
              ## nnz <- sum(unlist(lens))  # number of non-zeros
              i <- rep.int(0:(dm[1]-1), lens) # column indices (0-based)
              j <- as.integer(unlist(edges) - 1) # row indices (0-based)
              if(symm) {            # symmetric: ensure upper triangle
                  tmp <- i
                  flip <- i > j
                  i[flip] <- j[flip]
                  j[flip] <- tmp[flip]
                  new("nsTMatrix", i = i, j = j, Dim = dm,
                      Dimnames = list(nd, nd), uplo = "U")
              } else {
                  new("ngTMatrix", i = i, j = j, Dim = dm,
                      Dimnames = list(nd, nd))
              }
          }
      })

setAs("sparseMatrix", "graph", function(from) as(from, "graphNEL"))
setAs("sparseMatrix", "graphNEL",
      function(from) as(as(from, "TsparseMatrix"), "graphNEL"))

Tsp2grNEL <- function(from) {
    d <- dim(from)
    if(d[1] != d[2])
	stop("only square matrices can be used as incidence matrices for graphs")
    n <- d[1]
    if(n == 0) return(new("graphNEL"))
    if(is.null(rn <- dimnames(from)[[1]]))
	rn <- as.character(1:n)
    from <- uniq(from) ## Need to 'uniquify' the triplets!

    if(isSymmetric(from)) { # either "symmetricMatrix" or otherwise
	##-> undirected graph: every edge only once!
	if(!is(from, "symmetricMatrix")) {
	    ## a general matrix which happens to be symmetric
	    ## ==> remove the double indices
	    from <- tril(from)
	}
        eMode <- "undirected"
    } else {
        eMode <- "directed"
    }
    ## every edge is there only once, either upper or lower triangle
    ft1 <- cbind(rn[from@i + 1L], rn[from@j + 1L])
    ## not yet: graph::ftM2graphNEL(.........)
    ftM2graphNEL(ft1, W = from@x, V= rn, edgemode= eMode)

}
setAs("TsparseMatrix", "graphNEL", Tsp2grNEL)


### Subsetting -- basic things (drop = "missing") are done in ./Matrix.R

### FIXME : we defer to the "*gT" -- conveniently, but not efficient for gC !

## [dl]sparse -> [dl]gT   -- treat both in one via superclass
##                        -- more useful when have "z" (complex) and even more

setMethod("[", signature(x = "sparseMatrix", i = "index", j = "missing",
			 drop = "logical"),
	  function (x, i, j, drop) {
	      cld <- getClassDef(class(x))
	      if(!extends(cld, "generalMatrix")) x <- as(x, "generalMatrix")
	      viaCl <- paste(.M.kind(x, cld), "gTMatrix", sep='')
	      x <- callGeneric(x = as(x, viaCl), i=i, drop=drop)
	      ## try_as(x, c(cl, sub("T","C", viaCl)))
	      if(is(x, "Matrix") && extends(cld, "CsparseMatrix"))
		  as(x, "CsparseMatrix") else x
	  })

setMethod("[", signature(x = "sparseMatrix", i = "missing", j = "index",
			 drop = "logical"),
	  function (x, i, j, drop) {
	      cld <- getClassDef(class(x))
	      if(!extends(cld, "generalMatrix")) x <- as(x, "generalMatrix")
	      viaCl <- paste(.M.kind(x, cld), "gTMatrix", sep='')
	      x <- callGeneric(x = as(x, viaCl), j=j, drop=drop)
	      if(is(x, "Matrix") && extends(cld, "CsparseMatrix"))
		  as(x, "CsparseMatrix") else x
	  })

setMethod("[", signature(x = "sparseMatrix",
			 i = "index", j = "index", drop = "logical"),
	  function (x, i, j, drop) {
	      cld <- getClassDef(class(x))
	      ## be smart to keep symmetric indexing of <symm.Mat.> symmetric:
	      doSym <- (extends(cld, "symmetricMatrix") &&
			length(i) == length(j) && all(i == j))
	      if(!doSym && !extends(cld, "generalMatrix"))
		  x <- as(x, "generalMatrix")
	      viaCl <- paste(.M.kind(x, cld),
			     if(doSym) "sTMatrix" else "gTMatrix", sep='')
	      x <- callGeneric(x = as(x, viaCl), i=i, j=j, drop=drop)
	      if(is(x, "Matrix") && extends(cld, "CsparseMatrix"))
		  as(x, "CsparseMatrix") else x
	  })


## setReplaceMethod("[", .........)
## -> ./Tsparse.R
## &  ./Csparse.R
## FIXME: also for RsparseMatrix


## Group Methods

setMethod("Math",
	  signature(x = "sparseMatrix"),
	  function(x) callGeneric(as(x, "CsparseMatrix")))

## further group methods -> see ./Ops.R



### --- show() method ---

## FIXME(?) -- ``merge this'' (at least ``synchronize'') with
## - - -   prMatrix() from ./Auxiliaries.R
## FIXME: prTriang() in ./Auxiliaries.R  should also get  align = "fancy"
## --> help for this is currently (rudimentary) in ../man/sparseMatrix-class.Rd
printSpMatrix <- function(x, digits = getOption("digits"),
		       maxp = getOption("max.print"), zero.print = ".",
		       col.names, note.dropping.colnames = TRUE,
		       col.trailer = '', align = c("fancy", "right"))
{
    cl <- getClassDef(class(x))
    stopifnot(extends(cl, "sparseMatrix"))
    d <- dim(x)
    if(prod(d) > maxp) { # "Large" => will be "cut"
        ## only coerce to dense that part which won't be cut :
        nr <- maxp %/% d[2]
	m <- as(x[1:max(1, nr), ,drop=FALSE], "Matrix")
    } else {
        m <- as(x, "matrix")
    }
    dn <- dimnames(m) ## will be === dimnames(cx)
    logi <- extends(cl,"lsparseMatrix") || extends(cl,"nsparseMatrix")
    if(logi)
	cx <- array("N", dim(m), dimnames=dn)
    else { ## numeric (or --not yet-- complex):
	cx <- apply(m, 2, format)
	if(is.null(dim(cx))) {# e.g. in	1 x 1 case
	    dim(cx) <- dim(m)
	    dimnames(cx) <- dn
	}
    }
    if (missing(col.names))
        col.names <- {
            if(!is.null(cc <- getOption("sparse.colnames")))
                cc
            else if(is.null(dn[[2]]))
                FALSE
            else { # has column names == dn[[2]]
                ncol(x) < 10
            }
        }
    if(identical(col.names, FALSE))
        cx <- emptyColnames(cx, msg.if.not.empty = note.dropping.colnames)
    else if(is.character(col.names)) {
        stopifnot(length(col.names) == 1)
        cn <- col.names
        switch(substr(cn, 1,3),
               "abb" = {
                   iarg <- as.integer(sub("^[^0-9]*", '', cn))
                   colnames(cx) <- abbreviate(colnames(cx), minlength = iarg)
               },
               "sub" = {
                   iarg <- as.integer(sub("^[^0-9]*", '', cn))
                   colnames(cx) <- substr(colnames(cx), 1, iarg)
               },
               stop("invalid 'col.names' string: ", cn))
    }
    ## else: nothing to do for col.names == TRUE
    if(is.logical(zero.print))
	zero.print <- if(zero.print) "0" else " "
    if(logi) {
	cx[!m] <- zero.print
	cx[m] <- "|"
    } else { # non logical
	## show only "structural" zeros as 'zero.print', not all of them..
	## -> cannot use 'm'
        d <- dim(cx)
	ne <- length(iN0 <- 1L + encodeInd(non0ind(x, cl), nr = d[1]))
	if(0 < ne && ne < prod(d)) {
	    align <- match.arg(align)
	    if(align == "fancy") {
		fi <- apply(m, 2, format.info) ## fi[3,] == 0  <==> not expo.
		## now 'format' the zero.print by padding it with ' ' on the right:
		## case 1: non-exponent:  fi[2,] + as.logical(fi[2,] > 0)
		## the column numbers of all 'zero' entries -- (*large*)
		cols <- 1L + (0:(prod(d)-1L))[-iN0] %/% d[1]
		pad <-
		    ifelse(fi[3,] == 0,
			   fi[2,] + as.logical(fi[2,] > 0),
			   ## exponential:
			   fi[2,] + fi[3,] + 4)
                ## now be efficient ; sprintf() is relatively slow
                ## and pad is much smaller than 'cols'; instead of "simply"
		## zero.print <- sprintf("%-*s", pad[cols] + 1, zero.print)
		if(any(doP <- pad > 0)) {#
		    ## only pad those that need padding - *before* expanding
		    z.p.pad <- rep.int(zero.print, length(pad))
		    z.p.pad[doP] <- sprintf("%-*s", pad[doP] + 1, zero.print)
		    zero.print <- z.p.pad[cols]
		}
                else
                    zero.print <- rep.int(zero.print, length(cols))
	    } ## else "right" : nothing to do

	    cx[-iN0] <- zero.print
	} else if (ne == 0)# all zeroes
	    cx[] <- zero.print
    }
    if(col.trailer != '')
        cx <- cbind(cx, col.trailer, deparse.level = 0)
    ## right = TRUE : cheap attempt to get better "." alignment
    print(cx, quote = FALSE, right = TRUE, max = maxp)
    invisible(x)
}

setMethod("print", signature(x = "sparseMatrix"), printSpMatrix)

setMethod("show", signature(object = "sparseMatrix"),
   function(object) {
       d <- dim(object)
       cl <- class(object)
       cat(sprintf('%d x %d sparse Matrix of class "%s"\n', d[1], d[2], cl))
       maxp <- getOption("max.print")
       if(prod(d) <= maxp)
	   printSpMatrix(object, maxp = maxp)
       else { ## d[1] > maxp / d[2] >= nr : -- this needs [,] working:

	   nR <- d[1] # nrow
           useW <- getOption("width") - (format.info(nR)[1] + 3+1)
           ##                           space for "[<last>,] "

           ## --> suppress rows and/or columns in printing ...

           suppCols <- (d[2] * 2 > useW)
           nc <- if(suppCols) (useW - (1 + 6)) %/% 2 else d[2]
           ##                          sp+ col.trailer
           col.trailer <- if(suppCols) "......" else ""
	   nr <- maxp %/% nc
           suppRows <- (nr < nR)
           if(suppRows) {
	       if(suppCols)
		   object <- object[ , 1:nc, drop = FALSE]
	       n2 <- ceiling(nr / 2)
	       printSpMatrix(object[seq_len(min(nR, max(1, n2))), , drop=FALSE],
                             col.trailer = col.trailer)
	       cat("\n ..............................",
		   "\n ..........suppressing rows in show(); maybe adjust 'options(max.print= *)'",
		   "\n ..............................\n\n", sep='')
	       ## tail() automagically uses "[..,]" rownames:
	       printSpMatrix(tail(object, max(1, nr-n2)),
                             col.trailer = col.trailer)
	   }
	   else if(suppCols) {
	       printSpMatrix(object[ , 1:nc , drop = FALSE],
                             col.trailer = col.trailer)

	       cat("\n .....suppressing columns in show(); maybe adjust 'options(max.print= *)'",
		   "\n ..............................\n", sep='')
	   }
           else stop("logic programming error in printSpMatrix(), please report")

           invisible(object)
       }
   })


## For very large and very sparse matrices,  the above show()
## is not really helpful;  Use  summary() as an alternative:

setMethod("summary", signature(object = "sparseMatrix"),
	  function(object, ...) {
	      d <- dim(object)
	      T <- as(object, "TsparseMatrix")
	      ## return a data frame (int, int,	 {double|logical|...})	:
	      r <- data.frame(i = T@i + 1L, j = T@j + 1L, x = T@x)
	      attr(r, "header") <-
		  sprintf('%d x %d sparse Matrix of class "%s", with %d entries',
			  d[1], d[2], class(object), nnzero(object))
	      ## use ole' S3 technology for such a simple case
	      class(r) <- c("sparseSummary", class(r))
	      r
	  })

print.sparseSummary <- function (x, ...) {
    cat(attr(x, "header"),"\n")
    print.data.frame(x, ...)
    invisible(x)
}

setMethod("isSymmetric", signature(object = "sparseMatrix"),
	  function(object, tol = 100*.Machine$double.eps) {
	      ## pretest: is it square?
	      d <- dim(object)
	      if(d[1] != d[2]) return(FALSE)
	      ## else slower test
	      if (is(object, "dMatrix"))
		  ## use gC; "T" (triplet) is *not* unique!
		  isTRUE(all.equal(.as.dgC.0.factors(  object),
				   .as.dgC.0.factors(t(object)), tol = tol))
	      else if (is(object, "lMatrix"))
		  ## test for exact equality; FIXME(?): identical() too strict?
		  identical(as(object, "lgCMatrix"),
			    as(t(object), "lgCMatrix"))
	      else if (is(object, "nMatrix"))
		  ## test for exact equality; FIXME(?): identical() too strict?
		  identical(as(object, "ngCMatrix"),
			    as(t(object), "ngCMatrix"))
	      else stop("not yet implemented")
	  })


## These two are not (yet?) exported:
setMethod("isTriangular", signature(object = "sparseMatrix"),
	  function(object, upper = NA)
              isTriC(as(object, "CsparseMatrix"), upper))

setMethod("isDiagonal", signature(object = "sparseMatrix"),
	  function(object) {
              d <- dim(object)
              if(d[1] != d[2]) return(FALSE)
              ## else
	      gT <- as(object, "TsparseMatrix")
	      all(gT@i == gT@j)
	  })


setMethod("diag", signature(x = "sparseMatrix"),
	  function(x, nrow, ncol = n) diag(as(x, "CsparseMatrix")))

setMethod("dim<-", signature(x = "sparseMatrix", value = "ANY"),
	  function(x, value) {
	      if(!is.numeric(value) || length(value) != 2)
		  stop("dim(.) value must be numeric of length 2")
	      if(prod(dim(x)) != prod(value <- as.integer(value)))
		  stop("dimensions don't match the number of cells")
              ## be careful to keep things sparse
	      as(spV2M(as(x, "sparseVector"), nrow=value[1], ncol=value[2]),
		 class(x))
	  })


lm.fit.sparse <-
function(x, y, offset = NULL, method = c("qr", "cholesky"),
         tol = 1e-7, singular.ok = TRUE, transpose = FALSE, ...)
### Fit a linear model using a sparse QR or a sparse Cholesky factorization
{
    stopifnot(is(x, "dsparseMatrix"))
    yy <- as.numeric(y)
    if (!is.null(offset)) {
        stopifnot(length(offset) == length(y))
        yy <- yy - as.numeric(offset)
    }
    ans <- switch(as.character(method)[1],
                  cholesky = .Call(dgCMatrix_cholsol,
                  as(if (transpose) x else t(x), "dgCMatrix"), yy),
                  qr = .Call(dgCMatrix_qrsol,
                  as(if (transpose) t(x) else x, "dgCMatrix"), yy),
                  stop(paste("unknown method", dQuote(method)))
                  )
    ans
}

fac2sparse <- function(from, to = c("d","i","l","n","z"))
{
    ## factor(-like) --> sparseMatrix {also works for integer, character}
    levs <- levels(fact <- factor(from)) # drop unused levels
    n <- length(fact)
    to <- match.arg(to)
    res <- new(paste(to, "gCMatrix", sep=''))
    res@i <- as.integer(fact) - 1L # 0-based
    res@p <- 0:n
    res@Dim <- c(length(levs), n)
    res@Dimnames <- list(levs, NULL)
    if(to != "n")
	res@x <- rep.int(switch(to,
				"d" = 1., "i" = 1L, "l" = TRUE, "z" = 1+0i),
			 n)
    res
}

setAs("factor", "sparseMatrix", function(from) fac2sparse(from, to = "d"))
