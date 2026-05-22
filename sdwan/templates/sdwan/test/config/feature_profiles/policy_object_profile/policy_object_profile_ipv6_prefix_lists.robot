*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration IPv6 Prefix List
Name            Policy Object Profile IPv6 Prefix List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    ipv6_prefix_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.ipv6_prefix_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get IPv6 Prefix Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${ipv6_prefix_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/ipv6-prefix
    Set Suite Variable    ${ipv6_prefix_raw}


{% for ipv6_prefix_list in sdwan.feature_profiles.policy_object_profile.ipv6_prefix_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} IPv6 Prefix List Feature {{ ipv6_prefix_list.name }}

    ${ipv6_prefix_list}=    Json Search    ${ipv6_prefix_raw.json()}    data[?payload.name=='{{ ipv6_prefix_list.name }}'] | [0].payload
    Run Keyword If    $ipv6_prefix_list is None    Fail    Feature '{{ ipv6_prefix_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${ipv6_prefix_list}    name    {{ ipv6_prefix_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ipv6_prefix_list}    description    {{ ipv6_prefix_list.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json List Length    ${ipv6_prefix_list}    data.entries    {{ ipv6_prefix_list.get('entries', []) | length }}    msg=entries length
{% if ipv6_prefix_list.get('entries', []) | length > 0 %}
    Log     === Entries List ===
{% for entry in ipv6_prefix_list.entries | default([]) %}

    {% set ip_list = entry.prefix.split('/') %}
    Should Be Equal Value Json Yaml    ${ipv6_prefix_list}    data.entries[{{ loop.index0 }}].ipv6Address    {{ ip_list[0] | default('not_defined') }}    not_defined    msg=ipv6 address
    Should Be Equal Value Json Yaml    ${ipv6_prefix_list}    data.entries[{{ loop.index0 }}].ipv6PrefixLength    {{ ip_list[1] | default('not_defined') }}    not_defined    msg=ipv6 prefix length

    Should Be Equal Value Json Yaml    ${ipv6_prefix_list}    data.entries[{{ loop.index0 }}].geRangePrefixLength    {{ entry.ge | default('not_defined') }}    not_defined    msg=ge range prefix length
    Should Be Equal Value Json Yaml    ${ipv6_prefix_list}    data.entries[{{ loop.index0 }}].leRangePrefixLength    {{ entry.le | default('not_defined') }}    not_defined    msg=le range prefix length

{% endfor %}
{% endif %}


{% endfor %}

{% endif %}