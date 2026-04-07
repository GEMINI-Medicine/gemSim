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
NULL

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
#' @keywords internal
#'
rlnorm_trunc <- function(n, meanlog, sdlog, min, max, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (any(min > max)) {
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
#' @keywords internal

rnorm_trunc <- function(n, mean, sd, min, max, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (any(min > max)) {
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
#' @importFrom sn rsn
#'
#' @keywords internal
#'
rsn_trunc <- function(n, xi, omega, alpha, min, max, seed = NULL) {
  # checks for input validity
  if (any(min > max)) {
    stop("The min is greater than the max. Invalid sampling range provided - stopping.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }
  # first sampling of results
  res <- rsn(n = n, xi = xi, omega = omega, alpha = alpha)
  if (n == 1) {
    # if only one number is sampled
    while (res[1] < min || res[1] > max) {
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
#' @return A numeric vector following the specified distribution.
#'
#' @keywords internal
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
  # subtract 24 to turn 12am into 00:00
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
#' @return A numeric vector following the specified distribution.
#'
#' @keywords internal
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
    res[c(res < min || res > max)] <- sample_dist(oor_sum, meanlog, sdlog)
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
#' - `genc_id` (`integer`): Mock encounter number, may be repeated in multiple rows based on avg_repeats
#' - `hospital_num` (`integer`): Mock hospital ID number
#'
#' @examples
#' sample_cohort <- data.table::data.table(genc_id = 1:100, hospital_num = rep(1:5, each = 20))
#' generate_id_hospital(cohort = sample_cohort, include_prop = 0.8, avg_repeats = 1.5, by_los = TRUE, seed = 1)
#' generate_id_hospital(nid = 1000, n_hospitals = 10, avg_repeats = 1)
#'
#' @export
#'
generate_id_hospital <- function(
  nid = 1000, n_hospitals = 10, avg_repeats = 1.5, include_prop = 1, cohort = NULL, by_los = FALSE, seed = NULL
) {
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
      tryCatch(
        {
          include_set$admission_date_time <- Rgemini::convert_dt(include_set$admission_date_time, "ymd HM")
        },
        warning = function(w) {
          stop(conditionMessage(w))
        }
      )

      tryCatch(
        {
          include_set$discharge_date_time <- Rgemini::convert_dt(include_set$discharge_date_time, "ymd HM")
        },
        warning = function(w) {
          stop(conditionMessage(w))
        }
      )

      include_set$los <- as.numeric(difftime(
        include_set$discharge_date_time,
        include_set$admission_date_time,
        units = "hours"
      ))
      # order from shortest to longest
      include_set <- include_set[order(los)]
      n_repeats <- sort(n_repeats)
    }
    # In both cases, assign repeats
    res <- include_set[rep(seq_len(.N), times = n_repeats), ]
  }

  res[, genc_id := as.integer(genc_id)]
  res[, hospital_num := as.integer(hospital_num)]
  return(res)
}

#' @title
#' Internal function to sample from the t distribution truncated within a given range
#'
#' @description
#' This function samples a numeric vector as per the params and returns it.
#' This is used to sample electrolyte lab test result values.
#'
#' @param n (`integer`)\cr The length of the final vector
#'
#' @param df (`numeric`)\cr The degrees of freedom for the distribution
#'
#' @param sd (`numeric`)\cr The standard deviation for the distribution
#'
#' @param mean (`numeric`)\cr The mean of the distribution
#'
#' @param min (`numeric`)\cr The minimum for truncating the distribution
#'
#' @param max (`numeric`)\cr The maximum for truncating the distribution
#'
#' @return A numeric vector following the specified t distribution.
#'
#' @import Rgemini
#' @keywords internal
rt_trunc <- function(n, df, sd, mean, min, max) {
  # check inputs
  Rgemini:::check_input(n, "integer")
  Rgemini:::check_input(list(df, sd, mean, min, max), "numeric")
  if (min > max) {
    stop("The min is less than the max. Stopping.")
  }

  # initial distribution with given parameters
  res <- rt(n, df = df) * sd + mean
  # re-sample values out of range
  while (sum(res < min) + sum(res > max) > 0) {
    n2 <- sum(res < min) + sum(res > max)
    res[c(res < min | res > max)] <- rt(n2, df = df) * sd + mean
  }
  return(res)
}

#' @title
#' Internal function to sample from the t distribution truncated within a given range
#'
#' @description
#' This function samples a numeric vector from the Johnson distribution as per the params and returns it.
#' This is used to sample CBC lab test result values.
#'
#' @param n (`integer`)\cr The length of the final vector
#'
#' @param min (`numeric`)\cr The minimum for truncating the distribution
#'
#' @param max (`numeric`)\cr The maximum for truncating the distribution
#'
#' @return A numeric vector following the specified Johnson distribution.
#'
#' @import Rgemini
#' @importFrom SuppDists rJohnson
#' @keywords internal
rjohnson_trunc <- function(n, min, max) {
  # check inputs
  Rgemini:::check_input(n, "integer")
  Rgemini:::check_input(c(min, max), "numeric")
  if (min > max) {
    stop("The min is less than the max. Stopping.")
  }

  # the parameters of the distribution of lab results for CBC
  fit_j_cbc <- list(
    gamma = -0.8,
    delta = 2,
    xi = -7.7,
    lambda = 189,
    type = "SB"
  )

  # inital distribution
  res <- rJohnson(n, fit_j_cbc)

  # re-sample values out of range
  while (sum(res < min) + sum(res > max) > 0) {
    n2 <- sum(res < min) + sum(res > max)
    res[res < min | res > max] <- rJohnson(n2, fit_j_cbc)
  }
  return(res)
}
