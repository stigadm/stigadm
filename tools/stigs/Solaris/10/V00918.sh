#!/bin/bash


# Define a minimum days range for locked accounts
min_days=35

# UID minimum as exclusionary for system/service accounts
uid_min=100

# User exceptions (UID or name)
declare -a exceptions
exceptions+=("nobody")
exceptions+=("nobody4")
exceptions+=("noaccess")
exceptions+=("acas")


###############################################
# Bootstrapping environment setup
###############################################

# Get our working directory
cwd="$(pwd)"

# Define our bootstrapper location
bootstrap="${cwd}/tools/bootstrap.sh"

# Bail if it cannot be found
if [ ! -f ${bootstrap} ]; then
  echo "Unable to locate bootstrap; ${bootstrap}" && exit 1
fi

# Load our bootstrap
source ${bootstrap}


###############################################
# Metrics start
###############################################

# Get EPOCH
s_epoch="$(gen_epoch)"

# Create a timestamp
timestamp="$(gen_date)"

# Whos is calling? 0 = singular, 1 is from stigadm
caller=$(ps -p $PPID | grep -c stigadm)


###############################################
# STIG validation/remediation/restoration
###############################################

# Create an exclude pattern from ${exceptions[@]}
pattern="$(echo "${exceptions[@]}" | tr ' ' '|')"

# Get current list of users (greater than ${uid_min} & excluding ${exceptions[@]})
user_list=($(getent passwd | egrep -v ${pattern} |
  nawk -F: -v min="${uid_min}" '$3 >= min{print $1}' 2>/dev/null))

# Iterate ${user_list[@]}
for act in ${user_list[@]}; do

  # Get array of login history (ignores system accounts, removes dupes & ignores all but last login per user)
  logins=($(last ${act} 2>/dev/null |
    nawk '{print $1":"$5":"$6}' 2>/dev/null | head -1))
done


# Set current day, month and year
cday=$(date +%d | sed "s/^0//g")
cmonth=$(date +%m)
cyear=$(date +%Y)

# Get the current day of year (Current Julian Day Of Year)
cjdoy=$(conv_date_to_jdoy ${cday} ${cmonth} ${cyear})


# Iterate ${logins[@]}
for lgn in ${logins[@]}; do

  # Set ${user} from ${lgn}
  user="$(echo "${lgn}" | cut -d: -f1)"

  # Convert ${month} to integer from ${lgn}
  month="$(month_to_int $(echo "${lgn}" | cut -d: -f2))"

  # Set ${day} from ${lgn}
  day="$(echo "${lgn}" | cut -d: -f3)"

  # Set ${year} to current year or if ${month} and ${day} > today use last year
  [ ${month} -gt ${cmonth} ] &&
    year=$(subtract 1 ${cyear}) || year=${cyear}

  # Get the Julian Date from ${day}, ${month}, ${year}
  ucjdoy=$(conv_date_to_jdoy ${day} ${month} ${year})

  # If ${user} has a ${ucjdoy} > ${min_days} when compared with ${cjdoy} flag
  [ $(compare_jdoy_dates ${cjdoy} ${ucjdoy} ${min_days}) -gt 0 ] &&
    errors+=("${user}:${year}-${month}-${day}")

  # Mark all as inspected
  inspected+=("${user}:${year}-${month}-${day}")
done


# If ${change} = 1
if [ ${change} -eq 1 ]; then

  # Iterate ${errors}
  for error in ${errors[@]}; do

    # Get the username from ${error}
    user="$(echo "${error}" | cut -d: -f1)"

    # Get the last login date as well
    lldate="$(echo "${error}" | cut -d: -f2)"

    # Lock account for ${user}
    passwd -l ${user} &> /dev/null

    # Get results
    locked=$(awk -F: '$2 !~ /^LK/{print 1}' /etc/shadow)

    # If ${locked} > 0 flag it
    [ ${locked:=0} -gt 0 ] &&
      terrors+=("${user}:${lldate}")
  done
fi

# Replace ${errors[@]} if change occured
[ ${#terrors[@]} -gt 0 ] &&
  errors=( "${terrors[@]}" )


###############################################
# Results for printable report
###############################################

# If ${#errors[@]} > 0
if [ ${#errors[@]} -gt 0 ]; then

  # Set ${results} error message
  results="Failed validation"
fi

# Set ${results} passed message
[ ${#errors[@]} -eq 0 ] && results="Passed validation"


###############################################
# Report generation specifics
###############################################

# Apply some values expected for report footer
#[ ${#errors[@]} -eq 0 ] && passed=1 || passed=0
#[ ${#errors[@]} -gt 0 ] && failed=1 || failed=0

# Calculate a percentage from applied modules & errors incurred
percentage=$(percent ${passed} ${failed})

# If the caller was only independant
if [ ${caller} -eq 0 ]; then

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Generate the report
  report "${results}"

  # Display the report
  cat ${log}
else

  # Since we were called from stigadm
  module_header "${results}"

  # Show failures
  [ ${#errors[@]} -gt 0 ] && print_array ${log} "errors" "${errors[@]}"

  # Provide detailed results to ${log}
  if [ ${verbose} -eq 1 ]; then

    # Print array of failed & validated items
    [ ${#inspected[@]} -gt 0 ] && print_array ${log} "validated" "${inspected[@]}"
  fi

  # Finish up the module specific report
  module_footer
fi


###############################################
# Return code for larger report
###############################################

# Return an error/success code (0/1)
exit ${#errors[@]}


# Date: 2018-06-29
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V00918
# STIG_Version: SV-39824r1
# Rule_ID: GEN000760
#
# OS: Solaris
# Version: 10
# Architecture: Sparc
#
# Title: Accounts must be locked upon 35 days of inactivity.
# Description: Accounts must be locked upon 35 days of inactivity.
