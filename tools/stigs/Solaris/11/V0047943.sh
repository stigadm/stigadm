#!/bin/bash

# OS: Solaris
# Version: 11
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-47943
# Name: SV-60815r1


# Define a minimum days range for locked accounts
min_days=56

# Define the configuration file for handling the default maxweeks value
file=/etc/default/passwd

# Define the maxweeks before a password is to be changed
maxweeks=8

# Define a default of current MAXWEEKS value (in case it is not defined)
mweeks=10

# UID minimum as exclusionary for system/service accounts
uid_min=1000

# An array of exceptions
declare -a exceptions
exceptions+=('nobody')
exceptions+=('nobody4')
exceptions+=('noaccess')
exceptions+=('ldap-bind')
exceptions+=('oracle')
exceptions+=('ctm')
exceptions+=('sdb')
exceptions+=('aabadm')
exceptions+=('lcbadm')
exceptions+=('CMacct1')
exceptions+=('CMacct2')


# Global defaults for tool
author=
verbose=0
change=0
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
while getopts "ha:cvri" OPTION ; do
  case $OPTION in
    h) usage && exit 1 ;;
    a) author=$OPTARG ;;
    c) change=1 ;;
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


# Handle symlinks
file="$(get_inode ${file})"

# Exit if ${file} isn't a file
if [ ! -f ${file} ]; then
  usage "The file; '${file}' configured is not a real file" && exit 1
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

  # Create a backup of the passwd database
  bu_passwd_db "${author}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Backup of passwd database failed, exiting..." 1

    # Stop, we require a backup of the passwd database for changes
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of passwd database file(s)"


  # Create a backup of ${file}
  bu_file "${author}" "${file}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${file}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${file}'"
fi


# Get current 'MAXWEEKS' configuration
mweeks=$(grep -i ^MAXWEEKS ${file} | cut -d= -f2)

# Exit if value isn't set as an error
if [ "${mweeks}" == "" ]; then

  err=1
else
  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Obtained current MAXWEEKS value from '${file}' (${mweeks})"
fi



# If ${mweeks} > ${maxweeks}
if [ ${mweeks:=0} -gt ${maxweeks} ]; then

  # If ${change} set
  if [ ${change} -eq 1 ]; then

    # Get the last backup file
    tfile="$(bu_file_last "$(dirname ${file})" "${author}")"
    if [ ! -f ${tfile} ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "An error occurred getting temporary file for changes"
      exit 1
    fi

    # Make change for ${maxweeks} from ${tfile} into ${file}
    sed -e "s/^MAXWEEKS=.*/MAXWEEKS=${maxweeks}/g" ${tfile} > ${file}

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Made changes to '${file}' reflecting 'MAXWEEKS=${maxweeks}'"
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Obtained current MAXWEEKS value from '${file}' (${mweeks})"

  # Get current 'MAXWEEKS' configuration
  tmweeks=$(grep -i ^MAXWEEKS ${file} | cut -d= -f2)

  # If ${tmweeks} > ${maxweeks}
  if [ ${tmweeks} -gt ${maxweeks} ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "'${file}' does not reflect 'MAXWEEKS=${maxweeks}'; does not conform to '${stigid}'" 1
  fi
fi


# If ${#uid_excl[@]} > 0 create a pattern
pattern="$(echo "${exceptions[@]}" | tr ' ' '|')"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Created exclude pattern ($(truncate_cols "${pattern}" 20))"


# Get current list of users (greater than ${uid_min} & excluding ${uid_excl[@]})
user_list=($(nawk -F: -v min="${uid_min}" -v pat="${pattern}" '$3 >= min && $1 !~ pat{print $1}' /etc/passwd 2>/dev/null))


# If ${#user_list[@]} = 0 exit
if [ ${#user_list[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#user_list[@]}' users found meeting criteria for examination" 1

else
  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Obtained list of users to examine (Total: ${#user_list[@]})"
fi


# Apply a filter of users to limit results to
filter="$(echo "${user_list[@]}" | tr ' ' '|')"

# Print friendly message
[ ${verbose} -eq 1 ] && print "Created include filter ($(truncate_cols "${filter}" 20))"

# Get a filtered array of logins (ignores system accounts, removes dupes & locked/system accounts)
accounts=($(logins -ox | nawk -F: -v min="${min_days}" -v pat="${filter}" '$1 ~ pat && $8 ~ /^PS|UP|LK$/ && ($11 > min || $11 == -1){print $1}' 2>/dev/null))


# If ${#accounts[@]} = 0 exit
if [ ${#accounts[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#accounts[@]}' accounts found, system conforms to '${stigid}'"
else

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Obtained filtered list of accounts '${#accounts[@]}'"
fi


declare -a errlgn
declare -a success

# Iterate ${accounts[@]}
for lgn in ${accounts[@]}; do

  # If ${change} = 1
  if [ ${change} -eq 1 ]; then

    # Lock account for ${lgn}
    passwd -x ${min_days} ${lgn} &> /dev/null

    # IF an error occurred locking ${lgn} handle it
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Couldn't set '${min_days}' for '${lgn}'" 1
    fi
  fi

  # Get current status of ${lgn}
  status=$(logins -oxl ${lgn} | nawk -F: -v min="${min_days}" '$8 !~ /^NP|LK|NL/ && $8 ~ /^PS|UP$/ && ($11 > min || $11 == -1){print $1}')

  # If ${status} isn't empty then the user doesn't conform to ${stigid}
  if [ "${status}" != "" ]; then

    errlgn+=("${lgn}")
  else

    # Push ${lgn} to ${success[@]}
    success+=("${lgn}")
  fi
done


# Check to see if ${#success[@]} > 0
if [ ${#success[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "The following accounts conform to '${stigid}'"

  # Iterate ${success[@]}
  for succ in ${success[@]}; do

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  ${succ}"
  done
fi


# Check to see if ${#errlgn[@]} > 0
if [ ${#errlgn[@]} -gt 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Host does not conform to '${stigid}'" 1

  # Iterate ${errlgn[@]}
  for nme in ${errlgn[@]}; do

    # Print friendly success
    [ ${verbose} -eq 1 ] && print "  ${nme}" 1
  done
fi

# If ${err} is set then exit & show error
if [ ${err:=0} -eq 1 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "Host does not conform to '${stigid}'" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0
