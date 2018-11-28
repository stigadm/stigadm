#!/bin/bash


# Define the hosts.allow path
hosts_allow=/etc/hosts.allow

# Define the hosts.allow path
hosts_deny=/etc/hosts.deny

# Define a template
read -d '' wrapper_tpl <<"EOF"
ALL:{RANGE}:banners /etc/issue
EOF


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

# Acquire current IPv4 & IPv6 addresses
ipv4=( $(get_ipv4) )
ipv6=( $(get_ipv6) )

# Get list of current configurations from ${hosts_allow}

# Compare current against ${ipv4[@]} & ${ipv6[@]}

# Push offenders to ${errors[@]} array

# Ensure ${hosts_deny} is indeed DENY by default

# If ${change} is enabled

# Make backup of both ${hosts_allow} & ${hosts_deny}

# Iterate ${errors[@]} & add to ${hosts_allow}

# Re-write ${hosts_deny} as ALL:ALL (deny by default)

# Refresh ${errors[@]} array


# Examine inetdadm for TCP_WRAPPERS enabled

# If not push to ${errors[@]} array

# If ${change} enabled

# Enable TCP_WRAPPERS for inetd


# Since SOME of the legacy services have moved to SMF
services=( $(svcs -a | awk 'NR>1{print $3}' | sort | sed "s|:default||g") )

# Filter ${servcies[@]} for those with a tcp_wrapper option
for service in ${services[@]}; do

  # Get service & configuration item name if matched
  item="$(svccfg -s ${service} listprop 2>/dev/null | grep tcp | grep boolean |
    awk '$1 ~ /wrappers$/{print}' | grep false | nawk -v svc="${service}" '{printf("%s:%s:%s\n", svc, $1, $3)}')"

  # If ${item} is null try ${service}:default configuration values
  [ "${item}" == "" ] &&
    item="$(svccfg -s ${service}:default listprop 2>/dev/null | grep tcp | grep boolean |
      awk '$1 ~ /wrappers$/{print}' | grep false | nawk -v svc="${service}" '{printf("%s:%s:%s\n", svc, $1, $3)}')"

  # If ${item} isn't null add to ${errors[@]} because it has a configuration option for tcpwrappers and is NOT enabled
  [ "${item}" != "" ] && errors+=("${item}")
done

# Copy ${services[@]} array to ${inspected[@]}
inspected+=( "$(echo "${services[@]}"|tr ' ' '\n'|awk '{printf("Service:%s\n", $0)}')" )


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

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2018-09-05
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0048221
# STIG_Version: SV-61093r1
# Rule_ID: SOL-11.1-050140
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The system must implement TCP Wrappers.
# Description: The system must implement TCP Wrappers.
