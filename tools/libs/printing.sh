#!/bin/bash

# Determine template(s) to use
function get_template_path()
{
  local path="${1}"
  local template="${2}"

  # Test ${path}/${template} combination
  [ ! -d ${path}/${template} ] && (echo 0 && return 0)

  # Return the template path
  echo "${path}/${template}/" && return 0
}


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
