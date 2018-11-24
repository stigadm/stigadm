#!/bin/bash


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
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is from stigadm
caller=$(ps $PPID | grep -c stigadm)


###############################################
# Global zones only check
###############################################

# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then

  # Report warning & exit module
  report "${stigid} only applies to global zones" && exit 1
fi


###############################################
# STIG validation/remediation/restoration
###############################################

# Set ${status} to false
status=0

# Get a blob of the current status
blob="$(auditconfig -getcond)"

# Get boolean of current status
status=$(echo "${blob}" | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')


# If ${restore} = 1 go to restoration mode
if [[ ${restore} -eq 1 ]] && [[ ${status} -eq 1 ]]; then

  # Do work
  audit -t
  if [ $? -ne 0 ]; then

    # Report & exit module
    report "Failed to stop audit service" && exit 1
  fi

  # Report & exit module
  report "Successfully disabled audit service" && exit 0
fi


# If ${change} == 1 & ${status} = 0
if [[ ${change} -eq 1 ]] && [[ ${status} -eq 0 ]]; then

  # Do work
  audit -s 2>/dev/null

  # Get a blob of the current status
  blob="$(auditconfig -getcond)"

  # Get boolean of current status
  status=$(echo "${blob}" | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')
fi


###############################################
# Results for printable report
###############################################

# If ${status} != 1
if [ ${status:=0} -ne 1 ]; then

  # Set ${results} error message
  results="Failed validation"

  # Populate a value in ${errors[@]} if ${caller} is > 0
  [ ${caller} -gt 0 ] && errors=("${stigid}")
fi

# Set ${results} passed message
[ ${status} -eq 1 ] && results="Passed validation"


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
[ ${status} -eq 1 ] && exit 0 || exit 1


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047787
# STIG_Version: SV-60663r1
# Rule_ID: SOL-11.1-010080
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must provide the capability to automatically process audit records for events of interest based upon selectable, event criteria.
# Description: Without an audit reporting capability, users find it difficult to identify specific patterns of attack.
