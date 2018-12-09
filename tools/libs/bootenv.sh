#!/bin/bash


# @file tools/libs/bootenv.sh
# @brief Implements bootenv creation, mounting etc

# @description Create a new boot environment
#
# @arg ${1} String; Name of new boot env.
# @arg ${2} Integer; OS Version
#
# @example
#   create_be foo 10
#   create_be bar 11
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Activates the newly created boot env.
#
# @arg ${1} String; Name of new boot env.
# @arg ${2} Integer; OS Version
#
# @example
#   activate_be foo 10
#   activate_be bar 11
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Validates new boot environment
#
# @arg ${1} String; Name of new boot env.
# @arg ${2} Integer; OS Version
#
# @example
#   validate_be foo 10
#   validate_be bar 11
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Mount the boot environment
#
# @arg ${1} String; Name of new boot env.
# @arg ${2} Integer; OS Version
# @arg ${3} String; Path of boot env. mount
#
# @example
#   mount_be foo 10 /path/to/mount/
#   mount_be bar 11 /path/to/mount/
#
# @exitcode 0 Success
# @exitcode 1 Error
function mount_be()
{
  local name="${1}"
  local version="${2}"
  local path="${3}"

  [ ! -d ${path} ] && mkdir -p ${path}

  if [ ${version} -gt 11 ]; then
    bechk=$(beadm mount ${name} ${path}; echo $?)
  else
    bechk=$(lumount ${name} ${path}; echo $?)
  fi

  return ${bechk}
}


# @description Create, activate & validate boot env.
#
# @arg ${1} String; Name of new boot env.
# @arg ${2} Integer; OS Version
#
# @example
#   bootenv foo 10
#   bootenv bar 11
#
# @exitcode 0 Success
# @exitcode 1 Error
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
