*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Advanced Inspection Profile
Name            Policy Object Profile Security Advanced Inspection Profile
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_advanced_inspection_profiles
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles is defined %}
*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}

Get Security Advanced Malware Protection Profiles
    ${security_advanced_malware_protection_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/advanced-malware-protection
    Set Suite Variable    ${security_advanced_malware_protection_profiles_raw}

Get Security Intrusion Prevention Profiles
    ${security_intrusion_prevention_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/intrusion-prevention
    Set Suite Variable    ${security_intrusion_prevention_profiles_raw}

Get Security URL Filtering Profiles
    ${security_url_filtering_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/url-filtering
    Set Suite Variable    ${security_url_filtering_profiles_raw}

Get Security Advanced Inspection Profiles
    ${security_advanced_inspection_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/advanced-inspection-profile
    Set Suite Variable    ${security_advanced_inspection_profiles_raw}

{% set tls_action_map = {'decrypt': 'decrypt', 'never_decrypt': 'neverDecrypt', 'skip_decrypt': 'skipDecrypt'} %}
{% for security_advanced_inspection_profile in sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles | default([]) %}
Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Advanced Inspection Profile Feature {{ security_advanced_inspection_profile.name }}

    ${security_advanced_inspection_profile}=    Json Search    ${security_advanced_inspection_profiles_raw.json()}    data[?payload.name=='{{ security_advanced_inspection_profile.name }}'] | [0].payload
    Run Keyword If    $security_advanced_inspection_profile is None    Fail    Feature '{{ security_advanced_inspection_profile.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager
    Should Be Equal Value Json String               ${security_advanced_inspection_profile}    name           {{ security_advanced_inspection_profile.name }}    msg=name
    Should Be Equal Value Json Special_String       ${security_advanced_inspection_profile}    description    {{ security_advanced_inspection_profile.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${security_advanced_inspection_profile}           data.tlsDecryptionAction                      {{ tls_action_map.get(security_advanced_inspection_profile.tls_action, 'not_defined') }}    not_defined    msg=tls_action
    Should Be Equal Referenced Object Name    ${security_advanced_inspection_profile}    data.advancedMalwareProtection.refId.value    ${security_advanced_malware_protection_profiles_raw.json()}      {{ security_advanced_inspection_profile.advanced_malware_protection | default('not_defined') }}    advanced_malware_protection
    Should Be Equal Referenced Object Name    ${security_advanced_inspection_profile}    data.intrusionPrevention.refId.value          ${security_intrusion_prevention_profiles_raw.json()}             {{ security_advanced_inspection_profile.intrusion_prevention | default('not_defined') }}    intrusion_prevention
    Should Be Equal Referenced Object Name    ${security_advanced_inspection_profile}    data.urlFiltering.refId.value                 ${security_url_filtering_profiles_raw.json()}                    {{ security_advanced_inspection_profile.url_filtering | default('not_defined') }}    url_filtering

{% endfor %}

{% endif %}
