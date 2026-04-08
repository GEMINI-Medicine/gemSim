# Sample SCU admission and discharge date times by genc_id.

The "ipscu" data table is a long format data table with multiple repeats
for each genc_id. SCU admission and discharge date times must be sampled
in such a way that SCU stays occur between inpatient admission and
discharge dates and times, and that if a patient has multiple SCU stays,
they do not overlap. This is a helper function for `dummy_ipscu`.

## Usage

``` r
sample_scu_date_time(
  scu_cohort,
  use_ip_dates = TRUE,
  start_date = NULL,
  end_date = NULL,
  seed = NULL
)
```

## Arguments

- scu_cohort:

  (`data.table`) The dummy data table requiring the addition of SCU
  admission and discharge date time columns. It requires the following
  columns:

  - `genc_occurrence` (`integer`): for each `genc_id`, its numbered
    appearance in the data table, i.e. 1, 2, 3, ...

  - `genc_id` (`integer`): Mock encounter ID; integers starting from 1

  - `hospital_num` (`integer`): Mock hospital ID number; integers
    starting from 1 If `use_ip_dates` is TRUE, it will also require the
    following columns:

  - `admission_date_time` (`POSIXct`): the date and time of IP admission
    in YYYY-MM-DD HH:MM format

  - `discharge_date_time` (`POSIXct`): the date and time of IP discharge
    in YYYY-MM-DD HH:MM format

- use_ip_dates:

  (`logical`) Optional, whether the table `scu_cohort` contains
  information about inpatient admission and discharge date times. If
  TRUE, the function will sample SCU data based on these date times and
  if not, it will sample at random.

- start_date:

  (`Date`) Optional, the earliest date in the range for the SCU
  admissions in the dummy data table. It is not used if `use_ip_dates`
  is TRUE.

- end_date:

  (`Date`) Optional, the latest date in the range for the SCU admissions
  in the dummy data table. It is not used if `use_ip_dates` is TRUE.

- seed:

  (`integer`) Optional, an integer for setting the seed for reproducible
  results.

## Value

(`data.table`) A copy of the input, `scu_cohort`, will be returned. It
will contain the same fields, with the addition of:

- `scu_admit_date_time` (`character`): the date and time of admission to
  the SCU

- `scu_discharge_date_time` (`character`): the date and time of
  discharge from the SCU
