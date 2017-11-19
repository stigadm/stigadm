#!/bin/bash


# File for changes
file=/etc/default/passwd

# Define an associative array of key/values
declare -A opts
opts['MINUPPER']=2


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


# Handle symlinks
file="$(get_inode ${file})"


# Ensure ${file} exists @ specified location
if [ ! -f ${file} ]; then
  usage "'${file}' does not exist at specified location" && exit 1
fi


# Ensure ${#opts[@]}} > 0
if [ ${#opts[@]} -eq 0 ]; then
  usage "'${#opts[@]}' options defined" && exit 1
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


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create a backup of ${file}
  bu_file "${author}" "${file}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${file}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${file}'"


  # Get last backed up file for changes
  tfile="$(bu_file_last "${file}" "${author}")"


  # Iterate ${!opts[@]}
  for opt in ${!opts[@]}; do

    # Check to see if ${opt} exists
    if [ $(grep -ic "^${opt}.*" ${tfile}) -gt 0 ]; then

      # Get current value of ${opt} from ${tfile}
      cur_val=$(grep -i "^${opt}.*" ${tfile} | cut -d= -f2)
    else

      # Set ${cur_val} to 0
      cur_val=0
    fi

    # Look for ${opt} in ${tfile}
    if [[ ${cur_val} -lt ${def_min} ]]; then

      # Make change
      sed -e "s|^${opt}.*|${opt}=${opts[${opt}]}|g" ${tfile} > ${file}

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Set '${opt}' = '${opts[${opt}]}' in '${file}'"
    else

      # Add ${opt}=${opts[${opt}]} to ${file}
      echo "${opt}=${opts[${opt}]}" >> ${file}

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Added '${opt}' = '${opts[${opt}]}' in '${file}'"
    fi
  done

fi


# Define an empty array for errors
declare -a err

# Iterate ${!opts[@]}
for opt in ${!opts[@]}; do

  # Look for ${opt} in ${file}
  [ $(grep -ic "^${opt}=${opts[${opt}]}" ${file}) -eq 0 ] && err+=("${opt}")
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "An error occurred validating '${file}'" 1

  # Iterate ${err[@]}
  for error in ${err[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  - ${error}" 1
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
# STIG_ID: V0047971
# STIG_Version: SV-60843r1
# Rule_ID: SOL-11.1-040070
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The system must require passwords to contain at least one uppercase alphabetic character.
# Description: Complex passwords can reduce the likelihood of success of automated password-guessing attacks.

