#' Helper function to read a data file
#'
#' Checks file for existence in the current
#' directory and returns its content as a tibble.
#' Used by \code{fars_read_years} and \code{fars_map_state}.
#'
#' @param filename A string with the exact name of
#' the file to read
#'
#' @return A tibble with the full data file contents
#'
#' @examples
#' fars_read("accident_2014.csv.bz2")
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df
#' 
fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}

#' Helper function to compose a full filename
#' according with the \code{fars_data} conventions
#' by providing only the year number.
#'
#' Used by \code{fars_read_years} and \code{fars_map_state},
#' before \code{fars_read}.
#'
#' @param year A value representing the year. It will
#' be coerced to integer, therefore it does not need
#' to be of a specific type, as long as the coercion
#' is feasible.
#'
#' @return A string with the full filename.
#'
#' @examples
#' make_filename(2014)
#'
make_filename <- function(year) {
        year <- as.integer(year)
        sprintf("accident_%d.csv.bz2", year)
}

#' Helper function to select months from a year list.
#'
#' Since data is split in files one per year, a year
#' column is added and the results combined into a
#' single tibble.
#' Checks for year validity.
#' Used by \code{fars_summarize_years} and \code{fars_map_state}.
#'
#' @param years A list or vector of values representing years.
#'
#' @return A tibble with one row per accident and
#' columns year and MONTH reporting the accident date.
#'
#' @examples
#' fars_read_years(c(2013, 2015))
#'
#' @importFrom dplyr mutate select
#'
fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>% 
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Summarizes accident data for a set of years.
#'
#' Summarizes and tidies the data returned by \code{fars_read_years} by
#' counting the accident numbers per year and month.
#'
#' @param years A list or vector of values representing years.
#'
#' @return A tibble with the number of accidents per year per month.
#'
#' @examples
#' fars_summarize_years(c(2013, 2015))
#'
#' @import dplyr
#' @importFrom tidyr spread
#'
#' @export
#' 
fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>% 
                dplyr::group_by(year, MONTH) %>% 
                dplyr::summarize(n = n()) %>%
                tidyr::spread(year, n)
}

#' Displays a map of a state with the accident locations in the given year.
#'
#' Checks for state code validity, accident presence in the
#' specified subset and latitude/longitude range.
#' Returns NULL invisibly.
#'
#' @param state.num A value representing the state
#' numerical code. It will be coerced to integer,
#' therefore it does not need to be of a specific type,
#' as long as the coercion is feasible.
#' 
#' @param year A value representing the year. It will
#' be coerced to integer, therefore it does not need
#' to be of a specific type, as long as the coercion
#' is feasible.
#'
#' @examples
#' fars_map_state(6, 2015)
#'
#' @importFrom dplyr filter
#' @importFrom maps map
#' @importFrom graphics points
#'
#' @export
#' 
fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
