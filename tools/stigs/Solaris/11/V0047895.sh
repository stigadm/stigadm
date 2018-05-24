#!/bin/bash


# Define an array of zone ppriv attributes any configured zone must use
declare -a pprivs
pprivs+=("limitpriv:default")


# Global defaults for tool
author=
verbose=0
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


# Make sure ${ppriv[@]} is not empty
if [ ${#pprivs[@]} -eq 0 ]; then
  usage "Must define values corresponding to those available from ppriv"
  exit 1
fi

# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi

# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
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


# Create a filter based on ${pprivs[@]}
filter="$(echo "${pprivs[@]}" | tr ' ' '\n' | cut -d: -f1)"


# Acquire list of configured/installed zones
zones=( $(zoneadm list -cv | awk 'NR > 1 && $0 !~ /global|solaris-kz/{print $2}') )

# If ${#zones[@]} == 0
if [ ${#zones[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "${#zones[@]} found on host"

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"
  exit 0
fi

# Iterate ${zones[@]}
for zone in ${zones[@]}; do

  # Acquire properties for anything matching ${filter}
  props+=( "${zone}:"$(zonecfg -z ${zone} info | egrep ${filter} | awk '{printf("%s%s\n", $1, $2)}') )
done

# If ${#props[@]} == 0
if [ ${#props[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Unable to acquire list of zones & their attributes"
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Acquired list of zones and their attributes: ${#props[@]}"


# Create an error array
declare -a errors


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${props[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of zones and properties failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of zones and associated attributes"


  # Iterate ${props[@]}
  for prop in ${props[@]}; do

    # Cut ${prop} into zone, key & values
    zone="$(echo "${prop}" | cut -d: -f1)"
    key="$(echo "${prop}" | cut -d: -f2)"
    values=( $(echo "${prop}" | cut -d: -f3 | tr ',' ' ') )

    # Make a needle out of ${pprivs[${key}]
    needle="$(echo "${pprivs[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2)"

    # Bail if ${pprivs[@]} key/value exist
    [ $(in_array "${needle}" "${values[@]}") -eq 0 ] &&
      continue

    # Create an array of configured property values from ${pprivs[@]}
    dvalues=( $(echo "${pprivs[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2 | tr ',' ' ') )

    # Merge ${values[@]} w/ ${dvalues[@]} matching ${key}
    values=( $(echo "${dvalues[@]}" "${values[@]}" | tr ' ' '\n' | sort -u) )

    # Set ${key} on ${zone} to ${values[@]}
    zonecfg -z ${zone} set ${key}=$(echo "${values[@]}" | tr ' ' ',') 2>/dev/null

    # Determine if an error is to be raised
    [ $? -ne 0 ] && errors+=("${prop}")

    # Raise an error if ${values[@]} doesn't match
    cval=$(zonecfg -z ${zone} info ${key} | grep -c "$(echo "${values[@]}" | tr ' ' ',')")
    [ ${cval} -le 0 ] && errors+=("${prop}")
  done

  # Zero ${props[@]}
  props=()

  # Refresh ${props[@]}
  for zone in ${zones[@]}; do

    # Acquire properties for anything matching ${filter}
    props+=( "${zone}:"$(zonecfg -z ${zone} info | egrep ${filter} | awk '{printf("%s%s\n", $1, $2)}') )
  done
fi


# Iterate ${props[@]}
for prop in ${props[@]}; do

  # Cut ${prop} into zone, key & values
  zone="$(echo "${prop}" | cut -d: -f1)"
  key="$(echo "${prop}" | cut -d: -f2)"
  values=( $(echo "${prop}" | cut -d: -f3 | tr ',' ' ') )

  # Make a needle out of ${pprivs[${key}]
  needle="$(echo "${pprivs[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2)"

  # Bail if ${pprivs[@]} key/value exist
  [ $(in_array "${needle}" "${values[@]}") -eq 1 ] && errors+=("${prop}")
done


# Exit 1 if validation failed
if [ ${#errors[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Host does not conform to '${stigid}'"

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    zone="$(echo "${error}" | cut -d: -f1)"
    key="$(echo "${error}" | cut -d: -f2)"
    values=( $(echo "${error}" | cut -d: -f3 | tr ',' ' ') )

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  ${zone} ${key} [${values[@]}]" 1
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
# STIG_ID: V0047895
# STIG_Version: SV-60767r3
# Rule_ID: SOL-11.1-100020
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The limitpriv zone option must be set to the vendor default or less permissive.
# Description: The limitpriv zone option must be set to the vendor default or less permissive.
