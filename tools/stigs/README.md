# stigadm modules

Here lies the stigadm modules that facilitate validation, remediation & optionally restoration for DISA IASE STIG rules.

Each module implements a standard API to ensure consistency while addressing the unique validation/remediation specified by the STIG Identification number.

An example of the standardized API can be seen below:

```sh
Handles DISA STIG <STIG-ID>

Usage ./<STIG-ID>.sh [options]

  Options:
    -h  Show this message
    -v  Enable verbosity mode

  Required:
    -c  Make the change
    -a  Author name (required when making change)
    -m  Display meta data associated with module

  Restoration options:
    -r  Perform rollback of changes
    -i  Interactive mode, to be used with -r
```

## contributing ##

Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2017.
