*** Settings ***
Documentation    Verify Device Template Configuration Apply
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags     sdwan    config    sites
Resource         ../sdwan_common.resource

{% if sdwan.sites is defined %}

*** Test Cases ***
Get Device Template Configuration Apply
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/device 
    Set Suite Variable    ${r}

Get Configuration Group Apply
    ${r_config_groups}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/config-group
    Set Suite Variable    ${r_config_groups}

Get Policy Group Apply
    ${r_policy_groups}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/policy-group
    Set Suite Variable    ${r_policy_groups}

{% for site in sdwan.sites | default([]) %}

{% for router in site.routers | default([]) %}

{% if router.device_template is defined %}

Verify Device Template Configuration Apply {{ router.device_template }} With Chassis Id {{ router.chassis_id }}

    ${dt_id}=    Json Search String    ${r.json()}    data[?templateName=='{{ router.device_template }}'] | [0].templateId
    ${post_headers}=    Set Variable    {"templateId":"${dt_id}","deviceIds":["{{ router.chassis_id }}"],"isEdited":false,"isMasterEdited":false}
    ${response}=    Wait Until Keyword Succeeds    6x    10s    POST On Session    sdwan_manager    /dataservice/template/device/config/input    data=${post_headers}

    Should Be Equal Value Json String    ${r.json()}    data[?templateName=='{{ router.device_template }}'] | [0].deviceType    vedge-{{ router.model }}     msg=model

{% for key, value in router.device_variables.items() | default({}) %}

    ${val}=    Json Search List    ${response.json()}    header.columns[?contains(title, '{{ key }}')].property
    ${r_value}=    Json Search String    ${response.json()}    data[0]."${val[0]}"
    Should Be Equal As Strings    ${r_value}    {{ router.device_variables[key] }}    ignore_case=${True}    msg={{ key }}

{% endfor %}

{% endif %}

{% if router.configuration_group is defined %}

Verify Configuration Group Apply {{ router.configuration_group }} With Chassis Id {{ router.chassis_id }}
    ${cg_id}=    Json Search String    ${r_config_groups.json()}    [?name=='{{ router.configuration_group }}'] | [0].id
    Should Not Be Empty    ${cg_id}    msg=Check if configuration group "{{ router.configuration_group }}" is found
    ${response}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/config-group/${cg_id}/device/associate
    ${device}=    Json Search    ${response.json()}    devices[?id=='{{ router.chassis_id }}'] | [0]
    Run Keyword If    $device is None    Fail    Device with chassis id "{{ router.chassis_id }}" not associated to configuration group "{{ router.configuration_group }}"
    Should Be Equal Value Json String    ${device}    groupTopologyLabel    {{ router.topology_label | default('not_defined') }}    ignore_case=${True}    msg=topology_label

    ${response}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/config-group/${cg_id}/device/variables    params=device-id={{ router.chassis_id }}
{% for key, value in router.device_variables.items() | default({}) %}
{% set key_name = 'region-id' if key == 'region_id' else key %}
{% if value is iterable and value is not string %}
    ${var_value}=    Json Search List    ${response.json()}    devices[0].variables[?name=='{{ key_name }}'] | [0].value
    ${expected_value}=    Evaluate    {{ value }}
    Lists Should Be Equal    ${var_value}    ${expected_value}    ignore_order=True    msg={{ key }}
{% else %}
    ${var_value}=    Json Search String    ${response.json()}    devices[0].variables[?name=='{{ key_name }}'] | [0].value
    Should Be Equal As Strings    ${var_value}    {{ value }}    ignore_case=${True}    msg={{ key }}
{% endif %}
{% endfor %}

{% endif %}

{% if router.policy_group is defined %}

Verify Policy Group Apply {{ router.policy_group }} With Chassis Id {{ router.chassis_id }}
    ${pg_id}=    Json Search String    ${r_policy_groups.json()}    [?name=='{{ router.policy_group }}'] | [0].id
    Should Not Be Empty    ${pg_id}    msg=Check if policy group "{{ router.policy_group }}" is found
    ${response}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/policy-group/${pg_id}/device/variables    params=device-id={{ router.chassis_id }}
{% for key, value in router.get('policy_variables', {}).items() %}
{% if value is iterable and value is not string %}
    ${var_value}=    Json Search List    ${response.json()}    devices[0].variables[?name=='{{ key }}'] | [0].value
    ${expected_value}=    Evaluate    {{ value }}
    Lists Should Be Equal    ${var_value}    ${expected_value}    ignore_order=True    msg={{ key }}
{% else %}
    ${var_value}=    Json Search String    ${response.json()}    devices[0].variables[?name=='{{ key }}'] | [0].value
    Should Be Equal As Strings    ${var_value}    {{ value }}    ignore_case=${True}    msg={{ key }}
{% endif %}
{% endfor %}

{% endif %}

{% endfor %}

{% endfor %}

{% endif %}
