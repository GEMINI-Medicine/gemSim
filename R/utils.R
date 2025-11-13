#' Imports for the entire package
#' Doesn't require Depends or `@import` per function
#'
#' @rawNamespace
#' import(data.table, except = c("first", "last", "between", "month", "hour",
#' "quarter", "week", "year", "wday", "second", "minute", "mday", "yday",
#' "isoweek"))
#' @rawNamespace
#' import(dplyr, except = c("first", "last", "between", "matches"))
#' @rawNamespace
#' import(lubridate)
#'
NULL

#' @title
#' Check user inputs
#'
#' @description
#' Function checking whether user-provided inputs for a function are
#' appropriate. The following check is applied for all inputs:
#' - Whether input is of correct type (e.g., `logical`, `numeric`, `character`
#' etc.)
#' For some input types, the following additional checks can be applied
#' optionally:
#' - Check whether length of provided input is as expected
#' - For `numeric`/`integer` inputs: Check whether provided input is within
#' acceptable interval (e.g., between 1-100).
#' - For `character` (categorical) inputs: Check whether input corresponds to
#' one of acceptable categories.
#' - For `data.table|data.frame` inputs: 1) Check whether required columns exist
#' in table, 2) whether each column is of a specified type, and 3) whether all
#' entries are unique.
#'
#' @param arginput (`character`)\cr
#' Input argument to be checked. Users can provide multiple inputs to be checked
#' within a single call to this function by providing all inputs as a list
#' (e.g., `arginput = list(input1, input2)`). However, this only works if all
#' input arguments (e.g., input1 AND input2) are supposed to meet the same
#' criteria (e.g., both should be numeric within interval 0-10).
#'
#' @param argtype (`character`)\cr
#' Required type of input argument based on `class()`. Example type(s) users can
#' specify:
#' - `"logical"`
#' - `"character"`
#' - `"numeric"` (or `"integer"` if specifically checking for integers)
#' - `"data.table"`
#' - `"data.frame"`
#' - `"DBI" | "dbcon" | "PostgreSQL"` for DB connection input
#' - `"list"`
#' - `"Date"`, `"POSIXct"`, `"POSIXt"`
#' - ...
#'
#' If an input object can be one of several acceptable types (e.g.,
#' `data.table` OR `data.frame`), types should be provided as a character vector
#' (e.g., `argtype = c("data.frame", "data.table")`).
#'
#' If `argtype` is `"integer"`, the tests will pass
#' 1) if `class(input) == "integer"` or
#' 2) if `class(input) == "numeric"` and the number is an integer
#'
#' If `argtype` is `"numeric"`, inputs that are of class `"integer"` will also
#' pass. In other words, integers are treated as a special case of numeric in
#' the case of `argtype`. Therefore, checks with
#' `argtype = c("integer", "numeric")` (i.e., input should be either integer
#' *or* numeric) are not meaningful and should be avoided. Instead, users should
#' specify if inputs need to be an `"integer"` specifically
#' (`argtype = "integer"`), or if they just need to be any `"numeric"` input
#' (`argtype = "numeric"`).
#'
#' @param length (`numeric`)\cr
#' Optional input specifying the expected length of a given input argument
#' (e.g., use `length = 2` to check if a vector/list contains 2 elements).
#'
#' @param categories (`character`)\cr
#' Optional input if argtype is `"character"`.
#' Character vector specifying acceptable categories for character inputs (e.g.,
#' `categories = c("none", "all")`)
#'
#' @param interval (`numeric`)\cr
#' Optional input if argtype is `"numeric"` or `"integer"`.
#' Numeric vector specifying acceptable range for numeric inputs (e.g.,
#' `interval = c(1,100)`, or for non-negative numbers: `interval = c(0, Inf)`).
#' Note that `interval` specifies a closed interval (i.e., end points are
#' included).
#'
#' @param colnames (`character`)\cr
#' Optional input if argtype is `"data.frame"` or `"data.table"`.
#' Character vector specifying all columns that need to exist in the input table
#' (e.g., `colnames = c("genc_id", "discharge_date_time")`).
#'
#' @param coltypes (`character`)\cr
#' Optional input if argtype is `"data.frame"` or `"data.table"`.
#' Character vector specifying required data type of each column in `colnames`
#' (e.g., `coltypes = c("integer", "character")`) where the order of the vector
#' elements should correspond to the order of the entries in `colnames`.
#' If a column can have multiple acceptable types, types should be separated by
#' `|` (e.g., `coltypes = c("integer|numeric", "character|POSIXct")`)). For any
#' columns that do not have to be of a particular type, simply specify as `""`
#' (e.g., `coltypes = c("integer|numeric", "")`).
#'
#' Note: As opposed to `argtype`, `coltypes` need to strictly correspond to the
#' type that is returned by `class(column)`. That means that type `"integer"` is
#' *not* a special case of `"numeric"`, but is treated as a separate type. This
#' is relevant for `genc_id` columns, which are of class `"integer"`, and
#' therefore `coltype = "numeric"` will return an error.
#'
#' @param unique (`logical`)\cr
#' Optional input if argtype is `"data.frame"` or `"data.table"`. Flag
#' indicating whether all rows in the provided input table need to be distinct.
#'
#' @return \cr
#' If any of the input checks fail, function will return error message and stop
#' execution of parent `Rgemini` function. Otherwise, function will not return
#' anything.
#'
#' @examples
#' \dontrun{
#' my_function <- function(input1 = TRUE, # logical
#'                         input2 = 2, # numeric
#'                         input3 = 1.5, # numeric
#'                         input4 = data.frame(
#'                           genc_id = as.integer(5),
#'                           discharge_date_time = Sys.time(),
#'                           hospital_num = 1
#'                         )) {
#'   # check single input
#'   check_input(input1, "logical")
#'
#'   # check multiple inputs that should be of same type/meet same criteria
#'   check_input(
#'     arginput = list(input2, input3), argtype = "numeric",
#'     length = 1, interval = c(1, 10)
#'   )
#'
#'   # check table input (can be either data.frame or data.table)
#'   check_input(input4,
#'     argtype = c("data.table", "data.frame"),
#'     colnames = c("genc_id", "discharge_date_time", "hospital_num"),
#'     coltypes = c("integer", "character|POSIXct", ""),
#'     unique = TRUE
#'   )
#' }
#'
#' # will not result in any errors (default inputs are correct)
#' my_function()
#'
#' # will result in an error
#' my_function(input1 = 1) # input 1 has to be logical
#' }
#'
check_input <- function(arginput, argtype,
                        length = NULL,
                        categories = NULL, # for character inputs only
                        interval = NULL, # for numeric inputs only
                        colnames = NULL, # for data.table/.frame inputs only
                        coltypes = NULL, #          "-"
                        unique = FALSE) { #          "-"


  ## Get argument names and restructure input
  if (any(class(arginput) == "list")) {
    # Note: Users can provide multiple arginputs to be checked by combining them
    # into a list ...or they might want to check an arginput that is supposed to
    # be a list itself
    # Here: We infer which one it is based on deparse(substitute)
    # If arginput is provided as a single input name:
    # -> assume input itself is supposed to be a list
    # If each list item corresponds to a separate argument name
    # -> assume user wants to check individual items
    # it's a bit hacky but seems to work for tested scenarios
    argnames <- sapply(substitute(arginput), deparse)[-1]
    if (length(argnames) < 1) {
      argnames <- deparse(substitute(arginput))
      arginput <- list(arginput = arginput)
    }
  } else {
    # get name of argument
    argnames <- deparse(substitute(arginput))

    # turn arginput into list (for Map function below to work)
    arginput <- list(arginput = arginput)
  }


  ## Define new function to check for integers
  #  Note: base R's `is.integer` does not return TRUE if type == numeric
  #  Note 2: For coltypes check below, this function is not used
  #  (instead coltypes are checked for whether class(column) returns "integer")
  is_integer <- function(x) {
    if (is.numeric(x)) {
      tol <- .Machine$double.eps
      return(abs(x - round(x)) < tol)
    } else {
      return(FALSE)
    }
  }


  ## Function defining all input checks
  run_checks <- function(arginput, argname) {
    ###### CHECK 1 (for all input types): Check if type is correct
    ## For DB connections
    if (any(grepl("dbi|con|posgre|sql", argtype, ignore.case = TRUE))) {
      if (inherits(arginput, "OdbcConnection") || !grepl("PostgreSQL", class(arginput)[1])) {
        stop(
          paste0(
            "Invalid user input in '",
            as.character(sys.calls()[[1]])[1], "': '",
            argname, "' needs to be a valid PostgreSQL database connection.\n",
            "Database connections established with `odbc` are currently not supported.\n",
            "Instead, please use the following method to establish a DB connection:\n",
            "drv <- dbDriver('PostgreSQL')\n",
            "dbcon <- DBI::dbConnect(drv, dbname = 'db_name', ",
            "host = 'domain_name.ca', port = 1234, ",
            "user = getPass('Enter user:'), password = getPass('password'))\n",
            "\nPlease refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      } else if (!RPostgreSQL::isPostgresqlIdCurrent(arginput)) {
        # if PostgreSQL connection, make sure it's still active
        stop(
          paste0(
            "Please make sure your database connection is still active.\n",
            "You may need to reconnect to the database if the connection has timed out."
          ),
          call. = FALSE
        )
      }

      ## For all other inputs
    } else if ((any(argtype == "integer") && !all(is_integer(arginput))) ||
      (!any(argtype == "integer") && !any(class(arginput) %in% argtype) &&
        (!(any(argtype == "numeric") &&
          all(is_integer(arginput)))))) { # in case argtype is "numeric" and provided input is "integer", don't show error
      stop(
        paste0(
          "Invalid user input in '", as.character(sys.calls()[[1]])[1], "': '",
          argname, "' needs to be of type '", paste(argtype,
            collapse = "' or '"
          ), "'.",
          "\nPlease refer to the function documentation for more details."
        ),
        call. = FALSE
      )
    }


    ###### CHECK 2: Check if length of input argument is as expected [optional]
    if (!is.null(length)) {
      if (length(arginput) != length) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1],
            "': '", argname, "' needs to be of length ", length,
            "\nPlease refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      }
    }


    ###### CHECK 3 (for character inputs):
    ###### Check if option is one of acceptable alternatives [optional]
    if (any(argtype == "character") && !is.null(categories)) {
      if (any(!arginput %in% categories)) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1],
            "': '", argname, "' needs to be either '", paste0(
              paste(categories[seq_along(categories) - 1], collapse = "', '"),
              "' or '", categories[length(categories)]
            ), "'.",
            "\nPlease refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      }
    }


    ###### CHECK 4 (for numeric/integer inputs):
    ###### Check if number is within acceptable interval [optional]
    if (any(argtype %in% c("numeric", "integer")) && !is.null(interval)) {
      if (any(arginput < interval[1]) || any(arginput > interval[2])) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1],
            "': '", argname, "' needs to be within closed interval [",
            interval[1], ", ", interval[2], "].",
            "\nPlease refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      }
    }


    ###### CHECK 5 (for data.table/data.frame inputs):
    ###### Check if nrow() > 0 & if relevant columns exist [optional]
    if (any(argtype %in% c("data.frame", "data.table")) && !is.null(colnames)) {
      if (nrow(arginput) == 0) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1],
            "': '", argname, "' input table has 0 rows.",
            "\nPlease carefully check your input."
          ),
          call. = FALSE
        )
      }

      # get missing columns
      missing_cols <- setdiff(colnames, colnames(arginput))

      if (length(missing_cols) > 0) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1],
            "': '", argname, "' input table is missing required column(s) '",
            paste0(missing_cols, collapse = "', '"), "'.",
            "\nPlease refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      }
    }


    ###### CHECK 6 (for data.table/data.frame inputs):
    ###### Check if required columns are of correct type [optional]
    if (any(argtype %in% c("data.frame", "data.table")) && !is.null(coltypes)) {
      # for simplicity of error output:
      # only show first column where incorrect type was found (if any)
      # ignore coltypes without specification ("")
      check_col_type <- function(col, coltype) {
        if (coltype != "" && !any(grepl(coltype,
          class(as.data.table(arginput)[[col]]),
          ignore.case = TRUE
        ))) {
          stop(
            paste0(
              "Invalid user input in '", as.character(sys.calls()[[1]])[1],
              "': '", col, "' in input table '", argname,
              "' has to be of type '", coltype, "'.",
              "\nPlease refer to the function documentation for more details."
            ),
            call. = FALSE
          )
        }
      }
      mapply(check_col_type, colnames, coltypes)
    }


    ###### CHECK 7 (for data.table/data.frame inputs):
    ###### Check if all rows are distinct [optional]
    if (any(argtype %in% c("data.frame", "data.table")) && unique == TRUE) {
      if (any(duplicated(arginput))) {
        stop(
          paste0(
            "Invalid user input in '", as.character(sys.calls()[[1]])[1], "': ",
            "Input table '", argname, "' has to contain unique rows.",
            "\nPlease check for duplicate entries and ",
            "refer to the function documentation for more details."
          ),
          call. = FALSE
        )
      }
    }
  }


  ### Run checks on all input arguments (if multiple)
  check_all <- Map(run_checks, arginput, argnames)
}

#' @title
#' Sample a truncated log normal distribution
#'
#' @description
#' Sample from a log normal distribution using the `rlnorm` function
#' Truncate it to specified minimum and maximum values
#'
#' @param n (`integer`) The length of the output vector
#'
#' @param meanlog (`numeric`) The mean of the log normal distribution
#'
#' @param sdlog (`numeric`) The standard deviation of the log normal distribution
#'
#' @param min (`numeric`) The minimum value to truncate the data to.
#'
#' @param max (`numeric`) The maximum value to truncate the data to.
#'
#' @param seed (`integer`) Optional, a number for setting the seed for reproducible results
#'
#' @return A numeric vector following the log normal distribution, truncated to the specified range.
#'
#' @export
#'
rlnorm_trunc <- function(n, meanlog, sdlog, min, max, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (min > max) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  res <- rlnorm(n, meanlog, sdlog)
  # keep redrawing until all are in range
  # get out of range values
  oor <- (res < min) | (res > max)
  while (any(oor)) {
    res[oor] <- rlnorm(sum(oor, na.rm = TRUE), meanlog, sdlog)
    oor <- (res < min) | (res > max)
  }
  return(res)
}

#' @title
#' Sample a truncated normal distribution
#'
#' @description
#' Sample from a normal distribution using the `rnorm` function but truncate it to specified minimum and maximum values
#'
#' @param n (`integer`) The length of the output vector
#'
#' @param mean (`numeric`) The mean of the normal distribution
#'
#' @param sd (`numeric`) The standard deviation of the normal distribution
#'
#' @param min (`numeric`) The minimum value to truncate the data to.
#'
#' @param max (`numeric`) The maximum value to truncate the data to.
#'
#' @param seed (`integer`) Optional, a number for setting the seed for reproducible results
#'
#' @return A numeric vector following the normal distribution, truncated to the specified range.
#'
#' @export
#'
rnorm_trunc <- function(n, mean, sd, min, max, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (min > max) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  res <- rnorm(n, mean, sd)
  while (sum(res < min) + sum(res > max) > 0) {
    res[c(res < min | res > max)] <- rnorm(
      sum(res < min) + sum(res > max),
      mean,
      sd
    )
  }
  return(res)
}

#' @title
#' Sample a truncated skewed normal distribution
#'
#' @description
#' Sample from a skewed normal distribution using the `rsn` function
#' Truncate it to specified minimum and maximum values
#'
#' @param n (`integer`) The length of the output vector
#'
#' @param xi (`numeric`) The center of the skewed normal distribution
#'
#' @param omega (`numeric`) The spread of the skewed normal distribution
#'
#' @param alpha (`numeric`) The skewness of the skewed normal distribution
#'
#' @param min (`numeric`) The minimum value to truncate the data to.
#'
#' @param max (`numeric`) The maximum value to truncate the data to.
#'
#' @param seed (`integer`) Optional, a number for setting the seed for reproducible results
#'
#' @return A numeric vector following the skewed normal distribution, truncated to the specified range.
#'
#' @export
#'
rsn_trunc <- function(n, xi, omega, alpha, min, max, seed = NULL) {
  # checks for input validity
  if (min > max) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }
  # first sampling of results
  res <- rsn(n = n, xi = xi, omega = omega, alpha = alpha)
  if (n == 1) {
    # if only one number is sampled
    while (res[1] < min | res[1] > max) {
      res <- rsn(n = 1, xi = xi, omega = omega, alpha = alpha)
    }
    return(res[1])
  } else {
    # re-sample until all values are in the specified range
    while (sum(res < min) + sum(res > max) > 0) {
      res[c(res < min | res > max)] <- rsn(
        n = sum(res < min) + sum(res > max),
        xi = xi,
        omega = omega,
        alpha = alpha
      )
    }
  }
  return(res)
}

#' @title
#' Chopped, skewed normal distribution for time variables
#'
#' @description
#' The function samples from a skewed normal distribution using `rsn` to obtain time of day data in hours.
#' Values greater than 24 are subtracted by 24 (moved to the next day) so that a real time variable is observed.
#'
#' @param nrow (`integer`) The number of data points to sample
#'
#' @param xi (`numeric`) The center of the skewed normal distribution
#'
#' @param omega (`numeric`) The spread of the skewed normal distribution
#'
#' @param alpha (`numeric`) The skewness of the skewed normal distribution
#'
#' @param min (`numeric`) Optional, a minimum value to left truncate the value to; the default value is set to 0.
#'
#' @param max (`numeric`) Optional, a maximum value to right truncate the value to; the default value is set to 48.
#'
#' @param seed (`integer`) Optional, an integer for setting the seed for reproducible results.
#'
#'
#' @return A numeric vector following the specified distribution.
#'
#' @export
#'
sample_time_shifted <- function(nrow, xi, omega, alpha, min = 0, max = 48, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (min > max) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  # sampling of skewed normal distribution
  time_orig <- rsn_trunc(
    n = nrow,
    xi = xi,
    omega = omega,
    alpha = alpha,
    min = min,
    max = max,
  )
  # times greater than 24 hours are after 12am
  # subtract 25 to turn 12am into 00:00
  final_time <- ifelse(time_orig >= 24,
    time_orig - 24,
    time_orig
  )
  return(final_time)
}


#' @title
#' Chopped log normal distribution for time variables
#'
#' @description
#' The function samples from a log normal using `rlnorm` to obtain time of day data in hours.
#' Values greater than 24 are subtracted by 24 (moved to the next day) so that a real time variable is observed.
#'
#' @param nrow (`integer`) The number of data points to sample
#'
#' @param meanlog (`numeric`) The log mean for the distribution
#'
#' @param sdlog (`numeric`) The log standard deviation
#'
#' @param min (`numeric`) Optional, a minimum value to left truncate the value to; the default value is set to 0.
#'
#' @param max (`numeric`) Optional, a maximum value to right truncate the value to; the default value is set to 48.
#'
#' @param seed (`integer`) Optional, an integer for setting the seed for reproducible results.
#'
#'
#' @return A numeric vector following the specified distribution.
#'
#' @export
#'
sample_time_shifted_lnorm <- function(nrow, meanlog, sdlog, min = 0, max = 48, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (min > max) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  sample_dist <- function(nrow, meanlog, sdlog) {
    # sampling of skewed normal distribution
    time_orig <- rlnorm(
      n = nrow,
      meanlog = meanlog,
      sdlog = sdlog
    )
    # times greater than 24 hours are after 12am
    # subtract 25 to turn 12am into 00:00
    final_time <- ifelse(time_orig >= 24,
      time_orig - 24,
      time_orig
    )
    return(final_time)
  }
  res <- sample_dist(nrow, meanlog, sdlog)
  while (sum(res < min) + sum(res > max) > 0) {
    oor_sum <- sum(res < min) + sum(res > max)
    res[c(res < min | res > max)] <- sample_dist(oor_sum, meanlog, sdlog)
  }
  return(res)
}


#' @title
#' Generate a data table with basic inpatient stay information.
#' At the minimum, it will include an encounter and hospital ID,
#' along with other information if `cohort` is included in the input.
#'
#' @description
#' This function creates a data table of simulated encounter IDs and hospital IDs.
#' The creation is either based on user's desired number of encounters and unique hospitals,
#' or based on a given set of encounter IDs. It can be used to create long format data tables
#' where users have control over average repeat frequency.

#'
#' @param nid (`integer`)\cr Optional, number of unique encounter IDs to simulate
#'
#' @param n_hospitals (`integer`)\cr Optional, number of hospitals to simulate and assign to encounter IDs
#'
#' @param avg_repeats (`numeric`)\cr The average number of repeats per row in the final data table
#'
#' @param include_prop (`numeric`)\cr A number between 0 and 1,
#' for the proportion of unique rows in `cohort` to include in the final data table
#'
#' @param cohort (`data.table`)\cr Optional, resembling the GEMINI "admdad" table to build the returned data table from
#'
#' @param by_los (`logical`)\cr Optional, whether to assign more repeats to longer hospital stays or not.
#' Default to FALSE. When TRUE, two additional columns are required in the input `cohort` dataset -
#' `admission_date_time` and `discharge_date_time` for calculating length of stay.
#'
#' @param seed (`integer`)\cr Optional, a number for setting the seed for reproducible results
#'
#' @return (`data.table`)\cr A data.table object with the same columns as `cohort`,
#' but with some rows excluded and/or repeated based on user specifications.
#' If `cohort` is not included, then it will have the following fields:
#' - `genc_id` (`integer`): GEMINI encounter number, may be repeated in multiple rows based on avg_repeats
#' - `hospital_num` (`integer`): An integer identifying the hospital attached to the encounter
#'
#' @export
#'
#' @examples
#' sample_cohort <- data.table::data.table(genc_id = 1:100, hospital_num = rep(1:5, each = 20))
#' generate_id_hospital(cohort = sample_cohort, include_prop = 0.8, avg_repeats = 1.5, by_los = TRUE, seed = 1)
#' generate_id_hospital(nid = 1000, n_hospitals = 10, avg_repeats = 1)
#'
generate_id_hospital <- function(nid = 1000, n_hospitals = 10, avg_repeats = 1.5, include_prop = 1, cohort = NULL, by_los = FALSE, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (is.null(cohort)) {
    # if cohort is not provided, create data.table out of parameters
    hosp_names <- seq(1:n_hospitals)
    hosp_assignment <- sample(hosp_names, nid, replace = TRUE) # this creates randomness in hospital size

    # simulate number of repeats for each id (from Poisson)
    if (avg_repeats != 1) {
      n_repeats <- rpois(nid, lambda = avg_repeats) # random sample number of repeats for each id
      n_repeats[n_repeats == 0] <- 1
    } else {
      n_repeats <- rep(1, nid)
    }
    # expand ids and sites
    id_list <- 1:nid
    id_vector <- rep(id_list, times = n_repeats)
    site_vector <- rep(hosp_assignment, times = n_repeats)

    res <- data.table(genc_id = id_vector, hospital_num = site_vector, stringsAsFactors = FALSE)
  } else {
    include_set <- cohort[sample(seq_len(nrow(cohort)), round(include_prop * nrow(cohort))), ]

    if (avg_repeats == 1) {
      n_repeats <- rep(1, nrow(include_set))
    } else {
      # sample rows with repeats
      n_repeats <- rpois(nrow(include_set), lambda = avg_repeats)
      n_repeats[n_repeats == 0] <- 1
    }

    # may sort by LOS to assign more repeats to longer stays
    if (by_los) {
      # convert date times to a useable format
      include_set$admission_date_time <- as.POSIXct(include_set$admission_date_time,
        format = "%Y-%m-%d %H:%M"
      )
      include_set$discharge_date_time <- as.POSIXct(include_set$discharge_date_time,
        format = "%Y-%m-%d %H:%M"
      )

      include_set$los <- as.numeric(difftime(
        include_set$discharge_date_time,
        include_set$admission_date_time,
        units = "hours"
      ))
      # order from shortest to longest
      include_set <- include_set[order(los)]
      n_repeats <- sort(n_repeats)

      res <- include_set[rep(seq_len(.N), times = n_repeats), ]
    } else {
      # if not sorting by LOS, just assign repeats randomly
      res <- include_set[rep(seq_len(.N), times = n_repeats), ]
    }
  }

  return(res)
}
