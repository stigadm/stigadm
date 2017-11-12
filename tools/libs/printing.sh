#!/bin/bash

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


# Pretty printer
# Arguments:
#  [String]: Provided message for error printing
#  [Integer] (Optional): Force error message printing
function print()
{
  # An error is present
  if [[ -n "${2}" ]] && [[ ${2} -eq 1 ]]; then
    perror "${1}" && return 0
  fi

  psuccess "${1}" && return 0
}
