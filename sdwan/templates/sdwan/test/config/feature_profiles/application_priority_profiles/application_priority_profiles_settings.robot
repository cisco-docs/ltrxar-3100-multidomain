*** Settings ***
Documentation   Verify Application Priority Feature Profile Configuration Settings Policy
Name            Application Priority Settings Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    application_priority_profiles    settings
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.application_priority_profiles is defined %}

*** Test Cases ***
Get Application Priority Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.application_priority_profiles | default([]) %}
Verify Feature Profiles Application Priority {{ profile.name }} Settings Policy Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${profile_details_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}
    ${settings_parcel}=    Json Search    ${profile_details_res.json()}    associatedProfileParcels[?parcelType=='policy-settings'] | [0]
    Run Keyword If    $settings_parcel is None    Fail    Settings Policy feature expected to be configured within the application priority profile '{{ profile.name }}' on the Manager
    ${settings_id}=    Json Search String    ${settings_parcel}    parcelId

    ${settings_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}/policy-settings/${settings_id}
    ${settings}=    Json Search    ${settings_res.json()}    payload

    Should Be Equal Value Json String    ${settings}    name    {{ profile.name }}_settings    msg=name

    Should Be Equal Value Json Yaml
    ...    ${settings}    data.appVisibility
    ...    {{ profile.get('settings', {}).get('ipv4_application_visibility', defaults.sdwan.feature_profiles.application_priority_profiles.settings.ipv4_application_visibility) }}    not_defined
    ...    msg=settings.ipv4_application_visibility

    Should Be Equal Value Json Yaml
    ...    ${settings}    data.appVisibilityIPv6
    ...    {{ profile.get('settings', {}).get('ipv6_application_visibility', defaults.sdwan.feature_profiles.application_priority_profiles.settings.ipv6_application_visibility) }}    not_defined
    ...    msg=settings.ipv6_application_visibility

    Should Be Equal Value Json Yaml
    ...    ${settings}    data.flowVisibility
    ...    {{ profile.get('settings', {}).get('ipv4_flow_visibility', defaults.sdwan.feature_profiles.application_priority_profiles.settings.ipv4_flow_visibility) }}    not_defined
    ...    msg=settings.ipv4_flow_visibility

    Should Be Equal Value Json Yaml
    ...    ${settings}    data.flowVisibilityIPv6
    ...    {{ profile.get('settings', {}).get('ipv6_flow_visibility', defaults.sdwan.feature_profiles.application_priority_profiles.settings.ipv6_flow_visibility) }}    not_defined
    ...    msg=settings.ipv6_flow_visibility
{% endfor %}
{% endif %}
