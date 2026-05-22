*** Settings ***
Documentation   Verify System Feature Profile Configuration Performance Monitoring
Name            System Profiles Performance Monitoring
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    performance_monitoring
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_perfmonitor_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.performance_monitoring is defined %}
  {% set _ = profile_perfmonitor_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_perfmonitor_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.performance_monitoring is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} Performance Monitoring Feature {{ profile.performance_monitoring.name }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${system_perfmonitor_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/perfmonitor
    ${system_perfmonitor}=    Json Search    ${system_perfmonitor_res.json()}    data[0].payload
    Run Keyword If    $system_perfmonitor is None    Fail    Feature '{{ profile.performance_monitoring.name }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_perfmonitor}

    Should Be Equal Value Json String    ${system_perfmonitor}    name    {{ profile.performance_monitoring.name | default((defaults.sdwan.feature_profiles.system_profiles.performance_monitoring.name) if defaults is defined else "not_defined") }}    msg=name
    Should Be Equal Value Json Special_String    ${system_perfmonitor}    description    {{ profile.performance_monitoring.description | default('not_defined') | normalize_special_string }}    msg=description

    ${perfmonitor_app_groups_list}=    Create List    {{ profile.performance_monitoring.get('app_perf_monitor_app_groups', []) | join('   ') }}
    ${perfmonitor_app_groups_list}=    Set Variable If    ${perfmonitor_app_groups_list} == []    not_defined    ${perfmonitor_app_groups_list}
    Should Be Equal Value Json Yaml    ${system_perfmonitor}    data.appPerfMonitorConfig.policyFilters.appGroups    ${perfmonitor_app_groups_list}    not_defined    msg=performance_monitoring app_perf_monitor_app_groups

    Should Be Equal Value Json String    ${system_perfmonitor}    data.appPerfMonitorConfig.enabled.value    {{ profile.performance_monitoring.app_perf_monitor_enabled | default('False') }}    msg=performance_monitoring app_perf_monitor_enabled
    Should Be Equal Value Json String    ${system_perfmonitor}    data.umtsConfig.eventDrivenConfig.enabled.value    {{ profile.performance_monitoring.event_driven_config_enabled | default('False') }}    msg=performance_monitoring event_driven_config_enabled

    ${perfmonitor_event_driven_events_list}=    Create List    {{ profile.performance_monitoring.get('event_driven_events', []) | join('   ') }}
    ${perfmonitor_event_driven_events_list}=    Evaluate    [e.upper() for e in ${perfmonitor_event_driven_events_list}]
    ${perfmonitor_event_driven_events_list}=    Set Variable If    ${perfmonitor_event_driven_events_list} == []    not_defined    ${perfmonitor_event_driven_events_list}
    Should Be Equal Value Json Yaml    ${system_perfmonitor}    data.umtsConfig.eventDrivenConfig.events    ${perfmonitor_event_driven_events_list}    not_defined    msg=performance_monitoring event_driven_events

    Should Be Equal Value Json String    ${system_perfmonitor}    data.umtsConfig.monitoringConfig.enabled.value    {{ profile.performance_monitoring.monitoring_config_enabled | default('False') }}    msg=performance_monitoring monitoring_config_enabled
    Should Be Equal Value Json String    ${system_perfmonitor}    data.umtsConfig.monitoringConfig.interval.value    {{ profile.performance_monitoring.monitoring_config_interval | default('not_defined') }}    msg=performance_monitoring monitoring_config_interval


{% endif %}
{% endfor %}

{% endif %}
{% endif %}