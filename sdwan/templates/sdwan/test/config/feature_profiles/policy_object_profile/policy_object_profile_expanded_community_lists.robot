*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Expanded Community List
Name            Policy Object Profile Expanded Community List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    expanded_community_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.expanded_community_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Expanded Community Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${expanded_community_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/expanded-community
    Set Suite Variable    ${expanded_community_raw}


{% for expanded_community_list in sdwan.feature_profiles.policy_object_profile.expanded_community_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Expanded Community List Feature {{ expanded_community_list.name }}

    ${expanded_community_list}=    Json Search    ${expanded_community_raw.json()}    data[?payload.name=='{{ expanded_community_list.name }}'] | [0].payload
    Run Keyword If    $expanded_community_list is None    Fail    Feature '{{ expanded_community_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${expanded_community_list}    name    {{ expanded_community_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${expanded_community_list}    description    {{ expanded_community_list.description | default('not_defined') | normalize_special_string }}    msg=description

    ${expanded_communities_list}=    Create List    {{ expanded_community_list.get('expanded_communities', []) | join('   ') }}
    ${expanded_communities_list}=    Set Variable If    ${expanded_communities_list} == []    not_defined    ${expanded_communities_list}
    Should Be Equal Value Json Yaml    ${expanded_community_list}    data.expandedCommunityList    ${expanded_communities_list}    not_defined    msg=expanded communities

{% endfor %}

{% endif %}
