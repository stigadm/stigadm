#!/bin/bash

# Define the owner of p_dir
owner="root"

# Define the group of p_dir
group="root"

# Define the octal for p_dir
octal=00640


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


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a backup value
  bu_blob="audit_binfile:setplugin:$(echo "${audit_settings[@]}" | tr ' ' ',')"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${bu_blob}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    report "Snapshot of current audit plugin values failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Set user ownership on ${audit_folder}
  chown ${owner} ${audit_folder} 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("${audit_folder}:${owner}:$(get_inode_user "${audit_folder}")")


  # Set group ownership on ${audit_folder}
  chgrp ${group} ${audit_folder} 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("${audit_folder}:${group}:$(get_inode_group "${audit_folder}")")


  # Set permissions on ${audit_folder}
  chmod ${octal} ${audit_folder} 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("${audit_folder}:${octal}:$(get_inode_user "${audit_folder}")")


  # Restart the auditd service
  audit -s 2>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("auditconfig:service:restart")
fi


# Validate user ownership
cowner="$(get_inode_user ${audit_folder})"

# Trap the error
[ "${cowner}" != "${owner}" ] &&
  errors+=("Owner:${audit_folder}:${owner}:${cowner}")

# Show what we examined
inspected+=("Owner:${audit_folder}:${cowner}")


# Validate group ownership
cgroup="$(get_inode_group ${audit_folder})"

# Trap the error
[ "${cowner}" != "${owner}" ] &&
  errors+=("Group:${audit_folder}:${group}:${cgroup}")

# Show what we examined
inspected+=("Group:${audit_folder}:${cgroup}")

# Validate octal
coctal="$(get_octal ${audit_folder})"

# Trap the error
[ ${coctal} -gt ${octal} ] &&
  errors+=("Permissions:${audit_folder}:${octal}:${coctal}")

# Show what we examined
inspected+=("Permissons:${audit_folder}:${coctal}")


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
