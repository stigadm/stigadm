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
    nawk '$1 ~ /^[a-z0-9A-Z:]/{
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


# Validate IPv4 addresses
function is_ipv4()
{
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi

  echo $stat
}


# Get IPv4 addresses & properties
function get_ipv4()
{
  local -a obj
  local blob="$(ifconfig -a | grep -v LOOPBACK |
    sed -n "/^[a-zA-Z0-9:].*IPv4.*$/,/[inet|ether].*$/p")"

  local -a ifaces=( $(parse_ifconfig "${blob}") )

  # Fix subnet mask hex values
  for iface in ${!ifaces[@]}; do

    # Pluck out the netmask
    nm="$(echo "${ifaces[${iface}]}" | cut -d, -f3)"
    if [[ $(echo "${nm}" | grep -c "\.") -eq 0 ]] && [[ ${#nm} -eq 8 ]]; then

      # Get our values
      read -r h1 h2 h3 h4 <<<$(echo "${nm}" | sed 's/.\{2\}/& /g')

      # Fix ${nm} and assign to ${f_nm}
      f_nm="$(hex2dec "${h1}").$(hex2dec "${h2}").$(hex2dec "${h3}").$(hex2dec "${h4}")"

      # Replace ${ifaces[{iface}]} with ${nm}
      ifaces[${iface}]="$(echo "${ifaces[${iface}]}" |
        sed "s|^\(.*,\)${nm}\(,.*\)$|\1${f_nm}\2|g")"
    fi
  done

  echo "${ifaces[@]}"
}


# Get IPv6 addresses & properties
function get_ipv6()
{
  local -a obj
  local blob="$(ifconfig -a | grep -v LOOPBACK |
    sed -n "/^[a-zA-Z0-9:].*IPv6.*$/,/[inet|ether].*$/p")"

  local -a ifaces=( $(parse_ifconfig "${blob}") )

  echo "${ifaces[@]}"
}


# Determine IPv4 class (i.e. A, B, C, D or E)
function calc_ipv4_class()
{
  local -a ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )

  [ $(echo "${ipv4[0]}" | grep -c "^0") -eq 1 ] && class="A"
  [ $(echo "${ipv4[0]}" | grep -c "^10") -eq 1 ] && class="B"
  [ $(echo "${ipv4[0]}" | grep -c "^110") -eq 1 ] && class="C"
  [ $(echo "${ipv4[0]}" | grep -c "^1110") -eq 1 ] && class="D"
  [ $(echo "${ipv4[0]}" | grep -c "^1111") -eq 1 ] && class="E"

  echo "${class}"
}


# Calculate the borrowed bits from CIDR & 32 (addr length)
function calc_ipv4_bits()
{
  echo $(subtract ${1} 32)
}


# Get the CIDR notation from the netmask
function calc_ipv4_cidr()
{
  local -a netmask=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )

  echo $(match_char_num $(echo "${netmask[@]}" | sed "s| ||g") 1)
}


# Calculate the subnet host addr
function calc_ipv4_host_addr()
{
  local -a ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
  local -a netmask=( $(dec2bin4octet $(echo "${2}" | tr '.' ' ')) )
  local total=3
  local n=0
  local -a ip

  while [ ${n} -le ${total} ]; do
    ip+=( $(bin2dec $(bitwise_and_calc ${ipv4[${n}]} ${netmask[${n}]})) )
    n=$(add ${n} 1)
  done

  echo "${ip[@]}" | tr ' ' '.'
}


# Get total number of subnets
function calc_ipv4_subnets()
{
  local ipv4="${1}"
  local netmask="${2}"
  local -a subnets1=( $(dec2bin4octet $(echo "${netmask}" | tr '.' ' ')) )

  # x = 2 ^ y - Usable subnets per netmask provided

}


# Get the total number of subnets
function calc_ipv4_hosts_per_subnet()
{
  local -a netmask=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )

  # x = 2 - (2 ^ y) - Usable hosts per subnet
  echo $(subtract 2 $(pow 2 $(match_char_num $(echo ${netmask[@]} | sed "s| ||g") 0)))
}


# Get the IPv4 broadcast
function calc_ipv4_broadcast()
{
  local ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
}


# Returns start and end address for provided ipv4 and subnet
function calc_ipv4_host_range()
{
  local ipv4="${1}"
  local netmask="${2}"
  local host_addr="$(calc_ipv4_host_addr "${ipv4}" "${netmask}")"
  local hosts=$(calc_ipv4_hosts_per_subnet ${netmask})

  local t_host=( $(dec2bin4octet $(echo "${host_addr}" | tr '.' ' ')) )
  local t_start=( ${t_host[0]} ${t_host[1]} ${t_host[2]} $(add ${t_host[3]} 1) )
  local t_end=( ${t_host[0]} ${t_host[1]} ${t_host[2]} $(add $(bin2dec ${t_host[3]}) $(dec2bin4octet ${hosts})) )

  local total=3
  local n=0
  local -a start
  local -a end

  while [ ${n} -le ${total} ]; do
    start+=( $(bin2dec ${t_start[${n}]}) )
    end+=( $(bin2dec ${t_end[${n}]}) )
    n=$(add ${n} 1)
  done

  x="$(echo "${start[@]}" | tr ' ' '.')"
  y="$(echo "${end[@]}" | tr ' ' '.')"

  echo "${x},${y}"
}


# Get properties of IPv4 address
function ipv4_properties()
{
  echo
}