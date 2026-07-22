## This file is currently used on Win and Mac but NOT Linux
## Linux images have their own profile script

local({
  universe <- Sys.getenv('UNIVERSE_NAME')
  universe_url <- if(nchar(universe)){
    sprintf("https://%s.r-universe.dev", universe)
  }
  cran_url <- "https://cloud.r-project.org"
  fallback <- NULL

  if(nchar(Sys.getenv("CRAN_VERSION"))){
    cran_url <- sprintf("https://p3m.dev/cran/%s", Sys.getenv("CRAN_VERSION"))
  } else {
    if(grepl('darwin', R.version$platform)){
      fallback <- "https://mac.cran.dev"
    }
    if(grepl('x86_64-w64-mingw32', R.version$platform)){
      fallback <- "https://win.cran.dev"
    }
  }

  if(universe == 'bioc-release') {
    bioc_soft <- "https://bioconductor.posit.co/packages/release/bioc"
    bioc_anno <- "https://bioconductor.posit.co/packages/release/data/annotation"
    bioc_exp  <- "https://bioconductor.posit.co/packages/release/data/experiment"
  } else if(universe == 'bioc') {
    bioc_soft <- "https://bioconductor.posit.co/packages/devel/bioc"
    bioc_anno <- "https://bioconductor.posit.co/packages/devel/data/annotation"
    bioc_exp  <- "https://bioconductor.posit.co/packages/devel/data/experiment"
  } else {
    bioc_soft <- "https://bioc.r-universe.dev"
    bioc_anno <- sprintf("https://bioconductor.posit.co/packages/%s/data/annotation", utils:::.BioC_version_associated_with_R_version())
    bioc_exp  <- sprintf("https://bioconductor.posit.co/packages/%s/data/experiment", utils:::.BioC_version_associated_with_R_version())
  }

  # Always use our own binary repos on arm64-windows
  if(R.version$platform == "aarch64-w64-mingw32"){
    cran_url <- "https://cran.r-universe.dev"
    bioc_soft <- "https://bioc.r-universe.dev"
  }

  options(repos = c(
    universe = universe_url,
    CRAN = cran_url,
    fallback = fallback,
    BioCsoft = bioc_soft,
    BioCann = bioc_anno,
    BioCexp = bioc_exp
  ))
  options(Ncpus = 2, crayon.enabled = TRUE)
  options(HTTPUserAgent = paste0(getOption("HTTPUserAgent"), "; r-universe"))
  Sys.unsetenv(c("CI", "GITHUB_ACTIONS"))
})
