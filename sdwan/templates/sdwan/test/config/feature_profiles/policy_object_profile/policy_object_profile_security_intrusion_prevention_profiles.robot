*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Intrusion Prevention Profile
Name            Policy Object Profile Security Intrusion Prevention Profile
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_intrusion_prevention_profiles
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_intrusion_prevention_profiles is defined %}
*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}

Get Security IPS Signature Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_ips_signature_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-ipssignature
    Set Suite Variable    ${security_ips_signature_raw}

Get Security Intrusion Prevention Profiles
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_intrusion_prevention_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/intrusion-prevention
    Set Suite Variable    ${security_intrusion_prevention_profiles_raw}

{% for security_intrusion_prevention_profile in sdwan.feature_profiles.policy_object_profile.security_intrusion_prevention_profiles | default([]) %}
Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Intrusion Prevention Profile Feature {{ security_intrusion_prevention_profile.name }}

    ${security_intrusion_prevention_profile}=    Json Search    ${security_intrusion_prevention_profiles_raw.json()}    data[?payload.name=='{{ security_intrusion_prevention_profile.name }}'] | [0].payload
    Run Keyword If    $security_intrusion_prevention_profile is None    Fail    Feature '{{ security_intrusion_prevention_profile.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager
    Should Be Equal Value Json String    ${security_intrusion_prevention_profile}    name    {{ security_intrusion_prevention_profile.name }}    msg=name

    Should Be Equal Value Json Yaml    ${security_intrusion_prevention_profile}    data.signatureSet    {{ security_intrusion_prevention_profile.signature_set | default('not_defined') }}    not_defined    msg=signature_set
    Should Be Equal Value Json Yaml    ${security_intrusion_prevention_profile}    data.inspectionMode    {{ security_intrusion_prevention_profile.inspection_mode | default('not_defined') }}    not_defined    msg=inspection_mode
    Should Be Equal Value Json Yaml    ${security_intrusion_prevention_profile}    data.logLevel    {{ security_intrusion_prevention_profile.alert_log_level | default(defaults.sdwan.feature_profiles.policy_object_profile.security_intrusion_prevention_profiles.alert_log_level) }}    not_defined    msg=alert_log_level
    Should Be Equal Value Json Yaml    ${security_intrusion_prevention_profile}    data.customSignature    {{ security_intrusion_prevention_profile.custom_signature_set | default(defaults.sdwan.feature_profiles.policy_object_profile.security_intrusion_prevention_profiles.custom_signature_set) }}    not_defined    msg=custom_signature_set
    Should Be Equal Referenced Object Name    ${security_intrusion_prevention_profile}    data.signatureAllowedList.refId.value    ${security_ips_signature_raw.json()}    {{ security_intrusion_prevention_profile.signature_allow_list | default('not_defined') }}    signature_allow_list

{% endfor %}

{% endif %}