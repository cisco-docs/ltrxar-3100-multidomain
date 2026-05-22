*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security Zone
Name            Policy Object Profile Security Zone
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_zones
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_zones is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get Security Zones
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_zone_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-zone
    Set Suite Variable    ${security_zone_raw}


{% for security_zone in sdwan.feature_profiles.policy_object_profile.security_zones | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security Zone Feature {{ security_zone.name }}

    ${security_zone}=    Json Search    ${security_zone_raw.json()}    data[?payload.name=='{{ security_zone.name }}'] | [0].payload
    Run Keyword If    $security_zone is None    Fail    Feature '{{ security_zone.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${security_zone}    name    {{ security_zone.name }}    msg=name

    ${vpn_list}=    Create List    {{ security_zone.get('vpns', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_zone}    data.entries[].vpn.value    ${vpn_list}    msg=vpns

    ${interface_list}=    Create List    {{ security_zone.get('interfaces', []) | join('   ') }}
    Should Be Equal Value Json List    ${security_zone}    data.entries[].interface.value    ${interface_list}    msg=interfaces

{% endfor %}

{% endif %}
