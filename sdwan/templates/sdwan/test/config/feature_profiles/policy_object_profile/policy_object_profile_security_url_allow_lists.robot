*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security URL Allow List
Name            Policy Object Profile Security URL Allow List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_url_allow_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_url_allow_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security URL Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_url_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-urllist
    Set Suite Variable    ${security_url_raw}


{% for security_url_allow_list in sdwan.feature_profiles.policy_object_profile.security_url_allow_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security URL Allow List Feature {{ security_url_allow_list.name }}

    ${security_url_allow_list}=    Json Search    ${security_url_raw.json()}    data[?payload.name=='{{ security_url_allow_list.name }}'] | [0].payload
    Run Keyword If    $security_url_allow_list is None    Fail    Feature '{{ security_url_allow_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_url_allow_list}    name    {{ security_url_allow_list.name }}    msg=name

    Should Be Equal Value Json List Length    ${security_url_allow_list}    data.entries    {{ security_url_allow_list.get('urls', []) | length }}    msg=urls length
{% if security_url_allow_list.get('urls', []) | length > 0 %}
    Log     === URL Allow List ===
{% for url in security_url_allow_list.urls | default([]) %}
    Should Be Equal Value Json Yaml    ${security_url_allow_list}    data.entries[{{ loop.index0 }}].pattern    {{ url | default('not_defined') }}    not_defined    msg=url
{% endfor %}
{% endif %}


{% endfor %}

{% endif %}