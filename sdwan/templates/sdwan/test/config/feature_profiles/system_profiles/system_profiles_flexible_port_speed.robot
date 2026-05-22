*** Settings ***
Documentation   Verify System Feature Profile Configuration Flexible Port Speed
Name            System Profiles Flexible Port Speed
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    flexible_port_speed
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_flex_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.flexible_port_speed is defined %}
  {% set _ = profile_flex_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_flex_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}

{% if profile.flexible_port_speed is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} Flexible Port Speed Feature {{ profile.flexible_port_speed.name | default(defaults.sdwan.feature_profiles.system_profiles.flexible_port_speed.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${flexible_port_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/flexible-port-speed
    ${flexible_port}=    Json Search    ${flexible_port_res.json()}    data[0].payload
    Run Keyword If    $flexible_port is None    Fail    Feature '{{ profile.flexible_port_speed.name | default(defaults.sdwan.feature_profiles.system_profiles.flexible_port_speed.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${flexible_port}
    Should Be Equal Value Json String    ${flexible_port}    name    {{ profile.flexible_port_speed.name | default(defaults.sdwan.feature_profiles.system_profiles.flexible_port_speed.name) }}    msg=name
    Should Be Equal Value Json String    ${flexible_port}    description    {{ profile.flexible_port_speed.description | default('not_defined') | normalize_special_string }}    msg=description
    Should Be Equal Value Json Yaml    ${flexible_port}    data.portType    {{ profile.flexible_port_speed.port_type| default('not_defined') }}    {{ profile.flexible_port_speed.port_type_variable| default('not_defined') }}    msg=global port_type

{% endif %}
{% endfor %}

{% endif %}

{% endif %}