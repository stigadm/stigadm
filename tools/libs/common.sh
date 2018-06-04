#!/bin/bash

# Displays available arg list
# Arguments:
#  [String] (Optional): Error to display regarding usage of invoked tool
function usage()
{
  # Handle error if present
  [ "${1}" != "" ] && error="$(print "${1}" 1)"

  # Print a friendly menu
  cat <<EOF
${error}

Handles DISA STIG ${stigid}

Usage ./${prog} [options]

  Options:
    -h  Show this message
    -v  Enable verbosity mode

  Required:
    -c  Make the change
    -a  Author name (required when making change)
    -m  Display meta data associated with module

  Restoration options:
    -r  Perform rollback of changes
    -i  Interactive mode, to be used with -r

  Reporting:
    -j  JSON reporting structure (default)
    -x  XML reporting structure

EOF
}


# Get the current hostname
function get_hostname()
{
  local host="$(hostname)"

  if [[ "${host}" == "" ]] || [[ "${host}" =~ localhost ]]; then
    return 1
  fi

  echo "${host}" && return 0
}


# Function truncate output
# Arguments:
#  str [String]: String that requires truncation
#  count [Integer] (Optional): Number of columns (characters) to limit
function truncate_cols()
{
  local str="${1}"
  local count=$([ ! -x ${2} ] && echo ${2} || echo 80)

  echo "${str:0:${count}}..."
}


# Function to determine if path is on an NFS share
# Arguments:
#  str [String]: Path to validate as an NFS share
function is_nfs_path()
{
  local path="${1}"

  mounts=($(mount | nawk -v pat="${path}" '$1 ~ pat && $3 ~ /:/{split($3, obj, ":"); print obj[1]}'))
  echo ${#mounts[@]}
}


# Function to get list of Operating systems supported
function get_os()
{
  # Re-assign all arguments
  local obj=( ${@} )

  # If element 0 is = to 1 then change the return type from string to array
  if [ "${obj[0]}" == 1 ]; then
    retval=${obj[0]}
    path="${obj[@]:1}"
  else
    retval=0
    path="${obj[@]}"
  fi

  # Create a local array to handle directory list
  local -a dirs
  dirs=( $(find ${path}/* -type d -prune) )

  if [ ${#dirs[@]} -eq 0 ]; then
    echo "undefined"
    return
  fi

  # Return only the directory names (strip out paths)
  dirs=( $(echo "${dirs[@]}" | tr ' ' '\n' | sed "s|${path}||g" | sed "s|/||g") )

  if [ ${retval} -eq 1 ]; then
    echo "${dirs[@]}"
    return 0
  fi

  echo "${dirs[@]}" | tr ' ' '|'
}


# Function to get list of versions (per os)
function get_version()
{
  # Re-assign all arguments
  local obj=( ${@} )

  # If element 0 is = to 1 then change the return type from string to array
  if [ "${obj[0]}" == 1 ]; then
    retval=${obj[0]}
    path="${obj[@]:1}"
  else
    retval=0
    path="${obj[@]}"
  fi


  # Create a local array to handle directory list
  local -a versions
  versions=( $(find ${path}/*/* -type d -prune) )

  if [ ${#versions[@]} -eq 0 ]; then
    echo "undefined"
    return
  fi

  # Return only the directory names (strip out paths)
  versions=( $(echo "${versions[@]}" | tr ' ' '\n' | sed "s|${path}.*/||g" | sort -ru) )

  if [ ${retval} -eq 1 ]; then
    echo "${versions[@]}"
    return 0
  fi

  echo "${versions[@]}" | tr ' ' '|'
}


# Function to get list of available severity levels
function get_classification()
{
  # Re-assign all arguments
  local obj=( ${@} )

  # If element 0 is = to 1 then change the return type from string to array
  if [ "${obj[0]}" == 1 ]; then
    retval=${obj[0]}
    path="${obj[@]:1}"
  else
    retval=0
    path="${obj[@]}"
  fi


  # Create a local array to handle directory list
  local -a classes
  classes=( $(find ${path} -type f -prune -name "*.sh" -exec grep "^# Severity:" {} \;  | cut -d" " -f3) )

  if [ ${#classes[@]} -eq 0 ]; then
    echo "undefined"
    return
  fi

  # Cut out & sort our classifications
  classes=( $(echo "${classes[@]}" | tr ' ' '\n' | sort -u) )

  if [ ${retval} -eq 1 ]; then
    echo "${classes[@]}"
    return 0
  fi

  echo "${classes[@]}" | tr ' ' '|'
}


# Print meta data
function get_meta_data()
{
  local cwd="${1}"
  local stigid="${2}"
  local template="${3}"
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
