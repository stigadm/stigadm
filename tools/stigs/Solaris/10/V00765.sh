#!/bin/bash


# Definition for the file to validate/make changes to
file=/etc/syslog.conf

# Key to modify
key="auth.*"

# Value of ${key}
value="/var/log/authlog"

# Setting(s) for ${file}
setting="${key} ${value}"

# Ownership of file
owner="root:root"

# File permissions
perms=600


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


# If ${change} = 1 do work
if [ ${change} -eq 1 ]; then

  # Backup the file
  cp ${file} ${file}.${author}-$(gen_date)

  # Print friendly message regarding backup of ${file}
  [ ${verbose} -eq 1 ] && print "Backed up '${file}'"

  # Print friendly message regarding change
  [ ${verbose} -eq 1 ] && print "Applying changes for '${stigid}'"

  # Create & set permissions on temporary file
  tfile="$(gen_tmpfile "${file}" "${owner}" "${perms}" 1)"
  if [ $? -ne 0 ]; then
    usage "${tfile}" && exit 1
  fi

  # Print friendly message regarding temporary file
  [ ${verbose} -eq 1 ] && print "Created temporary file, '${tfile}'"

  # Make changes from ${file} into ${tfile}
  sed -e "s|^${key}|${setting}|g" ${file} > ${tfile}

  # Print friendly message regarding temporary file permissions
  [ ${verbose} -eq 1 ] && print "Set '${setting}' in '${tfile}'"

  # Move ${tfile} into ${file}
  mv ${tfile} ${file}

  # Print friendly message regarding restoration of ${file} from ${tfile}
  [ ${verbose} -eq 1 ] && print "Moved '${tfile}' to '${file}'"
fi


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating '${file}' according to STIG ID '${stigid}'"

# Get ${settings} from ${file}
haystack="$(grep "${setting}" ${file})"

# If ${haystack} is empty error & exit
if [ "${haystack}" == "" ]; then

  if [ ${verbose} -eq 1 ]; then
    print "Failed validation for '${stigid}'" 1
    print "  File: ${file}" 1
    print "  Value: ${setting}" 1
  fi

  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, '${file}' conforms to '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00765
# STIG_Version: SV-27080r1
# Rule_ID: GEN000440
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00765
# STIG_Version: SV-27080r1
# Rule_ID: GEN000440
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: Successful and unsuccessful logins and logouts must be logged.
# Description: Successful and unsuccessful logins and logouts must be logged.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00765
# STIG_Version: SV-27080r1
# Rule_ID: GEN000440
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: Successful and unsuccessful logins and logouts must be logged.
# Description: Successful and unsuccessful logins and logouts must be logged.

