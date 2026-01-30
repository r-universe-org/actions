## This file is currently used on Win and Mac but NOT Linux
## Linux images have their own profile script

local({
  universe <- Sys.getenv('UNIVERSE_NAME')
  universe_url <- if(nchar(universe)){
    sprintf("https://%s.r-universe.dev", universe)
  }
  cran_url <- if(nchar(Sys.getenv("CRAN_VERSION"))){
    sprintf("https://p3m.dev/cran/%s", Sys.getenv("CRAN_VERSION"))
  } else {
    "https://cloud.r-project.org"
  }
  bioc_ver <- if(universe == 'bioc-release') {
    'release'
  } else if(universe == 'bioc') {
    'devel'
  } else if(grepl("4.6", getRversion())) {
    '3.23'
  } else if(grepl("4.5", getRversion())) {
    '3.22'
  } else if(grepl("4.4", getRversion())) {
    '3.20'
  }
  bioc_soft <- sprintf("https://bioconductor.org/packages/%s/bioc", bioc_ver)
  bioc_anno <- sprintf("https://bioconductor.org/packages/%s/data/annotation", bioc_ver)
  bioc_exp <- sprintf("https://bioconductor.org/packages/%s/data/experiment", bioc_ver)
  options(repos = c(
    universe = universe_url,
    CRAN = cran_url,
    BioCsoft = bioc_soft,
    BioCann = bioc_anno,
    BioCexp = bioc_exp
  ))
  options(Ncpus = 2, crayon.enabled = TRUE)
  options(HTTPUserAgent = paste0(getOption("HTTPUserAgent"), "; r-universe"))
  Sys.unsetenv(c("CI", "GITHUB_ACTIONS"))
})
