#' Get children paths
#'
#' Given a url, a key and a path it returns all the children paths under the given one.
#'
#' @param url  The url.
#' @param fieldname  The path in which the urser is interested.
#' @param verbose By default \code{FALSE}. Change it to \code{TRUE} to get an
#' on-time log from the function.
#' @return A vector with all the fields that are under the path that has been given as input. 
#' @examples
#' 
#' nhanesPcbs <- get.children( 
#'                  fieldname   = "/nhanes/Demo/laboratory/laboratory/pcbs/", 
#'                  url         = "https://nhanes.hms.harvard.edu/"
#'               )
#' @export get.children


get.children <- function( fieldname, url, verbose = FALSE) {
    
    children <- c( )
    
    IRCT_REST_BASE_URL <- url
    IRCT_CL_SERVICE_URL <- paste(IRCT_REST_BASE_URL,"rest/v1/",sep="")
    IRCT_RESOURCE_BASE_URL <- paste(IRCT_CL_SERVICE_URL,"resourceService/",sep="")
    IRCT_PATH_RESOURCE_URL <- paste(IRCT_RESOURCE_BASE_URL,"path",sep="")
    
    nexturl <- paste( IRCT_PATH_RESOURCE_URL, fieldname, sep = "" )
    newchildren <-  httr::content(httr::GET(nexturl))
    
    if (length(newchildren) > 0) {
        for (i in 1:length(newchildren)) {
            res = tryCatch({
                newchild <- newchildren[[i]]$pui
                children <- c(children, newchild)
                getchildren(children, 
                            gsub("\\#","%23", gsub("\\?", "%3F", gsub("[)]","%29", gsub("[(]","%28", URLencode(newchild)))))
                )
            }, error = function(errorCondition) {
                if( verbose == TRUE){
                    message("ERROR: There is something wrong with the children")
                    message(newchildren)
                }
            })
        }
    } else {
        if( verbose == TRUE ){
            message("Ending loop. No more children.")
        }

    }
    
    return( children )
}
