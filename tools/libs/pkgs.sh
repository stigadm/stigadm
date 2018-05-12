#!/bin/bash


# Solaris package publisher function
function get_pkg_publishers()
{
  # Get locally scoped array of publishers
  local -a publishers=( $(pkg publisher 2>/dev/null | \
    awk 'NR > 1 && $3 == "online"{printf("%s\n", $5)}' | \
    cut -d/ -f3) )

  echo "${publishers[@]}"
}


# Function to parse package verify output for solaris
function parse_pkg_verify()
{
  # Re-assign ${1} to locally scoped ${blob}
  local blob="${1}"

  # Split ${blob} up into a digestable data structure
  #  <PKG-NAME>:<FILE>,<OWNER|GROUP|HASH|SIZE|MODE>,<ACTUAL>,<REQUIRED>+[...]
  pkgs=( $(echo "${blob}" | \
    sed "s|\(pkg:.*\)ERROR$|=\1|g" | tr '=' '\n' | \
    sed "s|file: \(.*\)$|/\1,|g" | \
    sed "s|dir: \(.*\)$|/\1,|g" | \
    sed "s|ERROR:||g" | \
    sed "s|\([Owner|Group]\): '\(.*\) .*'.*'\(.*\) .*$|\1,\2,\3+|g" | \
    sed "s|\([Hash|Size]\): \(.*\) should.*be \(.*\)$|\1,\2,\3+|g" | \
    sed "s| bytes||g" | \
    awk '{$1=$1;print}' | tr '\n' ':' | \
    nawk '{gsub(/::/, " ", $0);gsub(/\+:/, "+", $0);gsub(/,:/, ",", $0);print}') )

  # Return error if nothing parsed
  [ ${#pkgs[@]} -eq 0 ] && (echo 1 && return 1)

  # Spit out our array & exit with 0
  echo "${pkgs[@]}" && return 0
}


# Package verify helper
#  Does determination on actual findings when false positives exist
#  in output from `pkg verify`
function verify_pkgs()
{
  # Re-assign ${@} to locally scoped ${pkgs[@]} array
  local -a pkgs=( ${@} )
  local -a error=()

  # Bail if ${pkgs[@]} is empty
  [ ${#pkgs[@]} -eq 0 ] && (echo 1 && return 1)

  # Iterate ${pkgs[@]}
  for pkg in ${pkgs[@]}; do

    # Ensure we are filtering for garbage in ${pkgs[@]} first
    res=$(echo "${pkg}" | awk '$0 ~ /pkg:/{print 1}' 2>/dev/null)
    [ ${res:=0} -eq 0 ] && continue

    # Split up ${pkg} into an initial array
    array=( $(echo "${pkg}" | tr ':' ' ') )

    # Re-assign our actual package FMRI to ${pkg}
    pkg="${array[0]}:${array[1]}"

    # Break up element 2 into an array of inodes
    inodes=( $(echo "${array[2]}" | tr '+' ' ') )

    # Bail if empty
    [ ${#inodes[@]} -eq 0 ] && (echo 1 && return 1)

    # 
  done
}
