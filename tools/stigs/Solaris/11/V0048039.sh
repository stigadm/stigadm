#!/bin/bash


# Define a default user & group
def_user="root"

def_group="root"


# Disable user/group ownership changes for offending inodes found on remote shares
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



print "Not yet implemented" && exit 1

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


# Get all unowned inodes
files=( $(find / \( -fstype nfs -o -fstype cachefs -o -fstype autofs -o -fstype ctfs -o -fstype mntfs \
          -o -fstype objfs -o -fstype proc \) -prune \( -nouser -o -nogroup \) -ls | nawk '{print $11}') )

# Get all remote mount points
remotes=( $(mount | nawk '$3 ~ /.*\:.*/{print $1}') )


# If ${#files[@]}} = 0
if [ ${#files[@]} -eq 0 ]; then

  # Print friendly success
  [ ${verbose} -eq 1 ] && print "'${#files[@]}' files found without UID/GID owners on 'local' file systems. Success, conforms to '${stigid}'"

  exit 0
fi

# Print friendly message
[ ${verbose} -eq 1 ] && print "Found '#${#files[@]}' offending inode's regarding '${stigid}'" 1


# If ${change} > 0
if [ ${change} -ne 0 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"


  # Create a snapshot of ${inodes[@]} current permissions
  bu_inode_perms "${backup_path}" "${author}" "${stigid}" "${files[@]}"
  if [ $? -ne 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Snapshot of current permissions for '${stigid}' failed..."

    # Stop, we require a backup
    exit 1
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Created snapshot of current permissions"
fi


# Define an empty array for errors
declare -a errs

# Define an empty array for validated inodes
declare -a vals


# Iterate ${files[@]}
for inode in ${files[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Skip ${inode} if it's not a file
  [ ! -f ${inode} ] && continue

  # if ${change} = 1
  if [ ${change} -eq 1 ]; then

    # If ${inode} path doesnt exist in ${remotes[@]}
    if [ $(in_array_fuzzy "${inode}" "${remotes[@]}") -eq 1 ]; then

      # Change ownership on ${inode} to ${def_user}
      chown ${def_user} ${inode} 2> /dev/null

      # Handle return
      if [ $? -ne 0 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Could not set default owner on '${inode}'" 1
      fi
    else

      # If ${disable_remote} = 1
      if [ ${disable_remote} -eq 1 ]; then

        # Print friendly message
        [ ${verbose} -eq 1 ] && print "Remote; Skipping '${inode}'; enable with 'disable_remote=0'"
      else

        # Change ownership on ${inode} to ${def_user}
        chown ${def_user} ${inode} 2> /dev/null

        # Handle return
        if [ $? -ne 0 ]; then

          # Print friendly message
          [ ${verbose} -eq 1 ] && print "Could not set default owner on '${inode}'" 1
        fi
      fi
    fi
  fi

  # Get current owner of ${inode}
  cuser=$(get_inode_user ${inode})

  # Get current group owner of ${inode}
  cgroup=$(get_inode_group ${inode})


  # If ${cuser} or ${cgroup} > 0
  if [[ ${cuser} -gt 0 ]] || [[ ${cgroup} -gt 0 ]]; then

    # If ${cuser} = integer
    #if [ ${cuser} -gt 0 ]; then
    if [[ ! "${cuser}" =~ ^[0-9]+$ ]]; then
      errs+=("user:${inode}:${cuser}")
    fi

    # If ${cgroup} = integer
    #if [ ${cgroup} -gt 0 ]; then
    if [[ ! "${cgroup}" =~ ^[0-9]+$ ]]; then
      errs+=("group:${inode}:${cgroup}")
    fi

    continue
  fi

  # Assign ${inode} to ${vals[@]}
  vals+=("${inode}:${cuser}:${cgroup}")

done


# If ${#errs[@]} > 0
if [ ${#errs[@]} -gt 0 ]; then

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "List of inodes with invalid permissions" 1

  # Iterate ${errs[@]}
  for err in ${errs[@]}; do

    # Split ${err} into type
    etype="$(echo "${err}" | cut -d: -f1)"

    # Split ${err} into file
    efile="$(echo "${err}" | cut -d: -f2)"

    # Split ${err} into octal
    eowner="$(echo "${err}" | cut -d: -f3)"

    # Check to see if ${efile} path exists in ${remotes[@]}
    if [ $(in_array_fuzzy "${efile}" "${remotes[@]}") -eq 0 ]; then
      efile="[Remote/NFS] ${efile}"
    fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "  - ${efile} [${etype}: ${eowner}]" 1
  done

  exit 1
fi


# Print friendly message
[ ${verbose} -eq 1 ] && print "Validated world-writable permissions on '${#vals[@]}' inodes"

# Iterate ${vals[@]}
for val in ${vals[@]}; do

  # Split ${err} into type
  ofile="$(echo "${err}" | cut -d: -f1)"

  # Split ${err} into file
  oowner="$(echo "${err}" | cut -d: -f2)"

  # Split ${err} into octal
  ogroup="$(echo "${err}" | cut -d: -f3)"

  # Check to see if ${ofile} path exists in ${remotes[@]}
  if [ $(in_array_fuzzy "${ofile}" "${remotes[@]}") -eq 0 ]; then
    ofile="[Remote/NFS] ${ofile}"
  fi

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "  - ${ofile}  [${oowner}: ${ogroup}]"
done



# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048039
# STIG_Version: SV-60911r1
# Rule_ID: SOL-11.1-070200
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must have no unowned files.
# Description: A new user who is assigned a deleted user's user ID or group ID may then end up owning these files, and thus have more access on the system than was intended.
