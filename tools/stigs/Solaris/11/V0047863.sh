#!/bin/bash

# Define an array of policy kernel params
declare -a policy
policy+=("ahlt")


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

# If ${change} == 1
if [ ${change} -eq 1 ]; then

  # Get an array of default policy flags
  cur_policy=($(auditconfig -getpolicy |
    awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))


  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=("$(echo "setpolicy:${cur_policy[@]}" | tr ' ' ',')")

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    report "Snapshot of current audit flags for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Combine & remove duplicates from ${policy[@]} & ${cur_policy[@]}
  set_policy=( $(remove_duplicates "${policy[@]}" "${cur_policy[@]}") )

  # Convert ${set_defpolicy[@]} into a string
  defpol="$(echo "${set_policy[@]}" | tr ' ' ',')"


  # Set the value(s) to the audit service
  auditconfig -setpolicy ${defpol} &>/dev/null

  # Trap error
  [ $? -ne 0 ] && errors+=("Failed:set:auditconfig:setpolicy:${defpol}")
fi


# Get an array of default policy flags
cur_policy=($(auditconfig -getpolicy 2>/dev/null | awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

# Iterate ${policy[@]}
for pol in ${policy[@]}; do

  # Check for ${flag} in ${cur_policy[@]}
  [ $(in_array "${pol}" "${cur_policy[@]}") -eq 1 ] && errors+=("policy:${pol}")

  # Show inspected
  inspected+=("auditconfig:getpolicy:${pol}")
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
