*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Mirror List
Name            Policy Object Profile Mirror List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    mirrors
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.mirrors is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Mirror Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${mirror_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/mirror
    Set Suite Variable    ${mirror_raw}


{% for mirror in sdwan.feature_profiles.policy_object_profile.mirrors | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Mirror List Feature {{ mirror.name }}

    ${mirror}=    Json Search    ${mirror_raw.json()}    data[?payload.name=='{{ mirror.name }}'] | [0].payload
    Run Keyword If    $mirror is None    Fail    Feature '{{ mirror.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${mirror}    name    {{ mirror.name }}    msg=name
    Should Be Equal Value Json Special_String    ${mirror}    description    {{ mirror.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${mirror}    data.entries[0].remoteDestIp    {{ mirror.remote_destination_ip | default('not_defined') }}    not_defined    msg=remote destination ip
    Should Be Equal Value Json Yaml    ${mirror}    data.entries[0].sourceIp    {{ mirror.source_ip | default('not_defined') }}    not_defined    msg=source ip

{% endfor %}

{% endif %}