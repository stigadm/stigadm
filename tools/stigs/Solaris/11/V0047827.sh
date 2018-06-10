#!/bin/bash


###############################################
# STIG specific audit flags
###############################################

# Define the hosts file
host=/etc/hosts

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
  usage "${stigid} only applies to global zones" && exit 1
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
  usage "${#services[@]} remote logging services are defined" && exit 1
fi

# Ensure audit plugins are defined
if [ ${#plugins[@]} -eq 0 ]; then
  usage "${#plugins[@]} audit plug ins are defined" && exit 1
fi


###############################################
# Perform restoration
###############################################

# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  usage "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

# Double check ${host}
host="$(get_inode ${host})"

# Obtain an array of hosts in /etc/hosts
declare -a hosts
hosts=( $(grep -v "^#" ${host} | sort -u) )

# Find syslog.conf or rsyslog.conf & make a backup
conf="$(find / -xdev -type f -name "syslog.conf")"

# If ${log} is empty, try rsyslog.conf
if [ "${conf}" == "" ]; then
  conf="$(find / -xdev -type f -name "rsyslog.conf")"
fi

# If ${conf} doesn't exist bail
if [ ! -f ${conf} ]; then
  usage "Unable to locate syslog/rsyslog configuration" && exit 1
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
    usage "Could not create backup of audit plugins" && exit 1
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
fi


# Check ${log} for audit.notice @loghost entry
if [ $(grep -c "^audit.notice.*@loghost" ${log}) -le 0 ]; then

  # If the ${err['Syslog']} key exists
  if [ -z ${err['Syslog']} ]; then
    err['Syslog']="No_remote_loghosts_defined"
  else
    err['Syslog']="${err['Servers']}:No_remote_loghosts_defined"
  fi
fi


# Get currently configured 'loghost' entries from ${hosts} file
cur_hosts=( $(grep "loghost$" ${hosts} | awk '{printf("%s:%s\n", $1, $2)}') )

# Push to ${err['Servers']} if empty
if [ ${#cur_hosts[@]} -eq 0 ]; then

  # If the ${err['Services']} key exists
  if [ -z ${err['Servers']} ]; then
    err['Servers']="No_loghosts_defined"
  else
    err['Servers']="${err['Servers']}:No_loghosts_defined"
  fi
fi

# Iterate ${hosts[@]}
for log_host in ${cur_hosts[@]}; do

  # Split ${log_host} into ${ip} & ${hname}
  ip="$(echo "${log_host}" | cut -d: -f1)"
  hname="$(echo "${log_host}" | cut -d: -f2)"

  # Flag ${ip} if a local address (default)
  if [ "${ip}" == "127.0.0.1" ]; then

    # If the ${err['Services']} key exists
    if [ -z ${err['Servers']} ]; then
      err['Servers']="${ip}_${hname}"
    else
      err['Servers']="${err['Servers']}:${ip}_${hname}"
    fi
  fi
done


# Acquire all running (online) services
cur_services=( $(svcs -a | awk '$1 ~ /^online/{split($3, obj, ":");print obj[2]}' | sort -u) )

# Iterate ${services[@]}
for service in ${services[@]}; do

  # Determine if ${service} exists in ${cur_services[@]}
  if [ $(in_array_loose "${service}" "${cur_services[@]}") -ne 0 ]; then

    # If the ${err['Services']} key exists
    if [ -z ${err['Services']} ]; then
      err['Services']="${service}"
    else
      err['Services']="${err['Services']}:${service}"
    fi
  fi
done


# Get a list of inactive audit plugins
inactive=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 ~ /inactive/{print $2}'))

# Get a list of active audit plugins
active=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}'))

# Iterate ${plugins[@]}
for plugin in ${plugins[@]}; do

  # If ${plugin} contains a ':' split it up to get the necessary flags
  if [ $(echo "${plugin}" | grep -c ":") -gt 0 ]; then
    plugin="$(echo "${plugin}" | cut -d: -f1)"
  fi

  # If ${plugin} doesn't exist in ${inactive[@]} & ${active[@]}
  if [[ $(in_array "${plugin}" "${inactive[@]}") -eq 1 ]] && [[ $(in_array "${plugin}" "${active[@]}") -ne 0 ]]; then

    # If the ${err['Plugins']} key exists
    if [ -z ${err['Plugins']} ]; then
      err['Plugins']="${plugin}"
    else
      err['Plugins']="${err['Plugins']}:${plugin}"
    fi
  fi
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Could not validate '${stigid}'" 1

  # Iterate ${err[@]}
  for error in ${!err[@]}; do

    # Split ${error} into an array
    errors=( $(echo "${err[${error}]}" | tr ':' ' ') )

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${error}:  " 1

    # Iterate ${errors[@]}
    for e in ${errors[@]}; do

      # Break ${e} up if need be
      e="$(echo "${e}" | tr '_' ' ')"

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "     ${e}" 1
    done | sort -u
  done

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
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
