# tools/libs/bootenv.sh

Implements bootenv creation, mounting etc

* [create_be()](#create_be)
* [activate_be()](#activate_be)
* [validate_be()](#validate_be)
* [mount_be()](#mount_be)
* [bootenv()](#bootenv)


## create_be()

Create a new boot environment

### Arguments

* ${1} String; Name of new boot env.
* ${2} Integer; OS Version

### Example

```bash
create_be foo 10
create_be bar 11
```

### Exit codes

* **0**: Success
* **1**: Error

## activate_be()

Activates the newly created boot env.

### Arguments

* ${1} String; Name of new boot env.
* ${2} Integer; OS Version

### Example

```bash
activate_be foo 10
activate_be bar 11
```

### Exit codes

* **0**: Success
* **1**: Error

## validate_be()

Validates new boot environment

### Arguments

* ${1} String; Name of new boot env.
* ${2} Integer; OS Version

### Example

```bash
validate_be foo 10
validate_be bar 11
```

### Exit codes

* **0**: Success
* **1**: Error

## mount_be()

Mount the boot environment

### Arguments

* ${1} String; Name of new boot env.
* ${2} Integer; OS Version
* ${3} String; Path of boot env. mount

### Example

```bash
mount_be foo 10 /path/to/mount/
mount_be bar 11 /path/to/mount/
```

### Exit codes

* **0**: Success
* **1**: Error

## bootenv()

Create, activate & validate boot env.

### Arguments

* ${1} String; Name of new boot env.
* ${2} Integer; OS Version

### Example

```bash
bootenv foo 10
bootenv bar 11
```

### Exit codes

* **0**: Success
* **1**: Error

