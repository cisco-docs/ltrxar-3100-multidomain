*** Settings ***
Documentation   Verify SIG Credential Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.sig_credentials_templates is defined %}

*** Test Cases ***
Get SIG Credential Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_sig_credentials']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.sig_credentials_templates | default([]) %}

{% if ft_yaml.name in ["umbrella", "Cisco-Umbrella-Global-Credentials"] %}
{% set sigc_value = "Cisco-Umbrella-Global-Credentials" %}
{% elif ft_yaml.name in ["zscaler", "Cisco-Zscaler-Global-Credentials"] %}
{% set sigc_value = "Cisco-Zscaler-Global-Credentials" %}
{% endif %}

Verify Edge Feature Template SIG Credential Feature Template {{ sigc_value }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{sigc_value }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ sigc_value }}    msg=name
    ${ft_sig_template_name}=    Json Search String    ${ft_summary_json}    templateName
    ${description_default}=    Run Keyword If    '${ft_sig_template_name}'=='Cisco-Umbrella-Global-Credentials'
    ...    Set Variable    Global credentials for umbrella
    ...    ELSE    Set Variable    Global credentials for zscaler
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    ${description_default}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.sig_credentials_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{sigc_value }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    umbrella."api-key"
    ...    {{ ft_yaml.umbrella_api_key | default("not_defined") }}
    ...    {{ ft_yaml.umbrella_api_key_variable | default("not_defined") }}
    ...    msg=umbrella_api_key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    umbrella."api-secret"
    ...    {{ ft_yaml.umbrella_api_secret | default("not_defined") }}
    ...    {{ ft_yaml.umbrella_api_secret_variable | default("not_defined") }}
    ...    msg=umbrella_api_secret

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    umbrella."org-id"
    ...    {{ ft_yaml.umbrella_organization_id | default("not_defined") }}
    ...    {{ ft_yaml.umbrella_organization_id_variable | default("not_defined") }}
    ...    msg=umbrella_organization_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    zscaler.organization
    ...    {{ ft_yaml.zscaler_organization | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_organization_variable | default("not_defined") }}
    ...    msg=zscaler_organization

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    zscaler."partner-base-uri"
    ...    {{ ft_yaml.zscaler_partner_base_uri | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_partner_base_uri_variable | default("not_defined") }}
    ...    msg=zscaler_partner_base_uri

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    zscaler.username
    ...    {{ ft_yaml.zscaler_username | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_username_variable | default("not_defined") }}
    ...    msg=zscaler_username

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    zscaler.password
    ...    {{ ft_yaml.zscaler_password | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_password_variable | default("not_defined") }}
    ...    msg=zscaler_password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    zscaler."partner-key"
    ...    {{ ft_yaml.zscaler_partner_api_key | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_partner_api_key_variable | default("not_defined") }}
    ...    msg=zscaler_partner_api_key

{% endfor %}

{% endif %}
