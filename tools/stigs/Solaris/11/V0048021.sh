#!/bin/bash


# Define an array of items to disable with coreadm
disable=(global process global-setid proc-setid)


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


# Make sure ${disable[@]} is defined
if [ ${#disable[@]} -eq 0 ]; then
  usage "Must define core items to disable" && exit 1
fi


# Get list of enabled services
svs=($(coreadm | grep -v logging | grep -i enabled | nawk '{if (match($3, /^core$/)){print $1"-"$2}else{print $1}}'))

# Nothing found enabled
if [ ${#svs[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"
  exit 0
fi


# Perform intersection of ${disable[@]} with ${svs[@]} & assign to ${res[@]}
res=($(comm -13 <(printf "%s\n" "$(echo "${disable[@]}" | sort -u)") <(printf "%s\n" "$(echo "${svs[@]}" | sort -u)")))


# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${file}'"

  fi

  # Iterate & re-enable anything defined in ${res[@]}
  for en in ${res[@]}; do

    $(coreadm -e ${en} 2> /dev/null)
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred enabling '${en}' in coreadm" 1
      exit 1
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Enabled '${en}' in coreadm"
  done

  exit 0
fi

# Define err
err=()

# Iterate ${res[@]}
for dis in ${res[@]}; do

  # If ${change} = 1 make the change
  if [ ${change} -eq 1 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Disabling '${dis}' in coreadm"

    # Make the change
    $(coreadm -d ${dis} 2> /dev/null)
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred disabling '${dis}' in coreadm" 1
      exit 1
    fi
  fi

  # Apply formatting to ${dis} if it contains a "-"
  pattern="$(echo "${dis}" | tr '-' ' ' | tr ' ' '*')"

  # Get current status of ${dis}
  svs=("$(coreadm | grep "${pattern}" | grep -v logging | grep -i enabled)")

  # If ${svs} != "" then provide an error & exit
  if [ ${#svs} -gt 0 ]; then

    # Push ${dis} into ${err}
    err+=("${dis}")
  fi
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  if [ ${verbose} -eq 1 ]; then

    print "Issues found with coreadm services:" 1
    for er in ${err[@]}; do
      echo "  ${er}"
    done
  fi

  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048021
# STIG_Version: SV-60893r2
# Rule_ID: SOL-11.1-080040
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: Process core dumps must be disabled unless needed.
# Description: Process core dumps contain the memory in use by the process when it crashed. Process core dump files can be of significant size and their use can result in file systems filling to capacity, which may result in denial of service. Process core dumps can be useful for software debugging.

