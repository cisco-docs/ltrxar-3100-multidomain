*** Settings ***
Documentation   Verify System Feature Profile Configuration Basic
Name            System Profiles Basic
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    basic
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_basic_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.basic is defined %}
  {% set _ = profile_basic_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_basic_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.basic is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} Basic Feature {{ profile.basic.name | default(defaults.sdwan.feature_profiles.system_profiles.basic.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_basic_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/basic
    ${system_basic}=    Json Search    ${system_basic_res.json()}    data[0].payload
    Run Keyword If    $system_basic is None    Fail    Feature '{{ profile.basic.name | default(defaults.sdwan.feature_profiles.system_profiles.basic.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_basic}

    Should Be Equal Value Json String    ${system_basic}    name    {{ profile.basic.name | default(defaults.sdwan.feature_profiles.system_profiles.basic.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_basic}    description    {{ profile.basic.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${system_basic}    data.adminTechOnFailure    {{ profile.basic.admin_tech_on_failure | default('not_defined') }}    {{ profile.basic.admin_tech_on_failure_variable | default('not_defined') }}    msg=basic admin tech on failure
    Should Be Equal Value Json Yaml    ${system_basic}    data.affinityGroupNumber    {{ profile.basic.affinity_group_number | default('not_defined') }}    {{ profile.basic.affinity_group_number_variable | default('not_defined') }}    msg=basic affinity group number

    ${basic_affinity_group_preferences_list}=    Create List    {{ profile.basic.affinity_group_preferences | default([]) | join('   ') }}
    ${basic_affinity_group_preferences_list}=    Set Variable If    ${basic_affinity_group_preferences_list} == []    not_defined    ${basic_affinity_group_preferences_list}
    Should Be Equal Value Json Yaml    ${system_basic}    data.affinityGroupPreference    ${basic_affinity_group_preferences_list}    {{ profile.basic.affinity_group_preferences_variable | default('not_defined') }}    msg=basic affinity group preferences

    Should Be Equal Value Json Yaml    ${system_basic}    data.affinityPreferenceAuto    {{ profile.basic.affinity_preference_auto | default('not_defined') }}    {{ profile.basic.affinity_preference_auto_variable | default('not_defined') }}    msg=basic affinity preference auto
    Should Be Equal Value Json Yaml    ${system_basic}    data.consoleBaudRate    {{ profile.basic.console_baud_rate | default('not_defined') }}    {{ profile.basic.console_baud_rate_variable | default('not_defined') }}    msg=basic console baud rate
    Should Be Equal Value Json Yaml    ${system_basic}    data.controlSessionPps    {{ profile.basic.control_session_pps | default('not_defined') }}    {{ profile.basic.control_session_pps_variable | default('not_defined') }}    msg=basic control session pps

    ${basic_controller_groups_list}=    Create List    {{ profile.basic.controller_groups | default([]) | join('   ') }}
    ${basic_controller_groups_list}=    Set Variable If    ${basic_controller_groups_list} == []    not_defined    ${basic_controller_groups_list}
    Should Be Equal Value Json Yaml    ${system_basic}    data.controllerGroupList    ${basic_controller_groups_list}    {{ profile.basic.controller_groups_variable | default('not_defined') }}    msg=basic controller groups

    ${basic_device_groups_list}=    Create List    {{ profile.basic.device_groups | default([]) | join('   ') }}
    ${basic_device_groups_list}=    Set Variable If    ${basic_device_groups_list} == []    not_defined    ${basic_device_groups_list}
    Should Be Equal Value Json Yaml    ${system_basic}    data.deviceGroups    ${basic_device_groups_list}    {{ profile.basic.device_groups_variable | default('not_defined') }}    msg=basic device groups

    Should Be Equal Value Json Yaml    ${system_basic}    data.epfr    {{ profile.basic.enhanced_app_aware_routing | default('not_defined') }}    {{ profile.basic.enhanced_app_aware_routing_variable | default('not_defined') }}    msg=basic enhanced app aware routing

    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.geoFencing.enable    {{ profile.basic.geo_fencing_enable | default('not_defined') }}    not_defined    msg=basic geo fencing enable
    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.geoFencing.sms.enable    {{ profile.basic.geo_fencing_sms_enable | default('not_defined') }}    not_defined    msg=basic geo fencing sms enable

    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.geoFencing.range    {{ profile.basic.geo_fencing_range | default('not_defined') }}    {{ profile.basic.geo_fencing_range_variable | default('not_defined') }}    msg=basic geo fencing range
    Should Be Equal Value Json Yaml    ${system_basic}    data.idleTimeout    {{ profile.basic.idle_timeout | default('not_defined') }}    {{ profile.basic.idle_timeout_variable | default('not_defined') }}    msg=basic idle timeout
    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.latitude    {{ profile.basic.latitude | default('not_defined') }}    {{ profile.basic.latitude_variable | default('not_defined') }}    msg=basic latitude
    Should Be Equal Value Json Yaml    ${system_basic}    data.location    {{ profile.basic.location | default('not_defined') }}    {{ profile.basic.location_variable | default('not_defined') }}    msg=basic location
    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.longitude    {{ profile.basic.longitude | default('not_defined') }}    {{ profile.basic.longitude_variable | default('not_defined') }}    msg=basic longitude
    Should Be Equal Value Json Yaml    ${system_basic}    data.maxOmpSessions    {{ profile.basic.max_omp_sessions | default('not_defined') }}    {{ profile.basic.max_omp_sessions_variable | default('not_defined') }}    msg=basic max omp sessions
    Should Be Equal Value Json Yaml    ${system_basic}    data.multiTenant    {{ profile.basic.multitenant | default('not_defined') }}    {{ profile.basic.multitenant_variable | default('not_defined') }}    msg=basic multitenant
    Should Be Equal Value Json Yaml    ${system_basic}    data.onDemand.onDemandEnable    {{ profile.basic.on_demand_tunnel | default('not_defined') }}    {{ profile.basic.on_demand_tunnel_variable | default('not_defined') }}    msg=basic on demand tunnel
    Should Be Equal Value Json Yaml    ${system_basic}    data.onDemand.onDemandIdleTimeout    {{ profile.basic.on_demand_tunnel_idle_timeout | default('not_defined') }}    {{ profile.basic.on_demand_tunnel_idle_timeout_variable | default('not_defined') }}    msg=basic on demand tunnel idle timeout
    Should Be Equal Value Json Yaml    ${system_basic}    data.overlayId    {{ profile.basic.overlay_id | default('not_defined') }}    {{ profile.basic.overlay_id_variable | default('not_defined') }}    msg=basic overlay id
    Should Be Equal Value Json Yaml    ${system_basic}    data.portHop    {{ profile.basic.port_hopping | default('not_defined') }}    {{ profile.basic.port_hopping_variable | default('not_defined') }}    msg=basic port hopping
    Should Be Equal Value Json Yaml    ${system_basic}    data.portOffset    {{ profile.basic.port_offset | default('not_defined') }}    {{ profile.basic.port_offset_variable | default('not_defined') }}    msg=basic port offset

    ${basic_site_types_list}=    Create List    {{ profile.basic.get('site_types', []) | join('   ') }}
    ${basic_site_types_list}=    Set Variable If    ${basic_site_types_list} == []    not_defined    ${basic_site_types_list}
    Should Be Equal Value Json Yaml    ${system_basic}    data.siteType    ${basic_site_types_list}    {{ profile.basic.site_types_variable | default('not_defined') }}    msg=basic site types

    Should Be Equal Value Json Yaml    ${system_basic}    data.description    {{ profile.basic.system_description | default('not_defined') }}    {{ profile.basic.system_description_variable | default('not_defined') }}    msg=basic system description
    Should Be Equal Value Json Yaml    ${system_basic}    data.clock.timezone    {{ profile.basic.timezone | default('not_defined') }}    {{ profile.basic.timezone_variable | default('not_defined') }}    msg=basic timezone
    Should Be Equal Value Json Yaml    ${system_basic}    data.trackDefaultGateway    {{ profile.basic.track_default_gateway | default('not_defined') }}    {{ profile.basic.track_default_gateway_variable | default('not_defined') }}    msg=basic track default gateway
    Should Be Equal Value Json Yaml    ${system_basic}    data.trackInterfaceTag    {{ profile.basic.track_interface_tag | default('not_defined') }}    {{ profile.basic.track_interface_tag_variable | default('not_defined') }}    msg=basic track interface tag
    Should Be Equal Value Json Yaml    ${system_basic}    data.trackTransport    {{ profile.basic.track_transport | default('not_defined') }}    {{ profile.basic.track_transport_variable | default('not_defined') }}    msg=basic track transport
    Should Be Equal Value Json Yaml    ${system_basic}    data.transportGateway    {{ profile.basic.transport_gateway | default('not_defined') }}    {{ profile.basic.transport_gateway_variable | default('not_defined') }}    msg=basic transport gateway
    Should Be Equal Value Json Yaml    ${system_basic}    data.trackerDiaStabilizeStatus   {{ profile.basic.tracker_dia_stabilize_status | default('not_defined') }}    {{ profile.basic.tracker_dia_stabilize_status_variable | default('not_defined') }}    msg=basic tracker dia stabilize status

    Should Be Equal Value Json List Length    ${system_basic}    data.affinityPerVrf    {{ profile.basic.get('affinity_per_vrfs', []) | length }}    msg=basic affinity per vrfs length
{% for basic_affinity_per_vrf in profile.basic.affinity_per_vrfs | default([]) %}

    Should Be Equal Value Json Yaml    ${system_basic}    data.affinityPerVrf[{{ loop.index0 }}].affinityGroupNumber    {{ basic_affinity_per_vrf.affinity_group_number | default('not_defined') }}    {{ basic_affinity_per_vrf.affinity_group_number_variable | default('not_defined') }}    msg=basic affinity per vrfs affinity group number
    Should Be Equal Value Json Yaml    ${system_basic}    data.affinityPerVrf[{{ loop.index0 }}].vrfRange    {{ basic_affinity_per_vrf.vrf_range | default('not_defined') }}    {{ basic_affinity_per_vrf.vrf_range_variable | default('not_defined') }}    msg=basic affinity per vrfs vrf range

{% endfor %}

    Should Be Equal Value Json List Length    ${system_basic}    data.gpsLocation.geoFencing.sms.mobileNumber    {{ profile.basic.get('geo_fencing_sms_mobile_numbers', []) | length }}    msg=basic geo fencing sms mobile numbers length
{% for basic_geo_fencing_sms_mobile_number in profile.basic.geo_fencing_sms_mobile_numbers | default([]) %}

    Should Be Equal Value Json Yaml    ${system_basic}    data.gpsLocation.geoFencing.sms.mobileNumber[{{ loop.index0 }}].number    {{ basic_geo_fencing_sms_mobile_number.number | default('not_defined') }}    {{ basic_geo_fencing_sms_mobile_number.number_variable | default('not_defined') }}    msg=basic geo fencing sms mobile number

{% endfor %}


{% endif %}
{% endfor %}

{% endif %}

{% endif %}
