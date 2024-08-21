# This script can mostly be replaced by pak::pak(dependencies = "all") once pak is fixed.
cat('::group::Show build environment\n')
cat(Sys.which('gcc'), "\n")
invisible(system("gcc --version"))
print(as.list(getOption('repos')))
cat(readLines(Sys.getenv('R_ENVIRON_USER')), sep = '\n')
cat('::endgroup::\n')

# Do not try to install base packages
skiplist <- c("R", "base", "boot", "class", "cluster", "codetools",
  "compiler", "datasets", "foreign", "graphics", "grDevices", "grid",
  "KernSmooth", "lattice", "MASS", "Matrix", "methods", "mgcv",
  "nlme", "nnet", "parallel", "rpart", "spatial", "splines", "stats",
  "stats4", "survival", "tcltk", "tools", "utils")

cat('::group::Install package dependencies\n')
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
  message("Additional_repositories: ", paste(addrepos, collapse = ', '))
  options(repos = c(getOption('repos'), addrepos))
}

# Update existing packages
update.packages(oldPkgs = pkg_deps, ask = FALSE)

# Install new packages
installed <- row.names(installed.packages())
needpkg <- setdiff(pkg_deps, installed)
install.packages(needpkg)

# Test again if any are missing, try with remotes
installed <- row.names(installed.packages())
unavail <- setdiff(pkg_deps, installed)
if(length(unavail)) {
  warning("Installing from remotes: ", paste(unavail, collapse = ','))
  install.packages('remotes')
  remotes::install_deps(sourcepkg, dependencies = TRUE, upgrade = FALSE)
}

cat('::endgroup::\n')
