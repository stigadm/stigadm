#!/bin/bash -x


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


# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"


# Set ${cond} to false
cond=0

# Get boolean of current status
cond=$(auditconfig -getcond | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')


# If ${restore} = 1 go to restoration mode
if [[ ${restore} -eq 1 ]] && [[ ${cond} -eq 1 ]]; then

  # Do work
  audit -t
  [ $? -ne 0 ] && exit 1

  exit 0
fi


# If ${change} == 1 & ${cond} = 0
if [[ ${change} -eq 1 ]] && [[ ${cond} -eq 0 ]]; then

  # Do work
  audit -s
  if [ $? -ne 0 ]; then
    [ $? -ne 0 ] && exit 1
  fi

  # Get boolean of current status
  cond=$(auditconfig -getcond | nawk '$1 ~ /^audit/ && $4 ~ /^auditing/{print 1}')
fi


# Get EPOCH
e_epoch="$(gen_epoch)"

seconds=$(subtract ${s_epoch} ${e_epoch})

# Generate a run time
[ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."


# If ${cond} != 1
if [ ${cond:=0} -ne 1 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Auditing is not enabled" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047781
# STIG_Version: SOL-11.1-010040
# Rule_ID: SV-60657r1
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The audit system must produce records containing sufficient information to establish the identity of any user/subject associated with the event.
# Description: Enabling the audit system will produce records with accurate time stamps, source, user, and activity information. Without this information malicious activity cannot be accurately tracked.
