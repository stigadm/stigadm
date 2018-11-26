#!/bin/bash


# RBAC role array
declare -A profile
profile['name']='RestrictOutbound'
profile['desc']='Restrict Outbound Connections'
profile['limitpriv']='zone,!net_access'


# UID minimum as exclusionary for system/service accounts
uid_min=100

# UID/Account exceptions (any UID/username within ${uid_min}...2147483647 to exclude)
declare -a user_excp
user_excp+=(60001) # nobody
user_excp+=(60002) # nobody4
user_excp+=(65534) # noaccess
user_excp+=('acas')
user_excp+=('ca_user')
user_excp+=('ctm')
user_excp+=('cmacct1')
user_excp+=('CMacct1')
user_excp+=('CMacct2')
user_excp+=('ldap-bind')
user_excp+=('oracle')
user_excp+=('sapadm')
user_excp+=('splunk')


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


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


# Ensure ${#profile[@]} > 0
if [[ ${#profile[@]} -eq 0 ]] || [[ -z ${profile['name']} ]]; then
  usage "An RBAC profile must be defined & include a 'name',  'desc' & 'limitpriv' key/value combination" && exit 1
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


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Get properties of ${profile['name']}
  properties="$(profiles -p ${profile['name']} info)"

  # Create backup of file(s), settings or permissions on inodes
  # (see existing facilities in ${lib_path}/backup.sh)

  # Split the existing 'limitpriv' value up into an array
  privs=($(echo "${properties}" | awk '$0 ~ /limitpriv/{split($0, obj, "="); if (obj[2] != ""){print obj[2]}}' | tr ',' ' '))

  # Iterate ${profile[@]}
  for prop in ${!profile[@]}; do

    # Skip ${profile['name']}
    [ "${prop}" == "name" ] && continue

    # If ${prop} == "limitprivs"
    if [ "${prop}" == "limitprivs" ]; then

      # Split supplied limitprivs into an array
      tprop=($(echo "${profile[${prop}]}" | tr ',' ' '))

      # Combine ${profile[${prop}]} w/ ${tprop[@]} while removing duplicates & convert to a string
      prop="$(remove_duplicates "${profile[${prop}]}" "${tprop[@]}" | tr ' ' ',')"
    fi

    # Set ${profile['name']} property ${prop} = ${profile[${prop}]}
    profiles -p ${profile['name']} set ${prop}=${profile[${prop}]}
    if [ $? -ne 0 ]; then

      [ ${verbose} -eq 1 ] && print "Could not set '${profile['name']}' property for '${prop}' to '${property[${prop}]}'" 1
    fi
  done
fi


# Get properties of ${profile['name']} into an array
properties=($(profiles -p ${profile['name']} info | tr ' ' '_' | tr '\n' ' ' | xargs))

# Make sure ${#properties[@]} > 0
if [ ${#properties[@]} -eq 0 ]; then
  print "Could not locate any RBAC's named '${profile['name']}'" 1
  exit 1
fi


# Split the existing 'limitpriv' value up into an array
privs=($(echo "${properties}" | awk '$0 ~ /limitpriv/{split($0, obj, "="); if (obj[2] != ""){print obj[2]}}' | tr ',' ' '))

# Iterate ${profile[@]}
for prop in ${!profile[@]}; do

  # Skip ${profile['name']}
  [ "${prop}" == "name" ] && continue

  # If ${prop} == "limitprivs"
  if [ "${prop}" == "limitprivs" ]; then

    # Split supplied limitprivs into an array
    tprop=($(echo "${profile[${prop}]}" | tr ',' ' '))

    # Combine ${profile[${prop}]} w/ ${tprop[@]} while removing duplicates & convert to a string
    prop="$(remove_duplicates "${profile[${prop}]}" "${tprop[@]}" | tr ' ' ',')"
  fi
done


# If ${#user_excl[@]} > 0 create a pattern
pattern="$(echo "${user_excp[@]}" | tr ' ' '|')"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Created exclude pattern ($(truncate_cols "${pattern}" 20))"


# Get current list of users (greater than ${uid_min} & excluding ${uid_excl[@]})
user_list=($(nawk -F: -v min="${uid_min}" -v pat="${pattern}" '$3 >= min && $3 !~ pat && $1 !~ pat{print $1}' /etc/passwd 2>/dev/null | sort -u))


# If ${#user_list[@]} = 0 exit
if [ ${#user_list[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#user_list[@]}' users found meeting criteria for examination; exiting" 1

  exit 1
fi



# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create backup of file(s), settings or permissions on inodes
  # (see existing facilities in ${lib_path}/backup.sh)

  # Iterate ${user_list[@]}
  for user in ${user_list[@]}; do

    # Apply RBAC ${profile['name']} to ${user}
    usermod -P +${profile['name']} ${user} 2> /dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Unable to assign '${profile['name']}' RBAC to '${user}'" 1
    fi
  done

fi


# Iterate ${user_list[@]}
for user in ${user_list[@]}; do

  # Obtain a list of offending accounts based
  accounts+=($(profiles -l ${user} | nawk -v usr="${user}" '$0 ~ usr{getline; if (!match($0, /^RestrictOutbound$/)){print usr}}'))
done

# If ${#accounts[@]} = 0 exit
if [ ${#accounts[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#accounts[@]}' accounts found, system conforms to '${stigid}'"
  exit 0
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "'${#accounts[@]}' accounts found, not conforming to '${stigid}'" 1


# Exit 1 if validation failed


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048147
# STIG_Version: SV-61019r1
# Rule_ID: SOL-11.1-040490
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must prevent remote devices that have established a non-remote connection with the system from communicating outside of the communication path with resources in external networks.
# Description: This control enhancement is implemented within the remote device (e.g., notebook/laptop computer) via configuration settings not configurable by the user of the device. An example of a non-remote communications path from a remote device is a virtual private network. When a non-remote connection is established using a virtual private network, the configuration settings prevent split-tunneling. Split-tunneling might otherwise be used by remote users to communicate with the information system as an extension of the system and to communicate with local resources, such as a printer or file server. The remote device, when connected by a non-remote connection, becomes an extension of the information system allowing dual communications paths, such as split-tunneling, in effect allowing unauthorized external connections into the system. This is a split-tunneling requirement that can be controlled via the operating system by disabling interfaces.
