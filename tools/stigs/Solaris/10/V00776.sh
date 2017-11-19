#!/bin/bash


# Array of profile files
declare -a profiles
profiles+=(".bashrc")
profiles+=(".kshrc")
profiles+=(".profile")
profiles+=(".nshrc")
profiles+=(".zshrc")
profiles+=(".cshrc")

# Default path
path="PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/ucb:/usr/sfw:/opt/DTT/Bin"


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

  # Handle symlinks
  src="$(get_inode ${src})"

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


# Make sure ${#profiles[@]} is > 0
if [ ${#profiles[@]} -eq 0 ]; then
  usage "A list of profile configuration files to examine must be defined" && exit 1
fi


# Print friendly message regarding validation
[ ${verbose} -eq 1 ] && print "Validating root PATH according to STIG ID '${stigid}'"


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

  # Set ${chk} = 0 for default
  chk=0


  # If ${change} = 1 do work
  if [ ${change} -eq 1 ]; then

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

    # Backup the file
    cp ${file} ${file}.${author}-$(gen_date)

    # Print friendly message regarding backup of ${file}
    [ ${verbose} -eq 1 ] && print "Backed up '${file}'"

    # Perform check on ${stigid} rules for ${file}
    chk=$(echo "${cpath}" | awk '! $0 ~ /^\// && ! $0 ~ /\$PATH/ || $0 ~ /\.\./{print 1}')

    # Only apply changes to the $PATH if ${chk} != 0
    if [ ${chk} -ne 0 ]; then

      # Create & set permissions on temporary file
      tfile="$(gen_tmpfile "${file}" "${owner}" "${perms}" 1)"
      if [ $? -ne 0 ]; then
        usage "${tfile}" && exit 1
      fi

      # Print friendly message regarding temporary file
      [ ${verbose} -eq 1 ] && print "Created temporary file, '${tfile}'"

      # Make changes from ${file} into ${tfile}
      sed -e "s|^\$PATH=.*|${path}|g" ${file} > ${tfile}

      # Print friendly message regarding validation
      [ ${verbose} -eq 1 ] && print "Applied default PATH on '${tfile}'"

      # Move ${tfile} into ${file}
      mv ${tfile} ${file}

      # Print friendly message regarding restoration of ${file} from ${tfile}
      [ ${verbose} -eq 1 ] && print "Moved '${tfile}' to '${file}'"
    fi
  fi

  # Perform check on ${stigid} rules for ${file}
  chk=$(echo "${cpath}" | awk '! $0 ~ /^\// && ! $0 ~ /\$PATH/ || $0 ~ /\.\./{print 1}')

  if [ ${chk} -eq 1 ]; then
    print "Failed validation for '${stigid}' on '${file}'" 1
    exit 1
  fi
done


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, PATH validated in all specified profiles for '${stigid}'"

exit 0

# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00776
# STIG_Version: SV-776r4
# Rule_ID: GEN000940
#

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00776
# STIG_Version: SV-776r4
# Rule_ID: GEN000940
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: The root accounts executable search path must contain only authorized paths.
# Description: The root accounts executable search path must contain only authorized paths.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00776
# STIG_Version: SV-776r4
# Rule_ID: GEN000940
#
# OS: Solaris
# Version: 10
# Architecture: Sparc X86
#
# Title: The root accounts executable search path must contain only authorized paths.
# Description: The root accounts executable search path must contain only authorized paths.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00776
# STIG_Version: SV-776r4
# Rule_ID: GEN000940
#
# OS: Solaris
# Version: 10
# Architecture: X86
#
# Title: The root accounts executable search path must contain only authorized paths.
# Description: The executable search path (typically the PATH environment variable) contains a list of directories for the shell to search to find executables. If this path includes the current working directory or other relative paths, executables in these directories may be executed instead of system commands. This variable is formatted as a colon-separated list of directories. If there is an empty entry, such as a leading or trailing colon, two consecutive colons, or a single period, this is interpreted as the current working directory. Entries starting with a slash (/) are absolute paths.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00776
# STIG_Version: SV-776r4
# Rule_ID: GEN000940
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: The root accounts executable search path must contain only authorized paths.
# Description: The executable search path (typically the PATH environment variable) contains a list of directories for the shell to search to find executables. If this path includes the current working directory or other relative paths, executables in these directories may be executed instead of system commands. This variable is formatted as a colon-separated list of directories. If there is an empty entry, such as a leading or trailing colon, two consecutive colons, or a single period, this is interpreted as the current working directory. Entries starting with a slash (/) are absolute paths.

