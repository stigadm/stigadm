#!/bin/bash


# UID/GID values to determine system, applicaton or end user
#  Format: MIN:MAX
sysaccts="1:99"
appaccts="100:499"
usraccts="500:2147483647"


# Function to obtain an array of accounts
function get_accounts()
{
  # Test and get array of accounts
  local -a accounts=( $(getent passwd | sort -t: -k1 | tr ' ' '_') )

  echo "${accounts[@]}" && return 0
}


# Get uid based on username
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


# Get gid based on username
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


# Function to obain groups
function get_groups()
{
  # Test and get array of groups
  local -a groups=( $(getent group | sed 's/ /_/g') )

  echo "${groups[@]}" && return 0
}


# Get gid based on group name
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


# Function to retrieve system accounts
function get_system_accts()
{
  local min=$(echo "${sysaccts}" | cut -d: -f1)
  local min=$(echo "${sysaccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# Function to retrieve application accounts
function get_application_accts()
{
  local min=$(echo "${appaccts}" | cut -d: -f1)
  local min=$(echo "${appaccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# Function to retrieve user accounts
function get_user_accts()
{
  local min=$(echo "${usraccts}" | cut -d: -f1)
  local min=$(echo "${usraccts}" | cut -d: -f2)
  local -a accts=( $(get_accounts) )

  echo "$(echo "${accts[@]}" | tr ' ' '\n' | \
    nawk -v min=${min} -v max=${max} -F: '$3 >= min && $4 <= max{print $1}')"
}


# Function to filter accounts
function filter_accounts()
{
  local -a args=( ${@} )
  local index="${args[0]}"
  local -a obj=( ${args[@]:1} )

  echo "${obj[@]}" | tr ' ' '\n' | cut -d: -f${index}
}
