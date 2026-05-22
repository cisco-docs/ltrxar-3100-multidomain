*** Settings ***
Documentation   Verify OMP Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.omp_templates is defined %}

*** Test Cases ***
Get OMP Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_omp']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.omp_templates | default([]) %}

Verify Edge Feature Template OMP Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.omp_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    timers."advertisement-interval"
    ...    {{ ft_yaml.advertisement_interval | default("not_defined") }}
    ...    {{ ft_yaml.advertisement_interval_variable | default("not_defined") }}
    ...    msg=advertisement_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ecmp-limit"
    ...    {{ ft_yaml.ecmp_limit | default("not_defined") }}
    ...    {{ ft_yaml.ecmp_limit_variable | default("not_defined") }}
    ...    msg=ecmp_limit

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    timers."eor-timer"
    ...    {{ ft_yaml.eor_timer | default("not_defined") }}
    ...    {{ ft_yaml.eor_timer_variable | default("not_defined") }}
    ...    msg=eor_timer

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "graceful-restart"
    ...    {{ ft_yaml.graceful_restart | default("not_defined") | lower }}
    ...    {{ ft_yaml.graceful_restart_variable | default("not_defined") }}
    ...    msg=graceful_restart

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    timers."graceful-restart-timer"
    ...    {{ ft_yaml.graceful_restart_timer | default("not_defined") }}
    ...    {{ ft_yaml.graceful_restart_timer_variable | default("not_defined") }}
    ...    msg=graceful_restart_timer

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    timers.holdtime
    ...    {{ ft_yaml.holdtime | default("not_defined") }}
    ...    {{ ft_yaml.holdtime_variable | default("not_defined") }}
    ...    msg=holdtime

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ignore-region-path-length"
    ...    {{ ft_yaml.ignore_region_path_length | default("not_defined") }}
    ...    {{ ft_yaml.ignore_region_path_length_variable | default("not_defined") }}
    ...    msg=ignore_region_path_length

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "omp-admin-distance-ipv4"
    ...    {{ ft_yaml.omp_admin_distance_ipv4 | default("not_defined") }}
    ...    {{ ft_yaml.omp_admin_distance_ipv4_variable | default("not_defined") }}
    ...    msg=omp_admin_distance_ipv4

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "omp-admin-distance-ipv6"
    ...    {{ ft_yaml.omp_admin_distance_ipv6 | default("not_defined") }}
    ...    {{ ft_yaml.omp_admin_distance_ipv6_variable | default("not_defined") }}
    ...    msg=omp_admin_distance_ipv6

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "overlay-as"
    ...    {{ ft_yaml.overlay_as | default("not_defined") }}
    ...    {{ ft_yaml.overlay_as_variable | default("not_defined") }}
    ...    msg=overlay_as

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "send-path-limit"
    ...    {{ ft_yaml.send_path_limit | default("not_defined") }}
    ...    {{ ft_yaml.send_path_limit_variable | default("not_defined") }}
    ...    msg=send_path_limit

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") | lower }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "transport-gateway"
    ...    {{ ft_yaml.transport_gateway | default("not_defined") }}
    ...    {{ ft_yaml.transport_gateway_variable | default("not_defined") }}
    ...    msg=transport_gateway

    # Custom handling of protocol fileds
    ${omp_ipv4_advertise_protocols_list}=    Create List    {{ ft_yaml.ipv4_advertise_protocols | default([]) | join('   ') }}
    Should Be Equal Value Json List    ${ft.json()}    advertise.vipValue[].protocol.vipValue    ${omp_ipv4_advertise_protocols_list}    msg=ipv4_advertise_protocols

    ${omp_ipv6_advertise_protocols_list}=    Create List    {{ ft_yaml.ipv6_advertise_protocols | default([]) | join('   ') }}
    Should Be Equal Value Json List    ${ft.json()}    "ipv6-advertise".vipValue[].protocol.vipValue    ${omp_ipv6_advertise_protocols_list}    msg=ipv6_advertise_protocols
    # End of custom handling

{% endfor %}
{% endif %}
