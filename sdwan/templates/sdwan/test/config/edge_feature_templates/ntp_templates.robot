*** Settings ***
Documentation   Verify NTP Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.ntp_templates is defined%}

*** Test Cases ***
Get NTP Feature Templates
    ${r}=    GET On Session With Retry   sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_ntp']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.ntp_templates | default([]) %}

Verify Edge Feature Template NTP Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.ntp_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    master.enable
    ...    {{ ft_yaml.master | default("not_defined") }}
    ...    {{ ft_yaml.master_variable | default("not_defined") }}
    ...    msg=master

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    master.stratum
    ...    {{ ft_yaml.master_stratum | default("not_defined") }}
    ...    {{ ft_yaml.master_stratum_variable | default("not_defined") }}
    ...    msg=master_stratum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    master.source
    ...    {{ ft_yaml.master_source_interface | default("not_defined") }}
    ...    {{ ft_yaml.master_source_interface_variable | default("not_defined") }}
    ...    msg=master_source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    keys.trusted
    ...    {{ ft_yaml.trusted_keys | default("not_defined") }}
    ...    {{ ft_yaml.trusted_keys_variable | default("not_defined") }}
    ...    msg=trusted_keys

    Should Be Equal Value Json List Length    ${ft.json()}    keys.authentication.vipValue    {{ ft_yaml.authentication_keys | default([]) | length }}    msg=authentication_keys length

{% for ntp_auth_keys in ft_yaml.authentication_keys | default([]) %}

    Log    === Authentication Key {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    keys.authentication.vipValue[{{loop.index0}}].number
    ...    {{ ntp_auth_keys.id | default("not_defined") }}
    ...    {{ ntp_auth_keys.id_variable | default("not_defined") }}
    ...    msg=authentication_keys.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    keys.authentication.vipValue[{{loop.index0}}].md5
    ...    {{ ntp_auth_keys.value | default("not_defined") }}
    ...    {{ ntp_auth_keys.value_variable | default("not_defined") }}
    ...    msg=authentication_keys.value

    Should Be Equal Value Json String    ${ft.json()}    keys.authentication.vipValue[{{loop.index0}}].vipOptional
    ...    {{ ntp_auth_keys.optional | default("not_defined") }}
    ...    msg=authentication_keys.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    server.vipValue    {{ ft_yaml.servers | default([]) | length }}    msg=servers length

{% for ntp_server_template in ft_yaml.servers | default([]) %}

    Log    === NTP Server {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].name
    ...    {{ ntp_server_template.hostname_ip | default("not_defined") }}
    ...    {{ ntp_server_template.hostname_ip_variable | default("not_defined") }}
    ...    msg=servers.hostname_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].key
    ...    {{ ntp_server_template.authentication_key_id | default("not_defined") }}
    ...    {{ ntp_server_template.authentication_key_id_variable | default("not_defined") }}
    ...    msg=servers.authentication_key_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].vpn
    ...    {{ ntp_server_template.vpn_id | default("not_defined") }}
    ...    {{ ntp_server_template.vpn_id_variable | default("not_defined") }}
    ...    msg=servers.vpn_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].version
    ...    {{ ntp_server_template.version | default("not_defined") }}
    ...    {{ ntp_server_template.version_variable | default("not_defined") }}
    ...    msg=servers.version

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}]."source-interface"
    ...    {{ ntp_server_template.source_interface | default("not_defined") }}
    ...    {{ ntp_server_template.source_interface_variable | default("not_defined") }}
    ...    msg=servers.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].prefer
    ...    {{ ntp_server_template.prefer | default("not_defined") | lower }}
    ...    {{ ntp_server_template.prefer_variable | default("not_defined") }}
    ...    msg=servers.prefer

    Should Be Equal Value Json String    ${ft.json()}    server.vipValue[{{loop.index0}}].vipOptional
    ...    {{ ntp_server_template.optional | default("not_defined") }}
    ...    msg=servers.optional

{% endfor %}

{% endfor %}

{% endif %}
