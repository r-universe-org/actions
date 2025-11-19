status <- 'FAILURE'
sourcepkg <- commandArgs(TRUE)[1]

cat("::group::Install BiocCheck\n")
install.packages('BiocCheck')
cat('::endgroup::\n')

try({
	library(BiocCheck)
	results <- BiocCheck(sourcepkg, 'no-check-R-ver' = TRUE)
	if(length(results$error)){
		status <- 'ERROR'
	} else if(length(results$warning)){
		status <- 'WARNING'
	} else if(length(results$note)){
		status <- 'NOTE'
	} else {
		status <- 'OK'
	}
})

write_output <- function(key, value){
  cat(paste0(key, '=', value, '\n'), file = Sys.getenv("GITHUB_OUTPUT"), append = TRUE)
}

write_output('CHECKSTATUS', status)
