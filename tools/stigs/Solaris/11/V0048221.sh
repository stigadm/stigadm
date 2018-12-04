#!/bin/bash


# Define the hosts.allow path
hosts_allow=/etc/hosts.allow

# Define the hosts.allow path
hosts_deny=/etc/hosts.deny

# Define a template
read -d '' wrapper_tpl <<"EOF"
ALL:{RANGE}
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

# Current value of inetadm for inetd? false/true
curr_inetd=$(inetadm -p|grep tcp_wrappers|grep -c FALSE)

# If ${curr_inetd} > 0 add to ${errors[@]} array
[ ${curr_inetd} -gt 0 ] &&
  errors+=("svc:/network/inetd:tcp_wrappers:FALSE")


# Gather up all of our possible services (legacy & modern)
services=( $(svcs -a | awk 'NR>1 && $3 ~ /svc:\//{print $3}' | sort | sed "s|:default||g")
           $(inetadm | awk '/svc:\//{print $NF}' | sort) )

# Filter ${servcies[@]} for those with a tcp_wrapper option
for service in ${services[@]}; do

  # Get service & configuration item name if matched
  item="$(svccfg -s ${service} listprop 2>/dev/null | grep tcp | grep boolean |
    awk '$1 ~ /wrappers$/{print}' | grep false |
    nawk -v svc="${service}" '{printf("%s:%s:%s\n", svc, $1, $3)}')"

  # If ${item} is null try ${service}:default configuration values
  [ "${item}" == "" ] &&
    item="$(svccfg -s ${service}:default listprop 2>/dev/null | grep tcp | grep boolean |
      awk '$1 ~ /wrappers$/{print}' | grep false |
      nawk -v svc="${service}" '{printf("%s:%s:%s\n", svc, $1, $3)}')"

  # If ${item} is still null assume legacy and switch to inetadm
  [ "${item}" == "" ] &&
    item="$(inetadm -l ${service} 2>/dev/null | grep tcp_wrappers | grep FALSE |
      nawk -v svc="${service}" '{gsub(/\=/, ":", $NF);printf("%s:%s\n", svc, $NF)}')"

  # If ${item} isn't null add to ${errors[@]}
  [ "${item}" != "" ] && errors+=("${item}")
done


# Acquire current IPv4 & IPv6 addresses
interfaces=( $(get_ipv4) $(get_ipv6) )

# Get array of current configurations from ${hosts_allow}
curr_allow=( $(awk '$1 ~ /^[0-9|a-zA-Z]+\:|[ALL|LOCAL|*KNOWN|PARANOID]\:.*/{print}' ${hosts_allow}|tr ' ' '_') )

# Iterate ${interfaces[@]}
for interface in ${interfaces[@]}; do

  # Cut out IPv4/IPv6 from ${interface}
  ip="$(echo "${interface}" | cut -d, -f2)"
  mask="$(echo "${interface}" | cut -d, -f3)"

  # If ${ip} & ${mask} are IPv4
  if [[ $(is_ipv4 "${ip}") -eq 0 ]] && [[ $(is_ipv4 "${mask}") -eq 0 ]]; then

    # Calculate the range for current ${interface} & number of nodes
    range=$(calc_ipv4_hosts_per_subnet "${mask}")

    # Iterate ${curr_allow[@]}
    for current in ${curr_allow[@]}; do

      # Cut out possible IPv4 address
      curr_ip="$(echo "${current}" |
        awk -F: '{if(NF==3){print $3}if(NF==2){print $2}if(NF==1){print $1}}')"

      # Normalize ${curr_ip}
      n_ip="$(normalize_ipv4 "${curr_ip}")"

      # Get the range from ${n_ip}
      cur_range=$(calc_ipv4_hosts_per_subnet "${n_ip}")
    done
  fi

done

# Push offenders to ${errors[@]} array

# Ensure ${hosts_deny} is indeed DENY by default

# If ${change} is enabled

# Make backup of both ${hosts_allow} & ${hosts_deny}

# Iterate ${errors[@]} & add to ${hosts_allow}

# Re-write ${hosts_deny} as ALL:ALL (deny by default)

# Refresh ${errors[@]} array


# Remove dupes and sort ${errors[@]}
errors=( $(remove_duplicates "${errors[@]}") )

# Copy ${services[@]} array to ${inspected[@]}
inspected+=( $(remove_duplicates "${services[@]}") )


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
