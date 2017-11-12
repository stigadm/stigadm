#!/bin/bash

# Parse STIG XML into meta data

# Ensure path is robust
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Working directory
cwd="$(dirname $0)"

# Default output directory
output="${cwd}/output"

# Default template to add meta data to
template="${cwd}/template.sh"

# Create a timestamp
ts="$(date +%Y%m%d-%H%M%s)"


# Set variables
while getopts "f:o:t:" OPTION ; do
  case $OPTION in
    f) file=$OPTARG ;;
    t) template=$OPTARG ;;
    o) output=$OPTARG ;;
  esac
done


# Robot, do work


# Test ${file}
if [ ! -f ${file} ]; then
  echo "${file} does not exist or is not a file" && exit 1
fi


# Test ${template}
if [ ! -f ${template} ]; then
  echo "Default template file does not exist, bailing out"
fi


# Test ${output} directory
if [ ! -d ${output} ]; then
  mkdir -p ${output}
fi



# Define an array for all STIG documents
declare -a stigs

# Seek out all STIG XML documents
stigs=( $(find ${cwd} -type f -name "U_*-xccdf.xml" -ls | awk '{print $11}') )

# Bail if ${stigs[@]} is empty
if [ ${#stigs[@]} -eq 0 ]; then
  echo "Could not locate any DISA IASE STIG XML documents to process"
  exit 1
fi


# Iterate ${stigs[@]}
for stig in ${stigs[@]}; do

  # Extract directory name from ${stig}
  dir=$(dirname ${stig});

  # Extract & convert the ${stig} filename so we know it's been linted
  f=$(basename ${stig} | sed -e "s|.xml|-linted.xml|g");

  # Skip ${stig} if it has already been done (as referenced with ${dir}/${f}
  [ -f ${dir}/${f} ] && continue

  # LINT ${stig} as ${dir}/${f}
  xmllint --format ${stig} -o ${dir}/${f} 2>/dev/null
done


# Seek out all LINT'd STIG XML documents
stigs=( $(find ${cwd} -type f -name "U_*xccdf-linted.xml" -ls | awk '{print $11}') )

# Bail if ${stigs[@]} is empty
if [ ${#stigs[@]} -eq 0 ]; then
  echo "Could not locate any DISA IASE STIG XML (parseable) documents to process"
  exit 1
fi


# Iterate ${stigs[@]}
for stig in ${stigs[@]}; do

  # Extract directory name from ${stig}
  dir=$(dirname ${stig});

  # Extract & convert the ${stig} filename so we know it's been linted
  f=$(basename ${stig});

  # Acquire juicy bits from ${file} using our parser
  blobs=( $(awk -f ${cwd}/stig-parser.awk ${stig}) )

  # Skip if ${blob[@]} is empty
  [ ${#blobs[@]} -eq 0 ] && continue


  # Iterate ${blobs[@]}
  for blob in ${blobs[@]}; do

    # Since there are version discrepencies that affect formatting & column counts
    fields=$(echo "${blob}" | awk -F: '{print NF}')

    # Descision tree based on ${fields} count
    [ ${fields} -gt 10 ] && continue

    # Normal (modern) values
    if [ ${fields} -eq 9 ]; then


      # Aqcuire the STIG ID from ${blob}
      stigid="$(echo "${blob}" | cut -d: -f1)"

      # Aqcuire the category from ${blob}
      cat="$(echo "${blob}" | cut -d: -f2)"

      # Handle the effed up Oracle STIG item
      if [ $(echo "${cat}" | grep -ic "CAT") -eq 0 ]; then

        # Aqcuire the category from ${blob}
        cat="$(echo "${blob}" | cut -d: -f3)"

        # Aqcuire the STIG Version from ${blob}
        stigver="$(echo "${blob}" | cut -d: -f4)"

        # Aqcuire the rule id from ${blob}
        ruleid="$(echo "${blob}" | cut -d: -f5)"

        # Aqcuire the title from ${blob}
        title="$(echo "${blob}" | cut -d: -f6 | tr '~' ' ')"

        # Aqcuire the description from ${blob}
        description="$(echo "${blob}" | cut -d: -f7 | tr '~' ' ')"

        # Aqcuire the OS from ${blob}
        os="$(echo "${blob}" | cut -d: -f8)"

        # Aqcuire the version from ${blob}
        version="$(echo "${blob}" | cut -d: -f9)"

        # Aqcuire the arch from ${blob}
        arch="$(echo "${blob}" | cut -d: -f10)"
      else

        # Aqcuire the STIG Version from ${blob}
        stigver="$(echo "${blob}" | cut -d: -f3)"

        # Aqcuire the rule id from ${blob}
        ruleid="$(echo "${blob}" | cut -d: -f4 | tr '~' ' ')"

        # Aqcuire the title from ${blob}
        title="$(echo "${blob}" | cut -d: -f5 | tr '~' ' ')"

        # Aqcuire the description from ${blob}
        description="$(echo "${blob}" | cut -d: -f6 | tr '~' ' ')"

        # Aqcuire the OS from ${blob}
        os="$(echo "${blob}" | cut -d: -f7)"

        # Aqcuire the version from ${blob}
        version="$(echo "${blob}" | cut -d: -f8)"

        # Aqcuire the arch from ${blob}
        arch="$(echo "${blob}" | cut -d: -f9)"
      fi
    fi

    # Deal with older missing title values
    if [ ${fields} -eq 8 ]; then

      # Aqcuire the STIG ID from ${blob}
      stigid="$(echo "${blob}" | cut -d: -f1)"

      # Aqcuire the category from ${blob}
      cat="$(echo "${blob}" | cut -d: -f2)"

      # Aqcuire the STIG Version from ${blob}
      stigver="$(echo "${blob}" | cut -d: -f3)"

      # Aqcuire the rule id from ${blob}
      ruleid="$(echo "${blob}" | cut -d: -f4 | tr '~' ' ')"

      # Aqcuire the title from ${blob}
      title="${stigid}"

      # Aqcuire the description from ${blob}
      description="$(echo "${blob}" | cut -d: -f5 | tr '~' ' ')"

      # Aqcuire the OS from ${blob}
      os="$(echo "${blob}" | cut -d: -f6)"

      # Aqcuire the version from ${blob}
      version="$(echo "${blob}" | cut -d: -f7)"

      # Aqcuire the arch from ${blob}
      arch="$(echo "${blob}" | cut -d: -f8)"
    fi

    # Deal with older extra rule meta data
    if [ ${fields} -eq 10 ]; then

      # Aqcuire the STIG ID from ${blob}
      stigid="$(echo "${blob}" | cut -d: -f1)"

      # Aqcuire the category from ${blob}
      cat="$(echo "${blob}" | cut -d: -f3)"

      # Aqcuire the STIG Version from ${blob}
      stigver="$(echo "${blob}" | cut -d: -f4)"

      # Aqcuire the rule id from ${blob}
      ruleid="$(echo "${blob}" | cut -d: -f5)"

      # Aqcuire the title from ${blob}
      title="$(echo "${blob}" | cut -d: -f6 | tr '~' ' ')"

      # Aqcuire the description from ${blob}
      description="$(echo "${blob}" | cut -d: -f7 | tr '~' ' ')"

      # Aqcuire the OS from ${blob}
      os="$(echo "${blob}" | cut -d: -f8)"

      # Aqcuire the version from ${blob}
      version="$(echo "${blob}" | cut -d: -f9)"

      # Aqcuire the arch from ${blob}
      arch="$(echo "${blob}" | cut -d: -f10)"
    fi


    # Skip if ${os} or ${version} aren't right
    [ $(echo "${os}" | egrep -c 'AIX|HP-UX|Oracle|Red_Hat|Solaris') -eq 0 ] && continue


    # Create full path from ${output}, ${os} & ${version}
    full_path="${output}/${os}/${version}"

    # Test for combination of ${full_path}
    if [ ! -d ${full_path} ]; then
      mkdir -p ${full_path}
    fi


      cat <<EOF
# Output: ${full_path}
# File: ${full_path}/${stigid}.sh
#
# Severity: ${cat}
# Classification: UNCLASSIFIED
# STIG_ID: ${stigid}
# STIG_Version: ${stigver}
# Rule_ID: ${ruleid}
#
# OS: ${os}
# Version: ${version}
# Architecture: ${arch}
#
# Title: ${title}
# Description: ${description}

EOF


    # Test for existence of ${full_path}/${stigid}.sh
    if [ -f ${full_path}/${stigid}.sh ]; then

      # Try to replace meta data in ${full_path}/${stigid}.sh
      sed -e "s|^\(# Severity: \).*$|\1${cat}|g" \
          -e "s|^\(# Class: \).*$|\1UNCLASSIFIED|g" \
          -e "s|^\(# STIG_ID: \).*$|\1${stigid}|g" \
          -e "s|^\(# STIG_Version: \).*$|\1${stigver}|g" \
          -e "s|^\(# OS: \).*$|\1${os}|g" \
          -e "s|^\(# Version: \).*$|\1${version}|g" \
          -e "s|^\(# Architecture: \).*$|\1${arch}|g" \
          -e "s|^\(# Title: \).*$|\1${title}|g" \
          -e "s|^\(# Description: \).*$|\1${description}|g" ${full_path}/${stigid}.sh > ${full_path}/${stigid}-${ts}.sh

      # Copy ${full_path}/${stigid}-${ts}.sh into ${full_path}/${stigid}.sh
      mv -f ${full_path}/${stigid}-${ts}.sh ${full_path}/${stigid}.sh
    else

      # Copy ${template} to ${full_path}/${stigid}.sh
      cp -pf ${template} ${full_path}/${stigid}.sh

      # Add meta data to end of file
      cat <<EOF >> ${full_path}/${stigid}.sh

# Severity: ${cat}
# Classification: UNCLASSIFIED
# STIG_ID: ${stigid}
# STIG_Version: ${stigver}
# Rule_ID: ${ruleid}
#
# OS: ${os}
# Version: ${version}
# Architecture: ${arch}
#
# Title: ${title}
# Description: ${description}

EOF
    fi
  done
done
