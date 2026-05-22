*** Settings ***
Documentation   Verify Transport Feature Profile Configuration Cellular Controller
Name            Transport Profiles Cellular Controller
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    cellular_controllers
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.transport_profiles is defined %}
{% set profile_cellular_controller_list = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles %}
 {% if profile.cellular_controllers is defined %}
  {% set _ = profile_cellular_controller_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_cellular_controller_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.cellular_controllers is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} Cellular Controller Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_cellular_controller_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/cellular-controller
    Set Suite Variable    ${transport_cellular_controller_res}
    ${transport_cellular_controller}=    Json Search List    ${transport_cellular_controller_res.json()}    data[].payload
    Run Keyword If    ${transport_cellular_controller} == []    Fail    Cellular controller feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_cellular_controller}

{% for cellular_controller in profile.cellular_controllers | default([]) %}
    Log     === Cellular Controller: {{ cellular_controller.name }} ===

    # for each cellular controller find the corresponding one in the json and check parameters:
    ${cellular_controller_feature}=    Json Search    ${transport_cellular_controller}    [?name=='{{ cellular_controller.name }}'] | [0]
    Run Keyword If    $cellular_controller_feature is None    Fail    Cellular controller feature '{{ cellular_controller.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${cellular_controller_feature}    name    {{ cellular_controller.name }}    msg=name
    Should Be Equal Value Json Special_String    ${cellular_controller_feature}    description    {{ cellular_controller.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${cellular_controller_feature}    data.controllerConfig.id    {{ cellular_controller.cellular_id | default('not_defined') }}    {{ cellular_controller.cellular_id_variable | default('not_defined') }}    msg=cellular_id
    Should Be Equal Value Json Yaml    ${cellular_controller_feature}    data.controllerConfig.autoSim    {{ cellular_controller.firmware_auto_sim | default('not_defined') }}    {{ cellular_controller.firmware_auto_sim_variable | default('not_defined') }}    msg=firmware_auto_sim
    Should Be Equal Value Json Yaml    ${cellular_controller_feature}    data.controllerConfig.slot    {{ cellular_controller.primary_sim_slot | default('not_defined') }}    {{ cellular_controller.primary_sim_slot_variable | default('not_defined') }}    msg=primary_sim_slot
    Should Be Equal Value Json Yaml    ${cellular_controller_feature}    data.controllerConfig.maxRetry    {{ cellular_controller.sim_failover_retries | default('not_defined') }}    {{ cellular_controller.sim_failover_retries_variable | default('not_defined') }}    msg=sim_failover_retries
    Should Be Equal Value Json Yaml    ${cellular_controller_feature}    data.controllerConfig.failovertimer    {{ cellular_controller.sim_failover_timeout | default('not_defined') }}    {{ cellular_controller.sim_failover_timeout_variable | default('not_defined') }}    msg=sim_failover_timeout
{% endfor %}

{% endif %}

{% endfor %}

{% endif %}

{% endif %}