# tools/libs/datetime.sh

Handle date/time functionality

* [gen_date()](#gen_date)
* [get_day_of_year()](#get_day_of_year)
* [gen_epoch()](#gen_epoch)
* [conv_date_to_jdoy()](#conv_date_to_jdoy)
* [compare_jdoy_dates()](#compare_jdoy_dates)
* [month_to_int()](#month_to_int)


## gen_date()

Return a uniform timestamp

_Function has no arguments._

### Example

```bash
ts="$(get_date)"
```

### Output on stdout

* String Timestamp; YYYYmmdd-HHMMSS

## get_day_of_year()

Return the day of year

_Function has no arguments._

### Example

```bash
doy="$(get_day_ofyear)"
```

### Output on stdout

* Integer Day between 1-367

## gen_epoch()

Return the current EPOCH

_Function has no arguments._

### Example

```bash
epoch="$(gen_epoch)"
```

### Output on stdout

* Integer

## conv_date_to_jdoy()

Convert current/supplied date to Julian Day of Year

### Arguments

* ${1} Day
* ${2} Month
* ${3} Year

### Example

```bash
conv_date_jdoy
conv_date_jdoy 27 6 1975
```

### Output on stdout

* Integer

## compare_jdoy_dates()

Compare two Julian Dates

### Arguments

* ${1} Current
* ${2} Compariative
* ${3} Minimum integer

### Example

```bash
compare_jdoy_dates 2458461.5 2442590.5 30
compare_jdoy_dates $(conv_date_to_jdoy) $(conv_date_to_jody 27 6 27) 365
```

### Output on stdout

* Integer true/false

## month_to_int()

Month string to integer conversion mapper

### Arguments

* ${1} Month

### Example

```bash
month_to_int Dec
month_to_int january
```

### Output on stdout

* Integer 1-12

