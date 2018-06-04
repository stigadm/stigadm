#!/bin/bash


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

# Define the library template path(s)
templates=${cwd}/tools/templates/

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
  echo "${#incs[@]} libraries found in '${lib_path}'" && exit 1
fi


# Iterate ${incs[@]}
for src in ${incs[@]}; do

  # Make sure ${src} exists
  if [ ! -f ${src} ]; then
    echo "Skipping $(basename ${src}); not a real file"
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
while getopts "ha:cjl:mvrix" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    j) json=1 ;;
    l) log=$OPTARG ;;
    m) meta=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    x) xml=1 && ext="xml" && json=0 ;;
    ?) usage && exit 1 ;;
  esac
done


# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  usage "${stigid} only applies to global zones" && exit 1
fi


# Set the default log if nothing provided (/var/log/stigadm/<OS>-<VER>-<DATE>.json|xml)
log="${log:=/var/log/${appname}/${os}-${version}-${timestamp}.${ext:=json}}"

# If ${log} doesn't exist make it
[ ! -f ${log} ] && (mkdir -p $(dirname ${log}) && touch ${log})

# Acquire array of meta data
declare -a meta
meta=( $(get_meta_data "${cwd}" "${prog}") )

# Bail if ${#meta[@]} >= 0
if [ ${#meta[@]} -le 0 ]; then
  usage "Unable to acquire meta data for ${stigid}" && exit 1
fi


# Set ${cond} to false
cond=0

# Get boolean of current status
cond=$(auditconfig -getcond | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')


# If ${restore} = 1 go to restoration mode
if [[ ${restore} -eq 1 ]] && [[ ${cond} -eq 1 ]]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    print "Not yet implemented"
  fi

  # Do work
  audit -t
  [ $? -ne 0 ] && exit 1

  exit 0
fi


# If ${change} == 1 & ${cond} = 0
if [[ ${change} -eq 1 ]] && [[ ${cond} -eq 0 ]]; then

  # Do work
  audit -s
  if [ $? -ne 0 ]; then
    [ $? -ne 0 ] && exit 1
  fi

  # Get boolean of current status
  cond=$(auditconfig -getcond | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')
fi


# Get EPOCH
e_epoch="$(gen_epoch)"

seconds=$(subtract ${s_epoch} ${e_epoch})

# Generate a run time
[ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."


# If ${cond} != 1
if [ ${cond:=0} -ne 1 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Auditing is not enabled" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047781
# STIG_Version: SOL-11.1-010040
# Rule_ID: SV-60657r1
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must produce records containing sufficient information to establish the identity of any user/subject associated with the event.
# Description: Enabling the audit system will produce records with accurate time stamps, source, user, and activity information. Without this information malicious activity cannot be accurately tracked.
