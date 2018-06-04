#!/bin/bash

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


# Make sure we are operating on global zones
if [ "$(zonename)" != "global" ]; then
  usage "${stigid} only applies to global zones" && exit 1
fi


# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"


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


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Create backup of file(s), settings or permissions on inodes
  # (see existing facilities in ${lib_path}/backup.sh)

  # Make change according to ${stigid}
  [ ${verbose} -eq 1 ] && print "Make change here"
fi


# Validate change according to ${stigid}


# Exit 1 if validation failed


# Print friendly success
[ ${verbose} -eq 1 ] && print "Success, conforms to '${stigid}'"

exit 0
