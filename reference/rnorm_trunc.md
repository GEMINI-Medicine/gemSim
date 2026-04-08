# Sample a truncated normal distribution

Sample from a normal distribution using the `rnorm` function but
truncate it to specified minimum and maximum values

## Usage

``` r
rnorm_trunc(n, mean, sd, min, max, seed = NULL)
```

## Arguments

- n:

  (`integer`) The length of the output vector

- mean:

  (`numeric`) The mean of the normal distribution

- sd:

  (`numeric`) The standard deviation of the normal distribution

- min:

  (`numeric`) The minimum value to truncate the data to.

- max:

  (`numeric`) The maximum value to truncate the data to.

- seed:

  (`integer`) Optional, a number for setting the seed for reproducible
  results

## Value

A numeric vector following the normal distribution, truncated to the
specified range.
