#!/bin/bash

# Get inode owner
# Arguments:
#  inode [String]: Inode to obtain user information from
function get_inode_user()
{
  local inode="${1}"

  echo "$(ls -lad ${inode} | awk '{print $3}')" && return 0
}


# Get inode group
# Arguments:
#  inode [String]: Inode to obtain group information from
function get_inode_group()
{
  local inode="${1}"

  echo "$(ls -lad ${inode} | awk '{print $4}')" && return 0
}


# Get octal permission value
# Arguments:
#  inode [String]: Inode to obtain permissions from
function get_octal()
{
  local inode="${1}"

  # Verify ${inode} exists
  if [[ ! -d ${inode} ]] && [[ ! -f ${inode} ]]; then
    return 1
  fi
  
  echo $(ls -lahd ${inode} | nawk '{k = 0; for (g=2; g>=0; g--) for (p=2; p>=0; p--) {c = substr($1, 10 - (g * 3 + p), 1); if (c ~ /[sS]/) k += g * 02000; else if (c ~ /[tT]/) k += 01000; if (c ~ /[rwxts]/) k += 8^g * 2^p} if (k) printf("%05o", k)}')

  return 0
}
