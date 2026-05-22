*** Settings ***
Documentation   Verify Service Feature Profile Configuration LAN VPNs GRE Interfaces
Suite Setup     Login SDWAN Manager
Name            Service Profiles LAN VPNs GRE Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles   service_profiles  lan_vpns  gre_interfaces
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
    ${profile}=    Json Search     ${r.json()}    [?(@.profileName=='{{ profile.name }}')] | [0]
    Run Keyword If    $profile is None    Fail     Feature Profile '{{profile.name}}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable   ${profile_id}
    ${service_lan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn
    ${service_lan_vpn}=    Json Search List    ${service_lan_vpn_res.json()}    data
    Run Keyword If    ${service_lan_vpn} == []    Fail    Feature lan vpn expected to be configured within the service profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${service_lan_vpn}

{% for lan_vpn in profile.lan_vpns | default([]) %}

Verify Feature Profiles Service Profiles {{ profile.name }} {{lan_vpn.name}} GRE Interfaces 
    ${lan_vpn_profile}=    Json Search    ${service_lan_vpn}    [?payload.name=='{{ lan_vpn.name }}'] | [0]
    Run Keyword If    $lan_vpn_profile is None    Fail    Feature lan vpn '{{lan_vpn.name}}' expected to be configured within the service profile '{{profile.name}}' on the Manager
    ${lan_vpn_profile_id}=    Json Search String    ${lan_vpn_profile}    parcelId
    ${service_lan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn/${lan_vpn_profile_id}/interface/gre
    ${service_lan_vpn_intf}=    Json Search List    ${service_lan_vpn_intf_res.json()}    data[].payload

    Should Be Equal Value Json List Length     ${service_lan_vpn_intf}    @     {{ lan_vpn.get('gre_interfaces' , []) | length }}    msg=service_lan_vpn gre_interfaces length

{% for intf_entry in lan_vpn.gre_interfaces | default([]) %}

    Log   ======GRE Interface {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${service_lan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]

    Should Be Equal Value Json String            ${r_interface_name}    name         {{ intf_entry.name | default('not_defined') }}      msg=service_lan_vpn lan_vpn interface name
    Should Be Equal Value Json Special_String    ${r_interface_name}    description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=service_lan_vpn lan_vpn description
    
    # basic
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.clearDontFragment       {{ intf_entry.clear_dont_fragment | default('not_defined') }}    {{ intf_entry.clear_dont_fragment_variable | default('not_defined') }}   msg=service_lan_vpn interface clear_dont_fragment
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.dpdInterval   {{ intf_entry.dpd_interval | default('not_defined') }}    {{ intf_entry.dpd_interval_variable | default('not_defined') }}   msg=service_lan_vpn interface dpd_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.dpdRetries   {{ intf_entry.dpd_retries | default('not_defined') }}    {{ intf_entry.dpd_retries_variable | default('not_defined') }}   msg=service_lan_vpn interface dpd_retries
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeCiphersuite   {{ intf_entry.ike_cipher_suite | default('not_defined') }}    {{ intf_entry.ike_cipher_suite_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_cipher_suite
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeGroup   {{ intf_entry.ike_diffie_hellman_group | default('not_defined') }}    {{ intf_entry.ike_diffie_hellman_group_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_diffie_hellman_group
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeLocalId   {{ intf_entry.ike_id_for_local_endpoint | default('not_defined') }}    {{ intf_entry.ike_id_for_local_endpoint_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_id_for_local_endpoint
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeRemoteId   {{ intf_entry.ike_id_for_remote_endpoint | default('not_defined') }}    {{ intf_entry.ike_id_for_remote_endpoint_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_id_for_remote_endpoint
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeMode   {{ intf_entry.ike_integrity_protocol | default('not_defined') }}    {{ intf_entry.ike_integrity_protocol_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_integrity_protocol
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeRekeyInterval   {{ intf_entry.ike_rekey_interval | default('not_defined') }}    {{ intf_entry.ike_rekey_interval_variable | default('not_defined') }}   msg=service_lan_vpn interface ike_rekey_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeVersion   {{ intf_entry.ike_version | default('not_defined') }}    not_defined   msg=service_lan_vpn interface ike_version
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.description      {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}   msg=service_lan_vpn lan_vpn interface interface_description
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ifName      {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}   msg=service_lan_vpn lan_vpn interface interface_name
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.address.address       {{ intf_entry.ipv4_address | default('not_defined') }}    {{ intf_entry.ipv4_address_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.mtu           {{ intf_entry.ipv4_mtu | default('not_defined') }}    {{ intf_entry.ipv4_mtu_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv4_mtu
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.address.mask   {{ intf_entry.ipv4_subnet_mask | default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv4_subnet_mask
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tcpMssAdjust           {{ intf_entry.ipv4_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv4_tcp_mss_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv4_tcp_mss
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipv6Address   {{ intf_entry.ipv6_address | default('not_defined') }}    {{ intf_entry.ipv6_address_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.mtuV6   {{ intf_entry.ipv6_mtu | default('not_defined') }}    {{ intf_entry.ipv6_mtu_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv6_mtu
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tcpMssAdjustV6   {{ intf_entry.ipv6_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv6_tcp_mss_variable | default('not_defined') }}   msg=service_lan_vpn interface ipv6_tcp_mss
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecCiphersuite   {{ intf_entry.ipsec_cipher_suite | default('not_defined') }}    {{ intf_entry.ipsec_cipher_suite_variable | default('not_defined') }}   msg=service_lan_vpn interface ipsec_cipher_suite
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecRekeyInterval   {{ intf_entry.ipsec_rekey_interval | default('not_defined') }}    {{ intf_entry.ipsec_rekey_interval_variable | default('not_defined') }}   msg=service_lan_vpn interface ipsec_rekey_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecReplayWindow   {{ intf_entry.ipsec_replay_window | default('not_defined') }}    {{ intf_entry.ipsec_replay_window_variable | default('not_defined') }}   msg=service_lan_vpn interface ipsec_replay_window
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.perfectForwardSecrecy   {{ intf_entry.perfect_forward_secrecy | default('not_defined') }}    {{ intf_entry.perfect_forward_secrecy_variable | default('not_defined') }}   msg=service_lan_vpn interface perfect_forward_secrecy
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.preSharedSecret   {{ intf_entry.preshared_key_for_ike | default('not_defined') }}    {{ intf_entry.preshared_key_for_ike_variable | default('not_defined') }}   msg=service_lan_vpn interface preshared_key_for_ike
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.shutdown   {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}   msg=service_lan_vpn interface shutdown 
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelDestination           {{ intf_entry.tunnel_destination_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv4_address_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_destination_ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelDestinationV6   {{ intf_entry.tunnel_destination_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv6_address_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_destination_ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelMode   {{ intf_entry.tunnel_mode | default('not_defined') }}        not_defined     msg=service_lan_vpn interface tunnel_mode
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIp.tunnelRouteVia           {{ intf_entry.tunnel_route_via_loopback | default('not_defined') }}    {{ intf_entry.tunnel_route_via_loopback_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_route_via_loopback
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceNotLoopback.tunnelSourceInterface           {{ intf_entry.tunnel_source_interface | default('not_defined') }}    {{ intf_entry.tunnel_source_interface_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_source_interface
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceLoopback.tunnelSourceInterface           {{ intf_entry.tunnel_source_interface_loopback | default('not_defined') }}    {{ intf_entry.tunnel_source_interface_loopback_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_source_interface_loopback
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIp.tunnelSource           {{ intf_entry.tunnel_source_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv4_address_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_source_ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIpv6.tunnelSourceV6   {{ intf_entry.tunnel_source_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv6_address_variable | default('not_defined') }}   msg=service_lan_vpn interface tunnel_source_ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelProtection   {{ intf_entry.tunnel_protection | default('not_defined') }}      not_defined       msg=service_lan_vpn interface tunnel_protection
    
    # advanced
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.advanced.application   {{ intf_entry.application_tunnel_type | default('not_defined') }}    {{ intf_entry.application_tunnel_type_variable | default('not_defined') }}   msg=service_lan_vpn interface application_tunnel_type

{% endfor %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endif %}
