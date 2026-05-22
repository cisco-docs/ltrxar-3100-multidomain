*** Settings ***
Documentation   Verify Service Feature Profile Configuration LAN VPNs Ethernet Interfaces
Suite Setup     Login SDWAN Manager
Name            Service Profiles LAN VPNs Ethernet Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    lan_vpns    ethernet_interfaces
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.service_profiles is defined %}

{% set profile_lan_vpns = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', {}) %}
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
    Set Suite Variable   ${profile_id}
    ${service_profile_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}
    Set Suite Variable   ${service_profile_res}
    ${service_profile_features}=    Json Search List    ${service_profile_res.json()}    associatedProfileParcels
    Set Suite Variable    ${service_profile_features}
    ${tracker_objs_object}=    Json Search List    ${service_profile_features}    [?parcelType=='objecttracker']
    ${tracker_objs_group}=    Json Search List    ${service_profile_features}   [?parcelType=='objecttrackergroup']
    ${tracker_objs}=    Evaluate    $tracker_objs_object + $tracker_objs_group
    Set Suite Variable    ${tracker_objs}
    ${ipv4_acls}=    Json Search List    ${service_profile_features}  [?parcelType=='ipv4-acl']
    Set Suite Variable    ${ipv4_acls}
    ${ipv6_acls}=    Json Search List    ${service_profile_features}  [?parcelType=='ipv6-acl']
    Set Suite Variable    ${ipv6_acls}
    ${dhcp_server}=    Json Search List    ${service_profile_features}  [?parcelType=='dhcp-server']
    Set Suite Variable    ${dhcp_server}
    ${service_lan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn
    ${service_lan_vpn}=    Json Search List    ${service_lan_vpn_res.json()}    data
    Run Keyword If    ${service_lan_vpn} == []    Fail    Feature lan vpn expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_lan_vpn}

{% for lan_vpn in profile.lan_vpns | default([]) %}

Verify Feature Profiles Service Profiles {{ profile.name }} {{lan_vpn.name}} Ethernet Interfaces
    ${lan_vpn_profile}=    Json Search    ${service_lan_vpn}    [?payload.name=='{{ lan_vpn.name }}'] | [0]
    Run Keyword If    $lan_vpn_profile is None    Fail    Feature lan vpn '{{lan_vpn.name}}' expected to be configured within the service profile '{{ profile.name }}' on the Manager
    ${lan_vpn_profile_id}=    Json Search String    ${lan_vpn_profile}    parcelId
    ${trackers_lan_ethernet_interface}=   Json Search List    ${service_profile_res.json()}    associatedProfileParcels[].subparcels[] | [?parcelType=='lan/vpn/interface/ethernet']
    Set Suite Variable    ${trackers_lan_ethernet_interface}
    ${service_lan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn/${lan_vpn_profile_id}/interface/ethernet
    ${service_lan_vpn_intf}=    Json Search List    ${service_lan_vpn_intf_res.json()}    data[].payload

    Should Be Equal Value Json List Length   ${service_lan_vpn_intf}  @  {{ lan_vpn.get('ethernet_interfaces' , []) | length }}    msg=service_lan_vpn ethernet_interfaces length

{% for intf_entry in lan_vpn.ethernet_interfaces | default([]) %}

    Log   ======Ethernet Interface {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${service_lan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]

    Log   ============Tracker Associations=============

    ${lan_ethernet_interface_target}=    Json Search    ${trackers_lan_ethernet_interface}    [?payload.name=='{{ intf_entry.name }}'] | [0]

    Should Be Equal Value Json String
    ...    ${lan_ethernet_interface_target}    subparcels[?parcelType=='trackergroup'] | [0].payload.name
    ...    {{ intf_entry.ipv4_tracker_group | default('not_defined') }}
    ...    msg=service_lan_vpn ethernet_interfaces ipv4 tracker group name
    Should Be Equal Value Json String
    ...    ${lan_ethernet_interface_target}    subparcels[?parcelType=='tracker'] | [0].payload.name
    ...    {{ intf_entry.ipv4_tracker | default('not_defined') }}
    ...    msg=service_lan_vpn ethernet_interfaces tracker name

    Log   ============ DHCP Associations=============
    Should Be Equal Value Json String
    ...    ${lan_ethernet_interface_target}    subparcels[?parcelType=='dhcp-server'] | [0].payload.name
    ...    {{ intf_entry.dhcp_server | default('not_defined') }}
    ...    msg=service_lan_vpn ethernet_interfaces dhcp server name


    Log   ============Basic Configuration==============

    Should Be Equal Value Json String
    ...    ${r_interface_name}    name
    ...    {{ intf_entry.name | default('not_defined') }}
    ...    msg=service_lan_vpn lan_vpn interface name
    Should Be Equal Value Json Special_String    ${r_interface_name}   description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=service_lan_vpn lan_vpn description
    
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.interfaceName
    ...    {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}
    ...    msg=service_lan_vpn lan_vpn interface interface_name
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.description
    ...    {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface interface_description
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.shutdown
    ...    {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface shutdown

    Log    ===========Port Channel Configuration===========

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.portChannelInterface
    ...    {{ intf_entry.port_channel_interface | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface port_channel_interface
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.portChannelMemberInterface
    ...    {{ intf_entry.port_channel_member_interface | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface port_channel_member_interface

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.portChannel.subInterface.primaryInterfaceName
    ...    {{ intf_entry.port_channel_subinterface_primary_interface_name | default('not_defined') }}    {{ intf_entry.port_channel_subinterface_primary_interface_name_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface port_channel_subinterface_primary_interface_name
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.portChannel.subInterface.secondaryInterfaceName
    ...    {{ intf_entry.port_channel_subinterface_secondary_interface_name | default('not_defined') }}    {{ intf_entry.port_channel_subinterface_secondary_interface_name_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface port_channel_subinterface_secondary_interface_name

    ${port_channel_mode_lacp_check}=    Json Search List    ${r_interface_name}     data.portChannel.mainInterface.lacpModeMainInterface
    ${port_channel_mode_static_check}=    Json Search List    ${r_interface_name}     data.portChannel.mainInterface.staticModeMainInterface
    ${detected_port_channel_mode}=    Set Variable If    ${port_channel_mode_lacp_check} != []    lacp    ${port_channel_mode_static_check} != []    static    not_defined
    Should Be Equal As Strings    ${detected_port_channel_mode}    {{ intf_entry.port_channel_mode | default("not_defined") }}    msg=service_lan_vpn interface port_channel_mode

    {% if intf_entry.port_channel_mode is defined and intf_entry.port_channel_mode == 'lacp' %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpFastSwitchover    {{ intf_entry.port_channel_lacp_fast_switchover | default('not_defined') }}    {{ intf_entry.port_channel_lacp_fast_switchover_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_lacp_fast_switchover
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.loadBalance    {{ intf_entry.port_channel_load_balance | default('not_defined') }}    {{ intf_entry.port_channel_load_balance_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_load_balance
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpMaxBundle    {{ intf_entry.port_channel_lacp_max_bundle | default('not_defined') }}    {{ intf_entry.port_channel_lacp_max_bundle_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_lacp_max_bundle
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.lacpMinBundle    {{ intf_entry.port_channel_lacp_min_bundle | default('not_defined') }}    {{ intf_entry.port_channel_lacp_min_bundle_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_lacp_min_bundle
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelQosAggregate    {{ intf_entry.port_channel_qos_aggregate | default('not_defined') }}    {{ intf_entry.port_channel_qos_aggregate_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_qos_aggregate
        ${pc_mem_refids}=    JSON Search    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[*].interface.refId.value
    {% for port_channel_member in intf_entry.port_channel_member_links | default([]) %}
        ${pc_mem_yaml_ref_id}=    JSON Search    ${service_lan_vpn_intf_res.json()}    data[?payload.name=='{{ port_channel_member.interface_feature_name | default('not_defined') }}'] | [0].parcelId
        List Should Contain Value    ${pc_mem_refids}    ${pc_mem_yaml_ref_id}    msg=service_lan_vpn interface port_channel_member_links
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpMode    {{ port_channel_member.lacp_mode | default('not_defined') }}    {{ port_channel_member.lacp_mode_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_member_lacp_mode
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpRate    {{ port_channel_member.lacp_rate | default('not_defined') }}    {{ port_channel_member.lacp_rate_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_member_lacp_rate
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.lacpModeMainInterface.portChannelMemberLinks[?interface.refId.value=='${pc_mem_yaml_ref_id}'].lacpPortPriority    {{ port_channel_member.lacp_port_priority | default('not_defined') }}    {{ port_channel_member.lacp_port_priority_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_member_lacp_port_priority
    {% endfor %}
    {% elif intf_entry.port_channel_mode is defined and intf_entry.port_channel_mode == 'static' %}
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.loadBalance    {{ intf_entry.port_channel_load_balance | default('not_defined') }}    {{ intf_entry.port_channel_load_balance_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_static_load_balance
        Should Be Equal Value Json Yaml    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.portChannelQosAggregate    {{ intf_entry.port_channel_qos_aggregate | default('not_defined') }}    {{ intf_entry.port_channel_qos_aggregate_variable | default('not_defined') }}    msg=service_lan_vpn interface port_channel_qos_aggregate
        ${pc_mem_refids}=    JSON Search    ${r_interface_name}    data.portChannel.mainInterface.staticModeMainInterface.portChannelMemberLinks[*].interface.refId.value
    {% for port_channel_member in intf_entry.port_channel_member_links | default([]) %}
        ${pc_mem_yaml_ref_id}=    JSON Search    ${service_lan_vpn_intf_res.json()}    data[?payload.name=='{{ port_channel_member.interface_feature_name | default('not_defined') }}'] | [0].parcelId
        List Should Contain Value    ${pc_mem_refids}    ${pc_mem_yaml_ref_id}    msg=service_lan_vpn interface port_channel_member_links
    {% endfor %}
    {% endif %}

    # 20.15 uses data.intfIpAddress.static/dynamic directly; 20.18+ wraps it under data.intfIpAddress.either.static/dynamic
    ${ipv4_either_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.either
    IF    ${ipv4_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.addressType
        ...    {{ intf_entry.ipv4_address_type | default('not_defined') }}    {{ intf_entry.ipv4_address_type_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address_type
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.ipAddress
        ...    {{ intf_entry.ipv4_address| default('not_defined') }}    {{ intf_entry.ipv4_address_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressPrimary.subnetMask
        ...    {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.either.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses' , [] ) | length }}    msg=ipv4 secondary addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress
        ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask
        ...    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
{% endfor %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.either.dynamic.dynamicDhcpDistance
        ...    {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}    {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_dhcp_distance
    ELSE
        # below 20.18
        ${ipv4_static_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.static
        ${ipv4_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpAddress.dynamic
        ${detected_ipv4_type}=    Set Variable If    ${ipv4_static_check} != []    static    ${ipv4_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv4_type}    {{ intf_entry.ipv4_address_type | default('not_defined') }}    msg=service_lan_vpn interface ipv4_address_type detected from JSON structure
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.ipAddress
        ...    {{ intf_entry.ipv4_address| default('not_defined') }}    {{ intf_entry.ipv4_address_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressPrimary.subnetMask
        ...    {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_subnet_mask
        Should Be Equal Value Json List Length   ${r_interface_name}  data.intfIpAddress.static.staticIpV4AddressSecondary  {{ intf_entry.get('ipv4_secondary_addresses' , [] ) | length }}    msg=ipv4 secondary addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].ipAddress
        ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.static.staticIpV4AddressSecondary[{{ loop.index0 }}].subnetMask
        ...    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_address
{% endfor %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpAddress.dynamic.dynamicDhcpDistance
        ...    {{ intf_entry.ipv4_dhcp_distance| default('not_defined') }}    {{ intf_entry.ipv4_dhcp_distance_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv4_dhcp_distance
    END

    ${dhcp_helpers_list}=    Set Variable If    "{{ intf_entry.get('ipv4_dhcp_helpers', []) | length }}" == "0"    not_defined    {{ intf_entry.get('ipv4_dhcp_helpers', []) }}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.dhcpHelper
    ...    ${dhcp_helpers_list}    {{ intf_entry.ipv4_dhcp_helpers_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_dhcp_helpers

    ${ipv6_either_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.either
    IF    ${ipv6_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.addressType
        ...    {{ intf_entry.ipv6_address_type | default('not_defined') }}    {{ intf_entry.ipv6_address_type_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_address_type
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.static.primaryIpV6Address.address
        ...    {{ intf_entry.ipv6_address| default('not_defined') }}    {{ intf_entry.ipv6_address_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_address
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.either.static.secondaryIpV6Address  {{ intf_entry.get('ipv6_static_secondary_addresses', []) | length }}    msg=ipv6 static secondary addresses length
{% for sec_addr in intf_entry.ipv6_static_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.static.secondaryIpV6Address[{{ loop.index0 }}].address
        ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface static secondary ipv6_address
{% endfor %}
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.either.dynamic.secondaryIpV6Address  {{ intf_entry.get('ipv6_dynamic_secondary_addresses', []) | length }}    msg=ipv6 dynamic secondary addresses length
{% for dhcp_sec_addr in intf_entry.ipv6_dynamic_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.dynamic.secondaryIpV6Address[{{ loop.index0 }}].address
        ...    {{ dhcp_sec_addr.address | default('not_defined') }}    {{ dhcp_sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface dynamic secondary ipv6_address
{% endfor %}
    ELSE
        # below 20.18
        ${ipv6_static_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.static
        ${ipv6_dynamic_check}=    Json Search List    ${r_interface_name}     data.intfIpV6Address.dynamic
        ${detected_ipv6_type}=    Set Variable If    ${ipv6_static_check} != []    static    ${ipv6_dynamic_check} != []    dynamic    not_defined
        Should Be Equal As Strings    ${detected_ipv6_type}    {{ intf_entry.ipv6_address_type | default('not_defined') }}    msg=service_lan_vpn interface ipv6_address_type detected from JSON structure
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.static.primaryIpV6Address.address
        ...    {{ intf_entry.ipv6_address| default('not_defined') }}    {{ intf_entry.ipv6_address_variable| default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_address
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.static.secondaryIpV6Address  {{ intf_entry.get('ipv6_static_secondary_addresses', []) | length }}    msg=ipv6 static secondary addresses length
{% for sec_addr in intf_entry.ipv6_static_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.static.secondaryIpV6Address[{{ loop.index0 }}].address
        ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface static secondary ipv6_address
{% endfor %}
        Should Be Equal Value Json List Length      ${r_interface_name}  data.intfIpV6Address.dynamic.secondaryIpV6Address  {{ intf_entry.get('ipv6_dynamic_secondary_addresses', []) | length }}    msg=ipv6 dynamic secondary addresses length
{% for dhcp_sec_addr in intf_entry.ipv6_dynamic_secondary_addresses | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.dynamic.secondaryIpV6Address[{{ loop.index0 }}].address
        ...    {{ dhcp_sec_addr.address | default('not_defined') }}    {{ dhcp_sec_addr.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface dynamic secondary ipv6_address
{% endfor %}
    END
    
    Log    ============ARP Entries============

    Should Be Equal Value Json List Length      ${r_interface_name}   data.arp  {{ intf_entry.get('arp_entries', []) | length }}    msg=service_lan_vpn interface arp_entries length

{% for arp_entry in intf_entry.arp_entries | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.arp[{{ loop.index0 }}].ipAddress
    ...    {{ arp_entry.ip_address| default('not_defined') }}    {{ arp_entry.ip_address_variable| default('not_defined') }}
    ...    msg=service_lan_vpn intf arp_entry.ip_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.arp[{{ loop.index0 }}].macAddress
    ...    {{ arp_entry.mac_address| default('not_defined') }}    {{ arp_entry.mac_address_variable| default('not_defined') }}
    ...    msg=service_lan_vpn intf arp_entry.mac_address
{% endfor %}

    Log    ============IPv4 VRRP Groups==============

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrp  {{ intf_entry.get('ipv4_vrrp_groups', []) | length }}    msg=service_lan_vpn interface ipv4_vrrp_groups length

{% for vrrp_group in intf_entry.ipv4_vrrp_groups | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].group_id
    ...    {{ vrrp_group.id | default('not_defined') }}    {{ vrrp_group.id_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group id
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].ipAddress
    ...    {{ vrrp_group.address | default('not_defined') }}    {{ vrrp_group.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].minPreemptDelay
    ...    {{ vrrp_group.min_preempt_delay | default('not_defined') }}    {{ vrrp_group.min_preempt_delay_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group min_preempt_delay
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].priority
    ...    {{ vrrp_group.priority | default('not_defined') }}    {{ vrrp_group.priority_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group priority
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].timer
    ...    {{ vrrp_group.timer | default('not_defined') }}    {{ vrrp_group.timer_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group timer
    Should Be Equal Value Json String
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].tlocPrefChange.value
    ...    {{ vrrp_group.tloc_preference_change | default('False') }}
    ...    msg=service_lan_vpn interface vrrp_group tloc_preference_change
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].tlocPrefChangeValue
    ...    {{ vrrp_group.tloc_preference_change_value | default('not_defined') }}    {{ vrrp_group.tloc_preference_change_value_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tloc_preference_change_value
    Should Be Equal Value Json String
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].trackOmp.value
    ...    {{ vrrp_group.track_omp | default('False') }}
    ...    msg=service_lan_vpn interface vrrp_group track_omp

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrp[{{ loop.index0 }}].ipAddressSecondary  {{ vrrp_group.get('secondary_addresses', []) | length }}    msg=service_lan_vpn interface vrrp_group secondary_addresses length

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

{% for sec_addr in vrrp_group.secondary_addresses | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].ipAddressSecondary[{{ loop.index0 }}].ipAddress
    ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group secondary_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].ipAddressSecondary[{{ loop.index0 }}].subnetMask
    ...    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group secondary_subnet_mask
{% endfor %}

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrp[{{ loop.index0 }}].trackingObject  {{ vrrp_group.get('tracking_objects', []) | length }}    msg=service_lan_vpn interface vrrp_group tracking_objects length

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}

{% for track_obj in vrrp_group.tracking_objects | default([]) %}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].trackerAction
    ...    {{ track_obj.action | default('not_defined') }}    {{ track_obj.action_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tracking_object action
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].decrementValue
    ...    {{ track_obj.decrement_value | default('not_defined') }}    {{ track_obj.decrement_value_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tracking_object decrement_value    # --- Tracker Object RefId Check ---
{% if track_obj.tracker_object is defined %}
    ${tracker_obj}=    Json Search    ${tracker_objs}    [?payload.name=='{{ track_obj.tracker_object }}'] | [0]
    Run Keyword If    $tracker_obj is None    Fail    Tracker object '{{ track_obj.tracker_object }}' not found in Manager for profile '{{ profile.name }}'
    ${tracker_obj_id}=     Json Search String    ${tracker_obj}    parcelId
{% else %}
    ${tracker_obj_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].trackerId.refId
    ...    ${tracker_obj_id}    not_defined
    ...    msg=service_lan_vpn interface vrrp_group tracking_object tracker_object
{% endfor %}

{% endfor %}

    Log    ============IPv6 VRRP Groups==============

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrpIpv6  {{ intf_entry.get('ipv6_vrrp_groups', []) | length }}    msg=service_lan_vpn interface ipv6_vrrp_groups length

{% for vrrp_group in intf_entry.ipv6_vrrp_groups | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].followDualRouterHAAvailability
    ...    {{ vrrp_group.follow_dual_router_high_availability | default(True) }}    {{ vrrp_group.follow_dual_router_high_availability_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group follow_dual_router_high_availability
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].groupId
    ...    {{ vrrp_group.id | default('not_defined') }}    {{ vrrp_group.id_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group id
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].minPreemptDelay
    ...    {{ vrrp_group.min_preempt_delay | default('not_defined') }}    {{ vrrp_group.min_preempt_delay_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group min_preempt_delay
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].ipv6[0].prefix
    ...    {{ vrrp_group.global_prefix | default('not_defined') }}    {{ vrrp_group.global_prefix_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group global_prefix
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].ipv6[0].ipv6LinkLocal
    ...    {{ vrrp_group.link_local_address | default('not_defined') }}    {{ vrrp_group.link_local_address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group link_local_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].priority
    ...    {{ vrrp_group.priority | default('not_defined') }}    {{ vrrp_group.priority_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group priority
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].timer
    ...    {{ vrrp_group.timer | default('not_defined') }}    {{ vrrp_group.timer_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group timer
    Should Be Equal Value Json String
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].trackOmp.value
    ...    {{ vrrp_group.track_omp | default('False') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group track_omp

{% endfor %}

    Log    ===========IPv6 DHCP Helpers===========

    IF    ${ipv6_either_check} != []
        # 20.18 and higher
        Should Be Equal Value Json List Length      ${r_interface_name}   data.intfIpV6Address.either.static.dhcpHelperV6  {{ intf_entry.get('ipv6_dhcp_helpers', []) | length }}    msg=service_lan_vpn interface ipv6_dhcp_helpers length
{% for dhcp_helper in intf_entry.ipv6_dhcp_helpers | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.static.dhcpHelperV6[{{ loop.index0 }}].ipAddress
        ...    {{ dhcp_helper.address | default('not_defined') }}    {{ dhcp_helper.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_dhcp_helper address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.either.static.dhcpHelperV6[{{ loop.index0 }}].vpn
        ...    {{ dhcp_helper.vpn_id | default('not_defined') }}    {{ dhcp_helper.vpn_id_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_dhcp_helper vpn_id
{% endfor %}
    ELSE
        # below 20.18
        Should Be Equal Value Json List Length      ${r_interface_name}   data.intfIpV6Address.static.dhcpHelperV6  {{ intf_entry.get('ipv6_dhcp_helpers', []) | length }}    msg=service_lan_vpn interface ipv6_dhcp_helpers length
{% for dhcp_helper in intf_entry.ipv6_dhcp_helpers | default([]) %}
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.static.dhcpHelperV6[{{ loop.index0 }}].ipAddress
        ...    {{ dhcp_helper.address | default('not_defined') }}    {{ dhcp_helper.address_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_dhcp_helper address
        Should Be Equal Value Json Yaml
        ...    ${r_interface_name}    data.intfIpV6Address.static.dhcpHelperV6[{{ loop.index0 }}].vpn
        ...    {{ dhcp_helper.vpn_id | default('not_defined') }}    {{ dhcp_helper.vpn_id_variable | default('not_defined') }}
        ...    msg=service_lan_vpn interface ipv6_dhcp_helper vpn_id
{% endfor %}
    END

    Log    ===========Advanced Features===========

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.duplex
    ...    {{ intf_entry.duplex| default('not_defined') }}    {{ intf_entry.duplex_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface duplex
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.macAddress
    ...    {{ intf_entry.mac_address| default('not_defined') }}    {{ intf_entry.mac_address_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface mac_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.ipMtu
    ...    {{ intf_entry.ip_mtu| default('not_defined') }}    {{ intf_entry.ip_mtu_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ip_mtu
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.intrfMtu
    ...    {{ intf_entry.interface_mtu| default('not_defined') }}    {{ intf_entry.interface_mtu_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface interface_mtu
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.tcpMss
    ...    {{ intf_entry.tcp_mss| default('not_defined') }}    {{ intf_entry.tcp_mss_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.speed
    ...    {{ intf_entry.speed| default('not_defined') }}    {{ intf_entry.speed_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface speed
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.arpTimeout
    ...    {{ intf_entry.arp_timeout| default('not_defined') }}    {{ intf_entry.arp_timeout_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface arp_timeout
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.autonegotiate
    ...    {{ intf_entry.autonegotiate| default('not_defined') }}    {{ intf_entry.autonegotiate_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface autonegotiate
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.mediaType
    ...    {{ intf_entry.media_type| default('not_defined') }}    {{ intf_entry.media_type_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface media_type
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.loadInterval
    ...    {{ intf_entry.load_interval| default('not_defined') }}    {{ intf_entry.load_interval_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface load_interval
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.icmpRedirectDisable
    ...    {{ intf_entry.icmp_redirect_disable| default('not_defined') }}    {{ intf_entry.icmp_redirect_disable_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface icmp_redirect_disable
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.ipDirectedBroadcast
    ...    {{ intf_entry.ip_directed_broadcast| default('not_defined') }}    {{ intf_entry.ip_directed_broadcast_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ip_directed_broadcast
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.aclQos.shapingRate
    ...    {{ intf_entry.shaping_rate| default('not_defined') }}    {{ intf_entry.shaping_rate_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface shaping_rate
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.xconnect
    ...    {{ intf_entry.xconnect| default('not_defined') }}    {{ intf_entry.xconnect_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface xconnect
    Log    ===========Access Control Lists===========

    ${configured_ipv4_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclEgress.refId.value
    ${configured_ipv4_egress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv4_egress_acl}    payload.name
    ...    {{ intf_entry.ipv4_egress_acl | default('not_defined') }}
    ...    msg=wan_vpn.ethernet_interfaces_ipv4_egress_acl
    ${configured_ipv4_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclIngress.refId.value
    ${configured_ipv4_ingress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv4_ingress_acl}    payload.name
    ...    {{ intf_entry.ipv4_ingress_acl | default('not_defined') }}
    ...    msg=wan_vpn.ethernet_interfaces_ipv4_ingress_acl

    ${configured_ipv6_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclEgress.refId.value
    ${configured_ipv6_egress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv6_egress_acl}    payload.name
    ...    {{ intf_entry.ipv6_egress_acl | default('not_defined') }}
    ...    msg=wan_vpn.ethernet_interfaces_ipv6_egress_acl
    ${configured_ipv6_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclIngress.refId.value
    ${configured_ipv6_ingress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv6_ingress_acl}    payload.name
    ...    {{ intf_entry.ipv6_ingress_acl | default('not_defined') }}
    ...    msg=wan_vpn.ethernet_interfaces_ipv6_ingress_acl


    Log    ===========TrustSec Features===========

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.trustsec.enableSGTPropogation
    ...    {{ intf_entry.trustsec_enable_sgt_propogation | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface trustsec_enforced_sgt
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.trustsec.securityGroupTag
    ...    {{ intf_entry.trustsec_sgt | default('not_defined') }}    {{ intf_entry.trustsec_sgt_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface trustsec_sgt
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.trustsec.enableEnforcedPropogation
    ...    {{ intf_entry.trustsec_enable_enforced_propogation | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface trustsec_enforced_sgt
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.trustsec.enforcedSecurityGroupTag
    ...    {{ intf_entry.trustsec_enforced_sgt | default('not_defined') }}    {{ intf_entry.trustsec_enforced_sgt_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface trustsec_enforced_sgt
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.trustsec.propogate
    ...    {{ intf_entry.trustsec_propogate | default('not_defined')}}    not_defined
    ...    msg=service_lan_vpn interface trustsec_propogate

{% endfor %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endif %}
