# Sample a truncated log normal distribution

Sample from a log normal distribution using the `rlnorm` function
Truncate it to specified minimum and maximum values

## Usage

``` r
rlnorm_trunc(n, meanlog, sdlog, min, max, seed = NULL)
```

## Arguments

- n:

  (`integer`) The length of the output vector

- meanlog:

  (`numeric`) The mean of the log normal distribution

- sdlog:

  (`numeric`) The standard deviation of the log normal distribution

- min:

  (`numeric`) The minimum value to truncate the data to.

- max:

  (`numeric`) The maximum value to truncate the data to.

- seed:

  (`integer`) Optional, a number for setting the seed for reproducible
  results

## Value

A numeric vector following the log normal distribution, truncated to the
specified range.
