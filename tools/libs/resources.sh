#!/bin/bash

# Get network resources from Solaris
#  Requirements:
#   - An array of network interfaces; ${network_whitelist[@]}
#   - An associative array of network restrictions; ${network_properties[@]}
#   - A boolean true/false to acquire per zone; ${config_per_zone}
function get_network_resources()
{
  local -a current_network_properties

  # Iterate ${network_whitelist[@]} array
  for interface in ${network_whitelist[@]}; do

    # Iterate ${network_properties[@]}
    for property in ${!network_properties[@]}; do

      # Only if not 'maxbw'
      if [ "${property}" != "maxbw" ]; then

        # Get current value of ${property} for ${interface}
        cur_prop="$(dladm show-linkprop -p ${property} -o link,property,effective ${interface} 2>/dev/null |
          nawk 'NR > 1 && $3 !~ /--/{nic=$1;for(i=NR;i<=NR;i++){if($1 ~ /^[[0-9]+\./){val=val$1}else{val=nic":"$3}print val}}' | tail -1)"

        # Get the current ${property} values per ${interface}
        current_network_properties+=( "${interface}:${property}:${cur_prop}" )

        # Trap errors for missing ${item}
        [ $? -ne 0 ] && errors+=("Missing:interface:${interface}")


        # If protections are to be applied per zone
        if [ ${config_per_zone} -eq 1 ]; then

          # Iterate ${zones[@]}
          for zone in ${zones[@]}; do

            # Split ${zone} into name and path
            zpath="$(echo "${zone}" | cut -d: -f2)"
            zone="$(echo "${zone}" | cut -d: -f1)"

            # Get the current value of ${property} for ${interface} in ${zone}
            cur_zone_prop="$(dladm show-linkprop -p ${property} -o link,property,effective -z ${zone} ${interface} 2>/dev/null |
              nawk 'NR > 1 && $3 !~ /--/{nic=$1;for(i = NR;i<=NR;i++){if($1 ~ /^[[0-9]+\./){val=val$1}else{val=nic":"$3}print val}}' | tail -1)"

            # Get the current allowed-ips values for ${zone}
            current_network_properties+=( "${interface}:${property}:${cur_zone_prop}:${zone}" )

            # Trap errors for missing ${item}
            [ $? -ne 0 ] && errors+=("Missing:interface:${interface}:in:${zone}")
          done
        fi
      fi


      # Handle 'maxbw' differently
      if [ "${property}" == "maxbw" ]; then

        # The speed of the physical device that VNIC ${interface} is using
        phys="$(dladm show-vnic -o over ${interface} 2>/dev/null | awk 'NR > 1{printf("%s\n", $1)}')"

        # Bail if ${phys} is empty which indicates a non-vnic adapter
        [ "${phys}" == "" ] && continue


        # Capture the speed of ${phys} so we have something to calculate from
        cur_speed="$(dladm show-phys -o speed ${phys} 2>/dev/null |
          awk 'NR > 1 && $2 !~ /--/{printf("%s\n", $1)}')"

        # Get the current speed from the physical associated with ${interface}
        current_network_properties+=( "${interface}:speed:${phys}:${cur_speed}" )


        # Get the current 'maxbw' for ${interface}
        cur_maxbw="$(dladm show-linkprop -p ${property} -o value ${interface} |
          awk 'NR > 1 && $2 !~ /--/{printf("%s\n", $2)}')"

        # Add ${cur_maxbw} to array
        current_network_properties+=( "${interface}:${property}:${cur_maxbw}" )

        # If protections are to be applied per zone
        if [ ${config_per_zone} -eq 1 ]; then

          # Iterate ${zones[@]}
          for zone in ${zones[@]}; do

            # Split ${zone} into name and path
            zpath="$(echo "${zone}" | cut -d: -f2)"
            zone="$(echo "${zone}" | cut -d: -f1)"

            # Get the current allowed-ips values for ${zone}
            current_network_properties+=( "${interface}:${property}:$(dladm show-linkprop -p ${property} -o value -z ${zone} ${interface} 2>/dev/null |
              awk 'NR > 1 && $2 !~ /--/{printf("%s\n", $2)}' | tail -1):${zone}" )

            # Trap errors for missing ${item}
            [ $? -ne 0 ] && errors+=("Missing:interface:${interface}:in:${zone}")
          done
        fi
      fi
    done
  done

  # Return the results
  echo "${current_network_properties[@]}" | tr ' ' '\n'
}