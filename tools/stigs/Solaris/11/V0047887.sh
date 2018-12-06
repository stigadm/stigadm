#!/bin/bash


# Define an array of properties
declare -a properties
properties+=("signature-policy:verify")


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
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is as group
caller=$(ps -p $PPID | grep -c stigadm)


###############################################
# Perform restoration
###############################################

# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  report "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

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

    # Trap error
    report "Snapshot of package policy failed..."

    # Stop, we require a backup
    exit 1
  fi


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

# Verbose
inspected+=("${cproperties[@]}")


###############################################
# Results for printable report
###############################################

# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Set ${results} error message
  results="Failed validation"
fi

# Set ${results} passed message
[ ${#errors[@]} -eq 0 ] && results="Passed validation"


###############################################
# Report generation specifics
###############################################

# Apply some values expected for report footer
[ ${#errors[@]} -eq 0 ] && passed=1 || passed=0
[ ${#errors[@]} -gt 0 ] && failed=${#errors[@]} || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})


# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047887
# STIG_Version: SV-60759r1
# Rule_ID: SOL-11.1-020040
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must protect audit tools from unauthorized modification.
# Description: Failure to maintain system configurations may result in privilege escalation.
