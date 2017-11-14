#!/bin/bash

# OS: Solaris
# Version: 10
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-761
# Name: SV-27061r2


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


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating user accounts according to STIG ID '${stigid}'"

# Get ${settings} from ${file}
users=("$(passwd -sa | sort | uniq -c | awk '$1 > 1 {print $2}')")


# Return if ${#users[@]} = 0
if [ ${#users[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Success, all accounts conform to '${stigid}'"

  exit 0
fi

  
# If ${users[@]} is > 1 then notify
if [ ${#users[@]} -ge 1 ]; then

  if [ ${verbose} -eq 1 ]; then
    print "Failed validation for '${stigid}'; Found duplicate accounts" 1

    # Iterate ${users[@]} and list duplicate accounts
    for user in ${users[@]}; do
      print "  Account: ${user}" 1
    done
  fi

  exit 1
fi
  
# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, all accounts conform to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00761
# STIG_Version: SV-27061r2
# Rule_ID: GEN000300
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: All accounts on the system must have unique user or account names.
# Description: All accounts on the system must have unique user or account names.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00761
# STIG_Version: SV-27061r2
# Rule_ID: GEN000300
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: All accounts on the system must have unique user or account names.
# Description: All accounts on the system must have unique user or account names.

