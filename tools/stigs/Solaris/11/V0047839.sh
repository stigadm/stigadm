#!/bin/bash

# Declare audit policies to add
declare -a audit_policies
audit_policies+=("zonename")


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
caller=$(ps -p $PPID | grep -c stigadm)


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

# Define an array of inspected items
declare -a inspected

# Define an array of errors
declare -a errors

# Get currently defined audit policies
declare -a policies
policies=( $(auditconfig -getpolicy | grep "^active" | nawk '{print $5}' | tr ',' ' ') )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "setpolicy:$(echo "${policies[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Bail if we can't create a backup
    report "Failed to create backup of audit policies" && exit 1
  fi


  # Iterate ${audit_policies[@]}
  for audit_policy in ${audit_policies[@]}; do

    # Add ${audit_policy} from auditconfig
    auditconfig -setpolicy +${audit_policy} 2>/dev/null

    # Trap errors
    [ $? -ne 0 ] && errors+=("auditconfig:setpolicy:${audit_policy}")
  done

  # Refresh audit policies
  policies=( $(auditconfig -getpolicy | grep "^active" | nawk '{print $5}' | tr ',' ' ') )
fi


# Iterate ${audit_policies[@]}
for audit_policy in ${audit_policies[@]}; do

  # Look for perzone in ${policies[@]} array
  if [ $(in_array "${audit_policy}" "${policies[@]}") -ne 0 ]; then
    errors+=("auditconfig:getpolicy:${audit_policy}")
  fi

  # Make sure we populate ${inspected}
  inspected+=("auditconfig:getpolicy:${audit_policy}")
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
[ ${#errors[@]} -gt 0 ] && failed=1 || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})

# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
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


# Date: 2018-09-05
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0047839
# STIG_Version: SV-60713r1
# Rule_ID: SOL-11.1-100040
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must identify in which zone an event occurred.
# Description: The audit system must identify in which zone an event occurred.
