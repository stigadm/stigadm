#!/bin/bash

# Module specific variables go here

# Files: file=/path/to/file
# Arrays: declare -a array_name
# Strings: foo="bar"
# Integers: x=9


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

# Module specific validation code should go here
# Errors should go in ${errors[@]} array (which on remediation get handled)
# All inspected items should go in ${inspected[@]} array

errors=("${stigid}")


# If ${change} = 1
#if [ ${change} -eq 1 ]; then

  # Create the backup env
  #backup_setup_env "${backup_path}"

  # Create a backup (configuration output, file/folde permissions output etc
  #bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${array_values[@]}" | tr ' ' '\n')"
  #bu_file "${backup_path}" "${author}" "${stigid}" "${file}"
  #if [ $? -ne 0 ]; then
    # Stop, we require a backup
    #report "Unable to create backup" && exit 1
  #fi

  # Iterate ${errors[@]}
  #for error in ${errors[@]}; do

    # Work to remediate ${error} should go here
  #done
#fi

# Remove dupes
#inspected=( $(remove_duplicates "${inspected[@]}") )


###############################################
# Results for printable report
###############################################

# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Set ${results} error message
  #results="Failed validation"    UNCOMMENT ONCE WORK COMPLETE!
  results="Not yet implemented!"
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


# Date: 2018-09-18
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0058901
# STIG_Version: SV-73331r2
# Rule_ID: RHEL-06-000529
#
# OS: Red_Hat
# Version: 6
# Architecture: 
#
# Title: The sudo command must require authentication.
# Description: The "sudo" command allows authorized users to run programs (including shells) as other users, system users, and root. The "/etc/sudoers" file is used to configure authorized "sudo" users as well as the programs they are allowed to run. Some configuration options in the "/etc/sudoers" file allow configured users to run programs without re-authenticating. Use of these configuration options makes it easier for one compromised account to be used to compromise other accounts.

