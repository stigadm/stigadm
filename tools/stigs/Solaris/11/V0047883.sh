#!/bin/bash


# Define an array of properties
declare -a properties
properties+=("signature-policy:verify")


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


# Bail if ${#properties[@]} is 0
if [ ${#properties[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Must define at least one pkg policy property" 1
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


# Create a filter from ${properties[@]}
filter="$(echo "${properties[@]}" | cut -d: -f1 | tr ' ' ',')"

# Get blob of properties for packages
declare -a cproperties
cproperties=( $(pkg property | egrep ${filter} | awk '{printf("%s:%s\n", $1, $2)}') )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${cproperties[@]}" | tr ' ' '\n')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of package policy failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of package policy"


  # Iterate ${properties[@]}
  for property in ${properties[@]}; do

    # Split ${property} up
    key="$(echo "${property}" | cut -d: -f1)"
    value="$(echo "${property}" | cut -d: -f2)"

    # Set ${key} = ${value}
    pkg property set-property ${key} ${value} 2>/dev/null

    # Trap error
    [ $? -ne 0 ] && errors+=("${key}:${value}")
  done

  # Refresh ${cproperties[@]}
  cproperties=( $(pkg property | egrep ${filter} | awk '{printf("%s:%s\n", $1, $2)}') )
fi


# Iterate ${properties[@]}
for property in ${properties[@]}; do

  # Chop up ${property}
  key="$(echo "${property}" | cut -d: -f1)"
  value="$(echo "${property}" | cut -d: -f2)"

  # Pluck ${property} from ${cproperties[@]}
  cvalue="$(echo "${cproperties[@]}" | tr ' ' '\n' | grep "^${key}" | cut -d: -f2)"

  # Trap error if ${cvalue} not equal to ${value}
  [ "${cvalue}" != "${value}" ] && errors+=("${key}:${cvalue}:${value}")
done


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Does not conform to '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    # Chop up ${error}
    key="$(echo "${error}" | cut -d: -f1)"
    cvalue="$(echo "${error}" | cut -d: -f2)"
    value="$(echo "${error}" | cut -d: -f3)"

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  ${key} ${cvalue} [${value}]" 1
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
# STIG_ID: V0047883
# STIG_Version: SV-60755r1
# Rule_ID: SOL-11.1-020020
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The system must verify that package updates are digitally signed.
# Description: Digitally signed packages ensure that the source of the package can be identified.
