*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Geo Location List
Name            Policy Object Profile Security Geo Location List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_geo_location_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_geo_location_lists is defined %}
*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security Geo Location Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_geo_location_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-geolocation
    Set Suite Variable    ${security_geo_location_raw}

Verify Number of Security Geo Location Lists entries
    ${security_geo_location_lists}=    Json Search List    ${security_geo_location_raw.json()}    data[].payload.name
    Length Should Be    ${security_geo_location_lists}    {{ sdwan.feature_profiles.policy_object_profile.security_geo_location_lists | length }}

{% for security_geo_location_list in sdwan.feature_profiles.policy_object_profile.security_geo_location_lists | default([]) %}
Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Geo Location List Feature {{ security_geo_location_list.name }}

    ${security_geo_location_list}=    Json Search    ${security_geo_location_raw.json()}    data[?payload.name=='{{ security_geo_location_list.name }}'] | [0].payload
    Run Keyword If    $security_geo_location_list is None    Fail    Feature '{{ security_geo_location_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager
    Should Be Equal Value Json String    ${security_geo_location_list}    name    {{ security_geo_location_list.name }}    msg=name

    ${continents_list}=    Create List    {{ security_geo_location_list.get('continent_codes', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_geo_location_list}    data.entries[].continent.value    ${continents_list}    msg=continent codes
    ${countries_list}=    Create List    {{ security_geo_location_list.get('country_codes', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_geo_location_list}    data.entries[].country.value    ${countries_list}    msg=country codes

{% endfor %}

{% endif %}