#!/bin/bash


# Boolean true/false to set properties per configured zone
config_per_zone="true"


# Set some default actions
priv_level="priv"
log_level="warning"
action="deny"


# Define a log level for rctladm
log_level="syslog"


# An associative array of project attributes for application user accounts
declare -A application_accounts
application_accounts["process.max-file-descriptor"]=16000
application_accounts["process.max-stack-size"]="70%"
application_accounts["process.max-address-space"]="60%"
application_accounts["project.max-locked-memory"]="65%"
application_accounts["project.cpu-shares"]="80%"
application_accounts["project.max-shm-ids"]=64000
application_accounts["project.max-shm-memory"]="75%"
application_accounts["project.max-tasks"]=32000
application_accounts["project.max-lwps"]=32000
application_accounts["task.max-processes"]=16000


# An associative array of project attributes for end user accounts
declare -A user_accounts
user_accounts["process.max-file-descriptor"]=16000
user_accounts["process.max-stack-size"]="50%"
user_accounts["process.max-address-space"]="50%"
user_accounts["project.cpu-shares"]="60%"
user_accounts["project.max-locked-memory"]="40%"
user_accounts["project.max-shm-ids"]=16000
user_accounts["project.max-shm-memory"]="60%"
user_accounts["project.max-tasks"]=16000
user_accounts["project.max-lwps"]=16000
user_accounts["task.max-processes"]=16000


# An associative array of zone specific project limits
declare -A zone_limits
zone_limits["zone.cpu-shares"]="75%"
zone_limits["zone.max-lofi"]=8
zone_limits["zone.max-lwps"]=32000
zone_limits["zone.max-processes"]=64000
zone_limits["zone.max-shm-ids"]=64000
zone_limits["zone.max-shm-memory"]="75%"
zone_limits["zone.max-swap"]="70%"


# Define an associative array of virtual nic properties
declare -A network_properties
network_properties["zone"]="true" # Limit VNIC to zone where zone is configured to use vnic
network_properties["protection"]="mac-nospoof,restricted,ip-nospoof,dhcp-nospoof" # See `man dladm` for info
network_properties["allowed-ips"]="true" # Limits allowed outbound SRC datagrams on list ONLY (Acquires from configured IP's)
network_properties["maxbw"]="75%" # Use ${network_whitelist[@]} array to exclude VNIC's, otherwise limit bandwidth


# Define an whitelist of accounts to ignore
declare -a whitelist
whitelist+=("root")


# Define a whitelist of VNIC's to exclude from ${network_properties[@]}
declare -a network_whitelist
network_whitelist+=("vnic1")


# Define the project file
file=/etc/project


# Define the location of the nsswitch.conf
nsswitch=/etc/nsswitch.conf


# Global defaults for tool
author=
verbose=0
change=0
meta=0
restore=0
interactive=0

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
while getopts "ha:cmvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    m) meta=1 ;;
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
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


# Get total number of CPU's
# Get total amount of physical memory
# Get number of configured zones

# Calculate percentages for the following:
#  - CPU / [Memory | Zone] / X (Where X is the project|network limit)


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  #bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${pkgs[@]}" | tr ' ' '\n')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of broken packages failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of broken packages"
fi


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Does not conform to '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    key="$(echo "${error}" | cut -d: -f1,2)"
    inode="$(echo "${error}" | cut -d: -f3)"
    flag="$(echo "${error}" |  cut -d: -f4)"
    cvalue="$(echo "${error}" | cut -d: -f5)"
    value="$(echo "${error}" | cut -d: -f6)"

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  Package: ${key}" 1
    [ ${verbose} -eq 1 ] && print "    Inode: ${inode}" 1
    [ ${verbose} -eq 1 ] && print "      Type: ${type} ${cvalue} [${value}]" 1
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
