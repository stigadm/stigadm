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


# Get the IPv4 address range
function calc_ipv4_range()
{
  local ipv4=( $(dec2bin4octet $(echo "${1}" | tr '.' ' ')) )
  local netmask=( $(dec2bin4octet $(echo "${2}" | tr '.' ' ')) )

  IFS=. read -r o1 o2 o3 o4 <<< "${ip}"
  IFS=. read -r m1 m2 m3 m4 <<< "${netmask}"

  ip_bits=( $(dec2bin4octet "${o1}") $(dec2bin4octet "${o2}") $(dec2bin4octet "${o3}") $(dec2bin4octet "${o4}") )
  mask_bits=( $(dec2bin4octet "${m1}") $(dec2bin4octet "${m2}") $(dec2bin4octet "${m3}") $(dec2bin4octet "${m4}") )


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