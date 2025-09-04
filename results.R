first <- tools:::check_packages_in_dir_results('.')[1]
package <- names(first)
results <- first[[1]]
write_output <- function(key, value){
  cat(paste0(key, '=', value, '\n'), file = Sys.getenv("GITHUB_OUTPUT"), append = TRUE)
}
write_output('CHECKSTATUS', results$status)
writeLines(results$lines, 'checkresults.txt')

if(results$status == 'FAILURE'){
  details <- tools:::check_packages_in_dir_details('.')
  writeLines(paste(format(details), collapse = "\n\n"), "checkdetails.txt")
  errors <- details[details$Status=='FAILURE',]
  errors$Flags <- NULL
  errors$Package <- NULL
  errmsg <- paste(format(errors), collapse = "\n\n")
  cat(sprintf("::error file=%s::%s\n", package, gsub("\n", "%0A", errmsg, fixed = TRUE)))
} else if(results$status == 'ERROR'){
  details <- tools:::check_packages_in_dir_details('.')
  writeLines(paste(format(details), collapse = "\n\n"), "checkdetails.txt")
  errors <- details[details$Status=='ERROR',]
  errors$Flags <- NULL
  errors$Package <- NULL
  errmsg <- paste(format(errors), collapse = "\n\n")
  cat(sprintf("::error file=%s::%s\n", package, gsub("\n", "%0A", errmsg, fixed = TRUE)))
} else if(results$status == 'WARNING'){
  details <- tools:::check_packages_in_dir_details('.')
  writeLines(paste(format(details), collapse = "\n\n"), "checkdetails.txt")
  errors <- details[details$Status=='WARNING',]
  errors$Flags <- NULL
  errors$Package <- NULL
  errmsg <- paste(format(errors), collapse = "\n\n")
  cat(sprintf("::warning file=%s::%s\n", package, gsub("\n", "%0A", errmsg, fixed = TRUE)))
}
