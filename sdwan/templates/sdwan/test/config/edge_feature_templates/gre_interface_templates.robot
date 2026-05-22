*** Settings ***
Documentation   Verify GRE Interface Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.gre_interface_templates is defined %}

*** Test Cases ***
Get GRE Interface Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_vpn_interface_gre']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.gre_interface_templates | default([]) %}

Verify Edge Feature Template GRE Interface Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.gre_interface_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "if-name"
    ...    {{ ft_yaml.interface_name | default("not_defined") }}
    ...    {{ ft_yaml.interface_name_variable | default("not_defined") }}
    ...    msg=interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    description
    ...    {{ ft_yaml.interface_description | default("not_defined") }}
    ...    {{ ft_yaml.interface_description_variable | default("not_defined") }}
    ...    msg=interface_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-destination"
    ...    {{ ft_yaml.tunnel_destination | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_destination_variable | default("not_defined") }}
    ...    msg=tunnel_destination

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-source-interface"
    ...    {{ ft_yaml.tunnel_source_interface | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_source_interface_variable | default("not_defined") }}
    ...    msg=tunnel_source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-source"
    ...    {{ ft_yaml.tunnel_source_ip | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_source_ip_variable | default("not_defined") }}
    ...    msg=tunnel_source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.address
    ...    {{ ft_yaml.ip_address | default("not_defined") }}
    ...    {{ ft_yaml.ip_address_variable | default("not_defined") }}
    ...    msg=ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    mtu
    ...    {{ ft_yaml.ip_mtu | default("not_defined") }}
    ...    {{ ft_yaml.ip_mtu_variable | default("not_defined") }}
    ...    msg=ip_mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tcp-mss-adjust"
    ...    {{ ft_yaml.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tcp_mss_variable | default("not_defined") }}
    ...    msg=tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "clear-dont-fragment"
    ...    {{ ft_yaml.clear_dont_fragment | default("not_defined") }}
    ...    {{ ft_yaml.clear_dont_fragment_variable | default("not_defined") }}
    ...    msg=clear_dont_fragment

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "rewrite-rule"."rule-name"
    ...    {{ ft_yaml.rewrite_rule | default("not_defined") }}
    ...    {{ ft_yaml.rewrite_rule_variable | default("not_defined") }}
    ...    msg=rewrite_rule

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    application
    ...    {{ ft_yaml.application | default("not_defined") }}
    ...    {{ ft_yaml.application_variable | default("not_defined") }}
    ...    msg=application

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker
    ...    {{ ft_yaml.tracker | default("not_defined") }}
    ...    {{ ft_yaml.tracker_variable | default("not_defined") }}
    ...    msg=tracker

{% endfor %}

{% endif %}