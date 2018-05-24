#!/bin/bash


# Define an array of loggin services that should be enabled
declare -a services
services+=('auditd')
services+=('system-log')

# Define an array of plugins that should be active for auditing
#  Format: <PLUGIN>:<FLAGS> or <PLUGIN>
declare -a plugins
plugins+=("audit_syslog:p_flags=all")

# Define an array of remote logging hosts
#  - Can be defined as: <IP>:<HOSTNAME> or <HOSTNAME>
declare -a log_hosts
log_hosts+=('solaris')

# Global defaults for tool
author=
verbose=0
change=0
json=1
meta=0
restore=0
interactive=0
xml=0


# Working directory
cwd="$(dirname $0)"

# Tool name
prog="$(basename $0)"


# Copy ${prog} to DISA STIG ID this tool handles
stigid="$(echo "${prog}" | cut -d. -f1)"


# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


# Define the library include path
lib_path=${cwd}/../../../libs

# Define the tools include path
tools_path=${cwd}/../../../stigs

# Define the system backup path
backup_path=${cwd}/../../../backups/$(uname -n | awk '{print tolower($0)}')


# Robot, do work


# Error if the ${inc_path} doesn't exist
if [ ! -d ${lib_path} ] ; then
  echo "Defined library path doesn't exist (${lib_path})" && exit 1
fi


# Include all .sh files found in ${lib_path}
incs=($(ls ${lib_path}/*.sh))

# Exit if nothing is found
if [ ${#incs[@]} -eq 0 ]; then
  echo "'${#incs[@]}' libraries found in '${lib_path}'" && exit 1
fi


# Iterate ${incs[@]}
for src in ${incs[@]}; do

  # Make sure ${src} exists
  if [ ! -f ${src} ]; then
    echo "Skipping '$(basename ${src})'; not a real file (block device, symlink etc)"
    continue
  fi

  # Include $[src} making any defined functions available
  source ${src}

done

# Create a timestamp
ts=$(gen_date)

# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "ha:cjmvrix" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    j) json=1 ;;
    m) meta=1 ;;
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    x) xml=1 ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
fi


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Ensure a logging service is defined
if [ ${#services[@]} -eq 0 ]; then
  print "'${#services[@]}' remote logging services are defined" 1
  exit 1
fi

# Ensure audit plugins are defined
if [ ${#plugins[@]} -eq 0 ]; then
  print "'${#plugins[@]}' audit plug ins are defined" 1
  exit 1
fi

# Ensure configuration options are defined
if [ ${#log_hosts[@]} -eq 0 ]; then
  print "'${#log_hosts[@]}' remote syslog/rsyslog hosts defined" 1
  exit 1
fi


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# Validate ${#plugins[@]} defined
if [ ${#plugins[@]} -eq 0 ]; then
  usage "'${#plugins[@]}' plugins that should be enabled defined"
  exit 1
fi


# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${file}'"

  fi

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Restored '${file}'"

  exit 0
fi


# Define an array for inactive audit plugins
declare -a inactive

# Define an array for active audit plugins
declare -a active


# Define an associative array for errors
declare -A err


# Find syslog.conf or rsyslog.conf & make a backup
log="$(find / -xdev -type f -name "syslog.conf")"

# If ${log} is empty, try rsyslog.conf
if [ "${log}" == "" ]; then
  log="$(find / -xdev -type f -name "rsyslog.conf")"
fi


# Use /etc/hosts
hosts="/etc/hosts"

# Make sure we are working on the actual file
hosts="$(get_inode "${hosts}")"


# If ${hosts} doesn't exist make it
if [ ! -f ${hosts} ]; then
  hosts=/etc/inet/hosts
  touch ${hosts}
  chown root:sys ${hosts}
  chmod 00644 ${hosts}
fi

# If ${log} doesn't exist make it
if [ ! -f ${log} ]; then
  log=/etc/syslog.conf
  touch ${log}
  chown root:sys ${log}
  chmod 00644 ${log}
fi


# Iterate ${log_hosts[@]}
for log_host in ${log_hosts[@]}; do

  # If both IP & Hostname defined in ${log_host} split it up
  if [ $(echo "${log_host}" | grep -c ":") -gt 0 ]; then
    ip="$(echo "${log_host}" | cut -d: -f1)"
    hname="$(echo "${log_host}" | cut -d: -f2)"
  else
    hname="$(echo "${log_host}")"
  fi

  # Determine if ${log_host} is an RFC-1123 hostname
  if [ $(echo "${hname}" | nawk -v regex_hostname="${regex_hostname}" '{if($0 ~ regex_hostname){print 0}else{print 1}}') -ne 0 ]; then
    print "'${hname}' did not pass RFC-1123 validation..." 1
  fi

  # If ${ip} is defined
  if [ -z ${ip} ]; then

    # Determine if ${log_host} is an IPv4 or IPv6 address
    if [ $(echo "${ip}" | nawk -v regex_ipv4="${regex_ipv4}" -v regex_ipv6=${regex_ipv6} '{if($0 ~ regex_ipv4 || $0 ~ regex_ipv6){print 0}else{print 1}}') -eq 0 ]; then
      print "'${hname}' did not pass RFC-1123 validation..." 1
    fi
  fi


  # If only ${ip} OR ${hname} exist try to rely on DNS
  if [[ "${ip}" == "" ]] || [[ "${hname}" == "" ]]; then

    # If only the IP exists
    if [[ "${ip}" != "" ]] && [[ "${hname}" == "" ]]; then
      hname="$(nslookup ${ip} 2> /dev/null | awk '$1 ~ /^Name/{getline; print $2}')"
    fi

    # If only the hostname exists
    if [[ "${ip}" == "" ]] && [[ "${hname}" != "" ]]; then
      ip="$(nslookup ${hname} 2> /dev/null | awk '$1 ~ /^Name/{getline; print $2}')"
    fi
  fi

  # Create a new value for ${hosts[@]} (set default ${ip} to localhost (127.0.0.1)
  loghosts+=("${ip:=127.0.0.1}:${hname}")
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Get a list of active audit plugins
  active=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}'))

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=("$(echo "setplugin:${active[@]}" | tr ' ' ',')")

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugins for '${stigid}' failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current audit plugins for '${stigid}'"

  # If ${log} exists make a backup
  if [ -f ${log} ]; then
    bu_file "${author}" "${log}"
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Could not create a backup of '${log}', exiting..." 1
      exit 1
    fi
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${log}'"


  # If ${hosts} exists make a backup
  if [ -f ${hosts} ]; then
    bu_file "${author}" "${hosts}"
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Could not create a backup of '${hosts}', exiting..." 1
      exit 1
    fi
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${hosts}'"


  # Iterate ${services[@]}
  for service in ${services[@]}; do

    # Disable any ${services[@]}
    svcadm disable ${service} 2>/dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred disabling '${service}'" 1
    fi
  done

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Disabled requested services; [$(truncate_cols "$(echo "${services[@]}" | tr ' ' '|')")]"


  # Make a copy of ${log}
  cp -p ${log} ${log}-${ts}

  # Add/Modify ${log} 'audit.notice @loghost'
  if [ $(grep -c "^audit.notice" ${log}) -gt 0 ]; then
    sed "s|^\(audit.notice\).*$|\1                                    @loghost|g" ${log} > ${log}-${ts}
  else

    # Make sure the formatting is accurate when appending
    cat <<EOF >> ${log}-${ts}

audit.notice                                    @loghost

EOF
  fi

  # Double check addition/modification
  if [ $(grep -c "^audit.notice.*@loghost$" ${log}-${ts}) -gt 0 ]; then

    # Move ${log}-${ts} back in place
    mv ${log}-${ts} ${log}
  else

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "'audit.notice' was not found in '${log}-${ts}'..." 1
    rm ${log}-${ts}
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Remote logging enabled to '@loghost' (defined in ${hosts})"


  # If ${#loghosts[@]} > 0
  if [ ${#loghosts[@]} -gt 0 ]; then

    # Iterate ${hosts[@]}
    for log_host in ${loghosts[@]}; do

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


      # Make a copy of ${hosts} to preserve permissions
      cp -p ${hosts} ${hosts}-${ts}

      # Add/modify the entry to ${hosts}
      if [ $(grep -c "^${ip}" ${hosts}) -gt 0 ]; then
        sed "s|^${ip}.*$|${ip} ${hname} loghost|g" ${hosts} > ${hosts}-${ts}
      else
        echo "${ip} ${hname} loghost" >> ${hosts}-${ts}
      fi


      # Double check addition/modification
      if [ $(grep -c "^${ip}.*${hname}.*loghost$" ${hosts}-${ts}) -gt 0 ]; then

        # Move ${hosts}-${ts} back in place
        mv ${hosts}-${ts} ${hosts}
      else

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "'${ip} ${hname} loghost' was not found in '${hosts}-${ts}'..." 1
        rm ${hosts}-${ts}
      fi
    done

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Configured remote logging hosts; [$(truncate_cols "$(echo "${loghosts[@]}" | tr ' ' '\n' | cut -d: -f1 | tr ' ' '|')")]"
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
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Unable to enable audit plug-in '${plugin}'" 1
    fi
  done

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Enabled audit plug-ins; [$(truncate_cols "$(echo "${plugins[@]}" | tr ' ' '\n' | cut -d: -f1 | tr ' ' '|')")]"


  # Iterate ${services[@]}
  for service in ${services[@]}; do

    # Refresh ${services[@]}
    svcadm refresh ${service} 2>/dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred refreshing '${service}'" 1
    fi

    # Enable any ${services[@]}
    svcadm enable ${service} 2>/dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred enabling '${service}'" 1
    fi
  done

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Re-enabled services; [$(truncate_cols "$(echo "${services[@]}" | tr ' ' '|')")]"
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
