*** Settings ***
Documentation   Verify Transport Feature Profile Configuration WAN VPN
Name            Transport Profiles WAN VPN 
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    wan_vpn
Resource        ../../../sdwan_common.resource

{% set profile_wan_vpn = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
 {% if profile.wan_vpn is defined %}
  {% set _ = profile_wan_vpn.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_wan_vpn != [] %}


*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}
    
{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.wan_vpn is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} WAN VPN {{ profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name) }}

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${transport_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}
    ${wan_vpn_subparcels}=    Json Search List    ${transport_res.json()}    associatedProfileParcels[?parcelType=='wan/vpn'].subparcels | [0]
    Set Suite Variable    ${wan_vpn_subparcels}
    ${transport_wan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn
    ${transport_wan_vpn}=    Json Search List    ${transport_wan_vpn_res.json()}    data[].payload
    Run Keyword If    ${transport_wan_vpn} == []    Fail    Feature '{{ profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name) }}' expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_wan_vpn}

    Should Be Equal Value Json String    ${transport_wan_vpn[0]}    name    {{ profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name) }}    msg=transport_wan_vpn wan_vpn name
    Should Be Equal Value Json Special_String    ${transport_wan_vpn[0]}   description   {{ profile.wan_vpn.description | default('not_defined') | normalize_special_string }}   msg=transport_wan_vpn wan_vpn description
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.enhanceEcmpKeying   {{ profile.wan_vpn.enhance_ecmp_keying| default('not_defined') }}     {{ profile.wan_vpn.enhance_ecmp_keying_variable| default('not_defined') }}     msg=transport_wan_vpn enhance_ecmp_keying
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.dnsIpv4.primaryDnsAddressIpv4   {{ profile.wan_vpn.ipv4_primary_dns_address| default('not_defined') }}     {{ profile.wan_vpn.ipv4_primary_dns_address_variable| default('not_defined') }}     msg=transport_wan_vpn ipv4_primary_dns_address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.dnsIpv4.secondaryDnsAddressIpv4   {{ profile.wan_vpn.ipv4_secondary_dns_address| default('not_defined') }}     {{ profile.wan_vpn.ipv4_secondary_dns_address_variable| default('not_defined') }}     msg=transport_wan_vpn ipv4_secondary_dns_address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.dnsIpv6.primaryDnsAddressIpv6   {{ profile.wan_vpn.ipv6_primary_dns_address| default('not_defined') }}     {{ profile.wan_vpn.ipv6_primary_dns_address_variable| default('not_defined') }}     msg=transport_wan_vpn ipv6_primary_dns_address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.dnsIpv6.secondaryDnsAddressIpv6   {{ profile.wan_vpn.ipv6_secondary_dns_address| default('not_defined') }}     {{ profile.wan_vpn.ipv6_secondary_dns_address_variable| default('not_defined') }}     msg=transport_wan_vpn ipv6_secondary_dns_address

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.newHostMapping  {{ profile.wan_vpn.get('host_mappings', []) | length }}    msg=host mappings length

{% if profile.wan_vpn.host_mappings is defined and profile.wan_vpn.get('host_mappings', [])|length > 0 %}

    Log    =====Host Mappings=====

{% for host_entry in profile.wan_vpn.host_mappings | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.newHostMapping[{{ loop.index0 }}].hostName   {{ host_entry.hostname| default('not_defined') }}     {{ host_entry.hostname_variable| default('not_defined') }}     msg=transport_wan_vpn host_entry.hostname
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.newHostMapping[{{ loop.index0 }}].listOfIp   {{ host_entry.ips| default('not_defined') }}     {{ host_entry.ips_variable| default('not_defined') }}     msg=transport_wan_vpn host_entry.ips

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.ipv4Route  {{ profile.wan_vpn.get('ipv4_static_routes', []) | length }}    msg=ipv4 static routes length

{% if profile.wan_vpn.ipv4_static_routes is defined and profile.wan_vpn.get('ipv4_static_routes', [])|length > 0 %}

    Log    =====IPv4 Routes=====

{% for route_entry in profile.wan_vpn.ipv4_static_routes | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].prefix.ipAddress   {{ route_entry.network_address| default('not_defined') }}     {{ route_entry.network_address_variable| default('not_defined') }}     msg=transport_wan_vpn route_entry.network_address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].prefix.subnetMask   {{ route_entry.subnet_mask| default('not_defined') }}     {{ route_entry.subnet_mask_variable| default('not_defined') }}     msg=transport_wan_vpn route_entry.subnet_mask
    ${gateway_raw}=    Evaluate    "{{ route_entry.gateway | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.ipv4_static_routes.gateway) }}"
    ${gateway}=    Run Keyword If    '${gateway_raw}'.lower() == 'nexthop'    Set Variable    nextHop    ELSE    Set Variable    ${gateway_raw}
    Should Be Equal Value Json String    ${transport_wan_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].gateway.value   ${gateway}     msg=transport_wan_vpn route_entry.gateway
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv4Route[{{ loop.index0 }}].distance   {{ route_entry.administrative_distance| default('not_defined') }}     {{ route_entry.administrative_distance_variable| default('not_defined') }}     msg=transport_wan_vpn route_entry.admin_distance

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.ipv4Route[${outer_loop_index}].nextHop  {{ route_entry.get('next_hops', []) | length }}    msg=transport_wan_vpn wan_vpn next_hops length

{% if route_entry.next_hops is defined and route_entry.get('next_hops', []) | length > 0 %}

    Log    =====Next Hops=====

{% for nh_entry in route_entry.next_hops | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv4Route[${outer_loop_index}].nextHop[{{ loop.index0 }}].address    {{ nh_entry.address | default('not_defined') }}   {{ nh_entry.address_variable | default('not_defined') }}    msg=transport_wan_vpn wan_vpn nh_entry.address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv4Route[${outer_loop_index}].nextHop[{{ loop.index0 }}].distance    {{ nh_entry.administrative_distance | default('not_defined') }}    {{ nh_entry.administrative_distance_variable| default('not_defined') }}    msg=transport_wan_vpn wan_vpn nh_entry.admin_distance

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.ipv6Route  {{ profile.wan_vpn.get('ipv6_static_routes', []) | length }}    msg=ipv6 static routes length

{% if profile.wan_vpn.ipv6_static_routes is defined and profile.wan_vpn.get('ipv6_static_routes', [])|length > 0 %}

    Log    =====IPv6 Routes=====

{% for route_entry in profile.wan_vpn.ipv6_static_routes | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].prefix   {{ route_entry.prefix| default('not_defined') }}     {{ route_entry.prefix_variable| default('not_defined') }}     msg=transport_wan_vpn route_entry.prefix
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop  {{ route_entry.get('next_hops', []) | length }}    msg=transport_wan_vpn ipv6 route next_hops length

{% for nh_entry in route_entry.next_hops | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].address    {{ nh_entry.address | default('not_defined') }}     {{ nh_entry.address_variable | default('not_defined') }}    msg=transport_wan_vpn wan_vpn nh6_entry.address
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].distance    {{ nh_entry.administrative_distance | default('not_defined') }}    {{ nh_entry.administrative_distance_variable| default('not_defined') }}    msg=transport_wan_vpn wan_vpn nh6_entry.admin_distance

{% endfor %}

    Should Be Equal Value Json String    ${transport_wan_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.null0.value   {{ true if route_entry.gateway == 'null0' else 'not_defined' }}     msg=transport_wan_vpn wan_vpn nh6_entry.gateway
    ${nat_value}=    Set Variable    {{ route_entry.nat | default('not_defined') }}
    Should Be Equal Value Json String    ${transport_wan_vpn[0]}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.nat.value   ${nat_value}     msg=transport_wan_vpn wan_vpn nh6_entry.nat

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.nat64V4Pool  {{ profile.wan_vpn.get('nat_64_v4_pools', []) | length }}    msg=nat pools length

{% if profile.wan_vpn.nat_64_v4_pools is defined and profile.wan_vpn.get('nat_64_v4_pools', [])|length > 0 %}

    Log    =====NAT pools=====

{% for nat_pool in profile.wan_vpn.nat_64_v4_pools | default([]) %}

    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolName   {{ nat_pool.name| default('not_defined') }}     {{ nat_pool.name_variable| default('not_defined') }}     msg=nat_pool_name
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolRangeStart   {{ nat_pool.range_start| default('not_defined') }}     {{ nat_pool.range_start_variable| default('not_defined') }}     msg=nat_pool_range_start
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolRangeEnd   {{ nat_pool.range_end| default('not_defined') }}     {{ nat_pool.range_end_variable| default('not_defined') }}     msg=nat_pool_range_end
    Should Be Equal Value Json Yaml    ${transport_wan_vpn[0]}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolOverload   {{ nat_pool.overload| default('not_defined') }}     {{ nat_pool.overload_variable| default('not_defined') }}     msg=nat_pool_overload

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length   ${transport_wan_vpn[0]}  data.service  {{ profile.wan_vpn.get('services', []) | length }}    msg=services length

{% if profile.wan_vpn.services is defined %}

    ${services_list}=    Create List    {{ profile.wan_vpn.get('services', []) | join('   ') }}
    @{r_services_list}=    Create List

{% for services_entry in profile.wan_vpn.services | default([]) %}

    ${json_services}=   Json Search String   ${transport_wan_vpn[0]}   data.service[{{ loop.index0 }}].serviceType.value
    Append To List  ${r_services_list}     ${json_services}

{% endfor %}

    Lists Should Be Equal   ${services_list}   ${r_services_list}     msg=services_list     ignore_order=True

{% endif %}

    Log    ======Routing Associations=======

    Should Be Equal Value Json String    ${wan_vpn_subparcels}    [?parcelType=='routing/bgp'] | [0].payload.name   {{ profile.wan_vpn.bgp | default('not_defined') }}     msg=transport_wan_vpn wan_vpn bgp

    Should Be Equal Value Json String    ${wan_vpn_subparcels}    [?parcelType=='routing/ospf'] | [0].payload.name   {{ profile.wan_vpn.ospf | default('not_defined') }}     msg=transport_wan_vpn wan_vpn ospf

{% endif %}

{% endfor %}

{% endif %}