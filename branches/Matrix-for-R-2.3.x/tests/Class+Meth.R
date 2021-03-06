library(Matrix)
source(system.file("test-tools.R", package = "Matrix"))# identical3() etc

#### Automatically display the class inheritance structure
#### possibly augmented with methods

allCl <- getClasses("package:Matrix")

## Really nice would be to construct an inheritance graph and display
## it.  The following is just a cheap first step.

cat("All classes in the 'Matrix' package:\n")
for(cln in allCl) {
    cat("\n-----\n\nClass", dQuote(cln),":\n      ",
        paste(rep("~",nchar(cln)),collapse=''),"\n")
    ## A smarter version would use  getClass() instead of showClass(),
    ## build the "graph" and only then display.

    showClass(cln)
}

cat("\n\n")

## One could extend the `display' by using (something smarter than)
## are the "coerce" methods showing more than the 'Extends' output above?
cat("All (S4) methods in the 'Matrix' package:\n")
showMethods(where="package:Matrix")

## 1-indexing instead of 0-indexing for direct "dgT" should give error:
ii <- as.integer(c(1,2,2))
jj <- as.integer(c(1,1,3))
assertError(new("dgTMatrix",  i=ii, j=jj,        x= 10*(1:3), Dim=2:3))
assertError(new("dgTMatrix",  i=ii, j=jj - 1:1,  x= 10*(1:3), Dim=2:3))
assertError(new("dgTMatrix",  i=ii - 1:1, j=jj,  x= 10*(1:3), Dim=2:3))
(mm <- new("dgTMatrix",  i=ii - 1:1, j=jj - 1:1, x= 10*(1:3), Dim=2:3))
validObject(mm)

### Sparse Logical:
m <- Matrix(c(0,0,2:0), 3,5)
mT <- as(mC <- as(m, "dgCMatrix"), "dgTMatrix")
stopifnot(identical(as(mT,"dgCMatrix"), mC))
(mlC <- as(as(mT[1:2, 2:3], "dgCMatrix"), "lgCMatrix"))

if(FALSE) ## ltC no longer extends lgC -- want coercion possibility FIXME
as(mlC,"ltCMatrix")


### Test all classes:  validObject(new( * )) should be fulfilled -----------

## need stoplist for now:
not.ok.classes <- paste(c("lgR", # only stub implementation
			  "lsR", # dito
			  "ltR", # dito

			  "ltT", # ltTMatrix_validate missing; as(*,"matrix")
			  "lsT", # lsTMatrix_validate  "	"

			  ""), "Matrix", sep='')
## From the rest, those that don't show :
no.show.classes <- paste(c("dgR", # only stub implementation
			   "dsR", # dito
			   "dtR", #  "
			   ), "Matrix", sep='')

no.t.classes  <- no.show.classes # no t() available
not.coerce0   <- no.show.classes # not coercable to   "matrix"
not.coerce1   <- no.show.classes # not coercable from "dgeMatrix"
not.coerce2   <- no.show.classes # not coercable from "matrix"

tstMatrixClass <-
    function(cl, mM = Matrix(c(2,1,1,2) + 0, 2,2), mm = as(mM, "matrix"),
             recursive = TRUE, offset = 0)
{
    ## Purpose: Test 'Matrix' class {and do this for all of them}
    ## ----------------------------------------------------------------------
    ## Arguments: cl: class object of a class that extends "Matrix"
    ##            mM: a "Matrix"-matrix which will be coerced to class 'cl'
    ##            mm: a S3-matrix       which will be coerced to class 'cl'
    ## ----------------------------------------------------------------------
    ## Author: Martin Maechler

    ## This is sfsmisc::bl.string():
    bl.string <- function (no) paste(rep(" ", no), collapse = "")

    mM <- as(mM, "dgeMatrix")
    mm <- as(mm, "matrix")

    if(recursive)
        cList <- character(0)

    ## This is the recursive function
    dotestMat <- function(cl, offset)
    {
        cat. <- function(...) cat(bl.string(offset), ...)

        clNam <- cl@subClass
        cat("\n")
        cat.(clNam)
        ##---------
        if(isVirtualClass(clNam)) {
            cat(" - is virtual\n")
            if(recursive) {
                cat.("----- begin{class :", clNam, "}----new subclasses----\n")
                for(ccl in getClass(clNam)@subclasses) {
                    cclN <- ccl@subClass
                    if(cclN %in% cList)
                        cat.(cclN,": see above\n")
                    else {
                        cList <<- c(cList, cclN)
                        dotestMat(ccl, offset = offset + 3)
                    }
                }
                cat.("----- end{class :", clNam, "}---------------------\n")
            }
        } else {
            cat("; new(..): ")
            m <- new(clNam)

            if(any(clNam == not.ok.classes)) {
                cat("in 'stop list' - no validity\n")
            } else {
                cat("valid: ", validObject(m))

                if(any(clNam == no.t.classes)) {
                    cat(" in t()-'stop list'\n")
                } else {
                    cat("; t(t(m)) ==?== m :")
                    stopifnot(Qidentical(m, t(t(m))))
                    cat(" ok\n")
                }

                if(all(clNam != no.show.classes))
                    show(m)
                  ## improve: cat.(  captureOutput(show(m) ) )
                else cat.("	-- no show() yet \n")

                if(all(clNam != not.coerce0)) {## coerce to 'matrix'
                    m.m <- as(m, "matrix")
                    ## and test 'dim()' as well:
                    stopifnot(identical(dim(m.m), dim(m)))
                } else stopifnot(length(dim(m)) == 2)

### FIXME: organize differently :
### 1) produce 'mM'  and 'mm' for the other cases,
### 2) use identical code for all cases
                if(is(m, "dMatrix") && is(m, "compMatrix")) {
                    if(any(clNam == not.coerce1))
                        cat.("not coercable_1\n")
                    else {
                        cat.("as(dge*, <class>): ")
                        m2 <- as(mM, clNam)
                        cat("valid:", validObject(m2), "\n")
                        ## as.vector()
                        stopifnot(as.vector(m2) == as.vector(mM))
                    }
                    if(all(clNam != not.coerce2)) {
                        cat.("as(matrix, <class>): ")
                        m3 <- as(mm, clNam)
                        cat("valid:", validObject(m3), "\n")
                    }
                }
                else { ## not numeric composite: logical / triangular/diagonal ..
                    if(any(clNam == not.coerce1))
                        cat.("not coercable_1\n")
                    else {
                        ## FIXME: also add tests for these
                        if(is(m, "lMatrix")) {
                        }
                        else if(is(m, "triangularMatrix")) {
                            mm. <- mm
                            i0 <- if(m@uplo == "L")
                                upper.tri(mm.) else lower.tri(mm.)
                            mm.[i0] <- 0
                            cat.("as(matrix, <class>): ")
                            m3 <- as(mm., clNam)
                            cat("valid:", validObject(m3), "\n")
                        }
                        else { ## diagonal (only one)?
                            ## TODO
                        }
                    }
                }

                ## if(is(m, "denseMatrix")) {
                ##     ## .........
                ##     cat.("as dsparse* ")
                ##     msp <- as(m, "dsparseMatrix")
                ##     cat.("; valid coercion: ", validObject(msp), "\n")
                ## } else if(is(m, "sparseMatrix")) {

                ## } else cat.("-- not dense nor sparse -- should not happen(!?)\n")

                if(is(m, "dsparseMatrix")) {
                    if(any(clNam == not.coerce1))
                        cat.("not coercable_1\n")
                    else {
                        ## make sure we can coerce to dgT* -- needed, e.g. for "image"
                        cat.("as dgT* ")
                        mgT <- as(m, "dgTMatrix")
                        cat("; valid dgT* coercion: ", validObject(mgT), "\n")
                    }
                }
            }
        }
    } # end{dotestMat}

    for(scl in getClass(cl)@subclasses)
        dotestMat(scl, offset)
}


tstMatrixClass("Matrix")
if(FALSE)## or just a sub class
tstMatrixClass("triangularMatrix")


cat('Time elapsed: ', proc.time(),'\n') # for ``statistical reasons''
