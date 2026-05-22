*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Standard Community List
Name            Policy Object Profile Standard Community List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    standard_community_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles.policy_object_profile.standard_community_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Standard Community Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${standard_community_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/standard-community
    Set Suite Variable    ${standard_community_raw}


{% for standard_community_list in sdwan.feature_profiles.policy_object_profile.standard_community_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Standard Community List Feature {{ standard_community_list.name }}

    ${standard_community_list}=    Json Search    ${standard_community_raw.json()}    data[?payload.name=='{{ standard_community_list.name }}'] | [0].payload
    Run Keyword If    $standard_community_list is None    Fail    Feature '{{ standard_community_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json Special_String    ${standard_community_list}    description    {{ standard_community_list.description | default('not_defined') | normalize_special_string }}    msg=description

    ${standard_communities_list}=    Create List    {{ standard_community_list.get('standard_communities', []) | join('   ') }}
    # Extract features from the JSON
    ${standard_communities_list_json}=    Evaluate    [ item['standardCommunity']['value'] for item in ${standard_community_list['data']['entries']} if 'standardCommunity' in item and 'value' in item['standardCommunity'] ]
    Lists Should Be Equal    ${standard_communities_list}    ${standard_communities_list_json}    ignore_order=True    msg=standard communities

{% endfor %}

{% endif %}