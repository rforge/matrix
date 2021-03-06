####--------- Test interfaces to other non-standard Packages ---------------

library(Matrix)

pkgRversion <- function(pkgname)
    substring(packageDescription(pkgname)[["Built"]], 3,5)

MatrixRversion <- pkgRversion("Matrix")

###-- 1)  'graph' (from Bioconductor) ---------------------------
###-- ==  =======                     ---------------------------
if(isTRUE(try(require(graph)))) { # may be there and fail (with R-devel)

    if(packageDescription("graph")$Version <= "1.10.2") {
        ## graph 1.10.x for x <= 2 had too many problems  as(<graph>, "matrix")
        cat("Version of 'graph' is too old --- no tests done here!\n")

    } else if(pkgRversion("graph") != MatrixRversion) {

        cat(sprintf("The R version (%s) of 'graph' installation differs from the Matrix one (%s)\n",
                    pkgRversion("graph"), MatrixRversion))

    } else { ## do things

    ## 1) undirected

    V <- LETTERS[1:4]
    edL <- vector("list", length=4)
    names(edL) <- V
    ## 1a) unweighted
    for(i in 1:4)
        edL[[i]] <- list(edges = 5-i)
    gR <- new("graphNEL", nodes=V, edgeL=edL)
    str(edges(gR))
    sm.g <- as(gR, "sparseMatrix")
    str(sm.g) ## dgC: TODO: want 'ds.' (symmetric)
    validObject(sm.g)
    sm.g ## TODO: should also show the colnames

    ## 1b) weighted
    set.seed(123)
    for(i in 1:4)
        edL[[i]] <- list(edges = 5-i, weights=runif(1))
    gRw <- new("graphNEL", nodes=V, edgeL=edL)
    str(edgeWeights(gRw))
    sm.gw <- as(gRw, "sparseMatrix")
    str(sm.gw) ## *numeric* dgCMatrix
    validObject(sm.gw)
    sm.gw ## U[0,1] numbers in anti-diagonal

    ## 2) directed
    gU <- gR; edgemode(gU) <- "directed"
    sgU <- as(gU, "sparseMatrix")
    str(sgU) ## 'dgC'
    validObject(sgU)
    sgU

    ## Reverse :  sparseMatrix -> graph
    sm.g[1,2] <- 1
    gmg  <-  as(sm.g, "graph")
    validObject(gmg2 <-  as(sm.g, "graphNEL"))
    gmgw <-  as(sm.gw, "graph")
    validObject(gmgw2 <- as(sm.gw, "graphNEL"))
    gmgU <-  as(sgU, "graph")
    validObject(gmgU2 <- as(sgU, "graphNEL"))
    stopifnot(identical(gmg, gmg2),
              identical(gmgw, gmgw2),
              identical(gmgU, gmgU2))

    detach("package:graph")
}

} ## end{graph}

###-- 2)  'SparseM' ---------------------------------------------
###-- ==  ========  ---------------------------------------------

if(require(SparseM)) {

    if(pkgRversion("SparseM") != MatrixRversion) {

        cat(sprintf("The R version (%s) of 'SparseM' installation differs from the Matrix one (%s)\n",
                    pkgRversion("SparseM"), MatrixRversion))

    } else { ## do things

set.seed(1)
a <- round(rnorm(5*4), 2)
a[abs(a) < 0.7] <- 0
A <- matrix(a,5,4)
print(M <- Matrix(A))
stopifnot(
          validObject(A.csr <- as.matrix.csr(A)),
          validObject(At.csr <- as.matrix.csr(t(A))),
          identical(At.csr, t(A.csr)),
          identical(A, as.matrix(A.csr)),
          identical(M, as(A.csr, "dgCMatrix")),
          identical(t(M), as(At.csr, "dgCMatrix"))
          )

## TODO: More tests; in particular for triplets !

if(FALSE) # detaching the package gives an error (.GenericTable ...)
detach("package:SparseM")

    }

}## end{SparseM}
