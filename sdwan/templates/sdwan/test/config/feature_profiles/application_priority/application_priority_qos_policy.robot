*** Settings ***
Documentation   Verify Application Priority Feature Profile Configuration QoS Policy
Name            Application Priority QoS Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles     application_priority   qos_policies
Resource        ../../../sdwan_common.resource


{% set profile_qos_policy_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('application_priority', {}) %}
 {% if profile.qos_policies is defined %}
  {% set _ = profile_qos_policy_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_qos_policy_list != [] %}

*** Test Cases ***
Get Application Priority Profiles
    ${r}=    GET On Session    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Get Value From Json    ${r_po.json()}    $[?(@.profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}')]
    Run Keyword If    ${profile_po} == []    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Get Value From Json    ${profile_po}    $..profileId

    ${class_map_res}=    GET On Session    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id[0]}/class-map
    Set Suite Variable    ${class_map_res}

{% for profile in sdwan.feature_profiles.application_priority | default([]) %}
{% if profile.qos_policies is defined %}

Verify Feature Profiles Application Priority {{ profile.name }} QoS Policy Feature
    ${profile}=    Get Value From Json    ${r.json()}    $[?(@.profileName=='{{ profile.name }}')]
    Run Keyword If    ${profile} == []    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Get Value From Json    ${profile}    $..profileId
    Set Suite Variable    ${profile_id}
    ${qos_policy_res}=    GET On Session    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id[0]}/qos-policy
    Set Suite Variable    ${qos_policy_res}
    ${qos_policies}=    Get Value From Json    ${qos_policy_res.json()}    $..payload
    Run Keyword If    ${qos_policies} == []    Fail    QoS Policy feature(s) expected to be configured within the application priority profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${qos_policies}

{% for qos_policy in profile.qos_policies | default([]) %}
    Log    === QoS Policy: {{ qos_policy.name }} ===
    
    # for each qos_policy find the corresponding one in the json and check parameters:
    ${qos_policy_raw}=    Get Value From Json    ${qos_policies}    $[?(@.name=='{{ qos_policy.name }}')]
    ${qos_policy}=    Set Variable If    ${qos_policy_raw} == []    not_defined    ${qos_policy_raw[0]}

    Should Be Equal Value Json String    ${qos_policy}    $..name    {{ qos_policy.name }}    msg=name
    Should Be Equal Value Json Special_String    ${qos_policy}    $..description    {{ qos_policy.description | default('not_defined') | normalize_special_string }}    msg=description

    ${expected_target_interfaces}=    Set Variable If    {{ qos_policy.get('target_interfaces', []) | length == 0 }}    not_defined    {{ qos_policy.get('target_interfaces', []) }}
    Should Be Equal Value Json Yaml    ${qos_policy}    $..data.targetInterface    ${expected_target_interfaces}    {{ qos_policy.target_interfaces_variable | default('not_defined') }}    msg=qos_policy.target_interfaces    var_msg=qos_policy.target_interfaces_variable

    Should Be Equal Value Json List Length    ${qos_policy}    $..qosSchedulers    {{ qos_policy.get('qos_schedulers', []) | length }}    msg=qos_schedulers length
{% if qos_policy.get('qos_schedulers', []) | length > 0 %}
    Log    === QoS Schedulers List ===
{% for scheduler in qos_policy.qos_schedulers | default([]) %}
    Log    === QoS Scheduler {{ loop.index0 }} ===
    ${scheduler_raw}=    Get Value From Json    ${qos_policy}    $.data.qosSchedulers[{{ loop.index0 }}]
    Run Keyword If    ${scheduler_raw} == []    Fail    QoS Scheduler index {{ loop.index0 }} expected to be configured on the Manager
    ${scheduler}=    Set Variable If    ${scheduler_raw} == []    not_defined    ${scheduler_raw}

    Should Be Equal Value Json Yaml    ${scheduler}    $.bandwidthPercent    {{ scheduler.bandwidth_percent }}    not_defined    msg=qos_scheduler.bandwidth_percent    var_msg=not_defined

    ${configured_forwarding_class_refid_raw}=    Get Value From Json    ${scheduler}    $.classMapRef.refId.value
    ${configured_forwarding_class_refid}=    Set Variable If    ${configured_forwarding_class_refid_raw} == []    not_defined    ${configured_forwarding_class_refid_raw}
    ${configured_forwarding_class_name}=    Get Value From Json    ${class_map_res.json()}    $..data[?(@.parcelId=='${configured_forwarding_class_refid}')]
    Should Be Equal Value Json String    ${configured_forwarding_class_name}    $..name    {{ scheduler.forwarding_class }}    msg=qos_scheduler.forwarding_class

    Should Be Equal Value Json Yaml    ${scheduler}    $.drops    {{ scheduler.drops | default('not_defined') }}    not_defined    msg=qos_scheduler.drops    var_msg=not_defined

{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}