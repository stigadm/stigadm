#!/bin/bash -x

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
new_stigs=( $(find ${directory} -type f -name "*.sh" -ls | awk '{print $11}') )

# Get an array of existing modules
declare -a existing_stigs
existing_stigs=( $(find ${existing_directory} -type f -name "*.sh" -ls | awk '{print $11}') )


# Include some libraries
libs=( $(find ${libs_directory} -type f -name "*.sh" -ls | awk '{print $11}') )
for lib in ${libs[@]}; do
  source ${lib} 2>/dev/null
done

# Copy ${existing_stigs[@]} to an array without paths
declare -a stigs
stigs=( $(echo "${existing_stigs[@]}" | xargs -iF basename F) )

# Iterate ${new_stigs[@]}
for new_stig in ${new_stigs[@]}; do

  # Cut up ${new_stig} into PATH & file
  path="$(dirname ${new_stig})"
  file="$(basename ${new_stig})"

  [ ! -d ${path} ] && echo ${path}
done
