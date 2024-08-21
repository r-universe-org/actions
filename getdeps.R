# This script can mostly be replaced by pak::pak(dependencies = "all") once pak is fixed.
cat('::group::Show build environment\n')
cat(Sys.which('gcc'), "\n")
invisible(system("gcc --version"))
print(as.list(getOption('repos')))
cat(readLines(Sys.getenv('R_ENVIRON_USER')), sep = '\n')
cat('::endgroup::\n')

cat('::group::Install package dependencies\n')
dir.create(Sys.getenv('R_LIBS_USER'), recursive = TRUE, showWarnings = FALSE)
sourcepkg <- commandArgs(TRUE)[1]

# Derive all dependencies
filename <- sub("_.*", "/DESCRIPTION", basename(sourcepkg))
untar(sourcepkg, filename, extras = '--strip=1')
desc <- as.data.frame(read.dcf("DESCRIPTION"))
unlink('DESCRIPTION')
deps <- c(desc$Depends, desc$Imports, desc$LinkingTo, desc$Suggests, desc$Enhances)
pkg_deps <- unique(trimws(sub("\\(.*\\)", "", unlist(strsplit(deps, ',')))))
skiplist <- c("R", getOption('defaultPackages'))
pkg_deps <- setdiff(pkg_deps, skiplist)
installed <- row.names(installed.packages())

# Update existing packages
update.packages(oldPkgs = pkg_deps, ask = FALSE)

# Install new packages that we can find
needpkg <- setdiff(pkg_deps, installed)
avail <- row.names(available.packages())
install <- intersect(needpkg, avail)
unavail <- setdiff(needpkg, avail)
install.packages(install)

# Last resort
if(length(unavail)) {
  warning("Installing from remotes: ", paste(unavail, collapse = ','))
  install.packages('remotes')
  remotes::install_deps(sourcepkg, dependencies = TRUE, upgrade = FALSE)
}

cat('::endgroup::\n')
