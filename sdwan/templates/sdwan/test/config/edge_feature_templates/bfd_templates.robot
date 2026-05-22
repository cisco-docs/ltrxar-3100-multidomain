*** Settings ***
Documentation   Verify BFD Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.bfd_templates is defined %}

*** Test Cases ***
Get BFD Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_bfd']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.bfd_templates | default([]) %}

Verify Edge Feature Template BFD Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.bfd_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "default-dscp"
    ...    {{ ft_yaml.default_dscp | default("not_defined") }}
    ...    {{ ft_yaml.default_dscp_variable | default("not_defined") }}
    ...    msg=default_dscp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "app-route".multiplier
    ...    {{ ft_yaml.multiplier | default("not_defined") }}
    ...    {{ ft_yaml.multiplier_variable | default("not_defined") }}
    ...    msg=multiplier

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "app-route"."poll-interval"
    ...    {{ ft_yaml.poll_interval | default("not_defined") }}
    ...    {{ ft_yaml.poll_interval_variable | default("not_defined") }}
    ...    msg=poll_interval

    Should Be Equal Value Json List Length    ${ft.json()}    color.vipValue    {{ ft_yaml.colors | default([]) | length }}    msg=colors length

{% for color in ft_yaml.colors | default([]) %}

    Log    === Color {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    color.vipValue[{{loop.index0}}].color
    ...    {{ color.color | default("not_defined") }}
    ...    {{ color.color_variable | default("not_defined") }}
    ...    msg=colors.color

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    color.vipValue[{{loop.index0}}].dscp
    ...    {{ color.default_dscp | default("not_defined") }}
    ...    {{ color.default_dscp_variable | default("not_defined") }}
    ...    msg=colors.default_dscp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    color.vipValue[{{loop.index0}}]."hello-interval"
    ...    {{ color.hello_interval | default("not_defined") }}
    ...    {{ color.hello_interval_variable | default("not_defined") }}
    ...    msg=colors.hello_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    color.vipValue[{{loop.index0}}].multiplier
    ...    {{ color.multiplier | default("not_defined") }}
    ...    {{ color.multiplier_variable | default("not_defined") }}
    ...    msg=colors.multiplier

    Should Be Equal Value Json String    ${ft.json()}    color.vipValue[{{loop.index0}}].vipOptional
    ...    {{ color.optional | default("not_defined") }}
    ...    msg=colors.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    color.vipValue[{{loop.index0}}]."pmtu-discovery"
    ...    {{ color.path_mtu_discovery | default("not_defined") | lower() }}
    ...    {{ color.path_mtu_discovery_variable | default("not_defined") }}
    ...    msg=colors.path_mtu_discovery

{% endfor %}

{% endfor %}

{% endif %}
