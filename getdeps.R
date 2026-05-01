cat('::group::Show build environment\n')
cat(Sys.which('gcc'), "\n")
invisible(system("gcc --version"))
print(as.list(getOption('repos')))
cat(readLines(Sys.getenv('R_ENVIRON_USER')), sep = '\n')
cat('::endgroup::\n')

# Print warnings immediately
options(warn = 1)

write_output <- function(key, value){
  cat(paste0(key, '=', value, '\n'), file = Sys.getenv("GITHUB_OUTPUT"), append = TRUE)
}
write_output('rversion', getRversion())

# Do not try to install base packages
too_big <- c('SNPlocs.Hsapiens.dbSNP155.GRCh38', 'SNPlocs.Hsapiens.dbSNP155.GRCh37',
  'MafDb.gnomAD.r2.1.GRCh38', 'MafDb.gnomAD.r2.1.hs37d5')
skiplist <- c("R", too_big, row.names(installed.packages(priority="base")), too_big)

#cat('::group::Install package dependencies\n')
dir.create(Sys.getenv('R_LIBS_USER'), recursive = TRUE, showWarnings = FALSE)
sourcepkg <- commandArgs(TRUE)[1]

# Derive all dependencies
filename <- sub("_.*", "/DESCRIPTION", basename(sourcepkg))
untar(sourcepkg, filename, extras = '--strip=1')
desc <- as.data.frame(read.dcf("DESCRIPTION"))
unlink('DESCRIPTION')
deps <- c(desc$Depends, desc$Imports, desc$LinkingTo, desc$Suggests, desc$Enhances)
pkg_deps <- unique(trimws(sub("\\(.*\\)", "", unlist(strsplit(as.character(deps), ',')))))
pkg_deps <- setdiff(pkg_deps, skiplist)

# Add Additional_repositories
if(length(desc$Additional_repositories)){
  addrepos <- trimws(strsplit(desc$Additional_repositories, ",", fixed=TRUE)[[1]])
  addrepos <- grep('^https?://\\S+$', addrepos, value = TRUE)
  addrepos <- grep(Sys.getenv("MY_UNIVERSE"), fixed = TRUE, addrepos, value = TRUE, invert = TRUE)
  message("Additional_repositories: ", paste(addrepos, collapse = ', '))
  options(repos = c(getOption('repos'), addrepos))
}

# Install sysdeps (Linux only)
if(grepl("linux", R.Version()$platform)) {
  sysreqs <- gsub("\\s+", " ", desc[['Config/pak/sysreqs']])
  if(length(sysreqs)){
    cat("Installing sysreqs:", sysreqs, "\n")
    system("apt-get update")
    system(paste("apt-get install -y", sysreqs))
  }
}

# Hack for bioc mess
#if(identical('bioc', Sys.getenv('UNIVERSE_NAME'))){
#  pkg_deps <- c(pkg_deps, "zlibbioc")
#}


# Install new packages
options(install.packages.check.source = "no")
options("install.packages.compile.from.source"="never")

# Somehow 'install.packages.check.source=no' still installs packages w/o compiled code from src
# But we also need transitive deps that are not available as binary such as bioconductor data packages
if(R.version$platform == "x86_64-w64-mingw32"){
  install.packages(pkg_deps, type = .Platform$pkgType)
  alldeps <- unique(unname(c(pkg_deps, unlist(tools::package_dependencies(pkg_deps, recursive = TRUE)))))
  missingdeps <- setdiff(alldeps, c(skiplist, row.names(installed.packages())))
  message("Try building from source: ", paste(missingdeps, collapse = ', '))
  # Needed when some binaries are 404
  install.packages(missingdeps, type = 'source')
} else {
  install.packages(pkg_deps)
}

# Update pre-installed and outdated binary packages
options(install.packages.check.source = NULL)
options("install.packages.compile.from.source"="interactive")
update.packages(oldPkgs = pkg_deps, type = 'source', ask = FALSE)

# Test again if any are missing, try with remotes
installed <- row.names(installed.packages())
unavail <- setdiff(pkg_deps, installed)
if(length(unavail)) {
  warning("Installing from remotes: ", paste(unavail, collapse = ','))
  install.packages('remotes')
  remotes::install_deps(sourcepkg, dependencies = TRUE, upgrade = FALSE)
}

# Temp fixes for broken CRAN binaries
#if(identical(.Platform$pkgType, 'mac.binary.big-sur-x86_64') && R.version$minor == '6.0'){
#  if('data.table' %in% installed){
#    install.packages('data.table', repos = 'https://test.r-universe.dev')
#  }
#}
#if('Rcpp' %in% installed){
#  install.packages('Rcpp', repos = 'https://rcppcore.r-universe.dev')
#}
# Workaround bug in R-4.6-alpha, fixed in 89810
#if(R.version$minor == '6.0' && isTRUE(R.version[["svn rev"]] < "89810")) {
#  broken <- R.home("include/R_ext/RStartup.h")
#  readLines(broken) |> sub(pattern="new)", replacement="newval)", fixed = TRUE) |> writeLines(broken)
#}

# Clear PATH for some weird pkg
if(.Platform$OS.type == 'windows' && grepl("Rgraphviz", sourcepkg) && nchar(Sys.getenv("R_ENVIRON_USER"))){
  message("Clearing PATH for Rgraphviz")
  writeLines("PATH=C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem", Sys.getenv("R_ENVIRON_USER"))
}
