#!/bin/ksh

exit 0
echo "Checking value for PermitRootLogin…"
if [ -f $sshdconfig ]; then
  if [ `grep "^PermitRootLogin no" $sshdconfig | wc -l` -lt 1 ]; then
    if [ `grep "PermitRootLogin" $sshdconfig |wc -l` -lt 1 ]; then
      cp $sshdconfig $sshdconfig.orig.21A
      echo "PermitRootLogin no" >> $sshdconfig;
      echo "PermitRootLogin no has been added to $sshdconfig" >> $LOGFILE;
      echo "     added PermitRootLogin to $sshdconfig."
    else
      cp $sshdconfig $sshdconfig.21F
      grep -v PermitRootLogin $sshdconfig >> $sshdconfig.temp
      mv $sshdconfig.temp $sshdconfig
      echo "PermitRootLogin no" >> $sshdconfig;
      chmod 600 $sshdconfig
      chown root:sys $sshdconfig
      echo "PermitRootLogin value has been changed to no in " $sshdconfig >> $LOGFILE;
      echo "     changed value for PermitRootLogin in $sshdconfig."
    fi
  else
    echo "PermitRootLogin no is already set in "$sshdconfig >> $LOGFILE
    echo "     PermitRootLogin already set in $sshdconfig."
  fi
else
  echo $sshdconfig " does not exist or Secure Shell has not been installed" >> $LOGFILE
  echo "     $sshdconfig does not exist or Secure Shell has not been installed."
fi

# Date: 2018-09-05
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048103
# STIG_Version: SV-60975r1
# Rule_ID: SOL-11.1-040360
#
# OS: Solaris
# Version: 11
# Architecture: Sparc X86
#
# Title: Direct root account login must not be permitted for SSH access.
# Description: The system should not allow users to log in as the root user directly, as audited actions would be non-attributable to a specific user.

