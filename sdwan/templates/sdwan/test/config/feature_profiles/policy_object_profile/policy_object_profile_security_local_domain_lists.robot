*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Local Domain List
Name            Policy Object Profile Security Local Domain List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_local_domain_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_local_domain_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security Local Domain Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_local_domain_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-localdomain
    Set Suite Variable    ${security_local_domain_raw}


{% for security_local_domain_list in sdwan.feature_profiles.policy_object_profile.security_local_domain_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Local Domain List Feature {{ security_local_domain_list.name }}

    ${security_local_domain_list}=    Json Search    ${security_local_domain_raw.json()}    data[?payload.name=='{{ security_local_domain_list.name }}'] | [0].payload
    Run Keyword If    $security_local_domain_list is None    Fail    Feature '{{ security_local_domain_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_local_domain_list}    name    {{ security_local_domain_list.name }}    msg=name

    Should Be Equal Value Json List Length    ${security_local_domain_list}    data.entries    {{ security_local_domain_list.get('local_domains', []) | length }}    msg=local_domains length
{% if security_local_domain_list.get('local_domains', []) | length > 0 %}
    Log     === Local Domain List ===
{% for local_domain in security_local_domain_list.local_domains | default([]) %}
    Should Be Equal Value Json Yaml    ${security_local_domain_list}    data.entries[{{ loop.index0 }}].nameServer    {{ local_domain | default('not_defined') }}    not_defined    msg=local_domain
{% endfor %}
{% endif %}


{% endfor %}

{% endif %}
