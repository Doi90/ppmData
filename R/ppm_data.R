#' @name ppmData
#' @description ppmData is a package for setting up quadrature to implement
#' spatial Poisson Point process models and extensions. The approach uses quasi-
#' random sampling (Grafston & Tille, 2013, Foster et al., 2018) to generate a
#' quadrature scheme for numerical approximation of a Poisson point process
#' model (Berman & Turner 1992; Warton & Shepard 2010). Quasi-random sampling
#' quadrature are form of spatially-balanced survey design or point
#' stratification that aims to reduce the frequency of placing samples close to
#' each other (relative to pseudo-random or grid designs). A quasi-random
#' quadrature design improves efficiency of background point sampling (and
#' subsequent modelling) by reducing the amount of spatial auto-correlation
#' between data implying that each sample is providing as much unique
#' information as possible (Grafston & Tille, 2013, Foster et al., 2018) and
#' thus reducing low errors for geostatistical prediction (Diggle & Ribeiro,
#' 2007). Because the quasi-random design is not on a regular grid we use
#' Dirichlet tessellation to generate polygons for each point in the quadrature
#' scheme. Areal weights are then derived from these polygons.
#'
#' @author Skipton Woolley <skip.woolley@csiro.au> & Scott Foster <scott.foster@data61.csiro.au>
#'
#' @references Diggle, P. J., P. J. Ribeiro, Model-based Geostatistics. Springer Series in Statistics. Springer, 2007.
#'
#' Foster, S.D., Monk, J., Lawrence, E., Hayes, K.R., Hosack, G.R. and Przeslawski, R., 2018. Statistical considerations
#' for monitoring and sampling. Field manuals for marine sampling to monitor Australian waters, pp.23-41.
#'
#' Grafstrom, Anton, and Yves Tille. Doubly balanced spatial sampling with spreading and restitution of auxiliary totals.
#' Environmetrics 24.2 (2013): 120-131.
#'
#' Warton, D. I., and L. C. Shepherd. Poisson point process models solve the pseudo-absence problem for presence-only data #'in ecology. The Annals of Applied Statistics 4.3 (2010): 1383-1402.
#'
#' @useDynLib "ppmData", .registration = TRUE
#' @importFrom Rcpp sourceCpp

#' @title Develop a quadrature scheme using quasi-random sampling for spatial
#' point processes.
# #' @description This package is a way to efficiently generate a quasi-random set
# #' of background points for presence-only modelling of single or multiple
# #' responses. The package was set up to model multiple species presence-only
# #' data sets, but could be used for an spatial point process modelling.
# #' Quasi-random points are a nice alternative to pseudo-random samples, this is
# #' because we can generate a quasi-random sample across and areal region
# #' (X and Y coordinates). This in turn should reduce autocorrelation in
# #' quadrature scheme. The weight of each quadrature point is calculated using
# #' Dirichlet (Voronoi) Tessellation written in c++. We calculated the duel-graph
# #' of a Delaunay triangulation. The Delaunay triangulation is constructed based
# #' on a radial sweep algorithm.
#' @param presences a three column matrix or data.frame object giving the
#' coordinates of each species' presence in (should be a matrix of nsites * 3)
#' with the three columns being c("X","Y","SpeciesID"), where X is longitude,
#' Y is latitude and SpeciesID is a factor which associated each occurrence to a
#' species.
#' @param window SpatRaster a raster object giving the region where to generate
#' the quadrature scheme. Windows with NA cells are ignored and masked out of returned data.
#' If NULL, a rectangle bounding the extent of \code{presences} will be used as
#' the default window.
#' @param covariates SpatRaster A terra raster object containing covariates for modelling
#' the point process. These layers should match the resolution and extent of the window
#' provided. If NULL, only the coordinates of the presences and quadrature
#' points are returned for the ppmData object.
#' @param npoints Integer The number of quadrature points to generate. If NULL, the
#' number of quadrature points is calculated based on linear scaling. In
#' reality, the number of quadrature points needed to approximate the
#' log-likelihood function will depend on the data and likelihood function
#' being approximated. Typically, the more quadrature the better the estimate,
#' but there is a trade off between computational efficiency and accuracy.
#' See Warton & Shepard (2010) or Renner et al., 2015 for useful discussions
#' on the location and number of quadrature points required to converge a
#' ppm likelihood.
#' @param coord Character These are the users name of site coordinates. The
#' default is c('X','Y').
#' This should match the name of the coordinates in the presences data set.
#' @param mark.id Character This is the column name of the mark ID. The default
#' is "SpeciesID". But this should be changed to match the user's data. If this
#' column contains multiple "species" then a marked quadrature scheme will be
#' created.
#' @param quad.method Character The quadrature generation method. Default is
#' "quasi.random" for quasi-random, "pseudo.random" for pseudo-random (regular
#' random) and "grid" for a regular grid at a set resolution (with respect to
#' the original window resolution).
#' @param interpolation Character The interpolation method to use when extracting
#' covariate data at a presence or quadrature location. Default is "bilinear",
#' can also use "simple", this is based
#' on the terra package  \code{\link[terra]{extract}}.
#' @param unit Character The type of area to return. The default is "geo" and
#' returns the area based on the euclidean distance between geographic
#' coordinates. This will default to the values of the raster and presence
#' coordinate system. Alternatively, meters squared "m", kilometers squared "km"
#' , or hectares "ha" can be used.
#' @param na.rm Boolean Remove NA data from covariates. Only works for single
#' species models.
#' @param control list A list of control parameters for using ppmData. See
#' details for uses of control parameters.
#'
#' @details The approach uses quasi-random sampling to generate a quadrature
#' scheme based (e.g Berman & Turner 1992; Warton & Shepard 2010;
#' Foster et al, 2017). The weights each quasi-random point in the quadrature
#' scheme is calculated using a Dirichlet tessellation (Turner 2020). To improve
#' computational efficiency we have rewritten the Delaunay triangulation and
#' Dirichlet tessellation in c++ using a sweep algorithm. The control has a
#' bunch of parameters you can use to tweek the ppmData object.
#' \itemize{
#'  \item{quasirandom.samples}{ integer This sets the total number of samples
#'  to consider in the BAS step (rejection sampling). The default is set to NULL
#'  and the function internally generates 10 times the total number of
#'  quadrature points needed. This means if 10000 quadrature points are required
#'  for ppmData, then a halton sequence of 100000 quasi-random numbers are drawn
#'  and then thinned according to the inclusion probabilities. The more
#'  quasirandom.samples selected the slower the quasi-random quadrature scheme
#'  will be to generate.}
#'  \item{buffer.NA}{ boolean If extract from \code{\link[terra]{extract}}
#'  returns NA for point extract, do you want us to attempt to user buffer to
#'  calculate cells which are NA.}
#'  \item{buffer.size}{ numeric If you call 'buffer.NA' what is the range of the
#'  buffer in meters.}
#'  \item{mc.cores}{ integer The number of cores to use in the processing.
#'  default is parallel::detectCores()-1}
#'  \item{quiet}{ boolean If TRUE, do not print messages. Default is FALSE.}
#' }
#' @importFrom graphics legend par points
#' @importFrom methods as
#' @importFrom stats complete.cases median runif
#' @importFrom utils txtProgressBar
#' @importFrom terra extract ncell rast ext extract res
#' @export
#' @examples
#' \dontrun{
#' library(ppmData)
#' library(terra)
#' path <- system.file("extdata", package = "ppmData")
#' lst <- list.files(path=path,pattern='*.tif',full.names = TRUE)
#' preds <- rast(lst)
#' window <- preds[[1]]
#' presences <- subset(snails,SpeciesID %in% "Tasmaphena sinclairi")
#' quad <- ppmData(npoints = 1000, presences=presences, window = window, covariates = preds)
#' }

ppmData <- function(presences,
                    window = NULL,
                    covariates = NULL,
                    npoints = NULL,
                    coord = c('X','Y'),
                    mark.id = "SpeciesID",
                    quad.method = c("quasi.random","pseudo.random","grid"),
                    interpolation = c("simple","bilinear"),
                    unit = c("geo","m","km","ha"),
                    na.rm = FALSE,
                    control = list()){

  # default methods
  quad.method <- match.arg(quad.method)
  interp.method <- match.arg(interpolation)
  unit <- match.arg(unit)
  control <- checkControl(control, quad.method, unit)

  ## Make sure the column ids are characters and check for missing/wrong named coord/mark.id vars.
  if(!is.character(coord)) coord <- as.character(coord)
  if(all(!coord%in%colnames(presences))) stop(paste0('coord: "',coord[1],'" & "',coord[2],'" do not match any of the colnames in the presences data.frame'))
  if(!is.character(mark.id)) mark.id <- as.character(mark.id)
  if(all(!mark.id%in%colnames(presences))) stop(paste0('mark.id: "',mark.id,'" does not match any of the colnames in the presences data.frame'))

  # This should check the presences and make it returns the data in the correct format for the remaining function.
  pressies <- checkPresences(known.sites = presences,
                             window = window,
                             coord = coord,
                             mark.id = mark.id)

  # Check for duplicate presences - will remove duplicated points per species.
  pressies <- checkDuplicates(presences = pressies,
                              coord = coord,
                              mark.id = mark.id,
                              quiet = control$quiet)

  ## If npoints in NULL setup a default amount. This is taken from spatstat
  npoints <- checkNumPoints(npoints = npoints,
                           presences = pressies,
                           mark.id = mark.id)

  ## If not window is provided provide a dummy window
  if(is.null(window)) default_window <- TRUE
  else default_window <- FALSE
  window <- checkWindow(presences = pressies,
                        window = window,
                        coord = coord,
                        quiet = control$quiet)

  ## grab the crs of the spatial object/window - need this for dirichlet clipping
  crs <- getCRS(window)

  ## Hold onto the species names from the mark.id column
  sppNames <- getSppNames(presences = pressies,
                          mark.id = mark.id)

  ## Create some quadrature points
  bckpts <- quadMethod(quad.method = quad.method,
                       npoints = npoints,
                       window = window,
                       coord =  coord,
                       control = control)

  ## Sometimes the points are very close together, so let's jitter if needed.
  reswindow <- terra::res(window)[1]
  tmpPts <- jitterIfNeeded(pressiesJ = pressies,
                           bckpts=bckpts,
                           window=window,
                           coord=coord,
                           mark.id = mark.id,
                           aBit=reswindow/2)

  pressies <- tmpPts$pressies
  quadrature <- tmpPts$bckpts

  # Check to see if the presences are for a single species or multiple.
  ismulti <- checkMultispecies(presences = pressies,
                               mark.id = mark.id)

  if(ismulti){
    if(!control$quiet)message("Developing a quadrature scheme for multiple species (marked) dataset.")
      wts <- getMultispeciesWeights(quad.method = quad.method,
                                    presences = pressies,
                                    quadrature = quadrature,
                                    window = window,
                                    coord = coord,
                                    mark.id = mark.id,
                                    mc.cores = control$mc.cores,
                                    sppNames = sppNames,
                                    unit = unit,
                                    crs = crs,
                                    control = control)

      sitecovariates <- getCovariates(pbxy = wts,
                                      covariates = covariates,
                                      interpolation = interpolation,
                                      coord = coord,
                                      buffer.NA = control$buffer.NA,
                                      buffer.size = control$buffer.size,
                                      quiet = control$quiet)

    } else {
      if(!control$quiet)message("Developing a quadrature scheme for a single species dataset.")
      wts <- getSingleSpeciesWeights(quad.method= quad.method,
                                     presences = pressies,
                                     quadrature = quadrature,
                                     window = window,
                                     coord = coord,
                                     mark.id = mark.id,
                                     unit = unit,
                                     crs = crs,
                                     control = control)
      # extract the covariate data
      sitecovariates <- getCovariates(pbxy = wts,
                                      covariates = covariates,
                                      interpolation = interpolation,
                                      coord = coord,
                                      buffer.NA = control$buffer.NA,
                                      buffer.size = control$buffer.size,
                                      quiet = control$quiet)
    }

  # Assemble data
  dat <- assembleQuadData(presences = pressies,
                          quadrature = quadrature,
                          sitecovariates = sitecovariates,
                          wts = wts,
                          coord = coord,
                          mark.id = mark.id,
                          sppNames = sppNames)

  if(!is.null(covariates)){
    covarNames <- names(covariates)
  } else {
    covarNames <- NULL
  }
  coordNames <- coord
  res <- list()
  if(ismulti){
     res$ppmData <- transposePPMdata(dat, sppNames, coordNames, covarNames)
     res$marked <- TRUE
  } else {
    res$ppmData <- cleanWeightsPPMdata(dat)
    if(na.rm)
      res$ppmData <- cleanCovariatesPPMdata(res$ppmData)
    res$marked <- FALSE
  }

  res$presences.original <- presences
  res$presences.cleaned <- pressies
  res$window <- window
  res$covariates <- covariates
  res$params <- list(quad.method = quad.method,
                     coord = coord,
                     mark.id = mark.id,
                     interpolation = interpolation,
                     dw = default_window,
                     control = control)

  class(res) <- c("ppmData")

  if(!control$quiet)print(res)
  return(res)
}

jitterIfNeeded <- function( pressiesJ, bckpts, window, coord, mark.id, aBit=1e-4){
  #the pressie bit first
  #are there any duplicates within a species?  If so, then jitter the duplicates
  for( jj in as.character( unique( pressiesJ[,mark.id]))){ #I think that we have made the assumption that this is called SpeciesID...?
    sppJ <- which(  pressiesJ[,mark.id]==jj)
    dupes <- which( duplicated( pressiesJ[sppJ,coord]))  #shouldn't need to round this as deldir reportedly uses duplicated

    if( length( dupes)>0){
      pressiesJ[dupes,coord[1]] <- jitter( pressiesJ[sppJ[dupes],coord[1]], amount=aBit)
      pressiesJ[dupes,coord[2]] <- jitter( pressiesJ[sppJ[dupes],coord[2]], amount=aBit)
      #fixing up those points that have been jittered outside of the window
      kount <- 1
      tmp <- terra::extract(window, pressiesJ[,coord])
      outOfWindow <- which( is.na( tmp))
      while( kount < 10 & length( outOfWindow)>0){
      	pressiesJ[outOfWindow,coord[1]] <- jitter( pressiesJ[sppJ[outOfWindow],coord[1]], amount=aBit)
      	pressiesJ[outOfWindow,coord[2]] <- jitter( pressiesJ[sppJ[outOfWindow],coord[2]], amount=aBit)
      	tmp <- terra::extract( window, pressiesJ[,coord])
      	outOfWindow <- which( is.na( tmp))
      	kount <- kount + 1
      }
    }
  }

  #Are there any points that duplicate a presence point?  If so, jitter.
  npres <- nrow( pressiesJ)
  dupes <- which( duplicated( rbind( pressiesJ[,coord], bckpts)))
  if( length( dupes)>0)
    dupes <- dupes[dupes>npres]
  if( length( dupes)>0){
    dupes <- dupes - npres
    bckpts[dupes,coord[1]] <- jitter( bckpts[dupes,coord[1]], amount=aBit)
    bckpts[dupes,coord[2]] <- jitter( bckpts[dupes,coord[2]], amount=aBit)
    #fixing up those points that have been jittered outside of the window
    kount <- 1
    tmp <- terra::extract( window, bckpts[,coord])
    outOfWindow <- which( is.na( tmp))
    while( kount < 10 & length( outOfWindow)>0){
      bckpts[outOfWindow,coord[1]] <- jitter( bckpts[,coord[1]], amount=aBit)
      bckpts[outOfWindow,coord[2]] <- jitter( bckpts[,coord[2]], amount=aBit)
      tmp <- terra::extract( window, bckpts[,coord])
      outOfWindow <- which( is.na( tmp))
      kount <- kount + 1
    }
  }

  return( list( pressies=data.frame(pressiesJ), bckpts=data.frame(bckpts)))
}

assembleQuadData <- function(presences, quadrature, sitecovariates, wts, coord, mark.id, sppNames){

  ismulti <- checkMultispecies(presences, mark.id)

  if(!ismulti) type <- "long"
  else type <- "wide"

  final_dat <- switch(type,
                      long=longData(wts = wts,
                                   sitecovariates = sitecovariates,
                                   coord = coord),
                      wide=wideData(presence = presences,
                                   quadrature = quadrature,
                                   sitecovariates = sitecovariates, wts = wts,
                                   coord = coord,
                                   mark.id = mark.id,
                                   sppNames = sppNames))

  return(final_dat)

}


longData <- function(wts, sitecovariates=NULL, coord){

  if(!is.null(sitecovariates)) dat2 <- data.frame(wts[,coord],sitecovariates[,-1:-3],presence=wts$pres, weights=wts$wts)
  else dat2 <- data.frame(wts[,coord],presence=wts$pres,weights=wts$wts)

  return(dat2)
}

wideData <- function(presence, quadrature, sitecovariates, wts, coord, mark.id, sppNames){

  # Assemble a data.frame with all the bits we want.
  pamat <- fastWideMatrix(wts, mark.id)
  presences_pamat <- pamat[-which(pamat[,"quad"]==0),-which(colnames(pamat)%in%c('quad'))]
  quad_pamat <- pamat[which(pamat[,"quad"]==0),-which(colnames(pamat)%in%c('quad'))]
  quad_pamat[is.na(quad_pamat)]<-0
  response_ppmmat <- as.data.frame(rbind(presences_pamat,quad_pamat))
  response_ppmmat$Const <- 1
  response_ppmmat$OrigOrder <- as.integer(rownames(response_ppmmat))


  sitecovariates$OrigOrder <- wts$OrigOrder
  df <- merge(response_ppmmat,sitecovariates[!duplicated(sitecovariates$OrigOrder),], by = "OrigOrder", sort=TRUE)
  wtsmat <- fastWideMatrixWeights(wts, sppNames)

    if(!all.equal(colnames(wtsmat),colnames(quad_pamat))) message('names could be getting mixed up with factors in R')
  return(list(mm=df,wtsmat=wtsmat))
}


quadMethod <- function(quad.method, npoints, window, coord, control){
  quad <- switch(quad.method,
                  quasi.random = quasiRandomQuad(npoints,
                                          window,
                                          coord,
                                          control),
                  pseudo.random = pseudoRandomQuad(npoints,
                                            window,
                                            coord,
                                            control),
                  grid = gridQuad(npoints,
                                  window,
                                  coord,
                                  control))
  return(quad)
}

checkNumPoints <- function(npoints, presences, mark.id){

  if(is.null(npoints)){

    ## Taken from spatstat.
    ## linear scaling of quad points compared to max n presences.
    npmx <- max(table(presences[,mark.id]))
    nquad <- rep(pmax(32, 10 * ceiling(2 * sqrt(npmx)/10)),2)
    npoints <- prod(nquad)
  }
  return(npoints)
}

checkControl <- function(control, quad.method, unit){

  if (!("quasirandom.samples" %in% names(control)))
    control$quasirandom.samples <- NULL
  if (!("buffer.NA" %in% names(control)))
    control$buffer.NA <- FALSE
  if (!("buffer.size" %in% names(control)))
    control$buffer.size <- NULL
  if (!("quiet" %in% names(control)))
    control$quiet <- FALSE
  if (!("mc.cores" %in% names(control)))
    control$mc.cores <- 1
  if (!("mc.cores" %in% names(control)))
    control$mc.cores <- 1
  if(quad.method=="quasi.random" && is.null(control$approx) && unit=="geo")
    control$approx <- TRUE
  else
    control$approx <- FALSE

  return(control)

}

## Some checks, check yo self before you reck yo self. https://www.youtube.com/watch?v=bueFTrwHFEs
## check the covariates that go into building the quadrature scheme.
checkCovariates <- function(covariates){

  if(!is.null(covariates)){
    if(!inherits(covariates, c('SpatRaster')))
      stop("Covariates must be a terra SpatRaster of covariates which match the spatial window.")
    covars <- TRUE
  } else {
    covars <- FALSE
  }
  covars
}

## check to see if there are duplicated points per species.
## duplicated points are allowed across multiple species ala marked points.
checkDuplicates <- function(presences, coord, mark.id, quiet){
  if(is.null(presences))return(NULL)
  dups <- duplicated(presences)
  if(sum(dups)>0){
    if(!quiet)message("There were ",sum(dups)," duplicated points unique to X, Y & SpeciesID, they have been removed.")
    dat <- presences[!dups,]
  } else {
  dat <- presences
  }
  dat <- as.data.frame(dat)
  colnames(dat) <- c(coord, mark.id)
  dat
}

## check to see if the presences dataset is multispecies.
checkMultispecies <- function(presences, mark.id){
  if(length(unique(presences[,mark.id]))>1) multi <- TRUE
  else multi <- FALSE
  multi
}

checkPresences <- function(known.sites, window, coord, mark.id){

  # check for null sites
  if(is.null(known.sites))
    stop("This function requires a set of presences to run.\n")

  # check object classes
  expectClass(known.sites, c('matrix','data.frame'))

  if(!any(colnames(known.sites)%in%mark.id))
    stop("'mark.id': ",mark.id," ,does not match any of the column names in your presences data.\n")
  if(!any(colnames(known.sites)%in%coord))
    stop("The coordinates names: ",paste(coord,collapse = ", ")," do not match any of the column names in your presences data.\n")

  # try and sort out factors.
  known.sites[[mark.id]] <- factor(known.sites[[mark.id]], levels = unique(known.sites[[mark.id]]))
  df <- known.sites[,c(coord,mark.id)]

  return (df)
}


checkWindow <- function(presences, window, coord, quiet){

  if(!is.null(window))
    inherits(window,"SpatRaster")#switching to terra (as it appears to be faster)

  if (is.null(window)) {
    if(!quiet) message("Window is NULL, a raster-based window will be generated based on the extent of 'presences'.\n")
    window <- defaultWindow(presences,coord)
  }
  window
}

## A function to clean up the NAs and weights.
cleanWeightsPPMdata <- function(dat){

  dat <- dat[complete.cases(dat$weights),]
  dat <- dat[is.finite(dat$weights),]
  dat[dat$weights==0,] <- sqrt(.Machine$double.eps)

  return(dat)
}

cleanCovariatesPPMdata <- function(dat){

  dat <- dat[complete.cases(dat),]

  return(dat)
}

## function to extract covariates for presence and background points.
getCovariates <- function(pbxy, covariates=NULL, interpolation, coord, buffer.NA, buffer.size, quiet){
  if(is.null(covariates)){
    covars <- cbind(SiteID=pbxy[,"SiteID"],pbxy[,coord])
  } else {
    covars <- terra::extract(x = covariates,
                             y = as.matrix(cbind(X=as.numeric(pbxy[,coord[1]]),
                                                 Y=as.numeric(pbxy[,coord[2]]))),
                             method=interpolation)#,
                             # na.rm=TRUE) ## apparently na.rm doesn't work for matrix
    covars <- cbind(SiteID=pbxy[,"SiteID"],pbxy[,coord],covars)
  if(buffer.NA){
    if(any(!complete.cases(covars))){
        if(!quiet)message('NA cells generated during covariate extraction. Extracting values from nearest (1 step) neighbour -- might be prudent to check imputation (and why it was imputed).')
        missXY <- which(!complete.cases(covars))
        missCoord <- covars[missXY,coord]
        if(is.null(buffer.size)){
          if(terra::is.lonlat(covariates)) ltlnscale <- 100000
          else ltlnscale <- 1
          buff <- terra::global(terra::area(covariates),fun="mean")*ltlnscale
        }else {
          buff <- buffer.size
        }
        buffCovars <- extract(x=covariates,y=missCoord,fun=mean,na.rm=TRUE,buffer=buff)
        covars[missXY,-1:-3] <- buffCovars
        }
      }
    }
  return(covars)
}

getCRS <- function(window){

  crs.out <- sf::st_crs(terra::crs(window))

  return(crs.out)

}

getSppNames <- function(presences, mark.id){

  sppIdx <- list()
  sppIdx$sppNames <- unique(presences[,mark.id])
  sppIdx$sppNames <- factor(sppIdx$sppNames, levels = unique(presences[,mark.id]))
  sppIdx$sppNumber <- seq_along(sppIdx$sppNames)

  return(sppIdx)

}


defaultWindow <- function (presences, coord) {

  # get limits
  xlim <- range(presences[,coord[1]])
  ylim <- range(presences[,coord[2]])

  # buffer
  xlim <- xlim + c(-1, 1) * diff(xlim) * 0.1
  ylim <- ylim + c(-1, 1) * diff(ylim) * 0.1
  xlim[1] <- floor(xlim[1])
  xlim[2] <- ceiling(xlim[2])
  ylim[1] <- floor(ylim[1])
  ylim[2] <- ceiling(ylim[2])

  ## create a window using terra
  e <- terra::ext(c(xlim,ylim))
  win <- terra::rast(xmin=xlim[1],xmax=xlim[2],
             ymin=ylim[1],ymax=ylim[2],
             nrows=225,ncols=225,
             crs="+proj=longlat +datum=WGS84")
  terra::values(win) <- 1
  return (win)
}


fastWideMatrix <- function(dat, mark.id){

  dat[,"OrigOrder"] <- factor(dat[,"OrigOrder"])

  out <- matrix(nrow=nlevels(dat[,"OrigOrder"]),
                ncol=nlevels(dat[,"wts.dataset"]),
                dimnames=list(levels(dat[,"OrigOrder"]),levels(dat[,"wts.dataset"])))

  out[cbind(dat[,"OrigOrder"], dat[,"wts.dataset"])] <- dat[,"pres"]

  return(out)
}


fastWideMatrixWeights <- function(dat, sppNames){

  dat[,"OrigOrder"] <- factor(dat[,"OrigOrder"])
  dat[,"DatasetID"] <- factor(dat[,"DatasetID"])

  wtsdat <- with(dat, {
    out <- matrix(nrow=nlevels(OrigOrder),
                  ncol=nlevels(DatasetID),
                  dimnames=list(levels(OrigOrder),levels(DatasetID)));
    out[cbind(OrigOrder, DatasetID)] <- wts.area;
    out})

  colnames(wtsdat) <- sppNames$sppNames[which(colnames(wtsdat)%in%sppNames$sppNumber)]
  wtsdat
}

transposePPMdata <- function( dat, sppNames, coordNames, covarNames){

  dat1 <- list()
  dat1$wts <- dat$wtsmat
  ## look out fot any negative weights
  dat1$wts[!is.na(dat1$wts)& dat1$wts<=0] <- sqrt(.Machine$double.eps)
  my.ord <- match(sppNames$sppNames,colnames(dat1$wts))#gtools::mixedorder( colnames( dat1$wts))

  # responses
  dat1$y <- dat$mm[,colnames( dat$mm) %in% colnames( dat1$wts)]
  dat1$y <- dat1$y[,my.ord]
  dat1$y <- as.matrix( dat1$y)
  colnames(dat1$y) <- sppNames$sppNames[my.ord]

  #weights
  dat1$wts <- dat1$wts[,my.ord]
  colnames(dat1$wts) <- sppNames$sppNames[my.ord]

  # Model matrix add in coordinates in the model matrix
  if(!is.null(covarNames)){
    dat1$covars <- dat$mm[,covarNames]
    dat1$mm <- cbind(dat1$y,dat$mm[,coordNames],dat1$covars)
  } else {
    dat1$mm <- cbind(dat1$y,dat$mm[,coordNames])
  }

  # locations
  dat1$locations <- dat$mm[,coordNames] #passed to ppmdata as coord argument

  # expectation z
  dat1$z <- dat1$y / dat1$wts
  dat1$bkg <- apply( dat1$y, 1, function(x) all( x==0))
  dat1$nmark <- ncol( dat1$wts)
  dat1$m <- nrow( dat1$wts)
  dat1$sppNames <- colnames( dat1$wts)
  dat1$nUniquePres <- sum( !dat1$bkg)
  dat1$nBkg <- sum( dat1$bkg)

  return( dat1)
}


