# stigadm build tool

The `stig-parser.sh` tool facilitates automated STIG XML parsing & file creation based on the meta data contained therein.

## Requirements ##
In order to parse the DISA IASE STIG recommendations you must download & extract to the `build` folder. The `xmllint` tool much also be installed.

## Usage ##
Usage is simple, as long as the STIG XML file(s) is in the same folder as `stig-parser.sh` it will find and parse them.
```sh
$ ./stig-parser.sh
```

### Output ###
You can change the output directory once you have verified functionality of the parsed XML meta data. It is a safety mechanism to only add/update meta data in the default `output`.
```sh
$ ./stig-parser.sh -o <path-to-stig-modules>
```

### Templating ###
By default the parser will use the `template.sh` file to create a new file if an existing stigadm module does not exist.
```sh
$ ./stig-parser.sh -t <path-to-stig-template>
```

## contributing ##

Contributions are welcome & appreciated. Refer to the [contributing document](https://github.com/jas-/stigadm/blob/master/CONTRIBUTING.md)
to help facilitate pull requests.

## license ##

This software is licensed under the [MIT License](https://github.com/jas-/stigadm/blob/master/LICENSE).

Copyright Jason Gerfen, 2015-2017.
