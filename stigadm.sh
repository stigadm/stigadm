#!/bin/bash

# stigadm
# Apply/Validate STIG by OS, Version & Classification

# Current working directory
cwd="$(dirname $0)"

# Path for assets
assets=${cwd}/tools/stigs/

# Define the library include path
lib_path=${cwd}/tools/libs

# Define the library template path(s)
templates=${cwd}/tools/templates/

# Define the system backup path
backup_path=${cwd}/tools/backups/$(uname -n | awk '{print tolower($0)}')


# Robot, do work


# Error if the ${inc_path} doesn't exist
if [ ! -d ${lib_path} ] ; then
  echo "Defined library path doesn't exist (${lib_path})" && exit 1
fi


# Include all .sh files found in ${lib_path}
incs=( $(ls ${lib_path}/*.sh) )

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


# Global defaults for tool
author=
bootenv=0
change=0
count=0
classification=
flags=
interactive=0
json=1
os=
restore=0
version=
list=
xml=0

# Get EPOCH
s_epoch="$(gen_epoch)"

# Global array of modules (reset)
declare -a stigs
stigs=()

# Tool name
prog="$(basename $0)"


# Copy ${prog} to ${appname} for friendly messages
appname="$(echo "${prog}" | cut -d. -f1)"


# Create a timestamp
timestamp="$(gen_date)"


# Default bootenv directory
bootenv_dir="${cwd}/.${appname}"


# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


# Displays available arg list
function usage()
{
  # Gather list of available supported OS's
  local os_list="$(get_os ${assets})"

  # Gather list of available supported versions (non-os dependent)
  local version_list="$(get_version ${assets})"


  # Handle error if present
  [ "${1}" != "" ] && error="$(print "${1}" 1)"


  # Print a friendly menu
  cat <<EOF
${appname} - Facilitates STIG Validation & Modifications
${error}

Usage ./${appname} [options]

  Help:
    -h  Show this message

  Targeting:
    -O  Operating System
      Supported: [${os_list}]

    -V  OS Version
      Supported: [${version_list}]

  Filters:
    -A  Application
      Supported: [Not yet implemented]

    -C  Classification
      Supported: [CAT-I|CAT-II|CAT-III]

    -L  VMS ID List - A comma separated list VMS ID's
      Example: V0047799,V0048211,V0048189

  Options:
    -a  Author name (required when using -c)
    -b  Use new boot environment (Solaris only)
    -c  Make the change

  Restoration:
    -r  Perform rollback of changes
    -i  Interactive mode, to be used with -r

  Reporting:
    -l  Default: /var/log/stigadm-<OS>-<VER>-<DATE>.json)
    -j  JSON reporting structure (default)
    -x  XML reporting structure

EOF
}


# Robot, do work


# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "a:bchijlrC:O:L:V:x" OPTION ; do
  case $OPTION in
    a) author=$OPTARG ;;
    b) bootenv=1 ;;
    c) change=1 ;;
    h) usage && exit 1 ;;
    i) interactive=1 ;;
    j) json=1 ;;
    l) log=1 ;;
    r) restore=1 ;;
    C) classification=$OPTARG ;;
    L) list=$OPTARG ;;
    O) os=$OPTARG ;;
    V) version=$OPTARG ;;
    x) xml=1 && ext="xml" && json=0 ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we have the necessary OS & Version
if [[ "${os}" == "" ]] && [[ "${version}" == "" ]]; then

  # Setup a temporary array for env vars
  declare -a t_env

  # If nothing supplied try to get it ourselves
  t_env=( $(set_env) )

  if [ ${#t_env[@]} -ne 2 ]; then

    # Alert to requirements
    usage "Must provide OS & Version" && exit 1
  fi

  # Break up ${t_env[@]} into elements
  os="${t_env[0]}"
  version="${t_env[1]}"
fi


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Enable change w/ author argument
if [ ${change} -eq 1 ]; then
  flags="${flags} -c"
  [ "${author}" != "" ] && flags=" -a ${author}"
fi

# Enable restoration mode
if [ ${restore} -eq 1 ]; then
  flags="${flags} -r"
  [ ${interative} -eq 1 ] && flags="${flags} -i"
fi


# Set the default log if nothing provided (/var/log/stigadm/<OS>-<VER>-<DATE>.json|xml)
log="${log:=/var/log/${appname}/${os}-${version}-${timestamp}.${ext:=json}}"

# If ${log} doesn't exist make it
[ ! -f ${log} ] && (mkdir -p $(dirname ${log}) && touch ${log})


# Set a default value for classification if null
classificiation="${classification:=ALL}"


# If ${#stigs[@]} is greater than 0
if [ ${#stigs[@]} -eq 0 ]; then

  # Get complete list of stig modules
  stigs=( $(find ${assets}/${os}/${version} -type f -name "*.sh") )

  # Copy ${#stigs[@]} to ensure accurate counts
  total_stigs=${#stigs[@]}

  # If ${classification} != ALL then filter ${stigs[@]} by ${classification}
  if [ "${classification}" != "ALL" ]; then

    # Filter ${stigs[@]} array
    stigs=( $(echo "${stigs[@]}" | xargs grep -il "Severity: ${classification}$") )
  fi

  # If ${list} is not NULL create a filter & whittle down ${stigs[@]} with it
  if [ "${list}" != "" ]; then

    # Convert ${list} to an array
    list=( $(echo "${list}" | tr ',' ' ') )

    # Create a filter for egrep with ${list}
    filter="$(echo "${list[@]}" | tr ' ' '|')"

    # Replace ${stigs[@]} with filtered results
    stigs=( $(echo "${stigs[@]}" | tr ' ' '\n' | egrep -i "${filter}") )
  fi
fi

# If ${#stigs[@]} = 0 exit
if [ ${#stigs[@]} -eq 0 ]; then

  # Notify and provide usage menu
  usage "'${#stigs[@]}' STIG modules found; aborting" && exit 1
fi

# Re-sort & remove duplicates from ${stigs[@]}
stigs=( $(remove_duplicates "${stigs[@]}") )

# If ${#stigs[@]} != ${list[@]} get missing module(s)
if [ ${#stigs[@]} -ne ${#list[@]} ]; then

  # Define an array for missing modules
  declare -a missing

  # Iterate ${list[@]}
  for item in ${list[@]}; do

    # Look for ${item} in ${stigs[@]}
    if [ $(in_array_loose "${item}" "${stigs[@]}") -eq 1 ]; then

      # Add to ${missing[@]} array
      missing+=("${item}")
    fi
  done
fi


# If ${change} = 1, ${os} is Solaris & ${bootenv} = 1 setup a new BE
if [[ "$(to_lower "${os}")" == "solaris" ]] && [[ ${bootenv} -eq 1 ]] && [[ ${change} -eq 1 ]]; then

  # Define a name for the boot environment
  bename="${appname}-${author}-${timestamp}"

  # Be verbose if asked
  [ ${verbose} -eq 1 ] && print "Using new boot environment for changes; ${bename}"

  # Build & activate ${bename} while handling errors
  bootenv "${bename}" ${version}
  ret=$?
  case ${ret} in
    1) usage "Could not create boot environment; ${bename}" && exit 1 ;;
    2) usage "Could not activate boot environment; ${bename}" && exit 1 ;;
    3) usage "Could not validate boot environment; ${bename}" && exit 1 ;;
    0) break ;; # Mount bename, copy stigadm toolkit & chroot to env FIX!!
    ?) usage "Unknown error occurred with boot env. ${bename}; ${ret}" && exit 1 ;;
  esac
fi


# Iterate ${stigs[@]}
for stig in ${stigs[@]}; do

  # Get a nicer name for the ${stig} file
  stig_name="$(basename ${stig} | cut -d. -f1)"

  # Capture results from ${stig} ${flags} execution
  cat <<EOF
${results:=""}
results="$(./${stig} ${flags})"
EOF

  # Capture any errors
  [ $? -ne 0 ] && errors+=("${stig_name}");
done


# Calculate a percentage from applied modules & errors incurred
percentage=$(subtract $(percent ${#stigs[@]} ${#errors[@]}) 100)

# Get EPOCH
e_epoch="$(gen_epoch)"

seconds=$(subtract ${s_epoch} ${e_epoch})

# Generate a run time
[ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."

# Print something out
cat <<EOF
[${appname}]: ${timestamp}
STIG Compliance: ${percentage}%
 Failed: ${#errors[@]}/${#stigs[@]} of ${total_stigs}
  Details:
$(echo "${errors[@]}")

Run time: ${run_time}
EOF


# Exit with the number of errors
exit ${#errors[@]}
