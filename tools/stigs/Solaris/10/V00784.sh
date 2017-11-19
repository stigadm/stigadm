#!/bin/bash


# Array of folders to examine
declare -a folders
folders+=("/etc")
folders+=("/bin")
folders+=("/usr/bin")
folders+=("/usr/ucb")
folders+=("/sbin")
folders+=("/usr/sbin")


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


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating compliance with STIG ID '${stigid}'"


# Make sure ${#folders[@]} is > 0
if [ ${#folders[@]} -eq 0 ]; then
  usage "A list of folders to examine must be defined" && exit 1
fi


# Iterate ${folders[@]}
for folder in ${folders[@]}; do

  # Print friendly message regarding validation
  [ ${verbose} -eq 1 ] && print "Obtaining list of files in '${folder}'"

  # Get files in ${folder}
  contents=($(ls ${folder}))

  # Make sure it isn't empty
  if [ ${#contents[@]} -eq 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "0 files found in '${folder}', skipping"
    continue
  fi

  # Iterate ${contents[@]}
  for item in ${contents[@]}; do

    # Handle symlinks
    item="$(get_inode ${item})"
    [ -z ${item} ] && continue

    # Make changes
    if [ ${change} -eq 1 ]; then

      # Get octal of ${item}
      octal=$(get_octal ${item})

      # Get user octal
      uoctal=${octal:3:4}

      # Get group octal
      goctal=${octal:4:5}

      # Get world octal
      woctal=${octal:5:6}

      # Make sure ${uoctal} >= ${goctal & ${ucotal} >= ${woctal}
      if [[ ${uoctal} -lt ${goctal} ]] || [[ ${uoctal} -lt ${woctal} ]]; then

        # Get the lowest value still greater than ${uoctal}
        toctal=$(( ${goctal} < ${woctal} ? ${goctal} ? ${uoctal} ))

        # Apply ${toctal} @ element 3 in ${octal}
        foctal=$(echo ${octal} | sed "s/.*/${toctal}/3")

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Setting permissions on '${file}' from '${octal}' to '${foctal}'"

        # Apply permissions
        chmod ${foctal} ${file}
      fi
    fi

    # Get octal of ${item}
    octal=$(get_octal ${item})

    # Get user octal
    uoctal=${octal:3:4}

    # Get group octal
    goctal=${octal:4:5}

    # Get world octal
    woctal=${octal:5:6}

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Obtained octal value for '${item}'"

      # Make sure ${uoctal} >= ${goctal & ${ucotal} >= ${woctal}
    if [[ ${uoctal} -lt ${goctal} ]] || [[ ${uoctal} -lt ${woctal} ]]; then

      # Push exception ${file} into ${ferr[@]}
      ferr+=(${file})
    fi

  done
done


# Show issues if ${#ferr[@]} > 0
if [ ${#ferr[@]} -gt 0 ]; then

  [ ${verbose} -eq 1 ] && print "User permissions is less then group &/or world permission" 1

  # Iterate ${ferr[@]}
  for err in ${ferr[@]}; do
    print "  File: ${err}" 1
  done
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, system folder contents conform to STIG ID '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00784
# STIG_Version: SV-39833r1
# Rule_ID: GEN001140
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00784
# STIG_Version: SV-39833r1
# Rule_ID: GEN001140
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: System files and directories must not have uneven access permissions.
# Description: System files and directories must not have uneven access permissions.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00784
# STIG_Version: SV-39833r1
# Rule_ID: GEN001140
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: System files and directories must not have uneven access permissions.
# Description: System files and directories must not have uneven access permissions.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00784
# STIG_Version: SV-39833r1
# Rule_ID: GEN001140
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: System files and directories must not have uneven access permissions.
# Description: Discretionary access control is undermined if users, other than a file owner, have greater access permissions to system files and directories than the owner.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00784
# STIG_Version: SV-39833r1
# Rule_ID: GEN001140
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: System files and directories must not have uneven access permissions.
# Description: Discretionary access control is undermined if users, other than a file owner, have greater access permissions to system files and directories than the owner.

