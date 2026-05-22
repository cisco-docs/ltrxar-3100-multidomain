*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security FQDN List
Name            Policy Object Profile Security FQDN List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_fqdn_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_fqdn_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security FQDN Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_fqdn_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-fqdn
    Set Suite Variable    ${security_fqdn_raw}


{% for security_fqdn_list in sdwan.feature_profiles.policy_object_profile.security_fqdn_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security FQDN List Feature {{ security_fqdn_list.name }}

    ${security_fqdn_list}=    Json Search    ${security_fqdn_raw.json()}    data[?payload.name=='{{ security_fqdn_list.name }}'] | [0].payload
    Run Keyword If    $security_fqdn_list is None    Fail    Feature '{{ security_fqdn_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_fqdn_list}    name    {{ security_fqdn_list.name }}    msg=name

    Should Be Equal Value Json List Length    ${security_fqdn_list}    data.entries    {{ security_fqdn_list.get('fqdns', []) | length }}    msg=fqdns length
{% if security_fqdn_list.get('fqdns', []) | length > 0 %}
    Log     === FQDN List ===
{% for fqdn in security_fqdn_list.fqdns | default([]) %}
    Should Be Equal Value Json Yaml    ${security_fqdn_list}    data.entries[{{ loop.index0 }}].pattern    {{ fqdn | default('not_defined') }}    not_defined    msg=fqdn
{% endfor %}
{% endif %}


{% endfor %}

{% endif %}