#!/bin/bash


# Define a minimum days range for locked accounts
min_days=35

# UID minimum as exclusionary for system/service accounts
uid_min=100

# UID exceptions (any UID within ${uid_min}...2147483647 to exclude)
# Service/System account UID's
declare -a uid_excp
uid_excp+=(60001) # nobody
uid_excp+=(60002) # nobody4
uid_excp+=(65534) # noaccess


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


# If ${#uid_excl[@]} > 0 create a pattern
pattern="$(echo "${uid_excp[@]}" | tr ' ' '|')"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Created exclude pattern (${pattern})"


# Get current list of users (greater than ${uid_min} & excluding ${uid_excl[@]})
user_list=($(nawk -F: -v min="${uid_min}" -v pat="/${pattern}/" '$3 >= min && $3 !~ pat{print $1}' /etc/passwd 2>/dev/null))


# If ${#user_list[@]} = 0 exit
if [ ${#user_list[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#user_list[@]}' users found meeting criteria for examination; exiting" 1

  exit 1
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained list of users to examine (Total: ${#user_list[@]})"


# Iterate ${user_list[@]}
for act in ${user_list[@]}; do

  # Get array of login history (ignores system accounts, removes dupes & ignores all but last login per user)
  logins=($(last ${act} &>/dev/null | grep -v ^wtmp | nawk -v pat="/${pattern}/" '$1 != "" && $1 !~ pat{print $1":"$5":"$6}' 2>/dev/null | sort -urk2 | sort -k3))
done


# If ${#logins[@]} = 0 exit
if [ ${#logins[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#logins[@]}' logins found, exiting" 1
  exit 1
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "Obtained list of login activity"


# Get the current day of year (Current Julian Day Of Year)
cjdoy=$(conv_date_to_jdoy $(date +%d) $(date +%m) $(date +%Y))


# Iterate ${logins[@]}
for lgn in ${logins[@]}; do

  # Set ${user} from ${lgn}
  user="$(echo "${lgn}" | cut -d: -f1)"

  # Convert ${month} to integer from ${lgn}
  month="$(month_to_int $(echo "${lgn}" | cut -d: -f1))"

  # Set ${day} from ${lgn}
  day="$(echo "${lgn}" | cut -d: -f3)"

  # Set ${year} to current year
  year="$(date +%Y)"

  # Get the Julian Date from ${day}, ${month}, ${year}
  ucjdoy=$(conv_date_to_jdoy ${day} ${month} ${year})


  # If ${change} = 1
  if [ ${change} -eq 1]; then

    # Determine if ${user} exceeds criteria specified with ${min_days}
    if [ $(compare_jdoy_dates ${cjdoy} ${ucjdoy}) -ge ${min_days} ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Locking account for '${user}', exceeds '${min_days}'"

      # Lock account for ${user}
      passwd -l ${user} &> /dev/null

      # IF an error occurred locking ${user} handle it
      if [ $? -ne 0 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "An error occurred locking account for '${user}'" 1
      fi
    fi
  fi


  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Validating '${user}' last login compared to '${min_days}'"

  # Determine if ${user} exceeds criteria specified with ${min_days}
  if [ $(compare_jdoy_dates ${cjdoy} ${ucjdoy}) -ge ${min_days} ]; then

    # Declare an array to handle accounts
    errlgn=()

    # Get current status of ${user}
    if [ "$(awk -F: '$2 !~ /LK/{print 1}' /etc/shadow)" != "" ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Last login for '${user}' exceeds '${min_days}' and is NOT locked" 1
      errlgn+=("${user}")
    else

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Last login for '${user}' exceeds '${min_days}' and is locked" 1
      errlgn+=("${user}")
    fi
  fi
done


# Check to see if ${#errlgn[@]} > 0
if [ ${#errlgn[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Error, host does not conform to '${stigid}'" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00918
# STIG_Version: SV-39824r1
# Rule_ID: GEN000760
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00918
# STIG_Version: SV-39824r1
# Rule_ID: GEN000760
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: Accounts must be locked upon 35 days of inactivity.
# Description: Accounts must be locked upon 35 days of inactivity.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00918
# STIG_Version: SV-39824r1
# Rule_ID: GEN000760
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: Accounts must be locked upon 35 days of inactivity.
# Description: Accounts must be locked upon 35 days of inactivity.

