*** Settings ***
Documentation   Verify Transport Feature Profile Configuration GPS Feature
Name            Transport Profiles GPS Feature
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    gps_features
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.transport_profiles is defined %}
{% set profile_gps_feature_list = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles %}
 {% if profile.gps_features is defined %}
  {% set _ = profile_gps_feature_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_gps_feature_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.gps_features is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} GPS Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_gps_feature_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/gps
    Set Suite Variable    ${transport_gps_feature_res}
    ${transport_gps_feature}=    Json Search List    ${transport_gps_feature_res.json()}    data[].payload
    Run Keyword If    ${transport_gps_feature} == []    Fail    GPS feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_gps_feature}

{% for gps_feature in profile.gps_features | default([]) %}
    Log     === GPS: {{ gps_feature.name }} ===

    # for each gps feature find the corresponding one in the json and check parameters:
    ${gps_feature_obj}=    Json Search    ${transport_gps_feature}    [?name=='{{ gps_feature.name }}'] | [0]
    Run Keyword If    $gps_feature_obj is None    Fail    GPS feature '{{ gps_feature.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String             ${gps_feature_obj}     name            {{ gps_feature.name }}    msg=name
    Should Be Equal Value Json Special_String     ${gps_feature_obj}     description    {{ gps_feature.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.enable    {{ gps_feature.gps_enable | default('not_defined') }}    {{ gps_feature.gps_enable_variable | default('not_defined') }}    msg=gps_enable
    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.mode    {{ gps_feature.gps_mode | default('not_defined') }}    {{ gps_feature.gps_mode_variable | default('not_defined') }}    msg=gps_mode
    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.nmea       {{ gps_feature.nmea_enable | default('not_defined') }}    not_defined    msg=nmea_enable
    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.sourceAddress         {{ gps_feature.nmea_source_address | default('not_defined') }}         {{ gps_feature.nmea_source_address_variable | default('not_defined') }}    msg=nmea_source_address
    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.destinationAddress    {{ gps_feature.nmea_destination_address | default('not_defined') }}    {{ gps_feature.nmea_destination_address_variable | default('not_defined') }}    msg=nmea_destination_address
    Should Be Equal Value Json Yaml               ${gps_feature_obj}     data.destinationPort       {{ gps_feature.nmea_destination_port | default('not_defined') }}       {{ gps_feature.nmea_destination_port_variable | default('not_defined') }}    msg=nmea_destination_port

{% endfor %}


{% endif %}

{% endfor %}

{% endif %}

{% endif %}
