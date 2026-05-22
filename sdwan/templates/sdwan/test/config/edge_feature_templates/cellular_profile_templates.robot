*** Settings ***
Documentation   Verify Cellular Profile Feature Template
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.cellular_profile_templates is defined %}

*** Test Cases ***
Get Cellular Profile Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cellular-cedge-profile']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.cellular_profile_templates | default([]) %}

Verify Edge Feature Template Cellular Profile Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.cellular_profile_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    id
    ...    {{ ft_yaml.profile_id | default("not_defined") }}
    ...    {{ ft_yaml.profile_id_variable | default("not_defined") }}
    ...    msg=profile_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    apn
    ...    {{ ft_yaml.access_point_name | default("not_defined") }}
    ...    {{ ft_yaml.access_point_name_variable | default("not_defined") }}
    ...    msg=access_point_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "pdn-type"
    ...    {{ ft_yaml.packet_data_network_type | default("not_defined") }}
    ...    {{ ft_yaml.packet_data_network_type_variable | default("not_defined") }}
    ...    msg=packet_data_network_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    authentication
    ...    {{ ft_yaml.authentication_type | default("not_defined") }}
    ...    {{ ft_yaml.authentication_type_variable | default("not_defined") }}
    ...    msg=authentication_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    username
    ...    {{ ft_yaml.profile_username | default("not_defined") }}
    ...    {{ ft_yaml.profile_username_variable | default("not_defined") }}
    ...    msg=profile_username

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    password
    ...    {{ ft_yaml.profile_password | default("not_defined") }}
    ...    {{ ft_yaml.profile_password_variable | default("not_defined") }}
    ...    msg=profile_password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "no-overwrite"
    ...    {{ ft_yaml.no_overwrite | default("not_defined") }}
    ...    {{ ft_yaml.no_overwrite_variable | default("not_defined") }}
    ...    msg=no_overwrite

{% endfor %}

{% endif %}