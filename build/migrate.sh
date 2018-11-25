#!/bin/bash


# Migrate newly parsed STIG's with existing

# Get current directory
cwd="$(pwd)"

# Define our expected output directory of new modules
directory="${cwd}/build/output"

# Define out expected directory of existing modules
existing_directory="${cwd}/tools/stigs"

# Define out expected directory of libraries
libs_directory="${cwd}/tools/libs"


# Get an array of new modules
declare -a new_stigs
new_stigs=( $(find ${directory} -type f -name "*.sh" -ls | awk '{print $11}' | sort -u) )

# Get an array of existing modules
declare -a existing_stigs
existing_stigs=( $(find ${existing_directory} -type f -name "*.sh" -ls | awk '{print $11}' | sort -u) )


# Include some libraries
libs=( $(find ${libs_directory} -type f -name "*.sh" -ls | awk '{print $11}') )
for lib in ${libs[@]}; do
  source ${lib} 2>/dev/null
done


# Iterate ${new_stigs[@]}
for new_stig in ${new_stigs[@]}; do

  # Cut up ${new_stig} into PATH & file
  path="$(echo "$(dirname ${new_stig})" | sed "s|${directory}||g")"
  file="$(basename ${new_stig})"


  # Combine ${existing_directory}${path}
  path="${existing_directory}${path}"

  # Test & make ${path} if it isn't there
  [ ! -d ${path} ] && mkdir -p ${path}

  # Test for ${file} in ${path} & copy if missing
  if [ ! -f ${path}/${file} ]; then
    cp ${new_stig} ${path}/${file}
  else
    # Here we should do some differential work
    sum1="$(sha256sum ${new_stig} | awk '{print $1}')"
    sum2="$(sha256sum ${path}/${file} | awk '{print $1}')"

    # Compare & diff if not the same
    if [ "${sum1}" != "${sum2}" ]; then

      # Get blobs of meta data
      blob1="$(egrep '\# Date|\# Severity|\# Classification|\# STIG|\# Rule|\# OS|\# Version|\# Architecture|\# Title|\# Description' ${new_stig})"
      blob2="$(egrep '\# Date|\# Severity|\# Classification|\# STIG|\# Rule|\# OS|\# Version|\# Architecture|\# Title|\# Description' ${path}/${file})"

      # Since we expect ${blob1} to be newer
      echo "${new_stig}"
      echo "${path}/${file}"
      diff -NaubB <(echo "${blob2}") <(echo "${blob1}")
      echo
    fi
  fi
done
