#!/bin/bash

# Bootstrapper

# Global defaults for tool
author=
arch=
change=0
debug=1
ext="json"
hostname="$(hostname)"
os=
restore=0
timestamp=
verbose=0
ver=


# Working directory
cwd="$(dirname $0)"

# Tool name
prog="$(basename $0)"


# Copy ${prog} to DISA STIG ID this tool handles
stigid="$(echo "${prog}" | cut -d. -f1)"

# If ${appname} doesn't exist define it
appname="${appname:=stigadm}"


# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


# Define the library include path
lib_path=${cwd}/../../../libs

# Define the tools include path
tools_path=${cwd}/../../../stigs

# Define the library template path(s)
templates=${cwd}/../../../templates

# Define the system backup path
backup_path=${cwd}/../../../backups/$(uname -n | awk '{print tolower($0)}')


# Error if the ${inc_path} doesn't exist
if [ ! -d "${lib_path}" ] ; then
  echo "Defined library path doesn't exist (${lib_path})" && exit 1
fi


# Include all .sh files found in ${lib_path}
incs=("$(ls ${lib_path}/*.sh)")

# Exit if nothing is found
if [ ${#incs[@]} -eq 0 ]; then
  echo "${#incs[@]} libraries found in '${lib_path}'" && exit 1
fi


# Iterate ${incs[@]}
for src in ${incs[@]}; do

  # Make sure ${src} exists & is executable
  if [[ ! -f "${src}" ]] && [[ ! -x "${src}" ]]; then
    continue
  fi

  # Include $[src} making any defined functions available
  source "${src}"
done


# Ensure we have permissions
if [ $UID -ne 0 ] ; then
  usage "Requires root privileges" && exit 1
fi


# Set variables
while getopts "ha:cdjl:rvx" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
    d) debug=1 ;;
    j) ext="json" ;;
    l) log=$OPTARG ;;
    r) restore=1 ;;
    v) verbose=1 ;;
    x) ext="xml" ;;
    ?) report "Argument parsing error" && exit 1 ;;
  esac
done


# Enable debugging
#[ ${debug} -eq 1 ] && set -x || set +x


# Create a timestamp
timestamp="$(gen_date)"


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  report "Must specify an author name (use -a <initials>)" && exit 1
fi


# Acquire array of meta data
declare -a meta
meta=( $(get_meta_data "${cwd}" "${prog}") )

# Bail if ${#meta[@]} >= 0
if [ ${#meta[@]} -lt 11 ]; then
  report "Unable to acquire meta data for ${stigid}" && exit 1
fi


# Pick up the environment
read -r os version arch <<< $(set_env)

# Set the default log if nothing provided
#  /var/log/stigadm/<HOSTNAME>-<OS>-<VER>-<ARCH>-<DATE>.json|xml
log="${log:=/var/log/${appname}/${hostname}-${os}-${version}-${arch}-${timestamp}.${ext:=json}}"

# If ${log} doesn't exist make it
if [ ! -f ${log} ]; then
  mkdir -m 700 -p $(dirname ${log})
  touch ${log}
  chmod 400 ${log}
fi


# Re-define the ${templates} based on ${ext}
templates="${templates}/${ext}"

# Bail if ${templates} is not a folder
if [ ! -d "${templates}" ]; then
  report "Could not find a templates directory for report generation" && exit 1
fi

# Make sure there are template files available in ${templates}
if [ $(ls "${templates}" | wc -l) -lt 4 ]; then
  report "Could not find the necessary reporting templates" && exit 1
fi

# Make sure our report exists
if [[ ! -f "${templates}/report-header.${ext}" ]] || [[ ! -f "${templates}/report-footer.${ext}" ]]; then
  report "The stigadm template is missing" && exit 1
fi

# Make sure our report exists
if [[ ! -f "${templates}/stig-header.${ext}" ]] || [[ ! -f "${templates}/stig-footer.${ext}" ]]; then
  report "The STIG module template is missing" && exit 1
fi

# Define variable for module report
module_header="${templates}/stig-header.${ext}"
module_footer="${templates}/stig-footer.${ext}"

# Define variable for stigadm report
report_header="${templates}/report-header.${ext}"
report_footer="${templates}/report-footer.${ext}"
