if(grepl("4.3", getRversion())) Sys.setenv(R_BIOC_VERSION='3.18')
if(grepl("4.4", getRversion())) Sys.setenv(R_BIOC_VERSION='3.20')
if(grepl("4.5", getRversion())) Sys.setenv(R_BIOC_VERSION='3.20')
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(BioC_mirror = "https://bioc.cran.dev")
utils::setRepositories(ind = 1:3)
#options(repos = c(pppm = "https://p3m.dev/cran/latest", getOption("repos")))
if(nchar(Sys.getenv("MY_UNIVERSE"))){
  options(repos = c(universe = Sys.getenv("MY_UNIVERSE"), getOption("repos")))
}
options(Ncpus = 2, crayon.enabled = TRUE)
options(HTTPUserAgent = paste0(getOption("HTTPUserAgent"), "; r-universe"))
Sys.unsetenv(c("CI", "GITHUB_ACTIONS"))
