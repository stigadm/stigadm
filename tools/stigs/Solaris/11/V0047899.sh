#!/bin/bash

# Define an whitelist of accounts to ignore
declare -a whitelist
whitelist+=("root")
whitelist+=("nobody")
whitelist+=("noaccess")
whitelist+=("nogroup")

# Define a range of UID/GID's to associate with the ${application_accounts[@]} array
#  NOTE: Application account restrictions fall under 'priv'
declare -A application_acct_range
application_acct_range['min']=100
application_acct_range['max']=500

# Define a range of UID's to associat with the ${user_accounts[@]} array
#  NOTE: Application account restrictions fall under 'basic'
declare -A user_acct_range
user_acct_range['min']=501
user_acct_range['max']=2147483647


# Boolean true/false to set properties per configured zone
config_per_zone=1

# Define a whitelist of VNIC's to include for resource limitations from ${network_properties[@]}
#  NOTE: This also filters existing interfaces from zones if ${config_per_zone} is true
declare -a network_whitelist
network_whitelist+=("vnic0")

# Define an associative array of virtual nic properties
declare -A network_properties
network_properties["protection"]="mac-nospoof,restricted,ip-nospoof,dhcp-nospoof" # See `man dladm` for info
network_properties["allowed-ips"]=1 # Limits allowed outbound SRC datagrams on list ONLY (Acquires from configured IP's)
network_properties["maxbw"]="75%" # Use ${network_whitelist[@]} array to include VNIC's that need to limit bandwidth on


# An associative array of project attributes for application user accounts
declare -A application_accounts
application_accounts["process.max-file-descriptor"]=64000
application_accounts["process.max-stack-size"]="80%"
application_accounts["process.max-address-space"]="90%"
application_accounts["project.max-locked-memory"]="80%"
application_accounts["project.cpu-shares"]="80%"
application_accounts["project.max-shm-ids"]=64000
application_accounts["project.max-shm-memory"]="80%"
application_accounts["project.max-tasks"]=64000
application_accounts["project.max-lwps"]=64000
application_accounts["task.max-processes"]=64000


# An associative array of project attributes for end user accounts
declare -A user_accounts
user_accounts["process.max-file-descriptor"]=32000
user_accounts["process.max-stack-size"]="75%"
user_accounts["process.max-address-space"]="75%"
user_accounts["project.cpu-shares"]="75%"
user_accounts["project.max-locked-memory"]="75%"
user_accounts["project.max-shm-ids"]=32000
user_accounts["project.max-shm-memory"]="75%"
user_accounts["project.max-tasks"]=32000
user_accounts["project.max-lwps"]=32000
user_accounts["task.max-processes"]=32000


# An associative array of zone specific project limits
declare -A zone_limits
zone_limits["zone.cpu-shares"]="80%"
zone_limits["zone.max-lofi"]=8
zone_limits["zone.max-lwps"]=64000
zone_limits["zone.max-processes"]=64000
zone_limits["zone.max-shm-ids"]=64000
zone_limits["zone.max-shm-memory"]="80%"
zone_limits["zone.max-swap"]="80%"


# Define a log level for resource exceptions
log_level="warning"

# What action should the OS take on a resource exception?
action="deny"


# Define the project file
file=/etc/project


# Define the location of the nsswitch.conf
nsswitch=/etc/nsswitch.conf


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
  report "${stigid} only applies to global zones" && exit 1
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
  report "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

# Get total number of CPU's
cpus=$(psrinfo | wc -l)

# Get total amount of physical memory
memory=$(prtconf | awk '$1 ~ /Memory/{printf("%s\n", $3)}')


# Get an array of configured zones (excluding global)
zones=( $(zoneadm list -civ |
  awk 'NR > 1 && $0 !~ /global/{printf("%s:%s\n", $2, $4)}') )

# Get current network resources
current_network_resources=( $(get_network_resources) )

# Calculate percentages for the following:
#  - CPU / [Memory | Zone] / X (Where X is the project|network limit)


# Create an exclude filter of users/groups from ${whitelist[@]}
filter="$(echo "${whitelist[@]}" | tr ' ' '|')"

# Get an array of application groups that are within min/max ranges
declare -a app_groups
app_groups=( $(getent group |
  nawk -F: -v min=${application_acct_range['min']} -v max=${application_acct_range['max']} \
    -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}') )

# Get an array of application users that are within min/max ranges
declare -a app_users
app_users=( $(getent passwd |
  nawk -F: -v min=${application_acct_range['min']} -v max=${application_acct_range['max']} \
    -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}') )

# Get an array of groups that are within min/max ranges
declare -a groups
groups=( $(getent group |
  nawk -F: -v min=${user_acct_range['min']} -v max=${user_acct_range['max']} \
    -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}') )

# Get an array of users that are within min/max ranges
declare -a users
users=( $(getent passwd |
  nawk -F: -v min=${user_acct_range['min']} -v max=${user_acct_range['max']} \
    -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}') )


# If ${config_per_zone} is true
if [ ${config_per_zone} -eq 1 ]; then

  # Define associative arrays to handle per zone configs
  declare -A zone_app_groups
  declare -A zone_app_users
  declare -A zone_groups
  declare -A zone_users

  # Iterate ${zones[@]}
  for zone in ${zones[@]}; do

    # Cut out zone name
    zpath="$(echo "${zone}" | cut -d: -f2)"
    zone="$(echo "${zone}" | cut -d: -f1)"

    # Populate ${zone} element of filtered application groups
    zone_app_groups["${zone}"]="$(zlogin ${zone} 'getent group' 2>/dev/null |
      nawk -F: -v min=${application_acct_range['min']} -v max=${application_acct_range['max']} \
        -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}')"

    # Populate ${zone} element of filtered application users
    zone_app_users["${zone}"]="$(zlogin ${zone} 'getent passwd' 2>/dev/null |
      nawk -F: -v min=${application_acct_range['min']} -v max=${application_acct_range['max']} \
        -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}')"

    # Populate ${zone} element of filtered groups
    zone_groups["${zone}"]="$(zlogin ${zone} 'getent group' 2>/dev/null |
      nawk -F: -v min=${application_acct_range['min']} -v max=${application_acct_range['max']} \
        -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}')"

    # Populate ${zone} element of filtered users
    zone_users["${zone}"]="$(zlogin ${zone} 'getent passwd' 2>/dev/null |
      nawk -F: -v min=${user_acct_range['min']} -v max=${user_acct_range['max']} \
        -v filter="${filter}" '$3 >= min && $3 <= max && $1 !~ filter{printf("%s\n", $1)}')"
  done
fi


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  #bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${pkgs[@]}" | tr ' ' '\n')"
  if [ $? -ne 0 ]; then

    # Verbose
    report "Snapshot of broken packages failed..." 1

    # Stop, we require a backup
    exit 1
  fi
fi


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
# Disable debugging if it was enabled
###############################################
[ ${debug} -eq 1 ] && set +x


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047899
# STIG_Version: SV-60771r1
# Rule_ID: SOL-11.1-090280
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must manage excess capacity, bandwidth, or other redundancy to limit the effects of information flooding types of denial of service attacks.
# Description: In the case of denial of service attacks, care must be taken when designing the operating system so as to ensure that the operating system makes the best use of system resources.
