*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Forwarding Classes
Name            Policy Object Profile Forwarding Classes
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    forwarding_classes
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.forwarding_classes is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Forwarding Classes
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${forwarding_class_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/class
    Set Suite Variable    ${forwarding_class_raw}


{% for forwarding_class in sdwan.feature_profiles.policy_object_profile.forwarding_classes | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Forwarding Class Feature {{ forwarding_class.name }}

    ${forwarding_class}=    Json Search    ${forwarding_class_raw.json()}    data[?payload.name=='{{ forwarding_class.name }}'] | [0].payload
    Run Keyword If    $forwarding_class is None    Fail    Feature '{{ forwarding_class.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${forwarding_class}    name    {{ forwarding_class.name }}    msg=name
    Should Be Equal Value Json Special_String    ${forwarding_class}    description    {{ forwarding_class.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${forwarding_class}    data.entries[0].queue    {{ forwarding_class.queue | default('not_defined') }}    not_defined    msg=queue

{% endfor %}

{% endif %}