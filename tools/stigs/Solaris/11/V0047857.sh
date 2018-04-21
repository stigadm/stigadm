#!/bin/bash -x


# audit min free space
audit_min_free_space=5

# Quota percentage for auditing ZFS filesystem
audit_fs_quota=25

# Define an array of ZFS attributes to validate/modify
#  - Syntax: <ZFS-Attribute>:<Value>
#  INFO: All sizes should be as percentages
declare -a zfs_attrs
zfs_attrs+=('compression:on')
zfs_attrs+=('reservation:25')
zfs_attrs+=('quota:25')

# Define an empty array to hold audit pluign settings
declare -a audit_settings

# Define an empty array to hold zfs settings
declare -a zfs_settings


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


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  print "'${stigid}' only applies to global zones" 1
  exit 1
fi


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


# Obtain an array of audit settings regarding 'bin_file' plugin
audit_settings=( $(auditconfig -getplugin audit_binfile | awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )


# Get the auditing filesystem from ${audit_settings[@]}
audit_folder="$(dirname $(get_inode "$(echo "${audit_settings[@]}" | tr ' ' '\n' | grep "^p_dir" | cut -d: -f2)"))"

# Get the auditing min_free value from ${audit_settings[@]}
fs_free="$(echo "${audit_settings[@]}" | tr ' '  '\n' | grep "^p_minfree" | cut -d: -f2)"


# Obtain an array of zfs shares matching ${audit_folder}
zfs_list=( $(zfs list | grep "${audit_folder}" | awk '{printf("%s:%s\n", $1, $5)}') )

# Iterate ${zfs_list}
for zfs_item in ${zfs_list[@]}; do

  # Extract the zfs_path & dataset name
  zfs_path="$(echo "${zfs_item}" | cut -d: -f1)"
  zfs_dataset="$(echo "${zfs_item}" | cut -d: -f2)"

  # Look for ${audit_folder} in ${zfs_item}
  needle="$(find_dir ${zfs_dataset} $(basename ${audit_folder}))"

  # If ${needle} exists we have our dataset name
  if [ "${needle}" != "" ]; then
    zfs_fs="${zfs_path}"
    break
  fi
done

# Break down if nothing exists for ${zfs_fs}
if [ "${zfs_fs}" == "" ]; then
  [ ${verbose} -eq 1 ] && print "Could not determine an audit filesystem to examine" 1
  exit 1
fi


# Set ${opts} from ${zfs_attrs[@]} array
opts="$(echo "${zfs_attrs[@]}" | tr ' ' '\n' | cut -d: -f1 | tr '\n' ',')"
opts="$(echo "${opts}" | sed "s|,$||g")"

# Obtain an array of ZFS values for the p_file value of ${audit_settings[@]}
zfs_settings=( $(zfs get ${opts} "${zfs_fs}" | awk '$0 !~ /^NAME/{printf("%s:%s:%s\n", $1, $2, $3)}') )


# Get the current total size for ${zfs_fs}
size="$(zfs list ${zfs_fs} | grep "^${zfs_fs}" | awk '{print $3}')"

# Get the current free size for ${zfs_fs}
free_size="$(zfs list ${zfs_fs} | grep "^${zfs_fs}" | awk '{print $4}')"


# Get the size type from ${total}
size_type="$(echo "${size}" | sed "s|.*\([A-Z]\)$|\1|g")"

# Remove ${size_type} from ${size} to get ${total}
total="$(echo "${size}" | sed "s|${size_type}||g")"

# Convert ${total} to bytes
total_bytes=$(tobytes "${size_type}" ${total})

# Get the percentage of bytes based on ${audit_fs_quota} & ${total_bytes}
quota_size="$(frombytes "${size_type}" $(percent ${total_bytes} ${audit_fs_quota}))${size_type}"


# Get the parent folder for ${zfs_fs} & it's available size
zfs_fs_parent="$(zfs list $(dirname ${zfs_fs}) | awk '$0 !~ /^NAME/{printf("%s:%s:%s\n", $1, $3, $5)}')"


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "audit_binfile:setplugin:$(echo "${audit_settings[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugin values failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current audit plugin values for 'audit_binfile'"


  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "${zfs_settings[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current audit plugin values failed..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot settings applied to '${zfs_fs}' ZFS dataset"


  # Set the p_minfree value for the audit_binfile audit plugin
  auditconfig -setplugin audit_binfile p_minfree=${audit_min_free_space}
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not set the minimum free space for the audit service..." 1

    # Stop, we require a backup
    exit 1
  fi

  # Restart the auditd service
  audit -s
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Could not restart the audit service..." 1
  fi


  # Iterate ${zfs_attrs[@]}
  for attr in ${zfs_attrs[@]}; do

    # Split up ${attr} into the key & desired value
    key="$(echo "${attr}" | cut -d: -f1)"
    value="$(echo "${attr}" | cut -d: -f2)"

    # Test ${value} for an integer & apply a percentage
    if [ $(is_int ${value}) -eq 1 ]; then

      # Copy ${value}
      tvalue=${value}

      # Convert ${total_bytes} to a percentage of ${value}
      value="$(frombytes "${size_type}" $(percent ${total_bytes} ${value}))"

      # If ${value} is 0 then skip & notify of issue
      if [ ${value} -eq 0 ]; then

        [ ${verbose} -eq 1 ] && print "Calculations for '${key} [${total_bytes} / 100 * ${tvalue}]' resulted in '${value}', skipping" 1
        continue
      fi

      # Apply ${size_type} to ${value}
      value="${value}${size_type}"
    fi

    # Enable compression on the ZFS audit fs
    zfs set ${key}=${value} ${zfs_fs} 2>/dev/null
    if [ $? -ne 0 ]; then

      # Print friendly message
      [ ${verbose} -eq 1 ] && print "Could set '${key}' to '${value}' on '${zfs_fs}'..." 1

      continue
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Set '${key}' to '${value}' on '${zfs_fs}'..."
  done


  # Obtain an array of audit settings regarding 'bin_file' plugin
  audit_settings=( $(auditconfig -getplugin audit_binfile | awk '$0 ~ /Attributes/{print $2}' | tr ';' ' ' | tr '=' ':') )

  # Get the auditing min_free value from ${audit_settings[@]}
  fs_free="$(echo "${audit_settings[@]}" | tr ' '  '\n' | grep "^p_minfree" | cut -d: -f2)"

  # Create a copy of ${zfs_settings[@]} prior to over writting it
  declare -a orig_zfs_settings
  orig_zfs_settings=( ${zfs_settings} )

  # Obtain an array of ZFS values for the p_file value of ${audit_settings[@]}
  zfs_settings=( $(zfs get ${opts} "${zfs_fs}" | awk '$0 !~ /^NAME/{printf("%s:%s:%s\n", $1, $2, $3)}') )
fi


# Define an empty array ot handle errors
declare -a errors


# Get the current p_minfree value
cur_audit_min_free_space=$(echo "${audit_settings[@]}" | tr ' ' '\n' | grep "p_minfree" | cut -d: -f2)

# Validate p_minfree value for audit_binfile
if [ ${cur_audit_min_free_space} -ne ${audit_min_free_space} ]; then
  errors+=("p_minfree:${audit_min_free_space}:${cur_audit_min_free_space}")
fi


# Iterate ${zfs_attrs[@]}
for attr in ${zfs_attrs[@]}; do

  # Split up ${attr} into the key & desired value
  key="$(echo "${attr}" | cut -d: -f1)"
  value="$(echo "${attr}" | cut -d: -f2)"

  # Get the current ${key} from ${zfs_settings[@]}
  cur_value="$(echo "${zfs_settings[@]}" | tr ' ' '\n' | grep "${key}" | cut -d: -f3)"


  # Test ${value} for an integer & apply a percentage
  if [ $(is_int ${value}) -eq 1 ]; then

    # Copy ${value}
    tvalue=${value}

    # If ${value} starts with a number
    if [ $(echo "${value}" | awk '{if ($0 ~ /^[0-9]/){print 1}else{print 0}}') -eq 1 ]; then

      # Get the current size for the parent file system
      parent_size="$(echo "${zfs_fs_parent}" | cut -d: -f2)"

      # Get the size type from ${total}
      parent_size_type="$(echo "${parent_size}" | sed "s|.*\([A-Z]\)$|\1|g")"

      # Remove ${size_type} from ${size} to get ${total}
      parent_total="$(echo "${parent_size}" | sed "s|${parent_size_type}||g")"

      # Convert ${total} to bytes
      parent_total_bytes=$(tobytes "${parent_size_type}" ${parent_total})

      # Add ${parent_total_bytes} with ${cur_total_bytes}
      parent_total_bytes=$(add ${parent_total_bytes} ${total_bytes})

      # Get the percentage of bytes based on ${audit_fs_quota} & ${total_bytes}
      parent_quota_size="$(frombytes "${parent_size_type}" $(percent ${parent_total_bytes} ${audit_fs_quota}))${parent_size_type}"


      # If ${parent_quota_size} != ${cur_value}
      if [ $(echo "${cur_value}" | grep -c "^${parent_quota_size}$") -eq 0 ]; then
#      if [ "${parent_quota_size}${parent_size_type}" != "${cur_value}" ]; then

        errors+=("${zfs_fs}:${key}:${value}")
        continue
      fi
    fi

    # Test ${cur_value} against ${value}
    if [ "${cur_value}" != "${value}" ]; then
      errors+=("${zfs_fs}:${key}:${cur_value}")
    fi
  fi
done


# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  [ ${verbose} -eq 1 ] && print "Could not validate '${stigid}'" 1

  # Iterate ${errors[@]}
  for error in ${errors[@]}; do

    # Split up ${error}
    fs="$(echo "${error}" | cut -d: -f1)"
    key="$(echo "${error}" | cut -d: -f2)"
    value="$(echo "${error}" | cut -d: -f3)"

    [ ${verbose} -eq 1 ] && print " - ${fs} ${key} ${value}" 1

  done
  exit 1
fi


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047857
# STIG_Version: SV-60731r2
# Rule_ID: SOL-11.1-010400
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must allocate audit record storage capacity.
# Description: Proper audit storage capacity is crucial to ensuring the ongoing logging of critical events.
