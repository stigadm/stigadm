#!/bin/bash

# Define an array of booleans
declare -a booleans
booleans=("True" "False")

# Convert ${booleans@]} into a string
booleans_str="$(echo "${booleans[@]}" | tr ' ' '|')"


# Handle user selection for OS
function select_os()
{
  # Use $1 as our path
  local path="${1}"

  # Gather list of available supported OS's
  local -a os_list
  os_list=( $(get_os 1 ${path}) )

  # If ${#os_list[@]} = 0 abort
  if [ ${#os_list[@]} -eq 0 ]; then
    print "  Could not determine a valid list of target Operating Systems, aborting" 1
    return 1
  fi

  # Convert ${os_list[@]} into a string
  local os_list_str="$(echo "${os_list[@]}" | tr ' ' '|')"

  # Force selection of OS target
  while [ $(in_array "${os}" "${os_list[@]}") -eq 1 ]; do
    echo $(in_array "${os}" "${os_list[@]}")
    read -p "  Target OS [${os_list_str}]: " os
  done

  # Ask about new boot environment if solaris
  if [ $(to_lower "${os}" | grep -c 'solaris') -gt 0 ]; then

    while [ $(in_array "${bootenv}" "${booleans[@]}") -eq 1 ]; do
      read -p "  Use new boot environment [${booleans_str}]: " bootenv
      bootenv="${bootenv:=False}"
    done

    # Since we expect an integer later
    [ "$(to_lower "${bootenv}")" == "true" ] && bootenv=1
    [ "$(to_lower "${bootenv}")" == "false" ] && bootenv=0
  fi
}


# Handle user selection for version (based on previous OS selection)
function select_version()
{
  # Use $1 as our path
  local path="${1}"

  # Gather list of available supported versions (non-os dependent)
  local -a version_list
  version_list=( $(get_version 1 ${path}) )

  # Convert ${version_list[@]} into a string
  local version_list_str="$(echo "${version_list[@]}" | tr ' ' '|')"

  # Force selection of OS version
  while [ $(in_array "${version}" "${version_list[@]}") -eq 1 ]; do
    read -p "  OS Version [${version_list_str}]: " version
  done
}


# Handle optional category/severity selection
function select_classification()
{
  # Use $1 as our path
  local path="${1}"

  # Gather list of available supported severity (non-os dependent)
  local -a classification_list
  classification_list=( "ALL" $(get_classification 1 ${path}) )

  # Convert ${version_list[@]} into a string
  local classification_list_str="$(echo "${classification_list[@]}" | tr ' ' '|')"

  # Optional selection of severity level(s)
  while [ $(in_array "${classification}" "${classification_list[@]}") -eq 1 ]; do
    read -p "  Severity [${classification_list_str}]: " classification
    classification="${classification:=False}"
  done
}


# Handle selection mode for stig module(s)
function select_modules()
{
  # Use provided args as filters
  local path="${1}"
  local os="${2}"
  local version="${3}"
  local classification="${4}"

  # Define a local array of return modules
  local -a selected

  # Obtain an array of modules based on args
  local -a modules
  modules=( $(find ${path}/${os}/${verson} -type f -name "*.sh" -grep -il "${classificiation}" {} +) )

  # Return 1 if ${#modules[@]} == 0
  [ ${#modules[@]} -eq 0 ] && return 0

  # Add 'All' wildcard option & 'Done' elements to ${modules[@]} array
  modules+=('All' 'Done')

  # Define PS3
  PS3="Select module(s): "

  # Create menu
  select ${file} in ${modules[@]}; do

    # Handle results selected for ${file}
    case ${file} in
      'All')
        selected=("*")
        break ;;
      'Done')
        break ;;
      *)
        selected+=("${file}")
        ;;
    esac
  done

  # Return ${selected[@]}
  echo "$(remove_duplicates "${selected[@]}")"
}


# Handle the run mode; validation (default) or change
function select_mode()
{
  # Define some default modes
  local -a modes
  modes=("Change" "Validate" "Restore")

  # Convert ${modes[@]} into a string
  local modes_str="$(echo "${modes[@]}" | tr ' ' '|')"

  # Make sure the selection is valid
  while [ $(in_array "${mode}" "${modes[@]}") -eq 1 ]; do
    read -p "  Mode [${modes_str}]: " mode
    mode="${mode:=Validate}"
  done

  # Since we expect an integer later
  [ "${mode}" == "Change" ] && change=1
  [ "${mode}" == "Restore" ] && restore=1

  # If ${change} = 1 make sure the user provides an author value
  if [ ${change} -ne 0 ]; then
    while [ "${author}" == "" ]; do
      read -p "  Author Initials (Required for changes): " author
    done
  fi

  # If ${restore} = 1 ask about interactive mode
  if [ ${restore} -eq 1 ]; then

    # Make sure user is prompted for the optional interactive mode
    while [ $(in_array "${interactive}" "${booleans[@]}") -eq 1 ]; do
      read -p "  Interactive Mode [${booleans_str}]: " interactive
      interactive="${interactive:=Validate}"
    done

    # Since we expect an integer later
    [ "$(to_lower "${interactive}")" == "true" ] && interactive=1
  fi
}


# Handle additional run options; debug, verbosity etc
function set_options()
{
  # Make sure user is prompted for the verbosity option
  while [ $(in_array "${verbose}" "${booleans[@]}") -eq 1 ]; do
    read -p "  Enable verbosity [${booleans_str}]: " verbose
    [ "${verbose}" == "" ] && verbose="False"
  done

  # Since we expect an integer later
  [ "$(to_lower "${verbose}")" == "true" ] && verbose=1
  [ "$(to_lower "${verbose}")" == "false" ] && verbose=0


  # Make sure user is prompted for the debug option
  while [ $(in_array "${debug}" "${booleans[@]}") -eq 1 ]; do
    read -p "  Enable debug [${booleans_str}]: " debug
    debug="${debug:False}"
  done

  # Since we expect an integer later
  [ "$(to_lower "${debug}")" == "true" ] && debug=1
  [ "$(to_lower "${debug}")" == "false" ] && debug=0
}


# Function to walk the user through usage
function wizard()
{
  # Use $1 as our path
  local path="${1}"

  # Be nice & friendly
  echo "[${appname}]: Wizard mode for ${appname}"

  # Make sure ${path} is a directory
  if [ ! -d ${path} ]; then
    print "  Supplied path; ${path}, does not exist. Aborting." 1
    return 1
  fi

  # Get value for globally scoped ${os} & new value for ${path}
  select_os "${path}"

  # Get value for globally scoped ${version} & new value for ${path}
  select_version "${path}/${os}"

  # Get value for globally scoped ${classification}
  select_classification "${path}/${os}/${version}"

  # Select modules to apply
  stigs=( $(select_modules "${path}" "${os}" "${version}" "${classification}") )

  # Get globally scoped mode; i.e. validate, change or restore
  select_mode

  # Set globally scoped options; i.e. verbosity, debug etc
  set_options

  return 0
}
