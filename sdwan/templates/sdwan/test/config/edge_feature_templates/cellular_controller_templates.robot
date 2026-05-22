*** Settings ***
Documentation   Verify Cellular Controller Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.cellular_controller_templates is defined %}

*** Test Cases ***
Get Cellular Controller Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cellular-cedge-controller']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.cellular_controller_templates | default([]) %}

Verify Edge Feature Template Cellular Controller Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.cellular_controller_templates.device_types) %}
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
    ...    {{ ft_yaml.cellular_interface_id | default("not_defined") }}
    ...    {{ ft_yaml.cellular_interface_id_variable | default("not_defined") }}
    ...    msg=cellular_interface_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    lte.sim.primary.slot
    ...    {{ ft_yaml.primary_sim_slot | default("not_defined") }}
    ...    {{ ft_yaml.primary_sim_slot_variable | default("not_defined") }}
    ...    msg=primary_sim_slot

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    lte.sim."max-retry"
    ...    {{ ft_yaml.sim_failover_retries | default("not_defined") }}
    ...    {{ ft_yaml.sim_failover_retries_variable | default("not_defined") }}
    ...    msg=sim_failover_retries

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    lte.failovertimer
    ...    {{ ft_yaml.sim_failover_timeout | default("not_defined") }}
    ...    {{ ft_yaml.sim_failover_timeout_variable | default("not_defined") }}
    ...    msg=sim_failover_timeout

{% endfor %}

{% endif %}