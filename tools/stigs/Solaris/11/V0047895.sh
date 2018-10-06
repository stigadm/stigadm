#!/bin/bash


# Define an array of zone ppriv attributes any configured zone must use
declare -a pprivs
pprivs+=("limitpriv:default")


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

# Create a filter based on ${pprivs[@]}
filter="$(echo "${pprivs[@]}" | tr ' ' '\n' | cut -d: -f1)"


# Acquire list of configured/installed zones
zones=( $(zoneadm list -civ | awk 'NR > 1 && $0 !~ /global|solaris-kz/{print $2}') )

# Iterate ${zones[@]}
for zone in ${zones[@]}; do

  # Acquire properties for anything matching ${filter}
  props+=( "${zone}:"$(zonecfg -z ${zone} info | egrep ${filter} | awk '{printf("%s%s\n", $1, $2)}') )
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${props[@]}"
  if [ $? -ne 0 ]; then

    # Trap error
    report "Snapshot of zones and properties failed..."

    # Stop, we require a backup
    exit 1
  fi


  # Iterate ${props[@]}
  for prop in ${props[@]}; do

    # Cut ${prop} into zone, key & values
    zone="$(echo "${prop}" | cut -d: -f1)"
    key="$(echo "${prop}" | cut -d: -f2)"
    values=( $(echo "${prop}" | cut -d: -f3 | tr ',' ' ') )


    # Make a needle out of ${pprivs[${key}]
    needle="$(echo "${pprivs[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2)"


    # Bail if ${pprivs[@]} key/value exist
    [ $(in_array "${needle}" "${values[@]}") -eq 0 ] &&
      continue


    # Create an array of configured property values from ${pprivs[@]}
    dvalues=( $(echo "${pprivs[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2 | tr ',' ' ') )

    # Merge ${values[@]} w/ ${dvalues[@]} matching ${key}
    values=( $(echo "${dvalues[@]}" "${values[@]}" | tr ' ' '\n' | sort -u) )


    # If we are making a change
    if [ ${change} -eq 1 ]; then

      # Set ${key} on ${zone} to ${values[@]}
      zonecfg -z ${zone} set ${key}=$(echo "${values[@]}" | tr ' ' ',') 2>/dev/null

      # Determine if an error is to be raised
      [ $? -ne 0 ] && errors+=("Configured:${zone}:${prop}")

      # Set ${key} on the running zone ${zone} to ${values[@]}
      zonecfg -r -z ${zone} set ${key}=$(echo "${values[@]}" | tr ' ' ',') 2>/dev/null

      # Determine if an error is to be raised
      [ $? -ne 0 ] && errors+=("Running:${zone}:${prop}")
    fi


    # Raise an error if ${values[@]} doesn't match
    cval=$(zonecfg -z ${zone} info ${key} | grep -c "$(echo "${values[@]}" | tr ' ' ',')")
    [ ${cval} -le 0 ] && errors+=("Configured:${zone}:${prop}")

    # Raise an error if ${values[@]} doesn't match
    cval=$(zonecfg -r -z ${zone} info ${key} | grep -c "$(echo "${values[@]}" | tr ' ' ',')")
    [ ${cval} -le 0 ] && errors+=("${prop}")
  done
fi


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
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0047895
# STIG_Version: SV-60767r3
# Rule_ID: SOL-11.1-100020
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The limitpriv zone option must be set to the vendor default or less permissive.
# Description: The limitpriv zone option must be set to the vendor default or less permissive.
