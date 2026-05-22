*** Settings ***
Documentation   Verify BGP Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.bgp_templates is defined %}

*** Test Cases ***
Get BGP Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_bgp']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.bgp_templates | default([]) %}

Verify Edge Feature Template BGP Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.bgp_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}
 
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."best-path".med."always-compare"
    ...    {{ ft_yaml.always_compare_med | default("not_defined") }}
    ...    {{ ft_yaml.always_compare_med_variable | default("not_defined") }}
    ...    msg=always_compare_med

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."as-num"
    ...    {{ ft_yaml.as_number | default("not_defined") }}
    ...    {{ ft_yaml.as_number_variable | default("not_defined") }}
    ...    msg=as_number

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."best-path"."compare-router-id"
    ...    {{ ft_yaml.compare_router_id | default("not_defined") }}
    ...    {{ ft_yaml.compare_router_id_variable | default("not_defined") }}
    ...    msg=compare_router_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."best-path".med.deterministic
    ...    {{ ft_yaml.deterministic_med | default("not_defined") }}
    ...    {{ ft_yaml.deterministic_med_variable | default("not_defined") }}
    ...    msg=deterministic_med

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.distance.external
    ...    {{ ft_yaml.distance_external | default("not_defined") }}
    ...    {{ ft_yaml.distance_external_variable | default("not_defined") }}
    ...    msg=distance_external

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.distance.local
    ...    {{ ft_yaml.distance_local | default("not_defined") }}
    ...    {{ ft_yaml.distance_local_variable | default("not_defined") }}
    ...    msg=distance_local

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.distance.internal
    ...    {{ ft_yaml.distance_internal | default("not_defined") }}
    ...    {{ ft_yaml.distance_internal_variable | default("not_defined") }}
    ...    msg=distance_internal

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.timers.holdtime
    ...    {{ ft_yaml.holdtime | default("not_defined") }}
    ...    {{ ft_yaml.holdtime_variable | default("not_defined") }}
    ...    msg=holdtime

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.timers.keepalive
    ...    {{ ft_yaml.keepalive | default("not_defined") }}
    ...    {{ ft_yaml.keepalive_variable | default("not_defined") }}
    ...    msg=keepalive
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."best-path".med."missing-as-worst"
    ...    {{ ft_yaml.missing_med_as_worst | default("not_defined") }}
    ...    {{ ft_yaml.missing_med_as_worst_variable | default("not_defined") }}
    ...    msg=missing_med_as_worst

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."best-path"."as-path"."multipath-relax"
    ...    {{ ft_yaml.multipath_relax | default("not_defined") }}
    ...    {{ ft_yaml.multipath_relax_variable | default("not_defined") }}
    ...    msg=multipath_relax

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."propagate-aspath"
    ...    {{ ft_yaml.propagate_as_path | default("not_defined") }}
    ...    {{ ft_yaml.propagate_as_path_variable | default("not_defined") }}
    ...    msg=propagate_as_path

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."propagate-community"
    ...    {{ ft_yaml.propagate_community | default("not_defined") }}
    ...    {{ ft_yaml.propagate_community_variable | default("not_defined") }}
    ...    msg=propagate_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."router-id"
    ...    {{ ft_yaml.router_id | default("not_defined") }}
    ...    {{ ft_yaml.router_id_variable | default("not_defined") }}
    ...    msg=router_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    # Custom handling verifying existing address-families
    {% set af_yaml = [] %}
    {% if ft_yaml.ipv4_address_family is defined %}
        {% set _ = af_yaml.append("ipv4-unicast") %}
    {% endif %}
    {% if ft_yaml.ipv6_address_family is defined %}
        {% set _ = af_yaml.append("ipv6-unicast") %}
    {% endif %}
    ${af_yaml}=    Create List    {{ af_yaml | join('    ') if af_yaml else 'not_defined' }}

    ${af_json}=   Json Search List    ${ft.json()}    bgp."address-family".vipValue[]."family-type".vipValue
    Lists Should Be Equal   ${af_yaml}   ${af_json}   ignore_order=True    values=False    msg=address_families expected: '${af_yaml}' and got: '${af_json}'    

{% if ft_yaml.ipv4_address_family is defined %}
    Log    === IPv4 Address Family ===
    
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."default-information".originate
    ...    {{ ft_yaml.ipv4_address_family.default_information_originate | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.default_information_originate_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.default_information_originate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."maximum-paths".paths
    ...    {{ ft_yaml.ipv4_address_family.maximum_paths | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.maximum_paths_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.maximum_paths

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."aggregate-address".vipValue    {{ ft_yaml.ipv4_address_family.aggregate_addresses | default([]) | length }}    msg=ipv4_address_family.aggregate_addresses length

{% for aggregate in ft_yaml.ipv4_address_family.aggregate_addresses | default([]) %}

    Log    === Aggregate Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."aggregate-address".vipValue[{{loop.index0}}].prefix
    ...    {{ aggregate.prefix | default("not_defined") }}
    ...    {{ aggregate.prefix_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.aggregate_addresses.prefix

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."aggregate-address".vipValue[{{loop.index0}}]."as-set"
    ...    {{ aggregate.as_set_path | default("not_defined") }}
    ...    {{ aggregate.as_set_path_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.aggregate_addresses.as_set_path

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."aggregate-address".vipValue[{{loop.index0}}]."summary-only"
    ...    {{ aggregate.summary_only | default("not_defined") }}
    ...    {{ aggregate.summary_only_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.aggregate_addresses.summary_only

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."aggregate-address".vipValue[{{loop.index0}}].vipOptional
    ...    {{ aggregate.optional | default("not_defined") }}
    ...    msg=ipv4_address_family.aggregate_addresses.optional

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."table-map".name
    ...    {{ ft_yaml.ipv4_address_family.table_map_policy | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.table_map_policy_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.table_map_policy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0]."table-map".filter
    ...    {{ ft_yaml.ipv4_address_family.table_map_filter | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.table_map_filter_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.table_map_filter

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].redistribute.vipValue    {{ ft_yaml.ipv4_address_family.redistributes | default([]) | length }}    msg=ipv4_address_family.redistributes length

{% for redistribute in ft_yaml.ipv4_address_family.redistributes | default([]) %}

    Log    === Redistribute {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].redistribute.vipValue[{{loop.index0}}].protocol
    ...    {{ redistribute.protocol | default("not_defined") }}
    ...    {{ redistribute.protocol_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].redistribute.vipValue[{{loop.index0}}]."route-policy"
    ...    {{ redistribute.route_policy | default("not_defined") }}
    ...    {{ redistribute.route_policy_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.redistributes.route_policy

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].redistribute.vipValue[{{loop.index0}}].vipOptional
    ...    {{ redistribute.optional | default("not_defined") }}
    ...    msg=ipv4_address_family.redistributes.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.neighbor.vipValue    {{ ft_yaml.ipv4_address_family.neighbors | default([]) | length }}    msg=ipv4_address_family.neighbors length

{% for neighbor_index in range(ft_yaml.ipv4_address_family.neighbors | default([]) | length()) %}

    Log    === IPv4 Neighbor {{neighbor_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].address
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families | default([]) | length }}    msg=ipv4_address_family.neighbors.address_families length

{% for af_index in range(ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families | default([]) | length()) %}

    Log    === IPv4 Neighbor {{neighbor_index}} Address Family {{af_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."family-type"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].family_type | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].family_type_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.family_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes"."prefix-num"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.maximum_prefixes

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes".restart
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_restart | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_restart_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.maximum_prefixes_restart

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes".threshold
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_threshold | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_threshold_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.maximum_prefixes_threshold

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes"."warning-only"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_warning_only | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_warning_only_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.maximum_prefixes_warning_only

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."route-policy".vipValue[?direction.vipValue=='in'] | [0]."pol-name"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_in | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_in_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.route_policy_in

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."route-policy".vipValue[?direction.vipValue=='out'] | [0]."pol-name"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_out | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_out_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.route_policy_out

    Should Be Equal Value Json String    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}].vipOptional
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].address_families[af_index].optional | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.address_families.optional

    {% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."allowas-in"."as-number"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].allow_as_in | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].allow_as_in_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.allow_as_in

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."as-override"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].as_override | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].as_override_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.as_override

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].description
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].description | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].description_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."ebgp-multihop"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].ebgp_multihop | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].ebgp_multihop_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.ebgp_multihop

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."next-hop-self"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].next_hop_self | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].next_hop_self_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.next_hop_self

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].password
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].password | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].password_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."remote-as"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].remote_as | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].remote_as_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.remote_as

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."send-community"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_community | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_community_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.send_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."send-ext-community"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_extended_community | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_extended_community_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.send_extended_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."send-label"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_label | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_label_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.send_label

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."send-label-explicit"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_label_explicit_null | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].send_label_explicit_null_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.send_label_explicit_null

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].shutdown
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].shutdown | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].shutdown_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}]."update-source"."if-name"
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].source_interface | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].source_interface_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].timers.keepalive
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].keepalive | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].keepalive_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.keepalive

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].timers.holdtime
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].holdtime | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].holdtime_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.holdtime

    Should Be Equal Value Json String    ${ft.json()}    bgp.neighbor.vipValue[{{neighbor_index}}].vipOptional
    ...    {{ ft_yaml.ipv4_address_family.neighbors[neighbor_index].optional | default("not_defined") }}
    ...    msg=ipv4_address_family.neighbors.optional
{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].network.vipValue    {{ ft_yaml.ipv4_address_family.networks | default([]) | length }}    msg=ipv4_address_family.networks length

{% for network in ft_yaml.ipv4_address_family.networks | default([]) %}
    Log    === IPv4 Network {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].network.vipValue[{{loop.index0}}].prefix
    ...    {{ network.prefix | default("not_defined") }}
    ...    {{ network.prefix_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.networks.prefix

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv4-unicast'] | [0].network.vipValue[{{loop.index0}}].vipOptional
    ...    {{ network.optional | default("not_defined") }}
    ...    msg=ipv4_address_family.networks.optional
{% endfor %}

    # IPv4 Address Family Route Targets validation
    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv4".vipValue    {{ ft_yaml.ipv4_address_family.route_targets | default([]) | length }}    msg=ipv4_address_family.route_targets length

{% for target_index in range(ft_yaml.ipv4_address_family.route_targets | default([]) | length()) %}
    Log    === IPv4 Route Target {{target_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}]."vpn-id"
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].vpn_id_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.route_targets.vpn_id

    Should Be Equal Value Json String    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}].vipOptional
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].optional | default("not_defined") }}
    ...    msg=ipv4_address_family.route_targets.optional

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}].import.vipValue    {{ ft_yaml.ipv4_address_family.route_targets[target_index].imports | default([]) | length }}    msg=ipv4_address_family.route_targets.imports length

{% for import_index in range(ft_yaml.ipv4_address_family.route_targets[target_index].imports | default([]) | length()) %}
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}].import.vipValue[{{import_index}}]."asn-ip"
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].imports[import_index].asn_ip | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].imports[import_index].asn_ip_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.route_targets.imports.asn_ip
{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}].export.vipValue    {{ ft_yaml.ipv4_address_family.route_targets[target_index].exports | default([]) | length }}    msg=ipv4_address_family.route_targets.exports length

{% for export_index in range(ft_yaml.ipv4_address_family.route_targets[target_index].exports | default([]) | length()) %}
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv4".vipValue[{{target_index}}].export.vipValue[{{export_index}}]."asn-ip"
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].exports[export_index].asn_ip | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_family.route_targets[target_index].exports[export_index].asn_ip_variable | default("not_defined") }}
    ...    msg=ipv4_address_family.route_targets.exports.asn_ip
{% endfor %}

{% endfor %}

{% endif %}

    {% if ft_yaml.ipv6_address_family is defined %}
    Log    === IPv6 Address Family ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."default-information".originate
    ...    {{ ft_yaml.ipv6_address_family.default_information_originate | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.default_information_originate_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.default_information_originate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."maximum-paths".paths
    ...    {{ ft_yaml.ipv6_address_family.maximum_paths | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.maximum_paths_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.maximum_paths

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-aggregate-address".vipValue    {{ ft_yaml.ipv6_address_family.aggregate_addresses | default([]) | length }}    msg=ipv6_address_family.aggregate_addresses length

{% for aggregate in ft_yaml.ipv6_address_family.aggregate_addresses | default([]) %}

    Log    === IPv6 Aggregate Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-aggregate-address".vipValue[{{loop.index0}}].prefix
    ...    {{ aggregate.prefix | default("not_defined") }}
    ...    {{ aggregate.prefix_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.aggregate_addresses.prefix

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-aggregate-address".vipValue[{{loop.index0}}]."as-set"
    ...    {{ aggregate.as_set_path | default("not_defined") }}
    ...    {{ aggregate.as_set_path_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.aggregate_addresses.as_set_path

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-aggregate-address".vipValue[{{loop.index0}}]."summary-only"
    ...    {{ aggregate.summary_only | default("not_defined") }}
    ...    {{ aggregate.summary_only_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.aggregate_addresses.summary_only

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-aggregate-address".vipValue[{{loop.index0}}].vipOptional
    ...    {{ aggregate.optional | default("not_defined") }}
    ...    msg=ipv6_address_family.aggregate_addresses.optional

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."table-map".name
    ...    {{ ft_yaml.ipv6_address_family.table_map_policy | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.table_map_policy_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.table_map_policy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."table-map".filter
    ...    {{ ft_yaml.ipv6_address_family.table_map_filter | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.table_map_filter_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.table_map_filter

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0].redistribute.vipValue    {{ ft_yaml.ipv6_address_family.redistributes | default([]) | length }}    msg=ipv6_address_family.redistributes length

{% for redistribute in ft_yaml.ipv6_address_family.redistributes | default([]) %}

    Log    === IPv6 Redistribute {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0].redistribute.vipValue[{{loop.index0}}].protocol
    ...    {{ redistribute.protocol | default("not_defined") }}
    ...    {{ redistribute.protocol_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0].redistribute.vipValue[{{loop.index0}}]."route-policy"
    ...    {{ redistribute.route_policy | default("not_defined") }}
    ...    {{ redistribute.route_policy_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.redistributes.route_policy

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0].redistribute.vipValue[{{loop.index0}}].vipOptional
    ...    {{ redistribute.optional | default("not_defined") }}
    ...    msg=ipv6_address_family.redistributes.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."ipv6-neighbor".vipValue    {{ ft_yaml.ipv6_address_family.neighbors | default([]) | length }}    msg=ipv6_address_family.neighbors length

{% for neighbor_index in range(ft_yaml.ipv6_address_family.neighbors | default([]) | length()) %}

    Log    === IPv6 Neighbor {{neighbor_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].address
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families | default([]) | length }}    msg=ipv6_address_family.neighbors.address_families length

{% for af_index in range(ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families | default([]) | length()) %}

    Log    === IPv6 Neighbor {{neighbor_index}} Address Family {{af_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."family-type"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].family_type | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].family_type_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.family_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes"."prefix-num"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.maximum_prefixes

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes".restart
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_restart | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_restart_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.maximum_prefixes_restart

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes".threshold
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_threshold | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_threshold_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.maximum_prefixes_threshold

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."maximum-prefixes"."warning-only"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_warning_only | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].maximum_prefixes_warning_only_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.maximum_prefixes_warning_only

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."route-policy".vipValue[?direction.vipValue=='in'] | [0]."pol-name"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_in | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_in_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.route_policy_in

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}]."route-policy".vipValue[?direction.vipValue=='out'] | [0]."pol-name"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_out | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].route_policy_out_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.route_policy_out

    Should Be Equal Value Json String    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."address-family".vipValue[{{af_index}}].vipOptional
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].address_families[af_index].optional | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.address_families.optional

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."allowas-in"."as-number"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].allow_as_in | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].allow_as_in_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.allow_as_in

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."as-override"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].as_override | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].as_override_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.as_override

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].description
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].description | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].description_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."ebgp-multihop"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].ebgp_multihop | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].ebgp_multihop_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.ebgp_multihop

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."next-hop-self"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].next_hop_self | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].next_hop_self_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.next_hop_self

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].password
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].password | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].password_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."remote-as"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].remote_as | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].remote_as_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.remote_as

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."send-community"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_community | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_community_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.send_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."send-ext-community"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_extended_community | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_extended_community_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.send_extended_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."send-label"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_label | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_label_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.send_label

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."send-label-explicit"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_label_explicit_null | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].send_label_explicit_null_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.send_label_explicit_null

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].shutdown
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].shutdown | default("not_defined") | lower() }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].shutdown_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}]."update-source"."if-name"
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].source_interface | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].source_interface_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].timers.keepalive
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].keepalive | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].keepalive_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.keepalive

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].timers.holdtime
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].holdtime | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].holdtime_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.holdtime

    Should Be Equal Value Json String    ${ft.json()}    bgp."ipv6-neighbor".vipValue[{{neighbor_index}}].vipOptional
    ...    {{ ft_yaml.ipv6_address_family.neighbors[neighbor_index].optional | default("not_defined") }}
    ...    msg=ipv6_address_family.neighbors.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-network".vipValue    {{ ft_yaml.ipv6_address_family.networks | default([]) | length }}    msg=ipv6_address_family.networks length

{% for network in ft_yaml.ipv6_address_family.networks | default([]) %}

    Log    === IPv6 Network {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-network".vipValue[{{loop.index0}}].prefix
    ...    {{ network.prefix | default("not_defined") }}
    ...    {{ network.prefix_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.networks.prefix

    Should Be Equal Value Json String    ${ft.json()}    bgp."address-family".vipValue[?"family-type".vipValue=='ipv6-unicast'] | [0]."ipv6-network".vipValue[{{loop.index0}}].vipOptional
    ...    {{ network.optional | default("not_defined") }}
    ...    msg=ipv6_address_family.networks.optional

{% endfor %}

    # IPv6 Address Family Route Targets validation
    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv6".vipValue    {{ ft_yaml.ipv6_address_family.route_targets | default([]) | length }}    msg=ipv6_address_family.route_targets length

{% for target_index in range(ft_yaml.ipv6_address_family.route_targets | default([]) | length()) %}

    Log    === IPv6 Route Target {{target_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}]."vpn-id"
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].vpn_id_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.route_targets.vpn_id

    Should Be Equal Value Json String    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}].vipOptional
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].optional | default("not_defined") }}
    ...    msg=ipv6_address_family.route_targets.optional

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}].import.vipValue    {{ ft_yaml.ipv6_address_family.route_targets[target_index].imports | default([]) | length }}    msg=ipv6_address_family.route_targets.imports length

{% for import_index in range(ft_yaml.ipv6_address_family.route_targets[target_index].imports | default([]) | length()) %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}].import.vipValue[{{import_index}}]."asn-ip"
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].imports[import_index].asn_ip | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].imports[import_index].asn_ip_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.route_targets.imports.asn_ip

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}].export.vipValue    {{ ft_yaml.ipv6_address_family.route_targets[target_index].exports | default([]) | length }}    msg=ipv6_address_family.route_targets.exports length

{% for export_index in range(ft_yaml.ipv6_address_family.route_targets[target_index].exports | default([]) | length()) %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp.target."route-target-ipv6".vipValue[{{target_index}}].export.vipValue[{{export_index}}]."asn-ip"
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].exports[export_index].asn_ip | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_family.route_targets[target_index].exports[export_index].asn_ip_variable | default("not_defined") }}
    ...    msg=ipv6_address_family.route_targets.exports.asn_ip

{% endfor %}

{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length    ${ft.json()}    bgp."mpls-interface".vipValue    {{ ft_yaml.mpls_interfaces | default([]) | length }}    msg=mpls_interfaces length

{% for mpls_int in ft_yaml.mpls_interfaces | default([]) %}

    Log    === MPLS Interface {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    bgp."mpls-interface".vipValue[{{loop.index0}}]."if-name"
    ...    {{ mpls_int.interface_name | default("not_defined") }}
    ...    {{ mpls_int.interface_name_variable | default("not_defined") }}
    ...    msg=mpls_interfaces.interface_name

{% endfor %}

{% endfor %}

{% endif %}