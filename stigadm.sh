#!/bin/bash

# stigadm
# Apply/Validate STIG by OS, Version & Classification

# Current working directory
cwd="$(dirname $0)"

# Path for assets
assets=${cwd}/tools/stigs/

# Define the library include path
lib_path=${cwd}/tools/libs

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
classification=
flags=
debug=0
interactive=0
os=
restore=0
version=
verbose=0
list=

# Global array of modules (reset)
declare -a stigs
stigs=()

# Tool name
prog="$(basename $0)"


# Copy ${prog} to ${appname} for friendly messages
appname="$(echo "${prog}" | cut -d. -f1)"


# Create a timestamp
timestamp="$(date +%Y%m%d-%H%M)"


# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


# Displays available arg list
function usage()
{
  # Gather list of available supported OS's
  local os_list="$(get_os ${assets})"

  # Gather list of available supported versions (non-os dependent)
  local version_list="$(get_version ${assets}/*/)"

  # Gather list of available supported severity (non-os dependent)
  local classificication_list="$(get_classification ${assets})"

  
  # Handle error if present
  [ "${1}" != "" ] && error="$(print "${1}" 1)"


  # Print a friendly menu
  cat <<EOF
${appname} - Facilitates STIG Validation & Modifications
${error}

Usage ./${appname} [options]

  Help:
    -h  Show this message

  Required:
    -O  Operating System
      Supported: [${os_list}]

    -V  OS Version
      Supported: [${version_list}]

  Filters:
    -A  Application
      Supported: [Not yet implemented]

    -C  Classification
      Supported: [${classificication_list}]
      
    -L  VMS ID List - A comma separated list VMS ID's
      Example: V0047799,V0048211,V0048189

  Options:
    -a  Author name (required when using -c)
    -b  Use new boot environment (Solaris only)
    -c  Make the change
    -d  Debug mode
    -v  Enable verbosity mode

  Restoration:
    -r  Perform rollback of changes
    -i  Interactive mode, to be used with -r

EOF
}


# Robot, do work


# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "a:bcdhirvC:O:L:V:" OPTION ; do
  case $OPTION in
    a) author=$OPTARG ;;
    b) bootenv=1 ;;
    c) change=1 ;;
    d) debug=1 && set +x ;;
    h) usage && exit 1 ;;
    i) interactive=1 ;;
    r) restore=1 ;;
    v) verbose=1 ;;
    C) classification=$OPTARG ;;
    L) list=$OPTARG ;;
    O) os=$OPTARG ;;
    V) version=$OPTARG ;;
    ?) usage && exit 1 ;;
  esac
done


# Make sure we have the necessary OS & Version
if [[ "${os}" == "" ]] && [[ "${version}" == "" ]]; then
  
  # Run the wizard to walk the user through a target STIG
  wizard "${assets}"
  
  # Handle return
  if [ $? -ne 0 ]; then
    print "An occurred with wizard implementation, exiting"
    exit 1
  fi
  echo
fi


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# Turn on verbosity flag if defined
[ ${verbose} -eq 1 ] && flags=" -v"

# Turn on debug flag if defined
[ ${debug} -eq 1 ] && flags="${flags} -d"

# Enable change w/ author argument
if [ ${change} -eq 1 ]; then
  flags="${flags} -c"
  [ "${author}" != "" ] && flags="${flags} -a ${author}"
fi

# Enable restoration mode
if [ ${restore} -eq 1 ]; then
  flags="${flags} -r"
  [ ${interative} -eq 1 ] && flags="${flags} -i"
fi

# Set a default value for classification if null
classificiation="${classification:=ALL}"


# If ${#stigs[@]} is greater than 0
if [ ${#stigs[@]} -eq 0 ]; then

  # Get complete list of stig modules
  stigs=( $(find ${assets}/${os}/${version} -type f -name "*.sh") )

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

  print "'${#stigs[@]}' STIG modules found; aborting" 1
  exit 1
fi

# Re-sort & remove duplicates from ${stigs[@]}
stigs=( $(remove_duplicates "${stigs[@]}") )

# If ${#stigs[@]} != ${list[@]} get missing module(s)
if [ ${#stigs[@]} -ne ${#list[@]} ]; then
  
  # Define an array for missing modules
  declare -a missing
  
  # Get intersection from ${list[@]} & ${stigs[@]}
  missing=( $(comm -3 <(printf '%s\n' "${list[@]}" | sort -u) <(printf '%s\n' "$(echo "${stigs[@]}" | tr ' ' '\n' | nawk '{system("basename " $0)}' | cut -d. -f1 | tr '\n' ' ')" | sort -u) ) )
fi


# Be verbose if asked
[ ${verbose} -eq 1 ] && print "Built list of STIG modules: ${#stigs[@]}/${#list[@]}"
[ ${verbose} -eq 1 ] && print "  OS: ${os} Version: ${version} Classification: ${classification}"
[ ${verbose} -eq 1 ] && echo

# Provide list from ${missing[@]}
if [[ ${verbose} -eq 1 ]] && [[ ${#missing[@]} -gt 0 ]]; then
  print "Missing modules:" 1
  print "  $(echo "${missing[@]}")" 1
  echo
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
    1) print "Could not create boot environment; ${bename}" 1 && exit 1 ;;
    2) print "Could not activate boot environment; ${bename}" 1 && exit 1 ;;
    3) print "Could not validate boot environment; ${bename}" 1 && exit 1 ;;
    0) [ ${verbose} -eq 1 ] && print "Created, activated & validated boot env; ${bename}" ;;
    ?) print "Unknown error occurred with boot env. ${bename}; ${ret}" 1 && exit 1 ;;
  esac
fi


# Iterate ${stigs[@]}
for stig in ${stigs[@]}; do

  if [ ! -f ${stig} ]; then
  
    # Let the user know what is happening
    print "'$(basename ${stig})' is not a valid VMS ID or has not yet been implemented" 1
    continue
  fi

  # Let the user know what is happening
  [ ${verbose} -eq 1 ] && print "Executing '$(basename ${stig}) ${flags}'"

  # Do work
  ./${stig} ${flags}

  [ ${verbose} -eq 1 ] && echo
done

exit 0
