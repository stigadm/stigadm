#!/bin/bash


# Minimum allowable permssions
min_perm=0640

# Define an array of inodes to evaluate
declare -a indoes
inodes+=(/etc/security/audit_user)


# Global defaults for tool
author=
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
    r) restore=1 ;;
    i) interactive=1 ;;
    x) xml=1 ;;
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


# Make sure ${#inodes[@]} is defined
if [ ${#inodes[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && usage "A list of inodes to examine for '${stigid}' is not defined"
  exit 1
fi


# If ${change} > 0
if [ ${change} -ne 0 ]; then

  # Create a snapshot of ${inodes[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${inodes[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
fi


# Iterate ${inodes[@]}
for inode in ${inodes[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"
  [ -z ${inode} ] && continue

  # Get the current octal value for ${inode}
  cperm=$(get_octal ${inode})

  # If ${change} = 1
  if [ ${change} -eq 1 ]; then

    #
  fi

done


# If ${#offenders[@]} > 0 exit
if [ ${#offenders[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "System does not conform to '${stigid}'" 1

  # Iterate ${offenders[@]}
  for offndr in ${offenders[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  '${offndr}' is misconfigured" 1
  done

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0


# Date: 2018-06-29
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V004245
# STIG_Version: SV-4245r2
# Rule_ID: GEN000000-SOL00100
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: The /etc/security/audit_user file must have mode 0640 or less permissive.
# Description: Audit_user is a sensitive file that, if compromised, would allow a malicious user to select auditing parameters to ignore his sessions.  This would allow malicious operations the auditing subsystem would not log for that user.
