*** Settings ***
Documentation   Verify Configuration Group Configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    configuration_groups
Resource        ../sdwan_common.resource

{% if sdwan.configuration_groups is defined %}

*** Test Cases ***
Get Configuration Groups
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/config-group
    Set Suite Variable    ${r}

{% for configuration_group in sdwan.configuration_groups | default([]) %}

Verify Configuration Group {{ configuration_group.name }}
    ${cfg}=    Json Search    ${r.json()}    [?name=='{{ configuration_group.name }}'] | [0]
    Run Keyword If    $cfg is None    Fail    Configuration Group '{{configuration_group.name}}' should be present on the Manager

    Should Be Equal Value Json String    ${cfg}    name    {{ configuration_group.name }}    msg=name
    Should Be Equal Value Json Special_String    ${cfg}    description    {{ configuration_group.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json String    ${cfg}    profiles[?type=='cli'] | [0].name    {{ configuration_group.cli_profile | default('not_defined') }}    msg=cli_profile
    Should Be Equal Value Json String    ${cfg}    profiles[?type=='other'] | [0].name    {{ configuration_group.other_profile | default('not_defined') }}    msg=other_profile
    Should Be Equal Value Json String    ${cfg}    profiles[?type=='policy-object'] | [0].name    {{ configuration_group.policy_object_profile | default('not_defined') }}    msg=policy_object_profile
    Should Be Equal Value Json String    ${cfg}    profiles[?type=='service'] | [0].name    {{ configuration_group.service_profile | default('not_defined') }}    msg=service_profile
    Should Be Equal Value Json String    ${cfg}    profiles[?type=='system'] | [0].name    {{ configuration_group.system_profile | default('not_defined') }}    msg=system_profile
    Should Be Equal Value Json String    ${cfg}    profiles[?type=='transport'] | [0].name    {{ configuration_group.transport_profile | default('not_defined') }}    msg=transport_profile

    Should Be Equal Value Json List Length    ${cfg}    topology.devices    {{ configuration_group.get('device_tags', []) | length }}    msg=device_tags count
{% if configuration_group.get('device_tags', []) | length == 2 %}
    Log    === Dual Device Site ===

    # extract transport profile ID and service profile ID
    ${transport_id}=    Json Search String    ${cfg}    profiles[?type=='transport'] | [0].id
    Run Keyword If    $transport_id == ''    Fail    Transport profile not found in configuration group '{{ configuration_group.name }}'
    ${service_id}=    Json Search String    ${cfg}    profiles[?type=='service'] | [0].id
    Run Keyword If    $service_id == ''    Fail    Service profile not found in configuration group '{{ configuration_group.name }}'

    # get transport profile details
    ${transport_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${transport_id}
    Run Keyword If    ${transport_res.json()} == []    Fail    The transport profile '{{ configuration_group.transport_profile | default('not_defined') }}' should be present on the Manager
    ${transport_associated_profiles}=    Json Search    ${transport_res.json()}    associatedProfileParcels

    # get service profile details
    ${service_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${service_id}
    Run Keyword If    ${service_res.json()} == []    Fail    The service profile '{{ configuration_group.service_profile | default('not_defined') }}' should be present on the Manager
    ${service_associated_profiles}=    Json Search    ${service_res.json()}    associatedProfileParcels

    # Create ID to name mapping for all features in both profiles
    ${id_to_name_map}=    Evaluate    {p['parcelId']: p['payload']['name'] for profile_parcels in [$transport_associated_profiles, $service_associated_profiles] for parcel in profile_parcels for p in ([parcel] if parcel.get('payload', {}).get('name') else []) + parcel.get('subparcels', []) + [sp for sub in parcel.get('subparcels', []) for sp in sub.get('subparcels', [])] + [ssp for sub in parcel.get('subparcels', []) for sp in sub.get('subparcels', []) for ssp in sp.get('subparcels', [])] if p.get('payload', {}).get('name')}
    ${available_feature_names}=    Evaluate    set($id_to_name_map.values())

    ${unsupported_features_ids_device1}=    Json Search List    ${cfg}    topology.devices[0].unsupportedFeatures[].parcelId
    ${unsupported_features_ids_device2}=    Json Search List    ${cfg}    topology.devices[1].unsupportedFeatures[].parcelId

    # Convert unsupported feature IDs to names
    ${unsupported_features_names_device1}=    Evaluate    [${id_to_name_map}.get(id, id) for id in $unsupported_features_ids_device1]
    ${unsupported_features_names_device2}=    Evaluate    [${id_to_name_map}.get(id, id) for id in $unsupported_features_ids_device2]

    # two dimensional list of devices features (by name)
    @{feature_list_devices} =    Create List
{% for device_tag in configuration_group.get('device_tags', []) %}
    Log    Device Tag: {{ device_tag.name }}
    Should Be Equal Value Json String    ${cfg}    topology.devices[{{ loop.index0 }}].criteria.value    {{ device_tag.name | default('not_defined') }}    msg=device_tag_name

    @{feature_list} =    Create List
{% for feature in device_tag.get('features', []) %}
    Log    Feature: {{ feature }}

    # Verify feature exists in one of the profiles
    ${feature_exists}=    Evaluate    '{{ feature }}' in $available_feature_names
    Run Keyword If    not $feature_exists    Fail    Feature '{{ feature }}' should be present on the Manager
    Append To List    ${feature_list}    {{ feature }}

{% endfor %}

    Append To List    ${feature_list_devices}    ${feature_list}
{% endfor %}

    Log    Feature List Devices: ${feature_list_devices}
    # features defined in 1st device should be the same as the unsupported features list on 2nd device, vice versa
    Lists Should Be Equal    ${feature_list_devices[0]}    ${unsupported_features_names_device2}    ignore_order=True
    Lists Should Be Equal    ${feature_list_devices[1]}    ${unsupported_features_names_device1}    ignore_order=True

{% endif %}

{% endfor %}

{% endif %}
