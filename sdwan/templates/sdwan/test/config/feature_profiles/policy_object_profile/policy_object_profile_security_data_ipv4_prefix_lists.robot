*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Data IPv4 Prefix List
Name            Policy Object Profile Security Data IPv4 Prefix List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_data_ipv4_prefix_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_data_ipv4_prefix_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security Data IPv4 Prefix Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_data_ipv4_prefix_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-data-ip-prefix
    Set Suite Variable    ${security_data_ipv4_prefix_raw}


{% for security_data_ipv4_prefix_list in sdwan.feature_profiles.policy_object_profile.security_data_ipv4_prefix_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Data IPv4 Prefix List Feature {{ security_data_ipv4_prefix_list.name }}

    ${security_data_ipv4_prefix_list}=    Json Search    ${security_data_ipv4_prefix_raw.json()}    data[?payload.name=='{{ security_data_ipv4_prefix_list.name }}'] | [0].payload
    Run Keyword If    $security_data_ipv4_prefix_list is None    Fail    Feature '{{ security_data_ipv4_prefix_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_data_ipv4_prefix_list}    name    {{ security_data_ipv4_prefix_list.name }}    msg=name

    Should Be Equal Value Json List Length    ${security_data_ipv4_prefix_list}    data.entries    {{ security_data_ipv4_prefix_list.get('prefixes', []) | length }}    msg=prefixes length
{% if security_data_ipv4_prefix_list.get('prefixes', []) | length > 0 %}
    Log     === Prefixes List ===
{% for prefix in security_data_ipv4_prefix_list.prefixes | default([]) %}
    Should Be Equal Value Json Yaml    ${security_data_ipv4_prefix_list}    data.entries[{{ loop.index0 }}].ipPrefix    {{ prefix | default('not_defined') }}    not_defined    msg=ipv4 address
{% endfor %}
{% endif %}


{% endfor %}

{% endif %}