#!/bin/bash


# Define an array of default policy kernel params
declare -a defpolicy
defpolicy+=("argv")


# Define an array of default audit flags
declare -a defflags
defflags+=("cusa")
defflags+=("ps")
defflags+=("fd")
defflags+=("-fa")
defflags+=("fm")


# Define an array of non-attributable audit flags
declare -a defnaflags
defnaflags+=("cusa")
defnaflags+=("ps")
defnaflags+=("fd")
defnaflags+=("-fa")
defnaflags+=("fm")


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


# Make sure we have required defined values
if [[ ${#defpolicy[@]} -eq 0 ]] || [[ ${#defflags[@]} -eq 0 ]] || [[ ${#defnaflags[@]} -eq 0 ]]; then

  print "One or more default policies, flags or non-attributable flags defined" 1
  exit 1
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
if [[ ${restore} -eq 1 ]] && [[ ${cond} -eq 1 ]]; then

  # If ${interactive} = 1 go to interactive restoration mode
  if [ ${interactive} -eq 1 ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "Interactive restoration mode for '${file}'"

  fi

  # Do work
  audit -t
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Unable to disable auditing" 1
    exit 1
  fi

  exit 0
fi


# Define an empty array of policy flags
declare -a cur_policyflags

# Define an empty array of policy flags
declare -a set_policyflags

# Define an empty array of current flags
declare -a cur_defflags

# Define an empty array of flags
declare -a set_defflags

# Define an empty array of current flags
declare -a cur_defnaflags

# Define an empty array of non-attributable flags
declare -a set_defnaflags


# If ${change} == 1
if [ ${change} -eq 1 ]; then

  # Get an array of default policy flags
  cur_defpolicy=($(auditconfig -getpolicy | awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

  # Get an array of default flags
  cur_defflags=($(auditconfig -getflags | awk '$1 ~ /^active/{split($7, obj, "(");print obj[1]}' | tr ',' ' '))

  # Get an array of default non-attributable flags
  cur_defnaflags=($(auditconfig -getnaflags | awk '$1 ~ /^active/{split($6, obj, "(");print obj[1]}' | tr ',' ' '))


  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create array to handle configuration backup
  declare -a conf_bu
  conf_bu+=("$(echo "setpolicy:${cur_defpolicy[@]}" | tr ' ' ',')")
  conf_bu+=("$(echo "setflags:${cur_defflags[@]}" | tr ' ' ',')")
  conf_bu+=("$(echo "setnaflags:${cur_defnaflags[@]}" | tr ' ' ',')")

  # Create a snapshot of ${cur_defflags[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${conf_bu[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit flags for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current default audit flags & policies"


  # Combine & remove duplicates from ${defpolicy[@]} & ${cur_defpolicy[@]}
  set_defpolicy=( $(remove_duplicates "${defpolicy[@]}" "${cur_defpolicy[@]}") )

  # Combine & remove duplicates from ${defflags[@]} & ${cur_defflags[@]}
  set_defflags=( $(remove_duplicates "${defflags[@]}" "${cur_defflags[@]}") )

  # Combine & remove duplicates from ${defnaflags[@]} & ${cur_defnaflags[@]}
  set_defnaflags=( $(remove_duplicates "${defnaflags[@]}" "${cur_defnaflags[@]}") )


  # Convert ${set_defpolicy[@]} into a string
  defpol="$(echo "${set_defpolicy[@]}" | tr ' ' ',')"

  # Convert ${set_defflags[@]} into a string
  defflag="$(echo "${set_defflags[@]}" | tr ' ' ',')"

  # Convert ${set_defnaflags[@]} into a string
  defnaflag="$(echo "${set_defnaflags[@]}" | tr ' ' ',')"


  # Set the value(s) to the audit service
  auditconfig -setpolicy ${defpol} &>/dev/null

  # Handle results
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "An error occurred setting default audit policy: ${defpol}" 1
  fi


  # Set the value(s) to the audit service
  auditconfig -setflags ${defflag} &>/dev/null

  # Handle results
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "An error occurred setting default audit flags: ${defflag}" 1
  fi


  # Set the value(s) to the audit service
  auditconfig -setnaflags ${defnaflag} &>/dev/null

  # Handle results
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "An error occurred setting default non-immutable audit flags: ${defnaflag}" 1
  fi
fi


# Declare an empty array for errors
declare -a err


# Get an array of default policy flags
cur_defpolicy=($(auditconfig -getpolicy 2>/dev/null | awk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

# Iterate ${defpolicy[@]}
for pol in ${defpolicy[@]}; do

  # Check for ${flag} in ${cur_defpolicy[@]}
  [ $(in_array "${pol}" "${cur_defpolicy[@]}") -eq 1 ] && err+=("policy:${pol}")
done


# Get an array of default flags
cur_defflags=($(auditconfig -getflags 2>/dev/null | awk '$1 ~ /^active/{split($7, obj, "(");print obj[1]}' | tr ',' ' '))

# Iterate ${defflags[@]}
for flag in ${defflags[@]}; do

  # Check for ${flag} in ${cur_defflags[@]}
  [ $(in_array "${flag}" "${cur_defflags[@]}") -eq 1 ] && err+=("defflags:${flag}")
done


# Get an array of default non-attributable flags
cur_defnaflags=($(auditconfig -getnaflags 2>/dev/null | awk '$1 ~ /^active/{split($6, obj, "(");print obj[1]}' | tr ',' ' '))

# Iterate ${defnaflags[@]}
for naflag in ${defnaflags[@]}; do

  # Check for ${flag} in ${cur_defflags[@]}
  [ $(in_array "${naflag}" "${cur_defnaflags[@]}") -eq 1 ] && err+=("defnaflags:${naflag}")
done


# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Print friendly message
  print "Current audit settings does not conform to '${stigid}'" 1

  # Iterate ${err[@]}
  for error in ${err[@]}; do

    # Get setting from ${error}
    setting="$(echo "${error}" | cut -d: -f1)"

    # Get options from ${error}
    option="$(echo "${error}" | cut -d: -f2)"

    # Print friendly message
    print "  ${setting} (${option})" 1
  done | sort -u

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047821
# STIG_Version: SV-60697r1
# Rule_ID: SOL-11.1-010320
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must be configured to audit all discretionary access control permission modifications.
# Description: Without auditing, individual system accesses cannot be tracked, and malicious activity cannot be detected and traced back to an individual account.
