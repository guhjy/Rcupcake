#' Transform a data.frame into a \code{cupcakeData} object
#'
#' Given a tabulated file that contains the data in the 
#' correct format and generates a \code{cupcakeData} object.
#'
#' @param input Determines the file with the complete path where the required 
#' input file is located. This input file must contain the "patient_id", two demographic variables, "Gender" and "Age",
#' and a list of phenotypes and variations
#' @param age Vector that contains the age variable
#' @param gender Vector that contains the gender variable
#' @param phenotypes Vector that contains the phenotype variables
#' @param variants Vector that contains the variants names 
#' @param verbose By default \code{FALSE}. Change it to \code{TRUE} to get an
#' on-time log from the function.
#' @param warnings By default \code{TRUE}. Change it to \code{FALSE} to don't see
#' the warnings.
#' @return An object of class \code{cupcakeData}
#' @examples
#' queryExample <- dataframe2cupcake( input      = paste0(system.file("extdata", package="Rcupcake"), 
#'                                                 "/queryOutput.txt"),
#'                                    age        = "Age",
#'                                    gender     = "Gender",
#'                                    phenotypes = "Diabetes|Arthritis|LiverCancer|AnyCancer",
#'                                    variants   = "PCB153",
#'                                    verbose    = TRUE)
#' queryExample
#' @export dataframe2cupcake


dataframe2cupcake <- function( input, phenotypes, variants, age, gender, verbose = FALSE, warnings= TRUE) {
   
    if( verbose == TRUE){
        message( "Loading the input datasets" )
    } 
    
    patients <- read.delim( input, 
                            header = TRUE, 
                            sep = "\t", 
                            colClasses = "character" )
    
    colnames(patients)[ which(colnames(patients) == grep(age, colnames(patients) , value = TRUE ))]    <- "Age"
    colnames(patients)[ which(colnames(patients) == grep(gender, colnames(patients) , value = TRUE ))] <- "Gender"
    
    variantList <- unlist(strsplit(variants, "[|]"))
        for( i in 1:length(variantList)){
        variantList[i] <- gsub(" ", ".", variantList[i])
        colnames(patients)[ which(colnames(patients) == grep(variantList[i], colnames(patients) , value = TRUE ))] <- paste0("V.", variantList[i])
    }
    
    phenotypeList <- unlist(strsplit(phenotypes, "[|]"))
    
    
    for( i in 1:length(phenotypeList)){
        phenotypeList[i] <- gsub(" ", ".", phenotypeList[i])
        colnames(patients)[ which(colnames(patients) == grep(phenotypeList[i], colnames(patients) , value = TRUE ))] <- paste0("P.", phenotypeList[i])
        
    }
    
    
    if( verbose == TRUE){
        message("Checking the inputData file structure")
    }
    
        colnamesPatients   <- c("patient_id","Gender", "Age")   
        check <- colnamesPatients[colnamesPatients %in% colnames(patients)]
        if(length(check) != length(colnamesPatients)){
            message("Check the inputData file structure. Remember that this
                    file must contain at least three columns with the column 
                    names as follows:\n -> patient_id \n -> Gender \n -> Age")
            stop()
        }

        
        if( verbose == TRUE){
            message("Removing duplicated data")
        }
    
        patientComplete <- patients[! duplicated( patients), ]

    
        if( verbose == TRUE) {
        message( "There are ", length( unique ( patientComplete$patient_id)), " patients in your input data with complete information for all your variables, from the initial ", length( unique ( patients$patient_id ) ), " patients in your list.")
        message("Checking the number of variations in the inputData file")
        }
    
    
        colnamesInput   <- colnames(patientComplete) 
        check <- as.data.frame(as.character(colnamesInput))
        check <- check[! check[,1] %in% colnamesPatients,]
        check <- as.data.frame(check)
        check$firstL <- substr( check[,1], 1, 1)
        check$variable <- substr( check[,1], 3, nchar(as.character(check[,1])))
        check <- check[! duplicated(check),]
        
        variations <- check[ check$firstL == "V", ]
        phenotypes <- check[ check$firstL == "P", ]
        

        if( verbose == TRUE) {
            message("Generating the result object")
        }
        
        #with the data we have, we create a cupcakeData object
   
        result <- new( "cupcakeData", 
                       nVariations  = nrow(variations),
                       nPhenotype   = nrow(phenotypes),
                       nPatient     = length( unique ( patientComplete$patient_id ) ), 
                       iresult      = patientComplete, 
                       variations   = variations, 
                       phenotypes   = phenotypes
        )
        return( result )

}



