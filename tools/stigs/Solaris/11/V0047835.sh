#!/bin/bash

# Define the aliases file
aliases=/etc/mail/aliases

# Define the notification stanza
declare -a log_levels
log_levels+=("audit_warn")


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

# Define an array of inspected items
declare -a inspected

# Define an array of errors
declare -a errors

# Bail if ${log_levels[@]} not defined
if [ ${#log_levels[@]} -eq 0 ]; then
  report "${#log_levels[@]} log levels defined" && exit 1
fi

# Iterate ${log_levels[@]} to determine which one is the error
for log_level in ${log_levels[@]}; do

  # Push ${log_level} to ${errors[@]} if not found in ${aliases}
  [ $(grep -c ${log_level} ${aliases}) -eq 0 ] && errors+=("${log_level}:${aliases}")

  # Add ${log_level} to ${inspected[@]} array
  inspected+=("${log_level}:${aliases}")
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
[ ${#errors[@]} -le 0 ] && passed=1 || passed=0
[ ${#errors[@]} -ge 1 ] && failed=${#errors[@]} || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})


# If the caller was only independant
if [ ${caller} -eq 0 ]; then


  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#err[@]} -gt 0 ] && print_array ${log} "errors" "${err[@]}"
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
    [ ${#err[@]} -gt 0 ] && print_array ${log} "errors" "${err[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Disable debugging if it was enabled
###############################################
[ ${debug} -eq 1 ] && set +x


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047835
# STIG_Version: SV-60709r1
# Rule_ID: SOL-11.1-010370
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must alert the SA when the audit storage volume approaches its capacity.
# Description: Filling the audit storage area can result in a denial of service or system outage and can lead to events going undetected.
