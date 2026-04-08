# Sample a truncated skewed normal distribution

Sample from a skewed normal distribution using the `rsn` function
Truncate it to specified minimum and maximum values

## Usage

``` r
rsn_trunc(n, xi, omega, alpha, min, max, seed = NULL)
```

## Arguments

- n:

  (`integer`) The length of the output vector

- xi:

  (`numeric`) The center of the skewed normal distribution

- omega:

  (`numeric`) The spread of the skewed normal distribution

- alpha:

  (`numeric`) The skewness of the skewed normal distribution

- min:

  (`numeric`) The minimum value to truncate the data to.

- max:

  (`numeric`) The maximum value to truncate the data to.

- seed:

  (`integer`) Optional, a number for setting the seed for reproducible
  results

## Value

A numeric vector following the skewed normal distribution, truncated to
the specified range.
