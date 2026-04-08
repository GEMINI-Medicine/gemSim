# Generate simulated erintervention data

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "erintervention" table, as seen in [GEMINI
Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/).

This function simulates data with CCI codes detailing the type of
intervention used in the emergency department.

## Usage

``` r
dummy_erintervention_mri(
  nid = 1000,
  n_hospitals = 10,
  int_code = NULL,
  cohort = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Number of unique encounter IDs to simulate. Encounter IDs may repeat,
  resulting in a data table with more rows than `nid`. Ignored when
  `cohort` is provided.

- n_hospitals:

  (`integer`)  
  Number of hospitals to simulate. Ignored when `cohort` is provided.

- int_code:

  (`character or vector`)  
  Optional, user-specified intervention codes to include in the returned
  data table. It needs to be a valid MRI code.

- cohort:

  (`data.frame or data.table`)  
  Optional, data frame or data table containing the fields:

  - `genc_id` (`integer`): Mock encounter ID number

  - `hospital_num` (`integer`): Mock hospital ID number When `cohort` is
    not NULL, `nid` and `n_hospitals` are ignored.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible results

## Value

(`data.table`)  
A data.table object similar to the "ipintervention" table that contains
the columns:

- `genc_id` (`integer`): Mock encounter ID number; integers starting
  from 1 or from `cohort`

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or from `cohort`

- `intervention_code` (`character`): Valid CCI code(s) describing the
  services (procedures/intervention) performed for or on behalf of the
  patient to improve health. For this simulation, it will be for an MRI.

## Examples

``` r
dummy_erintervention_mri(nid = 1000, int_code = c("3AN40VA", "3SC40WC"))
#>       genc_id hospital_num intervention_code
#>         <int>        <int>            <char>
#>    1:       1            8           3AN40VA
#>    2:       1            8           3SC40WC
#>    3:       2            7           3SC40WC
#>    4:       2            7           3SC40WC
#>    5:       3            1           3AN40VA
#>   ---                                       
#> 2054:     999           10           3AN40VA
#> 2055:    1000            7           3AN40VA
#> 2056:    1000            7           3SC40WC
#> 2057:    1000            7           3SC40WC
#> 2058:    1000            7           3SC40WC
dummy_erintervention_mri(cohort = dummy_admdad(), int_code = "3AN40VA")
#>       genc_id hospital_num intervention_code
#>         <int>        <int>            <char>
#>    1:       1            8           3AN40VA
#>    2:       1            8           3AN40VA
#>    3:       1            8           3AN40VA
#>    4:       2            2           3AN40VA
#>    5:       3            3           3AN40VA
#>   ---                                       
#> 1985:     998            3           3AN40VA
#> 1986:     999           10           3AN40VA
#> 1987:     999           10           3AN40VA
#> 1988:     999           10           3AN40VA
#> 1989:    1000            3           3AN40VA

dummy_erintervention_mri(nid = 100, n_hospitals = 2, seed = 1)
#>      genc_id hospital_num intervention_code
#>        <int>        <int>            <char>
#>   1:       1            1           3SC40WC
#>   2:       1            1           3ER40VA
#>   3:       2            2           3SC40WC
#>   4:       3            1           3AN40VA
#>   5:       4            1           3AN40VA
#>  ---                                       
#> 208:      98            2           3SC40VA
#> 209:      99            2           3ER40VA
#> 210:     100            1           3YM40VA
#> 211:     100            1           3ID40VA
#> 212:     100            1           3SC40VA
```
