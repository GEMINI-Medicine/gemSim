# Generate simulated physicians data

This function creates a synthetic dataset with a subset of variables
that are contained in the GEMINI "physicians" table, as seen in [GEMINI
Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/).

## Usage

``` r
dummy_physicians(nid = 1000, n_hospitals = 10, cohort = NULL, seed = NULL)
```

## Arguments

- nid:

  (`integer`)  
  Number of unique encounter IDs to simulate. Optional if `cohort` is
  provided.

- n_hospitals:

  (`integer`)  
  Number of hospitals in simulated dataset. Optional if `cohort` is
  provided.

- cohort:

  (`data.frame or data.table`) Optional, an existing data table or data
  frame similar to `admdad` in GEMINI with at least the following
  columns:

  - `genc_id` (`integer`): Mock encounter ID; integers starting from 1

  - `hospital_num` (`integer`): Mock hospital ID; integers starting from
    1 If `cohort` is provided, `nid` and `n_hospitals` inputs are not
    used.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible
  results.

## Value

(`data.table`)  
A data.table object similar to the "physicians" table that contains the
following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or
  from `cohort` if provided

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or from `cohort` if provided

- `admitting_physician_gim` (`logical`): Whether the admitting physician
  attends a general medicine ward

- `discharging_physician_gim` (`logical`): Whether the discharging
  physician attends a general medicine ward

- `adm_phy_cpso_mapped` (`integer`): Synthetic mock CPSO number (with
  prefix 'SYN\_') of admitting physician

- `mrp_cpso_mapped` (`integer`): Synthetic mock CPSO number (with prefix
  'SYN\_') of most responsible physician (MRP)

- `dis_phy_cpso_mapped` (`integer`): Synthetic mock CPSO number (with
  prefix 'SYN\_') of discharging physician

## Examples

``` r
dummy_physicians(nid = 1000, n_hospitals = 10, seed = 1)
#>       genc_id hospital_num admitting_physician_gim discharging_physician_gim
#>         <int>        <int>                  <char>                    <char>
#>    1:       1            9                    <NA>                      <NA>
#>    2:       2            4                       y                      <NA>
#>    3:       3            7                    <NA>                      <NA>
#>    4:       4            1                    <NA>                         n
#>    5:       5            2                    <NA>                      <NA>
#>   ---                                                                       
#>  996:     996            8                    <NA>                      <NA>
#>  997:     997            6                       n                      <NA>
#>  998:     998            7                    <NA>                      <NA>
#>  999:     999            8                    <NA>                      <NA>
#> 1000:    1000            5                    <NA>                      <NA>
#>       adm_phy_cpso_mapped mrp_cpso_mapped
#>                    <char>          <char>
#>    1:           SYN_57866      SYN_122409
#>    2:          SYN_296817      SYN_192439
#>    3:           SYN_79648       SYN_79648
#>    4:          SYN_187582       SYN_92749
#>    5:          SYN_149054      SYN_149054
#>   ---                                    
#>  996:           SYN_50461       SYN_50461
#>  997:          SYN_146964      SYN_176082
#>  998:           SYN_56688       SYN_84272
#>  999:          SYN_234758      SYN_234758
#> 1000:          SYN_256618       SYN_70285
dummy_physicians(cohort = dummy_admdad(), seed = 2)
#>       genc_id hospital_num admitting_physician_gim discharging_physician_gim
#>         <int>        <int>                  <char>                    <char>
#>    1:       1            7                    <NA>                      <NA>
#>    2:       2            1                       y                         n
#>    3:       3            7                    <NA>                      <NA>
#>    4:       4            4                    <NA>                         n
#>    5:       5            6                       n                      <NA>
#>   ---                                                                       
#>  996:     996            9                    <NA>                      <NA>
#>  997:     997            4                    <NA>                         y
#>  998:     998            1                    <NA>                         n
#>  999:     999            2                    <NA>                         y
#> 1000:    1000            6                    <NA>                      <NA>
#>       adm_phy_cpso_mapped mrp_cpso_mapped
#>                    <char>          <char>
#>    1:          SYN_153171      SYN_153171
#>    2:          SYN_163375      SYN_163375
#>    3:          SYN_165605      SYN_165605
#>    4:           SYN_25387       SYN_10450
#>    5:          SYN_127182       SYN_52165
#>   ---                                    
#>  996:          SYN_235527      SYN_235527
#>  997:          SYN_280765      SYN_177097
#>  998:          SYN_249768       SYN_43746
#>  999:          SYN_191383      SYN_191383
#> 1000:           SYN_18652      SYN_177097
```
