*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Local Application List
Name            Policy Object Profile Security Local Application List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_local_application_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_local_application_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security Local Application Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_local_application_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-localapp
    Set Suite Variable    ${security_local_application_raw}


{% for security_local_application_list in sdwan.feature_profiles.policy_object_profile.security_local_application_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Local Application List Feature {{ security_local_application_list.name }}

    ${security_local_application_list}=    Json Search    ${security_local_application_raw.json()}    data[?payload.name=='{{ security_local_application_list.name }}'] | [0].payload
    Run Keyword If    $security_local_application_list is None    Fail    Feature '{{ security_local_application_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_local_application_list}    name    {{ security_local_application_list.name }}    msg=name

    ${app_list}=    Create List    {{ security_local_application_list.get('applications', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_local_application_list}    data.entries[].app.value    ${app_list}    msg=applications

    ${app_family_list}=    Create List    {{ security_local_application_list.get('application_families', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_local_application_list}    data.entries[].appFamily.value    ${app_family_list}    msg=application families

{% endfor %}

{% endif %}