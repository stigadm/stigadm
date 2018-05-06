#!/bin/bash


# Global defaults for tool
author=
verbose=0
change=0
meta=0
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
while getopts "ha:cmvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    m) meta=1 ;;
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


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
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


# Get list of published online repositories
publishers=( $(pkg publisher | awk 'NR > 1 && $3 == "online"{printf("%s:%s\n", $1, $5)}') )

# Make sure we have at least one or bail
if [ ${#publishers[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "No defined repositories published" 1
  exit 1
fi


# Obtain the gateway
gateway="$(netstat -nr | awk '$1 == "default"{print $2}')"

# Bail if no gateway defined
if [ "${gateway}" == "" ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "No gateway configured" 1
  exit 1
fi


# Test connectivity or bail
if [ $(ping ${gateway} | grep -c "alive") -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Unable to reach gateway" 1
  exit 1
fi


# Iterate ${publishers[@]}
for publisher in ${publishers[@]}; do

  # Split up the name to test functionality
  server="$(echo "${publisher}" | cut -d: -f3 | cut -d"/" -f3)"

  # Test for resolution via nameserver
  ip="$(nslookup -retry=2 -timeout=5 ${server} 2>/dev/null | awk '$1 ~ /^Name/{getline; print $2}')"

  # Skip if ${ip} is null
  [ "${ip}" == "" ] && continue

  # Skip if ${ip} not online
  [ $(ping ${gateway} | grep -c "alive") -eq 0 ] && continue

  # Increment ${online} for each pass
  online=$(add ${online} 1)
done


# If ${online} is 0 bail
if [ ${online:=0} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "${online} package repositories connecting" 1
  exit 1
fi


# Get total number of packages to install/update
pkgs=( $(pkg update -n 2>/dev/null | awk '$0 ~ /install|update/{print $4}') )

# Bail early if already conforms
if [ ${#pkgs[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Success, conforms to'${stigid}'"
  exit 0
fi


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${pkgs[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current packages to update failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of installable/updateable packages"

  # Update the system
  pkg update -q 2>/dev/null

  # If an error occurs trap it
  [ $? -gt 0 ] && error=1
fi


# Exit with errors
if [ ${error:=0} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Does not conform to '${stigid}'"
  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0


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
