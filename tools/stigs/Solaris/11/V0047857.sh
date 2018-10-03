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


###############################################
# Bootstrapping environment setup
###############################################

# Get our working directory
cwd="$(pwd)"

# Define our bootstrapper location
bootstrap="${cwd}/tools/bootstrap.sh"

# Bail if it cannot be found
if [ ! -f ${bootstrap} ]; then
  echo "Unable to locate bootstrap; ${bootstrap}" && exit 1
fi

# Load our bootstrap
source ${bootstrap}


###############################################
# Global zones only check
###############################################

# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  report "${stigid} only applies to global zones" && exit 1
fi


###############################################
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is as group
caller=$(ps $PPID | grep -c stigadm)


###############################################
# Perform restoration
###############################################

# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  report "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

# Obtain an array of audit settings regarding 'bin_file' plugin
audit_settings=( $(auditconfig -getplugin audit_binfile |
  awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )


# Get the auditing filesystem from ${audit_settings[@]}
audit_folder="$(dirname $(get_inode "$(echo "${audit_settings[@]}" |
  tr ' ' '\n' | grep "^p_dir" | cut -d: -f2)"))"

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
  report "Could not determine an audit filesystem to examine"
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

  # Capture current values
  bu_blob="audit_binfile:setplugin:$(echo "${audit_settings[@]}" | tr ' ' ',')"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${bu_blob}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    report "Snapshot of current audit plugin values failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${zfs_settings[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    report "Snapshot of current audit plugin values failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Set the p_minfree value for the audit_binfile audit plugin
  auditconfig -setplugin audit_binfile p_minfree=${audit_min_free_space} 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("Setting:min_free_space")


  # Restart the auditd service
  audit -s 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("Restarting:service")

  # Obtain an array of audit settings regarding 'bin_file' plugin
  audit_settings=( $(auditconfig -getplugin audit_binfile |
    awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )
fi


# Define an empty array ot handle errors
declare -a errors


# Iterate ${zfs_attrs[@]}
for attr in ${zfs_attrs[@]}; do

  # Get the current ${key} from ${zfs_settings[@]}
  cur_value="$(echo "${zfs_settings[@]}" | tr ' ' '\n' | grep "${attr}" | cut -d: -f3)"

  # Test ${cur_value}
  [ $(echo "${cur_value}" | egrep -c 'off|none') -gt 0 ] &&
    errors+=("${zfs_fs}:${attr}:${cur_value}")

  # Show what was inspected
  inspected+=("${zfs_fs}:${attr}:${cur_value}")
done


###############################################
# Results for printable report
###############################################

# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Set ${results} error message
  results="Failed validation"
fi

# Set ${results} passed message
[ ${#errors[@]} -eq 0 ] && results="Passed validation"


###############################################
# Report generation specifics
###############################################

# Apply some values expected for report footer
[ ${#errors[@]} -eq 0 ] && passed=1 || passed=0
[ ${#errors[@]} -gt 0 ] && failed=${#errors[@]} || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})


# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


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
