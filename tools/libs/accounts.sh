#!/bin/bash

# @file tools/libs/accounts.sh
# @brief Query local/remote accounts

# UID/GID values to determine system, applicaton or end user
#  Format: MIN:MAX
sysaccts="1:99"
appaccts="100:499"
usraccts="500:2147483647"


# @description Get all local/remote accounts
#
# @noargs
#
# @example
#   accounts=( $(get_accounts) )
#
# @stdout Array of local/remote accounts
#
# @exitcode >0 Success
# @exitcode 0 Error
function get_accounts()
{
  # Test and get array of accounts
  local -a accounts=( $(getent passwd | sort -t: -k1 | tr ' ' '_') )

  echo "${accounts[@]}" && return ${#accounts[@]}
}


# @description Obtain UID from provided username
#
# @arg ${1} Username
#
# @example
#   user_uid foo
#
# @stdout Integer UID
function user_uid()
{
  # Scope locally
  local user="${1}"
  local accts=( $(get_accounts) )
  local uid

  # Pluck uid from ${accts}
  uid=$(echo "${accts[@]}" | tr ' ' '\n' | grep "^${user}:" | cut -d: -f3)

  # return ${uid}
  echo ${uid:=-1}
}


# @description Obtain GID from provided username
#
# @arg ${1} Username
#
# @example
#   user_gid foo
#
# @stdout Integer GID
function user_gid()
{
  # Scope locally
  local group="${1}"
  local accts=( $(get_accounts) )
  local gid

  # Pluck gid from ${accts}
  gid=$(echo "${accts[@]}" | tr ' ' '\n' | grep "^${group}:" | cut -d: -f4)

  # return ${gid}
  echo ${gid:=-1}
}


# @description Obtain Array of local/remote groups
#
# @noargs
#
# @example
#   groups=( $(get_groups) )
#
# @stdout Array of local/remote groups
#
# @exitcode >0 Success
# @exitcode 0 Error
function get_groups()
{
  # Test and get array of groups
  local -a groups=( $(getent group | sed 's/ /_/g') )

  echo "${groups[@]}" && return ${#groups[@]}
}


# @description Get the GID of a requested group
#
# @arg ${1} Group name
#
# @example
#   group_gid foo
#
# @stdout Integer GID
function group_gid()
{
  # Scope locally
  local group="${1}"
  local accts=( $(get_groups) )
  local gid

  # Pluck gid from ${accts}
  gid=$(echo "${accts[@]}" | tr ' ' '\n' | grep "^${group}:" | cut -d: -f3)

  # return ${gid}
  echo ${gid:=-1}
}


# @description Get array of local/remote system accounts
#
# @noargs
#
# @example
#   system_accts=( $(get_system_accts) )
#
# @stdout Array of local/remote user accounts
function get_system_accts()
{
  local min=$(echo "${sysaccts}" | cut -d: -f1)
  local min=$(echo "${sysaccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# @description Get array of local/remote application accounts
#
# @noargs
#
# @example
#   application_accts=( $(get_application_accts) )
#
# @stdout Array of local/remote user accounts
function get_application_accts()
{
  local min=$(echo "${appaccts}" | cut -d: -f1)
  local min=$(echo "${appaccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# @description Get array of local/remote user accounts
#
# @noargs
#
# @example
#   user_accts=( $(get_user_accts) )
#
# @stdout Array of local/remote user accounts
function get_user_accts()
{
  local min=$(echo "${usraccts}" | cut -d: -f1)
  local min=$(echo "${usraccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# @description Return array of filtered user accounts
#
# @arg ${@} Array of total arguments
# @arg ${@[0]} Offset one of array is the needle
# @arg ${@:1} Offset element 0 is the haystack
#
# @example
#   filter_accts=( $(filter_accts "foo" $(get_user_accts)) )
#
# @stdout Array of filtered local/remote user accounts
function filter_accounts()
{
  local -a args=( ${@} )
  local index="${args[0]}"
  local -a obj=( ${args[@]:1} )

  echo "${obj[@]}" | tr ' ' '\n' | cut -d: -f${index}
}
