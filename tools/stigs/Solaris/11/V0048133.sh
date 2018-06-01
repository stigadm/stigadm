#!/bin/bash


# Define the minimum permissions allowed
perms=00750

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


# Iterate available logins (that have a password assigned)
for home in $(logins -ox | awk -F: '$8 == "PS"{print $6}'); do

  # Get a snapshot of current home directories with lax permissions
  offenders+=($(find ${home} -type d -prune \( -perm -g+w -o -perm -o+r -o -perm -o+w -o -perm -o+x \) -ls | awk '{print $11}' | tr '\n' ' '))
done

# If ${offenders[@]} = 0 then exit
if [ ${#offenders[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "'${#offenders[@]}' accounts found, conforms to '${stigid}'"

  exit 0
fi


# If ${change[@]} = 0 then create a backup
if [ ${change} -eq 1 ]; then

  # Setup the backup environment for ${stigid}
  backup_setup_env "${backup_path}"


  # Create a snapshot of ${offenders[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${offenders[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current permissions"
fi


# Set ${errs[@]}
errs=()

# Set ${success[@]}
success=()


# Iterate ${offenders[@]}
for inode in ${offenders[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # If ${change} = 1 do work
  if [ ${change} -eq 1 ]; then

    # Set ownership info
    chmod ${perms} ${inode} 2> /dev/null
    if [ $? -eq 1 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] print "An error occurred setting '${perms}' on '${inode}'" 1
    fi

    # Push ${inode} to ${success[@]}
    success+=("${inode}")
  fi

  # Get current octal on ${inode}
  coctal=$(get_octal ${inode})

  # Get current octal value of ${inode}
  if [ ${coctal} -gt ${perms} ]; then

    # Add ${inode} to ${errs[@]}
    errs+=("${inode}")
  fi
done


# Return validated inodes
if [ ${#success[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Following inodes conform to '${stigid}'" 1

  # Iterate ${err[@]} and print offending item
  for succ in ${succ[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${succ} [$(get_octal ${succ})]" 1
  done
fi


# Return error & error code on failure
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "System does not conform to '${stigid}'" 1

  # Iterate ${err[@]} and print offending item
  for err in ${errs[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${err} [$(get_octal ${err})]" 1
  done

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048133
# STIG_Version: SV-61005r1
# Rule_ID: SOL-11.1-070020
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: Permissions on user home directories must be 750 or less permissive.
# Description: Group-writable or world-writable user home directories may enable malicious users to steal or modify other users' data or to gain another user's system privileges.
