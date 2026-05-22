*** Settings ***
Documentation   Verify Service Feature Profile Configuration LAN VPN IPSec Interfaces
Suite Setup     Login SDWAN Manager
Name            Service Profiles LAN VPN IPSec Interfaces
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    lan_vpns    ipsec_interfaces
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.service_profiles is defined %}
{% set profile_lan_vpn_ipsec = [] %}
{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
 {% if profile.lan_vpns is defined %}
  {% for lan_vpn in profile.lan_vpns | default([]) %}
   {% if lan_vpn.ipsec_interfaces is defined and lan_vpn.get('ipsec_interfaces', []) | length > 0 %}
	{% set _ = profile_lan_vpn_ipsec.append(profile.name) %}
   {% endif %}
  {% endfor %}
 {% endif %}
{% endfor %}

{% if profile_lan_vpn_ipsec != [] %}

*** Test Cases ***
Get Service Profiles
	${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
	Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.lan_vpns is defined %}

	${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
	Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
	${profile_id}=    Json Search String    ${profile}    profileId
	${service_lan_vpn_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn
	${service_lan_vpn}=    Json Search List    ${service_lan_vpn_res.json()}    data
	Set Suite Variable    ${service_lan_vpn}
	Set Suite Variable    ${profile_id}
	Run Keyword If    ${service_lan_vpn} == []    Fail    Feature lan vpn expected to be configured within the service profile '{{ profile.name }}' on the Manager

{% for lan_vpn in profile.lan_vpns | default([]) %}
{% if lan_vpn.ipsec_interfaces is defined and lan_vpn.get('ipsec_interfaces', []) | length > 0 %}

Verify Feature Profiles Service Profiles {{ profile.name }} LAN VPN {{ lan_vpn.name }} IPSec Interfaces

	${lan_vpn_profile}=    Json Search    ${service_lan_vpn}    [?payload.name=='{{ lan_vpn.name }}'] | [0]
	Run Keyword If    $lan_vpn_profile is None    Fail    Feature lan vpn '{{ lan_vpn.name }}' expected to be configured within the service profile '{{ profile.name }}' on the Manager
	${lan_vpn_profile_id}=    Json Search String    ${lan_vpn_profile}    parcelId

	${service_lan_vpn_ipsec_intf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/lan/vpn/${lan_vpn_profile_id}/interface/ipsec
	${service_lan_vpn_ipsec_intf}=    Json Search List    ${service_lan_vpn_ipsec_intf_res.json()}    data[].payload

	Should Be Equal Value Json List Length   ${service_lan_vpn_ipsec_intf}   @   {{ lan_vpn.get('ipsec_interfaces', []) | length }}    msg=service_lan_vpn ipsec_interfaces length

{% for intf_entry in lan_vpn.ipsec_interfaces | default([]) %}

	Log   ======IPSec Interface {{ intf_entry.name }} =======

	${r_interface_name}=  Json Search    ${service_lan_vpn_ipsec_intf}      [?name=='{{ intf_entry.name }}'] | [0]

	Log   ======Basic Configuration========

	Should Be Equal Value Json String    ${r_interface_name}    name    {{ intf_entry.name | default('not_defined') }}    msg=service_lan_vpn ipsec interface name
	Should Be Equal Value Json Special_String    ${r_interface_name}   description   {{ intf_entry.description | default('not_defined') | normalize_special_string }}   msg=service_lan_vpn ipsec interface description

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ifName    {{ intf_entry.interface_name | default('not_defined') }}    {{ intf_entry.interface_name_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface interface_name
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.description    {{ intf_entry.interface_description | default('not_defined') }}    {{ intf_entry.interface_description_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface interface_description
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.shutdown    {{ intf_entry.shutdown | default('not_defined') }}    {{ intf_entry.shutdown_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface shutdown
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.application    {{ intf_entry.application_tunnel_type | default(defaults.sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_interfaces.application_tunnel_type) }}    {{ intf_entry.application_tunnel_type_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface application_tunnel_type
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.clearDontFragment    {{ intf_entry.clear_dont_fragment | default('not_defined') }}    {{ intf_entry.clear_dont_fragment_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface clear_dont_fragment
	Should Be Equal Value Json String    ${r_interface_name}    data.tunnelMode.value    {{ intf_entry.tunnel_mode | default('ipv4') }}    msg=service_lan_vpn ipsec interface tunnel_mode

	Log   ======Tunnel Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelSourceInterface    {{ intf_entry.tunnel_source_interface | default('not_defined') }}    {{ intf_entry.tunnel_source_interface_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_source_interface
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelSource.address    {{ intf_entry.tunnel_source_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv4_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_source_ipv4_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelSourceV6    {{ intf_entry.tunnel_source_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_source_ipv6_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_source_ipv6_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelDestination.address    {{ intf_entry.tunnel_destination_ipv4_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv4_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_destination_ipv4_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelDestinationV6    {{ intf_entry.tunnel_destination_ipv6_address | default('not_defined') }}    {{ intf_entry.tunnel_destination_ipv6_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_destination_ipv6_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tunnelRouteVia    {{ intf_entry.tunnel_route_via | default('not_defined') }}    {{ intf_entry.tunnel_route_via_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tunnel_route_via

	Log   ======IPv4 Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.address.address    {{ intf_entry.ipv4_address | default('not_defined') }}    {{ intf_entry.ipv4_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv4_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.address.mask    {{ intf_entry.ipv4_subnet_mask | default('not_defined') }}    {{ intf_entry.ipv4_subnet_mask_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv4_subnet_mask
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.mtu    {{ intf_entry.ipv4_mtu | default('not_defined') }}    {{ intf_entry.ipv4_mtu_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv4_mtu
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tcpMssAdjust    {{ intf_entry.ipv4_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv4_tcp_mss_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv4_tcp_mss

	Log   ======IPv6 Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ipv6Address    {{ intf_entry.ipv6_address | default('not_defined') }}    {{ intf_entry.ipv6_address_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv6_address
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.mtuV6    {{ intf_entry.ipv6_mtu | default('not_defined') }}    {{ intf_entry.ipv6_mtu_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv6_mtu
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tcpMssAdjustV6    {{ intf_entry.ipv6_tcp_mss | default('not_defined') }}    {{ intf_entry.ipv6_tcp_mss_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipv6_tcp_mss

	Log   ======IKE Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeVersion    {{ intf_entry.ike_version | default('not_defined') }}    {{ intf_entry.ike_version_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_version
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeCiphersuite    {{ intf_entry.ike_cipher_suite | default('not_defined') }}    {{ intf_entry.ike_cipher_suite_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_cipher_suite
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeGroup    {{ intf_entry.ike_diffie_hellman_group | default('not_defined') }}    {{ intf_entry.ike_diffie_hellman_group_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_diffie_hellman_group
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeMode    {{ intf_entry.ike_integrity_protocol | default('not_defined') }}    {{ intf_entry.ike_integrity_protocol_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_integrity_protocol
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeRekeyInterval    {{ intf_entry.ike_rekey_interval | default('not_defined') }}    {{ intf_entry.ike_rekey_interval_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_rekey_interval
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.preSharedSecret    {{ intf_entry.ike_preshared_key | default('not_defined') }}    {{ intf_entry.ike_preshared_key_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_preshared_key
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeLocalId    {{ intf_entry.ike_local_endpoint_id | default('not_defined') }}    {{ intf_entry.ike_local_endpoint_id_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_local_endpoint_id
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ikeRemoteId    {{ intf_entry.ike_remote_endpoint_id | default('not_defined') }}    {{ intf_entry.ike_remote_endpoint_id_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ike_remote_endpoint_id

	Log   ======IPSec Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ipsecCiphersuite    {{ intf_entry.ipsec_cipher_suite | default('not_defined') }}    {{ intf_entry.ipsec_cipher_suite_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipsec_cipher_suite
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.perfectForwardSecrecy    {{ intf_entry.ipsec_perfect_forward_secrecy | default('not_defined') }}    {{ intf_entry.ipsec_perfect_forward_secrecy_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipsec_perfect_forward_secrecy
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ipsecRekeyInterval    {{ intf_entry.ipsec_rekey_interval | default('not_defined') }}    {{ intf_entry.ipsec_rekey_interval_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipsec_rekey_interval
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.ipsecReplayWindow    {{ intf_entry.ipsec_replay_window | default('not_defined') }}    {{ intf_entry.ipsec_replay_window_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface ipsec_replay_window

	Log   ======DPD Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.dpdInterval    {{ intf_entry.dpd_interval | default('not_defined') }}    {{ intf_entry.dpd_interval_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface dpd_interval
	Should Be Equal Value Json Yaml    ${r_interface_name}    data.dpdRetries    {{ intf_entry.dpd_retries | default('not_defined') }}    {{ intf_entry.dpd_retries_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface dpd_retries

	Log   ======Tracker Configuration========

	Should Be Equal Value Json Yaml    ${r_interface_name}    data.tracker    {{ intf_entry.tracker_id | default('not_defined') }}    {{ intf_entry.tracker_id_variable | default('not_defined') }}    msg=service_lan_vpn ipsec interface tracker_id

{% endfor %}

{% endif %}
{% endfor %}

{% endif %}
{% endfor %}

{% endif %}
{% endif %}
