#!/bin/bash

# Default user
def_user="root"

# Array of allowed owners
declare -a accts
accts+=("root")
accts+=("bin")
accts+=("sys")

# Array of init script locations
declare -a inits
inits+=("/etc/rc*")
inits+=("/etc/init*")
inits+=("/lib/svc")
inits+=("/etc/systemd")
inits+=("/lib/systemd")


###############################################
# Bootstrapping environment setup
###############################################

# Get our working directory
cwd="$(pwd)"

# Define our bootstrapper location
bootstrap="${cwd}/tools/bootstrap.sh"

# Bail if it cannot be found
if [ ! -f ${bootstrap} ]; then
  echo "Unable to locate bootstrap; ${bootstrap}" && exit 1
fi

# Load our bootstrap
source ${bootstrap}


###############################################
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is as group
caller=$(ps $PPID | grep -c stigadm)


###############################################
# Perform restoration
###############################################

# If ${restore} = 1 go to restoration mode
if [ ${restore} -eq 1 ]; then
  report "Not yet implemented" && exit 1
fi


###############################################
# STIG validation/remediation
###############################################

# Get list of init scripts to examine
files=( $(find ${inits[@]} -type f -ls 2>/dev/null | awk '{print $11}') )


# Iterate ${files[@]}, resolve to actual file and pluck possible file(s) for examination
for inode in ${files[@]}; do

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Skip stripping out possible files from ELF's & data files
  if [ $(is_compiled ${inode}) -gt 0 ]; then
    tmp_files+=("${inode}")
    continue
  fi

  # Use extract_filenames() to obtain array of binaries from ${inode}
  tmp_files+=( $(extract_filenames ${inode}) )
done


# Remove dupes
files=( ${files[@]} $(remove_duplicates "${tmp_files[@]}") )


# Filter for actual files
files=( $(test_file "${files[@]}") )


# Iterate ${files[@]} and create haystack to find
for inode in ${files[@]}; do

  # Bail if ${inode} is null
  [ "${inode}" == "" ] && continue

  # Handle symlinks
  inode="$(get_inode ${inode})"

  # Bail if ${inode} is null
  [ "${inode}" == "" ] && continue


  # Get current owner & group
  owner="$(get_inode_user ${inode})"

  # If ${owner} of ${inode} doesn't exist in ${accts[@]} flag it
  [ $(in_array ${owner} ${accts[@]}) -ne 0 ] &&
    errors+=("${inode}:${owner}")

  # Mark them all as inspected
  inspected+=("${inode}:${owner}")
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${inspected[@]}" | tr ' ' '\n')"
  if [ $? -ne 0 ]; then
    # Stop, we require a backup
    report "Unable to create snapshot of init ownership" && exit 1
  fi

  # Iterate ${errors[@]}
  for file in ${errors[@]}; do

    # Set ownership to ${def_user}
    chown ${def_user} ${file} 2>/dev/null

    # Get current owner & group
    owner="$(get_inode_user ${inode})"

    # If ${owner} of ${inode} doesn't exist in ${accts[@]} flag it
    [ $(in_array ${owner} ${accts[@]}) -ne 0 ] &&
    errors+=("${inode}:${owner}")
  done

  # Remove dupes from ${errors[@]}
  errors=( $(remove_duplicates "${errors[@]}") )
fi

# Remove dupes
inspected=( $(remove_duplicates "${inspected[@]}") )


###############################################
# Results for printable report
###############################################

# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Set ${results} error message
  results="Failed validation"
fi

# Set ${results} passed message
[ ${#errors[@]} -eq 0 ] && results="Passed validation"


###############################################
# Report generation specifics
###############################################

# Apply some values expected for report footer
[ ${#errors[@]} -eq 0 ] && passed=1 || passed=0
[ ${#errors[@]} -gt 0 ] && failed=1 || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})

# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0059843
# STIG_Version: SV-74273r1
# Rule_ID: SOL-11.1-020380
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: System start-up files must only execute programs owned by a privileged UID or an application.
# Description: System start-up files executing programs owned by other than root (or another privileged user) or an application indicates the system may have been compromised.
