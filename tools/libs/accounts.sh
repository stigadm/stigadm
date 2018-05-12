#!/bin/bash


# Function to obtain an array of accounts
function get_accounts()
{
  # Test and get array of accounts
  [ -f /etc/passwd ] &&
    local -a accounts=( $(cat /etc/passwd) )

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
  [ -f /etc/group ] &&
    local -a groups=( $(cat /etc/group) )

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
