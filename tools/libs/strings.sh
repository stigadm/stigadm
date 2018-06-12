#!/bin/bash

# Convert string to upper case
function to_upper()
{
  echo "${1}" | nawk '{print toupper($0)}'
}


# Convert string to lower case
function to_lower()
{
  echo "${1}" | nawk '{print tolower($0)}'
}