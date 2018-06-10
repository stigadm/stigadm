# stigadm modules

Here lies the stigadm modules that facilitate validation, remediation & optionally restoration for DISA IASE STIG rules.

Each module implements a standard API to ensure consistency while addressing the unique validation/remediation specified by the STIG Identification number.

An example of the standardized API each module implements can be seen below:

## default help menu ##
```sh
Handles DISA STIG [STIG ID]

Usage ./[STIG ID].sh [options]

  Options:
    -h  Show this message
    -v  Enable verbosity mode

  Required:
    -c  Make the change
    -a  Author name (required when making change)
    -m  Display meta data associated with module

  Restoration options:
    -r  Perform rollback of changes

  Reporting:
    -l  Default: /var/log/stigadm/<HOST>-<OS>-<VER>-<ARCH>-<DATE>.json
    -j  JSON reporting structure (default)
    -x  XML reporting structure
```

## template ##
It is encouraged to make use of the [available template](https://github.com/jas-/stigadm/blob/master/build/template.sh) if you wish to contribute. Each module should us each module should use the same formating.

## api ##
An API for doing some heavy lifting is available but not yet documented. The [./tools/libs/](https://github.com/jas-/stigadm/blob/master/tools/libs) folder contains several scripts to assist with things like operating environment, disk I/O, permissions, needle/haystack searching arrays etc etc.

## contributing ##
Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2018.
