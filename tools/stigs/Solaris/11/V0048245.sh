#!/bin/bash


# Definition for the file to validate/make changes to
file=/etc/default/login

# Array of options
declare -a opts
opts+=("RETRIES=3")


# Definition for the policy file
policy=/etc/security/policy.conf

# Array of options
declare -a popts
popts+=("LOCK_AFTER_RETRIES=yes")


# User attr file
uattr=/etc/user_attr

# Define a min & max uid range
min_uid=10000
max_uid=

# Define an array of excluded accounts
declare -a exclude
exclude+=("root")
exclude+=("startup")


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
    v) verbose=1 ;;
    r) restore=1 ;;
    i) interactive=1 ;;
    x) xml=1 ;;
    ?) usage && exit 1 ;;
  esac
done


# Remove once work is complete on module
cat <<EOF
[${stigid}] Warning: Not yet implemented...

$(get_meta_data "${cwd}" "${prog}")
EOF
exit 1


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


print "Not yet implemented" && exit 0

# Handle symlinks
file="$(get_inode ${file})"

# Ensure ${file} exists @ specified location
if [ ! -f ${file} ]; then
  usage "'${file}' does not exist at specified location" && exit 1
fi


# Ensure ${policy} exists @ specified location
if [ ! -f ${policy} ]; then
  usage "'${policy}' does not exist at specified location" && exit 1
fi


# Ensure ${user_attr} exists @ specified location
if [ ! -f ${user_attr} ]; then
  usage "'${user_attr}' does not exist at specified location" && exit 1
fi


# If ${#opts[@]} <= 0 then exit
if [ ${#opts[@]} -eq 0 ]; then
  usage "No options defined for '${file}'" && exit 1
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


# Build a pattern from ${excludep[@]}
pattern=
[ ${#exclude[@]} -gt 0 ] && pattern="$(echo "${exclude[@]}" | tr ' ' '|')"

# Get list of users on system
users=($(nawk -F: -v pat="${pattern}" '$1 !~ pat{print $1}' /etc/passwd))

# If ${#users[@]} = 0
if [ ${#users[@]} -eq 0 ]; then

  # Print friendly message regarding restoration mode
  [ ${verbose} -eq 1 ] && print "Found '${#users[@]}' on system" 1
fi


# If ${change} > 0
if [ ${change} -eq 1 ]; then

  # Create a backup of ${file}
  bu_file "${author}" "${file}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${file}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${file}'"


  # Create a backup of ${policy}
  bu_file "${author}" "${policy}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${policy}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${policy}'"


  # Create a backup of ${uattr}
  bu_file "${author}" "${uattr}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not create a backup of '${uattr}', exiting..." 1
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created backup of '${uattr}'"


  # Iterate ${users[@]}
  for user in ${users[@]}; do

    # Set the lock after retries attribute
    usermod -K lock_after_retries=yes ${user} 2> /dev/null

    # Handle the error
    if [ $? -ne 0 ]; then

      # Print friendly message regarding restoration mode
      [ ${verbose} -eq 1 ] && print "An error occurred setting 'lock_after_retries' attribute on the '${user}' account" 1
    else

      # Print friendly message regarding restoration mode
      [ ${verbose} -eq 1 ] && print "Set 'lock_after_retries' attribute on the '${user}' account"
    fi
  done


  # Get the backup file name
  tfile="$(gen_tmpfile "${file}" "root:root" 00600 1)"

  # Iterate ${opts[@]} & do work
  for opt in ${opts[@]}; do


    # Print friendly message regarding change
    [ ${verbose} -eq 1 ] && print "Applying changes for '${stigid}'"

    # Split ${opt} into a ${key} & ${value} pair
    key="$(echo "${opt}" | cut -d= -f1)"
    value="$(echo "${opt}" | cut -d= -f2)"


    # Check to see if ${key} exists
    if [ $(grep "^${key}.*" ${file}) != "" ]; then

      # Make changes from ${file} into ${tfile}
      sed -e "s|^${key}.*|${opt}|g" ${file} > ${tfile}
      mv ${tfile} ${file}
    else
      echo "${opt}" >> ${file}
    fi

    # Print friendly message regarding temporary file permissions
    [ ${verbose} -eq 1 ] && print "Set '${opt}' in '${tfile}'"

    # Move ${tfile} into ${file}
    mv ${tfile} ${file}

    # Print friendly message regarding restoration of ${file} from ${tfile}
    [ ${verbose} -eq 1 ] && print "Moved '${tfile}' to '${file}'"


    # Print friendly message regarding validation
    [ ${verbose} -eq 1 ] && print "Validating '${key}' according to STIG ID '${stigid}'"

    # Get ${settings} from ${file}
    haystack="$(grep "^${opt}" ${file})"

    # If ${haystack} is empty error & exit
    if [ "${haystack}" == "" ]; then

      if [ ${verbose} -eq 1 ]; then
        print "Failed validation for '${stigid}'" 1
        print "  '${opt}' is missing or invalid" 1
      fi

      exit 1
    fi
  done


  # Get the backup file name
  pfile="$(gen_tmpfile "${pfile}" "root:root" 00600 1)"

  # Iterate ${popts[@]} & do work
  for opt in ${popts[@]}; do


    # Print friendly message regarding change
    [ ${verbose} -eq 1 ] && print "Applying changes for '${stigid}'"

    # Split ${opt} into a ${key} & ${value} pair
    key="$(echo "${opt}" | cut -d= -f1)"
    value="$(echo "${opt}" | cut -d= -f2)"


    # Check to see if ${key} exists
    if [ $(grep "^${key}.*" ${pfile}) != "" ]; then

      # Make changes from ${pfile} into ${pfile}
      sed -e "s|^${key}.*|${opt}|g" ${pfile} > ${pfile}
      mv ${pfile} ${pfile}
    else
      echo "${opt}" >> ${pfile}
    fi

    # Print friendly message regarding temporary file permissions
    [ ${verbose} -eq 1 ] && print "Set '${opt}' in '${pfile}'"

    # Move ${pfile} into ${pfile}
    mv ${pfile} ${pfile}

    # Print friendly message regarding restoration of ${pfile} from ${pfile}
    [ ${verbose} -eq 1 ] && print "Moved '${pfile}' to '${pfile}'"


    # Print friendly message regarding validation
    [ ${verbose} -eq 1 ] && print "Validating '${key}' according to STIG ID '${stigid}'"

    # Get ${settings} from ${pfile}
    haystack="$(grep "^${opt}" ${pfile})"

    # If ${haystack} is empty error & exit
    if [ "${haystack}" == "" ]; then

      if [ ${verbose} -eq 1 ]; then
        print "Failed validation for '${stigid}'" 1
        print "  '${opt}' is missing or invalid" 1
      fi

      exit 1
    fi
  done
fi


# Define an error and success array to handle verbose account pass/fail
declare -a fails
declare -a success

# Iterate ${users[@]}
for user in ${users[@]}; do

  # Check the lock after retries attribute
  chk="$(userattr lock_after_retries ${user} 2> /dev/null)"

  # Handle the error
  if [ "${chk}" == "no" ]; then

    # Print friendly message regarding restoration mode
    #[ ${verbose} -eq 1 ] && print "'lock_after_retries' attribute invalid for '${user}'" 1
    fails+=("${user}")
  else

    # Print friendly message regarding restoration mode
    #[ ${verbose} -eq 1 ] && print "'${user}' conforms to 'lock_after_retries' attributes"
    success+=("${user}")
  fi
done



# Set a default
ret=0

# Iterate ${opts[@]} & do work
for opt in ${opts[@]}; do

  if [ "$(grep "^${opt}" ${file})" == "" ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "'${opt}' is not set on '${file}'" 1

    # Set a return value
    ret=1
  fi
done


# Iterate ${popts[@]} & do work
for opt in ${popts[@]}; do

  if [ "$(grep "^${opt}" ${file})" == "" ]; then

    # Print friendly message regarding restoration mode
    [ ${verbose} -eq 1 ] && print "'${opt}' is not set on '${file}'" 1

    # Set a return value
    ret=1
  fi
done


# Handle valid accounts
if [ ${#success[@]} -gt 0 ]; then

  [ ${verbose} -eq 1 ] && print "'${#success[@]}/${#users[@]}' passed validation:"
  for successful in ${success[@]}; do
    [ ${verbose} -eq 1 ] && print "  '${successful}'"
  done
fi


# Handle invalid accounts
if [ ${#fails[@]} -gt 0 ]; then

  [ ${verbose} -eq 1 ] && print "'${#fails[@]}/${#users[@]}' passed validation:"
  for failed in ${fails[@]}; do
    [ ${verbose} -eq 1 ] && print "  '${failed}'"
  done
fi


# Return failure
if [ ${ret} -ne 0 ]; then
  [ ${verbose} -eq 1 ] && print "System does not conform to '${stigid}'" 1
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048245
# STIG_Version: SV-61117r1
# Rule_ID: SOL-11.1-040140
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The system must disable accounts after three consecutive unsuccessful login attempts.
# Description: Allowing continued access to accounts on the system exposes them to brute-force password-guessing attacks.
