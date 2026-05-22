*** Settings ***
Documentation   Verify Transport Feature Profile Configuration Cellular Profile
Name            Transport Profiles Cellular Profile
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    cellular_profiles
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.transport_profiles is defined %}
{% set profile_cellular_profile_list = [] %}
{% for profile in sdwan.feature_profiles.transport_profiles %}
 {% if profile.cellular_profiles is defined %}
  {% set _ = profile_cellular_profile_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_cellular_profile_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.cellular_profiles is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} Cellular Profile Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_cellular_profile_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/cellular-profile
    Set Suite Variable    ${transport_cellular_profile_res}
    ${transport_cellular_profile}=    Json Search List    ${transport_cellular_profile_res.json()}    data[].payload
    Run Keyword If    ${transport_cellular_profile} == []    Fail    Cellular profile feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_cellular_profile}

{% for cellular in profile.cellular_profiles | default([]) %}
    Log     === Cellular: {{ cellular.name }} ===

    # for each cellular find the corresponding one in the json and check parameters:
    ${cellular_feature}=    Json Search    ${transport_cellular_profile}    [?name=='{{ cellular.name }}'] | [0]
    Run Keyword If    $cellular_feature is None    Fail    Cellular profile feature '{{ cellular.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${cellular_feature}    name    {{ cellular.name }}    msg=name
    Should Be Equal Value Json Special_String    ${cellular_feature}    description    {{ cellular.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.profileInfo.apn    {{ cellular.access_point_name | default('not_defined') }}    {{ cellular.access_point_name_variable | default('not_defined') }}    msg=access_point_name
    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.profileInfo.noOverwrite    {{ cellular.no_overwrite | default('not_defined') }}    {{ cellular.no_overwrite_variable | default('not_defined') }}    msg=no_overwrite
    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.profileInfo.pdnType    {{ cellular.packet_data_network_type | default('not_defined') }}    {{ cellular.packet_data_network_type_variable | default('not_defined') }}    msg=packet_data_network_type
    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.id    {{ cellular.profile_id | default('not_defined') }}    {{ cellular.profile_id_variable | default('not_defined') }}    msg=profile_id

    # extract authentication_enable value from json
    ${authentication_enable_js}=    Json Search    ${cellular_feature}    data.profileConfig.profileInfo.authentication.needAuthentication
    ${authentication_enable_js}=    Set Variable If    $authentication_enable_js is None    False    True
    Should Be Equal    ${authentication_enable_js}    {{ cellular.authentication_enable | default('False') }}

    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.profileInfo.authentication.needAuthentication.type    {{ cellular.authentication_type | default('not_defined') }}    {{ cellular.authentication_type_variable | default('not_defined') }}    msg=authentication_type
    Should Be Equal Value Json Yaml    ${cellular_feature}    data.profileConfig.profileInfo.authentication.needAuthentication.username    {{ cellular.profile_username | default('not_defined') }}    {{ cellular.profile_username_variable | default('not_defined') }}    msg=profile_username
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Should Be Equal Value Json Yaml               ${cellular_feature}     data.profileConfig.profileInfo.authentication.needAuthentication.password    {{ cellular.profile_password | default('not_defined') }}    {{ cellular.profile_password_variable | default('not_defined') }}    msg=profile_password

{% endfor %}


{% endif %}

{% endfor %}

{% endif %}

{% endif %}