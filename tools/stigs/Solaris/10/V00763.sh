#!/bin/bash


# Definition for the file to validate/make changes to
file=/etc/issue

# Contents of ${file}
read -d '' banner <<"EOF"
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:
 -The USG routinely intercepts and monitors communications on this IS for purposes including, but not
  limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM),
  law enforcement (LE), and counterintelligence (CI) investigations.
 -At any time, the USG may inspect and seize data stored on this IS.
 -Communications using, or data stored on, this IS are not private, are subject to routine monitoring,
  interception, and search, and may be disclosed or used for any USG-authorized purpose.
 -This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not
  for your personal benefit or privacy.
 -Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching
  or monitoring of the content of privileged communications, or work product, related to personal representation
  or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work
  product are private and confidential. See User Agreement for details.
EOF


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

  # Make changes from ${file} into ${tfile}
  echo "${banner}" > ${file}

  # Print friendly message regarding temporary file permissions
  [ ${verbose} -eq 1 ] && print "Created '${stigid}' compliant '${file}'"
fi


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating '${file}' according to STIG ID '${stigid}'"

# Get ${banner} from ${file}
haystack="$(grep "${banner}" ${file})"

# If ${haystack} is empty error & exit
if [ "${haystack}" == "" ]; then

  if [ ${verbose} -eq 1 ]; then
    print "Failed validation for '${stigid}'" 1
    print "  File: ${file}" 1
    print "  Value: ${banner}" 1
  fi

  exit 1
fi

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, '${file}' conforms to '${stigid}'"

exit 0


# Date: 2018-06-29
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00763
# STIG_Version: SV-28596r1
# Rule_ID: GEN000400
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: The Department of Defense (DoD) login banner must be displayed immediately prior to, or as part of, console login prompts.
# Description: Failure to display the login banner prior to a logon attempt will negate legal proceedings resulting from unauthorized access to system resources.
