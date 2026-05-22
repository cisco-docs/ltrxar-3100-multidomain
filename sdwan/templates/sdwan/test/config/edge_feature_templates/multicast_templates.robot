*** Settings ***
Documentation   Verify Multicast Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.multicast_templates is defined %}

*** Test Cases ***
Get Multicast Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cedge_multicast']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.multicast_templates | default([]) %}

Verify Edge Feature Template Multicast Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.multicast_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    multicast."spt-only"
    ...    {{ ft_yaml.spt_only | default("not_defined") }}
    ...    {{ ft_yaml.spt_only_variable | default("not_defined") }}
    ...    msg=spt_only

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "multicast-replicator".local
    ...    {{ ft_yaml.local_replicator | default("not_defined") }}
    ...    {{ ft_yaml.local_replicator_variable | default("not_defined") }}
    ...    msg=local_replicator

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "multicast-replicator".threshold
    ...    {{ ft_yaml.threshold | default("not_defined") }}
    ...    {{ ft_yaml.threshold_variable | default("not_defined") }}
    ...    msg=threshold

{% endfor %}
{% endif %}
