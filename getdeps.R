cat('::group::Show build environment\n')
cat(Sys.which('gcc'), "\n")
invisible(system("gcc --version"))
print(as.list(getOption('repos')))
cat(readLines(Sys.getenv('R_ENVIRON_USER')), sep = '\n')
cat('::endgroup::\n')

write_output <- function(key, value){
  cat(paste0(key, '=', value, '\n'), file = Sys.getenv("GITHUB_OUTPUT"), append = TRUE)
}
write_output('rversion', getRversion())

# Do not try to install base packages
skiplist <- c("R", "base", "boot", "class", "cluster", "codetools",
  "compiler", "datasets", "foreign", "graphics", "grDevices", "grid",
  "KernSmooth", "lattice", "MASS", "Matrix", "methods", "mgcv",
  "nlme", "nnet", "parallel", "rpart", "spatial", "splines", "stats",
  "stats4", "survival", "tcltk", "tools", "utils")

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

# Temp fix
# if(.Platform$OS.type == 'windows' && R.version$minor == '6.0'){
#  install.packages('data.table', repos = 'https://test.r-universe.dev')
# }

# Install new packages
options(install.packages.check.source = "no")
options("install.packages.compile.from.source"="never")
installed <- row.names(installed.packages())
needpkg <- setdiff(pkg_deps, installed)

# Somehow 'install.packages.check.source=no' still installs packages w/o compiled code from src
# But we also need transitive deps that are not available as binary such as bioconductor data packages
if(.Platform$OS.type == 'windows'){
  install.packages(needpkg, type = 'win.binary')
  alldeps <- unique(unname(c(needpkg, unlist(tools::package_dependencies(needpkg, recursive = TRUE)))))
  missingdeps <- setdiff(alldeps, c(skiplist, row.names(installed.packages())))
  install.packages(missingdeps)
} else {
  install.packages(needpkg)
}

# Update pre-installed and outdated binary packages
options(install.packages.check.source = NULL)
options("install.packages.compile.from.source"="interactive")
update.packages(oldPkgs = pkg_deps, type = 'source', ask = FALSE)

# Workaround broken devel callr
if('callr' %in% row.names(installed.packages())){
  install.packages('callr', repos = getOption('repos')['CRAN'])
}

# Test again if any are missing, try with remotes
installed <- row.names(installed.packages())
unavail <- setdiff(pkg_deps, installed)
if(length(unavail)) {
  warning("Installing from remotes: ", paste(unavail, collapse = ','))
  install.packages('remotes')
  remotes::install_deps(sourcepkg, dependencies = TRUE, upgrade = FALSE)
}

#cat('::endgroup::\n')
