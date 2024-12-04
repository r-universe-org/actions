first <- tools:::check_packages_in_dir_results('.')[1]
package <- names(first)
results <- first[[1]]
writeLines(paste0('CHECKSTATUS=',results$status),Sys.getenv("GITHUB_OUTPUT"))
writeLines(results$lines, 'checkresults.txt')
if(results$status == 'ERROR'){
  details <- tools:::check_packages_in_dir_details('.')
  writeLines(paste(format(details), collapse = "\n\n"), "checkdetails.txt")
  errors <- details[details$Status=='ERROR',]
  errors$Flags <- NULL
  errors$Package <- NULL
  errmsg <- paste(format(errors), collapse = "\n\n")
  cat(sprintf("::error file=%s::%s\n", package, gsub("\n", "%0A", errmsg, fixed = TRUE)))
}
