# stigadm

DISA IASE STIG validation & remediation for [Linux/UNIX](https://iase.disa.mil/stigs/os/unix-linux/Pages/index.aspx)

Code Coverage: 2018-11-23

| OS            | Version   | STIG Rule(s)   | Completed | Percentage |
| :---          | :---      | :---           | :---      | :---       |
| AIX           | 6.1       | 505            | 0         | 0%         |
| HP-UX         | 11.31     | 518            | 0         | 0%         |
| Oracle Linux  | 5         | 569            | 0         | 0%         |
| Oracle Linux  | 6         | 262            | 0         | 0%         |
| Red Hat       | 6         | 259            | 0         | 0%         |
| Red Hat       | 7         | 232            | 0         | 0%         |
| Solaris       | 10        | 510            | 29        | 5.68%      |
| Solaris       | 11        | 236            | 94        | 39.83%     |
| Ubuntu        | 16.04     | 230            | 0         | 0%         |
| SuSE          | 12        | 138            | 0         | 0%         |
| Totals        |           | 3458           | 123       | 3.55%      |

## install ##
No installer package; simply copy latest `stigadm` toolkit and use.

## methods ##

* `validation`      Default: Performs validation of STIG recommendations
* `remediation`     Remediates STIG recommendations
* `restoration`     Restores configurations of any previously changed STIG remediations


## help system ##

```sh
$ ./stigadm -h
stigadm - Facilitates STIG Validation & Modifications


Usage ./stigadm [options]

  Help:
    -h  Show this message

  Targeting:
    -O  Operating System
      Supported: [Solaris]

    -V  OS Version
      Supported: [11|10]

  Filters:
    -C  Classification
      Supported: [CAT-I|CAT-II|CAT-III]

    -L  VMS ID List - A comma separated list VMS ID's
      Example: V0047799,V0048211,V0048189

  Options:
    -a  Author name (required when using -c)
    -b  Use new boot environment (Solaris only)
    -c  Make the change
    -v  Enable verbose messages

  Restoration:
    -r  Perform rollback of changes

  Reporting:
    -l  Default: /var/log/stigadm/<HOST>-<OS>-<VER>-<ARCH>-<DATE>.json
    -j  JSON reporting structure (default)
    -x  XML reporting structure
```

## examples ##
Here are a few usage examples to get you started with the toolkit. If you are interested
in the XML or JSON reporting that is generated see [here](https://gist.github.com/jas-/431d107d3d744ba7ba41bf3b8d5cbdcf)

### Validation mode
This is the default mode of the library. It evaluates each STIG rule and outputs the
current state. Use the `-v` for additional details"

#### OS targeting
Targeting the OS allows for greater flexibility with regards to an automated solution;

```sh
$ ./stigadm.sh -O Solaris -V 10
```

#### Classification targeting
Targeting the STIG classification can be used to filter tests or remediation

```sh
$ ./stigadm.sh -C CAT-II
```

#### Vulnability targeting
Providing a comma separated list of VMS ID's can also assist with filtering tests or remediation

```sh
$ ./stigadm.sh -L V0047799,V0048211,V0048189
```

### Remediation mode
Remeditaion mode will find and resolve STIG ID's. Note that an author name/initials is required for
any `-c` flag.

#### OS targeting
Targeting the OS allows for greater flexibility with regards to an automated solution;

```sh
$ ./stigadm.sh -O Solaris -V 10 -ca jlg
```

#### Classification targeting
Targeting the STIG classification can be used to filter tests or remediation

```sh
$ ./stigadm.sh -C CAT-II -ca jlg
```

#### Vulnability targeting
Providing a comma separated list of VMS ID's can also assist with filtering tests or remediation

```sh
$ ./stigadm.sh -L V0047799,V0048211,V0048189 -ca jlg
```

#### Solaris boot environment
Because Solaris offers an alternate boot environment for changes you can make use of the `-b` option
for changes. **Please note this is alpha stage of implementation**

```sh
$ ./stigadm.sh -C CAT-I -bca jlg
```


## contributing ##

Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## FAQ ##
Pleae read the [FAQ](https://github.com/stigadm/stigadm/wiki/FAQ) to answer general questions about the project. Thanks.


## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2018.
