*** Settings ***
Documentation   Verify Service Feature Profile Configuration OSPFv3 IPv4 Features
Name            Service Profiles OSPFv3 IPv4 Features
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    ospfv3_ipv4
Resource        ../../../sdwan_common.resource

{% set profile_ospfv3_ipv4_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', {}) %}
 {% if profile.ospfv3_ipv4_features is defined %}
  {% set _ = profile_ospfv3_ipv4_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ospfv3_ipv4_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

    
{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.ospfv3_ipv4_features is defined %}    

Verify Feature Profiles Service Profiles {{ profile.name }} OSPFv3 IPv4 Features
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${service_ospf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/routing/ospfv3/ipv4
    Set Suite Variable    ${service_ospf_res}
    ${service_ospf}=    Json Search List    ${service_ospf_res.json()}    data[].payload
    Run Keyword If    ${service_ospf} == []    Fail    OSPFv3 IPv4 feature(s) expected to be configured within the service profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${service_ospf}

    # Extract route policies since they might be used in OSPFv3 IPv4
    ${route_policies_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/route-policy
    Set Suite Variable    ${route_policies_res}

{% for ospfv3_ipv4 in profile.ospfv3_ipv4_features | default([]) %}
    Log    === OSPFv3 IPv4: {{ ospfv3_ipv4.name }} ===

    # for each ospf find the corresponding one in the json and check parameters:
    ${ospfv3_ipv4_feature}=    Json Search    ${service_ospf}    [?name=='{{ ospfv3_ipv4.name }}'] | [0]
    Run Keyword If    $ospfv3_ipv4_feature is None    Fail    OSPFv3 IPv4 feature '{{ ospfv3_ipv4.name }}' not found in profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${ospfv3_ipv4_feature}    name    {{ ospfv3_ipv4.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ospfv3_ipv4_feature}    description    {{ ospfv3_ipv4.description | default('not_defined') | normalize_special_string }}    msg=description
    # Basic OSPFv3 IPv4 parameters
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.basic.routerId    {{ ospfv3_ipv4.router_id | default('not_defined') }}    {{ ospfv3_ipv4.router_id_variable | default('not_defined') }}    msg=ospfv3_ipv4.router_id
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.basic.distance    {{ ospfv3_ipv4.distance | default('not_defined') }}    {{ ospfv3_ipv4.distance_variable | default('not_defined') }}    msg=ospfv3_ipv4.distance
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.basic.externalDistance    {{ ospfv3_ipv4.distance_external | default('not_defined') }}    {{ ospfv3_ipv4.distance_external_variable | default('not_defined') }}    msg=ospfv3_ipv4.distance_external
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.basic.interAreaDistance    {{ ospfv3_ipv4.distance_inter_area | default('not_defined') }}    {{ ospfv3_ipv4.distance_inter_area_variable | default('not_defined') }}    msg=ospfv3_ipv4.distance_inter_area
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.basic.intraAreaDistance    {{ ospfv3_ipv4.distance_intra_area | default('not_defined') }}    {{ ospfv3_ipv4.distance_intra_area_variable | default('not_defined') }}    msg=ospfv3_ipv4.distance_intra_area

    # Advanced OSPFv3 IPv4 parameters
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.referenceBandwidth    {{ ospfv3_ipv4.reference_bandwidth | default('not_defined') }}    {{ ospfv3_ipv4.reference_bandwidth_variable | default('not_defined') }}    msg=ospfv3_ipv4.reference_bandwidth
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.compatibleRfc1583    {{ ospfv3_ipv4.rfc1583_compatibility | default('not_defined') }}    {{ ospfv3_ipv4.rfc1583_compatibility_variable | default('not_defined') }}    msg=ospfv3_ipv4.rfc1583_compatibility

    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.defaultOriginate.originate    {{ ospfv3_ipv4.default_originate | default('not_defined') }}    not_defined    msg=default_originate
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.defaultOriginate.always    {{ ospfv3_ipv4.default_originate_always | default('not_defined') }}    {{ ospfv3_ipv4.default_originate_always_variable | default('not_defined') }}    msg=ospfv3_ipv4.default_originate_always
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.defaultOriginate.metric    {{ ospfv3_ipv4.default_originate_metric | default('not_defined') }}    {{ ospfv3_ipv4.default_originate_metric_variable | default('not_defined') }}    msg=ospfv3_ipv4.default_originate_metric
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.defaultOriginate.metricType    {{ ospfv3_ipv4.default_originate_metric_type | default('not_defined') }}    {{ ospfv3_ipv4.default_originate_metric_type_variable | default('not_defined') }}    msg=ospfv3_ipv4.default_originate_metric_type

    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.spfTimers.delay    {{ ospfv3_ipv4.spf_calculation_delay | default('not_defined') }}    {{ ospfv3_ipv4.spf_calculation_delay_variable | default('not_defined') }}    msg=ospfv3_ipv4.spf_calculation_delay
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.spfTimers.initialHold    {{ ospfv3_ipv4.spf_initial_hold_time | default('not_defined') }}    {{ ospfv3_ipv4.spf_initial_hold_time_variable | default('not_defined') }}    msg=ospfv3_ipv4.spf_initial_hold_time
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.spfTimers.maxHold    {{ ospfv3_ipv4.spf_maximum_hold_time | default('not_defined') }}    {{ ospfv3_ipv4.spf_maximum_hold_time_variable | default('not_defined') }}    msg=ospfv3_ipv4.spf_maximum_hold_time
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.advanced.filter    {{ ospfv3_ipv4.filter | default('not_defined') }}    {{ ospfv3_ipv4.filter_variable | default('not_defined') }}    msg=ospfv3_ipv4.filter
    # Route policy
    Should Be Equal Referenced Object Name    ${ospfv3_ipv4_feature}    data.advanced.policyName.refId.value    ${route_policies_res.json()}    {{ ospfv3_ipv4.route_policy | default('not_defined') }}    ospfv3_ipv4.route_policy

    Log    =====Redistributes=====
    Should Be Equal Value Json List Length    ${ospfv3_ipv4_feature}    data.redistribute    {{ ospfv3_ipv4.get('redistributes', []) | length }}    msg=ospfv3_ipv4.redistributes length
{% if ospfv3_ipv4.redistributes is defined and ospfv3_ipv4.get('redistributes', [])|length > 0 %}
{% for redistribute in ospfv3_ipv4.redistributes | default([]) %}
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.redistribute[{{ loop.index0 }}].protocol    {{ redistribute.protocol | default('not_defined') }}    {{ redistribute.protocol_variable | default('not_defined') }}    msg=ospfv3_ipv4.redistributes.protocol
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.redistribute[{{ loop.index0 }}].translateRibMetric    {{ redistribute.translate_rib_metric | default('not_defined') }}    {{ redistribute.translate_rib_metric_variable | default('not_defined') }}    msg=ospfv3_ipv4.redistributes.translate_rib_metric
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.redistribute[{{ loop.index0 }}].natDia    {{ redistribute.nat_dia | default('not_defined') }}    {{ redistribute.nat_dia_variable | default('not_defined') }}    msg=ospfv3_ipv4.redistributes.natdia
    Should Be Equal Referenced Object Name    ${ospfv3_ipv4_feature}    data.redistribute[{{ loop.index0 }}].routePolicy.refId.value    ${route_policies_res.json()}    {{ redistribute.route_policy | default('not_defined') }}    ospfv3_ipv4.redistributes.route_policy
{% endfor %}
{% endif %}

    Log    =====Router LSA=====
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.maxMetricRouterLsa.action    {{ ospfv3_ipv4.router_lsa_action | default('not_defined') }}    not_defined    msg=ospfv3_ipv4.router_lsa_action
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.maxMetricRouterLsa.onStartUpTime    {{ ospfv3_ipv4.router_lsa_on_startup_time | default('not_defined') }}    {{ ospfv3_ipv4.router_lsa_on_startup_time_variable | default('not_defined') }}    msg=ospfv3_ipv4.router_lsa_on_startup_time

    Log    =====Areas=====
    Should Be Equal Value Json List Length    ${ospfv3_ipv4_feature}    data.area    {{ ospfv3_ipv4.get('areas', []) | length }}    msg=ospfv3_ipv4.areas length
{% if ospfv3_ipv4.areas is defined and ospfv3_ipv4.get('areas', [])|length > 0 %}
{% for area in ospfv3_ipv4.areas | default([]) %}
{% set area_index = loop.index0 %}
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].areaNum                                   {{ area.number | default('not_defined') }}    {{ area.number_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.number
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].areaTypeConfig.areaType                   {{ area.type | default('not_defined') }}    not_defined    msg=ospfv3_ipv4.areas.type
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].areaTypeConfig.alwaysTranslate            {{ area.always_translate | default('not_defined') }}    {{ area.always_translate_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.always_translate
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].areaTypeConfig.noSummary                  {{ area.no_summary | default('not_defined') }}    {{ area.no_summary_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.no_summary

    Log    =====Area {{ area.number }} Interfaces=====
    Should Be Equal Value Json List Length    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].interfaces    {{ area.get('interfaces', []) | length }}    msg=ospfv3_ipv4.areas.interfaces length
{% if area.interfaces is defined and area.get('interfaces', [])|length > 0 %}
{% for interface in area.interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].ifName    {{ interface.name | default('not_defined') }}    {{ interface.name_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.name
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].helloInterval    {{ interface.hello_interval | default('not_defined') }}    {{ interface.hello_interval_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.hello_interval
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].deadInterval    {{ interface.dead_interval | default('not_defined') }}    {{ interface.dead_interval_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.dead_interval
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].retransmitInterval    {{ interface.lsa_retransmit_interval | default('not_defined') }}    {{ interface.lsa_retransmit_interval_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.lsa_retransmit_interval
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].cost    {{ interface.cost | default('not_defined') }}    {{ interface.cost_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.cost
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].networkType    {{ interface.network_type | default('not_defined') }}    {{ interface.network_type_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.network_type
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].passiveInterface    {{ interface.passive | default('not_defined') }}    {{ interface.passive_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.passive
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].authenticationConfig.authType    {{ interface.authentication_type | default('not_defined') }}    {{ interface.authentication_type_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.authentication_type
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].authenticationConfig.spi    {{ interface.authentication_ipsec_spi | default('not_defined') }}    {{ interface.authentication_ipsec_spi_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.authentication_ipsec_spi
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].interfaces[{{ loop.index0 }}].authenticationConfig.authKey    {{ interface.authentication_ipsec_key | default('not_defined') }}    {{ interface.authentication_ipsec_key_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.interfaces.authentication_ipsec_key
{% endfor %}
{% endif %}

    Log    =====Area {{ area.number }} Ranges=====
    Should Be Equal Value Json List Length    ${ospfv3_ipv4_feature}    data.area[{{ loop.index0 }}].ranges    {{ area.get('ranges', []) | length }}    msg=ospfv3_ipv4.areas.ranges length
{% if area.ranges is defined and area.get('ranges', [])|length > 0 %}
{% for range in area.ranges | default([]) %}
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].ranges[{{ loop.index0 }}].network.address    {{ range.network_address | default('not_defined') }}    {{ range.network_address_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.ranges.ip_address
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].ranges[{{ loop.index0 }}].network.mask    {{ range.subnet_mask | default('not_defined') }}    {{ range.subnet_mask_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.ranges.subnet_mask
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].ranges[{{ loop.index0 }}].cost    {{ range.cost | default('not_defined') }}    not_defined    msg=ospfv3_ipv4.areas.ranges.cost
    Should Be Equal Value Json Yaml    ${ospfv3_ipv4_feature}    data.area[{{ area_index }}].ranges[{{ loop.index0 }}].noAdvertise    {{ range.no_advertise | default('not_defined') }}    {{ range.no_advertise_variable | default('not_defined') }}    msg=ospfv3_ipv4.areas.ranges.no_advertise
{% endfor %}
{% endif %}

{% endfor %}
{% endif %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}