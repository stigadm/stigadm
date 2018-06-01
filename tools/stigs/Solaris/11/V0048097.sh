#!/bin/bash


# Default permissions
perms=750


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
    v) verbose=1 ;;
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


# Capture the IFS
cifs="$IFS"

# Set IFS to :
IFS=":"

# Iterate entries
logins -uxo | while read user uid group gid gecos home rest; do

  # Get a snapshot of current home directory ownership
  curperms+=($(find ${home} -type d -prune \! -user ${user} -print 2> /dev/null))
done

# Reset the global $IFS
IFS="${cifs}"


# If nothing is found
if [[ ${#curperms[@]} -eq 0 ]] && [[ ${restore} -eq 0 ]]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "'${#curperms[@]}' offending accounts found. Success, conforms to '${stigid}'"

  exit 0
fi


# If ${change} > 0
if [ ${change} -ne 0 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"


  # Create a snapshot of ${inodes[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${curperms[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current permissions"
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

# Iterate ${curperms[@]}
for inode in ${curperms[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # If ${change} = 1 do work
  if [ ${change} -eq 1 ]; then

    # Get octal for ${inode}
    octal=$(get_octal ${inode})

    # Get user for ${inode}
    usr=$(get_perms_user ${inode})

   # Print friendly message
    [ ${verbose} -eq 1 ] && print "Setting '${inode}' ownership to '${usr}'"

    # Set ownership info
    chown ${usr} ${inode} 2> /dev/null
    if [ $? -ne 0 ]; then
      print "Could not change ownership on '${inode}' to '${usr}'" 1
    fi
  fi

  # Get octal for ${inode}
  octal=$(get_octal ${inode})

  # Get user for ${inode}
  usr=$(get_perms_user ${inode})

  print " - Examining: ${usr} -> $(basename ${inode})"

  # If $(basename ${inode}) != ${usr}
  if [ "$(basename ${inode})" != "${usr}" ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "'${inode}' ownership does not conform to '${stigid}'" 1
  fi
done


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048097
# STIG_Version: SV-60969r2
# Rule_ID: SOL-11.1-070090
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: All home directories must be owned by the respective user assigned to it in /etc/passwd.
# Description: Since the user is accountable for files stored in the user's home directory, the user must be the owner of the directory.
