*** Settings ***
Documentation   Verify Service Feature Profile Configuration Route Policies
Name            Service Profiles Route Policies
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    route_policies
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.service_profiles is defined %}
{% set profile_route_policy_list = [] %}
{% for profile in sdwan.feature_profiles.service_profiles %}
 {% if profile.route_policies is defined %}
  {% set _ = profile_route_policy_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_route_policy_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId

    ${as_path_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/as-path
    Set Suite Variable    ${as_path_list_res}
    ${expanded_community_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/expanded-community
    Set Suite Variable    ${expanded_community_list_res}
    ${extended_community_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/ext-community
    Set Suite Variable    ${extended_community_list_res}
    ${ipv4_prefix_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/prefix
    Set Suite Variable    ${ipv4_prefix_list_res}
    ${ipv6_prefix_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/ipv6-prefix
    Set Suite Variable    ${ipv6_prefix_list_res}
    ${standard_community_list_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/standard-community
    Set Suite Variable    ${standard_community_list_res}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.route_policies is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} Route Policy Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${service_route_policy_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/route-policy
    Set Suite Variable    ${service_route_policy_res}
    ${service_route_policy}=    Json Search List    ${service_route_policy_res.json()}    data[].payload
    Run Keyword If    ${service_route_policy} == []    Fail    Route Policy feature(s) expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_route_policy}

{% for route_policy in profile.route_policies | default([]) %}
    Log    === Route Policy: {{ route_policy.name }} ===

    # for each route policy find the corresponding one in the json and check parameters:
    ${route_policy_feature}=    Json Search    ${service_route_policy}    [?name=='{{ route_policy.name }}'] | [0]
    Run Keyword If    $route_policy_feature is None    Fail    Route Policy feature '{{ route_policy.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${route_policy_feature}    name    {{ route_policy.name }}    msg=name
    Should Be Equal Value Json Special_String    ${route_policy_feature}    description    {{ route_policy.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json String    ${route_policy_feature}    data.defaultAction.value   {{ route_policy.default_action }}    msg=defaultAction

    Should Be Equal Value Json List Length    ${route_policy_feature}    data.sequences    {{ route_policy.get('sequences', []) | length }}    msg=sequences length
{% if route_policy.get('sequences', []) | length > 0 %}
    Log    === Sequences List ===
{% for sequence in route_policy.sequences | default([]) %}
    Log    === Sequence {{ sequence.id }} ===
    ${sequence}=    Json Search    ${route_policy_feature}    data.sequences[?sequenceId.value==`{{ sequence.id }}`] | [0]
    Run Keyword If    $sequence is None    Fail    Route Policy sequence ID {{ sequence.id }} expected to be configured on the Manager

    Should Be Equal Value Json Yaml    ${sequence}    sequenceId    {{ sequence.id }}    not_defined    msg=route_policy.sequence.id
    Should Be Equal Value Json Yaml    ${sequence}    sequenceName    {{ sequence.name | default(defaults.sdwan.feature_profiles.service_profiles.route_policies.sequences.name ) }}    not_defined    msg=route_policy.sequence.name
    Should Be Equal Value Json Yaml    ${sequence}    baseAction    {{ sequence.base_action | default('not_defined') }}    not_defined    msg=route_policy.sequence.base_action

    {% set protocol = sequence.get('protocol', defaults.sdwan.feature_profiles.service_profiles.route_policies.sequences.protocol) %}
    Should Be Equal Value Json Yaml    ${sequence}    protocol    {{ protocol.upper() }}    not_defined    msg=route_policy.sequence.protocol

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].asPathList.refId.value    ${as_path_list_res.json()}    {{ sequence.match_entries.as_path_list | default('not_defined') }}    route_policy.sequence.match_entries.as_path_list

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].bgpLocalPreference    {{ sequence.match_entries.bgp_local_preference | default('not_defined') }}    not_defined    msg=route_policy.sequence.match_entries.bgp_local_preference

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].communityList.expandedCommunityList.refId.value    ${expanded_community_list_res.json()}    {{ sequence.match_entries.expanded_community_list | default('not_defined') }}    route_policy.sequence.match_entries.expanded_community_list

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].extCommunityList.refId.value    ${extended_community_list_res.json()}    {{ sequence.match_entries.extended_community_list | default('not_defined') }}    route_policy.sequence.match_entries.extended_community_list

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].ipv4Address.refId.value    ${ipv4_prefix_list_res.json()}    {{ sequence.match_entries.ipv4_address_prefix_list | default('not_defined') }}    route_policy.sequence.match_entries.ipv4_address_prefix_list

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].ipv4NextHop.refId.value    ${ipv4_prefix_list_res.json()}    {{ sequence.match_entries.ipv4_next_hop_prefix_list | default('not_defined') }}    route_policy.sequence.match_entries.ipv4_next_hop_prefix_list

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].ipv6Address.refId.value    ${ipv6_prefix_list_res.json()}    {{ sequence.match_entries.ipv6_address_prefix_list | default('not_defined') }}    route_policy.sequence.match_entries.ipv6_address_prefix_list

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].ipv6NextHop.refId.value    ${ipv6_prefix_list_res.json()}    {{ sequence.match_entries.ipv6_next_hop_prefix_list | default('not_defined') }}    route_policy.sequence.match_entries.ipv6_next_hop_prefix_list

    ${configured_standard_community_list_refids}=    Json Search List    ${sequence}    matchEntries[0].communityList.standardCommunityList[*].refId.value
    ${configured_standard_community_list_names}=    Create List
    FOR    ${refid}    IN    @{configured_standard_community_list_refids}
        ${profile_standard_community_list}=    Json Search String    ${standard_community_list_res.json()}    data[?parcelId=='${refid}'].payload.name | [0]
        Append To List    ${configured_standard_community_list_names}    ${profile_standard_community_list}
    END
    ${expected_standard_community_list_names}=    Create List
{% for expected_community_list in sequence.get('match_entries', {}).get('standard_community_lists', []) | default([]) %}
    Append To List    ${expected_standard_community_list_names}    {{ expected_community_list }}
{% endfor %}
    Lists Should Be Equal    ${expected_standard_community_list_names}    ${configured_standard_community_list_names}   ignore_order=True    values=False    msg=route_policy.sequence.match_entries.standard_community_lists expected: '${expected_standard_community_list_names}' and got: '${configured_standard_community_list_names}'

    {% set criteria = sequence.get('match_entries', {}).get('standard_community_lists_criteria', 'not_defined') %}
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].communityList.criteria    {{ criteria.upper() if criteria != 'not_defined' else 'not_defined' }}    not_defined    msg=route_policy.sequence.match_entries.standard_community_lists_criteria

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setLocalPreference    {{ sequence.actions.bgp_local_preference | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.bgp_local_preference

    ${community_list}=    Create List    {{ sequence.get('actions', {}).get('communities', []) | join('    ') }}
    # Replace "local-as" with "local-AS" in the community_list
    ${community_list}=    Evaluate    [item if item != "local-as" else "local-AS" for item in ${community_list}]
    ${community_list}=    Set Variable If    ${community_list} == []    not_defined    ${community_list}
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setCommunity.community    ${community_list}    {{ sequence.actions.communities_variable | default('not_defined') }}    msg=route_policy.sequence.actions.communities

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setCommunity.additive    {{ sequence.actions.communities_additive | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.communities_additive

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setIpv4NextHop    {{ sequence.actions.ipv4_next_hop | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.ipv4_next_hop

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setIpv6NextHop    {{ sequence.actions.ipv6_next_hop | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.ipv6_next_hop

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setMetric    {{ sequence.actions.metric | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.metric

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setMetricType    {{ sequence.actions.metric_type | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.metric_type

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setOmpTag    {{ sequence.actions.omp_tag | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.omp_tag

    {% set origin = sequence.get('actions', {}).get('origin', 'not_defined') %}
    {% if origin == 'incomplete' %}
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setOrigin    Incomplete    not_defined    msg=route_policy.sequence.actions.origin
    {% else %}
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setOrigin    {{ origin.upper() if origin != 'not_defined' else 'not_defined' }}    not_defined    msg=route_policy.sequence.actions.origin
    {% endif %}

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setOspfTag    {{ sequence.actions.ospf_tag | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.ospf_tag

    ${prepend_aspaths_list}=    Create List    {{ sequence.get('actions', {}).get('prepend_as_paths', []) | join('    ') }}
    ${prepend_aspaths_list}=    Set Variable If    ${prepend_aspaths_list} == []    not_defined    ${prepend_aspaths_list}
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setAsPath.prepend    ${prepend_aspaths_list}    not_defined    msg=route_policy.sequence.actions.prepend_as_paths

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setWeight    {{ sequence.actions.weight | default('not_defined') }}    not_defined    msg=route_policy.sequence.actions.weight

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endif %}