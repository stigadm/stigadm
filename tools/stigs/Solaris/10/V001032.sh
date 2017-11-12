#!/bin/bash

# OS: Solaris
# Version: 10
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-1032
# Name: SV-39809r1

# Define a minimum days range between password changes
min_days=1

# UID minimum as exclusionary for system/service accounts
uid_min=100

# UID exceptions (any UID within ${uid_min}...2147483647 to exclude)
# Service/System account UID's
declare -a uid_excp
uid_excp+=(60001) # nobody
uid_excp+=(60002) # nobody4
uid_excp+=(65534) # noaccess


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


# If ${#uid_excl[@]} > 0 create a pattern
pattern="$(echo "${uid_excp[@]}" | tr ' ' '|')"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Created exclude pattern (${pattern})"

# Get current list of users (greater than ${uid_min} & excluding ${uid_excp[@]})
user_list=($(nawk -F: -v min="${uid_min}" -v pat="/${pattern}/" '$3 > min && $3 !~ pat{print $1}' /etc/passwd))

# If ${#user_list[@]} = 0 exit
if [ ${#user_list[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#user_list[@]}' users found meeting criteria for examination; exiting" 1

  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained list of users to examine (Total: ${#user_list[@]})"


# Create ${filter} from ${user_list[@]} to filter system & anything defined in ${uid_excp[@]}
filter="$(echo "${user_list[@]}" | tr ' ' '|')"

# Obtain list of offending accounts
offenders=($(nawk -F: -v max="${min_days}" -v pat="${filter}" '$4 > max && $1 ~ pat{print $1}' /etc/shadow))

# If ${#offenders[@]} = 0 exit
if [ ${#offenders[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"
  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained list of offending accounts (Total: ${#offenders[@]})"


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create a backup of the passwd database
  bu_passwd_db "${author}"
  if [ $? -ne 0 ]; then

    # Print friendly message 
    [ ${verbose} -eq 1 ] && print "Backup of passwd database failed, exiting..." 1

    # Stop, we require a backup of the passwd database for changes
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of passwd database."


  # Iterate ${offenders[@]}
  for offndr in ${offenders[@]}; do


    # Set ${offndr} password change to ${min_days}
    passwd -n 1 ${offndr} &> /dev/null

    # Handle errors
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Unable to change password change threshold for '${offndr}' to '${min_days}'"
    fi

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "Modified password change threshold for '${offndr}' to '${min_days}'"
  done
fi


# Obtain list of offending accounts (again)
offenders=($(nawk -F: -v max="${min_days}" -v excl="/${filter}/" '$4 > max && $1 ~ excl{print $1}' /etc/shadow))

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
