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

# Get list of published online repositories
publishers=( $(get_pkg_publishers) )

# Make sure we have at least one
[ ${#publishers[@]} -eq 0 ] && errors+=("Missing:repositories")

# Be verbose
inspected+=("Repositories:${publishers[@]}")


# Get total number of packages to install/update
[ ${#errors[@]} -eq 0 ] &&
  pkgs=( $(pkg update -n 2>&1 |
    awk '$0 ~ /install|update/ && $4 ~ /^[0-9]/{print $4}') )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${pkgs[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Trap error
    report "Snapshot of current packages to update failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Create ${inspected[@]} from ${pkgs[@]}
  inspected+=( "${pkgs[@]}" )

  # Update the system
  pkg update -q 2>/dev/null

  # Trap errors
  [ $? -ne 0 ] && errors+=("Package:update:failed")


  # Refresh ${pkgs[@]}
  pkgs=( $(pkg update -n 2>&1 |
    awk '$0 ~ /install|update/ && $4 ~ /^[0-9]/{print $4}') )
fi


# Be verbose
inspected+=( $(get_packages) )


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
# STIG_ID: V0047881
# STIG_Version: SV-60753r2
# Rule_ID: SOL-11.1-020010
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The System packages must be up to date with the most recent vendor updates and security fixes.
# Description: Failure to install security updates can provide openings for attack.
