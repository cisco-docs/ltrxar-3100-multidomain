*** Settings ***
Documentation   Verify Transport Feature Profile Configuration BGP Features
Name            Transport Profiles BGP Features
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    transport_profiles    bgp
Resource        ../../../sdwan_common.resource


{% set profile_bgp_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('transport_profiles', {}) %}
 {% if profile.bgp_features is defined %}
  {% set _ = profile_bgp_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_bgp_list != [] %}

*** Test Cases ***
Get Transport Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.transport_profiles | default([]) %}
{% if profile.bgp_features is defined %}

Verify Feature Profiles Transport Profiles {{ profile.name }} BGP Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${transport_bgp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/routing/bgp
    Set Suite Variable    ${transport_bgp_res}
    ${transport_bgp}=    Json Search List    ${transport_bgp_res.json()}    data[].payload
    Run Keyword If    ${transport_bgp} == []    Fail    BGP feature(s) expected to be configured within the transport profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${transport_bgp}

    # Extract route policies since they might be used in BGP
    ${route_policies_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/transport/${profile_id}/route-policy
    Set Suite Variable    ${route_policies_res}

{% for bgp in profile.bgp_features | default([]) %}
    Log    === BGP: {{ bgp.name }} ===
    
    # for each bgp find the corresponding one in the json and check parameters:
    ${bgp_feature}=    Json Search    ${transport_bgp}    [?name=='{{ bgp.name }}'] | [0]
    Run Keyword If    $bgp_feature is None    Fail    BGP feature '{{ bgp.name }}' expected in transport profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${bgp_feature}    name    {{ bgp.name }}    msg=name
    Should Be Equal Value Json Special_String    ${bgp_feature}    description    {{ bgp.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.alwaysCompare    {{ bgp.always_compare_med | default('not_defined') }}    {{ bgp.always_compare_med_variable | default('not_defined') }}    msg=bgp.always_compare_med
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.asNum    {{ bgp.as_number | default('not_defined') }}    {{ bgp.as_number_variable | default('not_defined') }}    msg=bgp.as_number
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.routerId    {{ bgp.router_id | default('not_defined') }}    {{ bgp.router_id_variable | default('not_defined') }}    msg=bgp.router_id
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.deterministic    {{ bgp.deterministic_med | default('not_defined') }}    {{ bgp.deterministic_med_variable | default('not_defined') }}    msg=bgp.deterministic_med
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.external    {{ bgp.external_routes_distance | default('not_defined') }}    {{ bgp.external_routes_distance_variable | default('not_defined') }}    msg=bgp.external_routes_distance
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.holdtime    {{ bgp.hold_time | default('not_defined') }}    {{ bgp.hold_time_variable | default('not_defined') }}    msg=bgp.hold_time
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.internal    {{ bgp.internal_routes_distance | default('not_defined') }}    {{ bgp.internal_routes_distance_variable | default('not_defined') }}    msg=bgp.internal_routes_distance

    Log    =====IPv4 Aggregate Addresses=====
{% if bgp.ipv4_aggregate_addresses is defined and bgp.get('ipv4_aggregate_addresses', [])|length > 0 %}
{% for aggregate in bgp.ipv4_aggregate_addresses | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.aggregateAddress[{{ loop.index0 }}].asSet    {{ aggregate.as_set_path | default('not_defined') }}     {{ aggregate.as_set_path_variable | default('not_defined') }}     msg=bgp.ipv4_aggregate_addresses.as_path_set 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.aggregateAddress[{{ loop.index0 }}].prefix.address    {{ aggregate.network_address | default('not_defined') }}     {{ aggregate.network_address_variable | default('not_defined') }}     msg=bgp.ipv4_aggregate_addresses.network_address 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.aggregateAddress[{{ loop.index0 }}].prefix.mask    {{ aggregate.subnet_mask | default('not_defined') }}     {{ aggregate.subnet_mask_variable | default('not_defined') }}     msg=bgp.ipv4_aggregate_addresses.subnet_mask 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.aggregateAddress[{{ loop.index0 }}].summaryOnly    {{ aggregate.summary_only | default('not_defined') }}     {{ aggregate.summary_only_variable | default('not_defined') }}     msg=bgp.ipv4_aggregate_addresses.summary_only 
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.originate    {{ bgp.ipv4_default_originate | default('not_defined') }}    {{ bgp.ipv4_default_originate_variable | default('not_defined') }}    msg=bgp.ipv4_default_originate
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.paths    {{ bgp.ipv4_eibgp_maximum_paths | default('not_defined') }}    {{ bgp.ipv4_eibgp_maximum_paths_variable | default('not_defined') }}    msg=bgp.ipv4_eibgp_maximum_paths

    Log    =====IPv4 Neighbors=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.neighbor    {{ bgp.get('ipv4_neighbors', []) | length }}    msg=bgp.ipv4_neighbors length
{% if bgp.ipv4_neighbors is defined and bgp.get('ipv4_neighbors', [])|length > 0 %}
{% for neighbor in bgp.ipv4_neighbors | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].address    {{ neighbor.address | default('not_defined') }}     {{ neighbor.address_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.address 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].asNumber    {{ neighbor.allowas_in_number | default('not_defined') }}     {{ neighbor.allowas_in_number_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.allowas_in_number 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].asOverride    {{ neighbor.as_override | default('not_defined') }}     {{ neighbor.as_override_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.as_override 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].description    {{ neighbor.description | default('not_defined') }}     {{ neighbor.description_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.description 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].ebgpMultihop    {{ neighbor.ebgp_multihop | default('not_defined') }}     {{ neighbor.ebgp_multihop_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.ebgp_multihop 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].holdtime    {{ neighbor.hold_time | default('not_defined') }}     {{ neighbor.hold_time_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.hold_time 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].keepalive    {{ neighbor.keepalive_time | default('not_defined') }}     {{ neighbor.keepalive_time_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.keepalive_time 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].localAs    {{ neighbor.local_as | default('not_defined') }}     {{ neighbor.local_as_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.local_as 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].nextHopSelf    {{ neighbor.next_hop_self | default('not_defined') }}     {{ neighbor.next_hop_self_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.next_hop_self 
    # Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].password    {{ neighbor.password | default('not_defined') }}     {{ neighbor.password_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.password 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].remoteAs    {{ neighbor.remote_as | default('not_defined') }}     {{ neighbor.remote_as_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.remote_as 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].sendCommunity    {{ neighbor.send_community | default('not_defined') }}     {{ neighbor.send_community_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.send_community 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].sendExtCommunity    {{ neighbor.send_extended_community | default('not_defined') }}     {{ neighbor.send_extended_community_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.send_extended_community 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].sendLabel    {{ neighbor.send_label | default('not_defined') }}     {{ neighbor.send_label_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.send_label 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].sendLabelExplicit    {{ neighbor.send_label_explicit_null | default('not_defined') }}     {{ neighbor.send_label_explicit_null_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.send_label_explicit_null 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].shutdown    {{ neighbor.shutdown | default('not_defined') }}     {{ neighbor.shutdown_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.shutdown 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].ifName    {{ neighbor.source_interface | default('not_defined') }}     {{ neighbor.source_interface_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.source_interface 

    Should Be Equal Value Json List Length    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].addressFamily    {{ neighbor.get('address_families', []) | length }}    msg=bgp.ipv4_neighbors.address_families length
{% if neighbor.address_families is defined and neighbor.get('address_families', [])|length > 0 %}
{% for af in neighbor.address_families | default([]) %}
    ${af}=    Json Search    ${bgp_feature}    data.neighbor[{{ loop.index0 }}].addressFamily[?familyType.value=='{{ af.family_type }}'] | [0]
    Run Keyword If    $af is None    Fail    Address Family {{ af.family_type }} expected to be configured in BGP neighbor

    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.policyType    {{ af.maximum_prefixes_reach_policy | default(defaults.sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_reach_policy) }}     not_defined     msg=bgp.ipv4_neighbors.address_families.maximum_prefixes_reach_policy
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.prefixNum    {{ af.maximum_prefixes_number | default('not_defined') }}     {{ af.maximum_prefixes_number_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.address_families.maximum_prefixes_number
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.restartInterval    {{ af.maximum_prefixes_restart_interval | default('not_defined') }}     {{ af.maximum_prefixes_restart_interval_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.address_families.maximum_prefixes_restart_interval
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.threshold    {{ af.maximum_prefixes_threshold | default('not_defined') }}     {{ af.maximum_prefixes_threshold_variable | default('not_defined') }}     msg=bgp.ipv4_neighbors.address_families.maximum_prefixes_threshold

    Should Be Equal Referenced Object Name    ${af}    inRoutePolicy.refId.value    ${route_policies_res.json()}    {{ af.route_policy_in | default('not_defined') }}    bgp.ipv4_neighbors.address_families.route_policy_in

    Should Be Equal Referenced Object Name    ${af}    outRoutePolicy.refId.value    ${route_policies_res.json()}    {{ af.route_policy_out | default('not_defined') }}    bgp.ipv4_neighbors.address_families.route_policy_out
{% endfor %}
{% endif %}

{% endfor %}
{% endif %}

    Log    =====IPv4 Networks=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.addressFamily.network    {{ bgp.get('ipv4_networks', []) | length }}    msg=bgp.ipv4_networks length
{% if bgp.ipv4_networks is defined and bgp.get('ipv4_networks', [])|length > 0 %}
{% for network in bgp.ipv4_networks | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.network[{{ loop.index0 }}].prefix.address    {{ network.network_address | default('not_defined') }}     {{ network.network_address_variable | default('not_defined') }}     msg=bgp.ipv4_networks.network_address 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.network[{{ loop.index0 }}].prefix.mask    {{ network.subnet_mask | default('not_defined') }}     {{ network.subnet_mask_variable | default('not_defined') }}     msg=bgp.ipv4_networks.subnet_mask 
{% endfor %}
{% endif %}

    Log    =====IPv4 Redistributes=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.addressFamily.redistribute    {{ bgp.get('ipv4_redistributes', []) | length }}    msg=bgp.ipv4_redistributes length
{% if bgp.ipv4_redistributes is defined and bgp.get('ipv4_redistributes', [])|length > 0 %}
{% for redistribute in bgp.ipv4_redistributes | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].metric    {{ redistribute.metric | default('not_defined') }}     {{ redistribute.metric_variable | default('not_defined') }}     msg=bgp.ipv4_redistributes.metric

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].ospfMatchRoute    {{ redistribute.ospf_match_route | default('not_defined') }}     {{ redistribute.ospf_match_route_variable | default('not_defined') }}     msg=bgp.ipv4_redistributes.ospf_match_route

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].protocol    {{ redistribute.protocol | default('not_defined') }}     {{ redistribute.protocol_variable | default('not_defined') }}     msg=bgp.ipv4_redistributes.protocol 

    Should Be Equal Referenced Object Name    ${bgp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].routePolicy.refId.value    ${route_policies_res.json()}    {{ redistribute.route_policy | default('not_defined') }}    bgp.ipv4_redistributes.route_policy
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.addressFamily.filter    {{ bgp.ipv4_table_map_filter | default('not_defined') }}    {{ bgp.ipv4_table_map_filter_variable | default('not_defined') }}    msg=bgp.ipv4_table_map_filter

    Should Be Equal Referenced Object Name    ${bgp_feature}    data.addressFamily.name.refId.value    ${route_policies_res.json()}    {{ bgp.ipv4_table_map_route_policy | default('not_defined') }}    bgp.ipv4_table_map_route_policy

    Log    =====IPv6 Aggregate Addresses=====
{% if bgp.ipv6_aggregate_addresses is defined and bgp.get('ipv6_aggregate_addresses', [])|length > 0 %}
{% for aggregate in bgp.ipv6_aggregate_addresses | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.ipv6AggregateAddress[{{ loop.index0 }}].asSet    {{ aggregate.as_set_path | default('not_defined') }}     {{ aggregate.as_set_path_variable | default('not_defined') }}     msg=bgp.ipv6_aggregate_addresses.as_path_set 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.ipv6AggregateAddress[{{ loop.index0 }}].prefix    {{ aggregate.prefix | default('not_defined') }}     {{ aggregate.prefix_variable | default('not_defined') }}     msg=bgp.ipv6_aggregate_addresses.prefix 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.ipv6AggregateAddress[{{ loop.index0 }}].summaryOnly    {{ aggregate.summary_only | default('not_defined') }}     {{ aggregate.summary_only_variable | default('not_defined') }}     msg=bgp.ipv6_aggregate_addresses.summary_only 
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.originate    {{ bgp.ipv6_default_originate | default('not_defined') }}    {{ bgp.ipv6_default_originate_variable | default('not_defined') }}    msg=bgp.ipv6_default_originate
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.paths    {{ bgp.ipv6_eibgp_maximum_paths | default('not_defined') }}    {{ bgp.ipv6_eibgp_maximum_paths_variable | default('not_defined') }}    msg=bgp.ipv6_eibgp_maximum_paths

    Log    =====IPv6 Neighbors=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.ipv6Neighbor    {{ bgp.get('ipv6_neighbors', []) | length }}    msg=bgp.ipv6_neighbors length
{% if bgp.ipv6_neighbors is defined and bgp.get('ipv6_neighbors', [])|length > 0 %}
{% for neighbor in bgp.ipv6_neighbors | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].address    {{ neighbor.address | default('not_defined') }}     {{ neighbor.address_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.address 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].asNumber    {{ neighbor.allowas_in_number | default('not_defined') }}     {{ neighbor.allowas_in_number_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.allowas_in_number 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].asOverride    {{ neighbor.as_override | default('not_defined') }}     {{ neighbor.as_override_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.as_override 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].description    {{ neighbor.description | default('not_defined') }}     {{ neighbor.description_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.description 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].ebgpMultihop    {{ neighbor.ebgp_multihop | default('not_defined') }}     {{ neighbor.ebgp_multihop_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.ebgp_multihop 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].holdtime    {{ neighbor.hold_time | default('not_defined') }}     {{ neighbor.hold_time_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.hold_time 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].keepalive    {{ neighbor.keepalive_time | default('not_defined') }}     {{ neighbor.keepalive_time_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.keepalive_time 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].localAs    {{ neighbor.local_as | default('not_defined') }}     {{ neighbor.local_as_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.local_as 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].nextHopSelf    {{ neighbor.next_hop_self | default('not_defined') }}     {{ neighbor.next_hop_self_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.next_hop_self 
    # Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].password    {{ neighbor.password | default('not_defined') }}     {{ neighbor.password_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.password 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].remoteAs    {{ neighbor.remote_as | default('not_defined') }}     {{ neighbor.remote_as_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.remote_as 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].sendCommunity    {{ neighbor.send_community | default('not_defined') }}     {{ neighbor.send_community_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.send_community 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].sendExtCommunity    {{ neighbor.send_extended_community | default('not_defined') }}     {{ neighbor.send_extended_community_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.send_extended_community 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].sendLabel    {{ neighbor.send_label | default('not_defined') }}     {{ neighbor.send_label_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.send_label 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].sendLabelExplicit    {{ neighbor.send_label_explicit_null | default('not_defined') }}     {{ neighbor.send_label_explicit_null_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.send_label_explicit_null 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].shutdown    {{ neighbor.shutdown | default('not_defined') }}     {{ neighbor.shutdown_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.shutdown 
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].ifName    {{ neighbor.source_interface | default('not_defined') }}     {{ neighbor.source_interface_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.source_interface 

    Should Be Equal Value Json List Length    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].addressFamily    {{ neighbor.get('address_families', []) | length }}    msg=bgp.ipv6_neighbors.address_families length
{% if neighbor.address_families is defined and neighbor.get('address_families', [])|length > 0 %}
{% for af in neighbor.address_families | default([]) %}
    ${af}=    Json Search    ${bgp_feature}    data.ipv6Neighbor[{{ loop.index0 }}].addressFamily[?familyType.value=='{{ af.family_type }}'] | [0]
    Run Keyword If    $af is None    Fail    Address Family {{ af.family_type }} expected to be configured in BGP neighbor

    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.policyType    {{ af.maximum_prefixes_reach_policy | default(defaults.sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_reach_policy) }}     not_defined     msg=bgp.ipv6_neighbors.address_families.maximum_prefixes_reach_policy
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.prefixNum    {{ af.maximum_prefixes_number | default('not_defined') }}     {{ af.maximum_prefixes_number_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.address_families.maximum_prefixes_number
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.restartInterval    {{ af.maximum_prefixes_restart_interval | default('not_defined') }}     {{ af.maximum_prefixes_restart_interval_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.address_families.maximum_prefixes_restart_interval
    Should Be Equal Value Json Yaml    ${af}    maxPrefixConfig.threshold    {{ af.maximum_prefixes_threshold | default('not_defined') }}     {{ af.maximum_prefixes_threshold_variable | default('not_defined') }}     msg=bgp.ipv6_neighbors.address_families.maximum_prefixes_threshold

    Should Be Equal Referenced Object Name    ${af}    inRoutePolicy.refId.value    ${route_policies_res.json()}    {{ af.route_policy_in | default('not_defined') }}    bgp.ipv6_neighbors.address_families.route_policy_in

    Should Be Equal Referenced Object Name    ${af}    outRoutePolicy.refId.value    ${route_policies_res.json()}    {{ af.route_policy_out | default('not_defined') }}    bgp.ipv6_neighbors.address_families.route_policy_out
{% endfor %}
{% endif %}

{% endfor %}
{% endif %}

    Log    =====IPv6 Networks=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.ipv6AddressFamily.ipv6Network    {{ bgp.get('ipv6_networks', []) | length }}    msg=bgp.ipv6_networks length
{% if bgp.ipv6_networks is defined and bgp.get('ipv6_networks', [])|length > 0 %}
{% for network in bgp.ipv6_networks | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.ipv6Network[{{ loop.index0 }}].prefix    {{ network.prefix | default('not_defined') }}     {{ network.prefix_variable | default('not_defined') }}     msg=bgp.ipv6_networks.prefix 
{% endfor %}
{% endif %}

    Log    =====IPv6 Redistributes=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.ipv6AddressFamily.redistribute    {{ bgp.get('ipv6_redistributes', []) | length }}    msg=bgp.ipv6_redistributes length
{% if bgp.ipv6_redistributes is defined and bgp.get('ipv6_redistributes', [])|length > 0 %}
{% for redistribute in bgp.ipv6_redistributes | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.redistribute[{{ loop.index0 }}].metric    {{ redistribute.metric | default('not_defined') }}     {{ redistribute.metric_variable | default('not_defined') }}     msg=bgp.ipv6_redistributes.metric

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.redistribute[{{ loop.index0 }}].ospfMatchRoute    {{ redistribute.ospf_match_route | default('not_defined') }}     {{ redistribute.ospf_match_route_variable | default('not_defined') }}     msg=bgp.ipv6_redistributes.ospf_match_route
    
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.redistribute[{{ loop.index0 }}].protocol    {{ redistribute.protocol | default('not_defined') }}     {{ redistribute.protocol_variable | default('not_defined') }}     msg=bgp.ipv6_redistributes.protocol

    Should Be Equal Referenced Object Name    ${bgp_feature}    data.ipv6AddressFamily.redistribute[{{ loop.index0 }}].routePolicy.refId.value    ${route_policies_res.json()}    {{ redistribute.route_policy | default('not_defined') }}    bgp.ipv6_redistributes.route_policy
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.ipv6AddressFamily.filter    {{ bgp.ipv6_table_map_filter | default('not_defined') }}    {{ bgp.ipv6_table_map_filter_variable | default('not_defined') }}    msg=bgp.ipv6_table_map_filter

    Should Be Equal Referenced Object Name    ${bgp_feature}    data.ipv6AddressFamily.name.refId.value    ${route_policies_res.json()}    {{ bgp.ipv6_table_map_route_policy | default('not_defined') }}    bgp.ipv6_table_map_route_policy

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.keepalive    {{ bgp.keepalive_time | default('not_defined') }}    {{ bgp.keepalive_time_variable | default('not_defined') }}    msg=bgp.keepalive_time
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.local    {{ bgp.local_routes_distance | default('not_defined') }}    {{ bgp.local_routes_distance_variable | default('not_defined') }}    msg=bgp.local_routes_distance
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.missingAsWorst    {{ bgp.missing_med_as_worst | default('not_defined') }}    {{ bgp.missing_med_as_worst_variable | default('not_defined') }}    msg=bgp.missing_med_as_worst

    Log    =====MPLS Interfaces=====
    Should Be Equal Value Json List Length    ${bgp_feature}    data.mplsInterface    {{ bgp.get('mpls_interfaces', []) | length }}    msg=bgp.mpls_interfaces length
{% if bgp.mpls_interfaces is defined and bgp.get('mpls_interfaces', [])|length > 0 %}
{% for interface in bgp.mpls_interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.mplsInterface[{{ loop.index0 }}].ifName    {{ interface.name | default('not_defined') }}     {{ interface.name_variable | default('not_defined') }}     msg=bgp.mpls_interfaces.name 
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${bgp_feature}    data.multipathRelax    {{ bgp.multipath_relax | default('not_defined') }}    {{ bgp.multipath_relax_variable | default('not_defined') }}    msg=bgp.multipath_relax
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.propagateAspath    {{ bgp.propagate_as_path | default('not_defined') }}    {{ bgp.propagate_as_path_variable | default('not_defined') }}    msg=bgp.propagate_as_path
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.propagateCommunity    {{ bgp.propagate_community | default('not_defined') }}    {{ bgp.propagate_community_variable | default('not_defined') }}    msg=bgp.propagate_community
    Should Be Equal Value Json Yaml    ${bgp_feature}    data.routerId    {{ bgp.router_id | default('not_defined') }}    {{ bgp.router_id_variable | default('not_defined') }}    msg=bgp.router_id

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}