#!/bin/bash

# OS: Solaris
# Version: 11
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-47881
# Name: SV-60753r2


# Global defaults for tool
author=
verbose=0
change=0
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
while getopts "ha:cvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
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

print "Not yet implemented" && exit 0

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


# Print friendly message
[ ${verbose} -eq 1 ] && print "Searching for updates"

# Obtain updates (if any)
updates="$(pkg update -n)"

if [ $? -ne 0 ]; then
  print "An error occurred retrieving updates from configured repositories" 1
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtaining meta data"

# Get the package removal count from ${update}
removal=($(echo "${updates}" | awk '{if ($0 ~ /Packages to remove/){obj=$4} if ($0 ~ /Removal instruction/){getline; obj1=$5} if (obj != "" && obj1 != ""){print obj":"obj1}}'))

# Get the package installation count from ${update}
install=($(echo "${updates}" | awk '{if ($0 ~ /Packages to install/){obj=$4} if ($0 ~ /Removal instruction/){getline; obj1=$5} if (obj != "" && obj1 != ""){print obj":"obj1}}'))
install_cnt=$(echo "${updates}" | awk '$0 ~ /Packages to install/{print $4}')

# Get the package update count from ${update}
update_cnt=$(echo "${updates}" | awk '$0 ~ /Packages to update/{print $4}')

# Get the removal command(s) to help with a restore point
removal=("$(echo "${updates}" | sed -n '/Removal instruction/,/Generic Instructions/p' | grep "#")")


# Use the following for verbose error output
#[ ${verbose} -eq 1 ] && print "error output, notice the 1 =>" 1


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047881
# STIG_Version: SV-60753r2
# Rule_ID: SOL-11.1-020010
#
# OS: Solaris
# Version: 11
# Architecture: Sparc
#
# Title: The System packages must be up to date with the most recent vendor updates and security fixes.
# Description: The System packages must be up to date with the most recent vendor updates and security fixes.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047881
# STIG_Version: SV-60753r2
# Rule_ID: SOL-11.1-020010
#
# OS: Solaris
# Version: 11
# Architecture: X86
#
# Title: The System packages must be up to date with the most recent vendor updates and security fixes.
# Description: The System packages must be up to date with the most recent vendor updates and security fixes.

