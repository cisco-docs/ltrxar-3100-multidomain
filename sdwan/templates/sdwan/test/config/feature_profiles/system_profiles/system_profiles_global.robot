*** Settings ***
Documentation   Verify System Feature Profile Configuration Global
Name            System Profiles Global
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    global
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_global_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.global is defined %}
  {% set _ = profile_global_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_global_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.global is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} Global Feature {{ profile.global.name | default(defaults.sdwan.feature_profiles.system_profiles.global.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_global_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/global
    ${system_global}=    Json Search    ${system_global_res.json()}    data[0].payload
    Run Keyword If    $system_global is None    Fail    Feature '{{ profile.global.name | default(defaults.sdwan.feature_profiles.system_profiles.global.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_global}

    Should Be Equal Value Json String    ${system_global}    name    {{ profile.global.name | default(defaults.sdwan.feature_profiles.system_profiles.global.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_global}    description    {{ profile.global.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpArpProxy    {{ profile.global.arp_proxy| default('not_defined') }}    {{ profile.global.arp_proxy_variable| default('not_defined') }}    msg=global arp_proxy
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.bgpCommunityNewFormat    {{ profile.global.bgp_community_new_format| default('not_defined') }}    {{ profile.global.bgp_community_new_format_variable| default('not_defined') }}    msg=global bgp_community_new_format
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpCdp    {{ profile.global.cdp| default('not_defined') }}    {{ profile.global.cdp_variable| default('not_defined') }}    msg=global cdp
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsConsoleLogging    {{ profile.global.console_logging| default('not_defined') }}    {{ profile.global.console_logging_variable| default('not_defined') }}    msg=global console_logging
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpDomainLookup    {{ profile.global.domain_lookup| default('not_defined') }}    {{ profile.global.domain_lookup_variable| default('not_defined') }}    msg=global domain_lookup
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.etherchannelFlowLoadBalance    {{ profile.global.etherchannel_flow_load_balance| default('not_defined') }}    {{ profile.global.etherchannel_flow_load_balance_variable| default('not_defined') }}    msg=global etherchannel_flow_load_balance
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.etherchannelVlanLoadBalance    {{ profile.global.etherchannel_vlan_load_balance| default('not_defined') }}    {{ profile.global.etherchannel_vlan_load_balance_variable| default('not_defined') }}    msg=global etherchannel_vlan_load_balance
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpFtpPassive    {{ profile.global.ftp_passive| default('not_defined') }}    {{ profile.global.ftp_passive_variable| default('not_defined') }}    msg=global ftp_passive
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalSettingsHttpAuthentication    {{ profile.global.http_authentication| default('not_defined') }}    {{ profile.global.http_authentication_variable| default('not_defined') }}    msg=global http_authentication
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpHttpServer    {{ profile.global.http_server| default('not_defined') }}    {{ profile.global.http_server_variable| default('not_defined') }}    msg=global http_server
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpHttpsServer    {{ profile.global.https_server| default('not_defined') }}    {{ profile.global.https_server_variable| default('not_defined') }}    msg=global https_server
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsIgnoreBootp    {{ profile.global.ignore_bootp| default('not_defined') }}    {{ profile.global.ignore_bootpp_variable| default('not_defined') }}    msg=global ignore_bootp
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsIPSourceRoute    {{ profile.global.ip_source_routing| default('not_defined') }}    {{ profile.global.ip_source_routing_variable| default('not_defined') }}    msg=global ip_source_routing
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.lacpSystemPriority    {{ profile.global.lacp_system_priority| default('not_defined') }}    {{ profile.global.lacp_system_priority_variable| default('not_defined') }}    msg=global lacp_system_priority
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpLldp    {{ profile.global.lldp| default('not_defined') }}    {{ profile.global.lldp_variable| default('not_defined') }}    msg=global lldp
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalSettingsNat64UdpTimeout    {{ profile.global.nat64_udp_timeout| default('not_defined') }}    {{ profile.global.nat64_udp_timeout_variable| default('not_defined') }}    msg=global nat64_udp_timeout
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalSettingsNat64TcpTimeout    {{ profile.global.nat64_tcp_timeout| default('not_defined') }}    {{ profile.global.nat64_tcp_timeout_variable| default('not_defined') }}    msg=global nat64_tcp_timeout
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpRcmd    {{ profile.global.rsh_rcp| default('not_defined') }}    {{ profile.global.rsh_rcpp_variable| default('not_defined') }}    msg=global rsh_rcp
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsSnmpIfindexPersist    {{ profile.global.snmp_ifindex_persist| default('not_defined') }}    {{ profile.global.snmp_ifindex_persist_variable| default('not_defined') }}    msg=global snmp_ifindex_persist
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpSourceIntrf    {{ profile.global.source_interface| default('not_defined') }}    {{ profile.global.source_interface_variable| default('not_defined') }}    msg=global source_interface
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalSettingsSSHVersion    {{ profile.global.ssh_version| default('not_defined') }}    {{ profile.global.ssh_version_variable| default('not_defined') }}    msg=global ssh_version
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsTcpKeepalivesIn    {{ profile.global.tcp_keepalives_in| default('not_defined') }}    {{ profile.global.tcp_keepalives_in_variable| default('not_defined') }}    msg=global tcp_keepalives_in
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsTcpKeepalivesOut    {{ profile.global.tcp_keepalives_out| default('not_defined') }}    {{ profile.global.tcp_keepalives_out_variable| default('not_defined') }}    msg=global tcp_keepalives_out
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsTcpSmallServers    {{ profile.global.tcp_small_servers| default('not_defined') }}    {{ profile.global.tcp_small_servers_variable| default('not_defined') }}    msg=global tcp_small_servers
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsUdpSmallServers    {{ profile.global.udp_small_servers| default('not_defined') }}    {{ profile.global.udp_small_servers_variable| default('not_defined') }}    msg=global udp_small_servers
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.servicesGlobalServicesIpLineVty    {{ profile.global.telnet_outbound| default('not_defined') }}    {{ profile.global.telnet_outbound_variable| default('not_defined') }}    msg=global telnet_outbound
    Should Be Equal Value Json Yaml    ${system_global}    data.services_global.services_ip.globalOtherSettingsVtyLineLogging    {{ profile.global.vty_logging| default('not_defined') }}    {{ profile.global.vty_logging_variable| default('not_defined') }}    msg=global vty_logging


{% endif %}
{% endfor %}

{% endif %}

{% endif %}