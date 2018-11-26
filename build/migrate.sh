#!/bin/bash


# Migrate newly parsed STIG's with existing

change=${1}

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
  if [ ! -d ${path} ]; then
    [ ${change:=0} -eq 1 ] && mkdir -p ${path}
  fi

  # Test for ${file} in ${path} & copy if missing
  if [ ! -f ${path}/${file} ]; then
    [ ${change:=0} -eq 1 ] && cp ${new_stig} ${path}/${file}
  else
    # Here we should do some differential work
    sum1="$(sha256sum ${new_stig} | awk '{print $1}')"
    sum2="$(sha256sum ${path}/${file} | awk '{print $1}')"

    # Compare & diff if not the same
    if [ "${sum1}" != "${sum2}" ]; then

      # Get meta data
      blob="$(egrep '\# Date|\# Severity|\# Classification|\# STIG_|\# Rule|\# OS|\# Version|\# Title|\# Description' ${new_stig})"

      # Cut up ${blob} so we can update the meta data in ${path}/${file}
      s_date="$(echo "${blob}" | grep "^\# Date:" | awk '{print $3}')"
      s_severity="$(echo "${blob}" | grep "^\# Severity:" | awk '{print $3}')"
      s_classification="$(echo "${blob}" | grep "^\# Classification:" | awk '{print $3}')"
      s_stig_id="$(echo "${blob}" | grep "^\# STIG_ID:" | awk '{print $3}')"
      s_stig_ver="$(echo "${blob}" | grep "^\# STIG_Version:" | awk '{print $3}')"
      s_rule_ver="$(echo "${blob}" | grep "^\# Rule_ID:" | awk '{print $3}')"
      s_os="$(echo "${blob}" | grep "^\# OS:" | awk '{print $3}')"
      s_os_ver="$(echo "${blob}" | grep "^\# Version:" | awk '{print $3}')"
      s_title="$(echo "${blob}" | grep "^\# Title:" | sed "s|^# Title: \(.*\)$|\1|g")"
      s_description="$(echo "${blob}" | grep "^\# Description:" | sed "s|^# Description: \(.*\)$|\1|g")"

      # Making a change?
      if [ ${change:=0} -eq 1 ]; then
        echo "${path}/${file}"
        sed -i -e "s|^\(# Date: \).*$|\1${s_date}|g" \
            -e "s|^\(# Severity: \).*$|\1${s_severity}|g" \
            -e "s|^\(# Classificiation: \).*$|\1${s_severity}|g" \
            -e "s|^\(# STIG_ID: \).*$|\1${s_stig_id}|g" \
            -e "s|^\(# STIG_Ver: \).*$|\1${s_stig_ver}|g" \
            -e "s|^\(# Rule_ID: \).*$|\1${s_rule_ver}|g" \
            -e "s|^\(# OS: \).*$|\1${s_os}|g" \
            -e "s|^\(# Version: \).*$|\1${s_os_ver}|g" \
            -e "s|^\(# Title: \).*$|\1${s_title}|g" \
            -e "s|^\(# Description: \).*$|\1${s_description}|g" ${path}/${file}
        egrep '\# Date|\# Severity|\# Classification|\# STIG_|\# Rule|\# OS|\# Version|\# Title|\# Description' ${path}/${file}
      else
        echo "${path}/${file}"
        sed -i -e "s|^\(# Date: \).*$|\1${s_date}|g" \
            -e "s|^\(# Severity: \).*$|\1${s_severity}|g" \
            -e "s|^\(# Classificiation: \).*$|\1${s_severity}|g" \
            -e "s|^\(# STIG_ID: \).*$|\1${s_stig_id}|g" \
            -e "s|^\(# STIG_Ver: \).*$|\1${s_stig_ver}|g" \
            -e "s|^\(# Rule_ID: \).*$|\1${s_rule_ver}|g" \
            -e "s|^\(# OS: \).*$|\1${s_os}|g" \
            -e "s|^\(# Version: \).*$|\1${s_os_ver}|g" \
            -e "s|^\(# Title: \).*$|\1${s_title}|g" \
            -e "s|^\(# Description: \).*$|\1${s_description}|g" ${path}/${file} |
        egrep '\# Date|\# Severity|\# Classification|\# STIG_|\# Rule|\# OS|\# Version|\# Title|\# Description'
      fi
      echo
    fi
  fi
done
