*** Settings ***
Documentation   Verify Transport Feature Profile Configuration WAN VPN Ethernet Interfaces
Suite Setup     Login SDWAN Manager
Name            Transport Profiles WAN VPN Ethernet Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    wan_vpn    ethernet_interfaces
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.transport_profiles is defined %}
{% set profile_wan_vpn = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles %}
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
{% if profile.wan_vpn.ethernet_interfaces is defined and profile.wan_vpn.get('ethernet_interfaces' , [])|length > 0 %}

Verify Feature Profiles Transport Profiles {{ profile.name }} WAN VPN {{ profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name) }} Interfaces

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${transport_wan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn
    ${transport_profile_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}
    ${transport_wan_vpn}=    Json Search List    ${transport_wan_vpn_res.json()}    data[].payload
    Run Keyword If    ${transport_wan_vpn} == []    Fail    Feature '{{profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name)}}' expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    ${vpn_parcel_id}=    Json Search String   ${transport_wan_vpn_res.json()}    data[0].parcelId
    Set Suite Variable  ${vpn_parcel_id}

    ${trans_wan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn/${vpn_parcel_id}/interface/ethernet
    ${trans_wan_vpn_intf}=    Json Search List    ${trans_wan_vpn_intf_res.json()}    data[].payload
    Set Suite Variable    ${trans_wan_vpn_intf}

    ${tracker_groups_ethernet_interfaces}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='wan/vpn'] | [0].subparcels[?parcelType=='wan/vpn/interface/ethernet']
    Set Suite Variable    ${tracker_groups_ethernet_interfaces}

    ${ipv4_acls}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='ipv4-acl']
    Set Suite Variable    ${ipv4_acls}

    ${ipv6_acls}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='ipv6-acl']
    Set Suite Variable    ${ipv6_acls}

    Should Be Equal Value Json List Length   ${trans_wan_vpn_intf}   @   {{ profile.wan_vpn.get('ethernet_interfaces' , []) | length }}    msg=transport_wan_vpn ethernet_interfaces length

{% for intf_entry in profile.wan_vpn.ethernet_interfaces | default([]) %}

    Log   ======Ethernet Interfaces {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${trans_wan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]
    ${tracker_groups_ethernet_interface}=   Json Search    ${tracker_groups_ethernet_interfaces}    [?payload.name=='{{ intf_entry.name }}'] | [0]

    Log   ======Tracker Associations=======

    Should Be Equal Value Json String     ${tracker_groups_ethernet_interface}   subparcels[?parcelType=='trackergroup'] | [0].payload.name  {{ intf_entry.ipv4_tracker_group | default('not_defined') }}    msg=transport_wan_vpn ethernet_interfaces ipv4 tracker group name
    Should Be Equal Value Json String     ${tracker_groups_ethernet_interface}   subparcels[?parcelType=='ipv6-trackergroup'] | [0].payload.name  {{ intf_entry.ipv6_tracker_group | default('not_defined') }}    msg=transport_wan_vpn ethernet_interfaces ipv6 tracker group name
    Should Be Equal Value Json String     ${tracker_groups_ethernet_interface}   subparcels[?parcelType=='tracker'] | [0].payload.name        {{ intf_entry.ipv4_tracker | default('not_defined') }}    msg=transport_wan_vpn ethernet_interfaces tracker name
    Should Be Equal Value Json String     ${tracker_groups_ethernet_interface}   subparcels[?parcelType=='ipv6-tracker'] | [0].payload.name   {{ intf_entry.ipv6_tracker | default('not_defined') }}    msg=transport_wan_vpn ethernet_interfaces ipv6 tracker name

    Log   ======Basic Configuration========

    Should Be Equal Value Json String    ${r_interface_name}    name    {{ intf_entry.name | default('not_defined') }}    msg=transport_wan_vpn wan_vpn interface name
    Should Be Equal Value Json Special_String    ${r_interface_name}   description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=transport_wan_vpn wan_vpn description

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannelInterface    {{ intf_entry.port_channel_interface | default('not_defined') }}    {{ intf_entry.port_channel_interface_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_interface
    Run Keyword If    {{ intf_entry.port_channel_subinterface | default(False) }} == True    Should Be Equal Value Json String    ${r_interface_name}    data.portChannel.subInterface.wan   {{ intf_entry.port_channel_subinterface | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_subinterface
        
    ${port_channel_mode_lacp_check}=    Json Search List    ${r_interface_name}     data.portChannel.mainInterface.lacpModeMainInterface
    ${port_channel_mode_static_check}=    Json Search List    ${r_interface_name}     data.portChannel.mainInterface.staticModeMainInterface
    ${detected_port_channel_mode}=    Set Variable If    ${port_channel_mode_lacp_check} != []    lacp    ${port_channel_mode_static_check} != []    static    not_defined
    Should Be Equal As Strings    ${detected_port_channel_mode}    {{ intf_entry.port_channel_mode | default("not_defined") }}    msg=port_channel_mode

    {% if intf_entry.port_channel_mode is defined and intf_entry.port_channel_mode == 'lacp' %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpFastSwitchover   {{ intf_entry.port_channel_lacp_fast_switchover | default('not_defined') }}    {{ intf_entry.port_channel_lacp_fast_switchover_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_fast_switchover
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.loadBalance    {{ intf_entry.port_channel_load_balance | default('not_defined') }}    {{ intf_entry.port_channel_load_balance_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_load_balance
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpMaxBundle   {{ intf_entry.port_channel_lacp_max_bundle | default('not_defined') }}    {{ intf_entry.port_channel_lacp_max_bundle_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_max_bundle
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpMinBundle   {{ intf_entry.port_channel_lacp_min_bundle | default('not_defined') }}    {{ intf_entry.port_channel_lacp_min_bundle_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_min_bundle
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelQosAggregate   {{ intf_entry.port_channel_qos_aggregate | default('not_defined') }}    {{ intf_entry.port_channel_qos_aggregate_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_qos_aggregate
        ${pc_mem_refids}=    JSON Search    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[*].interface.refId.value
    {% for port_channel_member in intf_entry.port_channel_member_links %}
        ${pc_mem_yaml_ref_id}=    JSON Search    ${trans_wan_vpn_intf_res.json()}    data[?payload.name=='{{ port_channel_member.interface_feature_name | default('not_defined') }}'] | [0].parcelId
        List Should Contain Value    ${pc_mem_refids}    ${pc_mem_yaml_ref_id}    msg=transport_wan_vpn interface port_channel_member_links
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpMode   {{ port_channel_member.lacp_mode | default('not_defined') }}    {{ port_channel_member.lacp_mode_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_mode
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpRate   {{ port_channel_member.lacp_rate  | default('not_defined') }}    {{ port_channel_member.lacp_rate_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_rate
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpPortPriority   {{ port_channel_member.lacp_port_priority  | default('not_defined') }}    {{ port_channel_member.lacp_port_priority_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_lacp_port_priority
    {% endfor %}
    {% elif intf_entry.port_channel_mode is defined and intf_entry.port_channel_mode == 'static' %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.loadBalance   {{ intf_entry.port_channel_load_balance | default('not_defined') }}    {{ intf_entry.port_channel_load_balance_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_static_load_balance
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.portChannelQosAggregate   {{ intf_entry.port_channel_qos_aggregate | default('not_defined') }}    {{ intf_entry.port_channel_qos_aggregate_variable | default('not_defined') }}    msg=transport_wan_vpn interface port_channel_qos_aggregate
        ${pc_mem_refids}=    JSON Search    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.portChannelMemberLinks[*].interface.refId.value
    {% for port_channel_member in intf_entry.port_channel_member_links %}
        ${pc_mem_yaml_ref_id}=    JSON Search    ${trans_wan_vpn_intf_res.json()}    data[?payload.name=='{{ port_channel_member.interface_feature_name | default('not_defined') }}'] | [0].parcelId
        List Should Contain Value    ${pc_mem_refids}    ${pc_mem_yaml_ref_id}    msg=transport_wan_vpn interface port_channel_member_links
    {% endfor %}
    {% endif %}

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.interfaceName    {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}    msg=transport_wan_vpn wan_vpn interface interface_name
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.description    {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}    msg=transport_wan_vpn interface interface_description
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.shutdown    {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}    msg=transport_wan_vpn interface shutdown
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.serviceProvider    {{ intf_entry.service_provider | default('not_defined') }}    {{ intf_entry.service_provider_variable | default("not_defined") }}    msg=transport_wan_vpn interface service provider
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.bandwidthUpstream    {{ intf_entry.bandwidth_upstream | default('not_defined') }}    {{ intf_entry.bandwidth_upstream_variable | default("not_defined") }}    msg=transport_wan_vpn interface bandwidth_upstream
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.bandwidthDownstream    {{ intf_entry.bandwidth_downstream | default('not_defined') }}    {{ intf_entry.bandwidth_downstream_variable | default("not_defined") }}    msg=transport_wan_vpn interface bandwidth_downstream
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.autoDetectBandwidth    {{ intf_entry.auto_detect_bandwidth | default('not_defined') }}    {{ intf_entry.auto_detect_bandwidth_variable | default("not_defined") }}    msg=transport_wan_vpn interface auto_detect_bandwidth

    # 20.15 uses data.intfIpAddress.static/dynamic directly; 20.18+ wraps it under data.intfIpAddress.either.static/dynamic
    ${ipv4_either_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.either
    IF    ${ipv4_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.addressType    {{ intf_entry.ipv4_address_type | default('not_defined') }}    {{ intf_entry.ipv4_address_type_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address_type
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.ipAddress    {{ intf_entry.ipv4_address| default('not_defined') }}    {{ intf_entry.ipv4_address_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.subnetMask    {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.either.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses' , [] ) | length }}    msg=ipv4 secondary addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
{% endfor %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.either.dynamic.dynamicDhcpDistance    {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}    {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_dhcp_distance
    ELSE
        # below 20.18
        ${ipv4_static_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.static
        ${ipv4_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.dynamic
        ${detected_ipv4_type}=    Set Variable If    ${ipv4_static_check} != []    static    ${ipv4_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv4_type}    {{ intf_entry.ipv4_address_type | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address_type detected from JSON structure
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.ipAddress    {{ intf_entry.ipv4_address| default('not_defined') }}    {{ intf_entry.ipv4_address_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.subnetMask    {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses' , [] ) | length }}    msg=ipv4 secondary addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_address
{% endfor %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpAddress.dynamic.dynamicDhcpDistance    {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}    {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv4_dhcp_distance
    END

{% if intf_entry.ipv4_dhcp_helpers is defined and intf_entry.get('ipv4_dhcp_helpers' , []) | length > 0 %}

    ${dhcp_helpers_list}=    Create List    {{ intf_entry.ipv4_dhcp_helpers | join('   ') }}
    ${r_dhcp_helpers_list}=    Create List

    ${r_dhcp_helpers_list}=   Json Search List    ${r_interface_name}     data.dhcpHelper.value

    Lists Should Be Equal   ${dhcp_helpers_list}    ${r_dhcp_helpers_list}     msg=transport_wan_vpn_intf_dhcp_helpers_list     ignore_order=True

{% endif %}

    ${ipv6_either_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.either
    IF    ${ipv6_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.addressType    {{ intf_entry.ipv6_address_type | default('not_defined') }}    {{ intf_entry.ipv6_address_type_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv6_address_type
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.static.primaryIpV6Address.address    {{ intf_entry.ipv6_address| default('not_defined') }}    {{ intf_entry.ipv6_address_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv6_address
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.either.static.secondaryIpV6Address  {{ intf_entry.get('ipv6_static_secondary_addresses', []) | length }}    msg=ipv6 static secondary addresses length
{% for sec_addr in intf_entry.ipv6_static_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.static.secondaryIpV6Address[{{ loop.index0 }}].address    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface static secondary ipv6_address
{% endfor %}
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.either.dynamic.secondaryIpV6Address  {{ intf_entry.get('ipv6_dynamic_secondary_addresses', []) | length }}    msg=ipv6 dynamic secondary addresses length
{% for dhcp_sec_addr in intf_entry.ipv6_dynamic_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.either.dynamic.secondaryIpV6Address[{{ loop.index0 }}].address    {{ dhcp_sec_addr.address | default('not_defined') }}    {{ dhcp_sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface dynamic secondary ipv6_address
{% endfor %}
    ELSE
        # below 20.18
        ${ipv6_static_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.static
        ${ipv6_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.dynamic
        ${detected_ipv6_type}=    Set Variable If    ${ipv6_static_check} != []    static    ${ipv6_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv6_type}    {{ intf_entry.ipv6_address_type | default('not_defined') }}    msg=transport_wan_vpn interface ipv6_address_type detected from JSON structure
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.static.primaryIpV6Address.address    {{ intf_entry.ipv6_address| default('not_defined') }}    {{ intf_entry.ipv6_address_variable| default('not_defined') }}    msg=transport_wan_vpn interface ipv6_address
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.static.secondaryIpV6Address  {{ intf_entry.get('ipv6_static_secondary_addresses', []) | length }}    msg=ipv6 static secondary addresses length
{% for sec_addr in intf_entry.ipv6_static_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.static.secondaryIpV6Address[{{ loop.index0 }}].address    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface static secondary ipv6_address
{% endfor %}
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.dynamic.secondaryIpV6Address  {{ intf_entry.get('ipv6_dynamic_secondary_addresses', []) | length }}    msg=ipv6 dynamic secondary addresses length
{% for dhcp_sec_addr in intf_entry.ipv6_dynamic_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.intfIpV6Address.dynamic.secondaryIpV6Address[{{ loop.index0 }}].address    {{ dhcp_sec_addr.address | default('not_defined') }}    {{ dhcp_sec_addr.address_variable | default('not_defined') }}    msg=transport_wan_vpn interface dynamic secondary ipv6_address
{% endfor %}
    END

    Log    ======Tunnel Configurations=======

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.allowFragmentation    {{ intf_entry.tunnel_interface.allow_fragmentation | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_fragmentation_variable | default('not_defined') }}    msg=transport_wan_vpn interface allow fragmentation
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.perTunnelQos    {{ intf_entry.tunnel_interface.per_tunnel_qos | default('not_defined') }}   {{ intf_entry.tunnel_interface.per_tunnel_qos_variable | default('not_defined') }}    msg=transport_wan_vpn interface per tunnel qos
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.bind    {{ intf_entry.tunnel_interface.bind_loopback_tunnel | default('not_defined') }}    {{ intf_entry.tunnel_interface.bind_loopback_tunnel_variable | default('not_defined') }}    msg=transport_wan_vpn interface bind loopback
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.carrier    {{ intf_entry.tunnel_interface.carrier | default('not_defined') }}    {{ intf_entry.tunnel_interface.carrier_variable| default('not_defined') }}    msg=transport_wan_vpn interface carrier
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.color    {{ intf_entry.tunnel_interface.color | default('not_defined') }}    {{ intf_entry.tunnel_interface.color_variable| default('not_defined') }}    msg=transport_wan_vpn interface color
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.helloInterval    {{ intf_entry.tunnel_interface.hello_interval | default('not_defined') }}    {{ intf_entry.tunnel_interface.hello_interval_variable| default('not_defined') }}    msg=transport_wan_vpn interface hello interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.helloTolerance    {{ intf_entry.tunnel_interface.hello_tolerance | default('not_defined') }}    {{ intf_entry.tunnel_interface.hello_tolerance_variable| default('not_defined') }}    msg=transport_wan_vpn interface hello tolerance
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.lastResortCircuit    {{ intf_entry.tunnel_interface.last_resort_circuit | default('not_defined') }}    {{ intf_entry.tunnel_interface.last_resort_circuit_variable| default('not_defined') }}    msg=transport_wan_vpn interface last_resort_circuit
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.tlocExtensionGreTo    {{ intf_entry.tunnel_interface.gre_tunnel_destination_ip | default('not_defined') }}    {{ intf_entry.tunnel_interface.gre_tunnel_destination_ip_variable | default('not_defined') }}    msg=transport_wan_vpn interface gre_tunnel_destination_ip
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.restrict    {{ intf_entry.tunnel_interface.restrict | default('not_defined') }}    {{ intf_entry.tunnel_interface.restrict_variable| default('not_defined') }}    msg=transport_wan_vpn interface restrict
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.group    {{ intf_entry.tunnel_interface.group | default('not_defined') }}    {{ intf_entry.tunnel_interface.group_variable| default('not_defined') }}    msg=transport_wan_vpn interface group
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.border    {{ intf_entry.tunnel_interface.border | default('not_defined') }}    {{ intf_entry.tunnel_interface.border_variable| default('not_defined') }}    msg=transport_wan_vpn interface border
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.maxControlConnections    {{ intf_entry.tunnel_interface.max_control_connections | default('not_defined') }}    {{ intf_entry.tunnel_interface.max_control_connections_variable| default('not_defined') }}    msg=transport_wan_vpn interface max_control_connections
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.multiRegionFabric.enableCoreRegion    {{ intf_entry.tunnel_interface.mrf_enable_core_region | default('not_defined') }}    {{ intf_entry.tunnel_interface.mrf_enable_core_region_variable | default('not_defined') }}    msg=transport_wan_vpn interface mrf_enable_core_region
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.multiRegionFabric.coreRegion    {{ intf_entry.tunnel_interface.mrf_core_region_type | default('not_defined') }}    {{ intf_entry.tunnel_interface.mrf_core_region_type_variable | default('not_defined') }}    msg=transport_wan_vpn interface mrf_core_region_type
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.multiRegionFabric.enableSecondaryRegion    {{ intf_entry.tunnel_interface.mrf_enable_secondary_region | default('not_defined') }}    {{ intf_entry.tunnel_interface.mrf_enable_secondary_region_variable | default('not_defined') }}    msg=transport_wan_vpn interface mrf_enable_secondary_region
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.multiRegionFabric.secondaryRegion    {{ intf_entry.tunnel_interface.mrf_secondary_region_type | default('not_defined') }}    {{ intf_entry.tunnel_interface.mrf_secondary_region_type_variable | default('not_defined') }}    msg=transport_wan_vpn interface mrf_secondary_region_type
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.setSdwanTunnelMTUToMax    {{ intf_entry.tunnel_interface.set_sdwan_tunnel_mtu_to_max | default('not_defined') }}    {{ intf_entry.tunnel_interface.set_sdwan_tunnel_mtu_to_max_variable | default('not_defined') }}    msg=transport_wan_vpn interface set_sdwan_tunnel_mtu_to_max
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.natRefreshInterval    {{ intf_entry.tunnel_interface.nat_refresh_interval | default('not_defined') }}    {{ intf_entry.tunnel_interface.nat_refresh_interval_variable| default('not_defined') }}    msg=transport_wan_vpn interface nat_refresh_interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.vBondAsStunServer    {{ intf_entry.tunnel_interface.vbond_as_stun_server | default('not_defined') }}    {{ intf_entry.tunnel_interface.vbond_as_stun_server_variable| default('not_defined') }}    msg=transport_wan_vpn interface vbond_as_stun_server
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.excludeControllerGroupList    {{ intf_entry.tunnel_interface.exclude_controller_groups | default('not_defined') }}    {{ intf_entry.tunnel_interface.exclude_controller_groups | default('not_defined') }}    msg=transport_wan_vpn interface exclude_controller_groups
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.vManageConnectionPreference    {{ intf_entry.tunnel_interface.vmanage_connection_preference | default('not_defined') }}    {{ intf_entry.tunnel_interface.vmanage_connection_preference_variable| default('not_defined') }}    msg=transport_wan_vpn interface vmanage_connection_preference
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.portHop    {{ intf_entry.tunnel_interface.port_hop | default('not_defined') }}    {{ intf_entry.tunnel_interface.port_hop_variable| default('not_defined') }}    msg=transport_wan_vpn interface port_hop
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.lowBandwidthLink    {{ intf_entry.tunnel_interface.low_bandwidth_link | default('not_defined') }}    {{ intf_entry.tunnel_interface.low_bandwidth_link_variable| default('not_defined') }}    msg=transport_wan_vpn interface low_bandwidth_link
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.tunnelTcpMss    {{ intf_entry.tunnel_interface.tcp_mss | default('not_defined') }}    {{ intf_entry.tunnel_interface.tcp_mss_variable| default('not_defined') }}    msg=transport_wan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.clearDontFragment    {{ intf_entry.tunnel_interface.clear_dont_fragment | default('not_defined') }}    {{ intf_entry.tunnel_interface.clear_dont_fragment_variable| default('not_defined') }}    msg=transport_wan_vpn interface clear_dont_fragment
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.ctsSgtPropagation    {{ intf_entry.tunnel_interface.cts_sgt_propagation | default('not_defined') }}    {{ intf_entry.tunnel_interface.cts_sgt_propagation_variable| default('not_defined') }}    msg=transport_wan_vpn interface cts_sgt_propagation
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.networkBroadcast    {{ intf_entry.tunnel_interface.network_broadcast | default('not_defined') }}    {{ intf_entry.tunnel_interface.network_broadcast_variable| default('not_defined') }}    msg=transport_wan_vpn interface network_broadcast

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.all    {{ intf_entry.tunnel_interface.allow_service_all | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_all_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_all
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.bgp    {{ intf_entry.tunnel_interface.allow_service_bgp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_bgp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_bgp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.dhcp    {{ intf_entry.tunnel_interface.allow_service_dhcp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_dhcp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_dhcp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ntp    {{ intf_entry.tunnel_interface.allow_service_ntp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ntp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ntp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ssh    {{ intf_entry.tunnel_interface.allow_service_ssh | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ssh_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ssh
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.dns    {{ intf_entry.tunnel_interface.allow_service_dns | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_dns_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_dns
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.icmp    {{ intf_entry.tunnel_interface.allow_service_icmp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_icmp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_icmp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.https    {{ intf_entry.tunnel_interface.allow_service_https | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_https_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_https
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ospf    {{ intf_entry.tunnel_interface.allow_service_ospf | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ospf_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ospf
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.stun    {{ intf_entry.tunnel_interface.allow_service_stun | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_stun_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_stun
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.snmp    {{ intf_entry.tunnel_interface.allow_service_snmp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_snmp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_snmp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.netconf    {{ intf_entry.tunnel_interface.allow_service_netconf | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_netconf_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_netconf
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.bfd    {{ intf_entry.tunnel_interface.allow_service_bfd | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_bfd_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_bfd

    ${gre_object}=    Json Search    ${r_interface_name}   data.encapsulation[?encap.value=='gre'] | [0]
    Should Be Equal Value Json Yaml   ${gre_object}    preference   {{ intf_entry.tunnel_interface.gre_preference | default('not_defined') }}   {{ intf_entry.tunnel_interface.gre_preference_variable | default('not_defined') }}  msg=transport_wan_vpn interface gre encapsulation
    Should Be Equal Value Json Yaml   ${gre_object}    weight   {{ intf_entry.tunnel_interface.gre_weight | default('not_defined') }}   {{ intf_entry.tunnel_interface.gre_weight_variable | default('not_defined') }}  msg=transport_wan_vpn interface gre weight

    ${ipsec_object}=    Json Search    ${r_interface_name}   data.encapsulation[?encap.value=='ipsec'] | [0]
    Should Be Equal Value Json Yaml   ${ipsec_object}    preference   {{ intf_entry.tunnel_interface.ipsec_preference | default('not_defined') }}   {{ intf_entry.tunnel_interface.ipsec_preference_variable | default('not_defined') }}  msg=transport_wan_vpn interface ipsec encapsulation
    Should Be Equal Value Json Yaml   ${ipsec_object}    weight   {{ intf_entry.tunnel_interface.ipsec_weight | default('not_defined') }}   {{ intf_entry.tunnel_interface.ipsec_weight_variable | default('not_defined') }}  msg=transport_wan_vpn interface ipsec weight


    Should Be Equal Value Json Yaml     ${r_interface_name}    data.nat   {{ intf_entry.ipv4_nat | default('not_defined') }}     {{ intf_entry.ipv4_nat_variable | default('not_defined') }}     msg=transport_wan_vpn interface nat
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv4.natType   {{ intf_entry.ipv4_nat_type | default('not_defined') }}     {{ intf_entry.ipv4_nat_type_variable| default('not_defined') }}     msg=transport_wan_vpn interface nat_type
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv4.udpTimeout   {{ intf_entry.ipv4_nat_udp_timeout | default('not_defined') }}     {{ intf_entry.ipv4_nat_udp_timeout_variable| default('not_defined') }}     msg=transport_wan_vpn interface nat_udp_timeout
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv4.tcpTimeout   {{ intf_entry.ipv4_nat_tcp_timeout | default('not_defined') }}     {{ intf_entry.ipv4_nat_tcp_timeout_variable| default('not_defined') }}     msg=transport_wan_vpn interface nat_tcp_timeout

    Should Be Equal Value Json List Length    ${r_interface_name}   data.natAttributesIpv4.newStaticNat    {{ intf_entry.get('ipv4_nat_static_entries', []) | length }}    msg=transport_wan_vpn interface ipv4_nat_static_entries length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

{% for nat_entry in intf_entry.ipv4_nat_static_entries | default([]) %}

    Should Be Equal Value Json Yaml   ${r_interface_name}   data.natAttributesIpv4.newStaticNat[{{ loop.index0 }}].enableDualRouterHAMapping    {{ nat_entry.enable_dual_router_ha_mapping | default('not_defined') }}     {{ nat_entry.enable_dual_router_ha_mapping_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv4_nat_static_entries enable_dual_router_ha_mapping
    Should Be Equal Value Json Yaml   ${r_interface_name}   data.natAttributesIpv4.newStaticNat[{{ loop.index0 }}].sourceIp     {{ nat_entry.source_ip | default('not_defined') }}     {{ nat_entry.source_ip_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv4_nat_static_entries source_ip
    Should Be Equal Value Json Yaml   ${r_interface_name}   data.natAttributesIpv4.newStaticNat[{{ loop.index0 }}].translateIp     {{ nat_entry.translate_ip | default('not_defined') }}     {{ nat_entry.translate_ip_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv4_nat_static_entries translate_ip
    Should Be Equal Value Json String   ${r_interface_name}   data.natAttributesIpv4.newStaticNat[{{ loop.index0 }}].staticNatDirection.value   {{ nat_entry.direction | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_static_entries direction
    Should Be Equal Value Json Yaml     ${r_interface_name}   data.natAttributesIpv4.newStaticNat[{{ loop.index0 }}].sourceVpn  {{ nat_entry.source_vpn_id | default('not_defined') }}     {{ nat_entry.source_vpn_id_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv4_nat_static_entries source_vpn_id

{% endfor %}

    Should Be Equal Value Json Yaml   ${r_interface_name}    data.natIpv6  {{ intf_entry.ipv6_nat | default('not_defined') }}    {{ intf_entry.ipv6_nat_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv6_nat
    Run Keyword If    '{{ intf_entry.get('ipv6_nat_type')  }}' == 'nat64' or '{{ intf_entry.get('ipv6_nat_type') }}' == 'nat66'    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv6.{{ intf_entry.get('ipv6_nat_type') }}   {{ intf_entry.ipv6_nat | default('False') }}   {{ intf_entry.ipv6_nat_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv6_nat_type
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

    Should Be Equal Value Json List Length      ${r_interface_name}   data.natAttributesIpv6.staticNat66  {{ intf_entry.get('ipv6_nat66_static_entries', []) | length }}    msg=transport_wan_vpn interface ipv6_nat66_static_entries length

{% for nat_entry in intf_entry.ipv6_nat66_static_entries | default([]) %}

    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv6.staticNat66[{{ loop.index0 }}].egressInterface  {{ nat_entry.egress_interface | default('not_defined') }}     {{ nat_entry.egress_interface_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv6_nat66_static_entries egress_interface
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv6.staticNat66[{{ loop.index0 }}].sourcePrefix  {{ nat_entry.source_prefix | default('not_defined') }}     {{ nat_entry.source_prefix_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv6_nat66_static_entries source_prefix
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv6.staticNat66[{{ loop.index0 }}].translatedSourcePrefix  {{ nat_entry.translate_prefix | default('not_defined') }}     {{ nat_entry.translate_prefix_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv6_nat66_static_entries translated_source_prefix
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv6.staticNat66[{{ loop.index0 }}].sourceVpnId  {{ nat_entry.source_vpn_id | default('not_defined') }}     {{ nat_entry.source_vpn_id_variable | default('not_defined') }}     msg=transport_wan_vpn interface ipv6_nat66_static_entries source_vpn_id

{% endfor %}

    Log    ======Multiple NAT Fields======

{% for ipv4_nat_loopback in intf_entry.ipv4_nat_loopbacks | default([]) %}
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multipleLoopback[{{ loop.index0 }}].loopbackInterface    {{ ipv4_nat_loopback.loopback_interface | default('not_defined') }}    {{ ipv4_nat_loopback.loopback_interface_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_loopbacks loopback_interface
{% endfor %}

    Should Be Equal Value Json List Length    ${r_interface_name}    data.natAttributesIpv4.multiplePool    {{ intf_entry.get('ipv4_nat_pools', []) | length }}    msg=transport_wan_vpn interface ipv4_nat_pools length

{% for ipv4_nat_pool in intf_entry.ipv4_nat_pools | default([]) %}
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].enableDualRouterHAMapping    {{ ipv4_nat_pool.enable_dual_router_ha_mapping | default('not_defined') }}    {{ ipv4_nat_pool.enable_dual_router_ha_mapping_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools enable_dual_router_ha_mapping
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].name    {{ ipv4_nat_pool.id | default('not_defined') }}    {{ ipv4_nat_pool.id_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools id
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].overload    {{ ipv4_nat_pool.overload | default('not_defined') }}    {{ ipv4_nat_pool.overload_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools overload
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].prefixLength    {{ ipv4_nat_pool.prefix_length | default('not_defined') }}    {{ ipv4_nat_pool.prefix_length_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools prefix_length
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].rangeEnd    {{ ipv4_nat_pool.range_end | default('not_defined') }}    {{ ipv4_nat_pool.range_end_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools range_end
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.multiplePool[{{ loop.index0 }}].rangeStart    {{ ipv4_nat_pool.range_start | default('not_defined') }}    {{ ipv4_nat_pool.range_start_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_pools range_start
{% endfor %}

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.matchInterface    {{ intf_entry.ipv4_nat_match_interface | default('not_defined') }}    {{ intf_entry.ipv4_nat_match_interface_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_match_interface


    Log    ======IPv4 NAT Port Forwarding Rules======

    Should Be Equal Value Json List Length    ${r_interface_name}    data.natAttributesIpv4.staticPortForward    {{ intf_entry.get('ipv4_nat_port_forwarding_rules', []) | length }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules length

{% for ipv4_nat_port_forwarding_rule in intf_entry.ipv4_nat_port_forwarding_rules | default([]) %}
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].staticNatDirection    {{ ipv4_nat_port_forwarding_rule.direction | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.direction_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules direction
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].enableDualRouterHAMapping    {{ ipv4_nat_port_forwarding_rule.enable_dual_router_ha_mapping | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.enable_dual_router_ha_mapping_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules enable_dual_router_ha_mapping
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].protocol    {{ ipv4_nat_port_forwarding_rule.protocol | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.protocol_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules protocol
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].sourceIp    {{ ipv4_nat_port_forwarding_rule.source_ip | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.source_ip_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules source_ip
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].sourcePort    {{ ipv4_nat_port_forwarding_rule.source_port | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.source_port_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules source_port
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].sourceVpn    {{ ipv4_nat_port_forwarding_rule.source_vpn | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.source_vpn_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules source_vpn
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].translateIp    {{ ipv4_nat_port_forwarding_rule.translated_ip | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.translated_ip_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules translated_ip
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.natAttributesIpv4.staticPortForward[{{ loop.index0 }}].translatePort    {{ ipv4_nat_port_forwarding_rule.translated_port | default('not_defined') }}    {{ ipv4_nat_port_forwarding_rule.translated_port_variable | default('not_defined') }}    msg=transport_wan_vpn interface ipv4_nat_port_forwarding_rules translated_port
{% endfor %}

    Should Be Equal Value Json List Length      ${r_interface_name}   data.arp  {{ intf_entry.get('arp_entries', []) | length }}    msg=transport_wan_vpn interface arp_entries length

    Log    ======ARP Entries======

{% for arp_entry in intf_entry.arp_entries | default([]) %}

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.arp[{{ loop.index0 }}].ipAddress   {{ arp_entry.ip_address| default('not_defined') }}     {{ arp_entry.ip_address_variable| default('not_defined') }}     msg=transport_wan_vpn intf arp_entry.ip_address
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.arp[{{ loop.index0 }}].macAddress   {{ arp_entry.mac_address| default('not_defined') }}     {{ arp_entry.mac_address_variable| default('not_defined') }}     msg=transport_wan_vpn intf arp_entry.mac_address

{% endfor %}

    Log    ======ACL/QoS======

    Run Keyword If    {{ intf_entry.port_channel_member_interface | default(False) }} == False    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.adaptiveQoS   {{ intf_entry.adaptive_qos | default('False') }}     {{ intf_entry.adaptive_qos_variable| default('False') }}     msg=transport_wan_vpn adaptive_qos
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.adaptPeriod   {{ intf_entry.adaptive_qos_period| default('not_defined') }}     {{ intf_entry.adaptive_qos_period_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_period
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.minShapingRateUpstream  {{ intf_entry.adaptive_qos_shaping_rate_upstream.minimum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.minimum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream minimum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.maxShapingRateUpstream   {{ intf_entry.adaptive_qos_shaping_rate_upstream.maximum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.maximum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream maximum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.defaultShapingRateUpstream   {{ intf_entry.adaptive_qos_shaping_rate_upstream.default| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.default| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream default
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.minShapingRateDownstream  {{ intf_entry.adaptive_qos_shaping_rate_downstream.minimum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.minimum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream minimum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.maxShapingRateDownstream   {{ intf_entry.adaptive_qos_shaping_rate_downstream.maximum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.maximum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream maximum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.defaultShapingRateDownstream   {{ intf_entry.adaptive_qos_shaping_rate_downstream.default| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.default| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream.default

    ${configured_ipv4_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclEgress.refId.value
    ${configured_ipv4_egress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv4_egress_acl}    payload.name    {{ intf_entry.ipv4_egress_acl | default('not_defined') }}    msg=wan_vpn.ethernet_interfaces_ipv4_egress_acl
    ${configured_ipv4_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclIngress.refId.value
    ${configured_ipv4_ingress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv4_ingress_acl}    payload.name    {{ intf_entry.ipv4_ingress_acl | default('not_defined') }}    msg=wan_vpn.ethernet_interfaces_ipv4_ingress_acl

    ${configured_ipv6_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclEgress.refId.value
    ${configured_ipv6_egress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv6_egress_acl}    payload.name    {{ intf_entry.ipv6_egress_acl | default('not_defined') }}    msg=wan_vpn.ethernet_interfaces_ipv6_egress_acl
    ${configured_ipv6_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclIngress.refId.value
    ${configured_ipv6_ingress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv6_ingress_acl}    payload.name    {{ intf_entry.ipv6_ingress_acl | default('not_defined') }}    msg=wan_vpn.ethernet_interfaces_ipv6_ingress_acl

    Log    =====Advanced Features=====

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.duplex   {{ intf_entry.duplex| default('not_defined') }}     {{ intf_entry.duplex_variable| default('not_defined') }}     msg=transport_wan_vpn interface duplex
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.macAddress   {{ intf_entry.mac_address| default('not_defined') }}     {{ intf_entry.mac_address_variable| default('not_defined') }}     msg=transport_wan_vpn interface mac_address
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipMtu   {{ intf_entry.ip_mtu| default('not_defined') }}     {{ intf_entry.ip_mtu_variable| default('not_defined') }}     msg=transport_wan_vpn interface ip_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.intrfMtu   {{ intf_entry.interface_mtu| default('not_defined') }}     {{ intf_entry.interface_mtu_variable| default('not_defined') }}     msg=transport_wan_vpn interface interface_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tcpMss   {{ intf_entry.tcp_mss| default('not_defined') }}     {{ intf_entry.tcp_mss_variable| default('not_defined') }}     msg=transport_wan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.speed   {{ intf_entry.speed| default('not_defined') }}     {{ intf_entry.speed_variable| default('not_defined') }}     msg=transport_wan_vpn interface speed
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.arpTimeout   {{ intf_entry.arp_timeout| default('not_defined') }}     {{ intf_entry.arp_timeout_variable| default('not_defined') }}     msg=transport_wan_vpn interface arp_timeout
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.autonegotiate   {{ intf_entry.autonegotiate| default('not_defined') }}     {{ intf_entry.autonegotiate_variable| default('not_defined') }}     msg=transport_wan_vpn interface autonegotiate
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.mediaType   {{ intf_entry.media_type| default('not_defined') }}     {{ intf_entry.media_type_variable| default('not_defined') }}     msg=transport_wan_vpn interface media_type
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.loadInterval   {{ intf_entry.load_interval| default('not_defined') }}     {{ intf_entry.load_interval_variable| default('not_defined') }}     msg=transport_wan_vpn interface load_interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.icmpRedirectDisable   {{ intf_entry.icmp_redirect_disable| default('not_defined') }}     {{ intf_entry.icmp_redirect_disable_variable| default('not_defined') }}     msg=transport_wan_vpn interface icmp_redirect_disable
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipDirectedBroadcast   {{ intf_entry.ip_directed_broadcast| default('not_defined') }}     {{ intf_entry.ip_directed_broadcast_variable| default('not_defined') }}     msg=transport_wan_vpn interface ip_directed_broadcast
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tlocExtension   {{ intf_entry.tloc_extension| default('not_defined') }}     {{ intf_entry.tloc_extension_variable| default('not_defined') }}     msg=transport_wan_vpn interface tloc_extension
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tlocExtensionGreFrom.sourceIp   {{ intf_entry.gre_tloc_extension_source_ip| default('not_defined') }}     {{ intf_entry.gre_tloc_extension_source_ip_variable| default('not_defined') }}   msg=transport_wan_vpn interface gre_tloc_extension_source_ip
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tlocExtensionGreFrom.xconnect   {{ intf_entry.gre_tloc_extension_xconnect| default('not_defined') }}     {{ intf_entry.gre_tloc_extension_xconnect_variable| default('not_defined') }}     msg=transport_wan_vpn interface gre_tloc_extension_xconnect

{% endfor %}

{% endif %}
    
{% endfor %}

{% endif %}

{% endif %}
