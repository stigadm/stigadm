#!/bin/bash -x

# Print errors
# Arguments:
#  [String]: Provided message for error printing
function perror()
{
  printf "[${stigid:=${appname}}] Error: %s\n" "${1}"
}


# Print success
# Arguments:
#  [String]: Provided message for successful printing
function psuccess()
{
  printf "[${stigid:=${appname}}] Ok: %s\n" "${1}"
}


# Print warning
# Arguments:
#  [String]: Provided message for warning
function pwarning()
{
  printf "[${stigid:=${appname}}] Warning: %s\n" "${1}"
}


# Pretty printer
# Arguments:
#  [String]: Provided message for error printing
#  [Integer] (Optional): Force error message printing
function print()
{
  # An warning is present
  if [[ -n "${2}" ]] && [[ ${2} -eq 2 ]]; then
    pwarning "${1}" && return 0
  fi

  # An error is present
  if [[ -n "${2}" ]] && [[ ${2} -eq 1 ]]; then
    perror "${1}" && return 0
  fi

  psuccess "${1}" && return 0
}


# Print a single line
# Arguments:
#  log [String]: Log file & path
#  key [String]: Index value
#  value [String]: Value of index
function print_line()
{
  # Capture arg list to an array
  local -a obj=("${@}")

  # Re-assign elements
  local log="${obj[0]}"
  local key="${obj[1]}"

  # Capture the remaining elements to a string
  local value="${obj[@]:2}"

  # Generate a log name
  local ext="$(basename ${log} | cut -d. -f2)"

  if [ "${ext}" == "json" ]; then
    echo "    ${key}: \"${value}\"," >> ${log}
  else
    echo "      <${key}>${value}</${key}>" >> ${log}
  fi
}


# Print an array
# Arguments:
#  log [String]: Log file & path
#  key [String]: Index value
#  values [Array]: Array of values
function print_array()
{
  # Capture arg list to an array
  local -a obj=("${@}")

  # Re-assign elements
  local log="${obj[0]}"
  local key="${obj[1]}"

  # Capture the remaining elements as an array
  local -a values=( ${obj[@]:2} )

  # Generate a log name
  local ext="$(basename ${log} | cut -d. -f2)"

  # Create a header for the JSON/XML array
  if [ "${ext}" == "json" ]; then
    echo "    ${key}: [" >> ${log}
  else
    echo "      <${key}>" >> ${log}
  fi

  # Iterate the array
  for value in ${values[@]}; do
    if [ "${ext}" == "json" ]; then
      echo "      \"$(echo "${value}" | tr ':' ' ')\"" >> ${log}
    else
      echo "        <item>$(echo "${value}" | tr ':' ' ')</item>" >> ${log}
    fi
  done

  # Close out the JSON/XML array
  if [ "${ext}" == "json" ]; then
    echo "    ]," >> ${log}
  else
    echo "      </${key}>" >> ${log}
  fi
}
