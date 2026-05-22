*** Settings ***
Documentation   Verify Service Feature Profile Configuration DHCP Server
Name            Service Profiles DHCP Server
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    dhcp_servers
Resource        ../../../sdwan_common.resource


{% set profile_dhcp_server_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', []) %}
 {% if profile.dhcp_servers is defined %}
  {% set _ = profile_dhcp_server_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_dhcp_server_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}


{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', []) %}
{% if profile.dhcp_servers is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} DHCP Server Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId

    Set Suite Variable    ${profile_id}
    ${service_dhcp_server_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/dhcp-server
    Set Suite Variable    ${service_dhcp_server_res}
    ${service_dhcp_server}=    Json Search List    ${service_dhcp_server_res.json()}    data[].payload
    Run Keyword If    $service_dhcp_server == []    Fail    DHCP server feature(s) expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_dhcp_server}

{% for dhcp_server in profile.dhcp_servers | default([]) %}
    Log     === DHCP Server: {{ dhcp_server.name }} ===

    # for each dhcp server find the corresponding one in the json and check parameters:
    ${dhcp_server_feature}=    Json Search    ${service_dhcp_server}    [?name=='{{ dhcp_server.name }}'] | [0]
    Run Keyword If    $dhcp_server_feature is None    Fail    DHCP server feature '{{ dhcp_server.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String     ${dhcp_server_feature}             name            {{ dhcp_server.name }}    msg=name
    Should Be Equal Value Json Special_String     ${dhcp_server_feature}     description    {{ dhcp_server.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.addressPool.networkAddress    {{ dhcp_server.pool_network_address | default('not_defined') }}    {{ dhcp_server.pool_network_address_variable | default('not_defined') }}    msg=pool_network_address
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.addressPool.subnetMask        {{ dhcp_server.pool_subnet_mask | default('not_defined') }}    {{ dhcp_server.pool_subnet_mask_variable | default('not_defined') }}    msg=pool_subnet_mask
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.defaultGateway                {{ dhcp_server.default_gateway | default('not_defined') }}    {{ dhcp_server.default_gateway_variable | default('not_defined') }}    msg=default_gateway

    ${dns_server_list}=    Create List    {{ dhcp_server.get('dns_servers', []) | join('   ') }}
    ${dns_server_list}=    Set Variable If    ${dns_server_list} == []    not_defined    ${dns_server_list}
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.dnsServers          ${dns_server_list}    {{ dhcp_server.dns_servers_variable | default('not_defined') }}    msg=dns_servers

    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.domainName                {{ dhcp_server.domain_name | default('not_defined') }}    {{ dhcp_server.domain_name_variable | default('not_defined') }}    msg=domain_name

    ${exclude_address_list}=    Create List    {{ dhcp_server.get('exclude_addresses', []) | join('   ') }}
    ${exclude_address_list}=    Set Variable If    ${exclude_address_list} == []    not_defined    ${exclude_address_list}
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.exclude          ${exclude_address_list}    {{ dhcp_server.exclude_addresses_variable | default('not_defined') }}    msg=exclude_addresses

    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.interfaceMtu                {{ dhcp_server.interface_mtu | default('not_defined') }}    {{ dhcp_server.interface_mtu_variable | default('not_defined') }}    msg=interface_mtu
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.leaseTime                {{ dhcp_server.lease_time | default('not_defined') }}    {{ dhcp_server.lease_time_variable | default('not_defined') }}    msg=lease_time

    Should Be Equal Value Json List Length    ${dhcp_server_feature}    data.optionCode    {{ dhcp_server.get('options', []) | length }}    msg=options length
{% if dhcp_server.get('options', []) | length > 0 %}
    Log     === Options List ===
{% for option in dhcp_server.options | default([]) %}

    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.optionCode[{{ loop.index0 }}].code      {{ option.code | default('not_defined') }}      {{ option.code_variable | default('not_defined') }}     msg=code
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.optionCode[{{ loop.index0 }}].ascii     {{ option.ascii | default('not_defined') }}     {{ option.ascii_variable | default('not_defined') }}    msg=ascii
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.optionCode[{{ loop.index0 }}].hex       {{ option.hex | default('not_defined') }}       {{ option.hex_variable | default('not_defined') }}      msg=hex

    ${ip_address_list}=    Create List    {{ option.get('ip_addresses', []) | join('   ') }}
    ${ip_address_list}=    Set Variable If    ${ip_address_list} == []    not_defined    ${ip_address_list}
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.optionCode[{{ loop.index0 }}].ip          ${ip_address_list}    {{ option.ip_addresses_variable | default('not_defined') }}    msg=ip_addresses

{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${dhcp_server_feature}    data.staticLease    {{ dhcp_server.get('static_leases', []) | length }}    msg=static_leases length
{% if dhcp_server.get('static_leases', []) | length > 0 %}
    Log     === Static Leases List ===
{% for static_lease in dhcp_server.static_leases | default([]) %}

    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.staticLease[{{ loop.index0 }}].ip              {{ static_lease.ip_address | default('not_defined') }}      {{ static_lease.ip_address_variable | default('not_defined') }}     msg=ip_address
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.staticLease[{{ loop.index0 }}].macAddress      {{ static_lease.mac_address | default('not_defined') }}      {{ static_lease.mac_address_variable | default('not_defined') }}     msg=mac_address

{% endfor %}
{% endif %}

    ${tftp_server_list}=    Create List    {{ dhcp_server.get('tftp_servers', []) | join('   ') }}
    ${tftp_server_list}=    Set Variable If    ${tftp_server_list} == []    not_defined    ${tftp_server_list}
    Should Be Equal Value Json Yaml    ${dhcp_server_feature}    data.tftpServers          ${tftp_server_list}    {{ dhcp_server.tftp_servers_variable | default('not_defined') }}    msg=tftp_servers


{% endfor %}

{% endif %}

{% endfor %}

{% endif %}