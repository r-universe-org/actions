first <- tools:::check_packages_in_dir_results('.')[1]
package <- names(first)
results <- first[[1]]
writeLines(paste0('CHECKSTATUS=',results$status),Sys.getenv("GITHUB_OUTPUT"))
writeLines(results$lines, 'checkresults.txt')
out <- lapply(grep("ERROR", results$lines, value=TRUE), function(errmsg){
  cat(sprintf("::error file=%s::R CMD check reported problem: %s\n", package, gsub("\\s+", " ", errmsg)))
})
