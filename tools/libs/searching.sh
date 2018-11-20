#!/bin/bash

# Find a directory
function find_dir()
{
  local path="${1}"
  local folder="${2}"

  find ${path} -type d -name "${folder}"
}


# Find a file
function find_file()
{
  local path="${1}"
  local file="${2}"

  find ${path} -type f -name "${file}"
}


# Search a haystack for the supplied needle
# Arguments:
#  args [Array]: Array of arguments supplied to in_array()
#  needle [String]: String to perform strict search on
#  haystack [Array]: Array of string(s) to search for ${string} in
function in_array()
{
  local args=("${@}")
  local needle="${args[0]}"
  local haystack=("${args[@]:1}")

  for i in ${haystack[@]}; do
    if [[ ${i} == ${needle} ]]; then
      echo 0 && return 0
    fi
  done

  echo 1 && return 1
}


# Perform fuzzy search of needle in supplied haystack
# Arguments:
#  args [Array]: Array of arguments supplied to in_array()
#  needle [String]: String to perform loose prefix based search on
#  haystack [Array]: Array of string(s) to search for ${string} in
function in_array_fuzzy()
{
  local args=("${@}")
  local needle="${args[0]}"
  local haystack=("${args[@]:1}")

  for i in ${haystack[@]}; do
    if [[ $(dirname ${needle}) =~ ^${i} ]]; then
      echo 0 && return 0
    fi
  done

  echo 1 && return 1
}


# Perform loose regex pattern based search of needle in supplied haystack
# Arguments:
#  args [Array]: Array of arguments supplied to in_array()
#  needle [String]: String to perform loose prefix based search on
#  haystack [Array]: Array of string(s) to search for ${string} in
function in_array_loose()
{
  local args=("${@}")
  local needle="${args[0]}"
  local haystack=("${args[@]:1}")

  for i in ${haystack[@]}; do
    if [ $(echo "${i}" | grep -c "${needle}") -gt 0 ]; then
      echo 0 && return 0
    fi
  done

  echo 1 && return 1
}


# Search for absolute file & path from a supplied file
# Arguments:
#  file [String]: File/String to search for patterns in
#  pattern [String] (Optional): BRE based regular expression for file matches
#  prefix [String] (Optional): String used to prefix ${pattern} with
#  suffix [String] (Optional): String used to suffix ${pattern} with
#  iterations [Integer] (Optional): Number of iterations to use when building pattern from ${prefix}, ${pattern} & ${suffix}
function extract_filenames()
{
  local file="${1}"
  local pattern="$([ ! -x ${2} ] && echo "${2}" || echo "[/\|~\|..][a-z0-9A-Z._-]*")"
  local prefix="$([ ! -x ${3} ] && echo "${3}" || echo ".*(")"
  local suffix="$([ ! -x ${4} ] && echo "${4}" || echo ").*")"
  local iterations=$([ ! -x ${5} ] && echo ${5} || echo 10)

  local -a results=()
  local tpat=
  local i=0

  # Iterate 0 - ${iterations}
  #for i in $(seq 1 ${iterations}); do
  while [ ${i} -le ${iterations} ]; do

    # Combine ${tpat} with ${pattern} to account for BRE limitations with complex regex's
    tpat="${tpat}${pattern}"

    # Combine the ${prefix}, ${tpat} & ${suffix} for a complete regex
    pat="${prefix}${tpat}${suffix}"

    # Extract any patterns matching ${pat} from ${file} while assigning to ${t_results[@]}
    if [ -f ${file} ]; then
      t_results="$(sed -ne "s|.*\(${pat}\).*|\1|p" ${file} 2> /dev/null)"
    else
      t_results="$(echo "${file}" | sed -ne "s|.*\(${pat}\).*|\1|p" 2> /dev/null)"
    fi

    # If ${t_results} is a file add it
    [ -f "${t_results}" ] && results+=( "${t_results}" )

    # Increment ${i}
    i=$(( ${i} + 1 ))
  done

  # Provide the ${results[@]} if > 0
  [ ${#results[@]} -gt 0 ] && echo "${results[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}


# Remove duplicates from an array
# Arguments:
#  [Array]: Array to remove duplicates from
function remove_duplicates()
{
  local -a obj
  obj=("${@}")

  echo "${obj[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}
