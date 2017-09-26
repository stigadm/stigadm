#!/bin/bash

# OS: Solaris
# Version: 11
# Severity: CAT-I
# Class: UNCLASSIFIED
# VulnID: V-47845
# Name: SV-60719r1


# Definition for the file to validate/make changes to
file=/etc/mail/aliases

# Array of aliases
declare -a aliases
aliases+=("")


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

# Ensure ${file} exists @ specified location
if [ ! -f ${file} ]; then
  usage "'${file}' does not exist at specified location" && exit 1
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


# If ${change} = 1 do work
if [ ${change} -eq 1 ]; then

  # Backup the file
  cp ${file} ${file}.${author}-$(gen_date)

  # Print friendly message regarding backup of ${file}
  [ ${verbose} -eq 1 ] && print "Backed up '${file}'"


  # Print friendly message regarding change
  [ ${verbose} -eq 1 ] && print "Applying changes for '${stigid}'"


  # Get octal notation for current perms on ${file}
  perms=$(get_octal ${file})

  # Get user/group for current ${file}
  owner="$(get_inode_user ${file}):$(get_inode_group ${file})"

  # Create & set permissions on temporary file
  tfile="$(gen_tmpfile "${file}" "${owner}" "${perms}" 1)"
  if [ $? -ne 0 ]; then
    usage "${tfile}" && exit 1
  fi

  # Print friendly message regarding temporary file
  [ ${verbose} -eq 1 ] && print "Created temporary file, '${tfile}'"


  # Make sure ${#aliases[@]} > 0
  if [ ${#aliases[@]} -eq 0 ]; then
    [ ${verbose} -eq 1 ] && print "No aliases defined" 1
    exit 1
  fi


  # Iterate ${aliases[@]}
  for talias in ${aliases[@]}; do
    #[ ${verbose} -eq 1 ] && print "Searching for '${talias}' in '${tfile}'"

    # Get alias keyword from ${talias}
    palias="$(echo "${talias}" | cut -d: -f1)"

    # Get the current list of emails from ${talias}
    IFS="," read -p lemails <<< "$(echo "${talias}" | cut -d: -f2)"

    # Search for ${alias} in ${tfile}
    tmp="$(grep "^${palias}" ${tfile})"

    # If ${tmp} is empty then simply add it
    if [ "${tmp}" == "" ]; then
      [ ${verbose} -eq 1 ] && print "Nothing found for '${palias}' in '${tfile}'"

      echo "${alias}" ${tfile}
    else

      # Since ${tmp} is not empty get list of emails
      IFS="," read -p cemails <<< "$(echo "${tmp}" | cut -d: -f2)"

      # Perform intersection of ${lemails[@]} with ${cemails[@]}
      temails=($(comm -13 <(printf "%s\n" "$(echo "${lemails[@]}" | sort -u)") \
                  <(printf "%s\n" "$(echo "${cemails[@]}" | sort -u)")))

      [ ${verbose} -eq 1 ] && print "Performed intersection on current emails & defined emails"

      # Skip if nothing found
      if [ ${temails[@]} -eq 0 ]; then
        [ ${verbose} -eq 1 ] && print "'${#temails[@]}' found for '${palias}', skipping"
        contine
      fi

      # Combine ${temails[@]} w/ ${palias} and change entry in ${tfile}
      sed -e "s|^${palias}.*|${palias}:$(echo "${temails[@]}" | tr ' ' ',')|g" ${file} > ${tfile}

      [ ${verbose} -eq 1 ] && print "Updated '${palias}' to reflect missing notification addresses"
      [ ${verbose} -eq 1 ] && print "  $(echo "{temails[@]}" | tr ' ' ',')"
    fi
  done

  # Move ${tfile} into ${file}
  mv ${tfile} ${file}

  # Print friendly message regarding restoration of ${file} from ${tfile}
  [ ${verbose} -eq 1 ] && print "Moved '${tfile}' to '${file}'"

  # Load the new aliases (if any)
  newaliases
fi


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating '${file}' according to STIG ID '${stigid}'"


# Define an array to handle errors
declare -a errs

# Iterate ${aliases[@]}
for talias in ${aliases[@]}; do
  [ ${verbose} -eq 1 ] && print "Searching for '${talias}' in '${file}'"

  # Get ${settings} from ${file}
  haystack="$(grep "^${talias}" ${file})"

  # If ${haystack} is empty
  if [ "${haystack}" == "" ]; then

    # Set an error code
    errs+=("${talias}")

  fi
done


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  print "Failed validation for '${stigid}'" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    if [ ${verbose} -eq 1 ]; then
      print "  Missing: ${err}" 1
    fi
  done

  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, '${file}' conforms to '${stigid}'"

exit 0
