*** Settings ***
Documentation   Verify Service Feature Profile Configuration
Name            Service Profiles Summary
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.service_profiles is defined %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}

Verify Feature Profiles Service Profile {{ profile.name }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    Should Be Equal Value Json String    ${profile}    profileName    {{ profile.name }}    msg=name
    Should Be Equal Value Json Special_String    ${profile}    description    {{ profile.description | default('not_defined') | normalize_special_string }}    msg=description

 {% if 'strict_config_check' not in robot_exclude_tags | default() %}
    ${profile_features_res}=   GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}
    # Extract feature list in profile from the data model
    ${expected_features}=    Create List
    {% for key,value in profile.items() if key != 'name' and key != 'description' %}
      {% if value is mapping %}
        {% if 'name' in value %}
            Append To List    ${expected_features}    {{ value.name }}
        {% else %}
            Append To List    ${expected_features}    {{ key }}
        {% endif %}
     {% elif value is iterable and value is not string %}
        {% for item in value %}
                Append To List    ${expected_features}    {{ item.name }}
        {% endfor %}
      {% endif %}
    {% endfor %}

    # Extract features from the JSON using JMESPath
    ${actual_features}=    Json Search List    ${profile_features_res.json()}    associatedProfileParcels[].payload.name
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