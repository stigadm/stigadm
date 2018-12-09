# tools/libs/common.sh

Common functions for various reasons

* [usage()](#usage)
* [get_meta_data()](#get_meta_data)


## usage()

Universal API arg list

### Arguments

* ${1} String; error message

### Example

```bash
usage
usage "An error occurred"
```

## get_meta_data()

Meta data parser

### Arguments

* ${1} String; Current working directory
* ${2} String; STIG V-ID to pluck meta data from

### Example

```bash
get_meta_data
declare -a meta_data=( $(get_meta_data) )
```

### Output on stdout

* Array Returns the STIG Date, Severity, Classification, V-ID, Version, Rule ID, OS, Title etc

