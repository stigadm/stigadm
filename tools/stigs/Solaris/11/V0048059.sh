#!/bin/bash

# OS: Solaris
# Version: 11
# Severity: CAT-III
# Class: UNCLASSIFIED
# VulnID: V-48059
# Name: SV-60931r2


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


# Define an array to capture unsigned binaries w/ SUID/SGID
declare -a errs

# Define an array to capture validated binaries
declare -a vals


# Get list of inodes that have the SUID/SGID bit set
inodes=($(find / \( -fstype nfs -o -fstype cachefs -o -fstype autofs -o -fstype ctfs -o -fstype mntfs -o -fstype objfs -o -fstype proc \) -prune -o -type f -perm -4000 -o -perm -2000 -print))

# Get list of package manifests that list inclusions of files with the SUID/SGID bit set
pkgs=($(pkg contents -a mode=4??? -a mode=2??? -t file -o path -H | awk '{print "/"$1}'))

# Perform intersection of ${inodes[@]} & ${pkgs[@]} to provide list of SUID/SGID binaries
offending=($(comm -3 <(printf "%s\n" "$(echo "${inodes[@]}" | sort -u)") <(printf "%s\n" "$(echo "${pkgs[@]}" | sort -u)")))


# If ${#offending[@]} = 0
if [ ${#offending[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "'${#offending[@]}' files with the SUID/SGID bit set; system conforms to '${stigid}'"
fi

# Print friendly message regarding restoration mode
[ ${verbose} -eq 1 ] && print "Found a total of '${#offending[@]}' files with the SUID/SGID bit set"


# Iterate ${offending[@]}
for inode in ${offending[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Validate with elfsign (just capture the return code)
  elfsign verify -e ${inode} &>/dev/null
  if [ $? -ne 0 ]; then
    errs+=("'${inode}'")
  else
    vals+=("'${inode}'")
  fi
done


# If ${#vals[@]} > 0
if [ ${#vals[@]} -gt 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "The following SUID/GUID binaries passed validation"

  # Iterate ${vals[@]}
  for val in ${vals[@]}; do

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "  - ${val}"
  done
fi


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "The following SUID/GUID binaries failed validation" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "  - ${err}" 1
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
# STIG_ID: V0048059
# STIG_Version: SV-60931r2
# Rule_ID: SOL-11.1-070190
#
# OS: Solaris
# Version: 11
# Architecture: Sparc
#
# Title: All valid SUID/SGID files must be documented.
# Description: All valid SUID/SGID files must be documented.


# Date: 2017-06-21
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0048059
# STIG_Version: SV-60931r2
# Rule_ID: SOL-11.1-070190
#
# OS: Solaris
# Version: 11
# Architecture: X86
#
# Title: All valid SUID/SGID files must be documented.
# Description: All valid SUID/SGID files must be documented.

