#!/bin/bash

# @file tools/libs/backup.sh
# @brief Handle backup operations

# @description Builds backup environment
#
# @arg ${1} Path to backup folder
#
# @example
#   backup_setup_env /path/to/backup
#
# @exitcode 0 Success
function backup_setup_env()
{
  local path="${1}"

  if [ ! -d ${path} ]; then
    mkdir -p ${path}
  fi

  return 0
}


# @description Backs up specified file while preserving permissions
#
# @arg ${1} Author of backup file
# @arg ${2} File to be backed up
# @arg ${3} Owner of file
# @arg ${4} Group owner of file
# @arg ${5} Permisison of file
#
# @example
#   bu_file author /path/to/backup/file
#   bu_file author /path/to/backup/file foo bar 640
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Gets the name of the last backup
#
# @arg ${1} File to be backed up
# @arg ${2} Author of backup file
#
# @example
#   bu_file_last /path/to/backup/file author
#
# @stdout String path to file
function bu_file_last()
{
  local path="${1}"
  local author="${2}"

  echo "$(ls ${path}.${author}-* | sort -r | head -1)"
}


# @description Backs up local passwd database file(s)
#
# @arg ${1} Author of backup file
# @arg ${2} File to be backed up
# @arg ${3} Owner of file
# @arg ${4} Group owner of file
# @arg ${5} Permisison of file
#
# @example
#   bu_file_db author /path/to/backup/file
#   bu_file_db author /path/to/backup/file foo bar 640
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Backs up array of file/folder permissions
#
# @arg ${1} Author of backup file
# @arg ${2} File to be backed up
# @arg ${3} STIG module ID
# @arg ${4} Array of files
#
# @example
#   bu_inode_perms
#   bu_inode_perms ${files[@]}
#   bu_inode_perms /path/to/backup/file
#   bu_inode_perms /path/to/backup/file author
#   bu_inode_perms /path/to/backup/file author stigid
#   bu_inode_perms /path/to/backup/file author stigid ${files[@]}
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Backs up array of configuration items
#
# @arg ${1} Author of backup file
# @arg ${2} File to be backed up
# @arg ${3} STIG module ID
# @arg ${4} Array of configuration items
#
# @example
#   bu_inode_perms
#   bu_inode_perms ${configuration[@]}
#   bu_inode_perms /path/to/backup/file
#   bu_inode_perms /path/to/backup/file author
#   bu_inode_perms /path/to/backup/file author stigid
#   bu_inode_perms /path/to/backup/file author stigid ${configuration[@]}
#
# @exitcode 0 Success
# @exitcode 1 Error
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