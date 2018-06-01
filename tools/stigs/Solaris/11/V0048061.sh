#!/bin/bash


# Define the expected umask value
umask=077


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


# Remove once work is complete on module
cat <<EOF
[${stigid}] Warning: Not yet implemented...

$(get_meta_data "${cwd}" "${prog}")
EOF
exit 1


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


# Create an empty array to handle errors
declare -a errs


# Obtain an array of home directories while filtering for duplicates
home_directories=( $(printf "%s\n" "$(cut -d: -f6 /etc/passwd)" | sort -u) )

# Search /etc & ${home_directories[@]} for hidden files & regular files for umask definitions != ${umask}
offenders=( $(find /etc ${home_directories[@]} -type f -exec grep -il ^umask -v "${umask}" 2> /dev/null) )

# If ${#offenders[@]} -eq 0
if [ ${#offenders[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "No offending umask definitions found; conforms to '${stigid}'"
  exit 0
fi


# Iterate ${offenders[@]}
for inode in ${offenders[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # If ${change} = 1
  if [ ${change} -eq 1 ]; then

    # Create a backup of ${file}
    bu_file "${author}" "${inode}"
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Could not create a backup of '${inode}', exiting..." 1
      exit 1
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Created backup of '${inode}'"


    # Get the last backup file
    tfile="$(bu_file_last "$(dirname ${inode})" "${author}")"
    if [ ! -f ${tfile} ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred getting temporary file for changes"
      exit 1
    fi


    # Make change for umask to ${umask} in ${tfile} while copying results to ${inode}
    sed -e "s/^\([umask|UMASK].*\)[0-9+][0-9+][0-9+]$/\1${umask}/g" ${tfile} > ${inode}

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Made changes to '${file}' reflecting UMASK; '${umask}'"
  fi


  # Validate current value of umask
  val="$(grep -i umask ${inode} | grep -v "${umask}")"

  # If ${chk} not empty
  if [ "${chk}" != "" ]; then

    # Put reference to ${inode} in ${errs[@]}
    errs+=("${inode}")
  fi
done


# If ${#errs[@]} -gt 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "System does not conform to '${stigid}'" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  umask value defined in '${err}' incorrect" 1
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
# STIG_ID: V0048061
# STIG_Version: SV-60933r2
# Rule_ID: SOL-11.1-040250
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The default umask for system and users must be 077.
# Description: Setting a very secure default value for umask ensures that users make a conscious choice about their file permissions.
