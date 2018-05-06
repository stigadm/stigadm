#!/bin/bash


# Default group
def_group="root"

# Array of allowed group owners
declare -a acts
acts+=("root")
acts+=("sys")
acts+=("bin")

# Array of init script locations
declare -a inits
inits+=("/etc/rc*")
inits+=("/etc/init.d")
inits+=("/lib/svc")

# Pattern to match *possible* binaries
pattern="/[a-z0-9A-Z._-]+"

# Disable changes for offending inodes found on remote shares
disable_remote=1


# Global defaults for tool
author=
verbose=0
change=0
meta=0
restore=0
interactive=0

# Working directory
cwd="$(dirname $0)"

# Tool name
prog="$(basename $0)"


# Copy ${prog} to DISA STIG ID this tool handles
stigid="$(echo "${prog}" | cut -d. -f1)"


# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


# Define the library include path
lib_path=${cwd}/../../../libs

# Define the tools include path
tools_path=${cwd}/../../../stigs

# Define the system backup path
backup_path=${cwd}/../../../backups/$(uname -n | awk '{print tolower($0)}')


# Robot, do work


# Error if the ${inc_path} doesn't exist
if [ ! -d ${lib_path} ] ; then
  echo "Defined library path doesn't exist (${lib_path})" && exit 1
fi


# Include all .sh files found in ${lib_path}
incs=($(ls ${lib_path}/*.sh))

# Exit if nothing is found
if [ ${#incs[@]} -eq 0 ]; then
  echo "'${#incs[@]}' libraries found in '${lib_path}'" && exit 1
fi


# Iterate ${incs[@]}
for src in ${incs[@]}; do

  # Make sure ${src} exists
  if [ ! -f ${src} ]; then
    echo "Skipping '$(basename ${src})'; not a real file (block device, symlink etc)"
    continue
  fi

  # Include $[src} making any defined functions available
  source ${src}

done


# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "ha:cmvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    m) meta=1 ;;
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${file}'"

  fi

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Restored '${file}'"

  exit 0
fi


# Make sure ${#inits[@]} is > 0
if [ ${#inits[@]} -eq 0 ]; then
  usage "A list of profile configuration files to examine must be defined" && exit 1
fi


# Get all remote mount points
remotes=($(mount | awk '$3 ~ /.*\:.*/{print $1}'))


# Get list of init scripts to examine
files=($(find ${inits[@]} -type f -ls | awk '{print $11}'))

# Exit if ${#files[@]} is 0
if [ ${#files[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#files[@]}' init scripts found to examine; exiting" && exit 0
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Got list of init scripts to examine; ${#files[@]}"


# Define an empty array
declare -a tmp_files

# Iterate ${files[@]}
for file in ${files[@]}; do

  # Handle symlinks
  file="$(get_inode ${file})"

  # Use extract_filenames() to obtain array of binaries from ${file}
  tmp_files+=($(extract_filenames ${file}))
done

# If ${#tmp_files[@]} = 0 then we are done
if [ ${#tmp_files[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#tmp_files[@]}' called file(s) found from init scripts; exiting" 1 && exit 0
fi

# Remove duplicates from ${tmp_files[@]}
tmp_files=($(remove_duplicates "${tmp_files[@]}"))

# Print friendly message
[ ${verbose} -eq 1 ] && print "Extracted list of possible binary paths to examine; ${#tmp_files[@]}"


# If ${change} > 0
if [ ${change} -ne 0 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"


  # Create a snapshot of ${inodes[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${tmp_files[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current permissions"
fi


# Define an empty array for errors
declare -a errs

# Define an empty array for validated inodes
declare -a vals


# Iterate ${tmp_files[@]}
for inode in ${tmp_files[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Skip ${inode} if it's not a file OR executable
  [ ! -x ${inode} ] && continue

  # if ${change} = 1
  if [ ${change} -eq 1 ]; then

    # If ${inode} path doesnt exist in ${remotes[@]}
    if [ $(in_array_fuzzy "${inode}" "${remotes[@]}") -eq 1 ]; then

      # Set group ownership to ${def_group} on ${inode}
      chgrp ${def_group} ${inode} 2>/dev/null

      # Handle return
      if [ $? -ne 0 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Could not set group ownership on '${inode}'" 1
      fi
    else

      # If ${disable_remote} = 1
      if [ ${disable_remote} -eq 1 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Remote; Skipping '${inode}'; enable with 'disable_remote=0'"
      else

        # Set group ownership to ${def_group} on ${inode}
        chgrp ${def_group} ${inode} 2>/dev/null

        # Handle return
        if [ $? -ne 0 ]; then

          # Print friendly message
          [ ${verbose} -eq 1 ] && print "Could not set group ownership on '${inode}'" 1
        fi
      fi
    fi
  fi

  # Get current group ownership of ${inode}
  cgrp=$(get_inode_group ${inode})

  # Determine if ${cgrp} exists in ${acts[@]}
  if [ $(in_array "${cgrp}" "${acts[@]}") -ne 0 ]; then

    # Assign ${inode} to ${errs[@]}
    errs+=("${inode}:${cgrp}")
    continue
  fi

  # Assign ${inode} to ${val[@]}
  vals+=("${inode}:${cgrp}")

done


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Calls to scripts with an invalid group ownership found" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Split ${err} into file
    efile="$(echo "${err}" | cut -d: -f1)"

    # Split ${err} into group
    egrp="$(echo "${err}" | cut -d: -f2)"

    # Assign ${inode} to ${errs[@]}
    if [ $(in_array_fuzzy "${efile}" "${remotes[@]}") -eq 0 ]; then
      efile="[Remote/NFS] ${efile}"
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${efile} [${egrp}]" 1
  done

  exit 1
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "Validated '${#vals[@]}/${#tmp_files[@]}' executable inodes referenced from '${#files[@]}' init scripts"

# Iterate ${vals[@]}
for val in ${vals[@]}; do

  # Split ${v} into file
  vfile="$(echo "${val}" | cut -d: -f1)"

  # Split ${v} into group
  vgrp="$(echo "${val}" | cut -d: -f2)"

  # Validate ${vfile} as existing in ${remotes[@]}
  if [ $(in_array_fuzzy "${vfile}" "${remotes[@]}") -eq 0 ]; then
    vfile="[Remote/NFS] ${vfile}"
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "  ${vfile} [${vgrp}]"
done


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, system conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0059841
# STIG_Version: SV-74271r1
# Rule_ID: SOL-11.1-020370
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: All system start-up files must be group-owned by root, sys, or bin.
# Description: If system start-up files do not have a group owner of root or a system group, the files may be modified by malicious users or intruders.

