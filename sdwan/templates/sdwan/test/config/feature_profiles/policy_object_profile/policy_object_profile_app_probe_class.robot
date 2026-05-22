*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration App Probe Class
Name            Policy Object Profile App Probe Class
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    app_probe_classes
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.app_probe_classes is defined %}

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

Get App Probe Classes
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${app_probe_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/app-probe
    Set Suite Variable    ${app_probe_raw}

{% for app_probe in sdwan.feature_profiles.policy_object_profile.app_probe_classes | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} App Probe Class Feature {{ app_probe.name }}

    ${app_probe}=    Json Search    ${app_probe_raw.json()}    data[?payload.name=='{{ app_probe.name }}'] | [0].payload
    Run Keyword If    $app_probe is None    Fail    Feature '{{ app_probe.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${app_probe}    name    {{ app_probe.name }}    msg=name
    Should Be Equal Referenced Object Name    ${app_probe}    data.entries[0].forwardingClass.refId.value    ${forwarding_class_raw.json()}    {{ app_probe.forwarding_class | default('not_defined') }}    forwarding_class
    Should Be Equal Value Json List Length    ${app_probe}    data.entries[0].map    {{ app_probe.get('mappings', []) | length }}    msg=mappings length
{% if app_probe.get('mappings', []) | length > 0 %}
    Log     === Mappings for {{ app_probe.forwarding_class }} ===
{% for mapping in app_probe.get('mappings', []) %}
    Should Be Equal Value Json Yaml    ${app_probe}    data.entries[0].map[{{ loop.index0 }}].color    {{ mapping.color | default('not_defined') }}    not_defined    msg=color
    Should Be Equal Value Json Yaml    ${app_probe}    data.entries[0].map[{{ loop.index0 }}].dscp    {{ mapping.dscp | default('not_defined') }}    not_defined    msg=dscp
{% endfor %}

{% endif %}

{% endfor %}

{% endif %}