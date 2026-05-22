*** Settings ***
Documentation   Verify Service Profile Configuration LAN VPNs
Name            Service Profiles LAN VPNs
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    lan_vpns
Resource        ../../../sdwan_common.resource

{% set profile_lan_vpns = [] %}
{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
 {% if profile.lan_vpns is defined %}
  {% set _ = profile_lan_vpns.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_lan_vpns != [] %}

*** Test Cases ***

Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.lan_vpns is defined %}

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${service_profile_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}
    ${service_profile_features}=    Json Search List    ${service_profile_res.json()}    associatedProfileParcels
    Set Suite Variable    ${service_profile_features}
    ${tracker_objs_object}=    Json Search List    ${service_profile_features}    [?parcelType=='objecttracker']
    ${tracker_objs_group}=    Json Search List    ${service_profile_features}    [?parcelType=='objecttrackergroup']
    ${tracker_objs}=    Evaluate    ${tracker_objs_object} + ${tracker_objs_group}
    Set Suite Variable    ${tracker_objs}
    ${trackers}=    Json Search List    ${service_profile_features}    [?parcelType=='tracker']
    ${tracker_groups}=    Json Search List    ${service_profile_features}    [?parcelType=='trackergroup']
    ${trackers_for_next_hop}=    Evaluate    ${trackers} + ${tracker_groups}
    Set Suite Variable    ${trackers_for_next_hop}
    ${route_policy_objs}=    Json Search List    ${service_profile_features}    [?parcelType=='route-policy']
    Set Suite Variable    ${route_policy_objs}
    ${service_lan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn
    ${service_lan_vpn}=    Json Search List    ${service_lan_vpn_res.json()}    data[].payload
    Run Keyword If    ${service_lan_vpn} == []    Fail    Feature lan vpn expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_lan_vpn}
    
{% for lan_vpn in profile.lan_vpns | default([]) %}
Verify Feature Profiles Service Profiles {{ profile.name }} LAN VPN {{ lan_vpn.name }}
    ${service_lan_vpn_data}=    Json Search    ${service_lan_vpn}   [?name=='{{ lan_vpn.name }}'] | [0]
    Run Keyword If    $service_lan_vpn_data is None    Fail    LAN VPN '{{ lan_vpn.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${service_lan_vpn_data}    name    {{ lan_vpn.name }}    msg=service_lan_vpn lan_vpn name
    Should Be Equal Value Json Special_String    ${service_lan_vpn_data}   description   {{ lan_vpn.description | default('not_defined') | normalize_special_string }}   msg=service_lan_vpn lan_vpn description
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.vpnId   {{ lan_vpn.vpn_id| default('not_defined') }}     {{ lan_vpn.vpn_id_variable| default('not_defined') }}     msg=service_lan_vpn vpn_id
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.name   {{ lan_vpn.vpn_name| default('not_defined') }}     {{ lan_vpn.vpn_name_variable| default('not_defined') }}     msg=service_lan_vpn vpn_name
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.dnsIpv4.primaryDnsAddressIpv4   {{ lan_vpn.ipv4_primary_dns_address| default('not_defined') }}     {{ lan_vpn.ipv4_primary_dns_address_variable| default('not_defined') }}     msg=service_lan_vpn ipv4_primary_dns_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.dnsIpv4.secondaryDnsAddressIpv4   {{ lan_vpn.ipv4_secondary_dns_address| default('not_defined') }}     {{ lan_vpn.ipv4_secondary_dns_address_variable| default('not_defined') }}     msg=service_lan_vpn ipv4_secondary_dns_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdminDistance      {{ lan_vpn.ipv4_omp_admin_distance| default('not_defined') }}     {{ lan_vpn.ipv4_omp_admin_distance_variable| default('not_defined') }}     msg=service_lan_vpn ipv4_omp_admin_distance
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.dnsIpv6.primaryDnsAddressIpv6   {{ lan_vpn.ipv6_primary_dns_address| default('not_defined') }}     {{ lan_vpn.ipv6_primary_dns_address_variable| default('not_defined') }}     msg=service_lan_vpn ipv6_primary_dns_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.dnsIpv6.secondaryDnsAddressIpv6   {{ lan_vpn.ipv6_secondary_dns_address| default('not_defined') }}     {{ lan_vpn.ipv6_secondary_dns_address_variable| default('not_defined') }}     msg=service_lan_vpn ipv6_secondary_dns_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdminDistanceIpv6   {{ lan_vpn.ipv6_omp_admin_distance| default('not_defined') }}     {{ lan_vpn.ipv6_omp_admin_distance_variable| default('not_defined') }}     msg=service_lan_vpn ipv6_omp_admin_distance

    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.newHostMapping  {{ lan_vpn.get('host_mappings', []) | length }}    msg=host mappings length
{% if lan_vpn.host_mappings is defined and lan_vpn.get('host_mappings', [])|length > 0 %}
    Log    =====Host Mappings=====
{% for host_entry in lan_vpn.host_mappings | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.newHostMapping[{{ loop.index0 }}].hostName   {{ host_entry.hostname| default('not_defined') }}     {{ host_entry.hostname_variable| default('not_defined') }}     msg=service_lan_vpn host_entry.hostname
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.newHostMapping[{{ loop.index0 }}].listOfIp   {{ host_entry.ips| default('not_defined') }}     {{ host_entry.ips_variable| default('not_defined') }}     msg=service_lan_vpn host_entry.ips
{% endfor %}
{% endif %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.greRoute  {{ lan_vpn.get('gre_routes', []) | length }}    msg=gre routes length
{% if lan_vpn.gre_routes is defined and lan_vpn.get('gre_routes', [])|length > 0 %}
    Log    =====GRE Routes=====
{% for gre_entry in lan_vpn.gre_routes | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.greRoute[{{ loop.index0 }}].prefix.ipAddress    {{ gre_entry.network_address|default('not_defined') }}   {{ gre_entry.network_address_variable|default('not_defined') }}   msg=gre_route network_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.greRoute[{{ loop.index0 }}].interface   {{ gre_entry.interfaces|default('not_defined') }}   {{ gre_entry.interfaces_variable|default('not_defined') }}   msg=gre_route interfaces
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.greRoute[{{ loop.index0 }}].prefix.subnetMask    {{ gre_entry.subnet_mask|default('not_defined') }}   {{ gre_entry.subnet_mask_variable|default('not_defined') }}   msg=gre_route subnet_mask
{% endfor %}
{% endif %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipsecRoute  {{ lan_vpn.get('ipsec_routes', []) | length }}    msg=ipsec routes length
{% if lan_vpn.ipsec_routes is defined and lan_vpn.get('ipsec_routes', [])|length > 0 %}
    Log    =====IPSEC Routes=====
{% for ipsec_entry in lan_vpn.ipsec_routes | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipsecRoute[{{ loop.index0 }}].prefix.ipAddress   {{ ipsec_entry.network_address|default('not_defined') }}   {{ ipsec_entry.network_address_variable|default('not_defined') }}   msg=ipsec_route network_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipsecRoute[{{ loop.index0 }}].interface   {{ ipsec_entry.interfaces|default('not_defined') }}   {{ ipsec_entry.interfaces_variable|default('not_defined') }}   msg=ipsec_route interfaces
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipsecRoute[{{ loop.index0 }}].prefix.subnetMask   {{ ipsec_entry.subnet_mask|default('not_defined') }}   {{ ipsec_entry.subnet_mask_variable|default('not_defined') }}   msg=ipsec_route subnet_mask
{% endfor %}
{% endif %}

    # ===== OMP Advertise IPv4 Routes =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ompAdvertiseIp4  {{ lan_vpn.get('ipv4_omp_advertise_routes', []) | length }}    msg=omp advertise ipv4 routes length
{% if lan_vpn.ipv4_omp_advertise_routes is defined and lan_vpn.get('ipv4_omp_advertise_routes', [])|length > 0 %}
    Log    =====OMP Advertise IPv4 Routes=====
{% for omp4_entry in lan_vpn.ipv4_omp_advertise_routes | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[{{ loop.index0 }}].ompProtocol  {{ omp4_entry.protocol|default('not_defined') }}   {{ omp4_entry.protocol_variable|default('not_defined') }}   msg=ipv4_omp_advertise_routes protocol
{% if omp4_entry.route_policy is defined %}
    ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ omp4_entry.route_policy }}']
    ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
    Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Route-policy '{{ omp4_entry.route_policy }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${route_policy_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[{{ loop.index0 }}].routePolicy.refId    ${route_policy_id}    not_defined    msg=route_policy refId
    
{% if omp4_entry.protocol == 'network' and omp4_entry.networks is defined %}
    Should Be Equal Value Json List Length    ${service_lan_vpn_data}    data.ompAdvertiseIp4[{{ loop.index0 }}].prefixList    {{ omp4_entry.networks | length }}    msg=ipv4_omp_advertise_routes networks length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
    {% for net in omp4_entry.networks %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix.address   {{ net.network_address|default('not_defined') }}   {{ net.network_address_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes network_address
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix.mask    {{ net.subnet_mask|default('not_defined') }}    {{ net.subnet_mask_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes subnet_mask
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].region   {{ net.region|default('not_defined') }}   {{ net.region_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes region
    {% endfor %}
{% elif omp4_entry.protocol == 'aggregate' and omp4_entry.aggregates is defined %}
    Should Be Equal Value Json List Length    ${service_lan_vpn_data}    data.ompAdvertiseIp4[{{ loop.index0 }}].prefixList    {{ omp4_entry.aggregates | length }}    msg=ipv4_omp_advertise_routes aggregates length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
    {% for agg in omp4_entry.aggregates %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix.address   {{ agg.aggregate_address|default('not_defined') }}   {{ agg.aggregate_address_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes aggregate_address
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix.mask    {{ agg.subnet_mask|default('not_defined') }}   {{ agg.subnet_mask_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes aggregate_subnet_mask
        Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].aggregateOnly.value    {{ agg.aggregate_only|default('not_defined') }}    msg=ipv4_omp_advertise_routes aggregate_only
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIp4[${outer_loop_index}].prefixList[{{ loop.index0 }}].region   {{ agg.region|default('not_defined') }}   {{ agg.region_variable|default('not_defined') }}    msg=ipv4_omp_advertise_routes region
    {% endfor %}
{% endif %}
{% endfor %}
{% endif %}
    # ===== OMP Advertise IPv6 Routes =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ompAdvertiseIpv6  {{ lan_vpn.get('ipv6_omp_advertise_routes', []) | length }}    msg=omp advertise ipv6 routes length
{% if lan_vpn.ipv6_omp_advertise_routes is defined and lan_vpn.get('ipv6_omp_advertise_routes', [])|length > 0 %}
    Log    =====OMP Advertise IPv6 Routes=====
{% for omp6_entry in lan_vpn.ipv6_omp_advertise_routes | default([]) %}

    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[{{ loop.index0 }}].ompProtocol   {{ omp6_entry.protocol | default('not_defined') }}   {{ omp6_entry.protocol_variable|default('not_defined') }}   msg=ipv6_omp_advertise_routes protocol
{% if omp6_entry.route_policy is defined %}
    ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ omp6_entry.route_policy }}']
    ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
    Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Route-policy '{{ omp6_entry.route_policy }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${route_policy_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.ompAdvertiseIpv6[{{ loop.index0 }}].routePolicy.refId   ${route_policy_id}  not_defined  msg=ipv6_omp_advertise_routes route_policy
{% if omp6_entry.protocol == 'network' and omp6_entry.networks is defined %}
    Should Be Equal Value Json List Length    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[{{ loop.index0 }}].prefixList    {{ omp6_entry.networks | length }}    msg=ipv6_omp_advertise_routes networks length
        ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
        {% for net in omp6_entry.networks %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix   {{ net.prefix|default('not_defined') }}   {{ net.prefix_variable|default('not_defined') }}    msg==ipv6_omp_advertise_routes prefix
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[${outer_loop_index}].prefixList[{{ loop.index0 }}].region   {{ net.region|default('not_defined') }}   {{ net.region_variable|default('not_defined') }}    msg=ipv6_omp_advertise_routes region
        {% endfor %}
{% elif omp6_entry.protocol == 'aggregate' and omp6_entry.aggregates is defined %}
        Should Be Equal Value Json List Length    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[{{ loop.index0 }}].prefixList    {{ omp6_entry.aggregates | length }}    msg=ipv6_omp_advertise_routes aggregates length
        ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
        {% for agg in omp6_entry.aggregates %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[${outer_loop_index}].prefixList[{{ loop.index0 }}].prefix   {{ agg.aggregate_prefix|default('not_defined') }}   {{ agg.aggregate_prefix_variable|default('not_defined') }}    msg=ipv6_omp_advertise_routes aggregate_prefix
            Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[${outer_loop_index}].prefixList[{{ loop.index0 }}].aggregateOnly.value   {{ agg.aggregate_only|default('not_defined') }}    msg=ipv6_omp_advertise_routes aggregate_only
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ompAdvertiseIpv6[${outer_loop_index}].prefixList[{{ loop.index0 }}].region   {{ agg.region|default('not_defined') }}   {{ agg.region_variable|default('not_defined') }}    msg=ipv6_omp_advertise_routes region
       {% endfor %}
{% endif %}
{% endfor %}
{% endif %}
    # ===== LAN VPN IPv4 Static Routes =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}    data.ipv4Route    {{ lan_vpn.get('ipv4_static_routes', []) | length }}    msg=ipv4 static routes length
{% if lan_vpn.ipv4_static_routes is defined and lan_vpn.get('ipv4_static_routes', [])|length > 0 %}
    Log    =====IPv4 Static Routes=====
{% for route_entry in lan_vpn.ipv4_static_routes | default([]) %}

    Log    =====IPv4 Static Route {{ route_entry.network_address|default (route_entry.network_address_variable) }}=====
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[{{ loop.index0 }}].prefix.ipAddress   {{ route_entry.network_address|default('not_defined') }}   {{ route_entry.network_address_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route network_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[{{ loop.index0 }}].prefix.subnetMask   {{ route_entry.subnet_mask|default('not_defined') }}   {{ route_entry.subnet_mask_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route subnet_mask

    Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ipv4Route[{{ loop.index0 }}].oneOfIpRoute.null0.value    {{ 'True' if route_entry.get('gateway', 'nexthop') == 'null0' else 'not_defined' }}   msg=lan_vpn_ipv4_route gateway null0
    Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ipv4Route[{{ loop.index0 }}].oneOfIpRoute.dhcp.value   {{ 'True' if route_entry.get('gateway', 'nexthop') == 'dhcp' else 'not_defined' }}   msg=lan_vpn_ipv4_route gateway dhcp
    Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ipv4Route[{{ loop.index0 }}].oneOfIpRoute.vpn.value  {{ 'True' if route_entry.get('gateway', 'nexthop') == 'vpn' else 'not_defined' }}   msg=lan_vpn_ipv4_route gateway vpn

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
{% if route_entry.get('gateway', defaults.sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.gateway) == 'nexthop' %}
    ${nexthop_json}=    Json Search List    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer
    ${gateway_value}=    Set Variable If    ${nexthop_json} != []    nexthop    not_defined
    Should Be Equal    ${gateway_value}    nexthop    msg=lan_vpn_ipv4_route gateway nexthop
{% endif %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop   {{ route_entry.get('next_hops', []) | length }}    msg=lan_vpn_ipv4_route next_hops length
{% if route_entry.next_hops is defined and route_entry.get('next_hops', []) | length > 0 %}
    Log    =====Next Hops=====
{% for nh_entry in route_entry.next_hops | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].address   {{ nh_entry.address|default('not_defined') }}   {{ nh_entry.address_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route nh_entry.address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].distance   {{ nh_entry.administrative_distance|default('not_defined') }}   {{ nh_entry.administrative_distance_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route nh_entry.admin_distance
{% endfor %}
{% endif %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHopWithTracker  {{ route_entry.get('next_hops_with_tracker', []) | length }}    msg=lan_vpn_ipv4_route next_hops with tracker length
{% if route_entry.next_hops_with_tracker is defined and route_entry.get('next_hops_with_tracker', []) | length > 0 %}
    Log    =====Next Hops With Tracker=====
{% for nh_entry in route_entry.next_hops_with_tracker | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHopWithTracker[{{ loop.index0 }}].address   {{ nh_entry.address|default('not_defined') }}   {{ nh_entry.address_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route nh_entry.address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHopWithTracker[{{ loop.index0 }}].distance   {{ nh_entry.administrative_distance|default('not_defined') }}   {{ nh_entry.administrative_distance_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route nh_entry.admin_distance
    # --- Tracker RefId Check for nextHopWithTracker ---
{% if nh_entry.tracker is defined %}
    ${tracker_nh}=    Evaluate    [x for x in ${trackers_for_next_hop} if x['payload']['name']=='{{ nh_entry.tracker }}']
    ${tracker_nh_id}=     Json Search String    ${tracker_nh}    [0].parcelId
    Run Keyword If    '${tracker_nh_id}' == 'not_defined'    Fail    Tracker '{{ nh_entry.tracker }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${tracker_nh_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHopWithTracker[{{ loop.index0 }}].tracker.refId   ${tracker_nh_id}  not_defined  msg=lan_vpn_ipv4_route tracker
{% endfor %}
{% endif %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.distance   {{ route_entry.administrative_distance|default('not_defined') }}   {{ route_entry.administrative_distance_variable|default('not_defined') }}   msg=lan_vpn_ipv4_route null0_administrative_distance

    Log    =====Static Route Interface=====
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipStaticRouteInterface[0].interfaceName   {{ route_entry.get('static_route_interface', {}).get('interface_name', 'not_defined') }}   {{ route_entry.get('static_route_interface', {}).get('interface_name_variable', 'not_defined') }}   msg=static_route_interface interface_name
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv4Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipStaticRouteInterface[0].nextHop   {{ route_entry.get('static_route_interface', {}).get('next_hops', []) | length }}    msg=static_route_interface next_hops length
{% if route_entry.get('static_route_interface', {}).get('next_hops', []) is defined and route_entry.get('static_route_interface', {}).get('next_hops', []) | length > 0 %}
{% for nh_iface in route_entry.get('static_route_interface', {}).get('next_hops', []) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipStaticRouteInterface[0].nextHop[{{ loop.index0 }}].address   {{ nh_iface.address|default('not_defined') }}   {{ nh_iface.address_variable|default('not_defined') }}   msg=static_route_interface next_hop address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv4Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipStaticRouteInterface[0].nextHop[{{ loop.index0 }}].distance   {{ nh_iface.administrative_distance|default('not_defined') }}   {{ nh_iface.administrative_distance_variable|default('not_defined') }}   msg=static_route_interface next_hop admin_distance
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
    # ===== LAN VPN IPv6 Static Routes =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv6Route  {{ lan_vpn.get('ipv6_static_routes', []) | length }}    msg=ipv6 static routes length
{% if lan_vpn.ipv6_static_routes is defined and lan_vpn.get('ipv6_static_routes', [])|length > 0 %}
    Log    =====IPv6 Static Routes=====
{% for route_entry in lan_vpn.ipv6_static_routes | default([]) %}

    Log    =====IPv6 Static Route {{ route_entry.prefix|default(route_entry.prefix_variable) }}=====
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[{{ loop.index0 }}].prefix   {{ route_entry.prefix|default('not_defined') }}   {{ route_entry.prefix_variable|default('not_defined') }}   msg=lan_vpn_ipv6_route prefix

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
{% if route_entry.get('gateway', defaults.sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.gateway) == 'nexthop' %}
    ${nexthop_json}=    Json Search List    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer
    ${gateway_value}=    Set Variable If    ${nexthop_json} != []    nexthop    not_defined
    Should Be Equal    ${gateway_value}    nexthop    msg=lan_vpn_ipv6_route gateway nexthop
{% endif %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop   {{ route_entry.get('next_hops', []) | length }}    msg=lan_vpn_ipv6_route next_hops length
{% if route_entry.next_hops is defined and route_entry.get('next_hops', []) | length > 0 %}
    Log    =====Next Hops=====
{% for nh_entry in route_entry.next_hops | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].address   {{ nh_entry.address|default('not_defined') }}   {{ nh_entry.address_variable|default('not_defined') }}   msg=lan_vpn_ipv6_route nh6_entry.address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.nextHopContainer.nextHop[{{ loop.index0 }}].distance   {{ nh_entry.administrative_distance|default('not_defined') }}   {{ nh_entry.administrative_distance_variable|default('not_defined') }}   msg=lan_vpn_ipv6_route nh6_entry.admin_distance
{% endfor %}
{% endif %}
    Should Be Equal Value Json String    ${service_lan_vpn_data}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.null0.value   {{ 'True' if route_entry.get('gateway', 'nexthop') == 'null0' else 'not_defined' }}   msg=lan_vpn_ipv6_route null0_gateway
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.ipv6Route[{{ loop.index0 }}].oneOfIpRoute.nat  {{ route_entry.nat | default('not_defined') }}   {{ route_entry.nat_variable|default('not_defined') }}   msg=lan_vpn_ipv6_route nat

    Log    =====IPv6 Static Route Interface=====
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipv6StaticRouteInterface[0].interfaceName   {{ route_entry.get('static_route_interface', {}).get('interface_name', 'not_defined') }}   {{ route_entry.get('static_route_interface', {}).get('interface_name_variable', 'not_defined') }}   msg=ipv6_static_route_interface interface_name
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.ipv6Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipv6StaticRouteInterface[0].nextHop   {{ route_entry.get('static_route_interface', {}).get('next_hops', []) | length }}    msg=ipv6_static_route_interface next_hops length
{% if route_entry.get('static_route_interface', {}).get('next_hops', []) is defined and route_entry.get('static_route_interface', {}).get('next_hops', []) | length > 0 %}
{% for nh_iface in route_entry.get('static_route_interface', {}).get('next_hops', []) %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipv6StaticRouteInterface[0].nextHop[{{ loop.index0 }}].address   {{ nh_iface.address|default('not_defined') }}   {{ nh_iface.address_variable|default('not_defined') }}   msg=ipv6_static_route_interface next_hop address
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.ipv6Route[${outer_loop_index}].oneOfIpRoute.interfaceContainer.ipv6StaticRouteInterface[0].nextHop[{{ loop.index0 }}].distance   {{ nh_iface.administrative_distance|default('not_defined') }}   {{ nh_iface.administrative_distance_variable|default('not_defined') }}   msg=ipv6_static_route_interface next_hop admin_distance
{% endfor %}
{% endif %}

{% endfor %}
{% endif %}
    # ===== NAT Pools =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.natPool  {{ lan_vpn.get('nat_pools', []) | length }}    msg=nat pools length
{% if lan_vpn.nat_pools is defined and lan_vpn.get('nat_pools', [])|length > 0 %}
    Log    =====NAT Pools=====
{% for nat_entry in lan_vpn.nat_pools | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].natPoolName   {{ nat_entry.id|default('not_defined') }}   {{ nat_entry.id_variable|default('not_defined') }}   msg=nat_pool id
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].rangeStart   {{ nat_entry.range_start|default('not_defined') }}   {{ nat_entry.range_start_variable|default('not_defined') }}   msg=nat_pool range_start
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].rangeEnd   {{ nat_entry.range_end|default('not_defined') }}   {{ nat_entry.range_end_variable|default('not_defined') }}   msg=nat_pool range_end
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].overload   {{ nat_entry.overload|default('not_defined') }}   {{ nat_entry.overload_variable|default('not_defined') }}   msg=nat_pool overload
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].direction   {{ nat_entry.direction|default('not_defined') }}   {{ nat_entry.direction_variable|default('not_defined') }}   msg=nat_pool direction
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].prefixLength  {{ nat_entry.prefix_length|default('not_defined') }}   {{ nat_entry.prefix_length_variable|default('not_defined') }}   msg=nat_pool prefix_length
    # --- Tracker Object RefId Check ---
{% if nat_entry.tracker_object is defined %}
    ${tracker_obj}=    Evaluate    [x for x in ${tracker_objs} if x['payload']['name']=='{{ nat_entry.tracker_object }}']
    ${tracker_obj_id}=     Json Search String    ${tracker_obj}    [0].parcelId
    Run Keyword If    '${tracker_obj_id}' == 'not_defined'    Fail    Tracker object '{{ nat_entry.tracker_object }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${tracker_obj_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.natPool[{{ loop.index0 }}].trackingObject.trackerId.refId   ${tracker_obj_id}  not_defined  msg=nat_pool tracker_object

{% endfor %}
{% endif %}
    # ===== NAT Port Forward =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.natPortForward  {{ lan_vpn.get('nat_port_forwards', []) | length }}    msg=nat port forward length
{% if lan_vpn.nat_port_forwards is defined and lan_vpn.get('nat_port_forwards', [])|length > 0 %}
    Log    =====NAT Port Forward=====
{% for natpf_entry in lan_vpn.nat_port_forwards | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].natPoolName   {{ natpf_entry.nat_pool_id|default('not_defined') }}   {{ natpf_entry.nat_pool_id_variable|default('not_defined') }}   msg=nat_port_forward nat_pool_id
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].sourcePort   {{ natpf_entry.source_port|default('not_defined') }}   {{ natpf_entry.source_port_variable|default('not_defined') }}   msg=nat_port_forward source_port
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].translatePort   {{ natpf_entry.translate_port|default('not_defined') }}   {{ natpf_entry.translate_port_variable|default('not_defined') }}   msg=nat_port_forward translate_port
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].sourceIp   {{ natpf_entry.source_ip|default('not_defined') }}   {{ natpf_entry.source_ip_variable|default('not_defined') }}   msg=nat_port_forward source_ip
    ${translatedSourceIp}=     Json Search List    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].TranslatedSourceIp
    Run Keyword If    ${translatedSourceIp} != []    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].TranslatedSourceIp   {{ natpf_entry.translate_ip|default('not_defined') }}   {{ natpf_entry.translate_ip_variable|default('not_defined') }}   msg=nat_port_forward translate_ip
    ...    ELSE    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].translatedSourceIp   {{ natpf_entry.translate_ip|default('not_defined') }}   {{ natpf_entry.translate_ip_variable|default('not_defined') }}   msg=nat_port_forward translate_ip
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.natPortForward[{{ loop.index0 }}].protocol   {{ natpf_entry.protocol| default('not_defined') }}   {{ natpf_entry.protocol_variable|default('not_defined') }}   msg=nat_port_forward protocol
{% endfor %}
{% endif %}

    # ===== Static NAT =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.staticNat  {{ lan_vpn.get('static_nat_entries', []) | length }}    msg=static nat length
{% if lan_vpn.static_nat_entries is defined and lan_vpn.get('static_nat_entries', [])|length > 0 %}
    Log    =====Static NAT=====
{% for snat_entry in lan_vpn.static_nat_entries | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].natPoolName   {{ snat_entry.nat_pool_id|default('not_defined') }}   {{ snat_entry.nat_pool_id_variable|default('not_defined') }}   msg=static_nat nat_pool_id
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].sourceIp   {{ snat_entry.source_ip|default('not_defined') }}   {{ snat_entry.source_ip_variable|default('not_defined') }}   msg=static_nat source_ip
    ${translatedSourceIp}=     Json Search List    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].TranslatedSourceIp
    Run Keyword If    ${translatedSourceIp} != []    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].TranslatedSourceIp   {{ snat_entry.translate_ip|default('not_defined') }}   {{ snat_entry.translate_ip_variable|default('not_defined') }}   msg=static_nat translate_ip
    ...    ELSE    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].translatedSourceIp   {{ snat_entry.translate_ip|default('not_defined') }}   {{ snat_entry.translate_ip_variable|default('not_defined') }}   msg=static_nat translate_ip
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].staticNatDirection   {{ snat_entry.direction|default('not_defined') }}   {{ snat_entry.direction_variable|default('not_defined') }}   msg=static_nat direction
    # --- Tracker Object RefId Check ---
{% if snat_entry.tracker_object is defined %}
    ${tracker_obj}=    Evaluate    [x for x in ${tracker_objs} if x['payload']['name']=='{{ snat_entry.tracker_object }}']
    ${tracker_obj_id}=     Json Search String    ${tracker_obj}    [0].parcelId
    Run Keyword If    '${tracker_obj_id}' == 'not_defined'    Fail    Tracker object '{{ snat_entry.tracker_object }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${tracker_obj_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.staticNat[{{ loop.index0 }}].trackingObject.trackerId.refId     ${tracker_obj_id}  not_defined  msg=static_nat tracker_object
{% endfor %}
{% endif %}
    # ===== Static NAT Subnets =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.staticNatSubnet  {{ lan_vpn.get('static_nat_subnets', []) | length }}    msg=static nat subnet length
{% if lan_vpn.static_nat_subnets is defined and lan_vpn.get('static_nat_subnets', [])|length > 0 %}
    Log    =====Static NAT Subnets=====
{% for snat_subnet in lan_vpn.static_nat_subnets | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNatSubnet[{{ loop.index0 }}].sourceIpSubnet   {{ snat_subnet.source_ip_subnet|default('not_defined') }}   {{ snat_subnet.source_ip_subnet_variable|default('not_defined') }}   msg=static_nat_subnet source_ip_subnet
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNatSubnet[{{ loop.index0 }}].translatedSourceIpSubnet   {{ snat_subnet.translated_source_ip_subnet|default('not_defined') }}   {{ snat_subnet.translated_source_ip_subnet_variable|default('not_defined') }}   msg=static_nat_subnet translated_source_ip_subnet
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNatSubnet[{{ loop.index0 }}].prefixLength   {{ snat_subnet.prefix_length|default('not_defined') }}   {{ snat_subnet.prefix_length_variable|default('not_defined') }}   msg=static_nat_subnet prefix_length
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.staticNatSubnet[{{ loop.index0 }}].staticNatDirection   {{ snat_subnet.direction|default('not_defined') }}   {{ snat_subnet.direction_variable|default('not_defined') }}   msg=static_nat_subnet direction
    # --- Tracker Object RefId Check ---
{% if snat_subnet.tracker_object is defined %}
    ${tracker_obj}=    Evaluate    [x for x in ${tracker_objs} if x['payload']['name']=='{{ snat_subnet.tracker_object }}']
    ${tracker_obj_id}=     Json Search String    ${tracker_obj}    [0].parcelId
    Run Keyword If    '${tracker_obj_id}' == 'not_defined'    Fail    Tracker object '{{ snat_subnet.tracker_object }}' not found in Manager for profile '{{ profile.name }}'
{% else %}
    ${tracker_obj_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml   ${service_lan_vpn_data}    data.staticNatSubnet[{{ loop.index0 }}].trackingObject.trackerId.refId     ${tracker_obj_id}  not_defined  msg=static_nat_subnet tracker_object
{% endfor %}
{% endif %}
    # ===== NAT64 Pools =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.nat64V4Pool  {{ lan_vpn.get('nat64_pools', []) | length }}    msg=nat64 pools length
{% if lan_vpn.nat64_pools is defined and lan_vpn.get('nat64_pools', [])|length > 0 %}
    Log    =====NAT64 Pools=====
{% for nat64_entry in lan_vpn.nat64_pools | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolName   {{ nat64_entry.name|default('not_defined') }}   {{ nat64_entry.name_variable|default('not_defined') }}   msg=nat64_pool name
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolRangeStart   {{ nat64_entry.range_start|default('not_defined') }}   {{ nat64_entry.range_start_variable|default('not_defined') }}   msg=nat64_pool range_start
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolRangeEnd   {{ nat64_entry.range_end|default('not_defined') }}   {{ nat64_entry.range_end_variable|default('not_defined') }}   msg=nat64_pool range_end
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.nat64V4Pool[{{ loop.index0 }}].nat64V4PoolOverload   {{ nat64_entry.overload|default('not_defined') }}   {{ nat64_entry.overload_variable|default('not_defined') }}   msg=nat64_pool overload
{% endfor %}
{% endif %}
    # ===== Services =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.service  {{ lan_vpn.get('services', []) | length }}    msg=services length
{% if lan_vpn.services is defined and lan_vpn.get('services', [])|length > 0 %}
    Log    =====Services=====
{% for svc_entry in lan_vpn.services | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.service[{{ loop.index0 }}].serviceType   {{ svc_entry.service_type | default('not_defined') }}   {{ svc_entry.service_type_variable|default('not_defined') }}   msg=service service_type
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.service[{{ loop.index0 }}].ipv4Addresses   {{ svc_entry.ipv4_addresses|default('not_defined') }}   {{ svc_entry.ipv4_addresses_variable|default('not_defined') }}   msg=service ipv4_addresses
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.service[{{ loop.index0 }}].tracking   {{ svc_entry.track_enable|default('not_defined') }}   {{ svc_entry.track_enable_variable|default('not_defined') }}   msg=service tracking
{% endfor %}
{% endif %}
    # ===== Service Routes =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.serviceRoute  {{ lan_vpn.get('service_routes', []) | length }}    msg=service routes length
{% if lan_vpn.service_routes is defined and lan_vpn.get('service_routes', [])|length > 0 %}
    Log    =====Service Routes=====
{% for sr_entry in lan_vpn.service_routes | default([]) %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.serviceRoute[{{ loop.index0 }}].prefix.ipAddress   {{ sr_entry.network_address|default('not_defined') }}   {{ sr_entry.network_address_variable|default('not_defined') }}   msg=service_route network_address
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.serviceRoute[{{ loop.index0 }}].prefix.subnetMask   {{ sr_entry.subnet_mask|default('not_defined') }}   {{ sr_entry.subnet_mask_variable|default('not_defined') }}   msg=service_route subnet_mask
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.serviceRoute[{{ loop.index0 }}].service   {{ sr_entry.service| default('not_defined') }}   not_defined   msg=service_route service
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.serviceRoute[{{ loop.index0 }}].sseInstance   {{ sr_entry.sse_instance | default('not_defined') }}   {{ sr_entry.get('sse_instance_variable') or 'not_defined' }}   msg=service_route sse_instance
{% endfor %}
{% endif %}
    # ===== Route Leak From Global =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakFromGlobal  {{ lan_vpn.get('route_leaks_from_global', []) | length }}    msg=route leak from global length
{% if lan_vpn.route_leaks_from_global is defined and lan_vpn.get('route_leaks_from_global', [])|length > 0 %}
    Log    =====Route Leak From Global=====
{% for rlfg_entry in lan_vpn.route_leaks_from_global | default([]) %}
    {% set outer_loop_index = loop.index0 %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromGlobal[{{ outer_loop_index }}].routeProtocol   {{ rlfg_entry.protocol|default('not_defined') }}   {{ rlfg_entry.protocol_variable|default('not_defined') }}   msg=route_leak_from_global protocol
    {% if rlfg_entry.route_policy is defined %}
        ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ rlfg_entry.route_policy }}']
        ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
        Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Route-policy '{{ rlfg_entry.route_policy }}' not found in Manager for profile '{{ profile.name }}'
    {% else %}
        ${route_policy_id}=     Set Variable    not_defined
    {% endif %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromGlobal[{{ outer_loop_index }}].routePolicy.refId   ${route_policy_id}  not_defined  msg=route_leak_from_global route_policy refId
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakFromGlobal[{{ outer_loop_index }}].redistributeToProtocol  {{ rlfg_entry.get('redistributions', []) | length }}    msg=route_leak_from_global redistributions length
    {% if rlfg_entry.redistributions is defined and rlfg_entry.get('redistributions', [])|length > 0 %}
        {% for redist in rlfg_entry.redistributions %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromGlobal[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].protocol   {{ redist.protocol|default('not_defined') }}   {{ redist.protocol_variable|default('not_defined') }}   msg=route_leak_from_global redistribution protocol
            {% if redist.route_policy is defined %}
                ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ redist.route_policy }}']
                ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
                Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Redistribution route-policy '{{ redist.route_policy }}' not found in Manager for profile '{{ profile.name }}'
            {% else %}
                ${route_policy_id}=     Set Variable    not_defined
            {% endif %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromGlobal[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].policy.refId   ${route_policy_id}  not_defined  msg=route_leak_from_global redistribution route_policy refId
        {% endfor %}
    {% endif %}
{% endfor %}
{% endif %}
    # ===== Route Leak To Global =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakFromService  {{ lan_vpn.get('route_leaks_to_global', []) | length }}    msg=route_leak_to_global length
{% if lan_vpn.route_leaks_to_global is defined and lan_vpn.get('route_leaks_to_global', [])|length > 0 %}
    Log    =====Route Leak From Service=====
{% for rlfs_entry in lan_vpn.route_leaks_to_global | default([]) %}
    {% set outer_loop_index = loop.index0 %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromService[{{ outer_loop_index }}].routeProtocol   {{ rlfs_entry.protocol|default('not_defined') }}   {{ rlfs_entry.protocol_variable|default('not_defined') }}   msg=route_leak_to_global protocol
    {% if rlfs_entry.route_policy is defined %}
        ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ rlfs_entry.route_policy }}']
        ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
        Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Route-policy '{{ rlfs_entry.route_policy }}' not found in Manager for profile '{{ profile.name }}'
    {% else %}
        ${route_policy_id}=     Set Variable    not_defined
    {% endif %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromService[{{ outer_loop_index }}].routePolicy.refId   ${route_policy_id}  not_defined  msg=route_leak_to_global route_policy refId
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakFromService[{{ outer_loop_index }}].redistributeToProtocol  {{ rlfs_entry.get('redistributions', []) | length }}    msg=route_leak_to_global redistributions length
    {% if rlfs_entry.redistributions is defined and rlfs_entry.get('redistributions', [])|length > 0 %}
        {% for redist in rlfs_entry.redistributions %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromService[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].protocol   {{ redist.protocol|default('not_defined') }}   {{ redist.protocol_variable|default('not_defined') }}   msg=route_leak_to_global redistribution protocol
            {% if redist.route_policy is defined %}
                ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ redist.route_policy }}']
                ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
                Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Redistribution route-policy '{{ redist.route_policy }}' not found in Manager for profile '{{ profile.name }}'
            {% else %}
                ${route_policy_id}=     Set Variable    not_defined
            {% endif %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakFromService[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].policy.refId   ${route_policy_id}  not_defined  msg=route_leak_to_global redistribution route_policy refId
        {% endfor %}
    {% endif %}
{% endfor %}
{% endif %}
    # ===== Route Leak from another Service =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakBetweenServices  {{ lan_vpn.get('route_leaks_from_service', []) | length }}    msg=route leak from service length
{% if lan_vpn.route_leaks_from_service is defined and lan_vpn.get('route_leaks_from_service', [])|length > 0 %}
    Log    =====Route Leak from another Service=====
{% for rlbs_entry in lan_vpn.route_leaks_from_service | default([]) %}
    {% set outer_loop_index = loop.index0 %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakBetweenServices[{{ outer_loop_index }}].sourceVpn   {{ rlbs_entry.source_vpn|default('not_defined') }}   {{ rlbs_entry.source_vpn_variable|default('not_defined') }}   msg=route_leak_between_services source_vpn
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakBetweenServices[{{ outer_loop_index }}].routeProtocol   {{ rlbs_entry.protocol|default('not_defined') }}   {{ rlbs_entry.protocol_variable|default('not_defined') }}   msg=route_leak_between_services protocol
    {% if rlbs_entry.route_policy is defined %}
        ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ rlbs_entry.route_policy }}']
        ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
        Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Route-policy '{{ rlbs_entry.route_policy }}' not found in Manager for profile '{{ profile.name }}'
    {% else %}
        ${route_policy_id}=     Set Variable    not_defined
    {% endif %}
    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakBetweenServices[{{ outer_loop_index }}].routePolicy.refId   ${route_policy_id}  not_defined  msg=route_leak_between_services route_policy refId
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.routeLeakBetweenServices[{{ outer_loop_index }}].redistributeToProtocol  {{ rlbs_entry.get('redistributions', []) | length }}    msg=route_leak_between_services redistributions length
    {% if rlbs_entry.redistributions is defined and rlbs_entry.get('redistributions', [])|length > 0 %}
        {% for redist in rlbs_entry.redistributions %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakBetweenServices[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].protocol   {{ redist.protocol|default('not_defined') }}   {{ redist.protocol_variable|default('not_defined') }}   msg=route_leak_between_services redistribution protocol
            {% if redist.route_policy is defined %}
                ${route_policy_obj}=    Evaluate    [x for x in ${route_policy_objs} if x['payload']['name']=='{{ redist.route_policy }}']
                ${route_policy_id}=     Json Search String    ${route_policy_obj}    [0].parcelId
                Run Keyword If    '${route_policy_id}' == 'not_defined'    Fail    Redistribution route-policy '{{ redist.route_policy }}' not found in Manager for profile '{{ profile.name }}'
            {% else %}
                ${route_policy_id}=     Set Variable    not_defined
            {% endif %}
            Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.routeLeakBetweenServices[{{ outer_loop_index }}].redistributeToProtocol[{{ loop.index0 }}].policy.refId   ${route_policy_id}  not_defined  msg=route_leak_between_services redistribution route_policy refId
        {% endfor %}
    {% endif %}
{% endfor %}
{% endif %}
    # ===== MPLS VPN IPv4 Route Targets =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.mplsVpnIpv4RouteTarget.importRtList  {{ lan_vpn.get('ipv4_import_route_targets', []) | length }}    msg= importRtList length
    {% for rt_entry in lan_vpn.ipv4_import_route_targets | default([]) %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.mplsVpnIpv4RouteTarget.importRtList[{{ loop.index0 }}].rt   {{ rt_entry.route_target|default('not_defined') }}   {{ rt_entry.route_target_variable|default('not_defined') }}   msg=importRtList value
    {% endfor %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.mplsVpnIpv4RouteTarget.exportRtList  {{ lan_vpn.get('ipv4_export_route_targets', []) | length }}    msg=mplsVpnIpv4RouteTarget exportRtList length
    {% for rt_entry in lan_vpn.ipv4_export_route_targets | default([]) %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.mplsVpnIpv4RouteTarget.exportRtList[{{ loop.index0 }}].rt   {{ rt_entry.route_target|default('not_defined') }}   {{ rt_entry.route_target_variable|default('not_defined') }}   msg=mplsVpnIpv4RouteTarget exportRtList value
    {% endfor %}
    # ===== MPLS VPN IPv6 Route Targets =====
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.mplsVpnIpv6RouteTarget.importRtList  {{ lan_vpn.get('ipv6_import_route_targets', []) | length }}    msg=mplsVpnIpv6RouteTarget importRtList length
    {% for rt_entry in lan_vpn.ipv6_import_route_targets | default([]) %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.mplsVpnIpv6RouteTarget.importRtList[{{ loop.index0 }}].rt   {{ rt_entry.route_target|default('not_defined') }}   {{ rt_entry.route_target_variable|default('not_defined') }}   msg=mplsVpnIpv6RouteTarget importRtList value
    {% endfor %}
    Should Be Equal Value Json List Length   ${service_lan_vpn_data}  data.mplsVpnIpv6RouteTarget.exportRtList  {{ lan_vpn.get('ipv6_export_route_targets', []) | length }}    msg=mplsVpnIpv6RouteTarget exportRtList length
    {% for rt_entry in lan_vpn.ipv6_export_route_targets | default([]) %}
        Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.mplsVpnIpv6RouteTarget.exportRtList[{{ loop.index0 }}].rt   {{ rt_entry.route_target|default('not_defined') }}   {{ rt_entry.route_target_variable|default('not_defined') }}   msg=mplsVpnIpv6RouteTarget exportRtList value
    {% endfor %}

    Should Be Equal Value Json Yaml    ${service_lan_vpn_data}    data.enableSdra    {{ lan_vpn.sdwan_remote_access|default('not_defined') }}   not_defined   msg= sdwan remote access

    Log    ======Routing Associations=======
    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/bgp'] | [0].payload.name    {{ lan_vpn.bgp | default('not_defined') }}    msg=bgp name

    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/eigrp'] | [0].payload.name    {{ lan_vpn.eigrp | default('not_defined') }}    msg=eigrp name

    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/ospf'] | [0].payload.name    {{ lan_vpn.ospf | default('not_defined') }}    msg=ospf name

    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/multicast'] | [0].payload.name    {{ lan_vpn.multicast | default('not_defined') }}    msg=multicast name

    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/ospfv3/ipv6'] | [0].payload.name    {{ lan_vpn.ospfv3_ipv6 | default('not_defined') }}    msg=ospfv3_ipv6 name

    Should Be Equal Value Json String    ${service_profile_features}    [?payload.name=='${service_lan_vpn_data['name']}'] | [0].subparcels[?parcelType=='routing/ospfv3/ipv4'] | [0].payload.name    {{ lan_vpn.ospfv3_ipv4 | default('not_defined') }}    msg=ospfv3_ipv4 name

{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
