*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration Security URL Filtering Profile
Name            Policy Object Profile Security URL Filtering Profile
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    security_url_filtering_profiles
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.policy_object_profile is defined and sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles is defined %}
*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}

Get Security URL Lists
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_url_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/security-urllist
    Set Suite Variable    ${security_url_raw}

Get Security URL Filtering Profiles
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${security_url_filtering_profiles_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/unified/url-filtering
    Set Suite Variable    ${security_url_filtering_profiles_raw}

{% for security_url_filtering_profile in sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles | default([]) %}
Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }} Security URL Filtering Profile Feature {{ security_url_filtering_profile.name }}

    ${security_url_filtering_profile}=    Json Search    ${security_url_filtering_profiles_raw.json()}    data[?payload.name=='{{ security_url_filtering_profile.name }}'] | [0].payload
    Run Keyword If    $security_url_filtering_profile is None    Fail    Feature '{{ security_url_filtering_profile.name }}' expected to be configured within the policy object profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' on the Manager
    Should Be Equal Value Json String    ${security_url_filtering_profile}    name    {{ security_url_filtering_profile.name }}    msg=name

    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.alerts    {{ security_url_filtering_profile.alerts | default('not_defined') }}    not_defined    msg=alerts
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.blockPageAction    {{ security_url_filtering_profile.block_page_action | default('not_defined') }}    not_defined    msg=block_page_action

{% if security_url_filtering_profile.block_page_action is defined and security_url_filtering_profile.block_page_action == "text" %}
    ${block_page_content_header}=    Set Variable       Access to the requested page has been denied.
    ${block_page_contents}=    Set Variable   ${block_page_content_header} {{ security_url_filtering_profile.block_page_content_body | default(defaults.sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles.block_page_content_body) }}
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.blockPageContents    ${block_page_contents}    not_defined    msg=block_page_content
{% endif %}

    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.enableAlerts    {{ security_url_filtering_profile.enable_alerts | default('not_defined') }}    not_defined    msg=enable_alerts
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.redirectUrl    {{ security_url_filtering_profile.redirect_url | default('not_defined') }}    not_defined    msg=redirect_url
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.webCategories    {{ security_url_filtering_profile.web_categories | default('not_defined') }}    not_defined    msg=web_categories
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.webCategoriesAction    {{ security_url_filtering_profile.web_categories_action | default('not_defined') }}    not_defined    msg=web_categories_action
    Should Be Equal Value Json Yaml    ${security_url_filtering_profile}    data.webReputation    {{ security_url_filtering_profile.web_reputation | default('not_defined') }}    not_defined    msg=web_reputation
    
    Should Be Equal Referenced Object Name    ${security_url_filtering_profile}    data.urlAllowedList.refId.value    ${security_url_raw.json()}    {{ security_url_filtering_profile.url_allow_list | default('not_defined') }}    url_allow_list
    Should Be Equal Referenced Object Name    ${security_url_filtering_profile}    data.urlBlockedList.refId.value    ${security_url_raw.json()}    {{ security_url_filtering_profile.url_block_list | default('not_defined') }}    url_block_list

{% endfor %}

{% endif %}