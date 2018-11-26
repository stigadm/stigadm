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


# Date: 2018-07-18
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0075571
# STIG_Version: SV-90251r1
# Rule_ID: UBTU-16-010780
#
# OS: Ubuntu
# Version: 16.04
# Architecture: LTS
#
# Title: All local interactive user initialization files executable search paths must contain only paths that resolve to the system default or the users home directory.
# Description: The executable search path (typically the PATH environment variable) contains a list of directories for the shell to search to find executables. If this path includes the current working directory executables in these directories may be executed instead of system commands. This variable is formatted as a colon-separated list of directories. If there is an empty entry, such as a leading or trailing colon or two consecutive colons, this is interpreted as the current working directory. If deviations from the default system search path for the local interactive user are required, they must be documented with the Information System Security Officer (ISSO).

