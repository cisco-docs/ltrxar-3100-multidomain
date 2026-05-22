*** Settings ***
Documentation   Verify Transport Feature Profile Configuration WAN VPN GRE Interfaces
Suite Setup     Login SDWAN Manager
Name            Transport Profiles WAN VPN GRE Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    wan_vpn    gre_interfaces
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
{% if profile.wan_vpn.gre_interfaces is defined and profile.wan_vpn.get('gre_interfaces' , [])|length > 0 %}

Verify Feature Profiles Transport Profiles {{ profile.name }} WAN VPN {{ profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name) }} GRE Interfaces

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${transport_wan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn
    ${transport_profile_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}
    ${transport_wan_vpn}=    Json Search List    ${transport_wan_vpn_res.json()}    data[].payload
    Run Keyword If    ${transport_wan_vpn} == []    Fail    Feature '{{profile.wan_vpn.name | default(defaults.sdwan.feature_profiles.transport_profiles.wan_vpn.name)}}' expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    ${vpn_parcel_id}=    Json Search String   ${transport_wan_vpn_res.json()}    data[0].parcelId
    Set Suite Variable  ${vpn_parcel_id}

    ${trans_wan_vpn_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/wan/vpn/${vpn_parcel_id}/interface/gre
    ${trans_wan_vpn_intf}=    Json Search List    ${trans_wan_vpn_intf_res.json()}    data[].payload
    Set Suite Variable    ${trans_wan_vpn_intf}

    ${trackers_gre_interfaces}=    Json Search List    ${transport_profile_res.json()}    associatedProfileParcels[?parcelType=='wan/vpn'] | [0].subparcels[?parcelType=='wan/vpn/interface/gre']
    Set Suite Variable    ${trackers_gre_interfaces}

    Should Be Equal Value Json List Length     ${trans_wan_vpn_intf}    @     {{ profile.wan_vpn.get('gre_interfaces' , []) | length }}    msg=transport_wan_vpn gre_interfaces length
{% for intf_entry in profile.wan_vpn.get('gre_interfaces', []) %}

    Log   ======GRE Interface {{ intf_entry.name }} =======

    ${r_interface_name}=  Json Search    ${trans_wan_vpn_intf}      [?name=='{{ intf_entry.name }}'] | [0]
    ${trackers_gre_interface}=   Json Search    ${trackers_gre_interfaces}    [?payload.name=='{{ intf_entry.name }}'] | [0]

    Log   ======Tracker Associations=======
    Should Be Equal Value Json String     ${trackers_gre_interface}   subparcels[?parcelType=='tracker'] | [0].payload.name        {{ intf_entry.ipv4_tracker | default('not_defined') }}    msg=transport_wan_vpn gre_interfaces tracker name

    Should Be Equal Value Json String            ${r_interface_name}    name         {{ intf_entry.name | default('not_defined') }}      msg=transport_wan_vpn wan_vpn interface name
    Should Be Equal Value Json Special_String    ${r_interface_name}    description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=transport_wan_vpn wan_vpn description
    
    # basic
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.clearDontFragment       {{ intf_entry.clear_dont_fragment | default('not_defined') }}    {{ intf_entry.clear_dont_fragment_variable | default('not_defined') }}   msg=transport_wan_vpn interface clear_dont_fragment
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.dpdInterval   {{ intf_entry.dpd_interval | default('not_defined') }}    {{ intf_entry.dpd_interval_variable | default('not_defined') }}   msg=transport_wan_vpn interface dpd_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.dpdRetries   {{ intf_entry.dpd_retries | default('not_defined') }}    {{ intf_entry.dpd_retries_variable | default('not_defined') }}   msg=transport_wan_vpn interface dpd_retries
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeCiphersuite   {{ intf_entry.ike_cipher_suite | default('not_defined') }}    {{ intf_entry.ike_cipher_suite_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_cipher_suite
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeGroup   {{ intf_entry.ike_diffie_hellman_group | default('not_defined') }}    {{ intf_entry.ike_diffie_hellman_group_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_diffie_hellman_group
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeLocalId   {{ intf_entry.ike_id_for_local_endpoint | default('not_defined') }}    {{ intf_entry.ike_id_for_local_endpoint_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_id_for_local_endpoint
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeRemoteId   {{ intf_entry.ike_id_for_remote_endpoint | default('not_defined') }}    {{ intf_entry.ike_id_for_remote_endpoint_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_id_for_remote_endpoint
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeMode   {{ intf_entry.ike_integrity_protocol | default('not_defined') }}    {{ intf_entry.ike_integrity_protocol_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_integrity_protocol
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeRekeyInterval   {{ intf_entry.ike_rekey_interval | default('not_defined') }}    {{ intf_entry.ike_rekey_interval_variable | default('not_defined') }}   msg=transport_wan_vpn interface ike_rekey_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ikeVersion   {{ intf_entry.ike_version | default('not_defined') }}    not_defined   msg=transport_wan_vpn interface ike_version
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.description      {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface interface_description
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ifName      {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface interface_name
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.address.address       {{ intf_entry.ipv4_address | default('not_defined') }}    {{ intf_entry.ipv4_address_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.mtu           {{ intf_entry.ipv4_mtu | default('not_defined') }}    {{ intf_entry.ipv4_mtu_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface ipv4_mtu
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.address.mask   {{ intf_entry.ipv4_subnet_mask | default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface ipv4_subnet_mask
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tcpMssAdjust           {{ intf_entry.ipv4_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv4_tcp_mss_variable | default('not_defined') }}   msg=transport_wan_vpn wan_vpn interface ipv4_tcp_mss
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipv6Address   {{ intf_entry.ipv6_address | default('not_defined') }}    {{ intf_entry.ipv6_address_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.mtuV6   {{ intf_entry.ipv6_mtu | default('not_defined') }}    {{ intf_entry.ipv6_mtu_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipv6_mtu
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tcpMssAdjustV6   {{ intf_entry.ipv6_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv6_tcp_mss_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipv6_tcp_mss
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.multiplexing   {{ intf_entry.multiplexing | default('not_defined') }}    {{ intf_entry.multiplexing_variable | default('not_defined') }}   msg=transport_wan_vpn interface multiplexing
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecCiphersuite   {{ intf_entry.ipsec_cipher_suite | default('not_defined') }}    {{ intf_entry.ipsec_cipher_suite_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipsec_cipher_suite
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecRekeyInterval   {{ intf_entry.ipsec_rekey_interval | default('not_defined') }}    {{ intf_entry.ipsec_rekey_interval_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipsec_rekey_interval
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.ipsecReplayWindow   {{ intf_entry.ipsec_replay_window | default('not_defined') }}    {{ intf_entry.ipsec_replay_window_variable | default('not_defined') }}   msg=transport_wan_vpn interface ipsec_replay_window
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.perfectForwardSecrecy   {{ intf_entry.perfect_forward_secrecy | default('not_defined') }}    {{ intf_entry.perfect_forward_secrecy_variable | default('not_defined') }}   msg=transport_wan_vpn interface perfect_forward_secrecy
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.preSharedSecret   {{ intf_entry.preshared_key_for_ike | default('not_defined') }}    {{ intf_entry.preshared_key_for_ike_variable | default('not_defined') }}   msg=transport_wan_vpn interface preshared_key_for_ike
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.shutdown   {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}   msg=transport_wan_vpn interface shutdown 
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelDestination           {{ intf_entry.tunnel_destination_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv4_address_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_destination_ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelDestinationV6   {{ intf_entry.tunnel_destination_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv6_address_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_destination_ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelMode   {{ intf_entry.tunnel_mode | default('not_defined') }}        not_defined     msg=transport_wan_vpn interface tunnel_mode
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIp.tunnelRouteVia           {{ intf_entry.tunnel_route_via_loopback | default('not_defined') }}    {{ intf_entry.tunnel_route_via_loopback_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_route_via_loopback
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceNotLoopback.tunnelSourceInterface           {{ intf_entry.tunnel_source_interface | default('not_defined') }}    {{ intf_entry.tunnel_source_interface_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_source_interface
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceLoopback.tunnelSourceInterface           {{ intf_entry.tunnel_source_interface_loopback | default('not_defined') }}    {{ intf_entry.tunnel_source_interface_loopback_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_source_interface_loopback
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIp.tunnelSource           {{ intf_entry.tunnel_source_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv4_address_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_source_ipv4_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelSourceType.sourceIpv6.tunnelSourceV6   {{ intf_entry.tunnel_source_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv6_address_variable | default('not_defined') }}   msg=transport_wan_vpn interface tunnel_source_ipv6_address
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.basic.tunnelProtection   {{ intf_entry.tunnel_protection | default('not_defined') }}      not_defined       msg=transport_wan_vpn interface tunnel_protection
    
    # advanced
    Should Be Equal Value Json Yaml     ${r_interface_name}    data.advanced.application   {{ intf_entry.application_tunnel_type | default('not_defined') }}    {{ intf_entry.application_tunnel_type_variable | default('not_defined') }}   msg=transport_wan_vpn interface application_tunnel_type

{% endfor %}    


{% endif %}
    
{% endfor %}

{% endif %}

{% endif %}
