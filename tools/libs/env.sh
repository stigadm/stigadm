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
  uname -p
}


# Get desired folder path
get_path()
{
  local cwd="${1}"
  local dir="${2}"

  local cur="$(pwd)"

  local path

  path="$(find ${cwd:=${cur}} -type d -name ${dir} | head -1)"

  echo "${path}"
}
