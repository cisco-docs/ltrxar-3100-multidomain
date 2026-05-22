*** Settings ***
Documentation   Verify System Feature Profile Configuration MRF
Name            System Profiles MRF
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    mrf
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_mrf_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.mrf is defined %}
  {% set _ = profile_mrf_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_mrf_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.mrf is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} MRF Feature {{ profile.mrf.name | default(defaults.sdwan.feature_profiles.system_profiles.mrf.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_mrf_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/mrf
    ${system_mrf}=    Json Search    ${system_mrf_res.json()}    data[0].payload
    Run Keyword If    $system_mrf is None    Fail    Feature '{{ profile.mrf.name | default(defaults.sdwan.feature_profiles.system_profiles.mrf.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_mrf}

    Should Be Equal Value Json String    ${system_mrf}    name    {{ profile.mrf.name | default(defaults.sdwan.feature_profiles.system_profiles.mrf.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_mrf}    description    {{ profile.mrf.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json String    ${system_mrf}    data.enableMrfMigration.value    {{ profile.mrf.migration_to_mrf | default('not_defined') }}    msg=migration_to_mrf
    Should Be Equal Value Json String    ${system_mrf}    data.migrationBgpCommunity.value    {{ profile.mrf.migration_bgp_community | default('not_defined') }}    msg=migration_bgp_community
   
    Should Be Equal Value Json Yaml    ${system_mrf}    data.role    {{ profile.mrf.role| default('not_defined') }}    {{ profile.mrf.role_variable| default('not_defined') }}    msg=role
    Should Be Equal Value Json Yaml    ${system_mrf}    data.secondaryRegion    {{ profile.mrf.secondary_region_id| default('not_defined') }}    {{ profile.mrf.secondary_region_id_variable| default('not_defined') }}    msg=secondary_region_id

{% endif %}
{% endfor %}

{% endif %}

{% endif %}
