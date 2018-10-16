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
ts=$(date +%Y%m%d-%H%M)


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

# Define an array for all STIG modules
declare -a stig_modules


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


    # Get the STIG accepted date
    stigdate="$(echo "${blob}" | cut -d: -f1)"

    # Skip if ${stigdate} is not a valid date
    if [ $(echo "${stigdate}" | awk '{if($0 !~ /^[0-9]+-[0-9]+-[0-9]+$/){print 1}else{print 0}}') -eq 1 ]; then
      continue
    fi


    # Cut out the STIG ID
    stigid="$(echo "${blob}" | cut -d: -f2)"

    # Skip if ${stigid} is not a valid STIG ID
    if [ $(echo "${stigid}" | awk '{if($0 !~ /^V[0-9]+$/){print 1}else{print 0}}') -eq 1 ]; then
      continue
    fi


    # Cut out the category/classification of STIG ID
    cat="$(echo "${blob}" | cut -d: -f3)"

    # Fix ${blob} if the ${cat} isn't right & cut again
    if [ $(echo "${cat}" | awk '{if($0 !~ /^CAT-.*$/){print 1}else{print 0}}') -eq 1 ]; then

      blob="$(echo "${blob}" | sed -e "s|\(.*:\)$(echo "${blob}" | cut -d: -f3):\(.*\)|\1\2|g")"

      # Cut out the category/classification of STIG ID
      cat="$(echo "${blob}" | cut -d: -f3)"
    fi


    # Cut out the STIG version from ${blob}
    stigver="$(echo "${blob}" | cut -d: -f4)"

    # Skip if ${stigid} is not a valid STIG version
    if [ $(echo "${stigver}" | awk '{if($0 !~ /^SV-/){print 1}else{print 0}}') -eq 1 ]; then
      continue
    fi

    # Cut out the Rule ID from ${blob}
    ruleid="$(echo "${blob}" | cut -d: -f5)"

    # Make sure we got something
    if [ "${ruleid}" == "" ]; then
      continue
    fi


    # Cut out the ${title} from ${blob}
    title="$(echo "${blob}" | cut -d: -f6 | tr '~' ' ')"

    # Make sure we got something
    if [ "${title}" == "" ]; then
      continue
    fi


    # Cut out the ${description} from ${blob}
    description="$(echo "${blob}" | cut -d: -f7 | tr '~' ' ')"

    # If ${description} matches an OS use ${title} as the ${description}
    if [ $(echo "${description}" | egrep -c 'AIX|HP-UX|Oracle|Red_Hat|Solaris|Ubuntu') -eq 1 ]; then
      description="${title}"
    fi

    # Make sure we got something
    if [ "${description}" == "" ]; then
      continue
    fi

    # Set the ${os} from ${blob}
    os="$(echo "${blob}" | cut -d: -f8)"
    col=9

    # If ${os} doesn't matche an OS use column 7
    if [ $(echo "${os}" | egrep -c 'AIX|HP-UX|Oracle|Red_Hat|Solaris|Ubuntu') -eq 0 ]; then

      # Set the ${os} from ${blob}
      os="$(echo "${blob}" | cut -d: -f7)"
      col=8
    fi

    # Skip if ${os} or ${version} aren't right
    [ $(echo "${os}" | egrep -c 'AIX|HP-UX|Oracle|Red_Hat|Solaris|Ubuntu') -eq 0 ] && continue


    # Get the OS version from ${blob}
    version="$(echo "${blob}" | cut -d: -f${col})"

    # Skip if ${version} isn't a number
    [ $(echo "${version}" | awk '{if($0 !~ /^[0-9]+/){print 1}else{print 0}}') -eq 1 ] && continue

    # Get the architecture if it exists
    arch="$(echo "${blob}" | cut -d: -f$(( ${col} + 1)))"


    # Add ${stigid} to ${stig_modules[@]} array
    stig_modules+=("${f}:${cat}:${stigid}:${stigver}:${ruleid}:${os}:${version}")

    # Create full path from ${output}, ${os} & ${version}
    full_path="${output}/${os}/${version}"

    # Test for combination of ${full_path}
    if [ ! -d ${full_path} ]; then
      mkdir -p ${full_path}
    fi


      cat <<EOF
STIG Module meta data details
Blob: $(echo "${blob}" | awk -F: '{print NF}') ${blob}
Output: ${full_path}
File: ${full_path}/${stigid}.sh

Date: ${stigdate}

Severity: ${cat}
Classification: UNCLASSIFIED
STIG_ID: ${stigid}
STIG_Version: ${stigver}
Rule_ID: ${ruleid}

OS: ${os}
Version: ${version}
Architecture: ${arch}

Title: ${title}
Description: ${description}

EOF


    # Test for existence of ${full_path}/${stigid}.sh
    if [ -f ${full_path}/${stigid}.sh ]; then

      # Get a 'blob' of current meta data (if any)
      blob="$(sed -n '/^# Severity/,/^# Description/p' ${full_path}/${stigid}.sh)"

      # If 12 lines returned per ${blob} assume all necessary meta data exists
      if [ $(echo "${blob}" | wc -l | awk '{print $1}') -eq 12 ]; then

        # Try to replace meta data in ${full_path}/${stigid}.sh
        sed -e "s|^\(# Date: \).*$|\1${stigdate}|g" \
            -e "s|^\(# Severity: \).*$|\1${cat}|g" \
            -e "s|^\(# Class: \).*$|\1UNCLASSIFIED|g" \
            -e "s|^\(# STIG_ID: \).*$|\1${stigid}|g" \
            -e "s|^\(# STIG_Version: \).*$|\1${stigver}|g" \
            -e "s|^\(# OS: \).*$|\1${os}|g" \
            -e "s|^\(# Version: \).*$|\1${version}|g" \
            -e "s|^\(# Architecture:.* \)$|\1${arch}|g" \
            -e "s|^\(# Title: \).*$|\1${title}|g" \
            -e "s|^\(# Description: \).*$|\1${description}|g" ${full_path}/${stigid}.sh > ${full_path}/${stigid}-${ts}.sh

        # Copy ${full_path}/${stigid}-${ts}.sh into ${full_path}/${stigid}.sh
        mv -f ${full_path}/${stigid}-${ts}.sh ${full_path}/${stigid}.sh
      else

        # Add meta data to end of file
        cat <<EOF >> ${full_path}/${stigid}.sh

# Date: ${stigdate}
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
      fi
    else

      # Copy ${template} to ${full_path}/${stigid}.sh
      cp -pf ${template} ${full_path}/${stigid}.sh

      # Add meta data to end of file
      cat <<EOF >> ${full_path}/${stigid}.sh

# Date: ${stigdate}
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
    fi

    # Set permission(s)
    chmod 00601 ${full_path}/${stigid}.sh
    chown root:root ${full_path}/${stigid}.sh
  done
done


# Print a summary of processing
# ${f}:${cat}:${stigid}:${stigver}:${ruleid}:${os}:${version}
cat <<EOF

STIG parsing summary

STIG file(s): ${#stigs[@]}
STIG ID(s): $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f3 | sort -u | wc -l)/$(echo "${blobs[@]}" | tr ' ' '\n' | cut -d: -f2 | wc -l)
STIG ID Versions: $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f4 | sort -u | wc -l)

STIG Rule(s): $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f5 | sort -u | wc -l)
STIG Category(s): $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f2 | sort -u | wc -l)

Operating System(s) details
OS: $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f6 | sort -u | wc -l)
$(for os in $(echo "${stig_modules[@]}" | tr ' ' '\n' | cut -d: -f6 | sort -u); do echo "  ${os}"; for ver in $(echo "${stig_modules[@]}" | tr ' ' '\n' | grep "${os}" | cut -d: -f7 | sort -u); do echo "   ${ver}: $(echo "${stig_modules[@]}" | tr ' ' '\n' | grep "${os}" | grep "${ver}" | cut -d: -f3 | sort -u | wc -l)"; done; done)

EOF
