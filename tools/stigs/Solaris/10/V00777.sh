#!/bin/bash



# Array of profile files
declare -a profiles
profiles+=(".bashrc")
profiles+=(".kshrc")
profiles+=(".profile")
profiles+=(".nshrc")
profiles+=(".zshrc")
profiles+=(".cshrc")

# Permissions string for removing world writeable bit
perms="o-w"


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
[ ${verbose} -eq 1 ] && print "Validating root PATH according to STIG ID '${stigid}'"


# Make sure ${#profiles[@]} is > 0
if [ ${#profiles[@]} -eq 0 ]; then
  usage "A list of profile configuration files to examine must be defined" && exit 1
fi


# Get ${settings} from ${file}
directory="$(awk -F: '$1 ~ /^root$/{print $6}' /etc/passwd)"

# Ensure ${directory} exists
if [ ! -d ${directory} ]; then
  [ ${verbose} -eq 1 ] && print "'${directory}' doesn't exist" 1
  exit 1
fi

# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Obtained root user's home directory; '${directory}'"


# Make sure ${#profiles[@]} > 0
if [ ${#profiles[@]} -eq 0 ]; then
  [ ${verbose} -eq 1 ] && print "No file(s) defined for root account PATH configuration" 1
  exit 1
fi


# Iterate ${profiles[@]} and do work
for profile in ${profiles[@]}; do

  # Set ${file} = ${directory + ${profile}
  file="${directory}/${profile}"

  # Handle symlinks
  file="$(get_inode ${file})"

  # Skip iteration if ${file} doesn't exist
  if [ ! -f ${file} ]; then

    [ ${verbose} -eq 1 ] && print "'${file}' doesn't exist, skipping"
    continue
  fi


  # Obtain the current $PATH info
  cpath="$(grep "^PATH=" ${file} | cut -d= -f2)"

  # Split ${cpath} into an array
  IFS=":" read -p paths <<< ${cpath}

  # If ${#paths[@]} = 0 exit
  if [ ${#paths[@]} -eq 0 ]; then
    [ ${verbose} -eq 1 ] && print "No path(s) defined in PATH configuration" 1
  fi

  # Iterate ${paths[@]} & set/validate world writeable
  for path in ${paths[@]}; do

    # Handle symlinks
    path="$(get_inode ${path})"
    [ -z ${path} ] && continue

    # Get current permissions on ${path} (stat would be nicer to use)
    cperm=$(get_octal ${path})

    # If ${cperm} = 0
    if [ ${cperm} -eq 0 ]; then
      [ ${cperm} -eq 1 ] && print "Unable to obtain octal permissions on '${path}'" 1
    fi

    # If ${change} = 1 do work
    if [ ${change} -eq 1 ]; then

      # Be verbose about current value & path
      [ ${verbose} -eq 1 ] && print "Working on '${path}' (${cperm})"

      # Copy the last octal to ${octal}
      octal="${perm:${#perm}-${#perm}-1:${#perm}-1}"

      # If last bit of ${cperm} > 6 remove world writeable bit
      if [[ ${octal} -ge 6 ]] && [[ ${octal} -eq 2 ]] && [[ ${octal} -eq 3 ]]; then

        # Be verbose about current value & path
        [ ${verbose} -eq 1 ] && print "'${cperm}' permissions for '${path}' are being modified"

        chmod ${perms} ${path}
      fi
    fi

    # Get current permissions on ${path} (stat would be nicer to use)
    cperm=$(get_octal ${path})

    # If ${cperm} = 0
    if [ ${cperm} -eq 0 ]; then
      [ ${cperm} -eq 1 ] && print "Unable to obtain octal permissions on '${path}'" 1
    fi


    # Copy the last octal to ${octal}
    octal="${perm:${#perm}-${#perm}-1:${#perm}-1}"

    # If last bit of ${cperm} > 6 remove world writeable bit
    if [[ ${octal} -ge 6 ]] && [[ ${octal} -eq 2 ]]; then
      [ ${verbose} -eq 1 ] && print "'${cperm}' permissions for '${path}' are world writeable" 1
      ret=1
    fi
  done
done

# Exit with error code
[ ${ret} -eq 1 ] && exit 1

# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, profile PATH elements validated according to '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00777
# STIG_Version: SV-37075r1
# Rule_ID: GEN000960
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00777
# STIG_Version: SV-37075r1
# Rule_ID: GEN000960
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: The root account must not have world-writable directories in its executable search path.
# Description: The root account must not have world-writable directories in its executable search path.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00777
# STIG_Version: SV-37075r1
# Rule_ID: GEN000960
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: The root account must not have world-writable directories in its executable search path.
# Description: The root account must not have world-writable directories in its executable search path.

