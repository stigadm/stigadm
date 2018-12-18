# tools/libs/io.sh

I/O operations

* [create_dir()](#create_dir)
* [gen_tmpfile()](#gen_tmpfile)
* [get_inode()](#get_inode)
* [test_file()](#test_file)
* [is_compiled()](#is_compiled)


## create_dir()

Create directory

### Arguments

* ${1} String path to directory

### Output on stdout

* Integer

## gen_tmpfile()

Create a new temporary file

### Arguments

* ${1} String File name
* ${2} String Owner of file
* ${3} String Group owner of file
* ${4} String Permissions of file
* ${5} String Suffix of file name

### Example

```bash
```

### Output on stdout

* String

## get_inode()

Resolve provided symlink to file name

### Arguments

* ${1} String File name

### Example

```bash
```

### Output on stdout

* String

## test_file()

Test array of files and return actual files

### Arguments

* ${1} Array List of files to test

### Example

```bash
```

### Output on stdout

* Array

## is_compiled()

Test file for compiled/data types

### Arguments

* ${1} String File to test

### Example

```bash
```

### Output on stdout

* Integer

