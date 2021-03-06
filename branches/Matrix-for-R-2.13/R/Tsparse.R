#### "TsparseMatrix" : Virtual class of sparse matrices in triplet-format

## more efficient than going via Csparse:
setAs("matrix", "TsparseMatrix",
      function(from)
      if(is.numeric(from)) mat2dgT(from)
      else if(is.logical(from)) as(Matrix(from, sparse=TRUE), "TsparseMatrix")
      else stop("not-yet-implemented coercion to \"TsparseMatrix\""))

setAs("numeric", "TsparseMatrix",
      function(from) as(as.matrix(from), "TsparseMatrix"))

setAs("TsparseMatrix", "matrix",
      function(from) .Call(dgTMatrix_to_matrix, as(from, "dgTMatrix")))

## in ../src/Tsparse.c :  |-> cholmod_T -> cholmod_C -> chm_sparse_to_SEXP
## adjusted for triangular matrices not represented in cholmod
.T.2.C <- function(from) .Call(Tsparse_to_Csparse, from, ##
			       is(from, "triangularMatrix"))

setAs("TsparseMatrix", "CsparseMatrix", .T.2.C)

.T.2.n <- function(from) {
    ## No: coercing to n(sparse)Matrix gives the "full" pattern including 0's
    ## if(any(is0(from@x))) ## 0 or FALSE -- the following should have drop0Tsp(.)
    ##	from <- as(drop0(from), "TsparseMatrix")
    if(is(from, "triangularMatrix")) # i.e. ?tTMatrix
	new("ntTMatrix", i = from@i, j = from@j,
	    uplo = from@uplo, diag = from@diag,
	    Dim = from@Dim, Dimnames = from@Dimnames)
    else if(is(from, "symmetricMatrix")) # i.e. ?sTMatrix
	new("nsTMatrix", i = from@i, j = from@j, uplo = from@uplo,
	    Dim = from@Dim, Dimnames = from@Dimnames)
    else
	new("ngTMatrix", i = from@i, j = from@j,
	    Dim = from@Dim, Dimnames = from@Dimnames)
}

setAs("TsparseMatrix", "nsparseMatrix", .T.2.n)
setAs("TsparseMatrix", "nMatrix", .T.2.n)

.T.2.l <- function(from) {
    cld <- getClassDef(class(from))
    xx <- if(extends(cld, "nMatrix"))
	rep.int(TRUE, length(from@i)) else as.logical(from@x)
    if(extends(cld, "triangularMatrix")) # i.e. ?tTMatrix
	new("ltTMatrix", i = from@i, j = from@j, x = xx,
	    uplo = from@uplo, diag = from@diag,
	    Dim = from@Dim, Dimnames = from@Dimnames)
    else if(extends(cld, "symmetricMatrix")) # i.e. ?sTMatrix
	new("lsTMatrix", i = from@i, j = from@j, x = xx, uplo = from@uplo,
	    Dim = from@Dim, Dimnames = from@Dimnames)
    else
	new("lgTMatrix", i = from@i, j = from@j, x = xx,
	    Dim = from@Dim, Dimnames = from@Dimnames)
}

setAs("TsparseMatrix", "lsparseMatrix", .T.2.l)
setAs("TsparseMatrix", "lMatrix", .T.2.l)



## Special cases   ("d", "l", "n")  %o%  ("g", "s", "t") :
## used e.g. in triu()

setAs("dgTMatrix", "dgCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("dsTMatrix", "dsCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("dtTMatrix", "dtCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, TRUE))


setAs("lgTMatrix", "lgCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("lsTMatrix", "lsCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("ltTMatrix", "ltCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, TRUE))


setAs("ngTMatrix", "ngCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("nsTMatrix", "nsCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, FALSE))

setAs("ntTMatrix", "ntCMatrix",
      function(from) .Call(Tsparse_to_Csparse, from, TRUE))

### "[" :
### -----

## Test for numeric/logical/character
## method-*internally* ; this is not strictly OO, but allows to use
## the following utility and hence much more compact code.

## Otherwise have to write methods for all possible combinations of
##  (i , j) \in
##  (numeric, logical, character, missing) x (numeric, log., char., miss.)


intI <- function(i, n, dn, give.dn = TRUE)
{
    ## Purpose: translate numeric | logical | character index
    ##		into 0-based integer
    ## ----------------------------------------------------------------------
    ## Arguments: i: index vector (numeric | logical | character)
    ##		  n: array extent		    { ==  dim(.) [margin] }
    ##		 dn: character col/rownames or NULL { == dimnames(.)[[margin]] }
    ## ----------------------------------------------------------------------
    ## Author: Martin Maechler, Date: 23 Apr 2007

    has.dn <- !is.null(dn)
    DN <- has.dn && give.dn
    if(is(i, "numeric")) {
	storage.mode(i) <- "integer"
	if(any(is.na(i)))
	    stop("'NA' indices are not (yet?) supported for sparse Matrices")
	if(any(i < 0L)) {
	    if(any(i > 0L))
		stop("you cannot mix negative and positive indices")
	    i0 <- (0:(n - 1L))[i]
	} else {
	    if(length(i) && max(i, na.rm=TRUE) > n)
		stop("index larger than maximal ",n)
	    if(any(z <- i == 0)) i <- i[!z]
	    i0 <- i - 1L		# transform to 0-indexing
	}
	if(DN) dn <- dn[i]
    }
    else if (is(i, "logical")) {
	if(length(i) > n)
	    stop(gettextf("logical subscript too long (%d, should be %d)",
			  length(i), n))
	i0 <- (0:(n - 1L))[i]
	if(DN) dn <- dn[i]
    } else { ## character
	if(!has.dn)
	    stop("no 'dimnames[[.]]': cannot use character indexing")
	i0 <- match(i, dn)
	if(any(is.na(i0))) stop("invalid character indexing")
	if(DN) dn <- dn[i0]
	i0 <- i0 - 1L
    }
    if(!give.dn) i0 else list(i0 = i0, dn = dn)
} ## {intI}

.ind.prep <- function(xi, intIlist, iDup = duplicated(i0), anyDup = any(iDup))
{
    ## Purpose: do the ``common things'' for "*gTMatrix" indexing for 1 dim.
    ##		and return match(.,.) + li = length of corresponding dimension
    ##
    ## xi = "x@i" ; intIlist = intI(i, dim(x)[margin], ....)

    i0 <- intIlist$i0
    stopifnot(is.numeric(i0))# cheap fast check (i0 may have length 0 !)

    m <- match(xi, i0, nomatch=0)
    if(anyDup) { # assuming   anyDup <- any(iDup <- duplicated(i0))
	## i0i: where in (non-duplicated) i0 are the duplicated ones
	i0i <- match(i0[iDup], i0)
	i.x <- which(iDup) - 1L
	jm <- lapply(i0i, function(.) which(. == m))
    }

    c(list(m = m, li = length(i0),
	   i0 = i0, anyDup = anyDup, dn = intIlist$dn),
      ## actually,  iDup  is rarely needed in calling code
      if(anyDup) list(iDup = iDup, i0i = i0i, i.x = i.x,
		      jm = unlist(jm), i.xtra = rep.int(i.x, sapply(jm, length))))
} ## {.ind.prep}

##' <description>
##' Do the ``common things'' for "*gTMatrix" sub-assignment
##' for 1 dimension, 'margin' ,
##' <details>
##' @title Indexing Preparation
##' @param i "index"
##' @param margin in {1,2};
##' @param di = dim(x)	{ used when i is not character }
##' @param dn = dimnames(x)
##' @return match(.,.) + li = length of corresponding dimension
##' difference to .ind.prep(): use 1-indices; no match(xi,..), no dn at end
##' @author Martin Maechler
.ind.prep2 <- function(i, margin, di, dn)
{
    intI(i, n = di[margin], dn = dn[[margin]], give.dn = FALSE)
}


## Select rows
setMethod("[", signature(x = "TsparseMatrix", i = "index", j = "missing",
			 drop = "logical"),
	  function (x, i, j, ..., drop) { ## select rows
	      na <- nargs()
	      Matrix.msg("Tsp[i,m,l]: nargs()=", na, .M.level=2)
	      if(na == 4)
		  .as.Tsp(as(x,"CsparseMatrix")[i, , drop=drop], noCheck = !drop)
	      else if(na == 3) ## e.g. M[0] , M[TRUE],	M[1:2]
		  .M.vectorSub(x,i)
	      else ## should not happen
		  stop("Matrix-internal error in <TsparseM>[i,,d]; please report")
	  })

## Select columns
setMethod("[", signature(x = "TsparseMatrix", i = "missing", j = "index",
			 drop = "logical"),
	  function (x, i, j, ..., drop) { ## select columns
	      .as.Tsp(as(x,"CsparseMatrix")[, j, drop=drop], noCheck = !drop)
	  })

setMethod("[", signature(x = "TsparseMatrix",
			 i = "index", j = "index", drop = "logical"),
	  function (x, i, j, ..., drop)
	  .as.Tsp(as(x,"CsparseMatrix")[i, j, drop=drop], noCheck = !drop))

## This is "just for now" -- Thinking of *not* doing this in the future
.as.Tsp <- function(x, noCheck)
    if(noCheck || is(x,"sparseMatrix")) as(x, "TsparseMatrix") else x


## FIXME: Learn from .TM... below or rather  .M.sub.i.2col(.) in ./Matrix.R
## ------ the following should be much more efficient than the
##  subset.ij() based ./Matrix.R code :
if(FALSE)
## A[ ij ]  where ij is (i,j) 2-column matrix :
setMethod("[", signature(x = "TsparseMatrix",
			 i = "matrix", j = "missing"),# drop="ANY"
	  function (x, i, j, ..., drop)
      {
	  di <- dim(x)
	  dn <- dimnames(x)
	  ## TODO check	 i (= 2-column matrix of indices) ---
	  ##	  as in	 .M.sub.i.2col() in ./Matrix.R
	  j <- i[,2]
	  i <- i[,1]
	  if(is(x, "symmetricMatrix")) {
	      isSym <- isTRUE(all(i == j))# work for i,j NA
	      if(!isSym)
		  x <- as(x, paste(.M.kind(x), "gTMatrix", sep=''))
	  } else isSym <- FALSE

	  if(isSym) {
	      offD <- x@i != x@j
	      ip1 <- .ind.prep(c(x@i,x@j[offD]), intI(i, n= di[1], dn=dn[[1]]))
	      ip2 <- .ind.prep(c(x@j,x@i[offD]), intI(j, n= di[2], dn=dn[[2]]))
	  } else {
	      ip1 <- .ind.prep(x@i, intI(i, n = di[1], dn = dn[[1]]))
	      ip2 <- .ind.prep(x@j, intI(j, n = di[2], dn = dn[[2]]))
	  }

	  stop("FIXME: NOT YET FINISHED IMPLEMENTATION")

	  ## The M[i_vec, j_vec] had -- we need "its diagonal" :
	  sel <- ip1$m	&  ip2$m
	  if(isSym) { # only those corresponding to upper/lower triangle
	      sel <- sel &
	      (if(x@uplo == "U") ip1$m <= ip2$m else ip2$m <= ip1$m)
	  }
	  x@i <- ip1$m[sel] - 1L
	  x@j <- ip2$m[sel] - 1L
	  if (!is(x, "nsparseMatrix"))
	      x@x <- c(x@x, if(isSym) x@x[offD])[sel]
	  if (drop && any(nd == 1)) drop(as(x,"matrix")) else x

      })


###========= Sub-Assignment aka *Replace*Methods =========================

### FIXME: make this `very fast'  for the very very common case of
### -----   M[i,j] <- v  with   i,j = length-1-numeric;  v= length-1 number
###                            *and* M[i,j] == 0 previously
##
## FIXME(2): keep in sync with replCmat() in ./Csparse.R
## FIXME(3): It's terribly slow when used e.g. from diag(M[,-1]) <- value
## -----     which has "workhorse"   M[,-1] <- <dsparseVector>
##
## workhorse for "[<-" :
replTmat <- function (x, i, j, ..., value)
{
## NOTE:  need '...', i.e., exact signature such that setMethod()
##	  does not use .local() such that nargs() will work correctly:
    di <- dim(x)
    dn <- dimnames(x)
    iMi <- missing(i)
    jMi <- missing(j)
    ## "FIXME": could pass this (and much ? more) when this function would not *be* a
    ## method but be *called* from methods
    spV <- is(value, "sparseVector")
    ## own version of all0() that works both for sparseVector and atomic vectors:
    .all0 <- function(v) if(spV) length(v@i) == 0 else all0(v)

    na <- nargs()
    if(na == 3) { ## i = vector (but *not* 2-col) indexing"  M[i] <- v
	Matrix.msg("diagnosing replTmat(x,i,j,v): nargs()= 3; ",
		   if(iMi | jMi) sprintf("missing (i,j) = (%d,%d)", iMi,jMi))
	if(iMi) stop("internal bug: missing 'i' in replTmat(): please report")
	if(is.character(i))
	    stop("[ <character> ] indexing not allowed: forgot a \",\" ?")
	if(is.matrix(i))
	    stop("internal bug: matrix 'i' in replTmat(): please report")
	## Now: have  M[i] <- v	 with vector logical or "integer" i :
	## Tmatrix maybe non-unique, have an entry split into a sum of several ones:

	if(!is(x,"generalMatrix")) {
	    cl <- class(x)
	    x <- as(x, paste(.M.kind(x), "gTMatrix", sep=''))
	    Matrix.msg("'sub-optimal sparse 'x[i] <- v' assignment: Coercing class ",
		       cl," to ",class(x))
	}
	nr <- di[1]
	x.i <- .Call(m_encodeInd2, x@i, x@j, di=di, FALSE)
	if(anyDuplicated(x.i)) { ## == if(is_duplicatedT(x, di = di))
	    x <- uniqTsparse(x)
	    x.i <- .Call(m_encodeInd2, x@i, x@j, di=di, FALSE)
	}

	if(is.logical(i)) { # full-size logical indexing
	    n <- prod(di)
	    if(n) {
		if(length(i) < n) i <- rep(i, length.out = n)
		i <- (0:(n-1))[i] # -> 0-based index vector as well {maybe LARGE!}
	    } else i <- integer(0)
	} else i <- as.integer(i) - 1L ## 0-based indices

        clx <- class(x)
        clDx <- getClassDef(clx) # extends(), is() etc all use the class definition
        has.x <- "x" %in% slotNames(clDx) # === slotNames(x)

	## now have 0-based indices   x.i (entries) and	 i (new entries)

	## the simplest case:
	if(.all0(value)) { ## just drop the non-zero entries
	    sel <- is.na(match(x.i, i))
	    if(any(!sel)) { ## non-zero there
		x@i <- x@i[sel]
		x@j <- x@j[sel]
		if(has.x)
		    x@x <- x@x[sel]
		if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
		    x@factors <- list()
	    }
	    return(x)
	}

	m <- length(i)
	if(length(value) != m) { ## use recycling rules
	    if(m %% length(value) != 0)
		warning("number of items to replace is not a multiple of replacement length")
	    value <- rep(value, length.out = m)
	}

	## matching existing non-zeros and new entries
	isE <- !is.na(mi <- match(i, x.i)) ## use  which(isE) , mi[isE]
	## 1) Change the matching non-zero entries
	if(has.x)
	    x@x[mi[isE]] <- value[isE]
	## 2) add the new non-zero entries
	i <- i[!isE]
	x@i <- c(x@i, i %%  nr)
	x@j <- c(x@j, i %/% nr)
	if(has.x)
	    x@x <- c(x@x, value[!isE])
	if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
	    x@factors <- list()
	return(x)
    }
    ## nargs() == 4 :  x[i,j] <- value
    lenV <- length(value)
    Matrix.msg(".. replTmat(x,i,j,v): nargs()= 4; cl.(x)=",
	       class(x),"; len.(value)=", lenV,"; ",
	       if(iMi | jMi) sprintf("missing (i,j) = (%d,%d)", iMi,jMi),
	       .M.level = 2)# level 1  gives too many messages

    ## FIXME: use  'abIndex' or a better algorithm, e.g.  if(iMi)
    i1 <- if(iMi) 0:(di[1] - 1L) else .ind.prep2(i, 1, di, dn)
    i2 <- if(jMi) 0:(di[2] - 1L) else .ind.prep2(j, 2, di, dn)
    dind <- c(length(i1), length(i2)) # dimension of replacement region
    lenRepl <- prod(dind)
    if(lenV == 0) {
        if(lenRepl != 0)
            stop("nothing to replace with")
        else return(x)
    }
    ## else: lenV := length(value)	 is > 0
    if(lenRepl %% lenV != 0)
        stop("number of items to replace is not a multiple of replacement length")
    ## Now deal with duplicated / repeated indices: "last one wins"
    if(!iMi && any(dup <- duplicated(i1, fromLast = TRUE))) { ## duplicated rows
        keep <- !dup
        i1 <- i1[keep]
        ## keep is "internally" recycled below {and that's important: it is dense!}
        lenV <- length(value <- rep(value, length.out = lenRepl)[keep])
        dind[1] <- length(i1)
        lenRepl <- prod(dind)
    }
    if(!jMi && any(dup <- duplicated(i2, fromLast = TRUE))) { ## duplicated columns
        iDup <- which(dup)
        ## FIXME: this is correct, but  rep(keep,..) can be *HUGE*
        ## keep <- !dup
        ## i2 <- i2[keep]
        ## lenV <- length(value <- rep(value, length.out = lenRepl)[rep(keep, each=dind[1])])
        ## solution: sv[-i] is efficient for sparseVector:
        i2 <- i2[- iDup]
        nr <- dind[1]
        iDup <- rep((iDup - 1)*nr, each=nr) + seq_len(nr)
        lenV <- length(value <- rep(value, length.out = lenRepl)[-iDup])
        dind[2] <- length(i2)
        lenRepl <- prod(dind)
    }
    clx <- class(x)
    clDx <- getClassDef(clx) # extends() , is() etc all use the class definition
    stopifnot(extends(clDx, "TsparseMatrix"))
    ## Tmatrix maybe non-unique, have an entry split into a sum of several ones:
    if(is_duplicatedT(x, di = di))
	x <- uniqTsparse(x)

    toGeneral <- r.sym <- FALSE
    if(extends(clDx, "symmetricMatrix")) {
        mkArray <- if(spV) # TODO: room for improvement
            function(v, dim) spV2M(v, dim[1],dim[2]) else array
	r.sym <- (dind[1] == dind[2]) && all(i1 == i2) &&
	(lenRepl == 1 || isSymmetric(value <- mkArray(value, dim=dind)))
	if(r.sym) { ## result is *still* symmetric --> keep symmetry!
	    xU <- x@uplo == "U"
            # later, we will consider only those indices above / below diagonal:
	}
	else toGeneral <- TRUE
    }
    else if(extends(clDx, "triangularMatrix")) {
        xU <- x@uplo == "U"
	r.tri <- ((any(dind == 1) || dind[1] == dind[2]) &&
		  if(xU) max(i1) <= min(i2) else max(i2) <= min(i1))
	if(r.tri) { ## result is *still* triangular
            if(any(i1 == i2)) # diagonal will be changed
                x <- diagU2N(x) # keeps class (!)
	}
	else toGeneral <- TRUE
    }
    if(toGeneral) { # go to "generalMatrix" and continue
	if((.w <- isTRUE(getOption("Matrix.warn"))) || isTRUE(getOption("Matrix.verbose")))
	    (if(.w) warning else message)(
	     "M[i,j] <- v :  coercing symmetric M[] into non-symmetric")
        x <- as(x, paste(.M.kind(x), "gTMatrix", sep=''))
        clDx <- getClassDef(clx <- class(x))
    }

    ## TODO (efficiency): replace  'sel' by 'which(sel)'
    get.ind.sel <- function(ii,ij)
	(match(x@i, ii, nomatch = 0) & match(x@j, ij, nomatch = 0))

    ## sel[k] := TRUE iff k-th non-zero entry (typically x@x[k]) is to be replaced
    sel <- get.ind.sel(i1,i2)
    has.x <- "x" %in% slotNames(clDx) # === slotNames(x)

    ## the simplest case: for all Tsparse, even for i or j missing
    if(.all0(value)) { ## just drop the non-zero entries
	if(any(sel)) { ## non-zero there
	    x@i <- x@i[!sel]
	    x@j <- x@j[!sel]
            if(has.x)
		x@x <- x@x[!sel]
	    if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
		x@factors <- list()
	}
	return(x)
    }

    ## else --  some( value != 0 ) --
    if(lenV > lenRepl)
        stop("too many replacement values")
    ## now have  lenV <= lenRepl

    ## another simple, typical case:
    if(lenRepl == 1) {
        if(spV && has.x) value <- as(value, "vector")
        if(any(sel)) { ## non-zero there
            if(has.x)
                x@x[sel] <- value
        } else { ## new non-zero
            x@i <- c(x@i, i1)
            x@j <- c(x@j, i2)
            if(has.x)
                x@x <- c(x@x, value)
        }
	if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
	    x@factors <- list()
        return(x)
    }

##     if(r.sym) # value already adjusted, see above
##        lenRepl <- length(value) # shorter (since only "triangle")
    if(!r.sym && lenV < lenRepl)
        value <- rep(value, length.out = lenRepl)

    ## now:  length(value) == lenRepl

    ## value[1:lenRepl]:  which are structural 0 now, which not?
    ## v0 <- is0(value)
    ## - replaced by using isN0(as.vector(.)) on a typical small subset value[.]
    ## --> more efficient for sparse 'value' & large 'lenRepl' :
    ## FIXME [= FIXME(3) above]:
    ## ----- The use of  seq_len(lenRepl) below is *still* inefficient
    ##   (or impossible e.g. when lenRepl == 50000^2)
    ##       and the  vN0 <- isN0(as.vector(value[iI0]))  is even more ...
    ## try to replace   'seq_len(lenRepl)'  by  'abIseq1(1L, lenRepl)' :
    ##_ new experimental: -- need   <value>[ <abIndex> ] , intersect() ...
    ##_ iI0 <- abIseq1(1L, lenRepl)
    ##_ old -- FIXME_replace -- (but need more abIndex functionality)
    iI0 <- seq_len(lenRepl)
    if(any(sel)) {
	## the 0-based indices of non-zero entries -- WRT to submatrix
	non0 <- cbind(match(x@i[sel], i1),
		      match(x@j[sel], i2)) - 1L
	iN0 <- 1L + .Call(m_encodeInd, non0, di = dind, FALSE)

	## 1a) replace those that are already non-zero with non-0 values
	vN0 <- isN0(as.vector(value[iN0]))
	if(any(vN0) && has.x)
	    x@x[sel][vN0] <- as.vector(value[iN0[vN0]])

	## 1b) replace non-zeros with 0 --> drop entries
	if(any(!vN0)) {
	    ii <- which(sel)[!vN0]
	    if(has.x)
		x@x <- x@x[-ii]
	    x@i <- x@i[-ii]
	    x@j <- x@j[-ii]
	}
	iI0 <- if(length(iN0) < lenRepl) iI0[-iN0] ## else NULL
                                        # == complementInd(non0, dind)
    }
    if(length(iI0)) {
        if(r.sym) {
	    ## should only set new entries above / below diagonal, i.e.,
            ## subset iI0 such as to contain only  above/below ..
            ## FIXME: this should be changed for abIndex case ...
	    iSel <- indTri(dind[1], upper=xU, diag=TRUE)
	    ## select also the corresponding triangle of values
	    iI0 <- intersect(iI0, iSel)
        }
        full <- length(iI0) == lenRepl
	vN0 <-
	    if(!is.atomic(value)) ## <==> "sparseVector"
		(if(full) value else value[iI0])@i
	    else which(isN0(if(full) value else value[iI0]))
	if(length(vN0)) {
	    ## 2) add those that were structural 0 (where value != 0)
	    iIN0 <- if(full) vN0 else iI0[vN0]
	    ij0 <- decodeInd(iIN0 - 1L, nr = dind[1])
	    x@i <- c(x@i, i1[ij0[,1] + 1L])
	    x@j <- c(x@j, i2[ij0[,2] + 1L])
	    if(has.x)
		x@x <- c(x@x, as.vector(value[iIN0]))
	}
    }
    if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
	x@factors <- list()
    x
} ## end{replTmat}

## A[ ij ] <- value,  where ij is a matrix; typically (i,j) 2-column matrix :
## ----------------   ./Matrix.R has a general cheap method
## This one should become as fast as possible -- is also used from Csparse.R --
.TM.repl.i.mat <- function (x, i, j, ..., value)
{
    nA <- nargs()
    if(nA != 3)
	stop(gettextf("nargs() = %d should never happen; please report.", nA))

    ## else: nA == 3  i.e.,  M [ cbind(ii,jj) ] <- value or M [ Lmat ] <- value
    if(is.logical(i)) {
	Matrix.msg(".TM.repl.i.mat(): drop 'matrix' case ...", .M.level=2)
	## c(i) : drop "matrix" to logical vector
	x[as.vector(i)] <- value
	return(x)
    } else if(extends(cli <- getClassDef(class(i)),"lMatrix") || extends(cli, "nMatrix")) {
	Matrix.msg(".TM.repl.i.mat(): \"lMatrix\" case ...", .M.level=2)
	i <- which(as(i, if(extends(cli, "sparseMatrix")) "sparseVector" else "vector"))
	## x[i] <- value ; return(x)
	return(`[<-`(x,i, value=value))
    } else if(!is.numeric(i) || ncol(i) != 2)
	stop("such indexing must be by logical or 2-column numeric matrix")
    if(!is.integer(i)) storage.mode(i) <- "integer"
    if(any(i < 0))
	stop("negative values are not allowed in a matrix subscript")
    if(any(is.na(i)))
	stop("NAs are not allowed in subscripted assignments")
    if(any(i0 <- (i == 0))) # remove them
	i <- i[ - which(i0, arr.ind = TRUE)[,"row"], ]
    if(length(attributes(i)) > 1) # more than just 'dim'; simplify: will use identical
	attributes(i) <- list(dim = dim(i))
    ## now have integer i >= 1
    m <- nrow(i)
    if(m == 0)
	return(x)
    if(length(value) == 0)
	stop("nothing to replace with")
    ## mod.x <- .type.kind[.M.kind(x)]
    if(length(value) != m) { ## use recycling rules
	if(m %% length(value) != 0)
	    warning("number of items to replace is not a multiple of replacement length")
	value <- rep(value, length = m)
    }
    clx <- class(x)
    clDx <- getClassDef(clx) # extends() , is() etc all use the class definition
    stopifnot(extends(clDx, "TsparseMatrix"))

    di <- dim(x)
    nr <- di[1]
    nc <- di[2]
    i1 <- i[,1]
    i2 <- i[,2]
    if(any(i1 > nr)) stop("row indices must be <= nrow(.) which is ", nr)
    if(any(i2 > nc)) stop("column indices must be <= ncol(.) which is ", nc)

    ## Tmatrix maybe non-unique, have an entry split into a sum of several ones:
    if(is_duplicatedT(x, di = di))
	x <- uniqTsparse(x)

    toGeneral <- FALSE
    if(r.sym <- extends(clDx, "symmetricMatrix")) {
	## Tests to see if the assignments are symmetric as well
	r.sym <- all(i1 == i2)
	if(!r.sym) { # do have *some* Lower or Upper entries
	    iL <- i1 > i2
	    iU <- i1 < i2
	    r.sym <- sum(iL) == sum(iU) # same number
	    if(r.sym) {
		iLord <- order(i1[iL], i2[iL])
		iUord <- order(i2[iU], i1[iU]) # row <-> col. !
		r.sym <- {
		    identical(i[iL,    , drop=FALSE][iLord,],
			      i[iU, 2:1, drop=FALSE][iUord,]) &&
		    all(value[iL][iLord] ==
			value[iU][iUord])
		}
	    }
	}
	if(r.sym) { ## result is *still* symmetric --> keep symmetry!
	    ## now consider only those indices above / below diagonal:
	    useI <- if(x@uplo == "U") i1 <= i2 else i2 <= i1
	    i <- i[useI, , drop=FALSE]
	    value <- value[useI]
	}
	else toGeneral <- TRUE
    }
    else if(extends(clDx, "triangularMatrix")) {
	r.tri <- all(if(x@uplo == "U") i1 <= i2 else i2 <= i1)
	if(r.tri) { ## result is *still* triangular
	    if(any(i1 == i2)) # diagonal will be changed
		x <- diagU2N(x) # keeps class (!)
	}
	else toGeneral <- TRUE
    }
    if(toGeneral) { # go to "generalMatrix" and continue
	if((.w <- isTRUE(getOption("Matrix.warn"))) || isTRUE(getOption("Matrix.verbose")))
	    (if(.w) warning else message)(
	     "M[ij] <- v :  coercing symmetric M[] into non-symmetric")
	x <- as(x, paste(.M.kind(x), "gTMatrix", sep=''))
	clDx <- getClassDef(clx <- class(x))
    }

    ii.v <- .Call(m_encodeInd, i - 1L, di, checkBounds = TRUE)# 0-indexing
    if(any(d <- duplicated(rev(ii.v)))) { # reverse: "last" duplicated FALSE
	warning("duplicate ij-entries in 'Matrix[ ij ] <- value'; using last")
	nd <- !rev(d)
	## i  <- i    [nd, , drop=FALSE]
	ii.v  <- ii.v [nd]
	value <- value[nd]
    }
    ii.x <- .Call(m_encodeInd2, x@i, x@j, di, FALSE)
    m1 <- match(ii.v, ii.x)
    i.repl <- !is.na(m1) # those that need to be *replaced*

    if(isN <- extends(clDx, "nMatrix")) { ## no 'x' slot
	isN <- all(value %in% c(FALSE, TRUE)) # will result remain  "nMatrix" ?
	if(!isN)
	    x <- as(x, paste(if(extends(clDx, "lMatrix")) "l" else "d",
			     .sparse.prefixes[.M.shape(x)], "TMatrix", sep=''))
    }
    has.x <- !isN ## isN  <===> "remains pattern matrix" <===> has no 'x' slot

    if(any(i.repl)) { ## some to replace at matching (@i, @j)
	if(has.x)
	    x@x[m1[i.repl]] <- value[i.repl]
	else { # nMatrix ; eliminate entries that are set to FALSE; keep others
	    if(any(isF <- !value[i.repl]))  {
		ii <- m1[i.repl][isF]
		x@i <- x@i[ -ii]
		x@j <- x@j[ -ii]
	    }
	}
    }
    if(any(i.new <- !i.repl & isN0(value))) { ## some new entries
	i.j <- decodeInd(ii.v[i.new], nr)
	x@i <- c(x@i, i.j[,1])
	x@j <- c(x@j, i.j[,2])
	if(has.x)
	    x@x <- c(x@x, value[i.new])
    }

    if(extends(clDx, "compMatrix") && length(x@factors)) # drop cashed ones
	x@factors <- list()
    x
} ## end{.TM.repl.i.mat}

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "index", j = "missing",
				value = "replValue"),
		 replTmat)

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "missing", j = "index",
				value = "replValue"),
		 replTmat)

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "index", j = "index",
				value = "replValue"),
		 replTmat)

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "matrix", j = "missing",
				value = "replValue"),
		 .TM.repl.i.mat)


### When the RHS 'value' is  a sparseVector, now can use  replTmat  as well
setReplaceMethod("[", signature(x = "TsparseMatrix", i = "missing", j = "index",
				value = "sparseVector"),
		 replTmat)

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "index", j = "missing",
				value = "sparseVector"),
		 replTmat)

setReplaceMethod("[", signature(x = "TsparseMatrix", i = "index", j = "index",
				value = "sparseVector"),
		 replTmat)




setMethod("solve", signature(a = "TsparseMatrix", b = "ANY"),
	  function(a, b, ...) solve(as(a, "CsparseMatrix"), b))
setMethod("solve", signature(a = "TsparseMatrix", b = "missing"),
	  function(a, b, ...) solve(as(a, "CsparseMatrix")))


## Want tril(), triu(), band() --- just as "indexing" ---
## return a "close" class:
setMethod("tril", "TsparseMatrix",
	  function(x, k = 0, ...)
	  as(tril(.T.2.C(x), k = k, ...), "TsparseMatrix"))
setMethod("triu", "TsparseMatrix",
	  function(x, k = 0, ...)
	  as(triu(.T.2.C(x), k = k, ...), "TsparseMatrix"))
setMethod("band", "TsparseMatrix",
	  function(x, k1, k2, ...)
	  as(band(.T.2.C(x), k1 = k1, k2 = k2, ...), "TsparseMatrix"))


## For the "general" T ones (triangular & symmetric have special methods):
setMethod("t", signature(x = "TsparseMatrix"),
	  function(x) {
              cld <- getClassDef(class(x))
	      r <- new(cld)
	      r@i <- x@j
	      r@j <- x@i
	      if(any("x" == slotNames(cld)))
		  r@x <- x@x
	      r@Dim <- x@Dim[2:1]
	      r@Dimnames <- x@Dimnames[2:1]
	      r
      })


setMethod("writeMM", "TsparseMatrix",
	  function(obj, file, ...)
          .Call(Csparse_MatrixMarket, as(obj, "CsparseMatrix"),
                as.character(file)))
