#!/bin/bash


# Define the IP protocols to target
declare -a protocols
protocols+=('tcp')


# Define an array of network device properties & their expected value
declare -A properties
properties['_conn_req_max_q']=1024


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
    v) verbose=1 ;;
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


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# Make sure ${#protocols[@]} > 0
if [ ${#protocols[@]} -eq 0 ]; then
  usage "Must define target protocols; i.e. ipv4, ipv6, icmp etc." && exit 1
fi

# Make sure ${#properties[@]} > 0
if [ ${#properties[@]} -eq 0 ]; then
  usage "Must define target properties; i.e. ignore_redirect, disable_forwarding etc." && exit 1
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


# Define an error handling array
declare -a errors

# Define a success handling array
declare -a success


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Iterate ${!properties[@]}
  for property in ${!properties[@]}; do

    # Iterate ${protocols[@]}
    for protocol in ${protocols[@]}; do

      # Set ${property} for ${properties[${property}]} corresponding to ${protocol}
      ipadm set-prop -p ${property}=${properties[${property}]} ${protocol} 2>/dev/null
    done
  done
fi



# Iterate ${!properties[@]}
for property in ${!properties[@]}; do

  # Iterate ${protocols[@]}
  for protocol in ${protocols[@]}; do

    # Capture ${property} for ${properties[${property}]} corresponding to ${protocol}
    value="$(ipadm show-prop -p ${property} -co current ${protocol})"

    if [ "${value}" != "${properties[${property}]}" ]; then

      # Push ${properties[${property}]} into the error handling array
      errors+=("${property}:${value}:${protocol}")
    else

      # Push ${properties[${property}]} into the passed handling array
      success+=("${property}:${value}:${protocol}")
    fi
  done
done


# Make sure ${#success[@]} > 0
if [ ${#success[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "The following network adapter properties passed validation:"

  # Iterate ${success[@]}
  for succ in ${success[@]}; do

    # Cut up ${succ}
    prop="$(echo "${succ}" | cut -d: -f1)"
    val="$(echo "${succ}" | cut -d: -f2)"
    prot="$(echo "${succ}" | cut -d: -f3)"

    print "  ${prop} = ${val} -> ${prot}"
  done
fi


# If ${#errors[@]} == 0 exit
if [ ${#errors[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"
  exit 0
fi

# Print friendly errors
[ ${verbose} -eq 1 ] && print "The following network adapter properties are mis-configured:"

# Iterate ${errors[@]}
for err in ${errors[@]}; do

  # Cut up ${err}
  eprop="$(echo "${err}" | cut -d: -f1)"
  eval="$(echo "${err}" | cut -d: -f2)"
  eprot="$(echo "${err}" | cut -d: -f3)"

  print "  ${eprop} = ${eval} -> ${eprot}" 1
done

[ ${verbose} -eq 1 ] && print "Failed conformity to '${stigid}'" 1
exit 1

# Date: 2017-06-21
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0048211
# STIG_Version: SV-61083r1
# Rule_ID: SOL-11.1-050120
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The system must set maximum number of incoming connections to 1024.
# Description: This setting controls the maximum number of incoming connections that can be accepted on a TCP port limiting exposure to denial of service attacks.
