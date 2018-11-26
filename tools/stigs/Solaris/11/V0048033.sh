#!/bin/bash

# Path to examine for files/folders permissions
logs_path=/var/adm

# Folder permissions
folder_perms=00750

# File permissions
file_perms=00640

# Ownership defaults
folder_ownership="root:sys"

# File ownership defaults
file_ownership="root:root"


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

# Whos is calling? 0 = singular, 1 is from stigadm
caller=$(ps $PPID | grep -c stigadm)


###############################################
# STIG validation/remediation/restoration
###############################################

# Capture array of files under ${logs_path} as well as ${logs_path}
files=( ${logs_path} $(find ${logs_path} -type f) )


# Iterate ${files[@]}
for file in ${files[@]}; do

  # Resolve ${file}
  file="$(get_inode ${file})"

  # Get owner, group & octal of each
  c_owner="$(get_inode_user ${file})"
  c_group="$(get_inode_group ${file})"
  c_perms=$(get_octal ${file})

  # If any do not match defaults push to errors array
  if [[ "${c_owner}" != "$(echo "${file_ownership}" | cut -d: -f1)" ]] ||
     [[ "${c_group}" != "$(echo "${file_ownership}" | cut -d: -f2)" ]] ||
     [[ ${c_perms} -gt ${file_perms} ]]; then
    errors+=("${file}:${c_owner}:${c_group}:${c_perms}")
  fi

  # Push all to inspected array
  inspected+=("${file}:${c_owner}:${c_group}:${c_perms}")
done


# If ${change} is requested
if [ ${change} -eq 1 ]; then

  # Create the backup env
  backup_setup_env "${backup_path}"

  # Create a snapshot of ${users[@]}
  bu_configuration "${backup_path}" "${author}" "${stigid}" "$(echo "${inspected[@]}" | tr ' ' ',')"
  if [ $? -ne 0 ]; then

    # Bail if we can't create a backup
    report "Failed to create backup" && exit 1
  fi

  # Iterate ${errors[@]}
  for file in ${errors[@]}; do

    # Resolve ${file}
    file="$(get_inode ${file})"

    # Set owner/group on ${file}
    chown ${file_ownership} ${file} 2>/dev/null

    # Set permissions on ${file}
    chmod ${file_perms} ${file}


    # Get owner, group & octal of each
    c_owner="$(get_inode_user ${file})"
    c_group="$(get_inode_group ${file})"
    c_perms=$(get_octal ${file})

    # If any do not match defaults push to errors array
    if [[ "${c_owner}" != "$(echo "${file_ownership}" | cut -d: -f1)" ]] ||
       [[ "${c_group}" != "$(echo "${file_ownership}" | cut -d: -f2)" ]] ||
       [[ ${c_perms} -gt ${file_perms} ]]; then
      errors+=("${file}:${c_owner}:${c_group}:${c_perms}")
    fi
  done

  # Remove dupes from ${errors[@]}
  errors=( $(remove_duplicates ${errors[@]}) )
fi


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

# Return an error/success code
exit ${#errors[@]}


# Date: 2018-09-05
#
# Severity: CAT-III
# Classification: UNCLASSIFIED
# STIG_ID: V0048033
# STIG_Version: SV-60905r2
# Rule_ID: SOL-11.1-070240
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must reveal error messages only to authorized personnel.
# Description: Proper file permissions and ownership ensures that only designated personnel in the organization can access error messages.
