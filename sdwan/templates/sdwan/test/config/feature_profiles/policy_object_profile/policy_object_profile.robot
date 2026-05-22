*** Settings ***
Documentation   Verify Policy Object Feature Profile Configuration
Name            Policy Object Profile Summary
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles.policy_object_profile is defined %}

*** Test Cases ***
Get Policy Object Profile
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r}

Verify Feature Profiles Policy Object Profile {{ sdwan.feature_profiles.policy_object_profile.name }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    Should Be Equal Value Json String    ${profile}    profileName    {{ sdwan.feature_profiles.policy_object_profile.name }}    msg=name
    Should Be Equal Value Json Special_String    ${profile}    description    {{ sdwan.feature_profiles.policy_object_profile.description | default('not_defined') | normalize_special_string }}    msg=description

# There is only one policy object profile so in most cases we don't want to fail if additional policy objects are created, but not used
# {% if 'strict_config_check' not in robot_exclude_tags | default() %}
#     ${profile_features_res}=   GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}
#     # Extract feature list in profile from the data model
#     ${expected_features}=    Create List
#     {% for key,value in sdwan.feature_profiles.policy_object_profile.items() if key != 'name' and key != 'description' %}
#         {% for item in value if item.name is defined and item.name %}
#         Append To List    ${expected_features}    {{ item.name }}
#         {% endfor %}
#     {% endfor %}
#
#     # Extract features from the JSON using JMESPath
#     ${actual_features}=    Json Search List    ${profile_features_res.json()}    associatedProfileParcels[].payload.name
#     ${data_match}=    Evaluate    set(${actual_features}) ^ set(${expected_features})
#     IF     ${data_match} != set()
#         FOR    ${feature}    IN    @{actual_features}
#             Run Keyword And Continue On Failure    Run Keyword If    '${feature}' not in ${expected_features}    Fail    Feature Profile '{{sdwan.feature_profiles.policy_object_profile.name}}' has the feature ${feature} that is not present in the data model
#         END
#     ELSE
#         Log    Feature Profile '{{sdwan.feature_profiles.policy_object_profile.name}}' contains all features defined in the configuration data model
#     END
# {% endif %}

{% endif %}