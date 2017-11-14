#!/bin/ksh

# OS: Solaris
# Version: 11
# Severity: CAT-II
# Class: UNCLASSIFIED
# VulnID: V-48103
# Name: SRG-OS-999999
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
# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048103
# STIG_Version: SV-60975r1
# Rule_ID: SOL-11.1-040360
#
# OS: Solaris
# Version: 11
# Architecture: Sparc
#
# Title: Direct root account login must not be permitted for SSH access.
# Description: Direct root account login must not be permitted for SSH access.


# Date: 2017-06-21
#
# Severity: CAT-II
# Classification: UNCLASSIFIED
# STIG_ID: V0048103
# STIG_Version: SV-60975r1
# Rule_ID: SOL-11.1-040360
#
# OS: Solaris
# Version: 11
# Architecture: X86
#
# Title: Direct root account login must not be permitted for SSH access.
# Description: Direct root account login must not be permitted for SSH access.

