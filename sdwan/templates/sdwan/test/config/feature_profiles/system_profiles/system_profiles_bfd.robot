*** Settings ***
Documentation   Verify System Feature Profile Configuration BFD
Name            System Profiles BFD
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    bfd
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_bfd_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.bfd is defined %}
  {% set _ = profile_bfd_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_bfd_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.bfd is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} BFD Feature {{ profile.bfd.name | default(defaults.sdwan.feature_profiles.system_profiles.bfd.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_bfd_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/bfd
    ${system_bfd}=    Json Search    ${system_bfd_res.json()}    data[0].payload
    Run Keyword If    $system_bfd is None    Fail    Feature '{{ profile.bfd.name | default(defaults.sdwan.feature_profiles.system_profiles.bfd.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_bfd}
    Should Be Equal Value Json String    ${system_bfd}    name    {{ profile.bfd.name | default(defaults.sdwan.feature_profiles.system_profiles.bfd.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_bfd}    description    {{ profile.bfd.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${system_bfd}    data.multiplier    {{ profile.bfd.multiplier | default('not_defined')  }}    {{ profile.bfd.multiplier_variable| default('not_defined') }}    msg=multiplier
    Should Be Equal Value Json Yaml    ${system_bfd}    data.defaultDscp    {{ profile.bfd.default_dscp | default("not_defined") }}    {{ profile.bfd.default_dscp_variable| default('not_defined') }}    msg=default_dscp
    Should Be Equal Value Json Yaml    ${system_bfd}    data.pollInterval    {{ profile.bfd.poll_interval | default("not_defined") }}    {{ profile.bfd.poll_interval_variable| default('not_defined') }}    msg=poll_interval

    Should Be Equal Value Json List Length    ${system_bfd}    data.colors    {{ profile.bfd.get('colors', []) | length }}    msg=colors_count   
{% if profile.bfd.colors is defined and profile.bfd.get('colors', [])|length > 0 %}
    Log   === Color list ===
{% for color_entry in profile.bfd.colors | default([]) %}

    Should Be Equal Value Json Yaml    ${system_bfd}    data.colors[{{ loop.index0 }}].color    {{ color_entry.color | default('not_defined') }}    {{ color_entry.color_variable | default('not_defined') }}    msg=color_entry_color
    Should Be Equal Value Json Yaml    ${system_bfd}    data.colors[{{ loop.index0 }}].helloInterval    {{ color_entry.hello_interval | default('not_defined') }}    {{ color_entry.hello_interval_variable | default('not_defined') }}    msg=color_entry_hello_interval
    Should Be Equal Value Json Yaml    ${system_bfd}    data.colors[{{ loop.index0 }}].multiplier    {{ color_entry.multiplier | default('not_defined') }}    {{ color_entry.multiplier_variable | default('not_defined') }}    msg=color_entry_multiplier
    Should Be Equal Value Json Yaml    ${system_bfd}    data.colors[{{ loop.index0 }}].pmtuDiscovery    {{ color_entry.path_mtu_discovery | default('not_defined') }}    {{ color_entry.path_mtu_discovery_variable | default('not_defined') }}    msg=color_entry_path_mtu_discovery
    Should Be Equal Value Json Yaml    ${system_bfd}    data.colors[{{ loop.index0 }}].dscp    {{ color_entry.default_dscp | default('not_defined') }}    {{ color_entry.default_dscp_variable | default('not_defined') }}    msg=color_entry_default_dscp

{% endfor %}
{% endif %}


{% endif %}
{% endfor %}

{% endif %}

{% endif %}
