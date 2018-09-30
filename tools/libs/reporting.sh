#!/bin/bash

# Print a single line
# Arguments:
#  log [String]: Log file & path
#  key [String]: Index value
#  value [String]: Value of index
function print_line()
{
  # Capture arg list to an array
  local -a obj=("${@}")

  # Re-assign elements
  local log="${obj[0]}"
  local key="${obj[1]}"

  # Capture the remaining elements to a string
  local value="${obj[@]:2}"

  # Generate a log name
  local ext="$(basename ${log} | cut -d. -f2)"

  if [ "${ext}" == "json" ]; then
    echo "      ${key}: \"${value}\"," >> ${log}
  else
    echo "        <${key}>${value}</${key}>" >> ${log}
  fi
}


# Print an array
# Arguments:
#  log [String]: Log file & path
#  key [String]: Index value
#  values [Array]: Array of values
function print_array()
{
  # Capture arg list to an array
  local -a obj=("${@}")

  # Re-assign elements
  local log="${obj[0]}"
  local key="${obj[1]}"

  # Capture the remaining elements as an array
  local -a values=( ${obj[@]:2} )

  # Generate a log name
  local ext="$(basename ${log} | cut -d. -f2)"

  # Create a header for the JSON/XML array
  if [ "${ext}" == "json" ]; then
    echo "    ${key}: [" >> ${log}
  else
    echo "      <${key}>" >> ${log}
  fi

  # Iterate the array
  for value in ${values[@]}; do
    if [ "${ext}" == "json" ]; then
      echo "      \"$(echo "${value}" | tr ':' ' ')\"" >> ${log}
    else
      echo "        <item>$(echo "${value}" | tr ':' ' ')</item>" >> ${log}
    fi
  done

  # Close out the JSON/XML array
  if [ "${ext}" == "json" ]; then
    echo "    ]," >> ${log}
  else
    echo "      </${key}>" >> ${log}
  fi
}


# Handle printing module header
function module_header()
{
  local results="${@}"

  # Capture the STIG module template to ${report}
  local header="$(cat ${module_header})"

  # Apply the meta data & report specifics
  header="$(echo "${header}" |
    sed "s|{STIGID}|${stigid}|g" |
    sed "s|{TITLE}|$(echo "${meta[8]}" | tr '_' ' ')|g" |
    sed "s|{DESCRIPTION}|$(echo "${meta[9]}" | tr '_' ' ')|g" |
    sed "s|{RELEASE_DATE}|${meta[0]}|g" |
    sed "s|{RULEID}|${meta[5]}|g" |
    sed "s|{STIGVER}|${meta[4]}|g" |
    sed "s|{SEVERITY}|${meta[1]}|g" |
    sed "s|{CLASSIFICATION}|${meta[2]}|g" |
    sed "s|{RESULTS}|${results}|g")"

  # Send everything to the ${log}
  cat <<EOF >> ${log}
${header}
EOF
}


# Handle printing module footer
function module_footer()
{
  local results="${@}"

  # Capture the STIG module template to ${report}
  local footer="$(cat ${module_footer})"

  # Capture the end time
  local e_epoch="$(gen_epoch)"

  # Determine miliseconds from start
  local seconds=$(subtract ${s_epoch} ${e_epoch})

  # Generate a run time
  local run_time
  [ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."

  footer="$(echo "${footer}" |
    sed "s|{START}|${s_epoch}|g" |
    sed "s|{END}|${e_epoch}|g" |
    sed "s|{ELAPSED}|${run_time}|g")"

  # Send everything to the ${log}
  cat <<EOF >> ${log}
${footer}
EOF
}


# Handle printing stigadm report
function report_header()
{
  local report="$(cat ${report_header})"

  # Apply the meta data & report specifics
  report="$(echo "${report}" |
    sed "s|{DATE}|${timestamp}|g" |
    sed "s|{HOST}|$(hostname)|g" |
    sed "s|{KERNEL}|$(uname -a)|g" |
    sed "s|{OS}|${os}|g" |
    sed "s|{OSVER}|${version}|g")"

  echo "${report}" > ${log}
}


# Handle printing stigadm report
function report_footer()
{
  local report="$(cat ${report_footer})"

  # Capture the end time
  local e_epoch="$(gen_epoch)"

  # Determine miliseconds from start
  local seconds=$(subtract ${s_epoch} ${e_epoch})

  # Generate a run time
  local run_time
  [ ${seconds} -gt 60 ] && run_time="$(divide ${seconds} 60) Min." || run_time="${seconds} Sec."

  # Apply the meta data & report specifics
  report="$(echo "${report}" |
    sed "s|{STIGS}|${total_stigs}|g" |
    sed "s|{MODULES}|${#stigs[@]}|g" |
    sed "s|{PASSED}|${passed}|g" |
    sed "s|{FAILED}|${failed}|g" |
    sed "s|{RATE}|${percentage:=0}|g" |
    sed "s|{START}|${s_epoch}|g" |
    sed "s|{END}|${e_epoch}|g" |
    sed "s|{ELAPSED}|${run_time}|g")"

  echo "${report}" >> ${log}
}


# Act as interface to module/general report
function report()
{
  local results="${@}"

  # If ${caller} = 0
  if [ ${caller} -eq 0 ]; then

    # Apply some values expected for general report
    stigs=("${stigid}")
    total_stigs=${#stigs[@]}

    # Generate the primary report header
    report_header
  fi

  module_header "${results[@]}"
  module_footer

  # If ${caller} = 0
  if [ ${caller} -eq 0 ]; then

    # Generate the primary report header
    report_footer
  fi

}
