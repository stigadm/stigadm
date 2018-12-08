# tools/libs/accounts.sh

Query local/remote accounts

* [get_accounts()](#get_accounts)
* [user_uid()](#user_uid)
* [user_gid()](#user_gid)
* [get_groups()](#get_groups)
* [group_gid()](#group_gid)
* [get_system_accts()](#get_system_accts)
* [get_application_accts()](#get_application_accts)
* [get_user_accts()](#get_user_accts)
* [filter_accounts()](#filter_accounts)


## get_accounts()

Get all local/remote accounts

_Function has no arguments._

### Example

```bash
accounts=( $(get_accounts) )
```

### Output on stdout

* Array of local/remote accounts

### Exit codes

* >**0**: Success
* **0**: Error

## user_uid()

Obtain UID from provided username

### Arguments

* ${1} Username

### Example

```bash
user_uid foo
```

### Output on stdout

* Integer UID

## user_gid()

Obtain GID from provided username

### Arguments

* ${1} Username

### Example

```bash
user_gid foo
```

### Output on stdout

* Integer GID

## get_groups()

Obtain Array of local/remote groups

_Function has no arguments._

### Example

```bash
groups=( $(get_groups) )
```

### Output on stdout

* Array of local/remote groups

### Exit codes

* >**0**: Success
* **0**: Error

## group_gid()

Get the GID of a requested group

### Arguments

* ${1} Group name

### Example

```bash
group_gid foo
```

### Output on stdout

* Integer GID

## get_system_accts()

Get array of local/remote system accounts

_Function has no arguments._

### Example

```bash
system_accts=( $(get_system_accts) )
```

### Output on stdout

* Array of local/remote user accounts

## get_application_accts()

Get array of local/remote application accounts

_Function has no arguments._

### Example

```bash
application_accts=( $(get_application_accts) )
```

### Output on stdout

* Array of local/remote user accounts

## get_user_accts()

Get array of local/remote user accounts

_Function has no arguments._

### Example

```bash
user_accts=( $(get_user_accts) )
```

### Output on stdout

* Array of local/remote user accounts

## filter_accounts()

Return array of filtered user accounts

### Arguments

* ${@} Array of total arguments
* ${@[0]} Offset one of array is the needle
* ${@:1} Offset element 0 is the haystack

### Example

```bash
filter_accts=( $(filter_accts "foo" $(get_user_accts)) )
```

### Output on stdout

* Array of filtered local/remote user accounts

