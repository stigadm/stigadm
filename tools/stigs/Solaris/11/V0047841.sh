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

# Get an array of currently configured & running zones
zones=( $(zoneadm list -vci | awk '$2 !~ /global|NAME/{print $2}' | sort -u) )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Iterate ${zones[@]}
  for zone in ${zones[@]}; do

    # Get a list of configuration file(s) applicable for all ${zones[@]} found
    config="$(find / -xdev -type f -name "${zone}.xml")"

    # Skip backup if ${config} doesn't exist
    [ "${config}" == "" ] && continue

    # If ${config} is a file make a backup
    if [ -f ${config} ]; then

      # Backup ${config}
      bu_file "${author}" "${config}"
      if [ $? -ne 0 ]; then

        # Bail if we can't create a backup
        report "Failed to create backup of zone configurations" && exit 1
      fi

      # Backup running zone as well
      bu_configuration "${backup_path}" "${author}" "${stigid}" "$(zonecfg -r -z ${zone} info)"
      if [ $? -ne 0 ]; then

        # Bail if we can't create a backup
        report "Failed to create backup of running zone configurations" && exit 1
      fi
    fi


    # Acquire a list of devices for ${zone}
    devices=( $(zonecfg -z ${zone} info | awk '$0 ~ /^device/{if(total == ""){total=0}else{total++}print total}') )

    # If ${#devices[@]} is 0, skip
    [ ${#devices[@]} -eq 0 ] && continue

    # Iterate ${devices[@]} (in reverse order)
    for device in $(echo "${devices[@]}" | tr ' ' '\n' | sort -r); do

      # Remove ${device} from the zone
      zonecfg -z ${zone} remove device ${device} 2>/dev/null

      # Trap errors
      [ $? -ne 0 ] &&
        errors+=("Error:removing:${device}") ||
        inspected+=("Removed:${device}")

      # Remove ${device} from the running zone configuration
      zonecfg -r -z ${zone} remove device ${device} 2>/dev/null

      # Trap errors
      [ $? -ne 0 ] &&
        errors+=("Error:removing:${device}") ||
        inspected+=("Removed:${device}")
    done

    # Ensure the zone is commit'd of the recent device removals
    zonecfg -z ${zone} commit 2>/dev/null

    # Trap errors
    [ $? -ne 0 ] && errors+=("Error:saving:${zone}")

    # Ensure the zone is commit'd of the recent device removals
    zonecfg -r -z ${zone} commit 2>/dev/null

    # Trap errors
    [ $? -ne 0 ] && errors+=("Error:saving:${zone}")

    # Ensure the zone is refreshed
    zonecfg -z ${zone} refresh 2>/dev/null

    # Trap errors
    [ $? -ne 0 ] && errors+=("Error:refreshing:${zone}")

    # Ensure the zone is refreshed
    zonecfg -r -z ${zone} refresh 2>/dev/null

    # Trap errors
    [ $? -ne 0 ] && errors+=("Error:refreshing:${zone}")
  done
fi


# Iterate ${zones[@]}
for zone in ${zones[@]}; do

  # Acquire a list of devices for ${zone}
  devices=( $(zonecfg -z ${zone} info 2>/dev/null | awk '$0 ~ /^device/{if(total == ""){total=0}else{total++}print total}') )

  # Trap errors
  [ $? -ne 0 ] && errors+=("Examining:configuration:${zone}")

  # If ${#devices[@]} > 0
  [ ${#devices[@]} -gt 0 ] &&
    errors+=("${zone}:${#devices[@]}:$(echo "${devices[@]}"|tr ' ' ',')") ||
    inspected+=("Configured:${zone}")

  # Acquire a list of devices for ${zone}
  devices=( $(zonecfg -r -z ${zone} info 2>/dev/null | awk '$0 ~ /^device/{if(total == ""){total=0}else{total++}print total}') )

  # Trap errors
  [ $? -ne 0 ] && errors+=("Examining:running:configuration:${zone}")

  # If ${#devices[@]} > 0
  [ ${#devices[@]} -gt 0 ] &&
    errors+=("${zone}:${#devices[@]}:$(echo "${devices[@]}"|tr ' ' ',')") ||
    inspected+=("Running:${zone}")
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
# STIG_ID: V0047841
# STIG_Version: SV-60715r1
# Rule_ID: SOL-11.1-100030
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The systems physical devices must not be assigned to non-global zones.
# Description: The systems physical devices must not be assigned to non-global zones.
