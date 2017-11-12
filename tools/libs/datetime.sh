#!/bin/bash

# Handle date string creation
function gen_date()
{
  echo "$(date +%Y%m%d-%H%M%S)"
}


# Get current day of year
function get_day_of_year()
{
  echo "$(date +%j)"
}


# Date to Julian Day of Year
# Arguments:
#  day [Integer]: Day of month
#  mon [Integer]: Month
#  year [Integer]: Year
function conv_date_to_jdoy()
{
  local dte="$(date +%d:%m:%Y)"

  local tday=$(echo "${dte}" | cut -d: -f1)
  local tmon=$(echo "${dte}" | cut -d: -f2)
  local tyear=$(echo "${dte}" | cut -d: -f3)

  local day="$([ ! -z ${1} ] && echo "${1}" || echo "${tday}")"
  local mon="$([ ! -z ${2} ] && echo "${2}" || echo "${tmon}")"
  local year="$([ ! -z ${3} ] && echo "${3}" || echo "${tyear}")"
  local sum

  if [ ${mon} -le 2 ]; then
    year=$(( ${year} - 1 ))
    mon=$(( ${mon} + 12 ))
  else
    year=${year}
    mon=${mon}
  fi

  sum=$(echo  "2 - ${year} / 100 + ${year} / 400" | bc)
  sum=$(echo  "(${sum} + 365.25 * (${year} + 4716)) / 1" | bc)
  sum=$(echo "(${sum} + 30.6001 * (${mon} + 1)) / 1" | bc)
  
  echo $(echo "${sum} + ${day} - 1524.5" | bc)
}


# Date comparison using Julian day of year
# Arguments:
#  current [Integer]: Current Julian Day Of Year
#  compare [Integer]: Comparison Julian Day Of Year
#  min [Integer]: Evaluated minimum between ${current} & ${compare}
function compare_jdoy_dates()
{
  local current="${1}"
  local compare="${2}"
  local min="${3}"

  [ $(echo "${current} - ${compare}" | bc | cut -d. -f1) -ge ${min} ] && return 1 || return 0
}


# Month to integer matrix
# Arguments:
#  month [String]: Supplied month to convert
function month_to_int()
{
  local month="${1}"

  case "${month}" in
    [j|J]an)
      echo 1 ;;
    [f|F]eb)
      echo 2 ;;
    [m|M]ar)
      echo 3 ;;
    [a|A]pr)
      echo 4 ;;
    [m|M]ay)
      echo 5 ;;
    [j|J]un)
      echo 6 ;;
    [j|J]ul)
      echo 7 ;;
    [a|A]ug)
      echo 8 ;;
    [s|S]ep)
      echo 9 ;;
    [o|O]ct)
      echo 10 ;;
    [n|N]ov)
      echo 11 ;;
    [d|D]ec)
      echo 12 ;;
  esac
}