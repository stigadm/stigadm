# stigadm

DOD DISA IASE STIG validation & remediation for Linux/UNIX

## install ##
No installer package; simply copy latest `stigadm` toolkit and use.

## methods ##

* `validation`      Default: Performs validation of STIG recommendations
* `remediation`     Remediates STIG recommendations
* `restoration`     Restores configurations of any previously changed STIG remediations


## help system ##

```sh
stigadm - Facilitates STIG Validation & Modifications

Usage ./stigadm [options]

  Help:
    -h  Show this message

  Required:
    -O  Operating System
      Supported: [Solaris|RedHat]

    -V  OS Version
      Supported: [5|6|10|11]

  Filters:
    -A  Application
      Supported: [Not yet implemented]

    -C  Classification
      Supported: [CAT-I|CAT-II|CAT-III]

    -L  VMS ID List - A comma separated list VMS ID's
      Example: V0047799,V0048211,V0048189

  Options:
    -a  Author name (required when using -c)
    -b  Use new boot environment (Solaris only)
    -c  Make the change
    -d  Debug mode
    -v  Enable verbosity mode

  Restoration:
    -r  Perform rollback of changes
    -i  Interactive mode, to be used with -r

```

## examples ##
Here are a few usage examples to get you started with the toolkit.

### default (wizard mode)
By default the toolkit will ask you a series of questions about how you would like it to run;

```sh
$ ./stigadm.sh
[stigadm]: Wizard mode for stigadm
  Target OS [Solaris]: Solaris
  Use new boot environment [True|False]: True
  OS Version [10|11]: 11
  Severity [ALL|CAT-I|CAT-II|CAT-III]: ALL
  Mode [Change|Validate|Restore]: Validate
  Enable verbosity [True|False]: True
  Enable debug [True|False]: False

[stigadm] Ok: Built list of STIG modules: 74/74
[stigadm] Ok:   OS: Solaris Version: 11 Classification: ALL

...
```

### OS targeting
Targeting the OS allows for greater flexibility with regards to an automated solution;

```sh
$ ./stigadm.sh -vO Solaris
stigadm] Ok: Built list of STIG modules: 74/74
[stigadm] Ok:   OS: Solaris Version: 11 Classification: ALL

...
```


## contributing ##

Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2017.
