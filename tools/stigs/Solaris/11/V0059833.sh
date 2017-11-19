#!/bin/bash



# Array of init script locations
declare -a inits
inits+=("/etc/rc*")
inits+=("/etc/init.d")
inits+=("/lib/svc")

# Pattern to match *possible* binaries
pattern="/[a-z0-9A-Z._-]+"

# Disable changes for offending inodes found on remote shares
disable_remote=1


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


# Make sure ${#inits[@]} is > 0
if [ ${#inits[@]} -eq 0 ]; then
  usage "A list of profile configuration files to examine must be defined" && exit 1
fi


# Get all remote mount points
remotes=( $(mount | awk '$3 ~ /.*\:.*/{print $1}') )

# Get list of init scripts to examine
files=( $(find ${inits[@]} -type f -ls | awk '{print $11}') )

# Exit if ${#files[@]} is 0
if [ ${#files[@]} -eq 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "'${#files[@]}' init scripts found to examine; exiting" && exit 0
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Got list of init scripts to examine; ${#files[@]}"


# Define an empty array for errors
declare -a errs

# Define an empty array for validated files
declare -a vals


# Iterate ${files[@]}
for inode in ${files[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Skip if ${inode} == 1
  [ "${inode}" == 1 ] && continue

  # Use extract_filenames() to obtain array of binaries from ${inode}
  tmp_files+=( $(extract_filenames ${inode}) )
done


# If $tmp_files[@]} > 0
if [ ${#tmp_files[@]} -gt 0 ]; then

  # Merge ${files[@]} with ${tmp_files[@]}
  files=( ${files[@]} ${tmp_files[@]} )
fi

# Discard duplicates from ${files}
files=( $(remove_duplicates "${files[@]}") )

# Print friendly message
[ ${verbose} -eq 1 ] && print "Found ${#files[@]} referenced files from init scripts to process"


# Iterate ${files[@]}
for inode in ${files[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Skip if ${inode} == 1
  [ "${inode}" == 1 ] && continue

  # Extract PATH from ${inode}
  haystack=( $(nawk '$0 ~ /LD_LIBRARY_PATH=[a-zA-Z0-9:\/]+/{split($0, obj, "=");if(obj[2] ~ /;/){split(obj[2], fin, ";");res=fin[1]}else{res=obj[2]}print res}' ${inode} 2>/dev/null | \
    grep -v "export") )


  # Skip ${inode} if LD_LIBRARY_PATH not found
  [ ${#haystack[@]} -eq 0 ] && continue


  # Iterate ${haystack[@]}
  for haybail in ${haystack[@]}; do

    # Examine ${haybail} for invalid path
    chk=$(echo "${haybail}" | egrep -c '^:|::|:$|:[a-zA-Z0-9-_~.]+')

    # Add ${inode} to ${errs[@]} array if ${chk} > 0 OR add it to ${vals[@]} array
    [ ${chk} -gt 0 ] && errs+=("${inode}") || vals+=("${inode}")


    # If ${change} > 0
    if [[ ${change} -ne 0 ]] && [[ $(in_array "${inode}" "${errs[@]}") -gt 0 ]]; then

      # Create the backup env
      backup_setup_env "${backup_path}"

      # Create a backup of ${file}
      bu_file "${author}" "${inode}"
      if [ $? -ne 0 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Could not create a backup of '${inode}', exiting..." 1

        # Stop, we require a backup
        exit 1
      fi

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Created backup of '${inode}'"

      # Get the last backup file
      tfile="$(bu_file_last "$(dirname ${inode})" "${author}")"
      if [ ! -f ${tfile} ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "An error occurred getting temporary file for changes"
        exit 1
      fi

      # Strip out invalid PATH entries from ${tfile};
      #   ugly... re factoring a more robust BRE pattern would be preferred
      sed -e "s/=://g" \
          -e "s/=~.*$//g" \
          -e "s/=~.*://g" \
          -e "s/=\..*://g" \
          -e "s/=\..*$//g" \
          -e "s/=\.\..*://g" \
          -e "s/=\.\..*$//g" \
          -e "s/:://g" \
          -e "s/:$//g" \
          -e "s/:~.*$//g" \
          -e "s/:~.*://g" \
          -e "s/:\..*://g" \
          -e "s/:\..*$//g" \
          -e "s/:\.\..*://g" \
          -e "s/:\.\..*$//g" ${tfile} > ${inode}
    fi
  done
done


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "List of inodes with invalid LD_LIBRARY_PATH(s) defined" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Look in ${remotes[@]} to determine possible remote share
    if [ $(in_array_fuzzy "${err}" "${remotes[@]}") -eq 0 ]; then
      efile="[Remote/NFS] ${err}"
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  - ${err}" 1
  done

  exit 1
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "'${#vals[@]}/${#files[@]}' LD_LIBRARY_PATH(s) from init scripts validated"

# If ${#validated[@]} > 0
if [ ${#vals[@]} -gt 0 ]; then

  # Iterate ${vals[@]}
  for val in ${vals[@]}; do

    # Assign ${inode} to ${validated[@]}
    if [ $(in_array_fuzzy "${val}" "${remotes[@]}") -eq 0 ]; then
      efile="[Remote/NFS] ${val}"
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  - ${val}"
  done
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, system conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0059833
# STIG_Version: SV-74263r2
# Rule_ID: SOL-11.1-020330
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: Run control scripts library search paths must contain only authorized paths.
# Description: The library search path environment variable(s) contain a list of directories for the dynamic linker to search to find libraries. If this path includes the current working directory or other relative paths, libraries in these directories may be loaded instead of system libraries. This variable is formatted as a colon-separated list of directories. If there is an empty entry, such as a leading or trailing colon, two consecutive colons, or a single period, this is interpreted as the current working directory. Paths starting with a slash (/) are absolute paths.

