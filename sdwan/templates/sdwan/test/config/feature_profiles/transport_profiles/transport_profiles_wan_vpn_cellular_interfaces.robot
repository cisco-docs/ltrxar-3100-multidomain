*** Settings ***
Documentation   Verify Transport Feature Profile Configuration WAN VPN Cellular Interfaces
Suite Setup     Login SDWAN Manager
Name            Transport Profiles WAN VPN Cellular Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    wan_vpn    cellular_interfaces
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
{% if profile.wan_vpn.cellular_interfaces is defined and profile.wan_vpn.get('cellular_interfaces' , [])|length > 0 %}

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

    ${trans_wan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn/${vpn_parcel_id}/interface/cellular
    ${trans_wan_vpn_intf}=    Json Search List    ${trans_wan_vpn_intf_res.json()}    data[].payload
    Set Suite Variable    ${trans_wan_vpn_intf}

    ${tracker_groups_cellular_interfaces}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='wan/vpn'] | [0].subparcels[?parcelType=='wan/vpn/interface/cellular']
    Set Suite Variable    ${tracker_groups_cellular_interfaces}

    ${ipv4_acls}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='ipv4-acl']
    Set Suite Variable    ${ipv4_acls}

    ${ipv6_acls}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='ipv6-acl']
    Set Suite Variable    ${ipv6_acls}

    Should Be Equal Value Json List Length   ${trans_wan_vpn_intf}   @   {{ profile.wan_vpn.get('cellular_interfaces' , []) | length }}    msg=transport_wan_vpn cellular_interfaces length

{% for intf_entry in profile.wan_vpn.cellular_interfaces | default([]) %}

    Log   ======Cellular Interfaces {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${trans_wan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]
    ${tracker_groups_cellular_interface}=   Json Search    ${tracker_groups_cellular_interfaces}    [?payload.name=='{{ intf_entry.name }}'] | [0]

    Log   ======Tracker Associations=======

    Should Be Equal Value Json String     ${tracker_groups_cellular_interface}   subparcels[?parcelType=='trackergroup'] | [0].payload.name  {{ intf_entry.ipv4_tracker_group | default('not_defined') }}    msg=transport_wan_vpn cellular_interfaces ipv4 tracker group name
    Should Be Equal Value Json String     ${tracker_groups_cellular_interface}   subparcels[?parcelType=='tracker'] | [0].payload.name        {{ intf_entry.ipv4_tracker | default('not_defined') }}    msg=transport_wan_vpn cellular_interfaces tracker name

    Log   ======Basic Configuration========

    Should Be Equal Value Json String    ${r_interface_name}    name    {{ intf_entry.name | default('not_defined') }}    msg=transport_wan_vpn wan_vpn interface name
    Should Be Equal Value Json Special_String    ${r_interface_name}   description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=transport_wan_vpn wan_vpn description

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.interfaceName    {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}    msg=transport_wan_vpn wan_vpn interface interface_name
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.description    {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}    msg=transport_wan_vpn interface interface_description
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.shutdown    {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}    msg=transport_wan_vpn interface shutdown
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.serviceProvider    {{ intf_entry.service_provider | default('not_defined') }}    {{ intf_entry.service_provider_variable | default("not_defined") }}    msg=transport_wan_vpn interface service provider
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.bandwidthUpstream    {{ intf_entry.bandwidth_upstream | default('not_defined') }}    {{ intf_entry.bandwidth_upstream_variable | default("not_defined") }}    msg=transport_wan_vpn interface bandwidth_upstream
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.bandwidthDownstream    {{ intf_entry.bandwidth_downstream | default('not_defined') }}    {{ intf_entry.bandwidth_downstream_variable | default("not_defined") }}    msg=transport_wan_vpn interface bandwidth_downstream
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.enableIpv6    {{ intf_entry.enable_ipv6 | default('not_defined') }}    {{ intf_entry.enable_ipv6_variable | default("not_defined") }}    msg=transport_wan_vpn interface enable_ipv6

{% if intf_entry.ipv4_dhcp_helpers is defined and intf_entry.get('ipv4_dhcp_helpers' , []) | length > 0 %}

    ${dhcp_helpers_list}=    Create List    {{ intf_entry.ipv4_dhcp_helpers | join('   ') }}
    ${r_dhcp_helpers_list}=    Create List

    ${r_dhcp_helpers_list}=   Json Search List    ${r_interface_name}     data.dhcpHelper.value

    Lists Should Be Equal   ${dhcp_helpers_list}    ${r_dhcp_helpers_list}     msg=transport_wan_vpn_intf_dhcp_helpers_list     ignore_order=True

{% endif %}

    Log    ======Tunnel Configurations=======

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.bind    {{ intf_entry.tunnel_interface.bind_loopback_tunnel | default('not_defined') }}    {{ intf_entry.tunnel_interface.bind_loopback_tunnel_variable | default('not_defined') }}    msg=transport_wan_vpn interface bind loopback
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.border    {{ intf_entry.tunnel_interface.border | default('not_defined') }}    {{ intf_entry.tunnel_interface.border_variable| default('not_defined') }}    msg=transport_wan_vpn interface border
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.carrier    {{ intf_entry.tunnel_interface.carrier | default('not_defined') }}    {{ intf_entry.tunnel_interface.carrier_variable| default('not_defined') }}    msg=transport_wan_vpn interface carrier
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.clearDontFragment    {{ intf_entry.tunnel_interface.clear_dont_fragment | default('not_defined') }}    {{ intf_entry.tunnel_interface.clear_dont_fragment_variable| default('not_defined') }}    msg=transport_wan_vpn interface clear_dont_fragment
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.color    {{ intf_entry.tunnel_interface.color | default('not_defined') }}    {{ intf_entry.tunnel_interface.color_variable| default('not_defined') }}    msg=transport_wan_vpn interface color
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.excludeControllerGroupList    {{ intf_entry.tunnel_interface.exclude_controller_groups | default('not_defined') }}    {{ intf_entry.tunnel_interface.exclude_controller_groups | default('not_defined') }}    msg=transport_wan_vpn interface exclude_controller_groups
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.group    {{ intf_entry.tunnel_interface.group | default('not_defined') }}    {{ intf_entry.tunnel_interface.group_variable| default('not_defined') }}    msg=transport_wan_vpn interface group
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.helloInterval    {{ intf_entry.tunnel_interface.hello_interval | default('not_defined') }}    {{ intf_entry.tunnel_interface.hello_interval_variable| default('not_defined') }}    msg=transport_wan_vpn interface hello interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.helloTolerance    {{ intf_entry.tunnel_interface.hello_tolerance | default('not_defined') }}    {{ intf_entry.tunnel_interface.hello_tolerance_variable| default('not_defined') }}    msg=transport_wan_vpn interface hello tolerance
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.lastResortCircuit    {{ intf_entry.tunnel_interface.last_resort_circuit | default('not_defined') }}    {{ intf_entry.tunnel_interface.last_resort_circuit_variable| default('not_defined') }}    msg=transport_wan_vpn interface last_resort_circuit
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.lowBandwidthLink    {{ intf_entry.tunnel_interface.low_bandwidth_link | default('not_defined') }}    {{ intf_entry.tunnel_interface.low_bandwidth_link_variable| default('not_defined') }}    msg=transport_wan_vpn interface low_bandwidth_link
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.maxControlConnections    {{ intf_entry.tunnel_interface.max_control_connections | default('not_defined') }}    {{ intf_entry.tunnel_interface.max_control_connections_variable| default('not_defined') }}    msg=transport_wan_vpn interface max_control_connections
    
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.natRefreshInterval    {{ intf_entry.tunnel_interface.nat_refresh_interval | default('not_defined') }}    {{ intf_entry.tunnel_interface.nat_refresh_interval_variable| default('not_defined') }}    msg=transport_wan_vpn interface nat_refresh_interval
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.networkBroadcast    {{ intf_entry.tunnel_interface.network_broadcast | default('not_defined') }}    {{ intf_entry.tunnel_interface.network_broadcast_variable| default('not_defined') }}    msg=transport_wan_vpn interface network_broadcast
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.perTunnelQos    {{ intf_entry.tunnel_interface.per_tunnel_qos | default('not_defined') }}   {{ intf_entry.tunnel_interface.per_tunnel_qos_variable | default('not_defined') }}    msg=transport_wan_vpn interface per tunnel qos
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.mode    {{ intf_entry.tunnel_interface.per_tunnel_qos_mode | default('not_defined') }}   {{ intf_entry.tunnel_interface.per_tunnel_qos_mode_variable | default('not_defined') }}    msg=transport_wan_vpn interface per_tunnel_qos_mode
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.portHop    {{ intf_entry.tunnel_interface.port_hop | default('not_defined') }}    {{ intf_entry.tunnel_interface.port_hop_variable| default('not_defined') }}    msg=transport_wan_vpn interface port_hop
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.restrict    {{ intf_entry.tunnel_interface.restrict | default('not_defined') }}    {{ intf_entry.tunnel_interface.restrict_variable| default('not_defined') }}    msg=transport_wan_vpn interface restrict
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.tunnelTcpMss    {{ intf_entry.tunnel_interface.tcp_mss | default('not_defined') }}    {{ intf_entry.tunnel_interface.tcp_mss_variable| default('not_defined') }}    msg=transport_wan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.vBondAsStunServer    {{ intf_entry.tunnel_interface.vbond_as_stun_server | default('not_defined') }}    {{ intf_entry.tunnel_interface.vbond_as_stun_server_variable| default('not_defined') }}    msg=transport_wan_vpn interface vbond_as_stun_server
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnel.vManageConnectionPreference    {{ intf_entry.tunnel_interface.vmanage_connection_preference | default('not_defined') }}    {{ intf_entry.tunnel_interface.vmanage_connection_preference_variable| default('not_defined') }}    msg=transport_wan_vpn interface vmanage_connection_preference

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.all    {{ intf_entry.tunnel_interface.allow_service_all | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_all_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_all
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.bfd    {{ intf_entry.tunnel_interface.allow_service_bfd | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_bfd_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_bfd
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.bgp    {{ intf_entry.tunnel_interface.allow_service_bgp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_bgp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_bgp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.dhcp    {{ intf_entry.tunnel_interface.allow_service_dhcp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_dhcp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_dhcp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.dns    {{ intf_entry.tunnel_interface.allow_service_dns | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_dns_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_dns
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.https    {{ intf_entry.tunnel_interface.allow_service_https | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_https_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_https
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.icmp    {{ intf_entry.tunnel_interface.allow_service_icmp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_icmp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_icmp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.netconf    {{ intf_entry.tunnel_interface.allow_service_netconf | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_netconf_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_netconf
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ntp    {{ intf_entry.tunnel_interface.allow_service_ntp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ntp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ntp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ospf    {{ intf_entry.tunnel_interface.allow_service_ospf | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ospf_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ospf
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.snmp    {{ intf_entry.tunnel_interface.allow_service_snmp | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_snmp_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_snmp
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.ssh    {{ intf_entry.tunnel_interface.allow_service_ssh | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_ssh_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_ssh
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.allowService.stun    {{ intf_entry.tunnel_interface.allow_service_stun | default('not_defined') }}    {{ intf_entry.tunnel_interface.allow_service_stun_variable| default('not_defined') }}    msg=transport_wan_vpn interface allow_service_stun

    ${gre_object}=    Json Search    ${r_interface_name}   data.encapsulation[?encap.value=='gre'] | [0]
    Should Be Equal Value Json Yaml   ${gre_object}    preference   {{ intf_entry.tunnel_interface.gre_preference | default('not_defined') }}   {{ intf_entry.tunnel_interface.gre_preference_variable | default('not_defined') }}  msg=transport_wan_vpn interface gre encapsulation
    Should Be Equal Value Json Yaml   ${gre_object}    weight   {{ intf_entry.tunnel_interface.gre_weight | default('not_defined') }}   {{ intf_entry.tunnel_interface.gre_weight_variable | default('not_defined') }}  msg=transport_wan_vpn interface gre weight

    ${ipsec_object}=    Json Search    ${r_interface_name}   data.encapsulation[?encap.value=='ipsec'] | [0]
    Should Be Equal Value Json Yaml   ${ipsec_object}    preference   {{ intf_entry.tunnel_interface.ipsec_preference | default('not_defined') }}   {{ intf_entry.tunnel_interface.ipsec_preference_variable | default('not_defined') }}  msg=transport_wan_vpn interface ipsec encapsulation
    Should Be Equal Value Json Yaml   ${ipsec_object}    weight   {{ intf_entry.tunnel_interface.ipsec_weight | default('not_defined') }}   {{ intf_entry.tunnel_interface.ipsec_weight_variable | default('not_defined') }}  msg=transport_wan_vpn interface ipsec weight


    Should Be Equal Value Json Yaml     ${r_interface_name}    data.nat   {{ intf_entry.ipv4_nat | default('not_defined') }}     {{ intf_entry.ipv4_nat_variable | default('not_defined') }}     msg=transport_wan_vpn interface nat
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv4.udpTimeout   {{ intf_entry.ipv4_nat_udp_timeout | default('not_defined') }}     {{ intf_entry.ipv4_nat_udp_timeout_variable| default('not_defined') }}     msg=transport_wan_vpn interface nat_udp_timeout
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.natAttributesIpv4.tcpTimeout   {{ intf_entry.ipv4_nat_tcp_timeout | default('not_defined') }}     {{ intf_entry.ipv4_nat_tcp_timeout_variable| default('not_defined') }}     msg=transport_wan_vpn interface nat_tcp_timeout

    Log    ======ACL/QoS======

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.adaptiveQoS   {{ intf_entry.adaptive_qos| default('not_defined') }}     not_defined     msg=transport_wan_vpn adaptive_qos
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.adaptPeriod   {{ intf_entry.adaptive_qos_period| default('not_defined') }}     {{ intf_entry.adaptive_qos_period_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_period
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.minShapingRateUpstream  {{ intf_entry.adaptive_qos_shaping_rate_upstream.minimum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.minimum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream minimum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.maxShapingRateUpstream   {{ intf_entry.adaptive_qos_shaping_rate_upstream.maximum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.maximum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream maximum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateUpstreamConfig.defaultShapingRateUpstream   {{ intf_entry.adaptive_qos_shaping_rate_upstream.default| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_upstream.default_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_upstream default
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.minShapingRateDownstream  {{ intf_entry.adaptive_qos_shaping_rate_downstream.minimum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.minimum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream minimum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.maxShapingRateDownstream   {{ intf_entry.adaptive_qos_shaping_rate_downstream.maximum| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.maximum_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream maximum
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRateDownstreamConfig.defaultShapingRateDownstream   {{ intf_entry.adaptive_qos_shaping_rate_downstream.default| default('not_defined') }}     {{ intf_entry.adaptive_qos_shaping_rate_downstream.default_variable| default('not_defined') }}     msg=transport_wan_vpn adaptive_qos_shaping_rate_downstream.default
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.aclQos.shapingRate   {{ intf_entry.shaping_rate| default('not_defined') }}     {{ intf_entry.shaping_rate_variable| default('not_defined') }}     msg=transport_wan_vpn shaping_rate

    ${configured_ipv4_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclEgress.refId.value
    ${configured_ipv4_egress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv4_egress_acl}    payload.name    {{ intf_entry.ipv4_egress_acl | default('not_defined') }}    msg=wan_vpn.cellular_interfaces_ipv4_egress_acl
    ${configured_ipv4_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv4AclIngress.refId.value
    ${configured_ipv4_ingress_acl}=    Json Search    ${ipv4_acls}    [?parcelId=='${configured_ipv4_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv4_ingress_acl}    payload.name    {{ intf_entry.ipv4_ingress_acl | default('not_defined') }}    msg=wan_vpn.cellular_interfaces_ipv4_ingress_acl

    ${configured_ipv6_egress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclEgress.refId.value
    ${configured_ipv6_egress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_egress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv6_egress_acl}    payload.name    {{ intf_entry.ipv6_egress_acl | default('not_defined') }}    msg=wan_vpn.cellular_interfaces_ipv6_egress_acl
    ${configured_ipv6_ingress_acl_refid}=    Json Search String    ${r_interface_name}    data.aclQos.ipv6AclIngress.refId.value
    ${configured_ipv6_ingress_acl}=    Json Search    ${ipv6_acls}    [?parcelId=='${configured_ipv6_ingress_acl_refid}'] | [0]
    Should Be Equal Value Json String    ${configured_ipv6_ingress_acl}    payload.name    {{ intf_entry.ipv6_ingress_acl | default('not_defined') }}    msg=wan_vpn.cellular_interfaces_ipv6_ingress_acl

    Log    =====Advanced Features=====

    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipMtu   {{ intf_entry.ip_mtu| default('not_defined') }}     {{ intf_entry.ip_mtu_variable| default('not_defined') }}     msg=transport_wan_vpn interface ip_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.intrfMtu   {{ intf_entry.interface_mtu| default('not_defined') }}     {{ intf_entry.interface_mtu_variable| default('not_defined') }}     msg=transport_wan_vpn interface interface_mtu
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tcpMss   {{ intf_entry.tcp_mss| default('not_defined') }}     {{ intf_entry.tcp_mss_variable| default('not_defined') }}     msg=transport_wan_vpn interface tcp_mss
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.ipDirectedBroadcast   {{ intf_entry.ip_directed_broadcast| default('not_defined') }}     {{ intf_entry.ip_directed_broadcast_variable| default('not_defined') }}     msg=transport_wan_vpn interface ip_directed_broadcast
    Should Be Equal Value Json Yaml    ${r_interface_name}    data.advanced.tlocExtension   {{ intf_entry.tloc_extension| default('not_defined') }}     {{ intf_entry.tloc_extension_variable| default('not_defined') }}     msg=transport_wan_vpn interface tloc_extension

{% endfor %}

{% endif %}
    
{% endfor %}

{% endif %}

{% endif %}
