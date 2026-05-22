*** Settings ***
Documentation   Verify Transport Profile Management VPN Profiles
Name            Transport Management VPN Profiles
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    management_vpn
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.transport_profiles is defined %}
{% set profile_management_vpn = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles %}
 {% if profile.management_vpn is defined %}
  {% set _ = profile_management_vpn.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_management_vpn != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.management_vpn is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} Management VPN {{ profile.management_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.management_vpn.name) }}

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable  ${profile_id}

    ${transport_mngt_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/management/vpn
    ${transport_mngt_vpn}=    Json Search List    ${transport_mngt_vpn_res.json()}    data[].payload
    Run Keyword If    ${transport_mngt_vpn} == []    Fail    Feature '{{ profile.management_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.management_vpn.name) }}' expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_mngt_vpn}
    log   ${transport_mngt_vpn}
    ${vpn_parcel_id}=    Json Search String   ${transport_mngt_vpn_res.json()}    data[0].parcelId
    Set Suite Variable  ${vpn_parcel_id}

    Should Be Equal Value Json String    ${transport_mngt_vpn[0]}    name    {{ profile.management_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.management_vpn.name) }}    msg=transport_mngt_vpn name
    Should Be Equal Value Json Special_String    ${transport_mngt_vpn[0]}    description    {{ profile.management_vpn.description | default('not_defined') | normalize_special_string }}    msg=transport_mngt_vpn description

    Log   ======DNS Addresses=======

    Should Be Equal Value Json Yaml   ${transport_mngt_vpn[0]}   data.dnsIpv4.primaryDnsAddressIpv4   {{ profile.management_vpn.ipv4_primary_dns_address| default('not_defined') }}    {{ profile.management_vpn.ipv4_primary_dns_address_variable| default('not_defined') }}   msg=management_vpn.ipv4_primary_dns_address
    Should Be Equal Value Json Yaml   ${transport_mngt_vpn[0]}    data.dnsIpv4.secondaryDnsAddressIpv4  {{ profile.management_vpn.ipv4_secondary_dns_address| default('not_defined') }}    {{ profile.management_vpn.ipv4_secondary_dns_address_variable| default('not_defined') }}   msg=management_vpn.ipv4_secondary_dns_address
    Should Be Equal Value Json Yaml   ${transport_mngt_vpn[0]}     data.dnsIpv6.primaryDnsAddressIpv6   {{ profile.management_vpn.ipv6_primary_dns_address| default('not_defined') }}    {{ profile.management_vpn.ipv6_primary_dns_address_variable| default('not_defined') }}   msg=management_vpn.ipv6_primary_dns_address
    Should Be Equal Value Json Yaml   ${transport_mngt_vpn[0]}    data.dnsIpv6.secondaryDnsAddressIpv6   {{ profile.management_vpn.ipv6_secondary_dns_address| default('not_defined') }}    {{ profile.management_vpn.ipv6_secondary_dns_address_variable| default('not_defined') }}   msg=management_vpn.ipv6_secondary_dns_address

    Should Be Equal Value Json List Length   ${transport_mngt_vpn[0]}  data.newHostMapping  {{ profile.management_vpn.get('host_mappings', []) | length }}    msg=host mappings length

{% if profile.management_vpn.host_mappings is defined and profile.management_vpn.get('host_mappings', [])|length > 0 %}
    
    Log   ======Host Mappings=======
        
{% for host_entry in profile.management_vpn.host_mappings | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.newHostMapping[{{ loop.index0 }}].hostName   {{ host_entry.hostname | default('not_defined') }}     {{ host_entry.hostname_variable | default('not_defined') }}     msg=transport_mngt_vpn host_entry.hostname
    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.newHostMapping[{{ loop.index0 }}].listOfIp   {{ host_entry.ips | default('not_defined') }}     {{ host_entry.ips_variable | default('not_defined') }}     msg=transport_mngt_vpn host_entry.ips

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length   ${transport_mngt_vpn[0]}  data.ipv4Route  {{ profile.management_vpn.get('ipv4_static_routes', []) | length }}    msg=ipv4 static routes length

{% if profile.management_vpn.ipv4_static_routes is defined and profile.management_vpn.get('ipv4_static_routes', [])|length > 0 %}

    Log   ======IPv4 Static Routes=======

{% for route_entry in profile.management_vpn.ipv4_static_routes | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].prefix.ipAddress   {{ route_entry.network_address| default('not_defined') }}     {{ route_entry.network_address_variable| default('not_defined') }}     msg=transport_mngt_vpn route_entry.network_address
    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].prefix.subnetMask   {{ route_entry.subnet_mask| default('not_defined') }}     {{ route_entry.subnet_mask_variable| default('not_defined') }}     msg=transport_mngt_vpn route_entry.subnet_mask
    ${gateway_raw}=    Evaluate    "{{ route_entry.gateway | default(defaults.sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_static_routes.gateway) }}"
    ${gateway}=    Run Keyword If    '${gateway_raw}' == 'nexthop'    Set Variable    nextHop    ELSE    Set Variable    ${gateway_raw}
    Should Be Equal Value Json String    ${transport_mngt_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].gateway.value   ${gateway}     msg=transport_mngt_vpn route_entry.gateway
    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].distance  {{ route_entry.administrative_distance | default('not_defined') }}     {{ route_entry.administrative_distance_variable | default('not_defined') }}     msg=transport_mngt_vpn route_entry.admin_distance

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

    Should Be Equal Value Json List Length   ${transport_mngt_vpn[0]}  data.ipv4Route[${outer_loop_index}].nextHop  {{ route_entry.get('next_hops', []) | length }}    msg=transport_mngt_vpn wan_vpn next_hops length
    
{% if route_entry.next_hops is defined and route_entry.get('next_hops', []) | length > 0 %}
    
    Log   ======Next Hops=======
    
{% for nh_entry in route_entry.next_hops | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv4Route[${outer_loop_index}].nextHop[{{ loop.index0 }}].address    {{ nh_entry.address | default('not_defined') }}   {{ nh_entry.address_variable | default('not_defined') }}    msg=transport_mngt_vpn mngt_vpn nh_entry.address
    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv4Route[${outer_loop_index}].nextHop[{{ loop.index0 }}].distance    {{ nh_entry.administrative_distance | default('not_defined') }}    {{ nh_entry.administrative_distance_variable| default('not_defined') }}    msg=transport_mngt_vpn mngt_vpn nh_entry.admin_distance
    
{% endfor %}
    
{% endif %}
    
{% endfor %}
    
{% endif %}  

    Should Be Equal Value Json List Length   ${transport_mngt_vpn[0]}  data.ipv6Route  {{ profile.management_vpn.get('ipv6_static_routes', []) | length }}    msg=ipv6 static routes length

{% if profile.management_vpn.ipv6_static_routes is defined and profile.management_vpn.get('ipv6_static_routes', [])|length > 0 %}

    Log   ======IPv6 Static Routes=======

{% for ipv6_route in profile.management_vpn.ipv6_static_routes | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].prefix   {{ ipv6_route.prefix| default('not_defined') }}     {{ ipv6_route.prefix_variable| default('not_defined') }}     msg=transport_mgnt_vpn route_entry.prefix
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

    Should Be Equal Value Json List Length   ${transport_mngt_vpn[0]}  data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop  {{ ipv6_route.get('next_hops', []) | length }}    msg=transport_mngt_vpn ipv6 route next_hops length

{% for hop in ipv6_route.next_hops | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].address    {{ hop.address | default('not_defined') }}     {{ hop.address_variable | default('not_defined') }}    msg=transport_mngt_vpn wan_vpn nh6_entry.address
    Should Be Equal Value Json Yaml    ${transport_mngt_vpn[0]}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].distance    {{ hop.administrative_distance | default('not_defined') }}    {{ hop.administrative_distance_variable| default('not_defined') }}    msg=transport_mngt_vpn nh6_entry.admin_distance

{% endfor %}

    Should Be Equal Value Json String    ${transport_mngt_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.null0.value    {{ true if ipv6_route.get("gateway", defaults.sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_static_routes.gateway) == 'null0' else 'not_defined' }}    msg=transport_mgnt_vpn nh6_entry.null0
    ${nat_value}=    Set Variable    {{ ipv6_route.nat | default('not_defined') }}
    Should Be Equal Value Json String    ${transport_mngt_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.nat.value    ${nat_value}    msg=transport_mgnt_vpn nh6_entry.nat

{% endfor %}

{% endif %} 

    ${trans_mngt_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/management/vpn/${vpn_parcel_id}/interface/ethernet
    ${trans_mngt_vpn_intf}=    Json Search List    ${trans_mngt_vpn_intf_res.json()}    data[].payload
    Set Suite Variable    ${trans_mngt_vpn_intf}
    Should Be Equal Value Json List Length   ${trans_mngt_vpn_intf}   @   {{ profile.management_vpn.get('ethernet_interfaces', []) | length }}    msg=transport_mngt_vpn ethernet interfaces length

{% if profile.management_vpn.ethernet_interfaces is defined and profile.management_vpn.get('ethernet_interfaces', [])|length > 0 %}

    Log   ======Ethernet Interfaces=======

{% for intf_entry in profile.management_vpn.ethernet_interfaces | default([]) %}

    ${r_interface_name}=    Json Search    ${trans_mngt_vpn_intf}    [?name=='{{ intf_entry.name }}'] | [0]
    Run Keyword If    $r_interface_name is None    Fail    Interface '{{ intf_entry.name }}' should be present on the Manager

    Should Be Equal Value Json String   ${r_interface_name}  name  {{ intf_entry.name | default('not_defined') }}  msg=transport_mngt_vpn_interface name
    Should Be Equal Value Json Special_String   ${r_interface_name}    description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}    msg=transport_mngt_vpn interface feature description

    Should Be Equal Value Json Yaml   ${r_interface_name}    data.interfaceName    {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}   msg=transport_mngt_vpn wan_vpn interface interface_name
    Should Be Equal Value Json Special_String    ${r_interface_name}    data.description.value  {{ intf_entry.interface_description | default('not_defined') | normalize_special_string }}   msg=transport_mngt_vpn interface interface_description

    # 20.15 uses data.intfIpAddress.static/dynamic directly; 20.18+ wraps it under data.intfIpAddress.either.static/dynamic
    ${ipv4_either_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.either
    IF    ${ipv4_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.addressType    {{ intf_entry.ipv4_address_type | default('not_defined') }}    {{ intf_entry.ipv4_address_type_variable | default('not_defined') }}    msg=transport_mngt_vpn wan_vpn interface ipv4_address_type
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.ipAddress   {{ intf_entry.ipv4_address| default('not_defined') }}     {{ intf_entry.ipv4_address_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.subnetMask   {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}     {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.either.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses', []) | length }}    msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml     ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress   {{ sec_addr.address | default('not_defined') }}     {{ sec_addr.address_variable | default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_address
        Should Be Equal Value Json Yaml     ${r_interface_name}   data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask   {{ sec_addr.subnet_mask | default('not_defined') }}     {{ sec_addr.subnet_mask_variable | default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_subnet_mask
{% endfor %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.dynamic.dynamicDhcpDistance   {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}     {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_dhcp_distance
    ELSE
        # below 20.18
        ${ipv4_static_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.static
        ${ipv4_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.dynamic
        ${detected_ipv4_type}=    Set Variable If    ${ipv4_static_check} != []    static    ${ipv4_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv4_type}    {{ intf_entry.ipv4_address_type | default('not_defined') }}    msg=transport_mngt_vpn interface ipv4_address_type detected from JSON structure
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.ipAddress   {{ intf_entry.ipv4_address| default('not_defined') }}     {{ intf_entry.ipv4_address_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.subnetMask   {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}     {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses', []) | length }}    msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml     ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress   {{ sec_addr.address | default('not_defined') }}     {{ sec_addr.address_variable | default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_address
        Should Be Equal Value Json Yaml     ${r_interface_name}   data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask   {{ sec_addr.subnet_mask | default('not_defined') }}     {{ sec_addr.subnet_mask_variable | default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_secondary_subnet_mask
{% endfor %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.dynamic.dynamicDhcpDistance   {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}     {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_dhcp_distance
    END
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.dhcpHelper   {{ intf_entry.ipv4_dhcp_helpers| default('not_defined') }}     {{ intf_entry.ipv4_dhcp_helpers_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv4_dhcp_helpers
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.iperfServer   {{ intf_entry.iperf_server| default('not_defined') }}     {{ intf_entry.iperf_server_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface iperf_server
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.autoDetectBandwidth   {{ intf_entry.auto_detect_bandwidth| default('not_defined') }}     {{ intf_entry.auto_detect_bandwidth_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface auto_detect_bandwidth
    ${ipv6_either_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.either
    IF    ${ipv6_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.addressType    {{ intf_entry.ipv6_address_type | default('not_defined') }}    {{ intf_entry.ipv6_address_type_variable | default('not_defined') }}    msg=transport_mngt_vpn wan_vpn interface ipv6_address_type
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.static.primaryIpV6Address.address   {{ intf_entry.ipv6_address| default('not_defined') }}     {{ intf_entry.ipv6_address_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv6_address
    ELSE
        # below 20.18
        ${ipv6_static_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.static
        ${ipv6_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.dynamic
        ${detected_ipv6_type}=    Set Variable If    ${ipv6_static_check} != []    static    ${ipv6_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv6_type}    {{ intf_entry.ipv6_address_type | default('not_defined') }}    msg=transport_mngt_vpn interface ipv6_address_type detected from JSON structure
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.static.primaryIpV6Address.address   {{ intf_entry.ipv6_address| default('not_defined') }}     {{ intf_entry.ipv6_address_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ipv6_address
    END

    Should Be Equal Value Json List Length   ${r_interface_name}    data.arp   {{ intf_entry.get('arp_entries', []) | length }}    msg=transport_mngt_vpn wan_vpn interface arp entries length

{% if intf_entry.arp_entries is defined and intf_entry.get('arp_entries', [])|length > 0 %}

    Log      === Arp Entries ===

{% for arp_entry in intf_entry.arp_entries | default([]) %}

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.arp[{{ loop.index0 }}].ipAddress   {{ arp_entry.ip_address| default('not_defined') }}     {{ arp_entry.ip_address_variable| default('not_defined') }}     msg=transport_mngt_vpn intf arp_entry.ip_address
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.arp[{{ loop.index0 }}].macAddress   {{ arp_entry.mac_address| default('not_defined') }}     {{ arp_entry.mac_address_variable| default('not_defined') }}     msg=transport_mngt_vpn intf arp_entry.mac_address

{% endfor %}

{% endif %}

    Log      === Advanced Features ===

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.duplex   {{ intf_entry.duplex| default('not_defined') }}     {{ intf_entry.duplex_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface duplex
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.macAddress   {{ intf_entry.mac_address| default('not_defined') }}     {{ intf_entry.mac_address_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface mac_address
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipMtu   {{ intf_entry.ip_mtu| default('not_defined') }}     {{ intf_entry.ip_mtu_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ip_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.intrfMtu   {{ intf_entry.interface_mtu| default('not_defined') }}     {{ intf_entry.interface_mtu_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface interface_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tcpMss   {{ intf_entry.tcp_mss| default('not_defined') }}     {{ intf_entry.tcp_mss_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.speed   {{ intf_entry.speed| default('not_defined') }}     {{ intf_entry.speed_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface speed
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.arpTimeout   {{ intf_entry.arp_timeout| default('not_defined') }}     {{ intf_entry.arp_timeout_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface arp_timeout
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.autonegotiate   {{ intf_entry.autonegotiate| default('not_defined') }}     {{ intf_entry.autonegotiate_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface autonegotiate
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.mediaType   {{ intf_entry.media_type| default('not_defined') }}     {{ intf_entry.media_type_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface media_type
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.loadInterval   {{ intf_entry.load_interval| default('not_defined') }}     {{ intf_entry.load_interval_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface load_interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.icmpRedirectDisable   {{ intf_entry.icmp_redirect_disable| default('not_defined') }}     {{ intf_entry.icmp_redirect_disable_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface icmp_redirect_disable
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipDirectedBroadcast   {{ intf_entry.ip_directed_broadcast| default('not_defined') }}     {{ intf_entry.ip_directed_broadcast_variable| default('not_defined') }}     msg=transport_mngt_vpn wan_vpn interface ip_directed_broadcast

{% endfor %}

{% endif %}

{% endif %}
    
{% endfor %}

{% endif %}

{% endif %}