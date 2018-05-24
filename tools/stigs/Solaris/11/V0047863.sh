#!/bin/bash

# Define an array of policy kernel params
declare -a policy
policy+=("ahlt")


# Global defaults for tool
author=
verbose=0
change=0
json=1
meta=0
restore=0
interactive=0
xml=0
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
while getopts "ha:cjmvrix" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    j) json=1 ;;
    m) meta=1 ;;
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    x) xml=1 ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Make sure we have required defined values
if [ ${#policy[@]} -eq 0 ]; then

  print "Requires one or more default policies defined" 1
  exit 1
fi


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
fi


# If ${restore} = 1 go to restoration mode
if [[ ${restore} -eq 1 ]] && [[ ${cond} -eq 1 ]]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${file}'"

  fi

  # Do work
  audit -t
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Unable to disable auditing" 1
    exit 1
  fi

  exit 0
fi


# If ${change} == 1
if [ ${change} -eq 1 ]; then

  # Get an array of default policy flags
  cur_policy=($(auditconfig -getpolicy | awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))


  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=("$(echo "setpolicy:${cur_policy[@]}" | tr ' ' ',')")

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit flags for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current default audit flags & policies"


  # Combine & remove duplicates from ${policy[@]} & ${cur_policy[@]}
  set_policy=( $(remove_duplicates "${policy[@]}" "${cur_policy[@]}") )

  # Convert ${set_defpolicy[@]} into a string
  defpol="$(echo "${set_policy[@]}" | tr ' ' ',')"


  # Set the value(s) to the audit service
  auditconfig -setpolicy ${defpol} &>/dev/null

  # Handle results
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "An error occurred setting default audit policy: ${defpol}" 1
  fi
fi


# Declare an empty array for errors
declare -a err


# Get an array of default policy flags
cur_policy=($(auditconfig -getpolicy 2>/dev/null | awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

# Iterate ${policy[@]}
for pol in ${policy[@]}; do

  # Check for ${flag} in ${cur_policy[@]}
  [ $(in_array "${pol}" "${cur_policy[@]}") -eq 1 ] && err+=("policy:${pol}")
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  print "Current audit settings does not conform to '${stigid}'" 1

  # Iterate ${err[@]}
  for error in ${err[@]}; do

    # Get setting from ${error}
    setting="$(echo "${error}" | cut -d: -f1)"

    # Get options from ${error}
    option="$(echo "${error}" | cut -d: -f2)"

    # Print friendly message
    print "  ${setting} (${option})" 1
  done | sort -u

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047863
# STIG_Version: SV-60737r1
# Rule_ID: SOL-11.1-010420
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must shut down by default upon audit failure (unless availability is an overriding concern).
# Description: Continuing to operate a system without auditing working properly can result in undocumented access or system changes.
