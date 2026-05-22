*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration AS Path List
Name            Policy Object Profile AS Path List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    as_path_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.as_path_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get AS Path Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${as_path_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/as-path
    Set Suite Variable    ${as_path_raw}


{% for as_path_list in sdwan.feature_profiles.policy_object_profile.as_path_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} AS Path List Feature {{ as_path_list.name }}

    ${as_path_list}=    Json Search    ${as_path_raw.json()}    data[?payload.name=='{{ as_path_list.name }}'] | [0].payload
    Run Keyword If    $as_path_list is None    Fail    Feature '{{ as_path_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${as_path_list}    name    {{ as_path_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${as_path_list}    description    {{ as_path_list.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${as_path_list}    data.asPathListNum    {{ as_path_list.id | default('not_defined') }}    not_defined    msg=as path list num

    ${as_paths_list}=    Create List    {{ as_path_list.get('as_paths', []) | join('   ') }}
    # Extract features from the JSON
    ${as_paths_list_json}=    Evaluate    [ item['asPath']['value'] for item in ${as_path_list['data']['entries']} if 'asPath' in item and 'value' in item['asPath'] ]
    Lists Should Be Equal    ${as_paths_list}    ${as_paths_list_json}    ignore_order=True    msg=as paths

{% endfor %}

{% endif %}