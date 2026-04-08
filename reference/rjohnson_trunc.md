# Internal function to sample from the t distribution truncated within a given range

This function samples a numeric vector from the Johnson distribution as
per the params and returns it. This is used to sample CBC lab test
result values.

## Usage

``` r
rjohnson_trunc(n, min, max)
```

## Arguments

- n:

  (`integer`)  
  The length of the final vector

- min:

  (`numeric`)  
  The minimum for truncating the distribution

- max:

  (`numeric`)  
  The maximum for truncating the distribution

## Value

A numeric vector following the specified Johnson distribution.
