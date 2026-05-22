*** Settings ***
Documentation   Verify Policy Object Feature Profile Security Protocol List Configuration
Name            Policy Object Profile Security Protocol List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_protocol_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_protocol_lists is defined %}
*** Test Cases ***

Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${r_json}=    Set Variable    ${r.json()}
    Set Suite Variable    ${r_json}

Get Security Protocol Lists
    ${profile}=    Json Search    ${r_json}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${security_protocol_list_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-protocolname
    Should Be Equal As Strings    ${security_protocol_list_raw.status_code}    200    msg=Failed to retrieve Security Protocol Lists, status code: ${security_protocol_list_raw.status_code}
    Set Suite Variable    ${security_protocol_list_raw}

Verify Number of Security Protocol Lists Entries
    ${security_protocol_list_names}=    Json Search List    ${security_protocol_list_raw.json()}    data[].payload.name
    ${security_protocol_list_count}=    Get Length    ${security_protocol_list_names}
    Should Be Equal As Integers    ${security_protocol_list_count}    {{ sdwan.feature_profiles.policy_object_profile.security_protocol_lists | length }}    msg=Fails when there is a difference in expected and actual deployed number of Security Protocol Lists

{% for security_protocol_list in sdwan.feature_profiles.policy_object_profile.security_protocol_lists | default([]) %}

Verify Security Protocol List Values for {{ security_protocol_list.name }}
    ${security_protocol_list_actual}=    Json Search List    ${security_protocol_list_raw.json()}    data[?payload.name=='{{ security_protocol_list.name }}'].payload.data.entries[].protocolName.value
    ${security_protocol_list_protocols_yaml}=    Create List    {{ security_protocol_list.get('protocols', []) | join('   ') }}
    Lists Should be Equal    ${security_protocol_list_actual}    ${security_protocol_list_protocols_yaml}    ignore_order=true    msg=Fails when Security Protocol List '{{ security_protocol_list.name }}' protocols do not match actual deployed values
{% endfor %}

{% endif %}
