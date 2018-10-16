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

# Obtain an array of users
declare -a accounts
accounts=( $(filter_accounts 1 $(get_accounts)) )

# Bail if nothing found
if [ ${#accounts[@]} -eq 0 ]; then
  report "Unable to obtain array of user accounts" && exit 1
fi

# Define an array for user audit flags
declare -a users

# Iterate all user accounts on system
for account in ${accounts[@]}; do

  # Skip root account
  [ "${account}" == "root" ] && continue

  # Get list of users & any auditing flags
  users+=("${account}:$(userattr audit_flags ${account})")
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${users[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    report "Unable to create snapshot of per user audit flags" && exit 1
  fi

  # Iterate ${users[@]}
  for user in ${users[@]}; do

    # Cut out the username from ${user}
    user="$(echo "${user}" | cut -d: -f1)"

    # Reset all audit_flags per ${user}
    usermod -K audit_flags= ${user} 2>/dev/null

    # Trap error
    [ $? -gt 1 ] && errors+=("audit_flags:${user}")
  done

  # Reset ${users[@]} so we can refresh it
  users=()

  # Iterate all user accounts on system
  for account in ${accounts[@]}; do

    # Skip root account
    [ "${account}" == "root" ] && continue

    # Get list of users & any auditing flags
    users+=("${account}:$(userattr audit_flags ${account})")
  done
fi

# Iterate ${users[@]}
for user in ${users[@]}; do

  # Split ${user} up
  flags="$(echo "${user}" | cut -d: -f2)"
  user="$(echo "${user}" | cut -d: -f1)"

  # If ${flags} is not NULL then add to an error array
  [ "${flags}" != "" ] && errors+=("audit_flags:${user}")

  # If verbosity enabled
  [ ${verbose} -eq 1 ] && inspected+=("audit_flags:${user}")
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
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2017-06-21
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0047831
# STIG_Version: SV-60705r1
# Rule_ID: SOL-11.1-010360
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The auditing system must not define a different auditing level for specific users.
# Description: Without auditing, individual system accesses cannot be tracked, and malicious activity cannot be detected and traced back to an individual account.
