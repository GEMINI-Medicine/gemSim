# Internal function to sample from the t distribution truncated within a given range

This function samples a numeric vector as per the params and returns it.
This is used to sample electrolyte lab test result values.

## Usage

``` r
rt_trunc(n, df, sd, mean, min, max)
```

## Arguments

- n:

  (`integer`)  
  The length of the final vector

- df:

  (`numeric`)  
  The degrees of freedom for the distribution

- sd:

  (`numeric`)  
  The standard deviation for the distribution

- mean:

  (`numeric`)  
  The mean of the distribution

- min:

  (`numeric`)  
  The minimum for truncating the distribution

- max:

  (`numeric`)  
  The maximum for truncating the distribution

## Value

A numeric vector following the specified t distribution.
