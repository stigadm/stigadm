#!/bin/bash


# Define max value before account is locked
max=35


# Define the configuration file for the max lockout value
file=/etc/default/login


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


# Handle symlinks
file="$(get_inode ${file})"


# Ensure ${file} exists @ specified location
if [ ! -f ${file} ]; then
  usage "'${file}' does not exist at specified location" && exit 1
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


# Declare an array for errors
declare -a errs


# Get the current configured value
cmax=$(useradd -D | xargs -n 1 | grep inactive | cut -d= -f2)

# Print friendly message
[ ${verbose} -eq 1 ] && print "Got default activity period for new accounts '${cmax}'"


# Get an array of users
user_list=($(logins -axo | nawk -F: -v max="${max}" '$13 > max || $13 == -1 && $8 !~ /^NP|LK|NL/ && $8 ~ /^PS|UP$/{print $1}'))

# Print friendly message
[ ${verbose} -eq 1 ] && print "Got '${#user_list[@]}' of mis-configured accounts"


# Get a list of roles
roles_list=($(logins -arxo | cut -d: -f1))


# If both ${cmax} = ${max} & ${#user_list[@]} = 0 it conforms
if [[ ${cmax} -eq ${max} ]] && [[ ${#user_list[@]} -eq 0 ]]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"
  exit 0
fi


# If ${change} = 1
if [ ${change} -gt 0 ]; then

  # Create a backup of the passwd database
  bu_passwd_db "${author}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Backup of passwd database failed, exiting..." 1

    # Stop, we require a backup of the passwd database for changes
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of passwd database file(s)"


  # Create a backup of ${file}
  bu_file "${author}" "${file}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${file}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${file}'"


  # If ${cmax} > ${max}
  if [ ${cmax} -gt ${max} ]; then

    # Make the global change
    useradd -D -f ${max} &> /dev/null

    # Handle errors
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred setting default value for account inactivity" 1
    fi
  fi


  # If ${#user_list[@]] > 0
  if [ ${#user_list[@]} -gt 0 ]; then

    # Iterate ${user_list[@]}
    for user in ${user_list[@]}; do

      # Fix the account
      [ $(in_array "${user}" "${roles_list[@]}") -eq 1 ] &&
        usermod -f ${max} ${user} 2> /dev/null || rolemod -f ${max} ${user} 2> /dev/null

      # Capture the error
      if [ $? -ne 0 ]; then
        # Print friendly message
        [ ${verbose} -eq 1 ] && print "An error occurred modifying '${user}' allowed inactivity threshold" 1
      else
        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Fixed '${user}' account's allowed inactivity threshold"
      fi
    done
  fi
fi


# Set a default return value
ret=0

# Get the current configured value
cmax=$(useradd -D | xargs -n 1 | grep inactive | cut -d= -f2)

# If ${cmax} > ${max}
if [ ${cmax} -gt ${max} ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Account inactivity value incorrect; ${cmax}" 1
  ret=1
fi


# Get an array of users
errs+=($(logins -axo | nawk -F: -v max="${max}" '$13 > max || $13 == -1 && $8 !~ /^NP|LK|NL/ && $8 ~ /^PS|UP$/{print $1}'))


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "The following accounts are using an incorrect inactivity value" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${err}" 1
  done

  ret=1
fi


# Return an error code
[ ${ret} -gt 0 ] && exit 1


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048085
# STIG_Version: SV-60957r1
# Rule_ID: SOL-11.1-040300
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: Emergency accounts must be locked after 35 days of inactivity.
# Description: Inactive accounts pose a threat to system security since the users are not logging in to notice failed login attempts or other anomalies.
