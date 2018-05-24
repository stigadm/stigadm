#!/bin/bash

# audit min free space
audit_min_free_space=5

# Define an array of ZFS attributes to validate/modify
declare -a zfs_attrs
zfs_attrs+=('compression')
zfs_attrs+=('reservation')
zfs_attrs+=('quota')

# Define an empty array to hold audit pluign settings
declare -a audit_settings

# Define an empty array to hold zfs settings
declare -a zfs_settings


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


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
fi


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


# Obtain an array of audit settings regarding 'bin_file' plugin
audit_settings=( $(auditconfig -getplugin audit_binfile | awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )


# Get the auditing filesystem from ${audit_settings[@]}
audit_folder="$(dirname $(get_inode "$(echo "${audit_settings[@]}" | tr ' ' '\n' | grep "^p_dir" | cut -d: -f2)"))"

# Get the auditing min_free value from ${audit_settings[@]}
fs_free="$(echo "${audit_settings[@]}" | tr ' '  '\n' | grep "^p_minfree" | cut -d: -f2)"


# Obtain an array of zfs shares matching ${audit_folder}
zfs_list=( $(zfs list | grep "${audit_folder}" | awk '{printf("%s:%s\n", $1, $5)}') )

# Iterate ${zfs_list}
for zfs_item in ${zfs_list[@]}; do

  # Extract the zfs_path & dataset name
  zfs_path="$(echo "${zfs_item}" | cut -d: -f1)"
  zfs_dataset="$(echo "${zfs_item}" | cut -d: -f2)"

  # Look for ${audit_folder} in ${zfs_item}
  needle="$(find_dir ${zfs_dataset} $(basename ${audit_folder}))"

  # If ${needle} exists we have our dataset name
  if [ "${needle}" != "" ]; then
    zfs_fs="${zfs_path}"
    break
  fi
done

# Break down if nothing exists for ${zfs_fs}
if [ "${zfs_fs}" == "" ]; then
  [ ${verbose} -eq 1 ] && print "Could not determine an audit filesystem to examine" 1
  exit 1
fi


# Set ${opts} from ${zfs_attrs[@]} array
opts="$(echo "${zfs_attrs[@]}" | tr ' ' ',')"

# Clean up trailing , if any
opts="$(echo "${opts}" | sed "s|,$||g")"


# Obtain an array of ZFS values for the p_file value of ${audit_settings[@]}
zfs_settings=( $(zfs get ${opts} "${zfs_fs}" | awk '$0 !~ /^NAME/{printf("%s:%s:%s\n", $1, $2, $3)}') )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "audit_binfile:setplugin:$(echo "${audit_settings[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugin values failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current audit plugin values for 'audit_binfile'"


  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${zfs_settings[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugin values failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot settings applied to '${zfs_fs}' ZFS dataset"


  # Set the p_minfree value for the audit_binfile audit plugin
  auditconfig -setplugin audit_binfile p_minfree=${audit_min_free_space}
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not set the minimum free space for the audit service..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Restart the auditd service
  audit -s
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not restart the audit service..." 1
  fi


  # Obtain an array of audit settings regarding 'bin_file' plugin
  audit_settings=( $(auditconfig -getplugin audit_binfile | awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )
fi


# Define an empty array ot handle errors
declare -a errors


# Iterate ${zfs_attrs[@]}
for attr in ${zfs_attrs[@]}; do

  # Get the current ${key} from ${zfs_settings[@]}
  cur_value="$(echo "${zfs_settings[@]}" | tr ' ' '\n' | grep "${attr}" | cut -d: -f3)"

  # Test ${cur_value}
  if [ $(echo "${cur_value}" | egrep -c 'off|none') -gt 0 ]; then
    errors+=("${zfs_fs}:${attr}:${cur_value}")
  fi
done


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  [ ${verbose} -eq 1 ] && print "Could not validate '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    # Split up ${error}
    fs="$(echo "${error}" | cut -d: -f1)"
    key="$(echo "${error}" | cut -d: -f2)"
    value="$(echo "${error}" | cut -d: -f3)"

    [ ${verbose} -eq 1 ] && print "  ${fs} ${key} [${value}]" 1

  done
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047857
# STIG_Version: SV-60731r2
# Rule_ID: SOL-11.1-010400
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must allocate audit record storage capacity.
# Description: Proper audit storage capacity is crucial to ensuring the ongoing logging of critical events.
