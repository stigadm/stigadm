#!/bin/bash


# Function to obtain an array of accounts
function get_accounts()
{
  # Test and get array of accounts
  [ -f [ /etc/passwd ] &&
    local -a accounts=( $(cat /etc/passwd) )

  echo "${accounts[@]}" && return 0
}


# Function to obain groups
function get_groups()
{
  # Test and get array of groups
  [ -f [ /etc/group ] &&
    local -a groups=( $(cat /etc/group) )

  echo "${groups[@]}" && return 0
}


# Get uid based on username
function get_uid()
{
  # Scope locally
  local obj=( ${@} )
  local user="${obj[0]}"
  local accts=( ${obj:1} )
  local uid

  # Pluck uid from ${accts}
  uid=$(echo "${accts[@]}" | grep "^${user}" | cut -d: -f3)

  # return ${uid}
  echo ${uid}
}


# Get gid based on username
function get_gid()
{
  # Scope locally
  local obj=( ${@} )
  local user="${obj[0]}"
  local accts=( ${obj:1} )
  local gid

  # Pluck gid from ${accts}
  gid=$(echo "${accts[@]}" | grep "^${user}" | cut -d: -f3)

  # return ${gid}
  echo ${gid}
}

