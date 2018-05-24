#!/bin/bash


# Define an array of packages to inspect
declare -a packages
packages+=("system/zones")


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


# Bail if ${#packages[@]} is 0
if [ ${#packages[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Must define at least one package" 1
  exit 1
fi


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
publishers=( $(get_pkg_publishers) )

# Make sure we have at least one or baill
if [ ${#publishers[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "No defined repositories published" 1
  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained package repository list"


# Obtain gateways on node
gateways=( $(get_gateways) )

# Bail if no gateways defined
if [ ${#gateways[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "No gateways configured" 1
  exit 1
fi


# Resolve ${publishers[@]} to IP's
nodes=( $(resolve_hosts "${publishers[@]}") )

# If ${#nodes[@]} is 0 bail
if [ ${#nodes[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "${#nodes[@]} package repositories resolving" 1
  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Performed rudimentary connectivity tests"


# Get a blob to cache results of 'pkg verify'
blob="$(pkg verify -H "${packages[@]}" 2>/dev/null)"

# Break ${blob} up into an easy to manage  array of packages
pkgs=( $(parse_pkg_verify "${blob}") )

# Define an empty array of errors
declare -a errors

# Print friendly message
[ ${verbose} -eq 1 ] && print "Retrieved & filtered list of broken packages"


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${pkgs[@]}" | tr ' ' '\n')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of broken packages failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of broken packages"


  # If ${#pkgs[@]} > 0
  if [ ${#pkgs[@]} -gt 0 ]; then

    # Look at #{pkgs[@]} for invalid items (ignores false positives)
    errors=( $(verify_pkgs "${pkgs[@]}") )

    # If ${#errors[@]} > 0
    if [ ${#errors[@]} -gt 0 ]; then

      # Iterate ${errors[@]}
      for error in ${errors[@]}; do

        # Get our package name
        pkg="$(echo "${error}" | cut -d: -f1)"

        # Run "pkg fix ${pkg}"
        pkg fix -Hq ${pkg} 2>/dev/null
      done
    fi

    # Refresh data from `pkg verify`
    blob="$(pkg verify -H "${packages[@]}" 2>/dev/null)"

    # Break ${blob} up into an easy to manage  array of packages
    pkgs=( $(parse_pkg_verify "${blob}") )
  fi
fi


# Look at #{pkgs[@]} for invalid items (ignores false positives)
errors+=( $(verify_pkgs "${pkgs[@]}") )


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Does not conform to '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    key="$(echo "${error}" | cut -d: -f1,2)"
    inode="$(echo "${error}" | cut -d: -f3)"
    flag="$(echo "${error}" |  cut -d: -f4)"
    cvalue="$(echo "${error}" | cut -d: -f5)"
    value="$(echo "${error}" | cut -d: -f6)"

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  Package: ${key}" 1
    [ ${verbose} -eq 1 ] && print "    Inode: ${inode}" 1
    [ ${verbose} -eq 1 ] && print "      Type: ${type} ${cvalue} [${value}]" 1
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
# STIG_ID: V0047897
# STIG_Version: SV-60769r1
# Rule_ID: SOL-11.1-100010
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The /etc/zones directory, and its contents, must have the vendor default owner, group, and permissions.
# Description: Incorrect ownership can result in unauthorized changes or theft of data.
