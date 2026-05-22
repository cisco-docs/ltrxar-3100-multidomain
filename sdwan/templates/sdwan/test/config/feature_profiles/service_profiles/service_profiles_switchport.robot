*** Settings ***
Documentation   Verify Service Feature Profile Configuration Switchport Features
Name            Service Profiles Switchport Features
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    switchport
Resource        ../../../sdwan_common.resource


{% set profile_switchport_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', {}) %}
 {% if profile.switchport_features is defined %}
  {% set _ = profile_switchport_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_switchport_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.switchport_features is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} Switchport Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${service_switchport_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/switchport
    Set Suite Variable    ${service_switchport_res}
    ${service_switchport}=    Json Search List    ${service_switchport_res.json()}    data[].payload
    Run Keyword If    ${service_switchport} == []    Fail    Switchport feature(s) expected to be configured within the service profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${service_switchport}

{% for switchport in profile.switchport_features | default([]) %}
    Log    === Switchport: {{ switchport.name }} ===

    # for each switchport find the corresponding one in the json and check parameters:
    ${service_switchport_feature}=    Json Search    ${service_switchport}    [?name=='{{ switchport.name }}'] | [0]
    Run Keyword If    $service_switchport_feature is None    Fail    Switchport feature '{{ switchport.name }}' not found in profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${service_switchport_feature}    name    {{ switchport.name }}    msg=name
    Should Be Equal Value Json Special_String    ${service_switchport_feature}    description    {{ switchport.description | default('not_defined') | normalize_special_string }}    msg=description
    # Basic switchport parameters
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.ageTime    {{ switchport.age_out_time | default('not_defined') }}    {{ switchport.age_out_time_variable | default('not_defined') }}    msg=switchport.age_out_time

    Log    =====Interfaces=====
    Should Be Equal Value Json List Length    ${service_switchport_feature}    data.interface    {{ switchport.get('interfaces', []) | length }}    msg=switchport.interfaces length
{% if switchport.interfaces is defined and switchport.get('interfaces', [])|length > 0 %}
{% for interface in switchport.interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].ifName    {{ interface.name | default('not_defined') }}    {{ interface.name_variable | default('not_defined') }}    msg=switchport.interfaces.name
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].mode    {{ interface.mode | default('not_defined') }}    not_defined    msg=switchport.interfaces.mode
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].paeEnable    {{ interface.pae_enable | default('not_defined') }}    {{ interface.pae_enable_variable | default('not_defined') }}    msg=switchport.interfaces.pae_enable
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].portControl    {{ interface.port_control | default('not_defined') }}    {{ interface.port_control_variable | default('not_defined') }}    msg=switchport.interfaces.port_control
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].reauthentication    {{ interface.reauthentication | default('not_defined') }}    {{ interface.reauthentication_variable | default('not_defined') }}    msg=switchport.interfaces.reauthentication
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].restrictedVlan    {{ interface.restricted_vlan | default('not_defined') }}    {{ interface.restricted_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.restricted_vlan
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].shutdown    {{ interface.shutdown | default('not_defined') }}    {{ interface.shutdown_variable | default('not_defined') }}    msg=switchport.interfaces.shutdown
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].speed    {{ interface.speed | default('not_defined') }}    {{ interface.speed_variable | default('not_defined') }}    msg=switchport.interfaces.speed
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].duplex    {{ interface.duplex | default('not_defined') }}    {{ interface.duplex_variable | default('not_defined') }}    msg=switchport.interfaces.duplex

    # Access mode parameters
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].switchportAccessVlan    {{ interface.access_vlan | default('not_defined') }}    {{ interface.access_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.access_vlan

    # Trunk mode parameters
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].switchportTrunkNativeVlan    {{ interface.trunk_native_vlan | default('not_defined') }}    {{ interface.trunk_native_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.trunk_native_vlan
    ${trunk_allowed_vlans_string}=    Set Variable If    {{ interface.get('trunk_allowed_vlans', []) | length == 0 }}    not_defined    {{ interface.get('trunk_allowed_vlans', []) | join(',') }}
    Should Be Equal Value Json Yaml    ${service_switchport_feature}     data.interface[{{ loop.index0 }}].switchportTrunkAllowedVlans    ${trunk_allowed_vlans_string}    {{ interface.trunk_allowed_vlans_variable | default('not_defined') }}    msg=switchport.interfaces.trunk_allowed_vlans

    # 802.1X Authentication parameters
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].enableDot1x    {{ interface.enable_dot1x | default('not_defined') }}    not_defined    msg=switchport.interfaces.enable_dot1x
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].hostMode    {{ interface.host_mode | default('not_defined') }}    {{ interface.host_mode_variable | default('not_defined') }}    msg=switchport.interfaces.host_mode
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].controlDirection    {{ interface.control_direction | default('not_defined') }}    {{ interface.control_direction_variable | default('not_defined') }}    msg=switchport.interfaces.control_direction
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].macAuthenticationBypass    {{ interface.mac_authentication_bypass | default('not_defined') }}    {{ interface.mac_authentication_bypass_variable | default('not_defined') }}    msg=switchport.interfaces.mac_authentication_bypass
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].enablePeriodicReauth    {{ interface.enable_periodic_reauth | default('not_defined') }}    {{ interface.enable_periodic_reauth_variable | default('not_defined') }}    msg=switchport.interfaces.enable_periodic_reauth
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].inactivity    {{ interface.inactivity | default('not_defined') }}    {{ interface.inactivity_variable | default('not_defined') }}    msg=switchport.interfaces.inactivity
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].guestVlan    {{ interface.guest_vlan | default('not_defined') }}    {{ interface.guest_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.guest_vlan
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].criticalVlan    {{ interface.critical_vlan | default('not_defined') }}    {{ interface.critical_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.critical_vlan

    # Voice VLAN parameters
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].enableVoice    {{ interface.enable_voice | default('not_defined') }}    {{ interface.enable_voice_variable | default('not_defined') }}    msg=switchport.interfaces.enable_voice
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.interface[{{ loop.index0 }}].voiceVlan    {{ interface.voice_vlan | default('not_defined') }}    {{ interface.voice_vlan_variable | default('not_defined') }}    msg=switchport.interfaces.voice_vlan

{% endfor %}
{% endif %}

    Log    =====Static MAC Addresses=====
    Should Be Equal Value Json List Length    ${service_switchport_feature}    data.staticMacAddress    {{ switchport.get('static_mac_addresses', []) | length }}    msg=switchport.static_mac_addresses length
{% if switchport.static_mac_addresses is defined and switchport.get('static_mac_addresses', [])|length > 0 %}
{% for mac_address in switchport.static_mac_addresses | default([]) %}
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.staticMacAddress[{{ loop.index0 }}].ifName    {{ mac_address.interface_name | default('not_defined') }}    {{ mac_address.interface_name_variable | default('not_defined') }}    msg=switchport.static_mac_addresses.interface_name
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.staticMacAddress[{{ loop.index0 }}].macaddr    {{ mac_address.mac_address | default('not_defined') }}    {{ mac_address.mac_address_variable | default('not_defined') }}    msg=switchport.static_mac_addresses.mac_address
    Should Be Equal Value Json Yaml    ${service_switchport_feature}    data.staticMacAddress[{{ loop.index0 }}].vlan    {{ mac_address.vlan_id | default('not_defined') }}    {{ mac_address.vlan_id_variable | default('not_defined') }}    msg=switchport.static_mac_addresses.vlan_id
{% endfor %}
{% endif %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}
