*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration SLA Class
Name            Policy Object Profile SLA Class
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    sla_classes
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.sla_classes is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get SLA Classes
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}

    ${sla_class_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/sla-class
    Set Suite Variable    ${sla_class_raw}


{% for sla_class in sdwan.feature_profiles.policy_object_profile.sla_classes | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} SLA Class Feature {{ sla_class.name }}

    ${sla_class}=    Json Search    ${sla_class_raw.json()}    data[?payload.name=='{{ sla_class.name }}'] | [0].payload
    Run Keyword If    $sla_class is None    Fail    Feature '{{ sla_class.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${sla_class}    name    {{ sla_class.name }}    msg=name
    Should Be Equal Value Json Special_String    ${sla_class}    description    {{ sla_class.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].jitter    {{ sla_class.jitter_ms | default('not_defined') }}    not_defined    msg=jitter
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].latency    {{ sla_class.latency_ms | default('not_defined') }}    not_defined    msg=latency
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].loss    {{ sla_class.loss_percentage | default('not_defined') }}    not_defined    msg=loss
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].fallbackBestTunnel.criteria    {{ sla_class.fallback_best_tunnel_criteria | default('not_defined') }}    not_defined    msg=fallback_best_tunnel_criteria
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].fallbackBestTunnel.jitterVariance    {{ sla_class.fallback_best_tunnel_jitter_variance | default('not_defined') }}    not_defined    msg=fallback_best_tunnel_jitter_variance
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].fallbackBestTunnel.latencyVariance    {{ sla_class.fallback_best_tunnel_latency_variance | default('not_defined') }}    not_defined    msg=fallback_best_tunnel_latency_variance
    Should Be Equal Value Json Yaml    ${sla_class}    data.entries[0].fallbackBestTunnel.lossVariance    {{ sla_class.fallback_best_tunnel_loss_variance | default('not_defined') }}    not_defined    msg=fallback_best_tunnel_loss_variance

    ${app_probe_id}=    Json Search List    ${sla_class}    data.entries[0].appProbeClass.refId.value
{% if sla_class.app_probe_class | default("not_defined") == "not_defined" %}
   Should Be Empty    ${app_probe_id}    msg={{ sla_class.name }}: App Probe Class
{% else %}
   ${app_probe_object}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/app-probe/${app_probe_id[0]}
   Should Be Equal Value Json String    ${app_probe_object.json()}    payload.name    {{ sla_class.app_probe_class }}    msg={{ sla_class.name }}: App Probe Class
{% endif %}


{% endfor %}

{% endif %}