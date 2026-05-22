*** Settings ***
Documentation   Verify Other Feature Profile Configuration UCSE
Name            Other Profiles UCSE
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    other_profiles    ucse
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.other_profiles is defined %}
{% set profile_ucse_list = [] %}
{% for profile in sdwan.feature_profiles.other_profiles %}
 {% if profile.ucse is defined %}
  {% set _ = profile_ucse_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ucse_list != [] %}

*** Test Cases ***
Get Other Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/other
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.other_profiles | default([]) %}

{% if profile.ucse is defined %}

Verify Feature Profiles Other Profiles {{ profile.name }} UCSE Feature {{ profile.ucse.name | default(defaults.sdwan.feature_profiles.other_profiles.ucse.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${other_ucse_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/other/${profile_id}/ucse
    ${other_ucse}=    Json Search    ${other_ucse_res.json()}    data[?payload.name=='{{ profile.ucse.name | default(defaults.sdwan.feature_profiles.other_profiles.ucse.name) }}'] | [0].payload
    Run Keyword If    $other_ucse is None    Fail    Feature '{{ profile.ucse.name | default(defaults.sdwan.feature_profiles.other_profiles.ucse.name) }}' expected to be configured within the other profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${other_ucse}

    Should Be Equal Value Json String    ${other_ucse}    name    {{ profile.ucse.name | default(defaults.sdwan.feature_profiles.other_profiles.ucse.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${other_ucse}    description    {{ profile.ucse.description | default('not_defined') | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${other_ucse}    data.bay.value    {{ profile.ucse.bay | default('not_defined') }}    msg=bay
    Should Be Equal Value Json String    ${other_ucse}    data.slot.value    {{ profile.ucse.slot | default('not_defined') }}    msg=slot
    Should Be Equal Value Json String    ${other_ucse}    data.imc."access-port".dedicated.value    {{ profile.ucse.cimc_access_port_dedicated | default('not_defined') }}    msg=access_port_dedicated
    Should Be Equal Value Json String    ${other_ucse}    data.imc."access-port".sharedLom.lomType.value    {{ profile.ucse.cimc_access_port_shared_type | default('not_defined') }}    msg=cimc_access_port_shared_type
    Should Be Equal Value Json String    ${other_ucse}    data.imc."access-port".sharedLom.failOverType.value   {{ profile.ucse.cimc_access_port_shared_failover_type | default('not_defined') }}    msg=cimc_access_port_shared_failover_type
    Should Be Equal Value Json Yaml    ${other_ucse}    data.imc.ip.address   {{ profile.ucse.cimc_ipv4_address | default('not_defined') }}    {{ profile.ucse.cimc_ipv4_address_variable | default('not_defined') }}    msg=cimc_ipv4_address
    Should Be Equal Value Json Yaml    ${other_ucse}    data.imc.ip.defaultGateway   {{ profile.ucse.cimc_default_gateway | default('not_defined') }}    {{ profile.ucse.cimc_default_gateway_variable | default('not_defined') }}    msg=cimc_default_gateway
    Should Be Equal Value Json Yaml    ${other_ucse}    data.imc.vlan.vlanId    {{ profile.ucse.cimc_vlan_id | default('not_defined') }}    {{ profile.ucse.cimc_vlan_id_variable | default('not_defined') }}    msg=cimc_vlan_id
    Should Be Equal Value Json Yaml    ${other_ucse}    data.imc.vlan.priority   {{ profile.ucse.cimc_assign_priority | default('not_defined') }}    {{ profile.ucse.cimc_assign_priority_variable | default('not_defined') }}    msg=cimc_assign_priority

    Should Be Equal Value Json List Length    ${other_ucse}   data.interface    {{ profile.ucse.get('interfaces', []) | length }}    msg=interfaces_count

{% if profile.ucse.interfaces is defined and profile.ucse.get('interfaces', [])|length > 0 %}
    Log  === UCSE Interfaces ===
{% for interfaces in profile.ucse.interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${other_ucse}    data.interface[{{ loop.index0 }}].ifName    {{ interfaces.interface_name | default('not_defined') }}    {{ interfaces.interface_name_variable | default('not_defined') }}    msg=ucse_interface_name
    Should Be Equal Value Json Yaml    ${other_ucse}    data.interface[{{ loop.index0 }}].ucseInterfaceVpn    {{ interfaces.vpn_id | default('not_defined') }}    {{ interfaces.vpn_id_variable | default('not_defined') }}    msg=ucse_vpn_id
    Should Be Equal Value Json Yaml    ${other_ucse}    data.interface[{{ loop.index0 }}].address    {{ interfaces.ipv4_address | default('not_defined') }}    {{ interfaces.ipv4_address_variable | default('not_defined') }}    msg=ucse_ipv4_address
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
{% endif %}

{% endif %}