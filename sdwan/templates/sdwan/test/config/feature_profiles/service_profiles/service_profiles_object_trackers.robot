*** Settings ***
Documentation   Verify Service Feature Profile Configuration Object Tracker and Object Tracker Group
Name            Service Profiles Object Tracker and Object Tracker Group
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    object_trackers    object_tracker_groups
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.service_profiles is defined %}
{% set profile_object_tracker_list = [] %}
{% for profile in sdwan.feature_profiles.service_profiles %}
 {% if profile.object_trackers is defined %}
  {% set _ = profile_object_tracker_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_object_tracker_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.object_trackers is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} Object Tracker Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${service_object_tracker_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/objecttracker
    Set Suite Variable    ${service_object_tracker_res}
    ${service_object_tracker}=    Json Search List    ${service_object_tracker_res.json()}    data[].payload
    Run Keyword If    ${service_object_tracker} == []    Fail    Object tracker feature(s) expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_object_tracker}

{% for tracker in profile.object_trackers | default([]) %}
    Log     === Tracker: {{ tracker.name }} ===

    # for each tracker find the corresponding one in the json and check parameters:
    ${tracker_feature}=    Json Search    ${service_object_tracker}    [?name=='{{ tracker.name }}'] | [0]
    Run Keyword If    $tracker_feature is None    Fail    Object tracker feature '{{ tracker.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String     ${tracker_feature}   name    {{ tracker.name }}    msg=name
    Should Be Equal Value Json Special_String     ${tracker_feature}     description    {{ tracker.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${tracker_feature}    data.objectId    {{ tracker.id | default('not_defined') }}    {{ tracker.id_variable | default('not_defined') }}    msg=id
    Should Be Equal Value Json Yaml    ${tracker_feature}    data.interface    {{ tracker.interface_name | default('not_defined') }}    {{ tracker.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${tracker_feature}    data.routeIp    {{ tracker.route_ip | default('not_defined') }}    {{ tracker.route_ip_variable | default('not_defined') }}    msg=route_ip
    Should Be Equal Value Json Yaml    ${tracker_feature}    data.routeMask    {{ tracker.route_mask | default('not_defined') }}    {{ tracker.route_mask_variable | default('not_defined') }}    msg=route_mask
    Should Be Equal Value Json Yaml    ${tracker_feature}    data.vpn    {{ tracker.vpn_id | default('not_defined') }}    {{ tracker.vpn_id_variable | default('not_defined') }}    msg=vpn_id

    # ignore case for tracker type value
    Should Be Equal Value Json String    ${tracker_feature}    data.objectTrackerType.value    {{ tracker.type | default('not_defined') }}    ignore_case=True    msg=type

{% endfor %}

{% endif %}


{% if profile.object_tracker_groups is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} Object Tracker Group Feature
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${service_tracker_grp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/objecttrackergroup
    ${service_tracker_grp}=    Json Search List    ${service_tracker_grp_res.json()}    data[].payload
    Run Keyword If    ${service_tracker_grp} == []    Fail    Object tracker group feature(s) expected to be configured within the service profile '{{ profile.name }}' on the Manager

    Set Suite Variable    ${service_tracker_grp}

{% for tracker_grp in profile.object_tracker_groups | default([]) %}
    Log     === Tracker Group: {{ tracker_grp.name }} ===

    # for each tracker_grp find the corresponding one in the json and check parameters:
    ${tracker_grp_feature}=    Json Search    ${service_tracker_grp}    [?name=='{{ tracker_grp.name }}'] | [0]
    Run Keyword If    $tracker_grp_feature is None    Fail    Object tracker group feature '{{ tracker_grp.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String     ${tracker_grp_feature}   name    {{ tracker_grp.name }}    msg=tracker_grp name
    Should Be Equal Value Json Special_String     ${tracker_grp_feature}     description    {{ tracker_grp.description | default('not_defined') | normalize_special_string }}    msg=tracker_grp description

    Should Be Equal Value Json Yaml    ${tracker_grp_feature}    data.criteria    {{ tracker_grp.tracker_boolean | default('not_defined') }}    not_defined   msg=tracker_boolean
    Should Be Equal Value Json Yaml    ${tracker_grp_feature}    data.objectId          {{ tracker_grp.id | default('not_defined') }}    {{ tracker_grp.id_variable | default('not_defined') }}    msg=id

    # Configuration has tracker names, tracker_group in JSON returns UUIDs
    # Find UUID from tracker name in tracker group configuration inside trackers API call
    # Compare with refId coming from tracker group API call
    Should Be Equal Value Json List Length    ${tracker_grp_feature}    data.trackerRefs    {{ tracker_grp.get('trackers', []) | length }}    msg=trackers_count

    ${service_tracker_data}=    Json Search List    ${service_object_tracker_res.json()}    data
{% for tracker_name in tracker_grp.trackers | default([]) %}
    Log     === Tracker: {{ tracker_name }} ===

    # Find correct tracker details from tracker JSON based on name inside tracker group configuration
    ${tracker_json}=    Json Search    ${service_tracker_data}    [?payload.name=='{{ tracker_name }}'] | [0]
    Run Keyword If    $tracker_json is None    Fail    Tracker '{{ tracker_name }}' not found in the service profile '{{ profile.name }}' on the Manager

    ${tracker_uuid}=    Json Search String    ${tracker_json}    parcelId

    # Extract refIDs from the trackerGroup JSON
    ${refid_values}=    Evaluate    [p["trackerRef"]["refId"]["value"] for p in ${tracker_grp_feature["data"]["trackerRefs"]}]
    Should Contain    ${refid_values}    ${tracker_uuid}

{% endfor %}

{% endfor %}

{% endif %}


{% endfor %}

{% endif %}

{% endif %}