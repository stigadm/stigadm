#!/bin/bash

# @file tools/libs/math.sh
# @brief Various calculations

# @description Test for integer
#
# @arg ${1} Integer
#
# @stdout Integer
#
# @return 1 Success
# @return 0 Error
function is_int()
{
  local res=$(echo "${1}" | awk '{if($0 ~ /^[0-9.]+$/){print 1}else{print 0}}')
  echo ${res} && return ${res}
}


# @description Kilobytes to bytes
#
# @arg ${1} Integer
#
# @stdout Integer
function kb2b()
{
  echo "${1} * 1024" | bc 2>/dev/null
}


# @description Megabytes to bytes
#
# @arg ${1} Integer
#
# @stdout Integer
function mb2b()
{
  echo "${1} * 1024 * 1024" | bc 2>/dev/null
}


# @description Gigabytes to bytes
#
# @arg ${1} Integer
#
# @stdout Integer
function gb2b()
{
  echo "${1} * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# @description Terabytes to bytes
#
# @arg ${1} Integer
#
# @stdout Integer
function tb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# @description Petabytes to bytes
#
# @arg ${1} Integer
#
# @stdout Integer
function pb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024 * 1024" | bc 2>/dev/null
}


# @description Bytes to kilobytes
#
# @arg ${1} Integer
#
# @stdout Integer
function b2kb()
{
  echo "${1} / 1024" | bc 2>/dev/null
}


# @description Bytes to megabytes
#
# @arg ${1} Integer
#
# @stdout Integer
function b2mb()
{
  echo "${1} / 1024 / 1024" | bc 2>/dev/null
}


# @description Bytes to gigabytes
#
# @arg ${1} Integer
#
# @stdout Integer
function b2gb()
{
  echo "${1} / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# @description Bytes to terabytes
#
# @arg ${1} Integer
#
# @stdout Integer
function b2tb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# @description Bytes to petabytes
#
# @arg ${1} Integer
#
# @stdout Integer
function b2pb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024 / 1024" | bc 2>/dev/null
}


# @description Addition
#
# @arg ${1} Integer
# @arg ${2} Integer
#
# @stdout Integer
function add()
{
  echo "${1} + ${2}" | bc 2>/dev/null
}


# @description Subtraction
#
# @arg ${1} Integer
# @arg ${2} Integer
#
# @stdout Integer
function subtract()
{
  echo "${2} - ${1}" | bc 2>/dev/null
}


# @description Multiplication
#
# @arg ${1} Integer
# @arg ${2} Integer
#
# @stdout Integer
function multiply()
{
  echo "${1} + ${2}" | bc 2>/dev/null
}


# @description Divide
#
# @arg ${1} Integer
# @arg ${2} Integer
# @arg ${3} Integer Rounding
#
# @stdout Integer
function divide()
{
  local scale=${3}

  echo "scale=${scale:=2}; ${1} / ${2}" |
    bc 2>/dev/null | grep -v "^divide"
}


# @description Percentage
#
# @arg ${1} Integer
# @arg ${2} Integer
# @arg ${3} Integer Rounding
#
# @stdout Integer
function percent()
{
  local total=${1}
  local value=${2}
  local scale=${3}

  echo "scale=${scale:=2}; 100 * ${value} / ${total}" |
    bc 2>/dev/null | grep -v "^divide"
}


# @description Decimal to fraction
#
# @arg ${1} Integer
#
# @stdout Integer
function dec2frac()
{
  local dec=${1}

  echo "${dec} / 1" | bc 2>/dev/null
}


# @description Binary to decimal
#
# @arg ${1} Integer
#
# @stdout Integer
function bin2dec()
{
  printf '%d\n' "$(( 2#${1} ))"
}


# @description Hex to decimal
#
# @arg ${1} Integer
#
# @stdout Integer
function hex2dec()
{
  printf '%d\n' "0x${1}"
}


# @description Convert decimal to binary for provided IPv4 octets
#
# @arg ${1} Integer
# @arg ${2} Integer
# @arg ${3} Integer Rounding
#
# @stdout Integer
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
