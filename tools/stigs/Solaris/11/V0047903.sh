#!/bin/bash

# Define an array of whitelisted applications
declare -a whitelisted
whitelisted+=("pkg://solaris/security/compliance/openscap")


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

# Obtain list of currently installed packages
pkgs=( $(get_packages | tr ' ' '\n' | cut -d@ -f1) )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${pkgs[@]} | tr ' ' '\n')"
  if [ $? -ne 0 ]; then

    # Trap error
    report "Snapshot of current installed packages failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Iterate ${whitelisted[@]}
  for whitelist in ${whitelisted[@]}; do

    # Remove ${blaclist}
    pkg install -q ${whitelist} 2>/dev/null
    [ $? -ne 0 ] && errors+=("${whitelist}")
  done


  # Obtain list of currently installed packages
  pkgs=( $(get_packages | tr ' ' '\n' | cut -d@ -f1) )
fi


# Verbose
inspected=("${pkgs[@]}")

# Iterate ${whitelisted[@]}
for whitelist in ${whitelisted[@]}; do

  # Trap errors
  [ $(in_array ${whitelist} ${pkgs[@]}) -gt 0 ] &&
    errors+=("${whitelist}")
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
# STIG_ID: V0047903
# STIG_Version: SV-60775r1
# Rule_ID: SOL-11.1-090270
#
# OS: Solaris
# Version: 11
# Architecture: Sparc
#
# Title: The operating system must identify potentially security-relevant error conditions.
# Description: Security functional testing involves testing the operating system for conformance to the operating system security function specifications, as well as for the underlying security model. The need to verify security functionality applies to all security functions. The conformance criteria state the conditions necessary for the operating system to exhibit the desired security behavior or satisfy a security property. For example, successful login triggers an audit entry.
