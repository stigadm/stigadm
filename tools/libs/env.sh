#!/bin/bash

# Determine OS type
function os()
{
  uname -s | sed -e 's/SunOS/Solaris/g'
}


# Determine OS version
function version()
{
  uname -v | cut -d. -f1
}


# Determine hw architecture
function architecture()
{
  uname -p | sed 's/i[3|4]86$/X86/g'
}


# Validate target OS & Version
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

