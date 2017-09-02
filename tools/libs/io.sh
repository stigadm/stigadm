#!/bin/bash

# Function handle folder creation
# Arguments:
#  dir [String]: Supplied path for directory creation
function create_dir()
{
  local dir="${1}"
  local ret=0
  
  if [ "${dir}" == "" ]; then
    ret=1
  fi
  
  if [ ! -d "${dir}" ]; then
    mkdir -p "${dir}"
    ret=$?
  fi
  
  return ${ret}
}


# Generate a new file
# Arguments:
#  file [String]: Name of file to base temporary file on
#  owner [String]: Owner:Group of file
#  perm [Integer]: Permissions for temporary file
#  tmp [String] (Optional): Supplied randomized string for suffix of ${file}
function gen_tmpfile()
{
  local file="${1}"
  local owner="${2}"
  local perm="${3}"
  local tmp="$([[ ! -x ${4} ]] && [[ ${4} -eq 1 ]] && echo ".$RANDOM")"

  # Create a temporary file with changes
  tfile="${file}${tmp}"

  # Create ${tfile}
  touch ${tfile}

  # Validate the ${tfile}
  if [ ! -f ${tfile} ]; then
    return 1
  fi

  # Set permissions on ${tfile}
  chmod ${perm} ${tfile}
  chown ${owner} ${tfile}

  echo "${tfile}" && return 0
}


# Return file/folder when dealing with symlinks
# Arguments:
#  file [String]: Name of inode to test for a symlink
function get_inode()
{
  # Copy ${1} to a local variable
  local inode="${1}"

  # If ${file} is a link
  if [[ -h ${inode} ]] || [[ -L ${inode} ]]; then

    # Attempt to follow link
    inode="$(readlink -e ${inode})"

    # Test for null & return code
    if [[ -z ${inode} ]] || [[ $? -eq 1 ]]; then
      echo 1 && return 1
    fi
  fi

  echo "${inode}" && return 0
}