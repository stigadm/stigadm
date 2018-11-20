#!/bin/bash

# Function to obtain gateways
function get_gateways()
{
  # Populate an array of possible gateways
  local gateways=( $(netstat -nr | awk '$1 ~ /default|0.0.0.0/{print $2}') )

  # Bail if no gateway's defined
  if [ ${#gateways[@]} -eq 0 ]; then
    echo 1 && return 1
  fi

  echo "${gateways[@]}" && return 0
}


# Ensure DNS is working by resolving hosts
#  ${@}: Array of hostnames
function resolve_hosts()
{
  # Re-assign ${@} as local in scope
  local hosts=( ${@} )
  local -a ips

  # Bail if nothing provided
  if [ ${#hosts[@]} -eq 0 ]; then
    echo && return 1
  fi

  # Iterate ${hosts[@]} & try to resolve
  for host in ${hosts[@]}; do

    # Push ${host} return value to ${ips[@]}
    ips=( $(nslookup -retry=2 -timeout=5 ${host} 2>/dev/null |
      awk '$1 ~ /^Name/{getline; print $2}') )
  done

  # Bail if ${#ips[@]} is 0
  if [ ${#ips[@]} -eq 0 ]; then
    echo && return 2
  fi

  echo "${ips[@]}" && return 0
}


# Get the IPv4 CIDR
function calc_ipv4_cidr()
{
  local ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )


}


# Function to parse ifconfig output
function parse_ifconfig()
{
  echo "${1}" |
    awk '$1 ~ /^[a-z0-9A-Z:]/{
      iface=$1;
      getline;
      if($1 ~ /inet/){ip=$2}
      if($3 == "netmask"){nm=$4}
      if($5 == "broadcast"){bc=$6}
      getline;
      if($1 == "ether"){mac=$2}
      gsub(/:/, ",", iface)
      printf("%s%s,%s,%s,%s\n", iface, ip, nm, bc, mac)}'
}

# Get IPv4 addresses & properties
function get_ipv4()
{
  local -a obj
  local blob="$(ifconfig -a | grep -v LOOPBACK |
    sed -n "/^[a-zA-Z0-9:].*IPv4.*$/,/[inet|ether].*$/p")"

  local -a ifaces=( $(parse_ifconfig "${blob}") )
}


# Get IPv6 addresses & properties
function get_ipv6()
{
  local -a obj
  local blob="$(ifconfig -a | grep -v LOOPBACK |
    sed -n "/^[a-zA-Z0-9:].*IPv6.*$/,/[inet|ether].*$/p")"

  local -a ifaces=( $(parse_ifconfig "${blob}") )
}


# Get the IPv4 address range
function calc_ipv4_range()
{
  local ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
  local netmask=( $(dec2bin4octet $(echo "${2}" | tr '.' ' ')) )

}


# Get the IPv4 broadcast
function calc_ipv4_broadcast()
{
  local ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
}


# Get properties of IPv4 address
function ipv4_properties()
{
  echo
}