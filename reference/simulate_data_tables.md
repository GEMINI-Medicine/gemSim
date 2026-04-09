# Data simulation wrapper function

A wrapper that coordinates table-specific simulation functions to
generate relational synthetic tables that reflect the inter-table
structure of the GEMINI data. Users specify which tables to generate and
provide shared inputs such as the number of encounters, hospitals, and
the time period. The function returns a list of simulated `data.table`s
with inter-table relationships handled automatically. Specifically, the
`admdad` table is generated first and provides the encounter IDs used as
the primary key for subsequent table. All tables are simulated to mirror
their real-world linkage patterns to the `admdad` table in GEMINI data.
Available tables include:

- `admdad`

- `ipscu`

- `er`

- `erdiagnosis`

- `ipdiagnosis`

- `locality_variables`

- `lab` \*: currently simulates CBC or electrolyte tests only

- `radiology` \*: currently simulates MRI, CT, and ultrasound imaging
  data only

- `erintervention` \*: currently simulates intervention MRI

- `ipintervention` \*: currently simulates interventions MRI and MAID
  only

- `transfusion`: transfusion information about blood product and issue
  date times

- `physicians`

See [GEMINI Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/) for table
definitions and individual simulation function documentation for
details.

## Usage

``` r
simulate_data_tables(
  tables,
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  ...
)
```

## Arguments

- tables:

  (`vector`)  
  A `character` vector listing the names of required data tables

- nid:

  (`integer`)  
  The number of mock encounter IDs to simulate.

- n_hospitals:

  (`integer`)  
  The number of mock hospital ID numbers to simulate.

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy). The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided.

- ...:

  Additional arguments that may be passed into data simulation
  functions. These arguments are normally used to customize table
  outputs.

## Value

(`list`)  
A list containing `data.table` objects, one per entry in the `tables`
parameter where entries are valid GEMINI data tables. May include:
`admdad`, `ipscu`, `er`, `erdiagnosis`, `ipdiagnosis`,
`locality_variables`, `lab`, `radiology`, `erintervention`,
`ipintervention`, `transfusion`, `physicians`

## Details

Wrapper function that calls data simulation functions to create a
synthetic, customizable database that reflects the inter-table relations
of the GEMINI database.

## Examples

``` r
simulate_data_tables(c("admdad", "ipscu", "er"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            2    2017-11-08 13:57    2017-11-09 13:15    57      F
#>    2:       2            1    2023-04-17 15:53    2023-04-18 15:41    75      M
#>    3:       3            5    2018-12-19 11:00    2019-01-20 23:21    67      M
#>    4:       4            1    2016-02-16 05:23    2016-02-19 00:04    56      M
#>    5:       5            3    2016-04-17 23:15    2016-04-18 17:51    81      F
#>   ---                                                                          
#>  996:     996            3    2023-04-11 11:05    2023-04-14 00:09    66      F
#>  997:     997            7    2017-04-10 14:08    2017-04-16 09:45    44      F
#>  998:     998           10    2019-08-28 05:14    2019-09-10 15:44    80      F
#>  999:     999            2    2022-05-10 08:39    2022-05-29 11:00    46      F
#> 1000:    1000            7    2023-07-05 11:57    2023-07-06 21:46    78      M
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                     5                         n                  0
#>    2:                     5                         n                 NA
#>    3:                    10                         N                  0
#>    4:                     5                         y                  1
#>    5:                     4                     false                  0
#>   ---                                                                   
#>  996:                     4                     false                  0
#>  997:                     5                         0                  0
#>  998:                     5                     false                  0
#>  999:                    72                         n                  0
#> 1000:                    10                         0                  0
#> 
#> $ipscu
#>      hospital_num genc_id scu_admit_date_time scu_discharge_date_time icu_flag
#>             <int>   <int>              <char>                  <char>   <lgcl>
#>   1:            3      11    2022-05-02 14:19        2022-05-05 14:34     TRUE
#>   2:            3      11    2022-05-09 04:51        2022-05-09 21:33     TRUE
#>   3:            1      30    2020-07-11 14:10        2020-07-11 16:06    FALSE
#>   4:            7      31    2015-04-25 23:52        2015-04-30 18:55    FALSE
#>   5:            6      34    2017-08-25 14:30        2017-08-26 11:12    FALSE
#>  ---                                                                          
#> 270:            8     990    2015-08-12 19:09        2015-08-17 19:23    FALSE
#> 271:           10     995    2015-06-12 17:27        2015-06-12 23:35    FALSE
#> 272:           10     995    2015-06-20 11:03        2015-06-21 16:32     TRUE
#> 273:           10     998    2019-08-28 16:39        2019-08-29 13:48     TRUE
#> 274:           10     998    2019-08-29 13:48        2019-08-29 14:04     TRUE
#>      scu_unit_number
#>                <num>
#>   1:              30
#>   2:              60
#>   3:              93
#>   4:              93
#>   5:              95
#>  ---                
#> 270:              93
#> 271:              90
#> 272:              50
#> 273:              20
#> 274:              25
#> 
#> $er
#>      genc_id hospital_num triage_date_time
#>        <int>        <int>           <char>
#>   1:       1            2 2017-11-08 09:38
#>   2:       2            1 2023-04-17 11:50
#>   3:       3            5 2018-12-18 13:49
#>   4:       6            6 2017-09-22 16:34
#>   5:       7            4 2023-09-21 15:51
#>  ---                                      
#> 696:     995           10 2015-06-11 18:49
#> 697:     996            3 2023-04-10 22:46
#> 698:     997            7 2017-04-10 12:21
#> 699:     999            2 2022-05-09 09:18
#> 700:    1000            7 2023-07-04 15:50
#> 

simulate_data_tables(c("admdad", "transfusion"), blood_product_list = c("4023915", "4137859"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            8    2016-01-25 08:53    2016-01-27 21:29    94      M
#>    2:       2            9    2023-04-19 09:16    2023-04-25 02:39    78      F
#>    3:       3            1    2018-01-01 14:51    2018-01-03 07:10    66      F
#>    4:       4            9    2023-10-10 07:48    2023-10-22 10:22    69      F
#>    5:       5            2    2019-06-19 11:29    2019-06-30 08:08    82      M
#>   ---                                                                          
#>  996:     996            5    2019-05-16 11:02    2019-05-19 13:46    71      F
#>  997:     997            8    2018-08-16 12:30    2018-08-18 21:42    75      F
#>  998:     998            9    2022-12-09 08:31    2022-12-13 20:48    36      M
#>  999:     999            4    2023-12-07 13:33    2023-12-12 14:56    69      F
#> 1000:    1000           10    2019-01-04 09:25    2019-01-06 18:37    55      F
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                    10                         N                 NA
#>    2:                    10                        99                  3
#>    3:                    10                         N                  0
#>    4:                     5                         0                  0
#>    5:                     4                     FALSE                  0
#>   ---                                                                   
#>  996:                     4                     false                  0
#>  997:                     4                         N                 NA
#>  998:                     5                         0                  0
#>  999:                     5                         N                  0
#> 1000:                    10                         0                  0
#> 
#> $transfusion
#>      genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>        <int>        <int>           <char>                    <char>
#>   1:       3            1 2018-01-02 13:08                   4137859
#>   2:       3            1 2018-01-02 20:29                   4137859
#>   3:       3            1 2018-01-02 12:02                   4137859
#>   4:       3            1 2018-01-02 10:30                   4137859
#>   5:       3            1 2018-01-02 12:04                   4137859
#>  ---                                                                
#> 527:     996            5 2019-05-18 21:55                   4023915
#> 528:     996            5 2019-05-18 01:50                   4023915
#> 529:     996            5 2019-05-17 10:28                   4023915
#> 530:     996            5 2019-05-18 12:23                   4137859
#> 531:     996            5 2019-05-19 10:03                   4023915
#>             blood_product_raw
#>                        <char>
#>   1: SAGM Red blood cells, LR
#>   2: SAGM Red blood cells, LR
#>   3: SAGM Red blood cells, LR
#>   4: SAGM Red blood cells, LR
#>   5: SAGM Red blood cells, LR
#>  ---                         
#> 527:                  Albumin
#> 528:                  Albumin
#> 529:                  Albumin
#> 530: SAGM Red blood cells, LR
#> 531:                  Albumin
#> 

simulate_data_tables(c("er", "erintervention", "erdiagnosis"), int_code = c("3AN40VA", "3SC40WC"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            9    2022-12-10 11:03    2022-12-26 08:43    78      F
#>    2:       2            3    2016-03-17 11:07    2016-03-21 03:11    87      M
#>    3:       3            5    2015-10-27 01:47    2015-10-29 04:33    88      F
#>    4:       4            6    2023-02-02 14:18    2023-02-09 00:33    63      F
#>    5:       5           10    2020-07-08 10:51    2020-07-25 05:06    36      M
#>   ---                                                                          
#>  996:     996            1    2017-11-12 10:20    2017-11-14 21:41    85      F
#>  997:     997            3    2017-12-08 10:11    2017-12-11 00:10    90      M
#>  998:     998           10    2020-07-26 08:40    2020-07-28 02:43    49      F
#>  999:     999            2    2017-02-28 10:28    2017-03-01 15:46    85      M
#> 1000:    1000            1    2015-10-12 08:40    2015-10-13 02:40    87      F
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                     4                      <NA>                  0
#>    2:                    30                      <NA>                  0
#>    3:                    30                      <NA>                  0
#>    4:                     5                      <NA>                 NA
#>    5:                     5                      <NA>                 NA
#>   ---                                                                   
#>  996:                    72                      <NA>                  0
#>  997:                    10                      <NA>                  0
#>  998:                     5                       ALC                  2
#>  999:                     5                         Y                  1
#> 1000:                     5                      <NA>                  0
#> 
#> $er
#>      genc_id hospital_num triage_date_time
#>        <int>        <int>           <char>
#>   1:       1            9 2022-12-09 07:45
#>   2:       2            3 2016-03-17 06:54
#>   3:       3            5 2015-10-26 12:44
#>   4:       4            6 2023-02-02 09:46
#>   5:       7            5 2022-01-24 07:30
#>  ---                                      
#> 696:     995            5 2021-12-27 18:36
#> 697:     997            3 2017-12-07 08:59
#> 698:     998           10 2020-07-25 12:46
#> 699:     999            2 2017-02-27 18:53
#> 700:    1000            1 2015-10-11 17:16
#> 
#> $erintervention
#>     genc_id hospital_num intervention_code
#>       <int>        <int>            <char>
#>  1:     445            2           3SC40WC
#>  2:     445            2           3SC40WC
#>  3:     445            2           3SC40WC
#>  4:     445            2           3SC40WC
#>  5:     555            7           3SC40WC
#>  6:     555            7           3SC40WC
#>  7:     555            7           3SC40WC
#>  8:     612            6           3AN40VA
#>  9:     612            6           3SC40WC
#> 10:     631            4           3AN40VA
#> 11:     631            4           3AN40VA
#> 12:     631            4           3SC40WC
#> 13:     631            4           3SC40WC
#> 14:     670            9           3SC40WC
#> 15:     898            5           3SC40WC
#> 
#> $erdiagnosis
#>       genc_id hospital_num er_diagnosis_code er_diagnosis_type
#>         <int>        <int>            <char>            <char>
#>    1:       1            9              M060                  
#>    2:       1            9              B743                 M
#>    3:       1            9              L558                  
#>    4:       2            3              T357                 M
#>    5:       2            3              N140                  
#>   ---                                                         
#> 2777:     999            2              J703                  
#> 2778:     999            2               O72                  
#> 2779:     999            2              F655                  
#> 2780:    1000            1              M111                 M
#> 2781:    1000            1              S015                  
#> 
```
