#!/bin/bash


###############################################
# STIG specific audit flags
###############################################

# Define an array of logging services that should be enabled
declare -a services
services+=('auditd')
services+=('system-log')

# Define an array of plugins that should be active for auditing
#  Format: <PLUGIN>:<FLAGS> or <PLUGIN>
declare -a plugins
plugins+=("audit_syslog:p_flags=all")


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
# Validate configuration definitions
###############################################

# Ensure a logging service is defined
if [ ${#services[@]} -eq 0 ]; then
  report "${#services[@]} remote logging services are defined" && exit 1
fi

# Ensure audit plugins are defined
if [ ${#plugins[@]} -eq 0 ]; then
  report "${#plugins[@]} audit plug ins are defined" && exit 1
fi


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

# Find syslog.conf or rsyslog.conf & make a backup
conf="$(find / -xdev -type f -name "syslog.conf")"

# If ${log} is empty, try rsyslog.conf
if [ "${conf}" == "" ]; then
  conf="$(find / -xdev -type f -name "rsyslog.conf")"
fi

# If ${conf} doesn't exist bail
if [ ! -f ${conf} ]; then
  report "Unable to locate syslog/rsyslog configuration" && exit 1
fi

# Since ${log} was found get an array of hosts for audit.*
declare -a logging_hosts
logging_hosts=( $(grep "^audit" ${conf} |
  nawk '$2 ~ /\@/{gsub(/\@/, "", $2);print $2}') )

# Get an array of active audit plugins
declare -a audit_plugins
audit_plugins=( $(auditconfig -getplugin 2>/dev/null |
  nawk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}') )

# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=( $(echo "setplugin:${audit_plugins[@]}" | tr ' ' ',') )

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Bail and notify
    report "Could not create backup of audit plugins" && exit 1
  fi

  # Iterate ${plugins[@]}
  for plugin in ${plugins[@]}; do

    # If ${plugin} contains a ':' split it up to get the necessary flags
    if [ $(echo "${plugin}" | grep -c ":") -gt 0 ]; then
      plugin="$(echo "${plugin}" | cut -d: -f1)"
      flags="$(echo "${plugin}" | cut -d: -f2)"
    fi

    # Make change according to ${stigid}
    auditconfig -setplugin ${plugin} active "${flags}" 2> /dev/null

    # Add to ${errors[@]}
    [ $? -ne 0 ] && errors+=("${plugin}:${flags}")

    # If verbosity enabled
    [ ${verbose} -eq 1 ] && inspected+=("${plugin}:${flags}")
  done

  # Iterate ${services[@]}
  for service in ${services[@]}; do

    # Refresh ${services[@]}
    svcadm refresh ${service} 2>/dev/null

    # Add to ${errors[@]}
    [ $? -ne 0 ] && errors+=("service:${service}")

    # Enable any ${services[@]}
    svcadm enable ${service} 2>/dev/null

    # Add to ${errors[@]}
    [ $? -ne 0 ] && errors+=("service:${service}")
  done

  # Refresh the audit plugins list
  audit_plugins=( $(auditconfig -getplugin 2>/dev/null |
    nawk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}') )
fi

# Validate remote logging hosts in ${log}
[ ${#logging_hosts[@]} -eq 0 ] && errors+=("logging:${conf}")

# If verbosity enabled
[ ${verbose} -eq 1 ] && inspected+=("logging:${conf}")


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


# Date: 2018-09-05
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0047827
# STIG_Version: SV-60703r2
# Rule_ID: SOL-11.1-010350
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must protect against an individual falsely denying having performed a particular action. In order to do so the system must be configured to send audit records to a remote audit server.
# Description: Keeping audit records on a remote system reduces the likelihood of audit records being changed or corrupted. Duplicating and protecting the audit trail on a separate system reduces the likelihood of an individual being able to deny performing an action.
