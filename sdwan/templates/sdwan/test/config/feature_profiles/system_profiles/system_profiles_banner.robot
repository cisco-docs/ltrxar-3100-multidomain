*** Settings ***
Documentation   Verify System Feature Profile Configuration Banner
Name            System Profiles Banner
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    banner
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_banner_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.banner is defined %}
  {% set _ = profile_banner_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_banner_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.banner is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} Banner Feature {{ profile.banner.name | default(defaults.sdwan.feature_profiles.system_profiles.banner.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_banner_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/banner
    ${system_banner}=    Json Search    ${system_banner_res.json()}    data[0].payload
    Run Keyword If    $system_banner is None    Fail    Feature '{{ profile.banner.name | default(defaults.sdwan.feature_profiles.system_profiles.banner.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_banner}

    Should Be Equal Value Json String    ${system_banner}    name    {{ profile.banner.name | default(defaults.sdwan.feature_profiles.system_profiles.banner.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_banner}    description    {{ profile.banner.description | default('not_defined') | normalize_special_string }}    msg=description

    {% if profile.banner.login is defined %}
        Should Be Equal Value Json Special_String    ${system_banner}    data.login.value    {{ profile.banner.login | default("not_defined") | normalize_special_string }}    msg=login
    {% else %}
        Should Be Equal Value Json Yaml    ${system_banner}    data.login    {{ profile.banner.login | default('not_defined') }}    {{ profile.banner.login_variable | default('not_defined') }}    msg=login
    {% endif %}

    
    {% if profile.banner.motd is defined %}
        Should Be Equal Value Json Special_String    ${system_banner}    data.motd.value    {{ profile.banner.motd | default("not_defined") | normalize_special_string }}    msg=motd
    {% else %}
        Should Be Equal Value Json Yaml    ${system_banner}    data.motd    {{ profile.banner.motd | default('not_defined') }}    {{ profile.banner.motd_variable | default('not_defined') }}    msg=motd
    {% endif %}


{% endif %}
{% endfor %}

{% endif %}

{% endif %}