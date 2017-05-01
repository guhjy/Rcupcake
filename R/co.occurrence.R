#' Co-occurrence Analysis \code{cupcakeResults}
#'
#' Given an object of type \code{cupcakeData}, a co-occurrence analysis is perform, 
#' for the subset of population under specific conditions of age, gender and gene status. 
#' It generates a \code{cupcakeResults} object.
#'
#' @param input  A \code{cupcakeData} object, obtained with the my.data function. 
#' @param pth Determines the path where the required file with phenotype data is located.
#' This file is generated applying the \code{phenotypeSummary} function. 
#' @param aggregate By default TRUE. Change it to FALSE if you want to 
#' analyze the comorbidity taking into all the values of each phenotype.
#' @param ageRange Determines what is the age range of interest for
#' performing the comorbidity analysis. By default it is set from 0 to 100 
#' years old. 
#' @param gender Determine what is the gender of interest for 
#' performing the comorbidity analysis. By default \code{ALL}. Change it to the 
#' gender of interest for your comorbidity analysis.
#' @param variation Determine what is the variation of interest for 
#' performing the comorbidity analysis. By default \code{c("", "")}. Change it to the 
#' value of interest for your comorbidity analysis. For example, \code{c("CHD8", "yes")}
#' @param nfactor By default 10. Change it into other number if you consider there is any
#' categorical variable with more than nfactor values. 
#' @param scoreCutOff The comorbidity score is a measure based on  the observed comorbidities
#' and the expected ones, based on the occurrence of each disease.
#' @param fdrCutOff A Fisher exact test for each pair of diseases is performed to assess 
#' the null hypothesis of independence between the two diseases. The Benjamini-Hochberg 
#' false discovery rate method (FDR) is applied to correct for multiple testing.
#' @param oddsRatioCutOff The odds ratio represents the increased chance that someone 
#' suffering disease X will have the comorbid disorder Y.
#' @param relativeRiskCutOff The relative risk refers to the fraction between the number of 
#' patients diagnosed with both diseases and random expectation based on disease 
#' prevalence.
#' @param phiCutOff The Pearsons correlation for binary variables (Phi) measures the 
#' robustness of the comorbidity association.
#' @param cores By default \code{1}. To run parallel computations on machines 
#' with multiple cores or CPUs, the cores argument can be changed. 
#' @param verbose By default \code{FALSE}. Change it to \code{TRUE} to get an
#' on-time log from the function.
#' @return An object of class \code{cupcakeResults}
#' @examples
#' load(system.file("extdata", "genophenoExData.RData", package="Rcupcake"))
#' cooccurrenceExample <- co.occurrence( 
#'               input         = genophenoExData,
#'               pth           = system.file("extdata", package="Rcupcake"),
#'               aggregate     = TRUE, 
#'               ageRange      = c(0,16),
#'               gender        = "male", 
#'               )
#' @export co.occurrence

co.occurrence <- function ( input, pth, ageRange=c(0,100), aggregate = TRUE, gender="ALL", variation=c("", ""), nfactor = 10, scoreCutOff, fdrCutOff, oddsRatioCutOff, relativeRiskCutOff, phiCutOff, cores = 1, verbose = FALSE){
    
    if( verbose == TRUE){
        message("Checking the input object")
    } 
    checkClass <- class(input)[1]
    
    if(checkClass != "cupcakeData"){
        message("Check the input object. Remember that this
                object must be obtained after applying the my.data
                function to your input file. The input object class must
                be:\"cupcakeData\"")
        stop()
    }
    
    data <- input@iresult
    
    
    if( verbose == TRUE){
        message( "Staring the comorbidity analysis" )
        message( "Loading the phenotype data file" )
    } 
    

 
    codes <- read.delim ( file.path(pth, "phenoSummary.txt"),
                          header=TRUE, 
                          sep="\t", 
                          colClasses="character" ) 
    
    if( aggregate == TRUE ){

        if( verbose == TRUE){
            message( "Checking the phenotype data file" )
        } 

        checkPheno <- as.data.frame( summary( as.factor( codes$yesno ) ) )
        good       <-  c("no", "yes")
        
        if( nrow( checkPheno) != 2 | 
            ! tolower( rownames( checkPheno)[1] ) %in% good |
            ! tolower( rownames( checkPheno)[2] ) %in% good){
            message("The yesno column in the phenoSummary file is not filled correctly. Please, revise it,\nand check that the only possible values for this column are: yes and no.")
            stop()
        }
        
        if( verbose == TRUE){
            message( "Aggregating the phenotypes values as yes/no" )
        } 
        
        
        for( i in 1:nrow(input@phenotypes)){
            
            pcolumn <- which(colnames(data) == as.character(input@phenotypes[i,1]))
            
            if( length( unique( data[,pcolumn])) > nfactor){
                message( colnames(data)[pcolumn], " phenotype is considered as a continuous variable. It will not be taken in to account for the comorbidity analysis")
            }else{
                codesSelection <- codes[ codes$phenotype == as.character(input@phenotypes[i,3]),c(2,6)]
                
                for( j in 1:nrow(codesSelection)){
                    data[ ,pcolumn][ data[ ,pcolumn] == codesSelection$PhenotypeValue[j]] <- codesSelection$yesno[j]
                }
                
                mt <- input@variations
                
                if( variation[1] %in% mt$variable ){
                    mt <- mt[ mt$variable == variation[1], ]        
                }else{
                    
                    
                    
                    message( "Your variation of interest is not in the variation list")
                    message( "The variations availabe for this analysis are: ")
                    for( i in 1:nrow(mt)){
                        message("-> ", mt$variable[i])
                    }
                    stop()
                }
                
                mt <- mt[ mt$variable == variation[1], ]  
                
                
                subset <- data[c("patient_id", "Gender", "Age", as.character(mt$check[1]), as.character(input@phenotypes[i,1]))]
                subcolumn <- which(colnames(subset) == as.character(input@phenotypes[i,1]))
                subset[,subcolumn] <- tolower(subset[,subcolumn])
                subset <- subset[ subset[as.character(input@phenotypes[i,1])] == "yes", ]
                subset[as.character(input@phenotypes[i,1])] <- input@phenotypes[i,3]
                colnames(subset)[subcolumn] <- "phenotype"
                
                if( i == 1){
                    qresult <- subset
                }else{ 
                    qresult <- rbind( qresult, subset )
                }
                
            }

            
            
        }
        
    }
    else if( aggregate == FALSE ){
        
        if( verbose == TRUE){
            message( "For each phenotypes, all the possible values will be used")
        } 
        
        
        
        for( i in 1:nrow(input@phenotypes)){
            
            pcolumn <- which(colnames(data) == as.character(input@phenotypes[i,1]))
            
            if( length( unique( data[,pcolumn])) > nfactor){
                if( verbose == TRUE){
                    message( colnames(data)[pcolumn], " phenotype is considered as a continuous variable. It will not be taken in to account for the comorbidity analysis")
                } 
            }else{
                data[ ,pcolumn] <- paste0( input@phenotypes[i,3], ": " ,data[ ,pcolumn] )
                
                mt <- input@variations
                
                if(variation[2] !=""){
                    if( variation[1] %in% mt$variable ){
                        mt <- mt[ mt$variable == variation[1], ]        
                    }else{
                        message( "Your variation of interest is not in the variation list")
                        message( "The variations availabe for this analysis are: ")
                        for( i in 1:nrow(mt)){
                            message("-> ", mt$variable[i])
                        }
                        stop()
                    }
                    
                    subset <- data[c("patient_id", "Gender", "Age", as.character(mt$check[1]), as.character(input@phenotypes[i,1]))]
                    
                }else{
                    if( nrow(mt) != 0){
                        if(verbose == TRUE ){
                            message("All the genotypes will be taken into account")
                            
                        }
                    }else {
                        if( verbose == TRUE ){
                            message("There is not genotype information")
                            
                        }
                    }
                    subset <- data[c("patient_id", "Gender", "Age", as.character(input@phenotypes[i,1]))]
                    
                }
              
                    
                subcolumn <- which(colnames(subset) == as.character(input@phenotypes[i,1]))
                colnames(subset)[subcolumn] <- "phenotype"
                
                if( i == 1){
                    qresult <- subset
                }else{ 
                    qresult <- rbind( qresult, subset )
                }
            }
            
            
        }

    }
  
    

    if ( !missing( ageRange ) ) {
        
        naCheck <- qresult[! is.na( qresult$Age), ]
        
        if( nrow(naCheck) != nrow( qresult)){
            message("There is not age information for all the patients.")
            noAge <- nrow( qresult ) - nrow( naCheck )
            message("The ", noAge, " patients without age data will be removed")
            qresult  <- qresult[! is.na( qresult$Age), ]
            
            
        }
        
        qresult$Age <- as.numeric(qresult$Age)
        qresult <- qresult[ qresult$Age >= ageRange[ 1 ] & qresult$Age <= ageRange[ 2 ], ]
    }
    
    if ( !missing( gender ) ) {
        if(gender!="ALL"){
            qresult <- qresult[ qresult$Gender == gender, ]
        }
    }
    
    totPatients <- length( unique( qresult$patient_id ) )
    
    
    if ( !missing( variation ) ) {
        if(variation[2] !="ALL"){
            ncolumn <- which(colnames(qresult) == as.character(mt$check[1]))
            qresult <- qresult[ qresult[,ncolumn] == variation[2], ]
        }
    }
    
    
    if( length( unique( qresult$phenotype)) < 2 ){
        message(paste0("Your patients subset only contains 1 phenotype: ", unique( qresult$phenotype)))
        message("Comorbidity analysis cannot be performed")
        stop()
    }
    
    else{
        ##active patients
        activePatients <- unique( qresult$patient_id )
        ##
        
        phenoPairs <- function ( pt ){
            pp <- qresult[ qresult$patient_id == pt, ]
            phenosC <- unique( pp$phenotype )
            phenos.f <- as.character( unique(pp$phenotype) )
            phenosC.c <- unique(do.call(c, apply(expand.grid(phenos.f, phenosC), 1, combn, m=2, simplify=FALSE)))
            phenos.f <- phenosC.c[sapply(phenosC.c, function(x) x[1] != x[2])]
        }
        
        
        if( verbose == TRUE){
            message( "Generating the cupcakeResults object" )
        } 

        finalCP  <- parallel::mclapply( activePatients, phenoPairs, mc.preschedule = TRUE, mc.cores = cores )
        finalCP <- finalCP[ sapply(finalCP, function(x) { length(x) != 0 }) ]
        
        f <- function( j ){ t( data.frame( j ) ) }
        unnest <-  do.call( f, list( j = finalCP  ) )
        unnest <- unnest[!duplicated(unnest), ]
        unnest <- lapply(1:nrow(unnest), function(ii) unnest[ii, ])
        
        
        
        resultado <- parallel::mclapply( unnest, tableData, mc.preschedule = TRUE, mc.cores = cores, data = qresult, lenActPa=totPatients)
        resultad2 <- do.call("rbind", resultado )
        resultad2 <- as.data.frame( resultad2, stringsAsFactors=FALSE )
        
        
        
        colnames(resultad2) <- c( "phenotypeA", "phenotypeB", "patientsPhenoA", "patientsPhenoB", "patientsPhenoAB", "patientsPhenoAnotB", "patientsPhenoABnotA", "patientsNotAnotBpheno", "fisher", "oddsRatio", "relativeRisk", "phi" )
        
        
        resultad2$expect <-  as.numeric( resultad2$patientsPhenoA ) * as.numeric( resultad2$patientsPhenoB ) / totPatients
        resultad2$score  <- log2( ( as.numeric( resultad2$patientsPhenoAB ) + 1 ) / ( resultad2$expect + 1) )
        resultad2        <- resultad2[ with( resultad2, order( resultad2$fisher ) ), ]
        resultad2$fdr    <- p.adjust( as.numeric( resultad2$fisher ), method = "fdr", n = nrow( resultad2 ) )
        resultad2$PercentagePhenoAB <- round(as.numeric( resultad2$patientsPhenoAB )/ length(activePatients)*100, 2)
        
        uniquepairs <- resultad2
        uniquepairs$pair   <- NA
         for(cont in 1:nrow(uniquepairs)){
             pairDis <- sort(c(uniquepairs$phenotypeA[cont], uniquepairs$phenotypeB[cont]))
             uniquepairs$pair[cont] <- paste(pairDis[1], pairDis[2], sep="*")
         }
         
        uniquepairs <- uniquepairs[!duplicated(uniquepairs$pair),]
        

        if ( !missing( scoreCutOff ) ) {
            resultad2 <- resultad2[ resultad2$score > scoreCutOff, ]
        }
        if ( !missing( fdrCutOff ) ) {
            resultad2 <- resultad2[ resultad2$fdr < fdrCutOff, ]
        }
        if ( !missing( oddsRatioCutOff ) ) {
            resultad2 <- resultad2[ resultad2$fdr > oddsRatioCutOff, ]
        }
        if ( !missing( relativeRiskCutOff ) ) {
            resultad2 <- resultad2[ resultad2$fdr > relativeRiskCutOff, ]
        }
        if ( !missing( phiCutOff ) ) {
            resultad2 <- resultad2[ resultad2$fdr < phiCutOff, ]        
        }
        
        resultad2$fisher <- round(as.numeric(resultad2$fisher), 3)
        resultad2$oddsRatio <- round(as.numeric(resultad2$oddsRatio), 3)
        resultad2$relativeRisk <- round(as.numeric(resultad2$relativeRisk), 3)
        resultad2$phi <- round(as.numeric(resultad2$phi), 3)
        resultad2$expect <- round(as.numeric(resultad2$expect), 3)
        resultad2$score <- round(as.numeric(resultad2$score), 3)
        resultad2$fdr <- round(as.numeric(resultad2$fdr), 3)
        
        if( nrow( resultad2 ) == 0 ){
            warning("None of the disease pairs has pass the filters") 
        }
        
        if( variation[1] == "" & nrow(mt) != 0){
            variation <- c("ALL")
        }else if( variation[1] == "" & nrow(mt) == 0){
            variation <- c("NONE")
        }
        
        co.occurrenceResults <- new( "cupcakeResults", 
                               ageMin     = ageRange[ 1 ], 
                               ageMax     = ageRange[ 2 ], 
                               gender     = gender, 
                               variation  = variation, 
                               patients   = totPatients,
                               tpatients  = length(activePatients),
                               prevalence = (length(activePatients)/totPatients)*100,
                               ORrange    = paste0( "[", round(min(as.numeric(resultad2$oddsRatio)), digits = 3), " , " , round(max(as.numeric(resultad2$oddsRatio)), digits = 3), "]"  ),
                               RRrange    = paste0( "[", round(min(as.numeric(resultad2$relativeRisk)), digits = 3), " , ",  round(max(as.numeric(resultad2$relativeRisk)), digits = 3), "]"  ),
                               PHIrange   = paste0( "[", round(min(as.numeric(resultad2$phi)), digits = 3), " , ",  round(max(as.numeric(resultad2$phi)), digits = 3) , "]" ),
                               dispairs   = nrow( uniquepairs ),
                               result     = resultad2 
        )
        return( co.occurrenceResults )
    
            
    }
    
}

tableData <- function ( pairCode, data, lenActPa ) {
    
    code1 <- pairCode[[ 1 ]]
    code2 <- pairCode[[ 2 ]]
    
    dis1 <- data[ data$phenotype == code1, ]
    dis2 <- data[ data$phenotype == code2, ]
    
    dis12 <- dis2[ dis2$patient_id %in% dis1$patient_id, ]
    
    disAcode <- code1
    disBcode <- code2
    disA     <- length( unique ( dis1$patient_id ) )
    disB     <- length( unique ( dis2$patient_id ) )
    AB       <- length( unique ( dis12$patient_id ) )
    AnotB    <- disA - AB
    BnotA    <- disB - AB
    notAB    <- lenActPa - AB - AnotB - BnotA
    
    mm <- matrix( c( AB, AnotB, BnotA, notAB), nrow = 2 )
    
    tryCatch( {ff <- fisher.test( mm )}, error=function(msg) {
        message(msg)
        message("code1:", code1, " - code2:", code2)
    })
    
    relativeRisk <- as.numeric(AB*lenActPa)/as.numeric(disA* disB)
    den <- as.numeric(disA*disB)*as.numeric(lenActPa-disA)*as.numeric(lenActPa-disB)
    num <- as.numeric(AB*lenActPa)-as.numeric(disA*disB)
    phi <- ((num)/sqrt(den))
    
    c( disAcode, disBcode, disA, disB, AB, AnotB, BnotA, notAB, ff$p.value, ff$estimate, relativeRisk, phi )    
    
}








