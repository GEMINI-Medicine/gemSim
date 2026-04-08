# Chopped log normal distribution for time variables

The function samples from a log normal using `rlnorm` to obtain time of
day data in hours. Values greater than 24 are subtracted by 24 (moved to
the next day) so that a real time variable is observed.

## Usage

``` r
sample_time_shifted_lnorm(nrow, meanlog, sdlog, min = 0, max = 48, seed = NULL)
```

## Arguments

- nrow:

  (`integer`) The number of data points to sample

- meanlog:

  (`numeric`) The log mean for the distribution

- sdlog:

  (`numeric`) The log standard deviation

- min:

  (`numeric`) Optional, a minimum value to left truncate the value to;
  the default value is set to 0.

- max:

  (`numeric`) Optional, a maximum value to right truncate the value to;
  the default value is set to 48.

- seed:

  (`integer`) Optional, an integer for setting the seed for reproducible
  results.

## Value

A numeric vector following the specified distribution.
