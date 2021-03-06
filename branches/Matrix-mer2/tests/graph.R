if(require(graph)) {

    library(Matrix)
    if(FALSE)## for ease of developer:
        library(Matrix, lib="/u/maechler/R/Pkgs/Matrix.Rcheck")

    example("graphNEL-class", echo = FALSE)
    nodes(gR)

    ## 1) undirected
    sm.g <- as(gR, "sparseMatrix")
    str(sm.g)## 'dsT' - fine; even has Dimnames!
    validObject(sm.g)
    sm.g # should show the Dimnames - at least row ones

    ## 2) directed
    gU <- gR; edgemode(gU) <- "directed"
    sgU <- as(gU, "sparseMatrix")
    str(sgU)## 'dgT' with dimnames
    validObject(sgU)
    sgU # should now show the Dimnames!

    ### Reverse :  sparseMatrix -> graph
    if(FALSE) { ## not yet (FIXME!)
        gmg  <- as(sm.g, "graph")
        gmg2 <- as(sm.g, "graphNEL")
        gmgU <- as(sgU, "graph")
        gmgU <- as(sgU, "graphNEL")
    }

}
