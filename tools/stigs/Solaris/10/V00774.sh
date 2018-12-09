#!/bin/bash


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


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating user accounts according to STIG ID '${stigid}'"

# Get ${settings} from ${file}
users=("$(awk -F: '$1 ~ /^root$/ && $6 ~ /^\/$/{print $1}' /etc/passwd)")

# If ${users[@]} is > 1 then notify
if [ ${#users[@]} -gt 1 ]; then

  if [ ${verbose} -eq 1 ]; then
    print "Failed validation for '${stigid}'" 1

    # Iterate ${users[@]} and list duplicate accounts
    for user in ${users[@]}; do
      print "  Account: ${user}" 1
    done
  fi

  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, all accounts conform to '${stigid}'"

exit 0

# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V00774
# STIG_Version: SV-774r2
# Rule_ID: GEN000900
#

# Date: 2018-06-29
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V00774
# STIG_Version: SV-774r2
# Rule_ID: GEN000900
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: The root user's home directory must not be the root directory (/).
# Description: Changing the root home directory to something other than / and assigning it a 0700 protection makes it more difficult for intruders to manipulate the system by reading the files that root places in its default directory. It also gives root the same discretionary access control for root's home directory as for the other plain user home directories.


# Date: 2018-06-29
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V00774
# STIG_Version: SV-774r2
# Rule_ID: GEN000900
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: The root user's home directory must not be the root directory (/).
# Description: Changing the root home directory to something other than / and assigning it a 0700 protection makes it more difficult for intruders to manipulate the system by reading the files that root places in its default directory. It also gives root the same discretionary access control for root's home directory as for the other plain user home directories.


# Date: 2018-06-29
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V00774
# STIG_Version: SV-774r2
# Rule_ID: GEN000900
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: The root user's home directory must not be the root directory (/).
# Description: Changing the root home directory to something other than / and assigning it a 0700 protection makes it more difficult for intruders to manipulate the system by reading the files that root places in its default directory. It also gives root the same discretionary access control for root's home directory as for the other plain user home directories.


# Date: 2018-06-29
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V00774
# STIG_Version: SV-774r2
# Rule_ID: GEN000900
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: The root user's home directory must not be the root directory (/).
# Description: Changing the root home directory to something other than / and assigning it a 0700 protection makes it more difficult for intruders to manipulate the system by reading the files that root places in its default directory. It also gives root the same discretionary access control for root's home directory as for the other plain user home directories.
