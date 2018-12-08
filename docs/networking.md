# tools/libs/networking.sh

Handle various networking operations

* [get_gateways()](#get_gateways)
* [resolve_hosts()](#resolve_hosts)
* [parse_ifconfig()](#parse_ifconfig)
* [is_ipv4()](#is_ipv4)
* [get_ipv4()](#get_ipv4)
* [get_ipv6()](#get_ipv6)
* [calc_ipv4_class()](#calc_ipv4_class)
* [calc_ipv4_bits()](#calc_ipv4_bits)
* [calc_ipv4_cidr()](#calc_ipv4_cidr)
* [calc_ipv4_cidr_subnet()](#calc_ipv4_cidr_subnet)
* [calc_ipv4_host_addr()](#calc_ipv4_host_addr)
* [calc_ipv4_subnets()](#calc_ipv4_subnets)
* [calc_ipv4_hosts_per_subnet()](#calc_ipv4_hosts_per_subnet)
* [calc_ipv4_broadcast()](#calc_ipv4_broadcast)
* [calc_ipv4_host_range()](#calc_ipv4_host_range)
* [calc_ipv4_host_in_range()](#calc_ipv4_host_in_range)
* [normalize_ipv4()](#normalize_ipv4)


## get_gateways()

Obtain current gateways

_Function has no arguments._

### Example

```bash
gateways=( $(get_gatways) )
```

### Output on stdout

* Array gateway IP's

### Exit codes

* **0**: Success
* **1**: Error

## resolve_hosts()

Resolve host via configured DNS

### Arguments

* ${@} Array of hosts to resolve

### Example

```bash
resolve_hosts host1 host2 host3
resolve_hosts "${hosts[@]}"
```

### Output on stdout

* Array of resolved IP's

### Exit codes

* **0**: Success
* >**0**: Error

## parse_ifconfig()

Function to parse ifconfig output

_Function has no arguments._

### Example

```bash
array_of_interfaces=( $(parse_ifconfig) )
```

### Output on stdout

* Array of interfaces and properties

### Exit codes

* >**0**: Success
* **0**: Error

## is_ipv4()

Validate IPv4 addresses

### Arguments

* ${1} IPv4 address

### Example

```bash
is_ipv4 192.168.2.15 (true = 0)
is_ipv4 192.168.2.256 (false = 1)
```

### Output on stdout

* boolean 1/0

### Exit codes

* **0**: Success
* **1**: Error

## get_ipv4()

Get IPv4 addresses & properties

_Function has no arguments._

See also

* [parse_ifconfig](#parse_ifconfig)

### Example

```bash
ipv4_interfaces=( $(get_ipv4) )
```

### Output on stdout

* Array of IPv4 addressed assigned interfaces and properties

### Exit codes

* >**0**: Success
* **0**: Error

## get_ipv6()

Get IPv6 addresses & properties

_Function has no arguments._

See also

* [parse_ifconfig](#parse_ifconfig)

### Example

```bash
ipv6_interfaces=( $(get_ipv6) )
```

### Output on stdout

* Array of IPv6 addressed assigned interfaces and properties

### Exit codes

* >**0**: Success
* **0**: Error

## calc_ipv4_class()

Determine IPv4 class (i.e. A, B, C, D or E)

### Arguments

* ${1} IPv4 address

### Example

```bash
calc_ipv4_class 192.168.2.125
```

### Output on stdout

* String; A, B, C, D, E

### Exit codes

* **0**: Success
* **1**: Error

## calc_ipv4_bits()

Calculate the borrowed bits from CIDR & 32 (addr length)

### Arguments

* ${1} CIDR

### Example

```bash
calc_ipv4_bits 25
```

### Output on stdout

* Integer

### Exit codes

* >**0**: Success
* **0**: Error

## calc_ipv4_cidr()

Get the CIDR notation from the netmask

### Arguments

* ${1} IPv4 subnet mask

### Example

```bash
calc_ipv4_cidr 255.255.255.128
```

### Output on stdout

* CIDR notation

### Exit codes

* >**0**: Success
* **1**: Error

## calc_ipv4_cidr_subnet()

CIDR to subnet

### Arguments

* ${1} CIDR notation

### Example

```bash
calc_ipv4_cidr_subnet 25
```

### Output on stdout

* String Reversed CIDR to mapped netmask

## calc_ipv4_host_addr()

Calculate the subnet host addr

### Arguments

* ${1} IPv4 address
* ${2} Subnet mask

### Example

```bash
calc_ipv4_host_addr 192.168.2.15 255.255.255.128
```

### Output on stdout

* String IPv4 host address

## calc_ipv4_subnets()

Calculate number of subnets available

### Arguments

* ${1} IPv4 address
* ${2} Subnet mask

### Example

```bash
calc_ipv4_subnets 192.168.2.15 255.255.255.128
```

### Output on stdout

* Integer Number of subnets available

## calc_ipv4_hosts_per_subnet()

Calculate the number of hosts in subnet

### Arguments

* ${1} Subnet mask

### Example

```bash
calc_ipv4_hosts_per_subnet 255.255.255.128
```

### Output on stdout

* Integer Number of available hosts

## calc_ipv4_broadcast()

Calculate broadcast address

### Arguments

* ${1} IPv4 address
* ${2} Subnet mask

### Example

```bash
calc_ipv4_broadcast 192.168.2.15 255.255.255.128
```

### Output on stdout

* String IPv4 broadcast address

## calc_ipv4_host_range()

Get the start/stop IPv4 addresses available in provided subnet

### Arguments

* ${1} IPv4 address
* ${2} Subnet mask

### Example

```bash
calc_ipv4_host_addr 192.168.2.15 255.255.255.128
```

### Output on stdout

* String IPv4 host address

## calc_ipv4_host_in_range()

Determine if provided IPv4 is in subnet range

### Arguments

* ${1} IPv4 comparison address
* ${2} Subnet comparison mask
* ${3} IPv4 target address

### Example

```bash
calc_ipv4_host_in_range 192.168.2.15 255.255.255.128 192.168.15.67
calc_ipv4_host_in_range 192.168.2.15 255.255.255.128 192.168.2.18
```

### Output on stdout

* String IPv4 host address

## normalize_ipv4()

Normalize IPv4 combinations
 - Pad IPv4 if partial
 - Convert CIDR to subnet (if provided)

### Arguments

* ${1} IPv4

### Example

```bash
normalize_ipv4 192.168.
normalize_ipv4 192.168./24
normalize_ipv4 192.168./255.255.128.0
normalize_ipv4 192.168.2.15/25
```

### Output on stdout

* String IPv4/Subnet

