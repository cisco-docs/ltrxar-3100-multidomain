*** Settings ***
Documentation   Verify OSPF Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.ospf_templates is defined %}

*** Test Cases ***
Get OSPF Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_ospf']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.ospf_templates | default([]) %}

Verify Edge Feature Template OSPF Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.ospf_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."auto-cost"."reference-bandwidth"
    ...    {{ ft_yaml.auto_cost_reference_bandwidth | default("not_defined") }}
    ...    {{ ft_yaml.auto_cost_reference_bandwidth_variable | default("not_defined") }}
    ...    msg=auto_cost_reference_bandwidth

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.compatible.rfc1583
    ...    {{ ft_yaml.compatible_rfc1583 | default("not_defined") }}
    ...    {{ ft_yaml.compatible_rfc1583_variable | default("not_defined") }}
    ...    msg=compatible_rfc1583

    # Custom handling to detect if default_information_originate enabled
    ${default_information_originate}=   Json Search List   ${ft.json()}        ospf."default-information".originate.*.vipType
    ${default_information_originate}=   Set Variable If    ${default_information_originate} == [] or ${default_information_originate} == ['ignore']    false    true
    Should Be Equal As Strings    ${default_information_originate}    {{ ft_yaml.default_information_originate | default("false") | lower() }}    msg=default_information_originate
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."default-information".originate.always
    ...    {{ ft_yaml.default_information_originate_always | default("not_defined") }}
    ...    {{ ft_yaml.default_information_originate_always_variable | default("not_defined") }}
    ...    msg=default_information_originate_always

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."default-information".originate.metric
    ...    {{ ft_yaml.default_information_originate_metric | default("not_defined") }}
    ...    {{ ft_yaml.default_information_originate_metric_variable | default("not_defined") }}
    ...    msg=default_information_originate_metric

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."default-information".originate."metric-type"
    ...    {{ ft_yaml.default_information_originate_metric_type | default("not_defined") }}
    ...    {{ ft_yaml.default_information_originate_metric_type_variable | default("not_defined") }}
    ...    msg=default_information_originate_metric_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.distance."inter-area"
    ...    {{ ft_yaml.distance_inter_area | default("not_defined") }}
    ...    {{ ft_yaml.distance_inter_area_variable | default("not_defined") }}
    ...    msg=distance_inter_area

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.distance."intra-area"
    ...    {{ ft_yaml.distance_intra_area | default("not_defined") }}
    ...    {{ ft_yaml.distance_intra_area_variable | default("not_defined") }}
    ...    msg=distance_intra_area

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.distance.external
    ...    {{ ft_yaml.distance_external | default("not_defined") }}
    ...    {{ ft_yaml.distance_external_variable | default("not_defined") }}
    ...    msg=distance_external

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."route-policy".vipValue[0]."pol-name"
    ...    {{ ft_yaml.route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_policy_variable | default("not_defined") }}
    ...    msg=route_policy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."router-id"
    ...    {{ ft_yaml.router_id | default("not_defined") }}
    ...    {{ ft_yaml.router_id_variable | default("not_defined") }}
    ...    msg=router_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.timers.spf.delay
    ...    {{ ft_yaml.timers_spf_delay | default("not_defined") }}
    ...    {{ ft_yaml.timers_spf_delay_variable | default("not_defined") }}
    ...    msg=timers_spf_delay

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.timers.spf."initial-hold"
    ...    {{ ft_yaml.timers_spf_initial_hold | default("not_defined") }}
    ...    {{ ft_yaml.timers_spf_initial_hold_variable | default("not_defined") }}
    ...    msg=timers_spf_initial_hold

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.timers.spf."max-hold"
    ...    {{ ft_yaml.timers_spf_max_hold | default("not_defined") }}
    ...    {{ ft_yaml.timers_spf_max_hold_variable | default("not_defined") }}
    ...    msg=timers_spf_max_hold

    Should Be Equal Value Json List Length    ${ft.json()}    ospf.area.vipValue    {{ ft_yaml.areas | default([]) | length }}    msg=areas length

{% for area_index in range(ft_yaml.areas | default([]) | length()) %}

    Log    === Area {{area_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}]."a-num"
    ...    {{ ft_yaml.areas[area_index].area_number | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].area_number_variable | default("not_defined") }}
    ...    msg=areas.area_number

    # Custom handling of area types
    ${rec_area_type}=    Json Search    ${ft.json()}    ospf.area.vipValue[{{ area_index }}]
    ${res_area_keys}=    Get Dictionary Keys    ${rec_area_type}

{% if ft_yaml.areas[area_index].area_type | default("not_defined") != "not_defined" %}

    List Should Contain Value    ${res_area_keys}    {{ ft_yaml.areas[area_index].area_type | default("not_defined") }}    msg=area type

{% else %}

    ${status}=    Evaluate    'stub' not in ${res_area_keys} and 'nssa' not in ${res_area_keys}
    IF    ${status} == ${False}
        Fail   msg=area type
    END

{% endif %}
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].{{ ft_yaml.areas[area_index].area_type | default("not_defined") }}."no-summary"
    ...    {{ ft_yaml.areas[area_index].no_summary | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].no_summary_variable | default("not_defined") }}
    ...    msg=areas.no_summary

    Should Be Equal Value Json String    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].vipOptional
    ...    {{ ft_yaml.areas[area_index].optional | default("not_defined") }}
    ...    msg=areas.optional

    Should Be Equal Value Json List Length    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue    {{ ft_yaml.areas[area_index].interfaces | default([]) | length }}    msg=areas.interfaces length

{% for int_index in range(ft_yaml.areas[area_index].interfaces | default([]) | length()) %}

    Log    === Area {{area_index}} Interface {{int_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].authentication."message-digest".md5
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_message_digest_key | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_message_digest_key_variable | default("not_defined") }}
    ...    msg=areas.interfaces.authentication_message_digest_key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].authentication."message-digest"."message-digest-key"
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_message_digest_key_id | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_message_digest_key_id_variable | default("not_defined") }}
    ...    msg=areas.interfaces.authentication_message_digest_key_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].authentication.type
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_type | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].authentication_type_variable | default("not_defined") }}
    ...    msg=areas.interfaces.authentication_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].cost
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].cost | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].cost_variable | default("not_defined") }}
    ...    msg=areas.interfaces.cost

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}]."dead-interval"
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].dead_interval | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].dead_interval_variable | default("not_defined") }}
    ...    msg=areas.interfaces.dead_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}]."hello-interval"
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].hello_interval | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].hello_interval_variable | default("not_defined") }}
    ...    msg=areas.interfaces.hello_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].name
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].name | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].name_variable | default("not_defined") }}
    ...    msg=areas.interfaces.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].network
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].network_type | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].network_type_variable | default("not_defined") }}
    ...    msg=areas.interfaces.network_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}]."passive-interface"
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].passive_interface | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].passive_interface_variable | default("not_defined") }}
    ...    msg=areas.interfaces.passive_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}].priority
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].priority | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].priority_variable | default("not_defined") }}
    ...    msg=areas.interfaces.priority

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].interface.vipValue[{{ int_index }}]."retransmit-interval"
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].retransmit_interval | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].interfaces[int_index].retransmit_interval_variable | default("not_defined") }}
    ...    msg=areas.interfaces.retransmit_interval

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].range.vipValue    {{ ft_yaml.areas[area_index].ranges | default([]) | length }}    msg=areas.ranges length

{% for range_index in range(ft_yaml.areas[area_index].ranges | default([]) | length()) %}

    Log    === Area {{area_index}} Range {{range_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].range.vipValue[{{ range_index }}].address
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].address | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].address_variable | default("not_defined") }}
    ...    msg=areas.ranges.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].range.vipValue[{{ range_index }}].cost
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].cost | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].cost_variable | default("not_defined") }}
    ...    msg=areas.ranges.cost

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.area.vipValue[{{ area_index }}].range.vipValue[{{ range_index }}]."no-advertise"
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].no_advertise | default("not_defined") }}
    ...    {{ ft_yaml.areas[area_index].ranges[range_index].no_advertise_variable | default("not_defined") }}
    ...    msg=areas.ranges.no_advertise

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ospf."max-metric"."router-lsa".vipValue    {{ ft_yaml.max_metric_router_lsas | default([]) | length }}    msg=max_metric_router_lsas length

{% for lsa_index in range(ft_yaml.max_metric_router_lsas | default([]) | length()) %}

    Log    === Max Metric Router LSA {{lsa_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."max-metric"."router-lsa".vipValue[{{lsa_index}}].time
    ...    {{ ft_yaml.max_metric_router_lsas[lsa_index].time | default("not_defined") }}
    ...    {{ ft_yaml.max_metric_router_lsas[lsa_index].time_variable | default("not_defined") }}
    ...    msg=max_metric_router_lsas.time

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf."max-metric"."router-lsa".vipValue[{{lsa_index}}]."ad-type"
    ...    {{ ft_yaml.max_metric_router_lsas[lsa_index].type | default("not_defined") }}
    ...    {{ ft_yaml.max_metric_router_lsas[lsa_index].type_variable | default("not_defined") }}
    ...    msg=max_metric_router_lsas.type

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ospf.redistribute.vipValue    {{ ft_yaml.redistributes | default([]) | length }}    msg=redistributes length

{% for redistribute_index in range(ft_yaml.redistributes | default([]) | length()) %}

    Log    === Redistribute {{redistribute_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.redistribute.vipValue[{{redistribute_index}}].dia
    ...    {{ ft_yaml.redistributes[redistribute_index].nat_dia | default("not_defined") }}
    ...    {{ ft_yaml.redistributes[redistribute_index].nat_dia_variable | default("not_defined") }}
    ...    msg=redistributes.nat_dia

    Should Be Equal Value Json String    ${ft.json()}    ospf.redistribute.vipValue[{{redistribute_index}}].vipOptional
    ...    {{ ft_yaml.redistributes[redistribute_index].optional | default("not_defined") }}
    ...    msg=redistributes.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.redistribute.vipValue[{{redistribute_index}}].protocol
    ...    {{ ft_yaml.redistributes[redistribute_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.redistributes[redistribute_index].protocol_variable | default("not_defined") }}
    ...    msg=redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ospf.redistribute.vipValue[{{redistribute_index}}]."route-policy"
    ...    {{ ft_yaml.redistributes[redistribute_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.redistributes[redistribute_index].route_policy_variable | default("not_defined") }}
    ...    msg=redistributes.route_policy

{% endfor %}

{% endfor %}

{% endif %}
