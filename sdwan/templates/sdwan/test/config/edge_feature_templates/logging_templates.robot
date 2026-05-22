*** Settings ***
Documentation   Verify Logging Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.logging_templates is defined %}

*** Test Cases ***
Get Logging Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_logging']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.logging_templates | default([]) %}

Verify Edge Feature Template Logging Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.logging_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    disk.enable
    ...    {{ ft_yaml.disk_logging | default("not_defined") | lower() }}
    ...    {{ ft_yaml.disk_logging_variable | default("not_defined") }}
    ...    msg=disk_logging

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    disk.file.rotate
    ...    {{ ft_yaml.log_rotations | default("not_defined") }}
    ...    {{ ft_yaml.log_rotations_variable | default("not_defined") }}
    ...    msg=log_rotations

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    disk.file.size
    ...    {{ ft_yaml.max_size | default("not_defined") }}
    ...    {{ ft_yaml.max_size_variable | default("not_defined") }}
    ...    msg=max_size

    Should Be Equal Value Json List Length    ${ft.json()}    server.vipValue    {{ ft_yaml.ipv4_servers | default([]) | length }}    msg=ipv4_servers length

{% for ipv4_server in ft_yaml.ipv4_servers | default([]) %}

    Log    === IPv4 Server {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].name
    ...    {{ ipv4_server.hostname_ip | default("not_defined") }}
    ...    {{ ipv4_server.hostname_ip_variable | default("not_defined") }}
    ...    msg=ipv4_servers.hostname_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].tls."enable-tls"
    ...    {{ ipv4_server.enable_tls | default("not_defined") | lower() }}
    ...    {{ ipv4_server.enable_tls_variable | default("not_defined") }}
    ...    msg=ipv4_servers.enable_tls

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].priority
    ...    {{ ipv4_server.logging_level | default("not_defined") }}
    ...    {{ ipv4_server.logging_level_variable | default("not_defined") }}
    ...    msg=ipv4_servers.logging_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}]."source-interface"
    ...    {{ ipv4_server.source_interface | default("not_defined") }}
    ...    {{ ipv4_server.source_interface_variable | default("not_defined") }}
    ...    msg=ipv4_servers.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].tls."tls-properties".profile
    ...    {{ ipv4_server.tls_profile | default("not_defined") }}
    ...    {{ ipv4_server.tls_profile_variable | default("not_defined") }}
    ...    msg=ipv4_servers.tls_profile

    Should Be Equal Value Json String    ${ft.json()}    server.vipValue[{{loop.index0}}].vipOptional
    ...    {{ ipv4_server.optional | default("not_defined") }}
    ...    msg=ipv4_servers.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    server.vipValue[{{loop.index0}}].vpn
    ...    {{ ipv4_server.vpn_id | default("not_defined") }}
    ...    {{ ipv4_server.vpn_id_variable | default("not_defined") }}
    ...    msg=ipv4_servers.vpn_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "ipv6-server".vipValue    {{ ft_yaml.ipv6_servers | default([]) | length }}    msg=ipv6_servers length

{% for ipv6_server in ft_yaml.ipv6_servers | default([]) %}

    Log    === IPv6 Server {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].name
    ...    {{ ipv6_server.hostname_ip | default("not_defined") }}
    ...    {{ ipv6_server.hostname_ip_variable | default("not_defined") }}
    ...    msg=ipv6_servers.hostname_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].tls."enable-tls"
    ...    {{ ipv6_server.enable_tls | default("not_defined") | lower() }}
    ...    {{ ipv6_server.enable_tls_variable | default("not_defined") }}
    ...    msg=ipv6_servers.enable_tls

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].priority
    ...    {{ ipv6_server.logging_level | default("not_defined") }}
    ...    {{ ipv6_server.logging_level_variable | default("not_defined") }}
    ...    msg=ipv6_servers.logging_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}]."source-interface"
    ...    {{ ipv6_server.source_interface | default("not_defined") }}
    ...    {{ ipv6_server.source_interface_variable | default("not_defined") }}
    ...    msg=ipv6_servers.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].tls."tls-properties".profile
    ...    {{ ipv6_server.tls_profile | default("not_defined") }}
    ...    {{ ipv6_server.tls_profile_variable | default("not_defined") }}
    ...    msg=ipv6_servers.tls_profile

    Should Be Equal Value Json String    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].vipOptional
    ...    {{ ipv6_server.optional | default("not_defined") }}
    ...    msg=ipv6_servers.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-server".vipValue[{{loop.index0}}].vpn
    ...    {{ ipv6_server.vpn_id | default("not_defined") }}
    ...    {{ ipv6_server.vpn_id_variable | default("not_defined") }}
    ...    msg=ipv6_servers.vpn_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "tls-profile".vipValue    {{ ft_yaml.tls_profiles | default([]) | length }}    msg=tls_profiles length
{% for tls_profile in ft_yaml.tls_profiles | default([]) %}

    Log    === TLS Profile {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tls-profile".vipValue[{{loop.index0}}]."auth-type"
    ...    {{ tls_profile.authentication_type | default("not_defined") | title() }}
    ...    {{ tls_profile.authentication_type_variable | default("not_defined") }}
    ...    msg=tls_profiles.authentication_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tls-profile".vipValue[{{loop.index0}}].ciphersuite."ciphersuite-list"
    ...    {{ tls_profile.ciphersuites | default("not_defined") }}
    ...    {{ tls_profile.ciphersuites_variable | default("not_defined") }}
    ...    msg=tls_profile.ciphersuites

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tls-profile".vipValue[{{loop.index0}}].profile
    ...    {{ tls_profile.name | default("not_defined") }}
    ...    {{ tls_profile.name_variable | default("not_defined") }}
    ...    msg=tls_profiles.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tls-profile".vipValue[{{loop.index0}}]."tls-version"."version"
    ...    {{ tls_profile.version | default("not_defined") }}
    ...    {{ tls_profile.version_variable | default("not_defined") }}
    ...    msg=tls_profiles.version

{% endfor %}

{% endfor %}

{% endif %}
