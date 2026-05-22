*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Extended Community List
Name            Policy Object Profile Extended Community List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    extended_community_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.extended_community_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Extended Community Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${extended_community_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/ext-community
    Set Suite Variable    ${extended_community_raw}


{% for extended_community_list in sdwan.feature_profiles.policy_object_profile.extended_community_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Extended Community List Feature {{ extended_community_list.name }}

    ${extended_community_list}=    Json Search    ${extended_community_raw.json()}    data[?payload.name=='{{ extended_community_list.name }}'] | [0].payload
    Run Keyword If    $extended_community_list is None    Fail    Feature '{{ extended_community_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${extended_community_list}    name    {{ extended_community_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${extended_community_list}    description    {{ extended_community_list.description | default('not_defined') | normalize_special_string }}    msg=description

    ${extended_communities_list}=    Create List    {{ extended_community_list.get('extended_communities', []) | join('   ') }}
    # Extract features from the JSON
    ${extended_communities_list_json}=    Evaluate    [ item['extCommunity']['value'] for item in ${extended_community_list['data']['entries']} if 'extCommunity' in item and 'value' in item['extCommunity'] ]
    Lists Should Be Equal    ${extended_communities_list}    ${extended_communities_list_json}    ignore_order=True    msg=extended communities

{% endfor %}

{% endif %}
