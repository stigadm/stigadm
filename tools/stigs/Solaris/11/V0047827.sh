#!/bin/bash



# Define an array of plugins that should be active for auditing
declare -a plugins
plugins+=("audit_syslog")


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


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
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


# Define an array for errors
declare -a err


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Get a list of active audit plugins
  active=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}'))

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=("$(echo "setplugin:${active[@]}" | tr ' ' ',')")

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugins for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Iterate ${plugins[@]}
  for plugin in ${plugins[@]}; do

    # Make change according to ${stigid}
    auditconfig -setplugin ${plugin} active 2> /dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Unable to enable audit plug-in '${plugin}'"
    fi
  done

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current default audit plugins"
fi


# Get a list of inactive audit plugins
inactive=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 ~ /inactive/{print $2}'))


# Get a list of active audit plugins
active=($(auditconfig -getplugin | awk '$1 ~ /^Plugin/ && $3 !~ /inactive/{print $2}'))


# Iterate ${plugins[@]}
for plugin in ${plugins[@]}; do

  # If ${plugin} doesn't exist in ${inactive[@]} & ${active[@]}
  if [[ $(in_array "${plugin}" "${inactive[@]}") -eq 1 ]] && [[ $(in_array "${plugin}" "${active[@]}") -ne 0 ]]; then

    # Push ${plugin} to ${err[@]}
    [ ${verbose} -eq 1 ] && err+=("${plugin}")
  fi
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "An error occurred validating available/active audit plug-ins:" 1

  # Iterate ${err[@]}
  for error in ${err[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  - ${error}" 1
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
# Description: The operating system must protect against an individual falsely denying having performed a particular action. In order to do so the system must be configured to send audit records to a remote audit server.

