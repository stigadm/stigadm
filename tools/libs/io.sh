#!/bin/bash

# @file tools/libs/io.sh
# @brief I/O operations

# @description Create directory
#
# @arg ${1} String path to directory
#
# @stdout Integer
#
# @return 1 Error
# @return 0 Success
function create_dir()
{
  local dir="${1}"
  local ret=0

  if [ "${dir}" == "" ]; then
    ret=1
  fi

  if [ ! -d "${dir}" ]; then
    mkdir -p "${dir}" -m 750
    ret=$?
  fi

  return ${ret}
}


# @description Create a new temporary file
#
# @arg ${1} String File name
# @arg ${2} String Owner of file
# @arg ${3} String Group owner of file
# @arg ${4} String Permissions of file
# @arg ${5} String Suffix of file name
#
# @example
#  gen_tmpfile /path/to/file root sys 640
#  gen_tmpfile /path/to/file root sys 640 $(openssl rand -hex 3)
#
# @stdout String
#
# @return 1 Error
# @return 0 Success
function gen_tmpfile()
{
  local file="${1}"
  local owner="${2}"
  local group="${3}"
  local perm="${4}"
  local tmp="$([[ ! -x ${5} ]] && [[ ${5} -eq 1 ]] && echo ".$RANDOM")"

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


# @description Resolve provided symlink to file name
#
# @arg ${1} String File name
#
# @example
#  get_inode /path/to/symlink
#
# @stdout String
#
# @return 1 Error
# @return 0 Success
function get_inode()
{
  # Copy ${1} to a local variable
  local inode="${1}"

  # If ${file} is a link
  if [[ -h ${inode} ]] || [[ -L ${inode} ]]; then

    # Attempt to follow link using readlink
    inode="$(readlink -e ${inode} 2>/dev/null)"

    # Try realpath
    [ "${inode}" == "" ] &&
      inode="$(realpath ${inode} 2>/dev/null)"

    # Test for null & return code
    if [ "${inode}" == "" ]; then
      echo 1 && return 1
    fi
  fi

  echo "${inode}" && return 0
}


# @description Test array of files and return actual files
#
# @arg ${1} Array List of files to test
#
# @example
#  test_file file1 file2 file3
#  test_file ${files[@]}
#
# @stdout Array
#
# @return >1 Success
# @return 0 Error
function test_file()
{
  # Reassign ${@}
  local -a obj="${@}"
  local -a results

  # Iterate ${obj[@]}
  for inode in ${obj[@]}; do

    # Filter for valid file(s) & assign to ${results[@]}
    [ -f ${inode} ] && results+=(${inode})
  done

  echo "${results[@]}" && return ${#results[@]}
}


# @description Test file for compiled/data types
#
# @arg ${1} String File to test
#
# @example
#  is_compiled /path/to/file
#
# @stdout Integer
#
# @return >1 Success
# @return 0 Error
function is_compiled()
{
  local res=$(file ${1} | egrep -c 'ELF|data')
  echo ${res} && return ${res}
}
