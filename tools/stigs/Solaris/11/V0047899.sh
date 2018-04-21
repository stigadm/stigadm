#!/bin/bash


# Define an associative array of proc/mem/network limits per object
#  - Each value must be in the following format due to limitations in bash's associative arrays
#    Format: obj["user.name"]="projid:[int] comment:[text] users:[text,...,...] groups:[text,...,...] attribs:[text,...,...]"
#    Example: obj["user.name"]="projid:1 comment:a user users:user1,user2,user3 groups:group1,group2,group3 attribs:process.max-file-descriptor=(basic,131072,deny),process.max-shm-memory(privileged,934584254464,deny)
# For information regarding possible attributes please review the kernel options man page
declare -A obj
obj["dba"]="projid:104 comment: users: groups: attribs:"
obj["default"]="projid:3 comment: users: groups: attribs:"
obj["oinstall"]="projid:103 comment: users: groups: attribs:"
obj["noproject"]="projid:2 comment: users: groups: attribs:"
obj["system"]="projid:0 comment: users: groups: attribs:"
obj["user.oracle"]="projid:105 comment: users: groups: attribs:process.max-file-descriptor=(basic,65536,deny),process.max-sem-nsems=(privileged,1024,deny),process.max-sem-ops=(privileged,512,deny),project.max-msg-ids=(privileged,4096,deny),project.max-sem-ids=(privileged,65535,deny),project.max-shm-ids=(privileged,4096,deny),project.max-shm-memory=(privileged,934584254464,deny)"
obj["user.root"]="projid:1 comment: users: groups: attribs:"
obj["group.dba"]="projid:104 comment: users: groups: attribs:process.max-file-descriptor=(basic,131072,deny)"
obj["group.staff"]="projid:10 comment: users: groups: attribs:"
obj["group.oinstall"]="projid:101 comment: users: groups: attribs:process.max-file-descriptor=(basic,131072,deny)"
obj["group.root"]="projid:102 comment: users: groups: attribs:process.max-file-descriptor=(basic,131072,deny)"


# The configuration file used for the 'projects' tool
file=/etc/projects

# Attributes hive pattern
pattern="^([a-z]+).([a-z]+)=\(([a-z]+,[a-z]+,[a-z]+)\)?,"


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


# Make sure we have an author if we are not restoring or validating
if [[ "${author}" == "" ]] && [[ ${restore} -ne 1 ]] && [[ ${change} -eq 1 ]]; then
  usage "Must specify an author name (use -a <initials>)" && exit 1
fi


# If ${meta} is true
if [ ${meta} -eq 1 ]; then

  # Print meta data
  get_meta_data "${cwd}" "${prog}"
fi


print "Not yet implemented" && exit 0
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


# Make sure ${#obj[@]} != 0
if [ ${#obj[@]} -eq 0 ]; then
  usage "No profile options defined" && exit 1
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


# Iterate ${opts[@]}
for key in ${!opts[@]}; do

  # Print friendly message
  [ ${verbose} -eq 1 ] && print "Evaluating '${key}'"

  # Fudge ${opts[${key}]} from string into array
  IFS=" " read -p values <<< ${opts[${key}]}

  # Skip if empty
  if [ ${#values[@]} -eq 0 ]; then

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Empty value for '${key}', skipping"
    continue
  fi

  # Iterate ${values[@]}
  for item in ${values[@]}; do

    # Get defined project id
    projid="$(echo "${values[${items}]}" | awk -F: '$0 ~ /^projid/{print $2}')"

    # Get defined comment(s)
    comment="$(echo "${values[${items}]}" | awk -F: '$0 ~ /^comment/{print $2}')"

    # Get defined user(s)
    users="$(echo "${values[${items}]}" | awk -F: '$0 ~ /^users/{print $2}')"

    # Get defined groups(s)
    groups="$(echo "${values[${items}]}" | awk -F: '$0 ~ /^groups/{print $2}')"

    # Get defined attribute(s)
    attribs="$(echo "${values[${items}]}" | awk -F: '$0 ~ /^attribs/{print $2}')"

    # Do a quick validation on ${attribs} to determine if we can iteratively validate/change each hive.key=(rules)
    vals=($(echo "${attribs}" | gawk -v pat="${pattern}" '{if (match($0, pat, obj)){ if (obj[1] != "" ) {print obj[1]} if (obj[2] != "") {print [obj[2]} if (obj[3] != "") {print obj[3]}}}'))

    # If ${attribs} != "" & matches hive.key=(hive,value,rule)
    #if [[ "${attribs}" != "" ]] && [[ ]]; then
    #  print "Not yet implemented"
    #fi

    # Print friendly message
    [ ${verbose} -eq 1 ] && print "Empty value for '${key}', skipping"

    # Make changes if requested
    if [ ${check} -eq 1 ]; then

    fi
  done
done



fi

# Use the following for verbose error output
#[ ${verbose} -eq 1 ] && print "error output, notice the 1 =>" 1


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0

# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0047899
# STIG_Version: SV-60771r1
# Rule_ID: SOL-11.1-090280
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: The operating system must manage excess capacity, bandwidth, or other redundancy to limit the effects of information flooding types of denial of service attacks.
# Description: In the case of denial of service attacks, care must be taken when designing the operating system so as to ensure that the operating system makes the best use of system resources.

