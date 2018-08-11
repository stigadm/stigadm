#!/bin/bash

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
  local args=( ${@} )

  # Re-assign local in scope from ${args[@]}
  local caller="${args[0]}"


  # If ${caller} = 0
  if [ ${caller} -eq 0 ]; then

    # Apply some values expected for general report
    stigs=("${stigid}")
    total_stigs=${#stigs[@]}

    # Generate the primary report header
    report_header
  fi

}
