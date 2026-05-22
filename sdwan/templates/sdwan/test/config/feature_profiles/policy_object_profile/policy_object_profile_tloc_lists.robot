*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration TLOC List
Name            Policy Object Profile TLOC List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    tloc_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.tloc_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get TLOC Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${tloc_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/tloc
    Set Suite Variable    ${tloc_raw}


{% for tloc_list in sdwan.feature_profiles.policy_object_profile.tloc_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} TLOC List Feature {{ tloc_list.name }}

    ${tloc_list}=    Json Search    ${tloc_raw.json()}    data[?payload.name=='{{ tloc_list.name }}'] | [0].payload
    Run Keyword If    $tloc_list is None    Fail    Feature '{{ tloc_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${tloc_list}    name    {{ tloc_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${tloc_list}    description    {{ tloc_list.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json List Length    ${tloc_list}    data.entries    {{ tloc_list.get('tlocs', []) | length }}    msg=tlocs length
{% if tloc_list.get('tlocs', []) | length > 0 %}
    Log     === TLOC List ===
{% for tloc in tloc_list.tlocs | default([]) %}

    Should Be Equal Value Json Yaml    ${tloc_list}    data.entries[{{ loop.index0 }}].color    {{ tloc.color | default('not_defined') }}    not_defined    msg=color
    Should Be Equal Value Json Yaml    ${tloc_list}    data.entries[{{ loop.index0 }}].encap    {{ tloc.encapsulation | default('not_defined') }}    not_defined    msg=encapsulation
    Should Be Equal Value Json Yaml    ${tloc_list}    data.entries[{{ loop.index0 }}].tloc    {{ tloc.tloc_ip | default('not_defined') }}    not_defined    msg=tloc ip
    Should Be Equal Value Json Yaml    ${tloc_list}    data.entries[{{ loop.index0 }}].preference    {{ tloc.preference | default('not_defined') }}    not_defined    msg=preference

{% endfor %}
{% endif %}


{% endfor %}

{% endif %}