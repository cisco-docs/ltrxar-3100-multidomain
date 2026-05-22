*** Settings ***
Documentation   Verify Switchport Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.switchport_templates is defined %}

*** Test Cases ***
Get Switchport Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='switchport']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.switchport_templates | default([]) %}

Verify Edge Feature Template Switchport Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.switchport_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    # Validate parameters
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "age-time"
    ...    {{ ft_yaml.age_out_time | default("not_defined") }}
    ...    {{ ft_yaml.age_out_time_variable | default("not_defined") }}
    ...    msg=age_out_time

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    slot
    ...    {{ ft_yaml.slot | default("not_defined") }}
    ...    {{ ft_yaml.slot_variable | default("not_defined") }}
    ...    msg=slot

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    subslot
    ...    {{ ft_yaml.sub_slot | default("not_defined") }}
    ...    {{ ft_yaml.sub_slot_variable | default("not_defined") }}
    ...    msg=subslot

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    module
    ...    {{ ft_yaml.module_type | default("not_defined") }}
    ...    {{ ft_yaml.module_type_variable | default("not_defined") }}
    ...    msg=module_type

    Should Be Equal Value Json List Length    ${ft.json()}    interface.vipValue    {{ ft_yaml.interfaces | default([]) | length }}    msg=interfaces length

{% for interface in ft_yaml.interfaces | default([]) %}

    Log    === Interface {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."if-name"
    ...    {{ interface.name | default("not_defined") }}
    ...    {{ interface.name_variable | default("not_defined") }}
    ...    msg=interfaces.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].switchport.mode
    ...    {{ interface.mode | default("not_defined") }}
    ...    {{ interface.mode_variable | default("not_defined") }}
    ...    msg=interfaces.mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].shutdown
    ...    {{ interface.shutdown | default("not_defined") }}
    ...    {{ interface.shutdown_variable | default("not_defined") }}
    ...    msg=interfaces.shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].speed
    ...    {{ interface.speed | default("not_defined") }}
    ...    {{ interface.speed_variable | default("not_defined") }}
    ...    msg=interfaces.speed

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].duplex
    ...    {{ interface.duplex | default("not_defined") }}
    ...    {{ interface.duplex_variable | default("not_defined") }}
    ...    msg=interfaces.duplex

    Should Be Equal Value Json String    ${ft.json()}    interface.vipValue[{{loop.index0}}].vipOptional
    ...    {{ interface.optional | default("not_defined") }}
    ...    msg=interfaces.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].switchport.access.vlan.vlan
    ...    {{ interface.access_vlan | default("not_defined") }}
    ...    {{ interface.access_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.access_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].switchport.trunk.native.vlan
    ...    {{ interface.trunk_native_vlan | default("not_defined") }}
    ...    {{ interface.trunk_native_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.trunk_native_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x."voice-vlan"
    ...    {{ interface.voice_vlan | default("not_defined") }}
    ...    {{ interface.voice_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.voice_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x."dot1x-enable"
    ...    {{ interface.dot1x.enable | default("not_defined") }}
    ...    {{ interface.dot1x.enable_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.enable

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication."control-direction"
    ...    {{ interface.dot1x.control_direction | default("not_defined") }}
    ...    {{ interface.dot1x.control_direction_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.control_direction

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x."port-control"
    ...    {{ interface.dot1x.port_control_mode | default("not_defined") }}
    ...    {{ interface.dot1x.port_control_mode_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.port_control_mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x."pae-enable"
    ...    {{ interface.dot1x.enable_pae | default("not_defined") }}
    ...    {{ interface.dot1x.enable_pae_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.enable_pae

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication."host-mode"
    ...    {{ interface.dot1x.host_mode | default("not_defined") }}
    ...    {{ interface.dot1x.host_mode_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.host_mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication.event."critical-vlan"
    ...    {{ interface.dot1x.critical_vlan | default("not_defined") }}
    ...    {{ interface.dot1x.critical_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.critical_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication.event."guest-vlan"
    ...    {{ interface.dot1x.guest_vlan | default("not_defined") }}
    ...    {{ interface.dot1x.guest_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.guest_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication.event."restricted-vlan"
    ...    {{ interface.dot1x.restricted_vlan | default("not_defined") }}
    ...    {{ interface.dot1x.restricted_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.restricted_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication.event."enable-voice"
    ...    {{ interface.dot1x.enable_criticial_voice_vlan | default("not_defined") }}
    ...    {{ interface.dot1x.enable_criticial_voice_vlan_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.enable_criticial_voice_vlan

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x."mac-authentication-bypass"
    ...    {{ interface.dot1x.mac_authentication_bypass | default("not_defined") }}
    ...    {{ interface.dot1x.mac_authentication_bypass_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.mac_authentication_bypass

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication."enable-periodic-reauth"
    ...    {{ interface.dot1x.enable_periodic_reauth | default("not_defined") }}
    ...    {{ interface.dot1x.enable_periodic_reauth_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.enable_periodic_reauth

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication."periodic-reauthentication".reauthentication
    ...    {{ interface.dot1x.periodic_reauth_interval | default("not_defined") }}
    ...    {{ interface.dot1x.periodic_reauth_interval_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.periodic_reauth_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].dot1x.authentication."periodic-reauthentication".inactivity
    ...    {{ interface.dot1x.periodic_reauth_inactivity_timeout | default("not_defined") }}
    ...    {{ interface.dot1x.periodic_reauth_inactivity_timeout_variable | default("not_defined") }}
    ...    msg=interfaces.dot1x.periodic_reauth_inactivity_timeout

    # Need custom handling as single JSON field is represented by two data model fields (trunk_allowed_vlans and trunk_allowed_vlan_ranges)
    ${allowed_vlans}=    Create List
    {% for allowed_vlan in interface.trunk_allowed_vlans | default([]) %}
    Append To List    ${allowed_vlans}    {{ allowed_vlan }}
    {% endfor %}

    {% for allowed_vlan_range in interface.trunk_allowed_vlans_ranges | default([]) %}
    {% set test_list = [] %}
    {% set _ = test_list.append(allowed_vlan_range.from) %}
    {% set _ = test_list.append(allowed_vlan_range.to) %}
    {% set vlan_range = '-'.join(test_list | map('string')) %}
    Append To List    ${allowed_vlans}    {{ vlan_range }}
    {% endfor %}

    ${allowed_vlans}=    Set Variable If    ${allowed_vlans} == []    not_defined    ${allowed_vlans}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].switchport.trunk.allowed.vlan.vlans
    ...    ${allowed_vlans}
    ...    {{ interface.trunk_allowed_vlans_variable | default("not_defined") }}
    ...    msg=interfaces.trunk_allowed_vlans|trunk_allowed_vlan_ranges
    # End of custom handling

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "static-mac-address".vipValue    {{ ft_yaml.static_mac_addresses | default([]) | length }}    msg=static_mac_addresses length

{% for address in ft_yaml.static_mac_addresses | default([]) %}

    Log    === Static Mac Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-mac-address".vipValue[{{loop.index0}}]."if-name"
    ...    {{ address.interface_name | default("not_defined") }}
    ...    {{ address.interface_name_variable | default("not_defined") }}
    ...    msg=static_mac_addresses.interface_name

    # Need custom handling to convert colon-separated MAC to dot-separated MAC
    ${expected_mac}=    Set Variable    {{ address.mac_address | default("not_defined") }}
    ${expected_mac}=    Run Keyword If    "${expected_mac}" != "not_defined"
    ...    Replace String    ${expected_mac}    :    ${EMPTY}
    ...    ELSE    Set Variable    not_defined
    ${expected_mac}=    Run Keyword If    "${expected_mac}" != "not_defined"
    ...    Evaluate    ".".join(["${expected_mac}"[i:i+4] for i in range(0, 12, 4)]) if "${expected_mac}" != "not_defined" else "not_defined"
    ...    ELSE    Set Variable    not_defined

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-mac-address".vipValue[{{loop.index0}}].macaddr
    ...    ${expected_mac}
    ...    {{ address.mac_address_variable | default("not_defined") }}
    ...    msg=static_mac_addresses.mac_address
    # End of custom handling

    Should Be Equal Value Json String    ${ft.json()}    "static-mac-address".vipValue[{{loop.index0}}].vipOptional
    ...    {{ address.optional | default("not_defined") }}
    ...    msg=static_mac_addresses.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-mac-address".vipValue[{{loop.index0}}].vlan
    ...    {{ address.vlan | default("not_defined") }}
    ...    {{ address.vlan_variable | default("not_defined") }}
    ...    msg=static_mac_addresses.vlan

{% endfor %}

{% endfor %}

{% endif %}
