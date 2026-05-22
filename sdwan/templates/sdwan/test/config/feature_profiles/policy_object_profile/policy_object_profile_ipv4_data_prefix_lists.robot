*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration IPv4 Data Prefix List
Name            Policy Object Profile IPv4 Data Prefix List
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    ipv4_data_prefix_lists
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.ipv4_data_prefix_lists is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}


Get IPv4 Data Prefix Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${ipv4_data_prefix_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/data-prefix
    Set Suite Variable    ${ipv4_data_prefix_raw}


{% for ipv4_data_prefix_list in sdwan.feature_profiles.policy_object_profile.ipv4_data_prefix_lists | default([]) %}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} IPv4 Data Prefix List Feature {{ ipv4_data_prefix_list.name }}

    ${ipv4_data_prefix_list}=    Json Search    ${ipv4_data_prefix_raw.json()}    data[?payload.name=='{{ ipv4_data_prefix_list.name }}'] | [0].payload
    Run Keyword If    $ipv4_data_prefix_list is None    Fail    Feature '{{ ipv4_data_prefix_list.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager

    Should Be Equal Value Json String    ${ipv4_data_prefix_list}    name    {{ ipv4_data_prefix_list.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ipv4_data_prefix_list}    description    {{ ipv4_data_prefix_list.description | default('not_defined') | normalize_special_string }}    msg=description

    ${prefixes_list}=    Create List    {{ ipv4_data_prefix_list.get('prefixes', []) | join('   ') }}
    # Extract features from the JSON
    ${prefixes_list_json}=    Evaluate    [f"{item['ipv4Address']['value']}/{item['ipv4PrefixLength']['value']}" for item in ${ipv4_data_prefix_list['data']['entries']} if 'ipv4Address' in item and 'ipv4PrefixLength' in item]
    Lists Should Be Equal    ${prefixes_list}    ${prefixes_list_json}    ignore_order=True    msg=ip prefix

{% endfor %}

{% endif %}