*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security IPS Signature List
Name            Policy Object Profile Security IPS Signature List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_ips_signature_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_ips_signature_lists is defined %}

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


{% for security_ips_signature_list in sdwan.feature_profiles.policy_object_profile.security_ips_signature_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security IPS Signature List Feature {{ security_ips_signature_list.name }}

    ${security_ips_signature_list}=    Json Search    ${security_ips_signature_raw.json()}    data[?payload.name=='{{ security_ips_signature_list.name }}'] | [0].payload
    Run Keyword If    $security_ips_signature_list is None    Fail    Feature '{{ security_ips_signature_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_ips_signature_list}    name    {{ security_ips_signature_list.name }}    msg=name

    Should Be Equal Value Json List Length    ${security_ips_signature_list}    data.entries    {{ security_ips_signature_list.get('entries', []) | length }}    msg=entries length
{% if security_ips_signature_list.get('entries', []) | length > 0 %}
    Log     === Entries List ===
{% for entry in security_ips_signature_list.entries | default([]) %}
    Should Be Equal Value Json Yaml    ${security_ips_signature_list}    data.entries[{{ loop.index0 }}].generatorId    {{ entry.generator_id | default('not_defined') }}    not_defined    msg=generator_id
    Should Be Equal Value Json Yaml    ${security_ips_signature_list}    data.entries[{{ loop.index0 }}].signatureId    {{ entry.signature_id | default('not_defined') }}    not_defined    msg=signature_id
{% endfor %}
{% endif %}


{% endfor %}

{% endif %}