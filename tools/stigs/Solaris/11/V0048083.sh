#!/bin/bash

# Define the configuration file for the max lockout value
file=/etc/default/login

# Define max value before account is locked
max=35

# Excluded usernames
declare -a excluded
excluded+=("root")
excluded+=("adm")
excluded+=("daemon")
excluded+=("dladm")
excluded+=("ikeuser")
excluded+=("lp")
excluded+=("netadm")
excluded+=("netcfg")
excluded+=("ocm")
excluded+=("pkg5srv")
excluded+=("zfssnap")


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

# Whos is calling? 0 = singular, 1 is from stigadm
caller=$(ps $PPID | grep -c stigadm)


###############################################
# STIG validation/remediation/restoration
###############################################

# Get the current configured value
cmax=$(useradd -D | xargs -n 1 | grep inactive | cut -d= -f2)

# Convert ${excluded[@]} to a filter
filter="$(echo "${excluded[@]}" | tr ' ' '|')"

# Get a list of roles excluding those in ${filter}
roles=( $(logins -arxo | cut -d: -f1 | egrep -v ${filter}) )

# Get array of all accounts & roles excluding those in ${filter}
accounts=( $(logins -axo | tr ' ' '_' | egrep -v ${filter}) )


# Extract those ${accounts[@]} with passwords & exceeding ${max}
errors=( $(echo "${accounts[@]}" | tr ' ' '\n' | sort -u |
  nawk -F: -v max="${max}" '$13 > max || $13 == -1 && $8 ~ /^PS|UP|LK|UN|NL$/{printf("%s:%s\n", $1, $13)}') )

# Add to our ${errors[@]} array if inactivity is > ${max}
[ ${cmax} -gt ${max} ] &&
  errors+=("inactive:${cmax}")


# If ${change} is requested
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a backup of the passwd database
  bu_passwd_db "${author}"
  if [ $? -ne 0 ]; then

    # Bail if we can't create a backup
    report "Failed to create backup of local passwd db" && exit 1
  fi

  # Create a backup of ${file}
  bu_file "${author}" "${file}"
  if [ $? -ne 0 ]; then

    # Bail if we can't create a backup
    report "Failed to create backup of ${file}" && exit 1
  fi

  # Fix ${cmax} if > ${max}
  [ ${cmax} -gt ${max} ] &&
    useradd -D -f ${max} &> /dev/null


  # Iterate ${errors[@]}
  for acct in ${errors[@]}; do

    # Cut user from ${acct}
    acct="$(echo "${acct}" | cut -d: -f1)"

    # Fix the account
    [ $(in_array "${acct}" "${roles[@]}") -eq 1 ] &&
      usermod -f ${max} ${acct} 2> /dev/null ||
      rolemod -f ${max} ${acct} 2> /dev/null
  done


  # Get the current configured value
  cmax=$(useradd -D | xargs -n 1 | grep inactive | cut -d= -f2)

  # Add to our ${errors[@]} array if inactivity is > ${max}
  [ ${cmax} -gt ${max} ] &&
    errors+=("inactive:${cmax}")


  # Refresh ${accounts[@]} array exclusing ${filter}
  accounts=( $(logins -axo | tr ' ' '_' | egrep -v ${filter}) )

  # Refresh ${errors[@]}
  errors=( $(echo "${accounts[@]}" | tr ' ' '\n' | sort -u |
    nawk -F: -v max="${max}" '$13 > max || $13 == -1 && $8 ~ /^PS|UP|LK|UN|NL$/{printf("%s:%s\n", $1, $13)}') )
fi

# Copy ${accounts[@]} to ${inspected[@]}
inspected=( $(echo "${accounts[@]}" | tr ' ' '\n' | sort | awk -F: '{printf("%s:%s\n", $1, $13)}') )


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
[ ${#errors[@]} -gt 0 ] && failed=1 || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})

# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code
exit ${#errors[@]}


# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048083
# STIG_Version: SV-60955r1
# Rule_ID: SOL-11.1-040290
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must manage information system identifiers for users and devices by disabling the user identifier after 35 days of inactivity.
# Description: Inactive accounts pose a threat to system security since the users are not logging in to notice failed login attempts or other anomalies.
