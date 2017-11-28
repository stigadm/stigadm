#!/bin/bash

# Test value for integer type
function is_int()
{
  echo "${1}" | awk '{if($0 ~ /^[0-9.]+$/){print 1}else{print 0}}'
}

# Calculate kilobytes to bytes
function kb2b()
{
  echo "${1} * 1024" | bc
}


# Calculate mb2bytes to bytes
function mb2b()
{
  echo "${1} * 1024 * 1024" | bc
}


# Calculate gigabytes to bytes
function gb2b()
{
  echo "${1} * 1024 * 1024 * 1024" | bc
}


# Calculate terrabytes to bytes
function tb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024" | bc
}


# Calculate petabytes to bytes
function pb2b()
{
  echo "${1} * 1024 * 1024 * 1024 * 1024 * 1024" | bc
}


# Calculate bytes to kilobytes
function b2kb()
{
  echo "${1} / 1024" | bc
}


# Calculate bytes to megabytes
function b2mb()
{
  echo "${1} / 1024 / 1024" | bc
}


# Calculate bytes to gigabytes
function b2gb()
{
  echo "${1} / 1024 / 1024 / 1024" | bc
}


# Calculate bytes to terrabytes
function b2tb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024" | bc
}


# Calculate bytes to petabytes
function b2pb()
{
  echo "${1} / 1024 / 1024 / 1024 / 1024 / 1024" | bc
}


# Return bytes based on % of total
function percent()
{
  total=${1}
  percent=${2}

  echo "${total} / 100 * ${percent}" | bc
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
