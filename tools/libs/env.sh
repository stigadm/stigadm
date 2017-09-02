#!/bin/bash

# Determine OS type
function os()
{
  uname -s
}


# Determine OS version
function version()
{
  uname -v
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
  local path
  
  path="$(find ${cwd} -type d -name ${dir} | head -1)"
  
  echo "${path}"
}

