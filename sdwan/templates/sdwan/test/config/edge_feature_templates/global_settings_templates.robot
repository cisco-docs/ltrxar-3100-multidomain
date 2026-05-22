*** Settings ***
Documentation   Verify Global Settings Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.global_settings_templates is defined %}

*** Test Cases ***
Get Global Settings Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cedge_global']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.global_settings_templates | default([]) %}

Verify Edge Feature Template Global Settings Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.global_settings_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."arp-proxy"
    ...    {{ ft_yaml.arp_proxy | default("not_defined") }}
    ...    {{ ft_yaml.arp_proxy_variable | default("not_defined") }}
    ...    msg=arp_proxy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip".cdp
    ...    {{ ft_yaml.cdp | default("not_defined") }}
    ...    {{ ft_yaml.cdp_variable | default("not_defined") }}
    ...    msg=cdp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."console-logging"
    ...    {{ ft_yaml.console_logging | default("not_defined") }}
    ...    {{ ft_yaml.console_logging_variable | default("not_defined") }}
    ...    msg=console_logging

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."domain-lookup"
    ...    {{ ft_yaml.domain_lookup | default("not_defined") }}
    ...    {{ ft_yaml.domain_lookup_variable | default("not_defined") }}
    ...    msg=domain_lookup

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."ftp-passive"
    ...    {{ ft_yaml.ftp_passive | default("not_defined") }}
    ...    {{ ft_yaml.ftp_passive_variable | default("not_defined") }}
    ...    msg=ftp_passive

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "http-global"."http-authentication"
    ...    {{ ft_yaml.http_authentication | default("not_defined") }}
    ...    {{ ft_yaml.http_authentication_variable | default("not_defined") }}
    ...    msg=http_authentication

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."http-server"
    ...    {{ ft_yaml.http_server | default("not_defined") }}
    ...    {{ ft_yaml.http_server_variable | default("not_defined") }}
    ...    msg=http_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."https-server"
    ...    {{ ft_yaml.https_server | default("not_defined") }}
    ...    {{ ft_yaml.https_server_variable | default("not_defined") }}
    ...    msg=https_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other".bootp
    ...    {{ ft_yaml.ignore_bootp | default("not_defined") }}
    ...    {{ ft_yaml.ignore_bootp_variable | default("not_defined") }}
    ...    msg=ignore_bootp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."source-route"
    ...    {{ ft_yaml.ip_source_routing | default("not_defined") }}
    ...    {{ ft_yaml.ip_source_routing_variable | default("not_defined") }}
    ...    msg=ip_source_routing

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip".lldp
    ...    {{ ft_yaml.lldp | default("not_defined") }}
    ...    {{ ft_yaml.lldp_variable | default("not_defined") }}
    ...    msg=lldp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "nat64-global"."nat64-timeout"."udp-timeout"
    ...    {{ ft_yaml.nat64_udp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.nat64_udp_timeout_variable | default("not_defined") }}
    ...    msg=nat64_udp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "nat64-global"."nat64-timeout"."tcp-timeout"
    ...    {{ ft_yaml.nat64_tcp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.nat64_tcp_timeout_variable | default("not_defined") }}
    ...    msg=nat64_tcp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip".rcmd
    ...    {{ ft_yaml.rsh_rcp | default("not_defined") }}
    ...    {{ ft_yaml.rsh_rcp_variable | default("not_defined") }}
    ...    msg=rsh_rcp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."snmp-ifindex-persist"
    ...    {{ ft_yaml.snmp_ifindex_persist | default("not_defined") }}
    ...    {{ ft_yaml.snmp_ifindex_persist_variable | default("not_defined") }}
    ...    msg=snmp_ifindex_persist

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."source-intrf"
    ...    {{ ft_yaml.source_interface | default("not_defined") }}
    ...    {{ ft_yaml.source_interface_variable | default("not_defined") }}
    ...    msg=source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ssh.version
    ...    {{ ft_yaml.ssh_version | default("not_defined") }}
    ...    {{ ft_yaml.ssh_version_variable | default("not_defined") }}
    ...    msg=ssh_version

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."tcp-keepalives-in"
    ...    {{ ft_yaml.tcp_keepalives_in | default("not_defined") }}
    ...    {{ ft_yaml.tcp_keepalives_in_variable | default("not_defined") }}
    ...    msg=tcp_keepalives_in

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."tcp-keepalives-out"
    ...    {{ ft_yaml.tcp_keepalives_out | default("not_defined") }}
    ...    {{ ft_yaml.tcp_keepalives_out_variable | default("not_defined") }}
    ...    msg=tcp_keepalives_out

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."tcp-small-servers"
    ...    {{ ft_yaml.tcp_small_servers | default("not_defined") }}
    ...    {{ ft_yaml.tcp_small_servers_variable | default("not_defined") }}
    ...    msg=tcp_small_servers

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-ip"."line-vty"
    ...    {{ ft_yaml.telnet_outbound | default("not_defined") }}
    ...    {{ ft_yaml.telnet_outbound_variable | default("not_defined") }}
    ...    msg=telnet_outbound

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."udp-small-servers"
    ...    {{ ft_yaml.udp_small_servers | default("not_defined") }}
    ...    {{ ft_yaml.udp_small_servers_variable | default("not_defined") }}
    ...    msg=udp_small_servers

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "services-global"."services-other"."vty-logging"
    ...    {{ ft_yaml.vty_logging | default("not_defined") }}
    ...    {{ ft_yaml.vty_logging_variable | default("not_defined") }}
    ...    msg=vty_logging

{% endfor %}

{% endif %}
