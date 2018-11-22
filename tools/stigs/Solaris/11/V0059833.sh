#!/bin/bash

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


  # Skip creating a haystack from ${inode} if is_binary is < 0
  [ $(is_compiled ${inode}) -gt 0 ] && continue

  # Extract possible LD_PRELOAD from ${inode} to an array as ${haystack[@]}
  haystack=( $(nawk '$0 ~ /LD_PRELOAD=/{if ($0 ~ /LD_PRELOAD=/){split($0, obj, "=");if(obj[2] ~ /;/){split(obj[2], fin, ";")}else{fin[2]=obj[2]}print fin[2]}}' ${inode} 2>/dev/null) )

  # Skip ${inode} if LD_PRELOAD not found
  [ ${#haystack[@]} -eq 0 ] && continue


  # Iterate ${haystack[@]}
  for haybail in ${haystack[@]}; do

    # Examine ${haybail} for invalid path
    chk=$(echo "${haybail}" | egrep -c '^:|::|:$|:[a-zA-Z0-9-_~.]+')

    # Add ${inode} to ${errors[@]} array if ${chk} > 0
    [ ${chk} -gt 0 ] && errors+=("${inode}")
  done

  # Mark them all as inspected
  inspected+=("${inode}")
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Iterate ${errors[@]}
  for file in ${errors[@]}; do

    # Create the backup env
    backup_setup_env "${backup_path}"

    # Create a snapshot of ${users[@]}
    bu_file "${author}" "${inode}"
    if [ $? -ne 0 ]; then
      # Stop, we require a backup
      report "Unable to create backup of ${inode}" && exit 1
    fi

    # Get the last backup file
    tfile="$(bu_file_last "$(dirname ${inode})" "${author}")"
    if [ ! -f ${tfile} ]; then
      # Stop we require ${tfile} to make changes
      report "Unable to acquire ${inode} backup name" && exit 1
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
  done

  # Remove dupes from ${errors[@]}
  errors=( $(remove_duplicates "${errors[@]}") )
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

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"
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
