#!/bin/bash


###############################################
# STIG specific audit flags
###############################################

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


###############################################
# Bootstrapping environment setup
###############################################

# Get our working directory
cwd="$(pwd)"

# Define our bootstrapper location
bootstrap="${cwd}/tools/bootstrap.sh"

# Bail if it cannot be found
if [ ! -f ${bootstrap} ]; then
  echo "Unable to locate bootstrap; ${bootstrap}" && exit 1
fi

# Load our bootstrap
source ${bootstrap}


###############################################
# Global zones only check
###############################################

# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  usage "${stigid} only applies to global zones" && exit 1
fi


###############################################
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is as group
caller=$(ps $PPID | grep -c stigadm)


###############################################
# STIG validation/remediation/restoration
###############################################

# Make sure we have required defined values
if [[ ${#defpolicy[@]} -eq 0 ]] || [[ ${#defflags[@]} -eq 0 ]] || [[ ${#defnaflags[@]} -eq 0 ]]; then

  usage "One or more default policies, flags or non-attributable flags defined" && exit 1
fi


# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  usage "Not yet implemented" && exit 1
fi


# Get an array of default policy flags
cur_defpolicy=($(auditconfig -getpolicy |
  nawk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

# Get an array of default flags
cur_defflags=($(auditconfig -getflags |
  nawk '$1 ~ /^active/{split($7, obj, "(");print obj[1]}' | tr ',' ' '))

# Get an array of default non-attributable flags
cur_defnaflags=($(auditconfig -getnaflags |
  nawk '$1 ~ /^active/{split($6, obj, "(");print obj[1]}' | tr ',' ' '))


# If ${change} == 1
if [ ${change} -eq 1 ]; then

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
    # Stop, we require a backup
    usage "Unable to create snapshot of audit flags" && exit 1
  fi


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

  # Set the value(s) to the audit service
  auditconfig -setflags ${defflag} &>/dev/null

  # Set the value(s) to the audit service
  auditconfig -setnaflags ${defnaflag} &>/dev/null

  # Get an array of default policy flags
  cur_defpolicy=($(auditconfig -getpolicy |
    nawk '$1 ~ /^active/{print}' | cut -d= -f2 | tr ',' ' '))

  # Get an array of default flags
  cur_defflags=($(auditconfig -getflags |
    nawk '$1 ~ /^active/{split($7, obj, "(");print obj[1]}' | tr ',' ' '))

  # Get an array of default non-attributable flags
  cur_defnaflags=($(auditconfig -getnaflags |
    nawk '$1 ~ /^active/{split($6, obj, "(");print obj[1]}' | tr ',' ' '))
fi


# Declare an empty array for errors
declare -a err

# Declare an empty array of verbose inspections
declare -a inspected


# Iterate ${defpolicy[@]}
for pol in ${defpolicy[@]}; do

  # Add to ${inspected[@]} array
  inspected+=("policy:${pol}")

  # Check for ${flag} in ${cur_defpolicy[@]}
  [ $(in_array "${pol}" "${cur_defpolicy[@]}") -eq 1 ] &&
    err+=("policy:${pol}")
done

# Iterate ${defflags[@]}
for flag in ${defflags[@]}; do

  # Add to ${inspected[@]} array
  inspected+=("defflags:${flag}")

  # Check for ${flag} in ${cur_defflags[@]}
  [ $(in_array "${flag}" "${cur_defflags[@]}") -eq 1 ] &&
    err+=("defflags:${flag}")
done

# Iterate ${defnaflags[@]}
for naflag in ${defnaflags[@]}; do

  # Add to ${inspected[@]} array
  inspected+=("defnaflags:${naflag}")

  # Check for ${flag} in ${cur_defflags[@]}
  [ $(in_array "${naflag}" "${cur_defnaflags[@]}") -eq 1 ] &&
    err+=("defnaflags:${naflag}")
done


###############################################
# Finish metrics
###############################################

# Get EPOCH
e_epoch="$(gen_epoch)"

# Determine miliseconds from start
seconds=$(subtract ${s_epoch} ${e_epoch})

# Generate a run time
[ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."


###############################################
# Results for printable report
###############################################

# If ${#err[@]} > 0
if [ ${#err[@]} -gt 0 ]; then

  # Set ${results} error message
  results="Failed validation"

  # Populate a value in ${errors[@]} if ${caller} is > 0
  [ ${caller} -gt 0 ] && errors=("${stigid}")
fi

# Set ${results} passed message
[ ${#err[@]} -eq 0 ] && results="Passed validation"


###############################################
# Report generation specifics
###############################################

# If ${caller} = 0
if [ ${caller} -eq 0 ]; then

  # Apply some values expected for general report
  stigs=("${stigid}")
  total_stigs=${#stigs[@]}

  # Generate the primary report header
  report_header
fi

# Capture module report to ${log}
module_header "${results}"

# Provide detailed results to ${log}
if [ ${verbose} -eq 1 ]; then

  # Print an array of inspected items
  print_array ${log} "inspected" "${inspected[@]}"
fi

# If we have accumulated errors
if [ ${#err[@]} -gt 0 ]; then

  # Print an array of the accumulated errors
  print_array ${log} "errors" "${err[@]}"
fi

# Print the modul footer
module_footer

if [ ${caller} -eq 0 ]; then

  # Apply some values expected for report footer
  [ ${status} -eq 1 ] && passed=${status} || passed=0
  [ ${status} -eq 1 ] && failed=0 || failed=${status}

  # Calculate a percentage from applied modules & errors incurred
  percentage=$(percent ${passed} ${failed})

  # Print the report footer
  report_footer

  # Print ${log} since we were called alone
  cat ${log}
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2017-06-21
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0047825
# STIG_Version: SV-60701r1
# Rule_ID: SOL-11.1-010340
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must be configured to audit failed attempts to access files and programs.
# Description: Without auditing, individual system accesses cannot be tracked, and malicious activity cannot be detected and traced back to an individual account.
