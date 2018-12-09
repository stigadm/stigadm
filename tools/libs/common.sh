#!/bin/bash

# @file tools/libs/common.sh
# @brief Common functions for various reasons

# @description Universal API arg list
#
# @arg ${1} String; error message
#
# @example
#   usage
#   usage "An error occurred"
function usage()
{
  # Handle error if present
  [ "${1}" != "" ] && error="$(print "${1}" 1)"

  # Print a friendly menu
  cat <<EOF
${error}

DISA STIG ${stigid}

Usage ./${prog} [options]

  Options:
    -h  Show this message
    -v  Enable verbosity mode

  Required:
    -c  Make the change
    -a  Author name (required when making change)

  Restoration options:
    -r  Perform rollback of changes

  Reporting:
    -l  Default: /var/log/stigadm/<HOST>-<OS>-<VER>-<ARCH>-<DATE>.json
    -j  JSON reporting structure (default)
    -x  XML reporting structure

EOF
}


# @description Meta data parser
#
# @arg ${1} String; Current working directory
# @arg ${2} String; STIG V-ID to pluck meta data from
#
# @example
#   get_meta_data
#   declare -a meta_data=( $(get_meta_data) )
#
# @stdout Array Returns the STIG Date, Severity, Classification, V-ID, Version, Rule ID, OS, Title etc
function get_meta_data()
{
  local cwd="${1}"
  local stigid="${2}"

  local stigid_parsed="$(echo "${stigid}" | cut -d. -f1)"
  local blob="$(sed -n '/^# Date/,/^# Description/p' ${cwd}/${stigid} | sed "s|^[# |#$|  ]||g")"
  local -a obj

  # Cut ${blob} up and assign to ${obj[@]} (UGLY!!! refactor)
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Date:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Severity:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Classification:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /STIG_ID:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /STIG_Version:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Rule_ID:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /OS:/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Version:/ && $0 !~ /STIG/{print $2}')")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Title/{print substr($0,index($0,$2))}' | tr ' ' "_")")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Description/{print substr($0,index($0,$2))}' | tr ' ' "_")")
  obj+=("$(echo "${blob}" | nawk '$0 ~ /Architecture:/{if ($3 != ""){print $2","$3}else{print $2}}')")

  echo "${obj[@]}"
}
