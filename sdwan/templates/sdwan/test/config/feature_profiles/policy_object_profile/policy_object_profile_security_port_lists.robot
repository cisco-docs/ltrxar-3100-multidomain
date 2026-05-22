*** Settings ***
Documentation   Verify Policy Object Feature Profile Security Port List Configuration
Name            Policy Object Profile Security Port List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_port_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_port_lists is defined %}

*** Test Cases ***

Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}

Get Security Port Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_port_list_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-port
    Set Suite Variable    ${security_port_list_raw}

Verify Number of Security Port Lists Entries
    ${security_port_list_names}=    Json Search List    ${security_port_list_raw.json()}    data[].payload.name
    ${security_port_list_count}=    Get Length    ${security_port_list_names}
    Should Be Equal As Integers    ${security_port_list_count}    {{ sdwan.feature_profiles.policy_object_profile.security_port_lists | length }}    msg=Fails when there is a difference in expected number and actual deployed Security Port Lists

{% for security_port_list in sdwan.feature_profiles.policy_object_profile.security_port_lists | default([]) %}

Verify Security Port List Values for {{ security_port_list.name }}
    ${security_port_list_actual}=    Json Search List    ${security_port_list_raw.json()}    data[?payload.name=='{{ security_port_list.name }}'].payload.data.entries[].port.value

    ${security_port_list_ports_yaml}=    Create List    {{ security_port_list.get('ports', []) | join('   ') }}

    Lists Should be Equal    ${security_port_list_actual}    ${security_port_list_ports_yaml}    ignore_order=true    msg=Fails when Security Port List '{{ security_port_list.name }}' ports do not match actual deployed values
{% endfor %}

{% endif %}