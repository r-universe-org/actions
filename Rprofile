## This file is currently used on Win and Mac but NOT Linux
## Linux images have their own profile script

if(grepl("4.4", getRversion())) Sys.setenv(R_BIOC_VERSION='3.20')
if(grepl("4.5", getRversion())) Sys.setenv(R_BIOC_VERSION='3.21')
#if(grepl("4.6", getRversion())) Sys.setenv(R_BIOC_VERSION='3.21')

# If a specific cran version is set, use only that
cran_version <- Sys.getenv("CRAN_VERSION")
if(nchar(cran_version)){
  options(repos = c(CRAN = sprintf("https://p3m.dev/cran/%s", cran_version)))
} else {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}
if(grepl("development", R.version[['status']])) {
  options(BioC_mirror = "https://bioc.cran.dev")
} else {
  options(BioC_mirror = "https://bioconductor.posit.co")
}

if(grepl("bioc", Sys.getenv('UNIVERSE_NAME'))){
  utils::setRepositories(ind = 1:5)
} else {
  utils::setRepositories(ind = 1:3)
}

if(nchar(Sys.getenv("MY_UNIVERSE"))){
  options(repos = c(universe = Sys.getenv("MY_UNIVERSE"), getOption("repos")))
}
options(Ncpus = 2, crayon.enabled = TRUE)
options(HTTPUserAgent = paste0(getOption("HTTPUserAgent"), "; r-universe"))
Sys.unsetenv(c("CI", "GITHUB_ACTIONS"))
