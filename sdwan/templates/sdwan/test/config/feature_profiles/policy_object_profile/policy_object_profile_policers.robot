*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Policer List
Name            Policy Object Profile Policer List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    policers
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles.policy_object_profile.policers is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Policer Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${policer_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/policer
    Set Suite Variable    ${policer_raw}


{% for policer in sdwan.feature_profiles.policy_object_profile.policers | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Policer List Feature {{ policer.name }}

    ${policer}=    Json Search    ${policer_raw.json()}    data[?payload.name=='{{ policer.name }}'] | [0].payload
    Run Keyword If    $policer is None    Fail    Feature '{{ policer.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${policer}    name    {{ policer.name }}    msg=name
    Should Be Equal Value Json Special_String    ${policer}    description    {{ policer.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${policer}    data.entries[0].burst    {{ policer.burst_bytes | default('not_defined') }}    not_defined    msg=burst bytes
    Should Be Equal Value Json Yaml    ${policer}    data.entries[0].exceed    {{ policer.exceed_action | default('not_defined') }}    not_defined    msg=exceed action
    Should Be Equal Value Json Yaml    ${policer}    data.entries[0].rate    {{ policer.rate_bps | default('not_defined') }}    not_defined    msg=rate bps

{% endfor %}

{% endif %}