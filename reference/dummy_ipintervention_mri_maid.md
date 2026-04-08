# Generate simulated ipintervention data

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "ipintervention" table, as seen in [GEMINI
Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/).

This function simulates data with CCI codes detailing the type of
intervention that occurred in an inpatient stay.

## Usage

``` r
dummy_ipintervention_mri_maid(
  nid = 1000,
  n_hospitals = 10,
  cohort = NULL,
  int_code = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Number of unique encounter IDs to simulate. Encounter IDs may repeat,
  resulting in a data table with more rows than `nid`. It is not used if
  `cohort` is provided.

- n_hospitals:

  (`integer`)  
  Number of unique hospitals to simulate. It is not used if `cohort` is
  provided.

- cohort:

  (`data.frame or data.table`)  
  Optional, data frame or data table containing the columns:

  - `genc_id` (`integer`): Mock encounter ID number

  - `hospital_num` (`integer`): Mock hospital ID number When `cohort` is
    not NULL, `nid` and `n_hospitals` are ignored.

- int_code:

  (`character`)  
  Optional, user-specified intervention codes to include in the returned
  data table. It needs to be a valid MRI or MAID code.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible results

## Value

(`data.table`)  
A data.table object similar to the "ipintervention" table that contains
the columns:

- `genc_id` (`integer`): Mock encounter ID number; integers starting
  from 1 or provided from `cohort`

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or provided from `cohort`

- `intervention_code` (`character`): Valid CCI code(s) describing the
  services (procedures/intervention) performed for or on behalf of the
  patient to improve health. For this simulation, it will either be for
  an MRI or medical assistance in dying (MAID)

## Examples

``` r
dummy_ipintervention_mri_maid(nid = 1000, int_code = c("3AN40VA", "3SC40WC"))
#>       genc_id hospital_num intervention_code
#>         <int>        <int>            <char>
#>    1:       1            4           3AN40VA
#>    2:       2            3           3AN40VA
#>    3:       3            7           3SC40WC
#>    4:       4            2           3AN40VA
#>    5:       4            2           3SC40WC
#>   ---                                       
#> 1495:     997            7           3AN40VA
#> 1496:     998            2           3AN40VA
#> 1497:     999            5           3SC40WC
#> 1498:    1000            5           3SC40WC
#> 1499:    1000            5           3SC40WC
dummy_ipintervention_mri_maid(nid = 1000, int_code = "3SC40WC")
#>       genc_id hospital_num intervention_code
#>         <int>        <int>            <char>
#>    1:       1            2           3SC40WC
#>    2:       2            2           3SC40WC
#>    3:       3            5           3SC40WC
#>    4:       4            5           3SC40WC
#>    5:       4            5           3SC40WC
#>   ---                                       
#> 1512:     998            8           3SC40WC
#> 1513:     999            7           3SC40WC
#> 1514:     999            7           3SC40WC
#> 1515:     999            7           3SC40WC
#> 1516:    1000            1           3SC40WC

dummy_ipintervention_mri_maid(nid = 1000, n_hospitals = 10, seed = 1)
#>       genc_id hospital_num intervention_code
#>         <int>        <int>            <char>
#>    1:       1            9           3GY40VA
#>    2:       2            4           3ER40WC
#>    3:       3            7           3SC40VA
#>    4:       4            1           3AN40VA
#>    5:       5            2           3SC40VA
#>   ---                                       
#> 1495:     998            7           3OT40VA
#> 1496:     998            7           3AN40VA
#> 1497:     999            8           3OT40WC
#> 1498:    1000            5           3SC40VA
#> 1499:    1000            5           3ER40VA
```
