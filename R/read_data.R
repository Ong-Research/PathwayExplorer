

#' A function to read and format the DE genes file
#' @param de_file The input file with the differential expressed genes
#' @return the contents of the file in a `tibble::tibble`
read_de_file <- function(de_file) {
  
  ext <- tools::file_ext(de_file)
  ext <- stringr::str_to_lower(ext)
  if (ext == "qs") {
    qs::qread(de_file)
  } else if (ext == "tsv") {
    readr::read_tsv(de_file)
  } else if (ext == "csv") {
    readr::read_csv(de_file)
  } else {
    stop(glue::glue("there is no definition for {ext} file extension", ext = ext))
  }
   
}