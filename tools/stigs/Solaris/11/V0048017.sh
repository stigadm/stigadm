#!/bin/bash


# Define an array of allowed group owners
declare -a gowners
gowners+=("root")
gowners+=("bin")
gowners+=("sys")


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


# Make sure ${gowners[@]} > 0
if [ ${#gowners[@]} -eq 0 ]; then
  usage "Must define at least one allowed group owner" && exit 1
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


# Obtain current path defined for core dumps
dmppath="$(dirname $(coreadm | sed -n "s/global core file pattern: \(.*\)/\1/p"))"

# If ${dmppath} is not a directory exit
if [ ! -d ${dmppath} ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Could not obtain path for core dumps" 1
  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained path for core dumps; '${dmppath}'"


# If ${change} > 0
if [ ${change} -ne 0 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${inodes[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${dmppath}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current permissions"

  # Set ${dmppath} = ${gowners[0]}
  chgrp ${gowners[0]} ${dmppath}

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Set '${gowners[0]}' on '${dmppath}'"
fi


# Get current octal value of ${dmppath}
gowner=$(get_inode_group ${dmppath})

# Compare ${gowner} with allowed list in ${gowners[@]}
if [ $(in_array "${gowner}" "${gowners[@]}") -eq 1 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${dmppath}' group ownership does NOT conform to '${stigid}' (${gowner})" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048017
# STIG_Version: SV-60889r1
# Rule_ID: SOL-11.1-080060
#
# OS: Solaris
# Version: 11
# Architecture: Sparc
#
# Title: The centralized process core dump data directory must be group-owned by root, bin, or sys.
# Description: The centralized process core dump data directory must be group-owned by root, bin, or sys.

