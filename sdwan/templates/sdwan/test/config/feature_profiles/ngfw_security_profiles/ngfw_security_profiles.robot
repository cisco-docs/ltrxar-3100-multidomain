*** Settings ***
Documentation   Verify NGFW Security Feature Profile Configuration
Name            NGFW Security Profiles Summary
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    ngfw_security_profiles
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.ngfw_security_profiles is defined %}

*** Test Cases ***
Get NGFW Security Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/embedded-security
    Set Suite Variable   ${r}

{% for profile in sdwan.feature_profiles.ngfw_security_profiles | default([]) %}

Verify Feature Profiles NGFW Security Profile {{ profile.name }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    Should Be Equal Value Json String    ${profile}    profileName    {{ profile.name }}    msg=name
    Should Be Equal Value Json Special_String    ${profile}    description    {{ profile.description | default('not_defined') | normalize_special_string }}    msg=description
 {% if 'strict_config_check' not in robot_exclude_tags | default() %}
    ${profile_features_res}=   GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/embedded-security/${profile_id}
    # Extract feature list in profile from the data model
    ${expected_features}=    Create List
    {% for key,value in profile.items() if key != 'name' and key != 'description' %}
        {% if value is iterable and value is not string %}
            {% for item in value if item.name is defined and item.name %}
    Append To List    ${expected_features}    {{ item.name }}
            {% endfor %}
        {% elif value.name is defined and value.name %}
    Append To List    ${expected_features}    {{ value.name }}
        {% endif %}
    {% endfor %}

    # Extract features from the JSON using JMESPath (filter to ngfirewall parcels only)
    ${actual_features}=    Json Search List    ${profile_features_res.json()}    associatedProfileParcels[?parcelType=='unified/ngfirewall'].payload.name
    ${data_match}=    Evaluate    set(${actual_features}) ^ set(${expected_features})
    IF     ${data_match} != set()
        FOR    ${feature}    IN    @{actual_features}
            Run Keyword And Continue On Failure    Run Keyword If    '${feature}' not in ${expected_features}    Fail    Feature Profile '{{ profile.name }}' has the feature ${feature} that is not present in the data model
        END
    ELSE
        Log    Feature Profile '{{ profile.name }}' contains all features defined in the configuration data model
    END
{% endif %}

{% endfor %}
{% endif %}
