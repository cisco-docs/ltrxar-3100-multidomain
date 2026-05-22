*** Settings ***
Documentation   Verify Application Priority Feature Profile Configuration QoS Policy
Name            Application Priority QoS Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    application_priority_profiles    qos_policies
Resource        ../../../sdwan_common.resource


{% set profile_qos_policy_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('application_priority_profiles', {}) %}
 {% if profile.qos_policies is defined %}
  {% set _ = profile_qos_policy_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_qos_policy_list != [] %}

*** Test Cases ***
Get Application Priority Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId

    ${class_map_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/class
    Set Suite Variable    ${class_map_res}

{% for profile in sdwan.feature_profiles.application_priority_profiles | default([]) %}
{% if profile.qos_policies is defined %}

Verify Feature Profiles Application Priority {{ profile.name }} QoS Policy Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}

    ${profile_details_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}
    ${associated_parcels}=    Json Search List    ${profile_details_res.json()}    associatedProfileParcels
    Set Suite Variable    ${associated_parcels}

{% for qos_policy in profile.qos_policies | default([]) %}
    Log    === QoS Policy: {{ qos_policy.name }} ===

    # Find the QoS policy ID from associated parcels
    ${qos_policy_parcel}=    Json Search    ${associated_parcels}    [?payload.name=='{{ qos_policy.name }}'] | [0]
    Run Keyword If    $qos_policy_parcel is None    Fail    QoS Policy '{{ qos_policy.name }}' expected to be configured within the application priority profile '{{ profile.name }}' on the Manager
    ${qos_policy_id}=    Json Search String    ${qos_policy_parcel}    parcelId

    # Get the individual QoS policy details
    ${qos_policy_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}/qos-policy/${qos_policy_id}
    ${qos_policy}=    Json Search    ${qos_policy_res.json()}    payload

    Should Be Equal Value Json String    ${qos_policy}    name    {{ qos_policy.name }}    msg=name
    Should Be Equal Value Json Special_String    ${qos_policy}    description    {{ qos_policy.description | default('not_defined') | normalize_special_string }}    msg=description

    ${expected_target_interfaces}=    Set Variable If    {{ qos_policy.get('target_interfaces', []) | length == 0 }}    not_defined    {{ qos_policy.get('target_interfaces', []) }}
    Should Be Equal Value Json Yaml    ${qos_policy}    data.target.interfaces    ${expected_target_interfaces}    {{ qos_policy.target_interfaces_variable | default('not_defined') }}    msg=qos_policy.target_interfaces

    Should Be Equal Value Json List Length    ${qos_policy}    data.qosMap.qosSchedulers    {{ qos_policy.get('qos_schedulers', []) | length }}    msg=qos_schedulers length
{% if qos_policy.get('qos_schedulers', []) | length > 0 %}
    Log    === QoS Schedulers List ===
{% for scheduler in qos_policy.qos_schedulers | default([]) %}
    Log    === QoS Scheduler {{ loop.index0 }} ===
    ${scheduler}=    Json Search    ${qos_policy}    data.qosMap.qosSchedulers[{{ loop.index0 }}]
    Run Keyword If    $scheduler is None    Fail    QoS Scheduler index {{ loop.index0 }} expected to be configured on the Manager

    Should Be Equal Value Json Yaml    ${scheduler}    bandwidthPercent    {{ scheduler.bandwidth_percent }}    not_defined    msg=qos_scheduler.bandwidth_percent

    ${configured_forwarding_class_refid}=    Json Search String    ${scheduler}    classMapRef.refId.value
    ${configured_forwarding_class}=    Json Search    ${class_map_res.json()}    data[?parcelId=='${configured_forwarding_class_refid}'].payload | [0]
    Should Be Equal Value Json String    ${configured_forwarding_class}    name    {{ scheduler.forwarding_class }}    msg=qos_scheduler.forwarding_class

    Should Be Equal Value Json Yaml    ${scheduler}    drops    {{ scheduler.drops | default('not_defined') }}    not_defined    msg=qos_scheduler.drops

{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}