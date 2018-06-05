#!/bin/bash

# Handle printing module reports
function stig_module_report()
{
  local results="${@}"

  # Capture the STIG module template to ${report}
  local report="$(cat ${report_module})"

  # Apply the meta data & report specifics
  report="$(echo "${report}" |
    sed "s|{STIGID}|${stigid}|g" |
    sed "s|{TITLE}|$( echo "${meta[8]}" | tr '_' ' ')|g" |
    sed "s|{DESCRIPTION}|$( echo "${meta[9]}" | tr '_' ' ')|g" |
    sed "s|{RELEASE_DATE}|${meta[0]}|g" |
    sed "s|{RULEID}|${meta[5]}|g" |
    sed "s|{STIGVER}|${meta[4]}|g" |
    sed "s|{SEVERITY}|${meta[1]}|g" |
    sed "s|{CLASSIFICATION}|${meta[2]}|g" |
    sed "s|{RESULTS}|${results}|g" |
    sed "s|{START}|${s_epoch}|g" |
    sed "s|{END}|${e_epoch}|g" |
    sed "s|{ELAPSED}|${run_time}|g")"

  echo "${report}"
}


# Handle printing stigadm report
function report()
{
  local report="$(cat ${stigadm_report})"

  # Apply the meta data & report specifics
  report="$(echo "${report}" |
    sed "s|{DATE}|${timestamp}|g" |
    sed "s|{REPORT}|$(hostname)|g" |
    sed "s|{DETAIL}||g" |
    sed "s|{OS}|${os}|g" |
    sed "s|{OSVER}|${version}|g" |
    sed "s|{STIGS}|${total_stigs}|g" |
    sed "s|{MODULES}|${#stigs[@]}|g" |
    sed "s|{START}|${s_epoch}|g" |
    sed "s|{END}|${e_epoch}|g" |
    sed "s|{ELAPSED}|${run_time}|g")"

  echo "${report}"
}
