#!/bin/bash


# Define an array of allowed networks
declare -a allowed

# Allow loop back service binds
allowed+=('127.0.0.1')


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


# Check dtrace -l output to see if we can examine ${pid}
examine=1
if [ $(dtrace -l | wc -l) -le 1 ]; then

  [ ${verbose} -eq 1 ] && print "Info: Cannot inspect PID(s) for crypto function calls"
  [ ${verbose} -eq 1 ] && print "  Reference: dtrace zone privileges: 'limitpriv dtrace_proc,dtrace_user'"

  # Set ${examine} = 0 to disable attempts to inspect PID(s) for encryption function calls
  examine=0
fi


# Get the PID per network process
net_procs=( $(netstat -anu | awk '$4 ~ /^[0-9]+$/{print $4}' | sort -u) )

# If ${#net_procs[@]} = 0
if [ ${#net_procs[@]} -eq 0 ]; then

  [ ${verbose} -eq 1 ] && print "'${#net_procs[@]}' network processes found, system conforms to '${stigid}'"
  exit 0
fi


# Iterate ${net_proces[@]}
for proc in ${net_procs[@]}; do

  # Obtain process name for ${proc} & push into ${procs[@]}
  procs+=( $(ps -o pid,comm -p ${proc} | awk '$0 !~ /PID/{print $1":"$2}') )
done

# If ${#procs[@]} = 0
if [ ${#procs[@]} -eq 0 ]; then

  [ ${verbose} -eq 1 ] && print "'${#procs[@]}' network processes binaries found, system conforms to '${stigid}'"
  exit 0
fi


# Sort & remove duplicate binary names



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


# Define an associative array of successful items
declare -A passed

# Define an associative array of failed items
declare -A failed

x=0

# Iterate ${procs[@]}
for cpid in ${procs[@]}; do

  # Split ${cpid} into PID
  pid=$(echo "${cpid}" | cut -d: -f1)

  # Split ${cpid} into command/binary
  binary=$(echo "${cpid}" | cut -d: -f2)

  # If ${binary} not a file
  if [ ! -f ${binary} ]; then

    # Attempt to search file system for $(basename ${binary})
    binary="$(find / -maxdepth 15 -type f -name $(basename ${binary}) 2>/dev/null)"

    # If empty skip
    if [ -z "${binary}" ]; then

      # Create an entry for ${binary} in ${failed['Missing']}
      if [ -z ${failed['Missing']} ]; then
        failed['Missing']="${binary}"
      else
        failed['Missing']="${failed['Missing']}:${binary}"
      fi

      continue
    fi

    # Update ${binary} @ ${procs[${x}]}
    procs[${x}]="${pid}:${binary}"

  fi


  # Increment ${x}
  x=$(( ${x} + 1 ))


  # Get a list of linked shared objects to limit syscall examination
  linked=($(pldd ${pid} | grep -i crypt))

  # If ${#linked[@]} = 0
  if [ ${#linked[@]} -eq 0 ]; then

    # Create an entry for ${binary} in ${failed['Libraries']}
    if [ -z ${failed['Libraries']} ]; then
      failed['Libraries']="${binary}"
    else
      failed['Libraries']="${failed['Libraries']}:${binary}"
    fi

    continue
  fi

  # Create an entry for ${binary} in ${passed['Libraries']}
  if [ -z ${passed['Libraries']} ]; then
    passed['Libraries']="${binary}"
  else
    passed['Libraries']="${passed['Libraries']}:${binary}"
  fi


  # If ${examine} = 1 then use dtrace to examine function calls for ${pid}
  if [ ${examine} -eq 1 ]; then

    # Get any functions calls from ${pid} that match 'crypt'
    calls=( $(dtrace -qln 'pid$target:::entry' -p ${pid} | grep -i crypt | gawk '{print $4}') )

    # If ${#calls[@]} = 0
    if [ ${#calls[@]} -eq 0 ]; then

      # Create an entry for ${binary} in ${failed['Functions']}
      if [ -z ${failed['Functions']} ]; then
        failed['Functions']="${binary}"
      else
        failed['Functions']="${failed['Functions']}:${binary}"
      fi

      continue
    fi

    # Create an entry for ${binary} in ${passed['Functions']}
    if [ -z ${passed['Functions']} ]; then
      passed['Functions']="${binary}"
    else
      passed['Functions']="${passed['Functions']}:${binary}"
    fi
  fi
done


# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained & examined '${#procs[@]}' network service(s)"

if [ ${#failed[@]} -eq 0 ]; then

  # Iterate ${procs[@]}
  for p in ${procs[@]}; do

    # Split ${p} into an id
    ipid="$(echo "${p}" | cut -d: -f1)"

    # Split ${p} into an binary
    ibin="$(echo "${p}" | cut -d: -f2)"

    [ ${verbose} -eq 1 ] && print "  [${ipid}] ${ibin}"
  done
fi


# If ${#passed[@]} > 0
if [ ${#passed[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Validated cryptographic communications"

  # Iterate ${passed[@]}
  for pass in ${!passed[@]}; do

    # Split ${fail} into an array
    passess=($(echo "${passed[${pass}]}" | tr ':' ' '))

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  '${pass}' (${#passess[@]}/${#procs[@]}) Items:"

    # Iterate ${pass[@]}
    for pss in ${passess[@]}; do

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "    ${pss}"
    done | sort -u
  done
fi


# If ${#failed[@]} > 0
if [ ${#failed[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Unable to validate cryptographic communications" 1

  # Iterate ${failed[@]}
  for fail in ${!failed[@]}; do

    # Split ${fail} into an array
    fails=($(echo "${failed[${fail}]}" | tr ':' ' '))

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  '${fail}' (${#fails[@]}/${#procs[@]}):" 1

    # Iterate ${fails[@]}
    for fl in ${fails[@]}; do

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "    ${fl}" 1
    done | sort -u
  done

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048179
# STIG_Version: SV-61051r1
# Rule_ID: SOL-11.1-060070
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must protect the integrity of transmitted information.
# Description: Ensuring the integrity of transmitted information requires the operating system take feasible measures to employ transmission layer security. This requirement applies to communications across internal and external networks.
