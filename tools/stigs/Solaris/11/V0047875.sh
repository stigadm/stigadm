#!/bin/bash

# Define an empty array to hold audit pluign settings
declare -a audit_settings

# Define the owner of p_dir
owner="root"

# Define the group of p_dir
group="root"

# Define the octal for p_dir
octal=00640


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

# Define an empty array ot handle errors
declare -a errors


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


  # Set user ownership on ${audit_folder}
  chown ${owner} ${audit_folder} 2>/dev/null
  if [ $? -ne 0 ]; then

    # Trap error
    [ $? -ne 0 ] && errors+=("${audit_folder}:${owner}:$(get_inode_user "${audit_folder}")")
  fi

  # Set group ownership on ${audit_folder}
  chgrp ${group} ${audit_folder} 2>/dev/null
  if [ $? -ne 0 ]; then

    # Trap error
    [ $? -ne 0 ] && errors+=("${audit_folder}:${group}:$(get_inode_group "${audit_folder}")")
  fi

  # Set permissions on ${audit_folder}
  chmod ${octal} ${audit_folder} 2>/dev/null
  if [ $? -ne 0 ]; then

    # Trap error
    [ $? -ne 0 ] && errors+=("${audit_folder}:${octal}:$(get_inode_user "${audit_folder}")")
  fi

  # Restart the auditd service
  audit -s
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not restart the audit service..." 1
  fi
fi


# Validate user ownership
cowner="$(get_inode_user ${audit_folder})"
if [ "${cowner}" != "${owner}" ]; then

  # Trap error
  errors+=("${audit_folder}:${owner}:${cowner}")
fi

# Validate group ownership
cgroup="$(get_inode_group ${audit_folder})"
if [ "${cowner}" != "${owner}" ]; then

  # Trap error
  errors+=("${audit_folder}:${group}:${cgroup}")
fi

# Validate octal
coctal="$(get_octal ${audit_folder})"
if [ ${coctal} -ne ${octal} ]; then

  # Trap error
  errors+=("${audit_folder}:${octal}:${coctal}")
fi

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
# Severity: CAT-I
# Classification: UNCLASSIFIED
# STIG_ID: V0047875
# STIG_Version: SV-60747r1
# Rule_ID: SOL-11.1-010450
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must protect audit information from unauthorized modification.
# Description: The operating system must protect audit information from unauthorized modification.
