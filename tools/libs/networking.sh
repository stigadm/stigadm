#!/bin/bash

# @file tools/libs/networking.sh
# @brief Handle various networking operations

# @description Obtain current gateways
#
# @noargs
#
# @example
#   gateways=( $(get_gatways) )
#
# @stdout Array gateway IP's
#
# @exitcode 0 Success
# @exitcode 1 Error
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


# @description Resolve host via configured DNS
#
# @arg ${@} Array of hosts to resolve
#
# @example
#   resolve_hosts host1 host2 host3
#   resolve_hosts "${hosts[@]}"
#
# @stdout Array of resolved IP's
#
# @exitcode 0 Success
# @exitcode >0 Error
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


# @description Function to parse ifconfig output
#
# @noargs
#
# @example
#   array_of_interfaces=( $(parse_ifconfig) )
#
# @stdout Array of interfaces and properties
#
# @exitcode >0 Success
# @exitcode 0 Error
function parse_ifconfig()
{
  local -a configs=( $(echo "${1}" |
    nawk '$1 ~ /^[a-z0-9A-Z:]/{
      iface=$1;
      getline;
      if($1 ~ /inet/){ip=$2}
      if($3 == "netmask"){nm=$4}
      if($5 == "broadcast"){bc=$6}
      getline;
      if($1 == "ether"){mac=$2}
      gsub(/:/, ",", iface)
      printf("%s%s,%s,%s,%s\n", iface, ip, nm, bc, mac)}') )

  echo "${configs[@]}" && return ${#configs[@]}
}


# @description Validate IPv4 addresses
#
# @arg ${1} IPv4 address
#
# @example
#   is_ipv4 192.168.2.15 (true = 0)
#   is_ipv4 192.168.2.256 (false = 1)
#
# @stdout boolean 1/0
#
# @exitcode 0 Success
# @exitcode 1 Error
function is_ipv4()
{
  local  ip="${1}"
  local  stat=1

  if [[ ${ip} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    ip=( $(echo "${ip}" | tr '.' ' ') )
    if [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]; then
      stat=0
    fi
  fi

  echo ${stat} && return ${stat}
}


# @description Get IPv4 addresses & properties
#
# @noargs
#
# @see parse_ifconfig
#
# @example
#   ipv4_interfaces=( $(get_ipv4) )
#
# @stdout Array of IPv4 addressed assigned interfaces and properties
#
# @exitcode >0 Success
# @exitcode 0 Error
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

  echo "${ifaces[@]}" && return ${#ifaces[@]}
}


# @description Get IPv6 addresses & properties
#
# @noargs
#
# @see parse_ifconfig
#
# @example
#   ipv6_interfaces=( $(get_ipv6) )
#
# @stdout Array of IPv6 addressed assigned interfaces and properties
#
# @exitcode >0 Success
# @exitcode 0 Error
function get_ipv6()
{
  local -a obj
  local blob="$(ifconfig -a | grep -v LOOPBACK |
    sed -n "/^[a-zA-Z0-9:].*IPv6.*$/,/[inet|ether].*$/p")"

  local -a ifaces=( $(parse_ifconfig "${blob}") )

  echo "${ifaces[@]}" && return ${#ifaces[@]}
}


# @description Determine IPv4 class (i.e. A, B, C, D or E)
#
# @arg ${1} IPv4 address
#
# @example
#   calc_ipv4_class 192.168.2.125
#
# @stdout String; A, B, C, D, E
#
# @exitcode 0 Success
# @exitcode 1 Error
function calc_ipv4_class()
{
  local -a ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
  local class

  [ $(echo "${ipv4[0]}" | grep -c "^0") -eq 1 ] && class="A"
  [ $(echo "${ipv4[0]}" | grep -c "^10") -eq 1 ] && class="B"
  [ $(echo "${ipv4[0]}" | grep -c "^110") -eq 1 ] && class="C"
  [ $(echo "${ipv4[0]}" | grep -c "^1110") -eq 1 ] && class="D"
  [ $(echo "${ipv4[0]}" | grep -c "^1111") -eq 1 ] && class="E"

  echo "${class}"
  [ "${class}" == "" ] return 1 || return 0
}


# @description Calculate the borrowed bits from CIDR & 32 (addr length)
#
# @arg ${1} CIDR
#
# @example
#   calc_ipv4_bits 25
#
# @stdout Integer
#
# @exitcode >0 Success
# @exitcode 0 Error
function calc_ipv4_bits()
{
  local bits=$(subtract ${1} 32)
  echo ${bits} && return ${bits}
}


# @description Get the CIDR notation from the netmask
#
# @arg ${1} IPv4 subnet mask
#
# @example
#   calc_ipv4_cidr 255.255.255.128
#
# @stdout CIDR notation
#
# @exitcode >0 Success
# @exitcode 1 Error
function calc_ipv4_cidr()
{
  local -a netmask=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
  local cidr=$(match_char_num $(echo "${netmask[@]}" | sed "s| ||g") 1)
  echo ${cidr} && return ${cidr}
}


# @description CIDR to subnet
#
# @arg ${1} CIDR notation
#
# @example
#   calc_ipv4_cidr_subnet 25
#
# @stdout String Reversed CIDR to mapped netmask
function calc_ipv4_cidr_subnet()
{
  local cidr="${1}"

  case "${cidr}" in
    0) net="0.0.0.0" ;;
    1) net="128.0.0.0" ;;
    2) net="192.0.0.0" ;;
    3) net="224.0.0.0" ;;
    4) net="240.0.0.0" ;;
    5) net="248.0.0.0" ;;
    6) net="252.0.0.0" ;;
    7) net="254.0.0.0" ;;
    8) net="255.0.0.0" ;;
    9) net="255.128.0.0" ;;
    10) net="255.192.0.0" ;;
    11) net="255.224.0.0" ;;
    12) net="255.240.0.0" ;;
    13) net="255.248.0.0" ;;
    14) net="255.252.0.0" ;;
    15) net="255.254.0.0" ;;
    16) net="255.255.0.0" ;;
    17) net="255.255.128.0" ;;
    18) net="255.255.192.0" ;;
    19) net="255.255.224.0" ;;
    20) net="255.255.240.0" ;;
    21) net="255.255.248.0" ;;
    22) net="255.255.252.0" ;;
    23) net="255.255.254.0" ;;
    24) net="255.255.255.0" ;;
    25) net="255.255.255.128" ;;
    26) net="255.255.255.192" ;;
    27) net="255.255.255.224" ;;
    28) net="255.255.255.240" ;;
    29) net="255.255.255.248" ;;
    30) net="255.255.255.252" ;;
    31) net="255.255.255.254" ;;
    32) net="255.255.255.255" ;;
    *) net="0.0.0.0"
  esac

  echo "${net}"
}


# @description Calculate the subnet host addr
#
# @arg ${1} IPv4 address
# @arg ${2} Subnet mask
#
# @example
#   calc_ipv4_host_addr 192.168.2.15 255.255.255.128
#
# @stdout String IPv4 host address
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


# @description Calculate number of subnets available
#
# @arg ${1} IPv4 address
# @arg ${2} Subnet mask
#
# @example
#   calc_ipv4_subnets 192.168.2.15 255.255.255.128
#
# @stdout Integer Number of subnets available
function calc_ipv4_subnets()
{
  local ipv4="${1}"
  local netmask="${2}"
  local -a subnets1=( $(dec2bin4octet $(echo "${netmask}" | tr '.' ' ')) )

  # x = 2 ^ y - Usable subnets per netmask provided

}


# @description Calculate the number of hosts in subnet
#
# @arg ${1} Subnet mask
#
# @example
#   calc_ipv4_hosts_per_subnet 255.255.255.128
#
# @stdout Integer Number of available hosts
function calc_ipv4_hosts_per_subnet()
{
  local -a netmask=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )

  # x = 2 - (2 ^ y) - Usable hosts per subnet
  echo $(subtract 2 $(pow 2 $(match_char_num $(echo ${netmask[@]} | sed "s| ||g") 0)))
}


# @description Calculate broadcast address
#
# @arg ${1} IPv4 address
# @arg ${2} Subnet mask
#
# @example
#   calc_ipv4_broadcast 192.168.2.15 255.255.255.128
#
# @stdout String IPv4 broadcast address
function calc_ipv4_broadcast()
{
  local ipv4="${1}"
  local netmask="${2}"

  local -a netmask_bits=( $(dec2bin4octet $(echo "${netmask}" | tr '.' ' ')) )
  local -a host_addr=( $(dec2bin4octet $(echo $(calc_ipv4_host_addr "${ipv4}" "${netmask}") | tr '.' ' ')) )

  local total=3
  local n=0
  local -a broadcast

  while [ ${n} -le ${total} ]; do
    t_netmask="$(echo "${netmask_bits[${n}]}" | tr 01 10)" # Flip some bits
    broadcast+=( $(bin2dec $(bitwise_or_calc ${host_addr[${n}]} ${t_netmask})) )
    n=$(add ${n} 1)
  done

  echo "$(echo "${broadcast[@]}" | tr ' ' '.')"
}


# @description Get the start/stop IPv4 addresses available in provided subnet
#
# @arg ${1} IPv4 address
# @arg ${2} Subnet mask
#
# @example
#   calc_ipv4_host_addr 192.168.2.15 255.255.255.128
#
# @stdout String IPv4 host address
function calc_ipv4_host_range()
{
  local ipv4="${1}"
  local netmask="${2}"
  local host_addr="$(calc_ipv4_host_addr "${ipv4}" "${netmask}")"

  local -a t_host=( $(dec2bin4octet $(echo "${host_addr}" | tr '.' ' ')) )
  local -a t_start=( ${t_host[0]} ${t_host[1]} ${t_host[2]} $(add ${t_host[3]} 1) )

  local -a broadcast=( $(dec2bin4octet $(echo $(calc_ipv4_broadcast "${ipv4}" "${netmask}") | tr '.' ' ')) )
  local -a t_end=( ${broadcast[0]} ${broadcast[1]} ${broadcast[2]} $(subtract 1 ${broadcast[3]}) )

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

  echo "${x}" "${y}"
}


# @description Determine if provided IPv4 is in subnet range
#
# @arg ${1} IPv4 comparison address
# @arg ${2} Subnet comparison mask
# @arg ${3} IPv4 target address
#
# @example
#   calc_ipv4_host_in_range 192.168.2.15 255.255.255.128 192.168.15.67
#   calc_ipv4_host_in_range 192.168.2.15 255.255.255.128 192.168.2.18
#
# @stdout String IPv4 host address
function calc_ipv4_host_in_range()
{
  local ipv4="${1}"
  local netmask="${2}"

  local -a net=( $(dec2bin4octet $(echo "${3}" | tr '.' ' ')) )

  local -a host_addr=( $(dec2bin4octet $(echo $(calc_ipv4_host_addr "${ipv4}" "${netmask}") | tr '.' ' ')) )

  local -a t_net=( ${net[0]} ${net[1]} ${net[2]} ${net[3]:0:5} )
  local -a t_host_addr=( ${host_addr[0]} ${host_addr[1]} ${host_addr[2]} ${host_addr[3]:0:5} )

  local total=3
  local n=0
  local -a results

  while [ ${n} -le ${total} ]; do
    results+=( $(bitwise_and_calc ${t_net[${n}]} ${t_host_addr[${n}]}) )
    n=$(add ${n} 1)
  done

  results=( ${results[0]} ${results[1]} ${results[2]} ${results[3]:0:5} )

  [ "$(echo "${t_host_addr[@]}" | sed 's/ //g')" == "$(echo "${results[@]}" | sed 's/ //g')" ] &&
    echo true || echo false
}


# @description Normalize IPv4 combinations
#  - Pad IPv4 if partial
#  - Convert CIDR to subnet (if provided)
#
# @arg ${1} IPv4
#
# @example
#   normalize_ipv4 192.168.
#   normalize_ipv4 192.168./24
#   normalize_ipv4 192.168./255.255.128.0
#   normalize_ipv4 192.168.2.15/25
#
# @stdout String IPv4/Subnet
function normalize_ipv4()
{
  local blob="${1}"
  local p_sub
  local mask
  local length
  local net
  local -a t_obj

  # Handle CIDR or subnet definitions
  if [ $(echo "${blob}" | grep -c "/") -gt 0 ]; then

    # Split ${blob} and check length of potential CIDR/Subnet
    p_sub="$(echo "${blob}" | cut -d"/" -f1)"
    mask="$(echo "${blob}" | cut -d"/" -f2)"
  else

    # Use ${blob} as ${p_sub}
    p_sub="${blob}"
  fi


  # If ${p_sub} length > 2 assume subnet notation
  [ "${mask}" != "" ] &&
    length=$(echo "${mask}" | awk '{print length($0)}') ||
    length=$(echo "${p_sub}" | awk '{print length($0)}')


  # Create temporary array so we can easily pad
  t_obj=( $(echo "${p_sub}" | tr '.' ' ') )

  local total=3
  local n=0
  local -a ip

  # Iterate to 4 elements
  while [ ${n} -le ${total} ]; do

    # Add or pad
    [ "${t_obj[${n}]}" != "" ] &&
      ip+=( "${t_obj[${n}]}" ) || ip+=( "0" )

    # Increment counter
    n=$(add ${n} 1)
  done

  # Convert ${ip[@]} to string
  net="$(echo "${ip[@]}" | tr ' ' '.')"

  # Reverse the CIDR notation
  if [ ${length} -eq 2 ]; then

    # Assume CIDR notation & convert to long decimal
    mask="$(calc_ipv4_cidr_subnet ${mask})"
  fi

  # Make sure we preserve both ip and mask for a possible in_range() call
  [ "${mask}" != "" ] && echo "${net},${mask}" || echo "${net}"
}