#!/bin/bash

# Test value for integer type
function is_int()
{
  echo "${1}" | awk '{if($0 ~ /^[0-9.]+$/){print 1}else{print 0}}'
}


# Calculate kilobytes to bytes
function kb2b()
{
  echo "${1} * 1024" | bc 2>/dev/null
}


# Calculate mb2bytes to bytes
function mb2b()
{
  echo "${1} * 1024 * 1024" | bc 2>/dev/null
}


# Calculate gigabytes to bytes
function gb2b()
{
  echo "${1} * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# Calculate terrabytes to bytes
function tb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# Calculate petabytes to bytes
function pb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# Calculate bytes to kilobytes
function b2kb()
{
  echo "${1} / 1024" | bc 2>/dev/null
}


# Calculate bytes to megabytes
function b2mb()
{
  echo "${1} / 1024 / 1024" | bc 2>/dev/null
}


# Calculate bytes to gigabytes
function b2gb()
{
  echo "${1} / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# Calculate bytes to terrabytes
function b2tb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# Calculate bytes to petabytes
function b2pb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# Add integers
function add()
{
  echo "${1} + ${2}" | bc 2>/dev/null
}


# Subtract integers
function subtract()
{
  echo "${2} - ${1}" | bc 2>/dev/null
}


# Multiply integers
function multiply()
{
  echo "${1} + ${2}" | bc 2>/dev/null
}


# Divide integers
function divide()
{
  local scale=${3}

  echo "scale=${scale:=2}; ${1} / ${2}" |
    bc 2>/dev/null | grep -v "^divide"
}


# Return bytes based on % of total
function percent()
{
  local total=${1}
  local value=${2}
  local scale=${3}

  echo "scale=${scale:=2}; 100 * ${value} / ${total}" |
    bc 2>/dev/null | grep -v "^divide"
}


# Convert decimal to fraction
function dec2frac()
{
  local dec=${1}

  echo "${dec} / 1" | bc 2>/dev/null
}


# Convert binary to decimal
function bin2dec()
{
  printf '%d\n' "$(( 2#${1} ))"
}


# Convert hex to decimal
function hex2dec()
{
  printf '%d\n' "0x${1}"
}


# Convert decimal to binary for provided IPv4 octets
function dec2bin4octet()
{
  local -a octets=( ${@} )
  local -a bin=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
  local -a results

  # Iterate ${octets[@]}
  for octet in ${octets[@]}; do

    # Push ${bin[${octet}]} to ${results[@]}
    results+=("${bin[${octet}]}")
  done

  echo "${results[@]}"
}


# Bitwise OR calculator
function bitwise_or_calc()
{
  printf '%08X\n' "$(( 0x${1} | 0x${2} ))"
}


# Bitwise AND calculator
function bitwise_and_calc()
{
  one="$(echo "${1}" | nawk '{gsub(/\(|\)/, "", $0);print}')"
  two="$(echo "${1}" | nawk '{gsub(/\(|\)/, "", $0);print}')"
  printf '%08X\n' "$(( 0x${one} & 0x${two} ))"
}


# Bitwise XOR calculator
function bitwise_xor_calc()
{
  printf '%08X\n' "$(( 0x${1} ^ 0x${2} ))"
}


# POW
function pow()
{
  echo "${1} ^ ${2}" | bc
}


# Perform conversion from requested size to bytes
function tobytes()
{
  local type="${1}"
  local size=${2}
  local bytes=

  case "${type}" in
    K) bytes=$(kb2b ${size}) ;;
    M) bytes=$(mb2b ${size}) ;;
    G) bytes=$(gb2b ${size}) ;;
    P) bytes=$(pb2b ${size}) ;;
  esac

  echo ${bytes}
}


# Perform conversion from bytes to requested size
function frombytes()
{
  local type="${1}"
  local size=${2}
  local bytes=

  case "${type}" in
    K) bytes=$(b2kb ${size}) ;;
    M) bytes=$(b2mb ${size}) ;;
    G) bytes=$(b2gb ${size}) ;;
    P) bytes=$(b2pb ${size}) ;;
  esac

  echo ${bytes}
}


# Return number of characters found
function match_char_num()
{
  echo "${1}" | tr -cd "${2}" | wc -c | xargs
}
