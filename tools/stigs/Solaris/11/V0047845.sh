#!/bin/bash

# Define the aliases file
aliases=/etc/mail/aliases

# Define an array of users to handle audit notifications
declare -a administrators
administrators+=("root@localhost")


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

# Get a list of currently defined users in ${aliases} for audit_warn
cur_aliases=( $(grep "^audit_warn" ${aliases} | cut -d: -f2 | sort -u | tr ',' ' ') )

# Combine ${cur_aliases[@]} with ${administrators[@]} & remove dupes
administrators=( "$(remove_duplicates "${cur_aliases[@]}" "${administrators[@]}")" )

# Create a string from ${administrators[@]}
administrators_str="$(echo "${administrators[@]}" | tr ' ' ',')"

# Chop the ending ","
administrators_str="$(echo "${administrators_str}" | sed "s|,$||g")"


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # If ${aliases} exists make a backup
  if [ -f ${aliases} ]; then
    bu_file "${author}" "${aliases}"
    if [ $? -ne 0 ]; then

      # Print friendly message
      report "Could not create a backup of '${aliases}', exiting..."
      exit 1
    fi
  fi


  # Create a working copy
  cp -p ${aliases} ${aliases}-${ts}


  # If ^audit_warn exists in ${aliases}
  if [ $(grep -c "^audit_warn:" ${aliases}) -gt 0 ]; then

    # Replace audit_warn with our new combined list of users
    sed "s|^\(audit_warn:\).*$|\1${administrators_str}|g" ${aliases} > ${aliases}-${ts}
  else

    # Add our new list of administrators
    echo "audit_warn:${administrators_str}" >> ${aliases}-${ts}
  fi


  # Make sure ${administrators_str} exists
  if [ $(grep -c "^audit_warn:${administrators_str}" ${aliases}-${ts}) -eq 0 ]; then

    # Trap the error
    errors+=("Error:adding:${administrators_str}:to:${aliases}")
    rm ${aliases}-${ts}
  else
    mv ${aliases}-${ts} ${aliases}

    # Import the aliases
    newaliases &>/dev/null

    # Trap error
    [ $? -ne 0 ] && errors+=("Error:importing:${administrators_str}")
  fi


  # Refresh ${cur_aliases[@]}
  cur_aliases=( $(grep "^audit_warn" ${aliases} | cut -d: -f2 | sort -u | tr ',' ' ') )
fi


# Flag error if ${#cur_aliases[@]} is 0
[ ${#cur_aliases[@]} -eq 0 ] && errors+=("Missing:${administrators_str}")

inspected+=("${aliases}:audit_warn:${administrators_str}")


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
# Severity: CAT-I
# Classification: UNCLASSIFIED
# STIG_ID: V0047845
# STIG_Version: SV-60719r1
# Rule_ID: SOL-11.1-010390
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must alert designated organizational officials in the event of an audit processing failure.
# Description: Proper alerts to system administrators and IA officials of audit failures ensure a timely response to critical system issues.
