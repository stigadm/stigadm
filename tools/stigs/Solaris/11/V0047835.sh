#!/bin/bash

# Define the aliases file
aliases=/etc/mail/aliases

# Define the notification stanza
declare -a log_levels
log_levels+=("audit_warn")


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
# Perform restoration
###############################################

# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  usage "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

# Define an array of inspected items
declare -a inspected

# Define an array of errors
declare -a errors

# Bail if ${log_levels[@]} not defined
if [ ${#log_levels[@]} -eq 0 ]; then
  usage "${#log_levels[@]} log levels defined" && exit 1
fi


# Create a filter of ${log_levels[@]}
filter="$(echo "${log_levels[@]}" | tr ' ' '\n' |
  nawk '{printf("^%s\n", $0)}' | tr '\n' '|')"

# Pull the ending | from ${filter}
filter="${filter:0:${#filter}-1}"

# Get a count based on ${filter} from ${aliases}
total=$(egrep -c ${filter} ${aliases})


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a backup
  bu_file "${author}" "${aliases}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    usage "Unable to create snapshot of per user audit flags" && exit 1
  fi

  # Iterate ${users[@]}
  for user in ${users[@]}; do

    # Cut out the username from ${user}
    user="$(echo "${user}" | cut -d: -f1)"

    # Reset all audit_flags per ${user}
    usermod -K audit_flags= ${user} 2>/dev/null

    # Trap error
    [ $? -gt 1 ] && errors+=("audit_flags:${user}")
  done

  # Reset ${users[@]} so we can refresh it
  users=()

  # Iterate all user accounts on system
  for account in ${accounts[@]}; do

    # Skip root account
    [ "${account}" == "root" ] && continue

    # Get list of users & any auditing flags
    users+=("${account}:$(userattr audit_flags ${account})")
  done
fi

# Iterate ${users[@]}
for user in ${users[@]}; do

  # Split ${user} up
  flags="$(echo "${user}" | cut -d: -f2)"
  user="$(echo "${user}" | cut -d: -f1)"

  # If ${flags} is not NULL then add to an error array
  [ "${flags}" != "" ] && errors+=("audit_flags:${user}")

  # If verbosity enabled
  [ ${verbose} -eq 1 ] && inspected+=("audit_flags:${user}")
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
if [ ${#errors[@]} -gt 0 ]; then

  # Print an array of the accumulated errors
  print_array ${log} "errors" "${errors[@]}"
fi

# Print the modul footer
module_footer

if [ ${caller} -eq 0 ]; then

  # Apply some values expected for report footer
  [ ${#errors[@]} -eq 0 ] && passed=1 || passed=0
  [ ${#errors[@]} -ge 1 ] && failed=1 || failed=0

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




# Define an array of users to handle audit notifications
declare -a administrators
administrators+=("root")


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


# Create a timestamp
ts=$(gen_date)


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


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
fi


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Make sure ${administrators[@]} is defined
if [ ${#administrators[@]} -eq 0 ]; then
  [ ${verbose} -eq 1 ] && print "'${#administrators[@]}' users defined for audit notifications" 1
  exit 1
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


# Get a list of currently defined users in ${aliases} for audit_warn
cur_aliases=( $(grep "^audit_warn" ${aliases} | cut -d: -f2 | sort -u | tr ',' ' ') )


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # If ${aliases} exists make a backup
  if [ -f ${aliases} ]; then
    bu_file "${author}" "${aliases}"
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Could not create a backup of '${aliases}', exiting..." 1
      exit 1
    fi
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${aliases}'"


  # Create a working copy
  cp -p ${aliases} ${aliases}-${ts}


  # Combine ${cur_aliases[@]} with ${administrators[@]} & remove dupes
  administrators=( "$(remove_duplicates "${cur_aliases[@]}" "${administrators[@]}")" )

  # Create a string from ${administrators[@]}
  administrators_str="$(echo "${administrators[@]}" | tr ' ' ',')"

  # If ^audit_warn exists in ${aliases}
  if [ $(grep -c "^audit_warn:" ${aliases}) -gt 0 ]; then

    # Replace audit_warn with our new combined list of users
    sed "s|^\(audit_warn:\).*$|\1${administrators_str}|g" ${aliases} > ${aliases}-${ts}
  else

    # Add our new list of administrators
    echo "audit_warn:${administrators_str}" >> ${aliases}-${ts}
  fi


  # Make sure ${administrators_str} exists
  if [ $(grep -c "^audit_warn:${administrators_str}$" ${aliases}-${ts}) -eq 0 ]; then
    [ ${verbose} -eq 1 ] && print "An error occured adding users to ${aliases}-${ts}" 1
    rm ${aliases}-${ts}
  else
    mv ${aliases}-${ts} ${aliases}
  fi


  # Get a list of currently defined users in ${aliases} for audit_warn
  cur_aliases=( $(grep "^audit_warn" ${aliases} | cut -d: -f2 | sort -u | tr ',' ' ') )

  # Import the aliases
  newaliases &>/dev/null
  if [ $? -ne 0 ]; then
    [ ${verbose} -eq 1 ] && print "Could not import new aliases" 1
  fi
fi


# Define an empty errors array
declare -a errors

# If ${#cur_aliases[@]} is empty add all of ${administrators[@]} to ${errors[@]}
if [ ${#cur_aliases[@]} -eq 0 ]; then
  errors=( "${administrators[@]}" )
else

  # Iterate ${cur_aliases[@]}
  for alias in ${cur_aliases[@]}; do

    # Look for ${alias} in ${administrators[@]}
    if [ $(in_array "${alias}" "${administrators[@]}") -eq 1 ]; then

      # Add ${alias} to ${errors[@]}
      errors+=("${alias}")
    fi
  done
fi


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Could not validate '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  ${error}" 1
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
# STIG_ID: V0047835
# STIG_Version: SV-60709r1
# Rule_ID: SOL-11.1-010370
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must alert the SA when the audit storage volume approaches its capacity.
# Description: Filling the audit storage area can result in a denial of service or system outage and can lead to events going undetected.
