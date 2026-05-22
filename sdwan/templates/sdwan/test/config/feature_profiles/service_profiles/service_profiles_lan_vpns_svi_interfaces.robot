*** Settings ***
Documentation   Verify Service Feature Profile Configuration LAN VPNs SVI Interfaces
Suite Setup     Login SDWAN Manager
Name            Service Profiles LAN VPNs SVI Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    lan_vpns    svi_interfaces
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

Verify Feature Profiles Service Profiles {{ profile.name }} {{lan_vpn.name}} SVI Interfaces
    ${lan_vpn_profile}=    Json Search    ${service_lan_vpn}    [?payload.name=='{{ lan_vpn.name }}'] | [0]
    Run Keyword If    $lan_vpn_profile is None    Fail    Feature lan vpn '{{lan_vpn.name}}' expected to be configured within the service profile '{{ profile.name }}' on the Manager
    ${lan_vpn_profile_id}=    Json Search String    ${lan_vpn_profile}    parcelId
    ${trackers_lan_svi_interface}=   Json Search List    ${service_profile_res.json()}    associatedProfileParcels[].subparcels[] | [?parcelType=='lan/vpn/interface/svi']
    Set Suite Variable    ${trackers_lan_svi_interface}
    ${service_lan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn/${lan_vpn_profile_id}/interface/svi
    ${service_lan_vpn_intf}=    Json Search List    ${service_lan_vpn_intf_res.json()}    data[].payload

    Should Be Equal Value Json List Length   ${service_lan_vpn_intf}  @  {{ lan_vpn.get('svi_interfaces' , []) | length }}    msg=service_lan_vpn svi_interfaces length

{% for intf_entry in lan_vpn.svi_interfaces | default([]) %}

    Log   ======SVI Interface {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${service_lan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]

    Log   ============Tracker Associations=============

    ${lan_svi_interface_target}=    Json Search    ${trackers_lan_svi_interface}    [?payload.name=='{{ intf_entry.name }}'] | [0]

    Should Be Equal Value Json String
    ...    ${lan_svi_interface_target}    subparcels[?parcelType=='trackergroup'] | [0].payload.name
    ...    {{ intf_entry.ipv4_tracker_group | default('not_defined') }}
    ...    msg=service_lan_vpn svi_interfaces ipv4 tracker group name
    Should Be Equal Value Json String
    ...    ${lan_svi_interface_target}    subparcels[?parcelType=='tracker'] | [0].payload.name
    ...    {{ intf_entry.ipv4_tracker | default('not_defined') }}
    ...    msg=service_lan_vpn svi_interfaces tracker name

    Log   ============ DHCP Associations=============
    Should Be Equal Value Json String
    ...    ${lan_svi_interface_target}    subparcels[?parcelType=='dhcp-server'] | [0].payload.name
    ...    {{ intf_entry.dhcp_server | default('not_defined') }}
    ...    msg=service_lan_vpn svi_interfaces dhcp server name


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
    ...    ${r_interface_name}    data.ipMtu
    ...    {{ intf_entry.ip_mtu| default('not_defined') }}    {{ intf_entry.ip_mtu_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ip_mtu
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ifMtu
    ...    {{ intf_entry.interface_mtu| default('not_defined') }}    {{ intf_entry.interface_mtu_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface interface_mtu
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.shutdown
    ...    {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface shutdown

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv4.addressV4.ipAddress
    ...    {{ intf_entry.ipv4_address| default('not_defined') }}    {{ intf_entry.ipv4_address_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv4.addressV4.subnetMask
    ...    {{ intf_entry.ipv4_subnet_mask| default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_subnet_mask  

    Should Be Equal Value Json List Length   ${r_interface_name}  data.ipv4.secondaryAddressV4  {{ intf_entry.get('ipv4_secondary_addresses' , [] ) | length }}    msg=ipv4 secondary addresses length
{% for sec_addr in intf_entry.ipv4_secondary_addresses | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv4.secondaryAddressV4[{{ loop.index0 }}].ipAddress
    ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_secondary_address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv4.secondaryAddressV4[{{ loop.index0 }}].subnetMask
    ...    {{ sec_addr.subnet_mask | default('not_defined') }}    {{ sec_addr.subnet_mask_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_secondary_subnet_mask

{% endfor %}

    ${dhcp_helpers_list}=    Set Variable If    "{{ intf_entry.get('ipv4_dhcp_helpers', []) | length }}" == "0"    not_defined    {{ intf_entry.get('ipv4_dhcp_helpers', []) }}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv4.dhcpHelperV4
    ...    ${dhcp_helpers_list}    {{ intf_entry.ipv4_dhcp_helpers_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv4_dhcp_helpers

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv6.addressV6
    ...    {{ intf_entry.ipv6_address| default('not_defined') }}    {{ intf_entry.ipv6_address_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_address
    
    Should Be Equal Value Json List Length      ${r_interface_name}  data.ipv6.secondaryAddressV6  {{ intf_entry.get('ipv6_secondary_addresses', []) | length }}    msg=ipv6 secondary addresses length
{% for sec_addr in intf_entry.ipv6_secondary_addresses  | default([]) %}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv6.secondaryAddressV6[{{ loop.index0 }}].address
    ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_secondary_address
{% endfor %}

    Should Be Equal Value Json List Length      ${r_interface_name}  data.ipv6.dhcpHelperV6  {{ intf_entry.get('ipv6_dhcp_helpers', []) | length }}    msg=ipv6 ipv6_dhcp_helpers length
{% for dhcp_helper in intf_entry.ipv6_dhcp_helpers  | default([]) %}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv6.dhcpHelperV6[{{ loop.index0 }}].address
    ...    {{ dhcp_helper.address | default('not_defined') }}    {{ dhcp_helper.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_dhcp_helpers address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.ipv6.dhcpHelperV6[{{ loop.index0 }}].vpn
    ...    {{ dhcp_helper.vpn_id | default('not_defined') }}    {{ dhcp_helper.vpn_id_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_dhcp_helpers vpn_id
{% endfor %}
    
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
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].ipAddress
    ...    {{ vrrp_group.address | default('not_defined') }}    {{ vrrp_group.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group address
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].followDualRouterHAAvailability
    ...    {{ vrrp_group.follow_dual_router_high_availability | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface vrrp_group follow_dual_router_high_availability
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].group_id
    ...    {{ vrrp_group.id | default('not_defined') }}    {{ vrrp_group.id_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group id
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].prefixList
    ...    {{ vrrp_group.prefix_list | default('not_defined') }}    {{ vrrp_group.prefix_list_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group prefix_list
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].priority
    ...    {{ vrrp_group.priority | default('not_defined') }}    {{ vrrp_group.priority_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group priority
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].timer
    ...    {{ vrrp_group.timer | default('not_defined') }}    {{ vrrp_group.timer_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group timer
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].tlocPrefChange
    ...    {{ vrrp_group.tloc_preference_change | default('not_defined') }}         not_defined
    ...    msg=service_lan_vpn interface vrrp_group tloc_preference_change
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].tlocPrefChangeValue
    ...    {{ vrrp_group.tloc_preference_change_value | default('not_defined') }}    {{ vrrp_group.tloc_preference_change_value_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tloc_preference_change_value
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[{{ loop.index0 }}].trackOmp
    ...    {{ vrrp_group.track_omp | default('not_defined') }}          not_defined
    ...    msg=service_lan_vpn interface vrrp_group track_omp

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrp[{{ loop.index0 }}].ipAddressSecondary  {{ vrrp_group.get('secondary_addresses', []) | length }}    msg=service_lan_vpn interface vrrp_group secondary_addresses length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
{% for sec_addr in vrrp_group.secondary_addresses | default([]) %}
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].ipAddressSecondary[{{ loop.index0 }}].address
    ...    {{ sec_addr.address | default('not_defined') }}    {{ sec_addr.address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group secondary_address
{% endfor %}

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrp[{{ loop.index0 }}].trackingObject  {{ vrrp_group.get('tracking_objects', []) | length }}    msg=service_lan_vpn interface vrrp_group tracking_objects length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
{% for track_obj in vrrp_group.tracking_objects | default([]) %}
    
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].trackAction
    ...    {{ track_obj.action | default('not_defined') }}    {{ track_obj.action_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tracking_object action
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].decrementValue
    ...    {{ track_obj.decrement_value | default('not_defined') }}    {{ track_obj.decrement_value_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface vrrp_group tracking_object decrement_value    
    
    # --- Tracker Object RefId Check ---
{% if track_obj.tracker_object is defined %}
    ${tracker_obj}=    Json Search    ${tracker_objs}    [?payload.name=='{{ track_obj.tracker_object }}'] | [0]
    Run Keyword If    $tracker_obj is None    Fail    Tracker object '{{ track_obj.tracker_object }}' not found in Manager for profile '{{ profile.name }}'
    ${tracker_obj_id}=     Json Search String    ${tracker_obj}    parcelId
{% else %}
    ${tracker_obj_id}=     Set Variable    not_defined
{% endif %}
    Should Be Equal Value Json String
    ...    ${r_interface_name}    data.vrrp[${outer_loop_index}].trackingObject[{{ loop.index0 }}].trackerId.refId.value
    ...    ${tracker_obj_id}
    ...    msg=service_lan_vpn interface vrrp_group tracking_object tracker_object

{% endfor %}

{% endfor %}

    Log    ============IPv6 VRRP Groups==============

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrpIpv6  {{ intf_entry.get('ipv6_vrrp_groups', []) | length }}    msg=service_lan_vpn interface ipv6_vrrp_groups length
{% for vrrp_group in intf_entry.ipv6_vrrp_groups | default([]) %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].followDualRouterHAAvailability
    ...    {{ vrrp_group.follow_dual_router_high_availability | default('not_defined') }}    not_defined
    ...    msg=service_lan_vpn interface ipv6_vrrp_group follow_dual_router_high_availability

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].groupId
    ...    {{ vrrp_group.id | default('not_defined') }}    {{ vrrp_group.id_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group id

    Should Be Equal Value Json List Length      ${r_interface_name}   data.vrrpIpv6[{{ loop.index0 }}].ipv6  {{ vrrp_group.get('addresses', []) | length }}    msg=service_lan_vpn interface ipv6 addresses length
    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
{% for address in vrrp_group.addresses | default([]) %}
    Should Be Equal Value Json Yaml     
    ...    ${r_interface_name}   data.vrrpIpv6[${outer_loop_index}].ipv6[{{ loop.index0 }}].ipv6LinkLocal
    ...    {{ address.link_local_address | default('not_defined') }}    {{ address.link_local_address_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6 addresses link_local_address

    Should Be Equal Value Json Yaml     
    ...    ${r_interface_name}   data.vrrpIpv6[${outer_loop_index}].ipv6[{{ loop.index0 }}].prefix 
    ...    {{ address.global_prefix | default('not_defined') }}    {{ address.global_prefix_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6 addresses global_prefix
{% endfor %}

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].priority
    ...    {{ vrrp_group.priority | default('not_defined') }}    {{ vrrp_group.priority_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group priority
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].timer
    ...    {{ vrrp_group.timer | default('not_defined') }}    {{ vrrp_group.timer_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group timer
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].trackOmp
    ...    {{ vrrp_group.track_omp | default('not_defined') }}        {{ vrrp_group.track_omp_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group track_omp
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.vrrpIpv6[{{ loop.index0 }}].trackPrefixList
    ...    {{ vrrp_group.track_prefix_list | default('not_defined') }}        {{ vrrp_group.track_prefix_list_variable | default('not_defined') }}
    ...    msg=service_lan_vpn interface ipv6_vrrp_group track_prefix_list

{% endfor %}

    Log    ===========Advanced Features===========

    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.tcpMss
    ...    {{ intf_entry.tcp_mss| default('not_defined') }}    {{ intf_entry.tcp_mss_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.arpTimeout
    ...    {{ intf_entry.arp_timeout| default('not_defined') }}    {{ intf_entry.arp_timeout_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface arp_timeout
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.icmpRedirectDisable
    ...    {{ intf_entry.icmp_redirect_disable| default('not_defined') }}    {{ intf_entry.icmp_redirect_disable_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface icmp_redirect_disable
    Should Be Equal Value Json Yaml
    ...    ${r_interface_name}    data.advanced.ipDirectedBroadcast
    ...    {{ intf_entry.ip_directed_broadcast| default('not_defined') }}    {{ intf_entry.ip_directed_broadcast_variable| default('not_defined') }}
    ...    msg=service_lan_vpn interface ip_directed_broadcast
    
    Log    ===========Access Control Lists===========

    ${configured_ipv4_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclEgress.refId.value
    ${configured_ipv4_egress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv4_egress_acl}    payload.name
    ...    {{ intf_entry.ipv4_egress_acl | default('not_defined') }}
    ...    msg=service_lan_vpn.svi_interfaces_ipv4_egress_acl
    ${configured_ipv4_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclIngress.refId.value
    ${configured_ipv4_ingress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv4_ingress_acl}    payload.name
    ...    {{ intf_entry.ipv4_ingress_acl | default('not_defined') }}
    ...    msg=service_lan_vpn.svi_interfaces_ipv4_ingress_acl

    ${configured_ipv6_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclEgress.refId.value
    ${configured_ipv6_egress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv6_egress_acl}    payload.name
    ...    {{ intf_entry.ipv6_egress_acl | default('not_defined') }}
    ...    msg=service_lan_vpn.svi_interfaces_ipv6_egress_acl
    ${configured_ipv6_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclIngress.refId.value
    ${configured_ipv6_ingress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String
    ...    ${configured_ipv6_ingress_acl}    payload.name
    ...    {{ intf_entry.ipv6_ingress_acl | default('not_defined') }}
    ...    msg=service_lan_vpn.svi_interfaces_ipv6_ingress_acl


{% endfor %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endif %}
