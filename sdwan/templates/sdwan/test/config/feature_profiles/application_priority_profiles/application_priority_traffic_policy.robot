*** Settings ***
Documentation   Verify Application Priority Feature Profile Configuration Traffic Policy
Name            Application Priority Traffic Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles     application_priority_profiles   traffic_policies
Resource        ../../../sdwan_common.resource


{% set profile_traffic_policy_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('application_priority_profiles', []) %}
 {% if profile.traffic_policies is defined %}
  {% set _ = profile_traffic_policy_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_traffic_policy_list != [] %}

*** Variables ***
# Value mappings for data model to API conversions
{% set traffic_category_map = {'optimize-allow': 'optimizeAllow'} %}
{% set secure_service_edge_instance_map = {'cisco-secure-access': 'Cisco-Secure-Access', 'zscaler': 'zScaler'} %}
{% set redirect_dns_type_map = {'ip-address': 'ipAddress', 'dns-host': 'dnsHost'} %}
{% set loss_correct_type_map = {'fec-adaptive': 'fecAdaptive', 'fec-always': 'fecAlways', 'packet-duplication': 'packetDuplication'} %}

*** Test Cases ***
Get Application Priority Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    ${profile_po}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}'] | [0]
    Run Keyword If    $profile_po is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name | default(defaults.sdwan.feature_profiles.policy_object_profile.name) }}' should be present on the Manager
    ${profile_po_id}=    Json Search String    ${profile_po}    profileId
    ${application_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/app-list
    Set Suite Variable    ${application_lists}
    ${sla_class_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/sla-class
    Set Suite Variable    ${sla_class_lists}
    ${data_ipv4_prefix_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/data-prefix
    Set Suite Variable    ${data_ipv4_prefix_lists}
    ${data_ipv6_prefix_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/data-ipv6-prefix
    Set Suite Variable    ${data_ipv6_prefix_lists}
    ${tloc_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/tloc
    Set Suite Variable    ${tloc_lists}
    ${policer_lists}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/policer
    Set Suite Variable    ${policer_lists}
    ${preferred_color_groups}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/preferred-color-group
    Set Suite Variable    ${preferred_color_groups}
    ${class_maps}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_po_id}/class
    Set Suite Variable    ${class_maps}

{% for profile in sdwan.feature_profiles.application_priority_profiles | default([]) %}
{% if profile.traffic_policies is defined %}

Setup Profile Context - {{ profile.name }}
    [Documentation]    Sets up profile context for all traffic policies under {{ profile.name }}

    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}

    # Fetch full profile details to get associatedProfileParcels
    ${profile_details_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}
    ${profile_details}=    Set Variable    ${profile_details_res.json()}

    # Get traffic policy parcels from profile's associatedProfileParcels
    ${traffic_policy_parcels}=    Json Search List    ${profile_details}    associatedProfileParcels[?parcelType=='traffic-policy']
    Run Keyword If    ${traffic_policy_parcels} == []    Fail    Traffic Policy feature(s) expected to be configured within the application priority profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${traffic_policy_parcels}

{% for traffic_policy in profile.traffic_policies | default([]) %}
Verify Profile {{ profile.name }} - Traffic Policy {{ traffic_policy.name }}
    [Documentation]    Validates traffic policy '{{ traffic_policy.name }}' in application priority profile '{{ profile.name }}'

    Log    === Traffic Policy: {{ traffic_policy.name }} ===

    # Find the traffic policy parcel by name from associatedProfileParcels
    ${traffic_policy_parcel}=    Json Search    ${traffic_policy_parcels}    [?payload.name=='{{ traffic_policy.name }}'] | [0]
    Run Keyword If    $traffic_policy_parcel is None    Fail    Traffic Policy '{{ traffic_policy.name }}' not found in application priority profile '{{ profile.name }}'
    ${traffic_policy_parcel_id}=    Json Search String    ${traffic_policy_parcel}    parcelId
    ${traffic_policy_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/application-priority/${profile_id}/traffic-policy/${traffic_policy_parcel_id}
    ${traffic_policy}=    Set Variable    ${traffic_policy_res.json()}

    Should Be Equal Value Json String
    ...    ${traffic_policy}    payload.name
    ...    {{ traffic_policy.name }}
    ...    msg=name

    Should Be Equal Value Json Yaml
    ...    ${traffic_policy}    payload.data.dataDefaultAction
    ...    {{ traffic_policy.default_action }}    not_defined
    ...    msg=traffic_policy.default_action

    ${expected_vpns}=    Run Keyword If    "{{ traffic_policy.get('vpns', []) | length == 0 }}" == "True"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ traffic_policy.get('vpns', []) }}
    Should Be Equal Value Json Yaml
    ...    ${traffic_policy}    payload.data.target.vpn
    ...    ${expected_vpns}    not_defined
    ...    msg=traffic_policy.vpns

    Should Be Equal Value Json Yaml
    ...    ${traffic_policy}    payload.data.target.direction
    ...    {{ traffic_policy.direction }}    not_defined
    ...    msg=traffic_policy.direction

    # Validate sequences
    Should Be Equal Value Json List Length    ${traffic_policy}    payload.data.sequences    {{ traffic_policy.get('sequences', []) | length }}    msg=sequences length
{% if traffic_policy.get('sequences', []) | length > 0 %}
    Log    === Sequences List ===
{% for sequence in traffic_policy.sequences | default([]) %}
    Log    === Sequence {{ sequence.sequence_name }} ===
    ${sequence}=    Json Search    ${traffic_policy}    payload.data.sequences[{{ loop.index0 }}]
    Run Keyword If    $sequence is None    Fail    Sequence index {{ loop.index0 }} expected to be configured on the Manager

    # Transform data model sequence_id to API sequenceId using formula: (user_id - 1) * 10 + 1
    Should Be Equal Value Json Yaml
    ...    ${sequence}    sequenceId
    ...    {{ (sequence.sequence_id - 1) * 10 + 1 }}    not_defined
    ...    msg=sequence.sequence_id
    Should Be Equal Value Json Yaml
    ...    ${sequence}    sequenceName
    ...    {{ sequence.sequence_name }}    not_defined
    ...    msg=sequence.sequence_name
    Should Be Equal Value Json Yaml
    ...    ${sequence}    baseAction
    ...    {{ sequence.base_action }}    not_defined
    ...    msg=sequence.base_action
    Should Be Equal Value Json Yaml
    ...    ${sequence}    sequenceIpType
    ...    {{ sequence.protocol | default(defaults.sdwan.feature_profiles.application_priority_profiles.traffic_policies.sequences.protocol) }}    not_defined
    ...    msg=sequence.protocol

    Log    === Match Entries ===
    ${match_entries}=    Json Search    ${sequence}    match.entries[0]
    Run Keyword If    $match_entries is None    Fail    Match entries expected to be configured in sequence {{ sequence.sequence_id }}

    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?appList] | [0].appList.refId.value
    ...    ${application_lists.json()}    {{ sequence.match_entries.get('application_list') if sequence.match_entries.get('application_list') else 'not_defined'}}
    ...    match_entries.application_list

    ${dscp_list}=    Run Keyword If    "{{ sequence.match_entries.get('dscps', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ sequence.match_entries.get('dscps', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?dscp] | [0].dscp
    ...    ${dscp_list}    not_defined
    ...    msg=match_entries.dscps
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?sourceIp] | [0].sourceIp
    ...    {{ sequence.match_entries.get('source_ipv4_prefix') if sequence.match_entries.get('source_ipv4_prefix') else 'not_defined' }}    not_defined
    ...    msg=match_entries.source_ipv4_prefix
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?destinationIp] | [0].destinationIp
    ...    {{ sequence.match_entries.get('destination_ipv4_prefix') if sequence.match_entries.get('destination_ipv4_prefix') else 'not_defined' }}    not_defined
    ...    msg=match_entries.destination_ipv4_prefix
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?sourceIpv6] | [0].sourceIpv6
    ...    {{ sequence.match_entries.get('source_ipv6_prefix') if sequence.match_entries.get('source_ipv6_prefix') else 'not_defined' }}    not_defined
    ...    msg=match_entries.source_ipv6_prefix
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?destinationIpv6] | [0].destinationIpv6
    ...    {{ sequence.match_entries.get('destination_ipv6_prefix') if sequence.match_entries.get('destination_ipv6_prefix') else 'not_defined' }}    not_defined
    ...    msg=match_entries.destination_ipv6_prefix

    # Validate source_data_ipv4_prefix_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?sourceDataPrefixList] | [0].sourceDataPrefixList.refId.value
    ...    ${data_ipv4_prefix_lists.json()}    {{ sequence.match_entries.get('source_data_ipv4_prefix_list') if sequence.match_entries.get('source_data_ipv4_prefix_list') else 'not_defined'}}
    ...    match_entries.source_data_ipv4_prefix_list

    # Validate destination_data_ipv4_prefix_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?destinationDataPrefixList] | [0].destinationDataPrefixList.refId.value
    ...    ${data_ipv4_prefix_lists.json()}    {{ sequence.match_entries.get('destination_data_ipv4_prefix_list') if sequence.match_entries.get('destination_data_ipv4_prefix_list') else 'not_defined' }}
    ...    match_entries.destination_data_ipv4_prefix_list

    # Validate source_data_ipv6_prefix_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?sourceDataIpv6PrefixList] | [0].sourceDataIpv6PrefixList.refId.value
    ...    ${data_ipv6_prefix_lists.json()}    {{ sequence.match_entries.get('source_data_ipv6_prefix_list') if sequence.match_entries.get('source_data_ipv6_prefix_list') else 'not_defined' }}
    ...    match_entries.source_data_ipv6_prefix_list

    # Validate destination_data_ipv6_prefix_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?destinationDataIpv6PrefixList] | [0].destinationDataIpv6PrefixList.refId.value
    ...    ${data_ipv6_prefix_lists.json()}    {{ sequence.match_entries.get('destination_data_ipv6_prefix_list') if sequence.match_entries.get('destination_data_ipv6_prefix_list') else 'not_defined' }}
    ...    match_entries.destination_data_ipv6_prefix_list

    ${protocol_list}=    Run Keyword If    "{{ sequence.match_entries.get('protocols', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ sequence.match_entries.get('protocols', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?protocol] | [0].protocol
    ...    ${protocol_list}    not_defined
    ...    msg=match_entries.protocols

     # Unified destination_ports handling 
    ${destination_port_list}=    Run Keyword If    "{{ sequence.match_entries.get('destination_ports', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ sequence.match_entries.get('destination_ports', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?destinationPort] | [0].destinationPort
    ...    ${destination_port_list}    not_defined
    ...    msg=match_entries.destination_ports
 # Unified source_ports handling (accepts both integers and range strings)
    ${source_port_list}=    Run Keyword If    "{{ sequence.match_entries.get('source_ports', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ sequence.match_entries.get('source_ports', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?sourcePort] | [0].sourcePort
    ...    ${source_port_list}    not_defined
    ...    msg=match_entries.source_ports
    ${icmp_message_list}=    Run Keyword If    "{{ sequence.match_entries.get('icmp_messages', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.match_entries.get('icmp_messages', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?icmpMessage] | [0].icmpMessage
    ...    ${icmp_message_list}    not_defined
    ...    msg=match_entries.icmp_messages
    ${icmp6_message_list}=    Run Keyword If    "{{ sequence.match_entries.get('icmp6_messages', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.match_entries.get('icmp6_messages', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?icmp6Message] | [0].icmp6Message
    ...    ${icmp6_message_list}    not_defined
    ...    msg=match_entries.icmp6_messages
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?trafficClass] | [0].trafficClass
    ...    {{ sequence.match_entries.get('traffic_class') if sequence.match_entries.get('traffic_class') else 'not_defined' }}    not_defined
    ...    msg=match_entries.traffic_class
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?dns] | [0].dns
    ...    {{ sequence.match_entries.get('dns') if sequence.match_entries.get('dns') else 'not_defined' }}    not_defined
    ...    msg=match_entries.dns
    # Validate dns_application_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?dnsAppList] | [0].dnsAppList.refId.value
    ...    ${application_lists.json()}    {{ sequence.match_entries.get('dns_application_list') if sequence.match_entries.get('dns_application_list') else 'not_defined' }}
    ...    match_entries.dns_application_list

    # Validate saas_application_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    match.entries[?saasAppList] | [0].saasAppList.refId.value
    ...    ${application_lists.json()}    {{ sequence.match_entries.get('saas_application_list') if sequence.match_entries.get('saas_application_list') else 'not_defined' }}
    ...    match_entries.saas_application_list
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?packetLength] | [0].packetLength
    ...    {{ sequence.match_entries.get('packet_length') | string if sequence.match_entries.get('packet_length') else 'not_defined' }}    not_defined
    ...    msg=match_entries.packet_length
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?tcp] | [0].tcp
    ...    {{ sequence.match_entries.get('tcp') if sequence.match_entries.get('tcp') else 'not_defined' }}    not_defined
    ...    msg=match_entries.tcp
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?trafficTo] | [0].trafficTo
    ...    {{ sequence.match_entries.get('traffic_to') if sequence.match_entries.get('traffic_to') else 'not_defined' }}    not_defined
    ...    msg=match_entries.traffic_to
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?trafficCategory] | [0].trafficCategory
    ...    {{ traffic_category_map.get(sequence.match_entries.get('traffic_category'), sequence.match_entries.get('traffic_category')) if sequence.match_entries.get('traffic_category') else 'not_defined' }}    not_defined
    ...    msg=match_entries.traffic_category
    ${service_areas_list}=    Run Keyword If    "{{ sequence.match_entries.get('service_areas', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.match_entries.get('service_areas', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?serviceArea] | [0].serviceArea
    ...    ${service_areas_list}    not_defined
    ...    msg=match_entries.service_areas
    Should Be Equal Value Json Yaml
    ...    ${sequence}    match.entries[?destRegion] | [0].destRegion
    ...    {{ sequence.match_entries.get('destination_region') if sequence.match_entries.get('destination_region') else 'not_defined' }}    not_defined
    ...    msg=match_entries.destination_region
    # Validate actions if present
{% if sequence.get('actions') %}
    Log    === Actions ===
    ${actions}=    Json Search    ${sequence}    actions[0]
    Run Keyword If    $actions is None    Fail    Actions expected to be configured in sequence {{ sequence.sequence_id }}

    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?dscp] | [0].dscp
    ...    {{ sequence.actions.get('dscp') if sequence.actions.get('dscp') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.dscp
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?log] | [0].log
    ...    {{ sequence.actions.get('log') if sequence.actions.get('log') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.log
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?count] | [0].count
    ...    {{ sequence.actions.get('counter_name') if sequence.actions.get('counter_name') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.counter_name
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?cflowd] | [0].cflowd
    ...    {{ sequence.actions.get('cflowd') if sequence.actions.get('cflowd') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.cflowd
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?cloudSaas] | [0].cloudSaas
    ...    {{ sequence.actions.get('cloud_saas') if sequence.actions.get('cloud_saas') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.cloud_saas
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?cloudProbe] | [0].cloudProbe
    ...    {{ sequence.actions.get('cloud_probe') if sequence.actions.get('cloud_probe') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.cloud_probe
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?nextHop] | [0].nextHop
    ...    {{ sequence.actions.get('next_hop_ipv4') if sequence.actions.get('next_hop_ipv4') else 'not_defined' }}    not_defined
    ...    msg=actions.next_hop_ipv4
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?nextHopIpv6] | [0].nextHopIpv6
    ...    {{ sequence.actions.get('next_hop_ipv6') if sequence.actions.get('next_hop_ipv6') else 'not_defined' }}    not_defined
    ...    msg=actions.next_hop_ipv6
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?nextHopLoose] | [0].nextHopLoose
    ...    {{ sequence.actions.get('next_hop_loose') if sequence.actions.get('next_hop_loose') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.next_hop_loose
    # Validate forwarding_class reference (class_map)
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?forwardingClass] | [0].forwardingClass.refId.value
    ...    ${class_maps.json()}    {{ sequence.actions.get('forwarding_class') if sequence.actions.get('forwarding_class') else 'not_defined' }}
    ...    actions.forwarding_class

    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?lossCorrection] | [0].lossCorrection.lossCorrectionType
    ...    {{ loss_correct_type_map.get(sequence.actions.get('loss_correct_type'), sequence.actions.get('loss_correct_type')) if sequence.actions.get('loss_correct_type') else 'not_defined' }}    not_defined
    ...    msg=actions.loss_correct_type
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?lossCorrection] | [0].lossCorrection.lossCorrectFec
    ...    {{ sequence.actions.get('loss_correct_fec_threshold') if sequence.actions.get('loss_correct_fec_threshold') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.loss_correct_fec_threshold
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?natPool] | [0].natPool
    ...    {{ sequence.actions.get('nat_pool') if sequence.actions.get('nat_pool') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.nat_pool
    # Validate policer reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?policer] | [0].policer.refId.value
    ...    ${policer_lists.json()}    {{ sequence.actions.get('policer_list') if sequence.actions.get('policer_list') else 'not_defined' }}
    ...    actions.policer_list


    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?vpn] | [0].vpn
    ...    {{ sequence.actions.get('vpn') if sequence.actions.get('vpn') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.vpn
    # Validate preferred_color_group reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?preferredColorGroup] | [0].preferredColorGroup.refId.value
    ...    ${preferred_color_groups.json()}    {{ sequence.actions.get('preferred_color_group') if sequence.actions.get('preferred_color_group') else 'not_defined' }}
    ...    actions.preferred_color_group

    ${backup_sla_colors_list}=    Run Keyword If    "{{ sequence.actions.get('backup_sla_preferred_colors', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('backup_sla_preferred_colors', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?backupSlaPreferredColors] | [0].backupSlaPreferredColors
    ...    ${backup_sla_colors_list}    not_defined
    ...    msg=actions.backup_sla_preferred_colors
    ${preferred_remote_colors_list}=    Run Keyword If    "{{ sequence.actions.get('preferred_remote_colors', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('preferred_remote_colors', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?preferredRemoteColor] | [0].preferredRemoteColor
    ...    ${preferred_remote_colors_list}    not_defined
    ...    msg=actions.preferred_remote_colors
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?preferredRemoteColorRestrict] | [0].remoteColorRestrict
    ...    {{ sequence.actions.get('preferred_remote_color_restrict') if sequence.actions.get('preferred_remote_color_restrict') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.preferred_remote_color_restrict
    # Validate local_tloc fields
    ${local_tloc_colors_list}=    Run Keyword If    "{{ sequence.actions.get('local_tloc', {}).get('colors', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('local_tloc', {}).get('colors', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?localTlocList] | [0].localTlocList.color
    ...    ${local_tloc_colors_list}    not_defined
    ...    msg=actions.local_tloc.colors
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?localTlocList] | [0].localTlocList.encap
    ...    {{ sequence.actions.get('local_tloc', {}).get('encapsulation') if sequence.actions.get('local_tloc', {}).get('encapsulation') else 'not_defined' }}    not_defined
    ...    msg=actions.local_tloc.encapsulation
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?localTlocList] | [0].localTlocList.restrict
    ...    {{ sequence.actions.get('local_tloc', {}).get('restrict') if sequence.actions.get('local_tloc', {}).get('restrict') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.local_tloc.restrict
    # Validate nat_vpn fields
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?nat] | [0].nat.useVpn
    ...    {{ sequence.actions.get('nat_vpn', {}).get('nat_vpn_0') if sequence.actions.get('nat_vpn', {}).get('nat_vpn_0') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.nat_vpn.nat_vpn_0
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?nat] | [0].nat.fallback
    ...    {{ sequence.actions.get('nat_vpn', {}).get('fallback') if sequence.actions.get('nat_vpn', {}).get('fallback') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.nat_vpn.fallback
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?nat] | [0].nat.bypass
    ...    {{ sequence.actions.get('nat_vpn', {}).get('bypass') if sequence.actions.get('nat_vpn', {}).get('bypass') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.nat_vpn.bypass
    ${nat_dia_pools_list}=    Run Keyword If    "{{ sequence.actions.get('nat_vpn', {}).get('dia_pools', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    [str(x) for x in {{ sequence.actions.get('nat_vpn', {}).get('dia_pools', []) }}]
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?nat] | [0].nat.diaPool
    ...    ${nat_dia_pools_list}    not_defined
    ...    msg=actions.nat_vpn.dia_pools
    ${nat_dia_interfaces_list}=    Run Keyword If    "{{ sequence.actions.get('nat_vpn', {}).get('dia_interfaces', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('nat_vpn', {}).get('dia_interfaces', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?nat] | [0].nat.diaInterface
    ...    ${nat_dia_interfaces_list}    not_defined
    ...    msg=actions.nat_vpn.dia_interfaces
    # Validate redirect_dns fields
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?redirectDns] | [0].redirectDns.field
    ...    {{ redirect_dns_type_map.get(sequence.actions.get('redirect_dns_type'), sequence.actions.get('redirect_dns_type')) if sequence.actions.get('redirect_dns_type') else 'not_defined' }}    not_defined
    ...    msg=actions.redirect_dns_type
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?redirectDns] | [0].redirectDns.value
    ...    {{ sequence.actions.get('redirect_dns_target') if sequence.actions.get('redirect_dns_target') else 'not_defined' }}    not_defined
    ...    msg=actions.redirect_dns_target
    # Validate sig_sse fields
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?sig] | [0].sig
    ...    {{ sequence.actions.get('sig_sse', {}).get('internet_gateway') if sequence.actions.get('sig_sse', {}).get('internet_gateway') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.sig_sse.internet_gateway
    # Validate sla_class fields
    # Validate sla_class_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?slaName] | [0].slaName.refId.value
    ...    ${sla_class_lists.json()}    {{ sequence.actions.get('sla_class', {}).get('sla_class_list') if sequence.actions.get('sla_class', {}).get('sla_class_list') else 'not_defined' }}
    ...    actions.sla_class.sla_class_list

    ${sla_preferred_colors_list}=    Run Keyword If    "{{ sequence.actions.get('sla_class', {}).get('preferred_colors', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('sla_class', {}).get('preferred_colors', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?preferredColor] | [0].preferredColor
    ...    ${sla_preferred_colors_list}    not_defined
    ...    msg=actions.sla_class.preferred_colors
    # Validate sla_class preferred_color_group reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?preferredColorGroup] | [0].preferredColorGroup.refId.value
    ...    ${preferred_color_groups.json()}    {{ sequence.actions.get('sla_class', {}).get('preferred_color_group') if sequence.actions.get('sla_class', {}).get('preferred_color_group') else 'not_defined' }}
    ...    actions.sla_class.preferred_color_group

    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?strict] | [0].strict
    ...    {{ sequence.actions.get('sla_class', {}).get('strict') if sequence.actions.get('sla_class', {}).get('strict') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.sla_class.strict
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?fallbackToBestPath] | [0].fallbackToBestPath
    ...    {{ sequence.actions.get('sla_class', {}).get('fallback_to_best_path') if sequence.actions.get('sla_class', {}).get('fallback_to_best_path') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.sla_class.fallback_to_best_path
    ${sla_remote_colors_list}=    Run Keyword If    "{{ sequence.actions.get('sla_class', {}).get('preferred_remote_colors', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('sla_class', {}).get('preferred_remote_colors', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?preferredRemoteColor] | [0].preferredRemoteColor
    ...    ${sla_remote_colors_list}    not_defined
    ...    msg=actions.sla_class.preferred_remote_colors
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?slaClass] | [0].slaClass[?remoteColorRestrict] | [0].remoteColorRestrict
    ...    {{ sequence.actions.get('sla_class', {}).get('remote_color_restrict') if sequence.actions.get('sla_class', {}).get('remote_color_restrict') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.sla_class.remote_color_restrict
    # Validate tloc fields
    ${tloc_colors_list}=    Run Keyword If    "{{ sequence.actions.get('tloc', {}).get('color', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('tloc', {}).get('color', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?tloc] | [0].tloc.color
    ...    ${tloc_colors_list}    not_defined
    ...    msg=actions.tloc.color
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?tloc] | [0].tloc.encap
    ...    {{ sequence.actions.get('tloc', {}).get('encapsulation') if sequence.actions.get('tloc', {}).get('encapsulation') else 'not_defined' }}    not_defined
    ...    msg=actions.tloc.encapsulation
    # Validate tloc_list reference (direct under set, not under tloc)
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?tlocList] | [0].tlocList.refId.value
    ...    ${tloc_lists.json()}    {{ sequence.actions.get('tloc', {}).get('list') if sequence.actions.get('tloc', {}).get('list') else 'not_defined' }}
    ...    actions.tloc_list

    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?tloc] | [0].tloc.ip
    ...    {{ sequence.actions.get('tloc', {}).get('ip') if sequence.actions.get('tloc', {}).get('ip') else 'not_defined' }}    not_defined
    ...    msg=actions.tloc.ip
    # Validate service fields
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.type
    ...    {{ sequence.actions.get('service', {}).get('type') if sequence.actions.get('service', {}).get('type') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service.type
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.vpn
    ...    {{ sequence.actions.get('service', {}).get('vpn') if sequence.actions.get('service', {}).get('vpn') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service.vpn
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.local
    ...    {{ sequence.actions.get('service', {}).get('local') if sequence.actions.get('service', {}).get('local') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service.local
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.restrict
    ...    {{ sequence.actions.get('service', {}).get('restrict') if sequence.actions.get('service', {}).get('restrict') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service.restrict
    ${service_tloc_colors_list}=    Run Keyword If    "{{ sequence.actions.get('service', {}).get('tloc_color', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('service', {}).get('tloc_color', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.tloc.color
    ...    ${service_tloc_colors_list}    not_defined
    ...    msg=actions.service.tloc_color
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.tloc.encap
    ...    {{ sequence.actions.get('service', {}).get('tloc_encapsulation') if sequence.actions.get('service', {}).get('tloc_encapsulation') else 'not_defined' }}    not_defined
    ...    msg=actions.service.tloc_encapsulation
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.tloc.ip
    ...    {{ sequence.actions.get('service', {}).get('tloc_ip') if sequence.actions.get('service', {}).get('tloc_ip') else 'not_defined' }}    not_defined
    ...    msg=actions.service.tloc_ip
    # Validate service tloc_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?service] | [0].service.tlocList.refId.value
    ...    ${tloc_lists.json()}    {{ sequence.actions.get('service', {}).get('tloc_list') if sequence.actions.get('service', {}).get('tloc_list') else 'not_defined' }}
    ...    actions.service.tloc_list

    # Validate service_chain fields 
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.type
    ...    {{ sequence.actions.get('service_chain', {}).get('type') if sequence.actions.get('service_chain', {}).get('type') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service_chain.type
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.vpn
    ...    {{ sequence.actions.get('service_chain', {}).get('vpn') if sequence.actions.get('service_chain', {}).get('vpn') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service_chain.vpn
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.local
    ...    {{ sequence.actions.get('service_chain', {}).get('local') if sequence.actions.get('service_chain', {}).get('local') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.service_chain.local
    # NOTE: fallback_to_routing has BOOLEAN INVERSION in TF module
    # Data model true → API false, Data model false → API true
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.restrict
    ...    {{ 'False' if sequence.actions.get('service_chain', {}).get('fallback_to_routing') == true else ('True' if sequence.actions.get('service_chain', {}).get('fallback_to_routing') == false else 'not_defined') }}    not_defined
    ...    msg=actions.service_chain.fallback_to_routing
    ${sc_tloc_colors_list}=    Run Keyword If    "{{ sequence.actions.get('service_chain', {}).get('tloc_color', []) | length }}" == "0"    Set Variable    not_defined
    ...    ELSE    Evaluate    {{ sequence.actions.get('service_chain', {}).get('tloc_color', []) }}
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.tloc.color
    ...    ${sc_tloc_colors_list}    not_defined
    ...    msg=actions.service_chain.tloc_color
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.tloc.encap
    ...    {{ sequence.actions.get('service_chain', {}).get('tloc_encapsulation') if sequence.actions.get('service_chain', {}).get('tloc_encapsulation') else 'not_defined' }}    not_defined
    ...    msg=actions.service_chain.tloc_encapsulation
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.tloc.ip
    ...    {{ sequence.actions.get('service_chain', {}).get('tloc_ip') if sequence.actions.get('service_chain', {}).get('tloc_ip') else 'not_defined' }}    not_defined
    ...    msg=actions.service_chain.tloc_ip
    # Validate service_chain tloc_list reference
    Should Be Equal Referenced Object Name
    ...    ${sequence}    actions[?set] | [0].set[?serviceChain] | [0].serviceChain.tlocList.refId.value
    ...    ${tloc_lists.json()}    {{ sequence.actions.get('service_chain', {}).get('tloc_list') if sequence.actions.get('service_chain', {}).get('tloc_list') else 'not_defined' }}
    ...    actions.service_chain.tloc_list

    # Validate appqoe_optimization fields
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?appqoeOptimization] | [0].appqoeOptimization.tcpOptimization
    ...    {{ sequence.actions.get('appqoe_optimization', {}).get('tcp_optimization') if sequence.actions.get('appqoe_optimization', {}).get('tcp_optimization') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.appqoe_optimization.tcp_optimization
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?appqoeOptimization] | [0].appqoeOptimization.dreOptimization
    ...    {{ sequence.actions.get('appqoe_optimization', {}).get('dre_optimization') if sequence.actions.get('appqoe_optimization', {}).get('dre_optimization') is not none else 'not_defined' }}    not_defined
    ...    msg=actions.appqoe_optimization.dre_optimization
    Should Be Equal Value Json Yaml
    ...    ${sequence}    actions[?appqoeOptimization] | [0].appqoeOptimization.serviceNodeGroup
    ...    {{ sequence.actions.get('appqoe_optimization', {}).get('service_node_group') if sequence.actions.get('appqoe_optimization', {}).get('service_node_group') else 'not_defined' }}    not_defined
    ...    msg=actions.appqoe_optimization.service_node_group
{% endif %}

{% endfor %}
{% endif %}

{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
