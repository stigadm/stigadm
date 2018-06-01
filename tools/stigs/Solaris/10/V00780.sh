#!/bin/bash


# Max GID for range of comparison with ${accounts[@]}
max_gid=99

# Array of profile files
declare -a accounts
accounts+=("root")
accounts+=("daemon")
accounts+=("bin")
accounts+=("sys")
accounts+=("adm")
accounts+=("lp")
accounts+=("smmsp")
accounts+=("listen")
accounts+=("gdm")
accounts+=("uucp")
accounts+=("nuucp")
accounts+=("webservd")
accounts+=("postgres")
accounts+=("svctag")
accounts+=("unknown")


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


# Make sure ${#accounts[@]} is > 0
if [ ${#accounts[@]} -eq 0 ]; then
  usage "A list of accounts to examine must be defined" && exit 1
fi

# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating GID system account reservations STIG ID '${stigid}'"


# Get ${settings} from ${file}
users=("$(awk -v max_gid="${max_gid}" ${-F: '$4 < max_gid{print $1}' /etc/passwd)")

# Make sure ${#users[@]} > 0
if [ ${#users[@]} -eq 0 ]; then
  [ ${verbose} -eq 1 ] && print "No users with a GID less than '${max_gid}' found" 1
  exit 1
fi

[ ${verbose} -eq 1 ] && print "Obtained list of users w/ GID less than '${max_gid}'"

# Do intersection of allowed system accounts in ${accounts[@]} with ${users[@]}
exceptions=("$(comm -12 <(printf "%s\n" "$(echo "${accounts[@]}"|sort -u)") <(printf "%s\n" "$(echo "${users[@]}"|sort -u)"))")

# If ${#exceptions[@]} > 1 then return error & optionally show accounts
if [ ${#exceptions[@]} -ge 1 ]; then

  # Print details of exceptions
  if [ ${verbose} -eq 1 ]; then
    print "Obtained list of users w/ GID less than '${max_gid}'" 1

    # Print list of exceptions
    for user in ${exceptions[@]}; do
      print "  Account: ${user}" 1
    done
  fi

  exit 1
fi

# Exit with error code
[ ${ret} -eq 1 ] && exit 1

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, all user GID's conform to '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00780
# STIG_Version: SV-28658r1
# Rule_ID: GEN000360
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00780
# STIG_Version: SV-28658r1
# Rule_ID: GEN000360
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: GIDs reserved for system accounts must not be assigned to non-system groups.
# Description: GIDs reserved for system accounts must not be assigned to non-system groups.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00780
# STIG_Version: SV-28658r1
# Rule_ID: GEN000360
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: GIDs reserved for system accounts must not be assigned to non-system groups.
# Description: GIDs reserved for system accounts must not be assigned to non-system groups.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00780
# STIG_Version: SV-28658r1
# Rule_ID: GEN000360
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: GIDs reserved for system accounts must not be assigned to non-system groups.
# Description: Reserved GIDs are typically used by system software packages.  If non-system groups have GIDs in this range, they may conflict with system software, possibly leading to the group having permissions to modify system files.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00780
# STIG_Version: SV-28658r1
# Rule_ID: GEN000360
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: GIDs reserved for system accounts must not be assigned to non-system groups.
# Description: Reserved GIDs are typically used by system software packages.  If non-system groups have GIDs in this range, they may conflict with system software, possibly leading to the group having permissions to modify system files.
