#!/bin/bash

# @file tools/libs/env.sh
# @brief Set/Get environment specifics

# @description Get the current OS name
#
# @noargs
#
# @stdout String
function os()
{
  uname -s | sed -e 's/SunOS/Solaris/g'
}


# @description Get the current OS version
#
# @noargs
#
# @stdout String
function version()
{
  uname -v | cut -d. -f1
}


# @description Get the current system architecture
#
# @noargs
#
# @stdout String
function architecture()
{
  uname -p | sed 's/i[3|4]86$/X86/g'
}


# @description Get all environment items
#
# @noargs
#
# @stdout Array
function set_env()
{
  # Get OS & Version
  local os="$(os)"
  local ver="$(version)"
  local arch="$(architecture)"

  if [[ "${os}" == "" ]] || [[ "${ver}" == "" ]]; then
    echo 1 && return 1
  fi

  echo "${os}" "${ver}" "${arch}" && return 0
}
