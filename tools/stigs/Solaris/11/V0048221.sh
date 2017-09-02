#!/bin/bash

# OS: Solaris 
# Version: 11
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-48221
# Name: SV-61093r1


# Define the hosts.allow path
hosts_allow=/etc/hosts.allow

# Define the hosts.allow path
hosts_deny=/etc/hosts.deny

# Define an array of subnet's to query
declare -a filter

# EBN network possibilities
filter+=("1.12.")
filter+=("1.212.")
filter+=("1.214.")

# OOB network possibilities
filter+=("2.12.")
filter+=("2.14.")
filter+=("2.32.")

# Production network possibilities
filter+=("131.77.")
filter+=("144.251.")
filter+=("214.6.")

# IBoIP network possibilities
filter+=("192.168.")

read -d '' wrapper_tpl <<"EOF"
ALL:{RANGE}:banners /etc/issue
EOF


# Global defaults for tool
author=
verbose=0
change=0
restore=0
interactive=0

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


# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "ha:cvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Make sure network filters is defined
if [ ${#filter[@]} -eq 0 ]; then

  # Print friendly message
  usage "Must define at least one filter IP range"
fi

# Convert ${filter[@]} into a string filter
str_filter="$(echo "${filter[@]}" | tr ' ' '|')"


# Obtain current list of networks based on ${str_filter}
nets=( $(ifconfig -a | grep "inet" | nawk -v filter="${str_filter}" '$2 ~ filter{split($2, obj, ".");print obj[1]"."obj[2]"."}'|sort -u) )

# Make sure we found some defined networks
if [ ${#nets[@]} -eq 0 ]; then

  # Print friendly message
  print "'${#nets[@]}' found matching provided filter(s); ${filter[@]}" 1
  exit 0
fi


# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then
  
    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${stigid}'"

  fi

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Restored '${stigid}'"

  exit 0
fi


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create a backup of ${hosts_allow}
  bu_file "${author}" "${hosts_allow}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${hosts_allow}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${hosts_allow}'"


  # Get the backup file name
  ballow="$(bu_file_last "${hosts_allow}" "${author}")"


  # Iterate ${filter[@]}
  for rule in ${filter[@]}; do

    # Create a BRE pattern from ${rule}
    pattern="$(echo "${rule}" | cut -d: -f1,2)"

    # Create a sed compatible pattern from ${pattern}
    spattern="^$(echo "${pattern}" | sed -e 's|\([:|.]\)|\\\1|g').*"

    # look for ${rule} in ${hosts_allow}
    if [ "$(grep -i "${spattern}" ${hosts_allow})" != "" ]; then

      # Make a temporary to work with
      tallow="$(gen_tmpfile "${hosts_allow}" "root:root" 00600 1)"

      # Change ${rule} in ${ballow} and copy to ${hosts_allow}
      sed -e "s|${spattern}|${rule}|g" ${hosts_allow} > ${tallow}

      # Handle the error
      if [ $? -ne 0 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "An error occurred when editing '${hosts_allow}'" 1
        
        # Remove ${tallow}
        rm ${tallow}
      else
      
        # Copy ${tallow} over to ${hosts_allow}
        mv -f ${tallow} ${hosts_allow}
      fi
    else

      # create the new ${rule} in ${hosts_allow}
      echo "${rule}" >> ${hosts_allow}
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Added '${rule}' to '${hosts_allow}'"
  done


  # Create a backup of ${hosts_deny}
  bu_file "${author}" "${hosts_deny}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${hosts_deny}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${hosts_deny}'"


  # Get the backup file name
  bdeny="$(bu_file_last "${hosts_deny}" "${author}")"

  # look for ${rule} in ${hosts_deny}
  if [ "$(grep -i "^ALL*$" ${hosts_deny})" != "" ]; then

    # Make a temporary to work with
    tdeny="$(gen_tmpfile "${hosts_deny}" "root:root" 00600 1)"

    # Change ${rule} in ${bdeny} and copy to ${hosts_deny}
    sed -e "s|^ALL.*$|ALL:ALL : banners /etc/banners|g" ${hosts_deny} > ${tdeny}

    # Handle the error
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred when editing '${hosts_deny}'" 1
      
      # Remove ${tdeny}
      rm ${tdeny}
    else
      
      # Move ${tdeny} over to ${hosts_deny}
      mv ${tdeny} ${hosts_deny}
    fi
  else

    # create the new ${rule} in ${hosts_deny}
    echo "ALL:ALL : banners /etc/banners" >> ${hosts_deny}
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Added 'ALL: ALL' to '${hosts_deny}'"


  # Set default tcp wrapper value to TRUE
  inetadm -M tcp_wrappers=TRUE 2> /dev/null

  # Handle the error
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "An error occurred modifying the default tcp_wrapper value"
  fi
fi


# Capture the current IFS
cIFS="$IFS"

# Change the $IFS
IFS=+

# Set the default return value
ret=0

# Iterate ${allowed[@]}
for rule in ${allowed[@]}; do

  # Create a BRE pattern from ${rule}
  pattern="^$(echo "${rule}" | cut -d: -f1,2)*$"

  # look for ${rule} in ${hosts_allow}
  if [ "$(grep -i "${pattern}" ${hosts_allow})" == "" ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "'${rule}' does not exist in '${hosts_allow}'" 1

    # Flag the error
    ret=1
  else

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Rule '${rule}' exists in '${hosts_allow}'"
  fi
done

# Reset the $IFS
IFS="${cIFS}"


# Get tcp wrappers value
wrapper="$(inetadm -p | grep tcp_wrappers | cut -d= -f2)"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained current inetd wrapper value; '${wrapper}'"

# If ${wrapper} != TRUE
[ "${wrapper}" != "TRUE" ] && print "TCP_WRAPPER is not enabled for all inetd services '${wrapper}'" 1


# Define an empty array for offending inetd services
declare -a offenders

# Get list of services that are enabled
svcs_list=($(inetadm | nawk '$1 ~ /^enabled$/ || $2 ~ /^online$/ && $3 ~ /^svc:\//{print $NF}'))

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained list of inetd services; '${#svcs_list[@]}'"

# if ${#svcs_list[@]} > 0
if [ ${#svcs_list[@]} -gt 0 ]; then

  # Iterate ${svcs_list[@]}
  for svc in ${svcs_list[@]}; do

    # Get current value of ${svc} into a new array named ${offenders[@]}
    offenders+=($(inetadm -l ${svc} | nawk -v svc="${svc}" '$2 ~ /^TCP_WRAPPERS=.*/ && $2 !~ /.*TRUE/{print svc}'))
  done

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Got list of offending inetd services; '${#offenders[@]}'"
fi


# Show errors
if [[ ${#offenders[@]} -gt 0 ]] || [[ "${wrapper}" != "TRUE" ]] || [[ "$(grep -i "^ALL:*$" ${bdeny})" != "" ]] || [[ ${ret} -ne 0 ]]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "System does not conform to '${stigid}'" 1

  # If ${#offenders[@]} -gt 0
  if [ ${#offenders[@]} -gt 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "These services are running/enabled without TCP_WRAPPERS enabled:" 1

    # Iterate ${offenders[@]}
    for offender in ${offenders[@]}; do

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "  - ${offender}" 1
    done
  fi
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0
