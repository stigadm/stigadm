#!/bin/bash

# Handle backup environment
# Arguments:
#  path [String]: Absolute path of directory
function backup_setup_env()
{
  local path="${1}"

  if [ ! -d ${path} ]; then
    mkdir -p ${path}
  fi

  return 0
}


# Function to handle backups
# Arguments:
#  author [String]: Author of change; typically the users initials
#  file [String]: File that is to be backed up (or created)
#  user [String] (Optional): User ownership to associate with ${file}
#  group [String] (Optional): Group ownership to associate with ${file}
#  octal [Integer] (Optional): Permission mode to associate with ${file}
function bu_file()
{
  # Define some locally scoped vars
  local author
  local file
  local user
  local group
  local octal
  local bfile
  local extension
  local is_nfs=0
  local ret=0

  # Define the changing user
  author=$([ ! -z ${1} ] && echo "${1}" || echo "$(id | nawk -F"(" '{print $2}' | cut -d")" -f1)")

  # Locally scoped copy of ${2}
  file="${2}"

  # Get the current user of ${file}
  user="$([ ! -z ${3} ] && echo "${3}" || echo $(get_inode_user ${file}))"

  # Get the current group of ${file}
  group="$([ ! -z ${4} ] && echo "${4}" || echo $(get_inode_group ${file}))"

  # Get the current octal mode permissions of ${file}
  octal="$([ ! -z ${5} ] && echo "${5}" || echo $(get_octal ${file}))"

  # Define an extension for backups
  extension="${author}-$(date +%Y%m%d-%H%M%S)"

  # Define a new file string
  bfile="${file}.${extension}"

  # Set is_nfs to accommodate for permission failures on remote disk(s)
  is_nfs=$(is_nfs_path $(echo "${bfile}" | cut -d"/" -f1,2))

  # Create ${bfile}
  touch ${bfile} 2>/dev/null
  [ $? -ne 0 ] && ret=1
  #(>&2 echo "touch: ${ret}")

  # If ${is_nfs} == 0
  if [ ${is_nfs} -eq 0 ]; then

    # Set ownership on ${bfile} to ${user}:${group}
    chown ${user}:${group} ${bfile} 2>/dev/null
    [ $? -ne 0 ] && ret=1
    #(>&2 echo "chown: ${ret}")

    # Set ${octal} on ${bfile}
    chmod ${octal} ${bfile} 2>/dev/null
    [ $? -ne 0 ] && ret=1
    #(>&2 echo "chmod: ${ret}")

  fi

  # If ${file} exists
  if [ -f ${file} ]; then

    # Now copy contents of ${file} into ${bfile}
    cat ${file} > ${bfile}
    [ $? -ne 0 ] && ret=1
    #(>&2 echo "cat: ${ret}")

  fi

  # Return ${ret}
  return ${ret}
}


# Get latest file created by bu_file()
# Arguments:
#  path [String]: Path to search for latest file created
#  author [String]: Author of change; typically the users initials
function bu_file_last()
{
  local path="${1}"
  local author="${2}"

  echo "$(ls ${path}.${author}-* | sort -r | head -1)"
}


# Handle backup of passwd db
# Arguments:
#  author [String]: Author of change; typically the users initials
#  passwd [String] (Optional): Path to passwd database file (ie. /etc/passwd)
#  shadow [String] (Optional): Path to shadow database file (ie. /etc/shadow)
#  group [String] (Optional): Path to group database file (ie. /etc/group)
function bu_passwd_db()
{
  # Define some locally scoped vars
  local file
  local ret=0

  # Define the changing user
  local author=$([ ! -z ${1} ] && echo "${1}" || echo "$(id | nawk -F"(" '{print $2}' | cut -d")" -f1)")

  # Define the array of files associated with the passwd db
  declare -a pwdb
  pwdb+=($([[ ! -z ${2} ]] && [[ -f ${2} ]] && echo "${2}" || echo /etc/passwd))
  pwdb+=($([[ ! -z ${3} ]] && [[ -f ${3} ]] && echo "${3}" || echo /etc/shadow))
  pwdb+=($([[ ! -z ${4} ]] && [[ -f ${4} ]] && echo "${4}" || echo /etc/group))


  # Iterate ${pwdb[@]}
  for file in ${pwdb[@]}; do

    # Pass ${file} over to bu_file()
    bu_file "${author}" "${file}"
    [ $? -ne 0 ] && ret=1
  done

  return ${ret}
}


# Creates snapshot of file/folder permissions
# Arguments:
#  path [String]: Path to use for snapshot of array of inodes supplied
#  author [String]: Author of change; typically the users initials
#  stigid [String]: STIG id associated with change
#  inodes [Array]: Array of inodes that require a snapshot of permissions regarding user/group/mode
function bu_inode_perms()
{
  # Define some locally scoped vars
  local file
  local item
  local snapshot
  local ret=0

  # Define the backup path
  local path=$([[ -n ${1} ]] && [[ -f ${1} ]] && echo "${1}" || echo "${backup_path}")

  # Define the changing user
  local author=$([ -n ${2} ] && echo "${2}" || echo "$(id | nawk -F"(" '{print $2}' | cut -d")" -f1)")

  # Define the stigid
  local stigid=$([[ -n ${3} ]] && [[ -f ${3} ]] && echo "${3}" || echo "${stigid}")

  # Handle the array of inodes
  local inodes=("${@:4}")

  # Ensure ${#indoes[@]} > 0
  [ ${#inodes[@]} -le 0 ] && return 1

  # Define an snapshot file
  snapshot="${path}/${stigid}"

  # Hand ${snapshot} off to bu_file()
  bu_file "${author}" "${snapshot}" "root" "root" "0600"
  [ $? -ne 0 ] && return 1

  # Get latest ${snapshot} from bu_file_last()
  snapshot="$(bu_file_last "${path}/${stigid}" "${author}")"
  
  # Make sure ${snapshot} is a file
  [ ! -f ${snapshot} ] && return 1

  # Iterate ${inodes[@]}
  for file in ${inodes[@]}; do

    # Get the current user of ${file}
    user="$(get_inode_user ${file})"

    # Get the current group of ${file}
    group="$(get_inode_group ${file})"

    # Get the current octal mode permissions of ${file}
    octal="$(get_octal ${file})"

    # Create the snapshot for ${file}
    item="${file}:${user}:${group}:${octal}"

    # Copy ${item} into ${snapshot}
    echo "${item}" >> ${snapshot}
  done

  return ${ret}
}


# Handle configuration parameter backups
function bu_configuration()
{
  # Define some locally scoped vars
  local file
  local item
  local snapshot
  local ret=0

  # Define the backup path
  local path=$([[ -n ${1} ]] && [[ -f ${1} ]] && echo "${1}" || echo "${backup_path}")

  # Define the changing user
  local author=$([ -n ${2} ] && echo "${2}" || echo "$(id | nawk -F"(" '{print $2}' | cut -d")" -f1)")

  # Define the stigid
  local stigid=$([[ -n ${3} ]] && [[ -f ${3} ]] && echo "${3}" || echo "${stigid}")

  # Handle the array of params
  local params=("${@:4}")

  # Ensure ${#indoes[@]} > 0
  [ ${#params[@]} -le 0 ] && return 1

  # Define an snapshot file
  snapshot="${path}/${stigid}"

  # Hand ${snapshot} off to bu_file()
  bu_file "${author}" "${snapshot}" "root" "root" "0600"
  [ $? -ne 0 ] && return 1

  # Get latest ${snapshot} from bu_file_last()
  snapshot="$(bu_file_last "${path}/${stigid}" "${author}")"
  [ ! -f ${snapshot} ] && return 1

  # Iterate ${params[@]}
  for param in ${params[@]}; do

    # Create entry for ${param} in ${snapshot}
    echo "${param}" >> ${snapshot}
  done

  return 0
}