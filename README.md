# stigadm

DOD DISA IASE STIG validation & remediation for Linux/UNIX

DISCLAIMER: Project coverage @ 93/3093 (3%) of STIG(s)
Coverage report: 2018-04-20 

| OS            | Version   | STIG Rule(s)   | Completed |
| :---:         | :---:     | :---:          | :---:     |
| AIX           | 6.1       | 505            | 0         |
| HP-UX         | 11.31     | 518            | 0         |
| Oracle Linux  | 5         | 569            | 0         |
| Oracle Linux  | 6         | 262            | 0         |
| Red Hat       | 6         | 259            | 0         |
| Red Hat       | 7         | 232            | 0         |
| Solaris       | 10        | 511            | 26        |
| Solaris       | 11        | 237            | 67        |

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
    -m  Display meta data for STIG
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
  Display meta data [True|False]: True
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

### Classification targeting
Targeting the STIG classification can be used to filter tests

```sh
$ ./stigadm.sh -vO Solaris -V 11 -C CAT-II
stigadm] Ok: Built list of STIG modules: 23/74
[stigadm] Ok:   OS: Solaris Version: 11 Classification: CAT-II

...
```

### Vulnability targeting
Providing a comma separated list of VMS ID's can also assist with filtering tests

```sh
$ ./stigadm.sh -vO Solaris -V 11 -L V0047799,V0048211,V0048189
stigadm] Ok: Built list of STIG modules: 3/74
[stigadm] Ok:   OS: Solaris Version: 11 Classification: ALL

...
```

## contributing ##

Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2017.
