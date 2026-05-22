*** Settings ***
Documentation   Verify Transport Feature Profile Configuration OSPF Features
Name            Transport Profiles OSPF Features
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    ospf
Resource        ../../../sdwan_common.resource


{% set profile_ospf_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('transport_profiles', {}) %}
 {% if profile.ospf_features is defined %}
  {% set _ = profile_ospf_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ospf_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.ospf_features is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} OSPF Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_ospf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/routing/ospf
    Set Suite Variable    ${transport_ospf_res}
    ${transport_ospf}=    Json Search List    ${transport_ospf_res.json()}    data[].payload
    Run Keyword If    ${transport_ospf} == []    Fail    OSPF feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_ospf}

    # Extract route policies since they might be used in OSPF
    ${route_policies_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/route-policy
    Set Suite Variable    ${route_policies_res}

{% for ospf in profile.ospf_features | default([]) %}
    Log    === OSPF: {{ ospf.name }} ===

    # for each ospf find the corresponding one in the json and check parameters:
    ${ospf_feature}=    Json Search    ${transport_ospf}    [?name=='{{ ospf.name }}'] | [0]
    Run Keyword If    $ospf_feature is None    Fail    OSPF feature '{{ ospf.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${ospf_feature}    name    {{ ospf.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ospf_feature}    description    {{ ospf.description | default('not_defined') | normalize_special_string }}    msg=description

    # Basic OSPF parameters
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.routerId    {{ ospf.router_id | default('not_defined') }}    {{ ospf.router_id_variable | default('not_defined') }}    msg=ospf.router_id
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.referenceBandwidth    {{ ospf.reference_bandwidth | default('not_defined') }}    {{ ospf.reference_bandwidth_variable | default('not_defined') }}    msg=ospf.reference_bandwidth
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.rfc1583    {{ ospf.rfc1583_compatibility | default('not_defined') }}    {{ ospf.rfc1583_compatibility_variable | default('not_defined') }}    msg=ospf.rfc1583_compatibility

    # Default route origination
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.originate    {{ ospf.default_originate | default('not_defined') }}    not_defined    msg=ospf.default_originate
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.always    {{ ospf.default_originate_always | default('not_defined') }}    {{ ospf.default_originate_always_variable | default('not_defined') }}    msg=ospf.default_originate_always
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.metric    {{ ospf.default_originate_metric | default('not_defined') }}    {{ ospf.default_originate_metric_variable | default('not_defined') }}    msg=ospf.default_originate_metric
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.metricType    {{ ospf.default_originate_metric_type | default('not_defined') }}    {{ ospf.default_originate_metric_type_variable | default('not_defined') }}    msg=ospf.default_originate_metric_type

    # Distance parameters
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.external    {{ ospf.distance_external | default('not_defined') }}    {{ ospf.distance_external_variable | default('not_defined') }}    msg=ospf.distance_external
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.interArea    {{ ospf.distance_inter_area | default('not_defined') }}    {{ ospf.distance_inter_area_variable | default('not_defined') }}    msg=ospf.distance_inter_area
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.intraArea    {{ ospf.distance_intra_area | default('not_defined') }}    {{ ospf.distance_intra_area_variable | default('not_defined') }}    msg=ospf.distance_intra_area

    # SPF timers
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.delay    {{ ospf.spf_calculation_delay | default('not_defined') }}    {{ ospf.spf_calculation_delay_variable | default('not_defined') }}    msg=ospf.spf_calculation_delay
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.initialHold    {{ ospf.spf_initial_hold_time | default('not_defined') }}    {{ ospf.spf_initial_hold_time_variable | default('not_defined') }}    msg=ospf.spf_initial_hold_time
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.maxHold    {{ ospf.spf_maximum_hold_time | default('not_defined') }}    {{ ospf.spf_maximum_hold_time_variable | default('not_defined') }}    msg=ospf.spf_maximum_hold_time

    # Route policy
    Should Be Equal Referenced Object Name    ${ospf_feature}    data.routePolicy.refId.value    ${route_policies_res.json()}    {{ ospf.route_policy | default('not_defined') }}    ospf.route_policy

    Log    =====Redistributes=====
    Should Be Equal Value Json List Length    ${ospf_feature}    data.redistribute    {{ ospf.get('redistributes', []) | length }}    msg=ospf.redistributes length
{% if ospf.redistributes is defined and ospf.get('redistributes', [])|length > 0 %}
{% for redistribute in ospf.redistributes | default([]) %}
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.redistribute[{{ loop.index0 }}].protocol    {{ redistribute.protocol | default('not_defined') }}    {{ redistribute.protocol_variable | default('not_defined') }}    msg=ospf.redistributes.protocol
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.redistribute[{{ loop.index0 }}].dia    {{ 'not_defined' if redistribute.get('dia', 'not_defined') == true else (redistribute.dia | default('not_defined')) }}    {{ redistribute.dia_variable | default('not_defined') }}    msg=ospf.redistributes.dia

    Should Be Equal Referenced Object Name    ${ospf_feature}    data.redistribute[{{ loop.index0 }}].routePolicy.refId.value    ${route_policies_res.json()}    {{ redistribute.route_policy | default('not_defined') }}    ospf.redistributes.route_policy
{% endfor %}
{% endif %}

    Log    =====Router LSA=====
    Should Be Equal Value Json List Length    ${ospf_feature}    data.routerLsa    {{ 1 if ospf.router_lsa_advertisement_type is defined else 0 }}    msg=ospf.router_lsa length
{% if ospf.router_lsa_advertisement_type is defined %}
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.routerLsa[0].adType    {{ ospf.router_lsa_advertisement_type | default('not_defined') }}    not_defined    msg=ospf.router_lsa_advertisement_type
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.routerLsa[0].time    {{ ospf.router_lsa_advertisement_time | default('not_defined') }}    not_defined    msg=ospf.router_lsa_advertisement_time
{% endif %}

    Log    =====Areas=====
    Should Be Equal Value Json List Length    ${ospf_feature}    data.area    {{ ospf.get('areas', []) | length }}    msg=ospf.areas length
{% if ospf.areas is defined and ospf.get('areas', [])|length > 0 %}
{% for area in ospf.areas | default([]) %}
{% set area_index = loop.index0 %}
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ loop.index0 }}].aNum    {{ area.number | default('not_defined') }}    {{ area.number_variable | default('not_defined') }}    msg=ospf.areas.number
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ loop.index0 }}].aType    {{ area.type | default('not_defined') }}    not_defined    msg=ospf.areas.type
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ loop.index0 }}].noSummary    {{ area.no_summary | default('not_defined') }}    {{ area.no_summary_variable | default('not_defined') }}    msg=ospf.areas.no_summary

    Log    =====Area {{ loop.index0 }} Interfaces=====
    Should Be Equal Value Json List Length    ${ospf_feature}    data.area[{{ loop.index0 }}].interface    {{ area.get('interfaces', []) | length }}    msg=ospf.areas.interfaces length
{% if area.interfaces is defined and area.get('interfaces', [])|length > 0 %}
{% for interface in area.interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].name    {{ interface.name | default('not_defined') }}    {{ interface.name_variable | default('not_defined') }}    msg=ospf.areas.interfaces.name
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].helloInterval    {{ interface.hello_interval | default('not_defined') }}    {{ interface.hello_interval_variable | default('not_defined') }}    msg=ospf.areas.interfaces.hello_interval
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].deadInterval    {{ interface.dead_interval | default('not_defined') }}    {{ interface.dead_interval_variable | default('not_defined') }}    msg=ospf.areas.interfaces.dead_interval
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].retransmitInterval    {{ interface.lsa_retransmit_interval | default('not_defined') }}    {{ interface.lsa_retransmit_interval_variable | default('not_defined') }}    msg=ospf.areas.interfaces.lsa_retransmit_interval
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].cost    {{ interface.cost | default('not_defined') }}    {{ interface.cost_variable | default('not_defined') }}    msg=ospf.areas.interfaces.cost
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].priority    {{ interface.designated_router_priority | default('not_defined') }}    {{ interface.designated_router_priority_variable | default('not_defined') }}    msg=ospf.areas.interfaces.designated_router_priority
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].network    {{ interface.network_type | default('not_defined') }}    {{ interface.network_type_variable | default('not_defined') }}    msg=ospf.areas.interfaces.network_type
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].passiveInterface    {{ interface.passive | default('not_defined') }}    {{ interface.passive_variable | default('not_defined') }}    msg=ospf.areas.interfaces.passive
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].type    {{ interface.authentication_type | default('not_defined') }}    {{ interface.authentication_type_variable | default('not_defined') }}    msg=ospf.areas.interfaces.authentication_type
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].interface[{{ loop.index0 }}].messageDigestKey    {{ interface.authentication_message_digest_key_id | default('not_defined') }}    {{ interface.authentication_message_digest_key_id_variable | default('not_defined') }}    msg=ospf.areas.interfaces.authentication_message_digest_key_id
    # Skip authentication_message_digest_key as it's write-only
{% endfor %}
{% endif %}

    Log    =====Area {{ loop.index0 }} Ranges=====
    Should Be Equal Value Json List Length    ${ospf_feature}    data.area[{{ loop.index0 }}].range    {{ area.get('ranges', []) | length }}    msg=ospf.areas.ranges length
{% if area.ranges is defined and area.get('ranges', [])|length > 0 %}
{% for range in area.ranges | default([]) %}
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].range[{{ loop.index0 }}].address.ipAddress    {{ range.network_address | default('not_defined') }}    {{ range.network_address_variable | default('not_defined') }}    msg=ospf.areas.ranges.network_address
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].range[{{ loop.index0 }}].address.subnetMask    {{ range.subnet_mask | default('not_defined') }}    {{ range.subnet_mask_variable | default('not_defined') }}    msg=ospf.areas.ranges.subnet_mask
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].range[{{ loop.index0 }}].cost    {{ range.cost | default('not_defined') }}    not_defined    msg=ospf.areas.ranges.cost
    Should Be Equal Value Json Yaml    ${ospf_feature}    data.area[{{ area_index }}].range[{{ loop.index0 }}].noAdvertise    {{ range.no_advertise | default('not_defined') }}    {{ range.no_advertise_variable | default('not_defined') }}    msg=ospf.areas.ranges.no_advertise
{% endfor %}
{% endif %}

{% endfor %}
{% endif %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}