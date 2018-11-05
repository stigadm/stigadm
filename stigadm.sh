#!/bin/bash


# stigadm - A minimalist approach to STIG validation/remediation
# Project: https://github.com/stigadm/stigadm
# Copyright(c) 2015-2018 Jason Gerfen <jason.gerfen@gmail.com>
# License: MIT


###############################################
# Environment setup
###############################################

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


# Error if the ${inc_path} doesn't exist
if [ ! -d ${lib_path} ] ; then
  echo "Defined library path doesn't exist (${lib_path})" && exit 1
fi


# Include all .sh files found in ${lib_path}
incs=( $(find ${lib_path} -type f -name "*.sh") )

# Exit if nothing is found
if [ ${#incs[@]} -eq 0 ]; then
  echo "'${#incs[@]}' libraries found in '${lib_path}'" && exit 1
fi


# Iterate ${incs[@]}
for src in ${incs[@]}; do

  # Make sure ${src} exists & is executable
  if [[ ! -f ${src} ]] && [[ ! -x ${src} ]]; then
    continue
  fi

  # Include $[src} making any defined functions available
  source ${src}
done


###############################################
# Global variable definitions
###############################################

# Global defaults for tool
author=
bootenv=0
change=0
count=0
classification=
ext="json"
flags=
interactive=0
os=
restore=0
version=
verbose=0
list=

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

# Pick up the environment
read -r os version arch <<< $(set_env)

# Whos is calling? 0 = singular, 1 is as group
caller=$(ps $PPID | grep -c stigadm)

# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


###############################################
# Usage menu function
###############################################

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
    -C  Classification
      Supported: [CAT-I|CAT-II|CAT-III]

    -L  VMS ID List - A comma separated list VMS ID's
      Example: V0047799,V0048211,V0048189

  Options:
    -a  Author name (required when using -c)
    -b  Use new boot environment (Solaris only)
    -c  Make the change
    -v  Enable verbose messages

  Restoration:
    -r  Perform rollback of changes

  Reporting:
    -l  Default: /var/log/stigadm/<HOST>-<OS>-<VER>-<ARCH>-<DATE>.json
    -j  JSON reporting structure (default)
    -x  XML reporting structure

EOF
}


###############################################
# Root priv & options processing
###############################################

# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  report "Requires root privileges" && exit 1
fi


# Set variables
while getopts "a:bchijl:rC:O:L:V:vx" OPTION ; do
  case $OPTION in
    a) author=$OPTARG ;;
    b) bootenv=1 ;;
    c) change=1 ;;
    h) report && exit 1 ;;
    i) interactive=1 ;;
    j) ext="json" ;;
    l) log=$OPTARG ;;
    r) restore=1 ;;
    C) classification=$OPTARG ;;
    L) list=$OPTARG ;;
    O) os=$OPTARG ;;
    V) version=$OPTARG ;;
    v) verbose=1 ;;
    x) ext="xml" ;;
    ?) report && exit 1 ;;
  esac
done


###############################################
# Setup the necessary templates for logging
###############################################

# Set the default log if nothing provided
#  /var/log/stigadm/<HOSTNAME>-<OS>-<VER>-<ARCH>-<DATE>.json|xml
log="${log:=/var/log/${appname}/$(hostname)-${os}-${version}-${arch}-${timestamp}.${ext:=json}}"

# If ${log} doesn't exist make it
if [ ! -f ${log} ]; then
  mkdir -m 700 -p $(dirname ${log})
  touch ${log}
  chmod 400 ${log}
fi

# Re-define the ${templates} based on ${ext}
templates="${templates}/${ext}"

# Bail if ${templates} is not a folder
if [ ! -d ${templates} ]; then
  report "Could not find a templates directory for report generation" && exit 1
fi

# Make sure there are template files available in ${templates}
if [ $(ls ${templates} | wc -l) -lt 4 ]; then
  report "Could not find the necessary reporting templates" && exit 1
fi

# Make sure our report exists
if [[ ! -f ${templates}/report-header.${ext} ]] || [[ ! -f ${templates}/report-footer.${ext} ]]; then
  report "The stigadm template is missing" && exit 1
fi

# Make sure our report exists
if [[ ! -f ${templates}/stig-header.${ext} ]] || [[ ! -f ${templates}/stig-footer.${ext} ]]; then
  report "The STIG module template is missing" && exit 1
fi

# Define variable for module report
module_header="${templates}/stig-header.${ext}"
module_footer="${templates}/stig-footer.${ext}"

# Define variable for stigadm report
report_header="${templates}/report-header.${ext}"
report_footer="${templates}/report-footer.${ext}"


###############################################
# OS & Version is detected or defined
###############################################

# Make sure we have the necessary OS & Version
if [[ "${os}" == "" ]] && [[ "${version}" == "" ]]; then

  # Setup a temporary array for env vars
  declare -a t_env

  # If nothing supplied try to get it ourselves
  t_env=( $(set_env) )

  if [ ${#t_env[@]} -ne 2 ]; then

    # Alert to requirements
    report "Must provide OS & Version" && exit 1
  fi

  # Break up ${t_env[@]} into elements
  os="${t_env[0]}"
  version="${t_env[1]}"
fi


###############################################
# Make sure we have an author if remediating
###############################################

# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  report "Must specify an author name (use -a <initials>)" && exit 1
fi


###############################################
# Bootstrap the module flags
###############################################

# Enable change w/ author argument
if [ ${change} -eq 1 ]; then
  flags="${flags} -c"
  [ "${author}" != "" ] && flags="${flags} -a ${author}"
fi

# Enable restoration mode
[ ${restore} -eq 1 ] && flags="${flags} -r"


# Enable verbosity option
[ ${verbose} -eq 1 ] && flags="${flags} -v"


# Use XML templates if requested
[ "${ext}" == "xml" ] && flags="${flags} -x"


# Tell each module which ${log} to append
flags="${flags} -l ${log}"

# Set a default value for classification if null
classificiation="${classification:=ALL}"


###############################################
# Seek out modules list for OS & Version
###############################################

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

  # Notify and provide report menu
  report "'${#stigs[@]}' STIG modules found; aborting" && exit 1
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


###############################################
# Solaris only alternate boot environment
###############################################

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
    1) report "Could not create boot environment; ${bename}" && exit 1 ;;
    2) report "Could not activate boot environment; ${bename}" && exit 1 ;;
    3) report "Could not validate boot environment; ${bename}" && exit 1 ;;
    0) break ;; # Mount bename, copy stigadm toolkit & chroot to env FIX!!
    ?) report "Unknown error occurred with boot env. ${bename}; ${ret}" && exit 1 ;;
  esac
fi


###############################################
# Start work by generating report header
###############################################

# Generate the primary report header
report_header


###############################################
# Begin iteration of target stigs
###############################################

# Define a counter
counter=${#stigs[@]}

# Iterate ${stigs[@]}
for stig in ${stigs[@]}; do

  # Decrement ${counter}
  counter=$(subtract 1 ${counter})

  # Get a nicer name for the ${stig} file
  stig_name="$(basename ${stig} | cut -d. -f1)"

  # Capture results from ${stig} ${flags} execution
  /bin/bash ./${stig} ${flags}

  # Capture any errors
  [ $? -ne 0 ] && errors+=("${stig_name}")

  # If necessary, append "," to ${log} for each iteration
  [[ ${counter} -ne 0 ]] && [[ "${ext}" != "xml" ]] && echo "    ," >> ${log}
done


###############################################
# Calculate some statistics
###############################################

# Provide passed vs. failed
passed=$(subtract ${#errors[@]} ${#stigs[@]})
failed=${#errors[@]}

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${#stigs[@]} ${#errors[@]})


###############################################
# Get some metrics of overall time spent
###############################################

# Get EPOCH
e_epoch="$(gen_epoch)"

seconds=$(subtract ${s_epoch} ${e_epoch})

# Generate a run time
[ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."


###############################################
# Generate the report footer
###############################################

report_footer

# Print ${log}
cat ${log}


###############################################
# Exit with the number of errors found
###############################################

# Exit with the number of errors
exit ${#errors[@]}
