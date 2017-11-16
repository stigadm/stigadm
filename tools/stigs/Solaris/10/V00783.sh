#!/bin/bash


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


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating compliance with STIG ID '${stigid}'"


# Get running process list into ${processes}
sec_updates=("$(smpatch analyze)")

# Make sure ${#sec_updates[@]} > 0
if [ ${#sec_updates[@]} -gt 0 ]; then
  [ ${verbose} -eq 1 ] && print "No security updates found for system" 1
  exit 1
fi

[ ${verbose} -eq 1 ] && print "Obtained list of security updates"


# Iterate ${sec_updates[@]} & update or make
for update in ${sec_updates[@]}; do

  [ ${verbose} -eq 1 ] && print "A security update exists for '${update}'"

  # If ${change} -gt 0 do work
  if [ ${change} -eq 1 ]; then

    [ ${verbose} -eq 1 ] && print "Performing update for '${update}'"

    smpatch update -i ${update}

    if [ $? -ne 0 ]; then
      [ ${verbose} -eq 1 ] && print "An error occurred performing update for '${update}'" 1
      ret=1
    fi
done


# Exit with error code
if [ ${ret} -ne 1 ]; then
  [ ${verbose} -eq 1 ] && print "Some updates failed for STIG ID '${stigid}'" 1
  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, system is running an IDS on allowed list conforming to STIG ID '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00783
# STIG_Version: SV-40813r2
# Rule_ID: GEN000120
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00783
# STIG_Version: SV-40813r2
# Rule_ID: GEN000120
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: System security patches and updates must be installed and up-to-date.
# Description: System security patches and updates must be installed and up-to-date.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00783
# STIG_Version: SV-40813r2
# Rule_ID: GEN000120
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: System security patches and updates must be installed and up-to-date.
# Description: System security patches and updates must be installed and up-to-date.

