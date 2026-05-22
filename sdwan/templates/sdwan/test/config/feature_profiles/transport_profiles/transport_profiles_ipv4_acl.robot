*** Settings ***
Documentation   Verify Transport Feature Profile Configuration IPv4 ACL
Name            Transport Profiles IPv4 ACL
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    ipv4_acls
Resource        ../../../sdwan_common.resource


{% set profile_ipv4_acl_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('transport_profiles', {}) %}
 {% if profile.ipv4_acls is defined %}
  {% set _ = profile_ipv4_acl_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ipv4_acl_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId

    ${ipv4_data_prefix_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/data-prefix
    Set Suite Variable    ${ipv4_data_prefix_res}

    ${mirror_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/mirror
    Set Suite Variable    ${mirror_res}

    ${policer_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/policer
    Set Suite Variable    ${policer_res}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.ipv4_acls is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} IPv4 ACL Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_ipv4_acl_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/ipv4-acl
    Set Suite Variable    ${transport_ipv4_acl_res}
    ${transport_acl}=    Json Search List    ${transport_ipv4_acl_res.json()}    data[].payload
    Run Keyword If    ${transport_acl} == []    Fail    IPv4 ACL feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_acl}

{% for acl in profile.ipv4_acls | default([]) %}
    Log    === IPv4 ACL: {{ acl.name }} ===

    # for each acl find the corresponding one in the json and check parameters:
    ${acl_feature}=    Json Search    ${transport_acl}    [?name=='{{ acl.name }}'] | [0]
    Run Keyword If    $acl_feature is None    Fail    IPv4 ACL feature '{{ acl.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${acl_feature}    name    {{ acl.name }}    msg=name
    Should Be Equal Value Json Special_String    ${acl_feature}    description    {{ acl.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${acl_feature}    data.defaultAction    {{ acl.default_action }}    not_defined    msg=acl.default_action

    Should Be Equal Value Json List Length    ${acl_feature}    data.sequences    {{ acl.get('sequences', []) | length }}    msg=sequences length
{% if acl.get('sequences', []) | length > 0 %}
    Log    === Sequences List ===
{% for sequence in acl.sequences | default([]) %}
    Log    === Sequence {{ sequence.id }} ===
    ${sequence}=    Json Search    ${acl_feature}    data.sequences[?sequenceId.value==`{{ sequence.id }}`] | [0]
    Run Keyword If    $sequence is None    Fail    IPv4 ACL sequence ID {{ sequence.id }} expected to be configured on the Manager

    Should Be Equal Value Json Yaml    ${sequence}    sequenceId    {{ sequence.id }}    not_defined    msg=acl.sequence.id
    Should Be Equal Value Json Yaml    ${sequence}    sequenceName    {{ sequence.name | default(defaults.sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.name ) }}    not_defined    msg=acl.sequence.name
{% if 'actions' not in sequence %}
    Should Be Equal Value Json Yaml    ${sequence}    baseAction    {{ sequence.base_action | default('not_defined') }}    not_defined    msg=acl.sequence.base_action
{% endif %}

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].destinationDataPrefix.destinationIpPrefix    {{ sequence.match_entries.destination_data_prefix | default('not_defined') }}    {{ sequence.match_entries.destination_data_prefix_variable | default('not_defined') }}    msg=acl.sequence.match_entries.destination_data_prefix

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].destinationDataPrefix.destinationDataPrefixList.refId.value    ${ipv4_data_prefix_res.json()}    {{ sequence.match_entries.destination_data_prefix_list | default('not_defined') }}    acl.sequence.match_entries.destination_data_prefix_list

    ${configured_destination_ports}=    Json Search List    ${sequence}    matchEntries[0].destinationPorts[*].destinationPort.value
    ${configured_destination_ports}=    Evaluate    [str(item) for item in $configured_destination_ports]
    ${expected_destination_ports}=    Create List
{% for destination_port in sequence.get('match_entries', {}).get('destination_ports', []) | default([]) %}
    Append To List    ${expected_destination_ports}    {{ destination_port | string }}
{% endfor %}
    Lists Should Be Equal    ${expected_destination_ports}    ${configured_destination_ports}   ignore_order=True    values=False    msg=acl.sequence.match_entries.destination_ports expected: '${expected_destination_ports}' and got: '${configured_destination_ports}'

    ${expected_dscps}=    Set Variable If    {{ sequence.get('match_entries', {}).get('dscps', []) | length == 0 }}    not_defined    {{ sequence.get('match_entries', {}).get('dscps', []) }}
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].dscp    ${expected_dscps}    not_defined    msg=acl.sequence.match_entries.dscps

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].icmpMsg    {{ sequence.match_entries.icmp_messages | default('not_defined') }}    not_defined    msg=acl.sequence.match_entries.icmp_messages
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].packetLength    {{ sequence.match_entries.packet_length | default('not_defined') }}    not_defined    msg=acl.sequence.match_entries.packet_length
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].protocol    {{ sequence.match_entries.protocols | default('not_defined') }}    not_defined    msg=acl.sequence.match_entries.protocols

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].sourceDataPrefix.sourceIpPrefix    {{ sequence.match_entries.source_data_prefix | default('not_defined') }}    {{ sequence.match_entries.source_data_prefix_variable | default('not_defined') }}    msg=acl.sequence.match_entries.source_data_prefix

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries[0].sourceDataPrefix.sourceDataPrefixList.refId.value    ${ipv4_data_prefix_res.json()}    {{ sequence.match_entries.source_data_prefix_list | default('not_defined') }}    acl.sequence.match_entries.source_data_prefix_list

    ${configured_source_ports}=    Json Search List    ${sequence}    matchEntries[0].sourcePorts[*].sourcePort.value
    ${configured_source_ports}=    Evaluate    [str(item) for item in $configured_source_ports]
    ${expected_source_ports}=    Create List
{% for source_port in sequence.get('match_entries', {}).get('source_ports', []) | default([]) %}
    Append To List    ${expected_source_ports}    {{ source_port | string }}
{% endfor %}
    Lists Should Be Equal    ${expected_source_ports}    ${configured_source_ports}   ignore_order=True    values=False    msg=acl.sequence.match_entries.source_ports expected: '${expected_source_ports}' and got: '${configured_source_ports}'

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries[0].tcp    {{ sequence.match_entries.tcp_state | default('not_defined') }}    not_defined    msg=acl.sequence.match_entries.tcp_state

    Should Be Equal Value Json Yaml    ${sequence}    (actions[0].accept.counterName || actions[0].drop.counterName)    {{ sequence.actions.counter_name | default('not_defined') }}    not_defined    msg=acl.sequence.actions.counter_name
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setDscp    {{ sequence.actions.dscp | default('not_defined') }}    not_defined    msg=acl.sequence.actions.dscp
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setNextHop    {{ sequence.actions.ipv4_next_hop | default('not_defined') }}    not_defined    msg=acl.sequence.actions.ipv4_next_hop
    Should Be Equal Value Json Yaml    ${sequence}    (actions[0].accept.log || actions[0].drop.log)    {{ sequence.actions.log | default('not_defined') }}    not_defined    msg=acl.sequence.actions.log

    Should Be Equal Referenced Object Name    ${sequence}    actions[0].accept.mirror.refId.value    ${mirror_res.json()}    {{ sequence.actions.mirror | default('not_defined') }}    acl.sequence.actions.mirror

    Should Be Equal Referenced Object Name    ${sequence}    actions[0].accept.policer.refId.value    ${policer_res.json()}    {{ sequence.actions.policer | default('not_defined') }}    acl.sequence.actions.policer

    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setServiceChain.fallback    {{ sequence.actions.service_chain_fallback | default('not_defined') }}    {{ sequence.actions.service_chain_fallback_variable | default('not_defined') }}    msg=acl.sequence.actions.service_chain_fallback
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setServiceChain.serviceChainNumber    {{ sequence.actions.service_chain_name | default('not_defined') }}    {{ sequence.actions.service_chain_name_variable | default('not_defined') }}    msg=acl.sequence.actions.service_chain_name
    Should Be Equal Value Json Yaml    ${sequence}    actions[0].accept.setServiceChain.vpn    {{ sequence.actions.service_chain_vpn | default('not_defined') }}    {{ sequence.actions.service_chain_vpn_variable | default('not_defined') }}    msg=acl.sequence.actions.service_chain_vpn

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}
