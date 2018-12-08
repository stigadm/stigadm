# tools/libs/backup.sh

Handle backup operations

* [backup_setup_env()](#backup_setup_env)
* [bu_file()](#bu_file)
* [bu_file_last()](#bu_file_last)
* [bu_passwd_db()](#bu_passwd_db)
* [bu_inode_perms()](#bu_inode_perms)
* [bu_configuration()](#bu_configuration)


## backup_setup_env()

Builds backup environment

### Arguments

* ${1} Path to backup folder

### Example

```bash
backup_setup_env /path/to/backup
```

### Exit codes

* **0**: Success

## bu_file()

Backs up specified file while preserving permissions

### Arguments

* ${1} Author of backup file
* ${2} File to be backed up
* ${3} Owner of file
* ${4} Group owner of file
* ${5} Permisison of file

### Example

```bash
bu_file author /path/to/backup/file
bu_file author /path/to/backup/file foo bar 640
```

### Exit codes

* **0**: Success
* **1**: Error

## bu_file_last()

Gets the name of the last backup

### Arguments

* ${1} File to be backed up
* ${2} Author of backup file

### Example

```bash
bu_file_last /path/to/backup/file author
```

### Output on stdout

* String path to file

## bu_passwd_db()

Backs up local passwd database file(s)

### Arguments

* ${1} Author of backup file
* ${2} File to be backed up
* ${3} Owner of file
* ${4} Group owner of file
* ${5} Permisison of file

### Example

```bash
bu_file_db author /path/to/backup/file
bu_file_db author /path/to/backup/file foo bar 640
```

### Exit codes

* **0**: Success
* **1**: Error

## bu_inode_perms()

Backs up array of file/folder permissions

### Arguments

* ${1} Author of backup file
* ${2} File to be backed up
* ${3} STIG module ID
* ${4} Array of files

### Example

```bash
bu_inode_perms
bu_inode_perms ${files[@]}
bu_inode_perms /path/to/backup/file
bu_inode_perms /path/to/backup/file author
bu_inode_perms /path/to/backup/file author stigid
bu_inode_perms /path/to/backup/file author stigid ${files[@]}
```

### Exit codes

* **0**: Success
* **1**: Error

## bu_configuration()

Backs up array of configuration items

### Arguments

* ${1} Author of backup file
* ${2} File to be backed up
* ${3} STIG module ID
* ${4} Array of configuration items

### Example

```bash
bu_inode_perms
bu_inode_perms ${configuration[@]}
bu_inode_perms /path/to/backup/file
bu_inode_perms /path/to/backup/file author
bu_inode_perms /path/to/backup/file author stigid
bu_inode_perms /path/to/backup/file author stigid ${configuration[@]}
```

### Exit codes

* **0**: Success
* **1**: Error

