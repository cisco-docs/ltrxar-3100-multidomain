*** Settings ***
Documentation   Verify System Feature Profile Configuration IPv4 Device Access Policy
Name            System Profiles IPv4 Device Access Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    ipv4_device_access_policy
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_ipv4_device_access_policy_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.ipv4_device_access_policy is defined %}
  {% set _ = profile_ipv4_device_access_policy_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ipv4_device_access_policy_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}


Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId

    ${ipv4_data_prefix_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/data-prefix
    Set Suite Variable    ${ipv4_data_prefix_res}


{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.ipv4_device_access_policy is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} IPv4 Device Access Policy Feature {{ profile.ipv4_device_access_policy.name | default(defaults.sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_ipv4_device_access_policy_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/ipv4-device-access-policy
    ${system_ipv4_device_access_policy}=    Json Search    ${system_ipv4_device_access_policy_res.json()}    data[0].payload
    Run Keyword If    $system_ipv4_device_access_policy is None    Fail    Feature '{{profile.ipv4_device_access_policy.name}}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_ipv4_device_access_policy}

    Should Be Equal Value Json String    ${system_ipv4_device_access_policy}    name    {{ profile.ipv4_device_access_policy.name | default(defaults.sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_ipv4_device_access_policy}    description    {{ profile.ipv4_device_access_policy.description | default('not_defined') | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${system_ipv4_device_access_policy}    data.defaultAction.value    {{ profile.ipv4_device_access_policy.default_action | default('not_defined') }}     msg=default action

    Should Be Equal Value Json List Length    ${system_ipv4_device_access_policy}    data.sequences    {{ profile.ipv4_device_access_policy.get('sequences', []) | length }}    msg=sequences length
{% if profile.ipv4_device_access_policy.get('sequences', []) | length > 0 %}
    Log     === Sequences List ===
{% for sequence in profile.ipv4_device_access_policy.sequences | default([]) %}
    Log    === Sequence {{ sequence.id }} ===
    ${sequence}=    Json Search    ${system_ipv4_device_access_policy}    data.sequences[?sequenceId.value==`{{ sequence.id }}`] | [0]
    Run Keyword If    $sequence is None    Fail    IPv4 Device Access Policy sequence ID {{ sequence.id }} expected to be configured on the Manager

    Should Be Equal Value Json Yaml    ${sequence}    baseAction    {{ sequence.base_action | default('not_defined') }}    not_defined    msg=base action
    Should Be Equal Value Json Yaml    ${sequence}    sequenceId    {{ sequence.id | default('not_defined') }}    not_defined    msg=id
    Should Be Equal Value Json Yaml    ${sequence}    sequenceName    {{ sequence.name | default('not_defined') }}    not_defined    msg=name

    ${destination_data_prefixes_list}=    Create List    {{ sequence.match_entries.get('destination_data_prefixes', []) | join('   ') }}
    ${destination_data_prefixes_list}=    Set Variable If    ${destination_data_prefixes_list} == []    not_defined    ${destination_data_prefixes_list}
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries.destinationDataPrefix.destinationIpPrefixList    ${destination_data_prefixes_list}    {{ sequence.match_entries.destination_data_prefixes_variable | default('not_defined') }}    msg=destination data prefixes

    Should Be Equal Value Json Yaml    ${sequence}    matchEntries.destinationPort    {{ sequence.match_entries.destination_port | default('not_defined') }}    not_defined    msg=destination port

    ${source_data_prefixes_list}=    Create List    {{ sequence.match_entries.get('source_data_prefixes', []) | join('   ') }}
    ${source_data_prefixes_list}=    Set Variable If    ${source_data_prefixes_list} == []    not_defined    ${source_data_prefixes_list}
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries.sourceDataPrefix.sourceIpPrefixList    ${source_data_prefixes_list}    {{ sequence.match_entries.source_data_prefixes_variable | default('not_defined') }}    msg=source data prefixes

    ${source_ports_list}=    Create List    {{ sequence.match_entries.get('source_ports', []) | join('   ') }}
    ${source_ports_list}=    Set Variable If    ${source_ports_list} == []    not_defined    ${source_ports_list}
    Should Be Equal Value Json Yaml    ${sequence}    matchEntries.sourcePorts    ${source_ports_list}    not_defined    msg=source ports

    Should Be Equal Referenced Object Name    ${sequence}    matchEntries.destinationDataPrefix.destinationDataPrefixList.refId.value    ${ipv4_data_prefix_res.json()}    {{ sequence.match_entries.destination_data_prefix_list | default('not_defined') }}    destination data prefix list
    Should Be Equal Referenced Object Name    ${sequence}    matchEntries.sourceDataPrefix.sourceDataPrefixList.refId.value    ${ipv4_data_prefix_res.json()}    {{ sequence.match_entries.source_data_prefix_list | default('not_defined') }}    source data prefix list

{% endfor %}
{% endif %}



{% endif %}
{% endfor %}

{% endif %}

{% endif %}