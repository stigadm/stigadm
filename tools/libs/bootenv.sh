#!/bin/bash

# Create new boot envrionment and handle errors
function create_be()
{
  local name="${1}"
  local version="${2}"

  # Create a new boot environment
  if [ ${version} -ge 11 ]; then
    beadm create -a "${name}"
    return $?
  else
    lucreate -n "${name}"
    return $?
  fi
}


# Activate boot environment
function activate_be()
{
  local name="${1}"
  local version="${2}"

  # Activate new boot environment
  if [ ${version} -ge 11 ]; then
    beadm activate "${name}"
    return $?
  else
    luactivate "${name}"
    return $?
  fi
}


# Validate boot environment is active now & on reboot
function validate_be()
{
  local name="${1}"
  local version="${2}"

  # Determine command for status of new boot environment; "${name}"
  if [ ${version} -ge 11 ]; then

    # Handle Solaris 11 toolkit for managing boot environment status
    bechk=$(beadm list | grep "^"${name}"" | nawk '{if ($2 == "NR" || $2 == "R"){print 0}else{print 1}}')
  else

    # Handle Solaris 11 toolkit for managing boot environment status
    bechk=$(lustatus ""${name}"" | nawk '{if ($3 == "yes" && $4 == "yes"){print 0}else{print 1}}')
  fi

  return ${bechk}
}


# Handle creation, activation & validation of new boot environment
function bootenv()
{
  local name="${1}"
  local version="${2}"

  # Create new boot environment
  create_be "${name}" ${version}
  [ $? -gt 0 ] && return 1

  # Activate new boot environment
  activate_be "${name}" ${version}
  [ $? -gt 0 ] && return 2

  # Validate new boot environment
  validate_be "${name}" ${version}
  [ $? -gt 0 ] && return 3

  return 0
}
