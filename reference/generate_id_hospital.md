# Generate a data table with basic inpatient stay information. At the minimum, it will include an encounter and hospital ID, along with other information if `cohort` is included in the input.

This function creates a data table of simulated encounter IDs and
hospital IDs. The creation is either based on user's desired number of
encounters and unique hospitals, or based on a given set of encounter
IDs. It can be used to create long format data tables where users have
control over average repeat frequency.

## Usage

``` r
generate_id_hospital(
  nid = 1000,
  n_hospitals = 10,
  avg_repeats = 1.5,
  include_prop = 1,
  cohort = NULL,
  by_los = FALSE,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Optional, number of unique encounter IDs to simulate

- n_hospitals:

  (`integer`)  
  Optional, number of hospitals to simulate and assign to encounter IDs

- avg_repeats:

  (`numeric`)  
  The average number of repeats per row in the final data table

- include_prop:

  (`numeric`)  
  A number between 0 and 1, for the proportion of unique rows in
  `cohort` to include in the final data table

- cohort:

  (`data.table`)  
  Optional, resembling the GEMINI "admdad" table to build the returned
  data table from

- by_los:

  (`logical`)  
  Optional, whether to assign more repeats to longer hospital stays or
  not. Default to FALSE. When TRUE, two additional columns are required
  in the input `cohort` dataset - `admission_date_time` and
  `discharge_date_time` for calculating length of stay.

- seed:

  (`integer`)  
  Optional, a number for setting the seed for reproducible results

## Value

(`data.table`)  
A data.table object with the same columns as `cohort`, but with some
rows excluded and/or repeated based on user specifications. If `cohort`
is not included, then it will have the following fields:

- `genc_id` (`integer`): Mock encounter number, may be repeated in
  multiple rows based on avg_repeats

- `hospital_num` (`integer`): Mock hospital ID number

## Examples

``` r
sample_cohort <- data.table::data.table(genc_id = 1:100, hospital_num = rep(1:5, each = 20))
generate_id_hospital(cohort = sample_cohort, include_prop = 0.8, avg_repeats = 1.5, by_los = TRUE, seed = 1)
#>      genc_id hospital_num admission_date_time discharge_date_time   los
#>        <int>        <int>              <POSc>              <POSc> <num>
#>   1:      68            4                <NA>                <NA>    NA
#>   2:      39            2                <NA>                <NA>    NA
#>   3:       1            1                <NA>                <NA>    NA
#>   4:      34            2                <NA>                <NA>    NA
#>   5:      87            5                <NA>                <NA>    NA
#>  ---                                                                   
#> 129:      19            1                <NA>                <NA>    NA
#> 130:      19            1                <NA>                <NA>    NA
#> 131:      19            1                <NA>                <NA>    NA
#> 132:      19            1                <NA>                <NA>    NA
#> 133:      19            1                <NA>                <NA>    NA
generate_id_hospital(nid = 1000, n_hospitals = 10, avg_repeats = 1)
#>       genc_id hospital_num
#>         <int>        <int>
#>    1:       1            4
#>    2:       2            2
#>    3:       3            1
#>    4:       4            7
#>    5:       5            9
#>   ---                     
#>  996:     996            9
#>  997:     997            6
#>  998:     998            6
#>  999:     999            6
#> 1000:    1000            1
```
