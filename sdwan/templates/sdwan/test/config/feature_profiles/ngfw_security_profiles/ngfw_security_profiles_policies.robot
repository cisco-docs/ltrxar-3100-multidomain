*** Settings ***
Documentation   Verify NGFW Security Feature Profile Policy and Settings Configuration
Name            NGFW Security Profiles Policies and Settings
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    ngfw_security_profiles    ngfw_policies
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.ngfw_security_profiles is defined %}
*** Test Cases ***
Get NGFW Security Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/embedded-security
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId
    ${security_local_app_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-localapp
    Set Suite Variable    ${security_local_app_lists}
    ${security_data_ipv4_prefix_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-data-ip-prefix
    Set Suite Variable    ${security_data_ipv4_prefix_lists}
    ${security_fqdn_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-fqdn
    Set Suite Variable    ${security_fqdn_lists}
    ${security_geo_location_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-geolocation
    Set Suite Variable    ${security_geo_location_lists}
    ${security_port_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-port
    Set Suite Variable    ${security_port_lists}
    ${security_protocol_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-protocolname
    Set Suite Variable    ${security_protocol_lists}
    ${security_advanced_inspection_profiles}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/unified/advanced-inspection-profile
    Set Suite Variable    ${security_advanced_inspection_profiles}
    ${security_zones}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/security-zone
    Set Suite Variable    ${security_zones}


{% for profile in sdwan.feature_profiles.get('ngfw_security_profiles', []) %}
Get NGFW Security Profile {{ profile.name }} Policies
    ${profile_json}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile_json is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile_json}    profileId
    Set Suite Variable    ${profile_id_{{ profile.name | replace('-', '_') }}}    ${profile_id}

    ${ngfw_policies_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/embedded-security/${profile_id}/unified/ngfirewall
    Set Suite Variable    ${ngfw_policies_raw_{{ profile.name | replace('-', '_') }}}    ${ngfw_policies_raw}
    Should Be Equal Value Json List Length    ${ngfw_policies_raw.json()}    data    {{ profile.get('policies', []) | length }}    msg=policies count

{% for policy in profile.get('policies', []) %}
Verify NGFW Security Profile {{ profile.name }} Policy {{ policy.name }}
    ${policy_raw}=    Json Search    ${ngfw_policies_raw_{{ profile.name | replace('-', '_') }}.json()}    data[?payload.name=='{{ policy.name }}'] | [0]
    Run Keyword If    $policy_raw is None    Fail    Policy '{{ policy.name }}' expected to be configured within the NGFW security profile '{{ profile.name }}' on the Manager
    ${policy_json}=    Set Variable    ${policy_raw}[payload]
    ${policy_parcel_id}=    Json Search String    ${policy_raw}    parcelId
    Set Suite Variable    ${policy_json_{{ policy.name | replace('-', '_') }}}    ${policy_json}
    Set Suite Variable    ${policy_parcel_id_{{ policy.name | replace('-', '_') }}}    ${policy_parcel_id}
    Should Be Equal Value Json String
    ...    ${policy_json}    name
    ...    {{ policy.name }}
    ...    msg=name
    Should Be Equal Value Json Yaml
    ...    ${policy_json}    data.defaultActionType
    ...    {{ policy.default_action | default('not_defined') }}    not_defined
    ...    msg=default_action
    Should Be Equal Value Json List Length    ${policy_json}    data.sequences    {{ policy.get('sequences', []) | length }}    msg=sequences length

{% if policy.get('sequences', []) | length > 0 %}
    Log    === Sequences List ===
{% for sequence in policy.get('sequences', []) %}
    Log    === Sequence {{ sequence.sequence_name }} ===
    ${sequence_json}=    Json Search    ${policy_json_{{ policy.name | replace('-', '_') }}}    data.sequences[?sequenceId.value=='{{ sequence.sequence_id }}'] | [0]
    Run Keyword If    $sequence_json is None    Fail    Sequence '{{ sequence.sequence_id }}' expected to be configured within policy '{{ policy.name }}' on the Manager
    Should Be Equal Value Json String
    ...    ${sequence_json}    sequenceName.value
    ...    {{ sequence.sequence_name }}
    ...    msg=sequence_name
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    baseAction
    ...    {{ sequence.base_action | default('not_defined') }}    not_defined
    ...    msg=base_action
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    sequenceType
    ...    {{ sequence.sequence_type | default(defaults.sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.sequence_type) }}    not_defined
    ...    msg=sequence_type
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    disableSequence
    ...    {{ sequence.disable_sequence | default(defaults.sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.disable_sequence) }}    not_defined
    ...    msg=disable_sequence

{% set me = sequence.get('match_entries', {}) or {} %}
    Should Be Equal Value Json List Length    ${sequence_json}    match.entries    {{ me | length if me else 0 }}    msg=match_entries count
{% if me %}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?sourceIp].sourceIp.ipv4Value | [0]
    ...    {{ me.get('source_data_ipv4_prefixes', 'not_defined') }}
    ...    {{ me.get('source_data_ipv4_prefixes_variable', 'not_defined') }}
    ...    msg=match_entries.source_data_ipv4_prefixes
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?destinationIp].destinationIp.ipv4Value | [0]
    ...    {{ me.get('destination_data_ipv4_prefixes', 'not_defined') }}
    ...    {{ me.get('destination_data_ipv4_prefixes_variable', 'not_defined') }}
    ...    msg=match_entries.destination_data_ipv4_prefixes
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?destinationFqdn].destinationFqdn.fqdnValue | [0]
    ...    {{ me.get('destination_fqdns', 'not_defined') }}
    ...    {{ me.get('destination_fqdns_variable', 'not_defined') }}
    ...    msg=match_entries.destination_fqdns
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?sourcePort].sourcePort.portValue | [0]
    ...    {{ me.get('source_ports', 'not_defined') }}
    ...    {{ me.get('source_ports_variable', 'not_defined') }}
    ...    msg=match_entries.source_ports
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?destinationPort].destinationPort.portValue | [0]
    ...    {{ me.get('destination_ports', 'not_defined') }}
    ...    {{ me.get('destination_ports_variable', 'not_defined') }}
    ...    msg=match_entries.destination_ports
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?sourceGeoLocation].sourceGeoLocation | [0]
    ...    {{ me.get('source_geo_locations', 'not_defined') }}
    ...    not_defined
    ...    msg=match_entries.source_geo_locations
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?destinationGeoLocation].destinationGeoLocation | [0]
    ...    {{ me.get('destination_geo_locations', 'not_defined') }}
    ...    not_defined
    ...    msg=match_entries.destination_geo_locations

    ${expected_protocol_names}=    Run Keyword If    "{{ me.get('protocol_names', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ me.get('protocol_names', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?protocolName].protocolName | [0]
    ...    ${expected_protocol_names}    not_defined
    ...    msg=match_entries.protocol_names

    ${protocol_list}=    Run Keyword If    "{{ me.get('protocols', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ me.get('protocols', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?protocol].protocol | [0]
    ...    ${protocol_list}    not_defined
    ...    msg=match_entries.protocols

    Should Be Equal Referenced Object Name
    ...    ${sequence_json}    match.entries[?appList] | [0].appList.refId.value
    ...    ${security_local_app_lists.json()}    {{ me.get('application_list', 'not_defined') }}
    ...    match_entries.application_list

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?sourceDataPrefixList].sourceDataPrefixList.refId.value[]    {{ me.get('source_data_ipv4_prefix_lists', []) | length }}    msg=match_entries.source_data_ipv4_prefix_lists length
{% if me.get('source_data_ipv4_prefix_lists', []) | length > 0 %}
    ${configured_src_prefix_list_ids}=    Json Search List    ${sequence_json}    match.entries[?sourceDataPrefixList].sourceDataPrefixList.refId.value[]
{% for n in me.get('source_data_ipv4_prefix_lists', []) %}
    ${expected_src_prefix_id_{{ loop.index0 }}}=    Json Search String    ${security_data_ipv4_prefix_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_src_prefix_list_ids}    ${expected_src_prefix_id_{{ loop.index0 }}}    msg=match_entries.source_data_ipv4_prefix_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?destinationDataPrefixList].destinationDataPrefixList.refId.value[]    {{ me.get('destination_data_ipv4_prefix_lists', []) | length }}    msg=match_entries.destination_data_ipv4_prefix_lists length
{% if me.get('destination_data_ipv4_prefix_lists', []) | length > 0 %}
    ${configured_dst_prefix_list_ids}=    Json Search List    ${sequence_json}    match.entries[?destinationDataPrefixList].destinationDataPrefixList.refId.value[]
{% for n in me.get('destination_data_ipv4_prefix_lists', []) %}
    ${expected_dst_prefix_id_{{ loop.index0 }}}=    Json Search String    ${security_data_ipv4_prefix_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_dst_prefix_list_ids}    ${expected_dst_prefix_id_{{ loop.index0 }}}    msg=match_entries.destination_data_ipv4_prefix_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?destinationFqdnList].destinationFqdnList.refId.value[]    {{ me.get('destination_fqdn_lists', []) | length }}    msg=match_entries.destination_fqdn_lists length
{% if me.get('destination_fqdn_lists', []) | length > 0 %}
    ${configured_dst_fqdn_list_ids}=    Json Search List    ${sequence_json}    match.entries[?destinationFqdnList].destinationFqdnList.refId.value[]
{% for n in me.get('destination_fqdn_lists', []) %}
    ${expected_dst_fqdn_id_{{ loop.index0 }}}=    Json Search String    ${security_fqdn_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_dst_fqdn_list_ids}    ${expected_dst_fqdn_id_{{ loop.index0 }}}    msg=match_entries.destination_fqdn_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?sourceGeoLocationList].sourceGeoLocationList.refId.value[]    {{ me.get('source_geo_location_lists', []) | length }}    msg=match_entries.source_geo_location_lists length
{% if me.get('source_geo_location_lists', []) | length > 0 %}
    ${configured_src_geo_list_ids}=    Json Search List    ${sequence_json}    match.entries[?sourceGeoLocationList].sourceGeoLocationList.refId.value[]
{% for n in me.get('source_geo_location_lists', []) %}
    ${expected_src_geo_id_{{ loop.index0 }}}=    Json Search String    ${security_geo_location_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_src_geo_list_ids}    ${expected_src_geo_id_{{ loop.index0 }}}    msg=match_entries.source_geo_location_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?destinationGeoLocationList].destinationGeoLocationList.refId.value[]    {{ me.get('destination_geo_location_lists', []) | length }}    msg=match_entries.destination_geo_location_lists length
{% if me.get('destination_geo_location_lists', []) | length > 0 %}
    ${configured_dst_geo_list_ids}=    Json Search List    ${sequence_json}    match.entries[?destinationGeoLocationList].destinationGeoLocationList.refId.value[]
{% for n in me.get('destination_geo_location_lists', []) %}
    ${expected_dst_geo_id_{{ loop.index0 }}}=    Json Search String    ${security_geo_location_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_dst_geo_list_ids}    ${expected_dst_geo_id_{{ loop.index0 }}}    msg=match_entries.destination_geo_location_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?sourcePortList].sourcePortList.refId.value[]    {{ me.get('source_port_lists', []) | length }}    msg=match_entries.source_port_lists length
{% if me.get('source_port_lists', []) | length > 0 %}
    ${configured_src_port_list_ids}=    Json Search List    ${sequence_json}    match.entries[?sourcePortList].sourcePortList.refId.value[]
{% for n in me.get('source_port_lists', []) %}
    ${expected_src_port_id_{{ loop.index0 }}}=    Json Search String    ${security_port_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_src_port_list_ids}    ${expected_src_port_id_{{ loop.index0 }}}    msg=match_entries.source_port_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?destinationPortList].destinationPortList.refId.value[]    {{ me.get('destination_port_lists', []) | length }}    msg=match_entries.destination_port_lists length
{% if me.get('destination_port_lists', []) | length > 0 %}
    ${configured_dst_port_list_ids}=    Json Search List    ${sequence_json}    match.entries[?destinationPortList].destinationPortList.refId.value[]
{% for n in me.get('destination_port_lists', []) %}
    ${expected_dst_port_id_{{ loop.index0 }}}=    Json Search String    ${security_port_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_dst_port_list_ids}    ${expected_dst_port_id_{{ loop.index0 }}}    msg=match_entries.destination_port_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${sequence_json}    match.entries[?protocolNameList].protocolNameList.refId.value[]    {{ me.get('protocol_name_lists', []) | length }}    msg=match_entries.protocol_name_lists length
{% if me.get('protocol_name_lists', []) | length > 0 %}
    ${configured_proto_name_list_ids}=    Json Search List    ${sequence_json}    match.entries[?protocolNameList].protocolNameList.refId.value[]
{% for n in me.get('protocol_name_lists', []) %}
    ${expected_proto_name_id_{{ loop.index0 }}}=    Json Search String    ${security_protocol_lists.json()}    data[?payload.name=='{{ n }}'] | [0].parcelId
    Should Contain    ${configured_proto_name_list_ids}    ${expected_proto_name_id_{{ loop.index0 }}}    msg=match_entries.protocol_name_lists: '{{ n }}' not found
{% endfor %}
{% endif %}

    ${expected_src_id_users}=    Run Keyword If    "{{ me.get('source_identity_users', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ me.get('source_identity_users', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?sourceIdentityUser].sourceIdentityUser | [0]
    ...    ${expected_src_id_users}    not_defined
    ...    msg=match_entries.source_identity_users
    ${expected_src_id_ug}=    Run Keyword If    "{{ me.get('source_identity_usergroups', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ me.get('source_identity_usergroups', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    match.entries[?sourceIdentityUsergroup].sourceIdentityUsergroup | [0]
    ...    ${expected_src_id_ug}    not_defined
    ...    msg=match_entries.source_identity_usergroups
{% endif %}

{% set act = sequence.get('actions', {}) or {} %}
{% set log_raw = act.get('log') %}
{% set log_value = log_raw if log_raw is not none else (defaults.sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.actions.log | default(false)) %}
{% if sequence.get('base_action') != 'inspect' %}
    Should Be Equal Value Json List Length    ${sequence_json}    actions[?type.value=='log']    {{ 1 if log_value else 0 }}    msg=actions.log count
{% if log_value %}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    actions[?type.value=='log'] | [0].parameter
    ...    {{ log_value | string | lower }}    not_defined
    ...    msg=actions.log
{% endif %}
{% else %}
    Should Be Equal Value Json List Length    ${sequence_json}    actions[?type.value=='connectionEvents']    {{ 1 if log_value else 0 }}    msg=actions.log count
{% if log_value %}
    Should Be Equal Value Json Yaml
    ...    ${sequence_json}    actions[?type.value=='connectionEvents'] | [0].parameter
    ...    {{ log_value | string | lower }}    not_defined
    ...    msg=actions.log
{% endif %}
    Should Be Equal Value Json List Length    ${sequence_json}    actions[?type.value=='advancedInspectionProfile']    {{ 1 if act.get('advanced_inspection_profile') is not none else 0 }}    msg=actions.advanced_inspection_profile count
{% if act.get('advanced_inspection_profile') is not none %}
    Should Be Equal Referenced Object Name
    ...    ${sequence_json}    actions[?type.value=='advancedInspectionProfile'] | [0].parameter.refId.value
    ...    ${security_advanced_inspection_profiles.json()}    {{ act.get('advanced_inspection_profile') }}
    ...    actions.advanced_inspection_profile
{% endif %}
{% endif %}

{% endfor %}
{% endif %}
{% endfor %}

{% if profile.get('settings') is not none or profile.get('policies') is not none %}
Get NGFW Security Profile {{ profile.name }} Policy Configuration
    ${policy_config_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/embedded-security/${profile_id_{{ profile.name | replace('-', '_') }}}/policy
    Set Suite Variable    ${policy_config_raw_{{ profile.name | replace('-', '_') }}}    ${policy_config_raw}

Verify NGFW Security Profile {{ profile.name }} Settings
    ${policy_config_json}=    Json Search    ${policy_config_raw_{{ profile.name | replace('-', '_') }}.json()}    data[0].payload
    Run Keyword If    $policy_config_json is None    Fail    Policy configuration expected to be configured within the NGFW security profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${policy_config_json_{{ profile.name | replace('-', '_') }}}    ${policy_config_json}

{% set settings = profile.get('settings', {}) or {} %}
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.auditTrail
    ...    {{ settings.get('audit_trail', 'not_defined') }}    not_defined
    ...    msg=settings.audit_trail
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.unifiedLogging
    ...    {{ settings.get('unified_logging', 'not_defined') }}    not_defined
    ...    msg=settings.unified_logging
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.failureMode
    ...    {{ settings.get('failure_mode', 'not_defined') }}    not_defined
    ...    msg=settings.failure_mode
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.tcpSynFloodLimit
    ...    {{ settings.get('tcp_syn_flood_limit', 'not_defined') }}    not_defined
    ...    msg=settings.tcp_syn_flood_limit
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.maxIncompleteTcpLimit
    ...    {{ settings.get('max_incomplete_tcp_limit', 'not_defined') }}    not_defined
    ...    msg=settings.max_incomplete_tcp_limit
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.maxIncompleteUdpLimit
    ...    {{ settings.get('max_incomplete_udp_limit', 'not_defined') }}    not_defined
    ...    msg=settings.max_incomplete_udp_limit
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.maxIncompleteIcmpLimit
    ...    {{ settings.get('max_incomplete_icmp_limit', 'not_defined') }}    not_defined
    ...    msg=settings.max_incomplete_icmp_limit
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.sessionReclassifyAllow
    ...    {{ settings.get('session_reclassify_allow', 'not_defined') }}    not_defined
    ...    msg=settings.session_reclassify_allow
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.settings.icmpUnreachableAllow
    ...    {{ settings.get('icmp_unreachable_allow', 'not_defined') }}    not_defined
    ...    msg=settings.icmp_unreachable_allow

{% set app_hosting = settings.get('app_hosting', {}) or {} %}
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.appHosting.nat
    ...    {{ app_hosting.get('nat', 'not_defined') }}
    ...    {{ app_hosting.get('nat_variable', 'not_defined') }}
    ...    msg=settings.app_hosting.nat
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.appHosting.databaseUrl
    ...    {{ app_hosting.get('download_url_database_on_device', 'not_defined') }}
    ...    {{ app_hosting.get('download_url_database_on_device_variable', 'not_defined') }}
    ...    msg=settings.app_hosting.download_url_database_on_device
    Should Be Equal Value Json Yaml
    ...    ${policy_config_json}    data.appHosting.resourceProfile
    ...    {{ app_hosting.get('resource_profile', 'not_defined') }}
    ...    {{ app_hosting.get('resource_profile_variable', 'not_defined') }}
    ...    msg=settings.app_hosting.resource_profile

{% set expected_assembly_count = profile.get('policies', []) | length + (1 if settings.get('advanced_inspection_profile') is not none else 0) %}
    Should Be Equal Value Json List Length    ${policy_config_json}    data.assembly    {{ expected_assembly_count }}    msg=data.assembly total entries count
    Should Be Equal Value Json List Length    ${policy_config_json}    data.assembly[?advancedInspectionProfile]    {{ 1 if settings.get('advanced_inspection_profile') is not none else 0 }}    msg=settings.advanced_inspection_profile length
{% if settings.get('advanced_inspection_profile') is not none %}
    Should Be Equal Referenced Object Name
    ...    ${policy_config_json}    data.assembly[?advancedInspectionProfile].advancedInspectionProfile.refId.value
    ...    ${security_advanced_inspection_profiles.json()}    {{ settings.get('advanced_inspection_profile') }}
    ...    settings.advanced_inspection_profile
{% endif %}

Verify NGFW Security Profile {{ profile.name }} Zone Mapping
{% for policy in profile.get('policies', []) %}
    Log    === Zone Mapping: {{ policy.name }} ===
    ${zone_mapping}=    Json Search    ${policy_config_json_{{ profile.name | replace('-', '_') }}}    data.assembly[?ngfirewall.refId.value=='${policy_parcel_id_{{ policy.name | replace('-', '_') }}}'] | [0].ngfirewall
    Run Keyword If    $zone_mapping is None    Fail    No zone mapping entry found for policy '{{ policy.name }}' in profile '{{ profile.name }}'
    Should Be Equal Value Json List Length    ${zone_mapping}    entries    {{ policy.get('destination_zones', []) | length }}    msg=zone_mapping[{{ policy.name }}].entries length
{% if policy.get('source_zone') in ['self', 'untrusted', 'no_zone'] %}
    Should Be Equal Value Json Yaml
    ...    ${zone_mapping}    entries[0].srcZone
    ...    {{ 'default' if policy.get('source_zone') == 'no_zone' else policy.get('source_zone') }}    not_defined
    ...    msg=zone_mapping[{{ policy.name }}].source_zone
{% else %}
    Should Be Equal Referenced Object Name
    ...    ${zone_mapping}    entries[0].srcZone.refId.value
    ...    ${security_zones.json()}    {{ policy.get('source_zone') }}
    ...    zone_mapping[{{ policy.name }}].source_zone
{% endif %}
{% for dst_zone in policy.get('destination_zones', []) %}
{% if dst_zone in ['self', 'untrusted', 'no_zone'] %}
    Should Be Equal Value Json Yaml
    ...    ${zone_mapping}    entries[{{ loop.index0 }}].dstZone
    ...    {{ 'default' if dst_zone == 'no_zone' else dst_zone }}    not_defined
    ...    msg=zone_mapping[{{ policy.name }}].destination_zones[{{ loop.index0 }}]
{% else %}
    Should Be Equal Referenced Object Name
    ...    ${zone_mapping}    entries[{{ loop.index0 }}].dstZone.refId.value
    ...    ${security_zones.json()}    {{ dst_zone }}
    ...    zone_mapping[{{ policy.name }}].destination_zones[{{ loop.index0 }}]
{% endif %}
{% endfor %}
{% endfor %}

{% endif %}
{% endfor %}

{% endif %}
