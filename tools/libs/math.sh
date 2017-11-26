#!/bin/bash

# Calculate kilobytes to bytes
function kb2b()
{
  echo $(expr ${1} \* 1024)
}


# Calculate mb2bytes to bytes
function mb2b()
{
  echo $(expr ${1} \* 1024 \* 1024)
}


# Calculate gigabytes to MB
function gb2mb()
{
  echo $(expr ${1} \* 1024)
}


# Calculate gigabytes to KB
function gb2kb()
{
  echo $(expr ${1} \* 1024 \* 1024)
}


# Calculate gigabytes to bytes
function gb2b()
{
  echo $(expr ${1} \* 1024 \* 1024 \* 1024)
}


# Calculate kilobytes to MB
function kb2mb()
{
  echo $(expr ${1} / 1024)
}


# Calculate bytes to MB
function b2mb()
{
  echo $(expr ${1} / 1024 / 1024)
}


# Return bytes based on % of total
function percent()
{
  total=${1}
  percent=${2}

  echo $((${total} / 100 * ${percent}))
}
