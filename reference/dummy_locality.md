# Generate simulated locality variables data

This function creates a synthetic dataset with a subset of variables
that are contained in the GEMINI "locality-variables" table, as seen in
[GEMINI Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/).

Specifically, the function simulates dissemination area IDs (da21uid)
based on Canadian census data for a user-specified set of mock encounter
and hospital IDs. To mimic GEMINI data characteristics, the majority of
simulated area IDs are drawn from Ontario and are clustered by hospital.

## Usage

``` r
dummy_locality(
  nid = 1000,
  n_hospitals = 10,
  cohort = NULL,
  da21uid = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Number of unique encounter IDs to simulate. In this data table, each
  ID occurs once. It is optional when `cohort` is provided.

- n_hospitals:

  (`integer`)  
  Number of hospitals in simulated dataset. It is optional when `cohort`
  is provided.

- cohort:

  (`data.frame or data.table`) Optional, an existing data frame or data
  table similar to `admdad` in GEMINI with at least the following
  columns:

  - `genc_id` (`integer`): Mock encounter ID, integers starting from 1
    or from `cohort`

  - `hospital_num` (`integer`): Mock hospital ID, integers starting from
    1 or from `cohort` If `cohort` is provided, `nid` and `n_hospital`
    inputs are not used.

- da21uid:

  (`integer` or `vector`)  
  Optional, allows the user to customize which dissemination area ID(s)
  to include in the output.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible
  results.

## Value

(`data.table`)  
A data.table object similar to the "locality_variables" table that
contains the following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or
  from `cohort` if provided

- `da21uid` (`integer`): Dissemination area ID based on 2021 Canadian
  census data using PCCF Version 8A

## Examples

``` r
dummy_locality(nid = 1000, n_hospitals = 10)
#>       genc_id hospital_num  da21uid
#>         <int>        <int>    <num>
#>    1:       1            4 35390244
#>    2:       2            9 35560189
#>    3:       3            3 35250240
#>    4:       4            3 35250313
#>    5:       5           10 35100280
#>   ---                              
#>  996:     996            6 35250180
#>  997:     997           10 35100135
#>  998:     998            4 35430562
#>  999:     999            6 35260194
#> 1000:    1000            5 35370216
```
