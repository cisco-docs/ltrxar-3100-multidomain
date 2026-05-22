*** Settings ***
Documentation   Verify Ethernet Interface Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates    ethernet_interface_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.ethernet_interface_templates is defined%}

*** Test Cases ***
Get Ethernet Interface Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_vpn_interface']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.ethernet_interface_templates | default([]) %}

Verify Edge Feature Template Ethernet Interface Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.ethernet_interface_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}
    
    # Custom handling to detect if adaptive QoS is enabled
    ${adaptive_qos_remote}=   Json Search List   ${ft.json()}        "qos-adaptive".*.vipType
    ${adaptive_qos_remote}=   Set Variable If    ${adaptive_qos_remote} == []    false    true
    Should Be Equal As Strings    ${adaptive_qos_remote}    {{ ft_yaml.adaptive_qos | default("false") | lower() }}    msg=adaptive_qos
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".period
    ...    {{ ft_yaml.adaptive_qos_period | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_period_variable | default("not_defined") }}
    ...    msg=adaptive_qos_period

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream."bandwidth-up"
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.default | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.default_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream.default

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream.range.umin
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.minimum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.minimum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream.minimum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream.range.umax
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.maximum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.maximum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream.maximum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream."bandwidth-down"
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.default | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.default_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream.default

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream.range.dmin
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.minimum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.minimum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream.minimum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream.range.dmax
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.maximum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.maximum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream.maximum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "arp-timeout"
    ...    {{ ft_yaml.arp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.arp_timeout_variable | default("not_defined") }}
    ...    msg=arp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    autonegotiate
    ...    {{ ft_yaml.autonegotiate | default("not_defined") }}
    ...    {{ ft_yaml.autonegotiate_variable | default("not_defined") }}
    ...    msg=autonegotiate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "auto-bandwidth-detect"
    ...    {{ ft_yaml.bandwidth_auto_detect | default("not_defined") }}
    ...    {{ ft_yaml.bandwidth_auto_detect_variable | default("not_defined") }}
    ...    msg=bandwidth_auto_detect

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "bandwidth-downstream"
    ...    {{ ft_yaml.bandwidth_downstream | default("not_defined") }}
    ...    {{ ft_yaml.bandwidth_downstream_variable | default("not_defined") }}
    ...    msg=bandwidth_downstream

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "bandwidth-upstream"
    ...    {{ ft_yaml.bandwidth_upstream | default("not_defined") }}
    ...    {{ ft_yaml.bandwidth_upstream_variable | default("not_defined") }}
    ...    msg=bandwidth_upstream

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "block-non-source-ip"
    ...    {{ ft_yaml.block_non_source_ip | default("not_defined") }}
    ...    {{ ft_yaml.block_non_source_ip_variable | default("not_defined") }}
    ...    msg=block_non_source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."dhcp-distance"
    ...    {{ ft_yaml.dhcp_distance | default("not_defined") }}
    ...    {{ ft_yaml.dhcp_distance_variable | default("not_defined") }}
    ...    msg=dhcp_distance

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    duplex
    ...    {{ ft_yaml.duplex | default("not_defined") }}
    ...    {{ ft_yaml.duplex_variable | default("not_defined") }}
    ...    msg=duplex

    # Custom handling to detect if SGT is enabled
    ${enable_sgt_remote_vt}=   Json Search List   ${ft.json()}        trustsec.enable.vipType
    ${enable_sgt_remote_vv}=   Json Search List   ${ft.json()}        trustsec.enable.vipValue
    ${enable_sgt_remote}=   Set Variable If    ${enable_sgt_remote_vt} == ['constant'] and ${enable_sgt_remote_vv} == ['true']    true    false
    Should Be Equal As Strings    ${enable_sgt_remote}    {{ ft_yaml.enable_sgt | default("false") | lower() }}    msg=enable_sgt
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.enable
    ...    {{ ft_yaml.enable_sgt | default("not_defined") }}
    ...    {{ ft_yaml.enable_sgt_variable | default("not_defined") }}
    ...    msg=enable_sgt

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tloc-extension-gre-from"."src-ip"
    ...    {{ ft_yaml.gre_tunnel_source_ip | default("not_defined") }}
    ...    {{ ft_yaml.gre_tunnel_source_ip_variable | default("not_defined") }}
    ...    msg=gre_tunnel_source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tloc-extension-gre-from".xconnect
    ...    {{ ft_yaml.gre_tunnel_xconnect | default("not_defined") }}
    ...    {{ ft_yaml.gre_tunnel_xconnect_variable | default("not_defined") }}
    ...    msg=gre_tunnel_xconnect

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "icmp-redirect-disable"
    ...    {{ ft_yaml.icmp_redirect_disable | default("not_defined") }}
    ...    {{ ft_yaml.icmp_redirect_disable_variable | default("not_defined") }}
    ...    msg=icmp_redirect_disable

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    description
    ...    {{ ft_yaml.interface_description | default("not_defined") }}
    ...    {{ ft_yaml.interface_description_variable | default("not_defined") }}
    ...    msg=interface_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "if-name"
    ...    {{ ft_yaml.interface_name | default("not_defined") }}
    ...    {{ ft_yaml.interface_name_variable | default("not_defined") }}
    ...    msg=interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ip-directed-broadcast"
    ...    {{ ft_yaml.ip_directed_broadcast | default("not_defined") }}
    ...    {{ ft_yaml.ip_directed_broadcast_variable | default("not_defined") }}
    ...    msg=ip_directed_broadcast

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "iperf-server"
    ...    {{ ft_yaml.iperf_server | default("not_defined") }}
    ...    {{ ft_yaml.iperf_server_variable | default("not_defined") }}
    ...    msg=iperf_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.address
    ...    {{ ft_yaml.ipv4_address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_variable | default("not_defined") }}
    ...    msg=ipv4_address
    
    # Custom handling to detect if IPv4 address DHCP is enabled
    ${ipv4_address_dhcp_remote}=   Json Search List   ${ft.json()}        ip."dhcp-client".vipValue
    ${ipv4_address_dhcp_remote}=   Set Variable If    ${ipv4_address_dhcp_remote} == ['true']    true    false
    Should Be Equal As Strings    ${ipv4_address_dhcp_remote}    {{ ft_yaml.ipv4_address_dhcp | default("false") | lower() }}    msg=ipv4_address_dhcp
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dhcp-helper"
    ...    {{ ft_yaml.ipv4_dhcp_helpers | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_dhcp_helpers_variable | default("not_defined") }}
    ...    msg=ipv4_dhcp_helpers

    # Custom handling for NAT as there is no single field in JSON describing if NAT is enabled or not
    ${ipv4_nat_remote_choice}=   Json Search List   ${ft.json()}        nat."nat-choice".vipType
    ${ipv4_nat_remote_int}=   Json Search List   ${ft.json()}        nat.interface.*.vipType
    ${ipv4_nat_remote_overload}=   Json Search List   ${ft.json()}        nat.overload.vipType
    ${ipv4_nat_remote}=   Evaluate    len($ipv4_nat_remote_choice) + len($ipv4_nat_remote_int) + len($ipv4_nat_remote_overload)
    ${ipv4_nat_remote}=   Set Variable If    ${ipv4_nat_remote} > 0    true    false
    Should Be Equal As Strings    ${ipv4_nat_remote}    {{ ft_yaml.ipv4_nat | default("false") | lower() }}    msg=ipv4_nat
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.interface."loopback-interface"
    ...    {{ ft_yaml.ipv4_nat_inside_source_loopback_interface | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_inside_source_loopback_interface_variable | default("not_defined") }}
    ...    msg=ipv4_nat_inside_source_loopback_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.overload
    ...    {{ ft_yaml.ipv4_nat_overload | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_overload_variable | default("not_defined") }}
    ...    msg=ipv4_nat_overload

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool."prefix-length"
    ...    {{ ft_yaml.ipv4_nat_pool_prefix_length | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_pool_prefix_length_variable | default("not_defined") }}
    ...    msg=ipv4_nat_pool_prefix_length

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool."range-end"
    ...    {{ ft_yaml.ipv4_nat_pool_range_end | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_pool_range_end_variable | default("not_defined") }}
    ...    msg=ipv4_nat_pool_range_end

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool."range-start"
    ...    {{ ft_yaml.ipv4_nat_pool_range_start | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_pool_range_start_variable | default("not_defined") }}
    ...    msg=ipv4_nat_pool_range_start

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."tcp-timeout"
    ...    {{ ft_yaml.ipv4_nat_tcp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_tcp_timeout_variable | default("not_defined") }}
    ...    msg=ipv4_nat_tcp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."udp-timeout"
    ...    {{ ft_yaml.ipv4_nat_udp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_udp_timeout_variable | default("not_defined") }}
    ...    msg=ipv4_nat_udp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."nat-choice"
    ...    {{ ft_yaml.ipv4_nat_type | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_nat_type_variable | default("not_defined") }}
    ...    msg=ipv4_nat_type
    
    Should Be Equal Value Json List Length    ${ft.json()}    nat."static-port-forward".vipValue    {{ ft_yaml.ipv4_port_forwarding_rules | default([]) | length }}    msg=ipv4_port_forwarding_rules length

    {% for port_fw in ft_yaml.ipv4_port_forwarding_rules | default([]) %}

    Log    === IPv4 Port Forwarding Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}].proto
    ...    {{ port_fw.protocol | default("not_defined") }}
    ...    {{ port_fw.protocol_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}]."source-ip"
    ...    {{ port_fw.source_ip | default("not_defined") }}
    ...    {{ port_fw.source_ip_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}]."source-port"
    ...    {{ port_fw.source_port | default("not_defined") }}
    ...    {{ port_fw.source_port_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.source_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}]."translate-ip"
    ...    {{ port_fw.translate_ip | default("not_defined") }}
    ...    {{ port_fw.translate_ip_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.translate_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}]."translate-port"
    ...    {{ port_fw.translate_port | default("not_defined") }}
    ...    {{ port_fw.translate_port_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.translate_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}]."source-vpn"
    ...    {{ port_fw.source_vpn_id | default("not_defined") }}
    ...    {{ port_fw.source_vpn_id_variable | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.source_vpn_id

    Should Be Equal Value Json String    ${ft.json()}    nat."static-port-forward".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ port_fw.optional | default("not_defined") }}
    ...    msg=ipv4_port_forwarding_rules.optional
    {% endfor %}

    Should be Equal Value Json List Length    ${ft.json()}    ip."secondary-address".vipValue    {{ ft_yaml.ipv4_secondary_addresses | default([]) | length }}    msg=ipv4_secondary_addresses length

    {% for sec_addr in ft_yaml.ipv4_secondary_addresses | default([]) %}

    Log    === IPv4 Secondary Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."secondary-address".vipValue[{{ loop.index0 }}].address
    ...    {{ sec_addr.address | default("not_defined") }}
    ...    {{ sec_addr.address_variable | default("not_defined") }}
    ...    msg=ipv4_secondary_addresses.address
    {% endfor %}
    
    Should Be Equal Value Json List Length    ${ft.json()}    nat.static.vipValue    {{ ft_yaml.ipv4_static_nat_rules | default([]) | length }}    msg=ipv4_static_nat_rules length

{% for static_nat in ft_yaml.ipv4_static_nat_rules | default([]) %}

    Log    === IPv4 Static NAT Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."source-ip"
    ...    {{ static_nat.source_ip | default("not_defined") }}
    ...    {{ static_nat.source_ip_variable | default("not_defined") }}
    ...    msg=ipv4_static_nat_rules.source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."translate-ip"
    ...    {{ static_nat.translate_ip | default("not_defined") }}
    ...    {{ static_nat.translate_ip_variable | default("not_defined") }}
    ...    msg=ipv4_static_nat_rules.translate_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."source-vpn"
    ...    {{ static_nat.source_vpn_id | default("not_defined") }}
    ...    {{ static_nat.source_vpn_id_variable | default("not_defined") }}
    ...    msg=ipv4_static_nat_rules.source_vpn_id

{% endfor %}

    Should be Equal Value Json List Length    ${ft.json()}    vrrp.vipValue    {{ ft_yaml.ipv4_vrrp_groups | default([]) | length }}    msg=ipv4_vrrp_groups length

{% for vrrp_group_index in range(ft_yaml.ipv4_vrrp_groups | default([]) | length()) %}

    Log    === IPv4 VRRP Group {{vrrp_group_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}].ipv4.address
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."grp-id"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].id | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].id_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}].priority
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].priority | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].priority_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.priority

    Should Be Equal Value Json String    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}].vipOptional
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].optional | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}].timer
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].timer | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].timer_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.timer

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."tloc-change-pref"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tloc_preference_change | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tloc_preference_change_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tloc_preference_change

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}].value
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tloc_preference_change_value | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tloc_preference_change_value_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tloc_preference_change_value

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."track-prefix-list"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].track_prefix_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].track_prefix_list_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.track_prefix_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."track-omp"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].track_omp | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].track_omp_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.track_omp

    Should be Equal Value Json List Length    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."tracking-object".vipValue    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects | default([]) | length }}    msg=ipv4_vrrp_groups.tracking_objects length

{% for tracking_object_index in range(ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects | default([]) | length()) %}

    ${ipv4_vrrp_track_objects}=    Json Search    ${ft.json()}    vrrp.vipValue[{{vrrp_group_index}}]."tracking-object"
    Log    === IPv4 VRRP Group {{vrrp_group_index}} Tracking Object {{tracking_object_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ipv4_vrrp_track_objects}    vipValue[{{tracking_object_index}}].name
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].id | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].id_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.id

    Should Be Equal Value Json Yaml UX1    ${ipv4_vrrp_track_objects}    vipValue[{{tracking_object_index}}]."track-action"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].action | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].action_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.action

    Should Be Equal Value Json Yaml UX1    ${ipv4_vrrp_track_objects}    vipValue[{{tracking_object_index}}].decrement
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].decrement_value | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_group_index].tracking_objects[tracking_object_index].decrement_value_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.decrement_value

{% endfor %}
{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.address
    ...    {{ ft_yaml.ipv6_address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_variable | default("not_defined") }}
    ...    msg=ipv6_address

    Should Be Equal Value Json List Length    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue    {{ ft_yaml.ipv6_dhcp_helpers | default([]) | length }}    msg=ipv6_dhcp_helpers length

    {% for dhcp_helper in ft_yaml.ipv6_dhcp_helpers | default([]) %}

    Log    === IPv6 DHCP Helper {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue[{{ loop.index0 }}].address
    ...    {{ dhcp_helper.address | default("not_defined") }}
    ...    {{ dhcp_helper.address_variable | default("not_defined") }}
    ...    msg=ipv6_dhcp_helpers.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue[{{ loop.index0 }}].vpn
    ...    {{ dhcp_helper.vpn_id | default("not_defined") }}
    ...    {{ dhcp_helper.vpn_id_variable | default("not_defined") }}
    ...    msg=ipv6_dhcp_helpers.vpn_id
    {% endfor %}

    # Custom handling for IPv6 NAT presence as there is no single field in JSON describing if IPv6 NAT is enabled or not
    ${ipv6_nat_presence_nat64}=   Json Search List   ${ft.json()}    nat64.*.vipValue
    ${ipv6_nat_presence_nat66}=   Json Search List   ${ft.json()}    nat66
    ${ipv6_nat_presence}=    Set Variable    ${ipv6_nat_presence_nat64} + ${ipv6_nat_presence_nat66}
    ${ipv6_nat_presence}=   Set Variable If    ${ipv6_nat_presence} == []    false    true
    Should Be Equal as Strings    ${ipv6_nat_presence}    {{ ft_yaml.ipv6_nat | default("false") | lower() }}    msg=ipv6_nat

    ${ipv6_nat_type}=    Set Variable If    ${ipv6_nat_presence_nat64} == []    not_defined    nat64
    ${ipv6_nat_type}=    Set Variable If    ${ipv6_nat_presence_nat66} == []    ${ipv6_nat_type}    nat66
    Should Be Equal As Strings    ${ipv6_nat_type}    {{ ft_yaml.ipv6_nat_type | default("not_defined") | lower() }}    msg=ipv6_nat_type
    # End of custom handling

    Should be Equal Value Json List Length    ${ft.json()}    ipv6."secondary-address".vipValue    {{ ft_yaml.ipv6_secondary_addresses | default([]) | length }}    msg=ipv6_secondary_addresses length

    {% for sec_addr in ft_yaml.ipv6_secondary_addresses | default([]) %}

    Log    === IPv6 Secondary Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."secondary-address".vipValue[{{ loop.index0 }}].address
    ...    {{ sec_addr.address | default("not_defined") }}
    ...    {{ sec_addr.address_variable | default("not_defined") }}
    ...    msg=ipv6_secondary_addresses.address
    {% endfor %}

    Should be Equal Value Json List Length    ${ft.json()}    nat66."static-nat66".vipValue    {{ ft_yaml.ipv6_static_nat_rules | default([]) | length }}    msg=ipv6_static_nat_rules length

    {% for static_nat in ft_yaml.ipv6_static_nat_rules | default([]) %}

    Log    === IPv6 Static NAT Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat66."static-nat66".vipValue[{{ loop.index0 }}]."source-prefix"
    ...    {{ static_nat.source_prefix | default("not_defined") }}
    ...    {{ static_nat.source_prefix_variable | default("not_defined") }}
    ...    msg=ipv6_static_nat_rules.source_prefix

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat66."static-nat66".vipValue[{{ loop.index0 }}]."translated-source-prefix"
    ...    {{ static_nat.translated_source_prefix | default("not_defined") }}
    ...    {{ static_nat.translated_source_prefix_variable | default("not_defined") }}
    ...    msg=ipv6_static_nat_rules.translated_source_prefix

    Should Be Equal Value Json String    ${ft.json()}    nat66."static-nat66".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ static_nat.optional | default("not_defined") }}
    ...    msg=ipv6_static_nat_rules.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat66."static-nat66".vipValue[{{ loop.index0 }}]."source-vpn-id"
    ...    {{ static_nat.source_vpn_id | default("not_defined") }}
    ...    {{ static_nat.source_vpn_id_variable | default("not_defined") }}
    ...    msg=ipv6_static_nat_rules.source_vpn_id
    {% endfor %}

    Should be Equal Value Json List Length    ${ft.json()}    "ipv6-vrrp".vipValue    {{ ft_yaml.ipv6_vrrp_groups | default([]) | length }}    msg=ipv6_vrrp_groups length

    {% for vrrp_group in ft_yaml.ipv6_vrrp_groups | default([]) %}

    Log    === IPv6 VRRP Group {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}]."grp-id"
    ...    {{ vrrp_group.id | default("not_defined") }}
    ...    {{ vrrp_group.id_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}].priority
    ...    {{ vrrp_group.priority | default("not_defined") }}
    ...    {{ vrrp_group.priority_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.priority

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}].timer
    ...    {{ vrrp_group.timer | default("not_defined") }}
    ...    {{ vrrp_group.timer_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.timer

    Should Be Equal Value Json String    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ vrrp_group.optional | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}]."track-prefix-list"
    ...    {{ vrrp_group.track_prefix_list | default("not_defined") }}
    ...    {{ vrrp_group.track_prefix_list_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.track_prefix_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}]."track-omp"
    ...    {{ vrrp_group.track_omp | default("not_defined") }}
    ...    {{ vrrp_group.track_omp_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.track_omp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}].ipv6.vipValue[0]."ipv6-link-local"
    ...    {{ vrrp_group.link_local_address | default("not_defined") }}
    ...    {{ vrrp_group.link_local_address_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.link_local_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ loop.index0 }}].ipv6.vipValue[0].prefix
    ...    {{ vrrp_group.global_prefix | default("not_defined") }}
    ...    {{ vrrp_group.global_prefix_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.global_prefix
    {% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "load-interval"
    ...    {{ ft_yaml.load_interval | default("not_defined") }}
    ...    {{ ft_yaml.load_interval_variable | default("not_defined") }}
    ...    msg=load_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "mac-address"
    ...    {{ ft_yaml.mac_address | default("not_defined") }}
    ...    {{ ft_yaml.mac_address_variable | default("not_defined") }}
    ...    msg=mac_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "media-type"
    ...    {{ ft_yaml.media_type | default("not_defined") }}
    ...    {{ ft_yaml.media_type_variable | default("not_defined") }}
    ...    msg=media_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "intrf-mtu"
    ...    {{ ft_yaml.mtu | default("not_defined") }}
    ...    {{ ft_yaml.mtu_variable | default("not_defined") }}
    ...    msg=mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "rewrite-rule"."rule-name"
    ...    {{ ft_yaml.rewrite_rule | default("not_defined") }}
    ...    {{ ft_yaml.rewrite_rule_variable | default("not_defined") }}
    ...    msg=rewrite_rule

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "shaping-rate"
    ...    {{ ft_yaml.shaping_rate | default("not_defined") }}
    ...    {{ ft_yaml.shaping_rate_variable | default("not_defined") }}
    ...    msg=shaping_rate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should be Equal Value Json List Length    ${ft.json()}    arp.ip.vipValue    {{ ft_yaml.static_arps | default([]) | length }}    msg=static_arps length

    {% for static_arp in ft_yaml.static_arps | default([]) %}

    Log    === Static ARP Entry {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].mac
    ...    {{ static_arp.mac_address | default("not_defined") }}
    ...    {{ static_arp.mac_address_variable | default("not_defined") }}
    ...    msg=static_arps.mac_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].addr
    ...    {{ static_arp.ip_address | default("not_defined") }}
    ...    {{ static_arp.ip_address_variable | default("not_defined") }}
    ...    msg=static_arps.ip_address

    Should Be Equal Value Json String    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ static_arp.optional | default("not_defined") }}
    ...    msg=static_arps.optional
    {% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.static.sgt
    ...    {{ ft_yaml.static_sgt | default("not_defined") }}
    ...    {{ ft_yaml.static_sgt_variable | default("not_defined") }}
    ...    msg=static_sgt

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.enforcement.enable
    ...    {{ ft_yaml.sgt_enforcement | default("not_defined") }}
    ...    {{ ft_yaml.sgt_enforcement_variable | default("not_defined") }}
    ...    msg=sgt_enforcement

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.enforcement.sgt
    ...    {{ ft_yaml.sgt_enforcement_tag | default("not_defined") }}
    ...    {{ ft_yaml.sgt_enforcement_tag_variable | default("not_defined") }}
    ...    msg=sgt_enforcement_tag

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.propagate.sgt
    ...    {{ ft_yaml.sgt_propagation | default("not_defined") }}
    ...    {{ ft_yaml.sgt_propagation_variable | default("not_defined") }}
    ...    msg=sgt_propagation

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.static.trusted
    ...    {{ ft_yaml.sgt_trusted | default("not_defined") }}
    ...    {{ ft_yaml.sgt_trusted_variable | default("not_defined") }}
    ...    msg=sgt_trusted

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    speed
    ...    {{ ft_yaml.speed | default("not_defined") }}
    ...    {{ ft_yaml.speed_variable | default("not_defined") }}
    ...    msg=speed

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tcp-mss-adjust"
    ...    {{ ft_yaml.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tcp_mss_variable | default("not_defined") }}
    ...    msg=tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tloc-extension"
    ...    {{ ft_yaml.tloc_extension | default("not_defined") }}
    ...    {{ ft_yaml.tloc_extension_variable | default("not_defined") }}
    ...    msg=tloc_extension

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker
    ...    {{ ft_yaml.tracker | default("not_defined") }}
    ...    {{ ft_yaml.tracker_variable | default("not_defined") }}
    ...    msg=tracker

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-map"
    ...    {{ ft_yaml.qos_map | default("not_defined") }}
    ...    {{ ft_yaml.qos_map_variable | default("not_defined") }}
    ...    msg=qos_map

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-map-vpn"
    ...    {{ ft_yaml.vpn_qos_map | default("not_defined") }}
    ...    {{ ft_yaml.vpn_qos_map_variable | default("not_defined") }}
    ...    msg=vpn_qos_map

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".all
    ...    {{ ft_yaml.tunnel_interface.allow_service_all | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_all_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_all

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".bgp
    ...    {{ ft_yaml.tunnel_interface.allow_service_bgp | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_bgp_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_bgp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".dhcp
    ...    {{ ft_yaml.tunnel_interface.allow_service_dhcp | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_dhcp_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_dhcp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".dns
    ...    {{ ft_yaml.tunnel_interface.allow_service_dns | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_dns_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_dns

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".https
    ...    {{ ft_yaml.tunnel_interface.allow_service_https | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_https_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_https

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".icmp
    ...    {{ ft_yaml.tunnel_interface.allow_service_icmp | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_icmp_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_icmp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".netconf
    ...    {{ ft_yaml.tunnel_interface.allow_service_netconf | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_netconf_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_netconf

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".ntp
    ...    {{ ft_yaml.tunnel_interface.allow_service_ntp | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_ntp_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_ntp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".ospf
    ...    {{ ft_yaml.tunnel_interface.allow_service_ospf | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_ospf_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_ospf

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".snmp
    ...    {{ ft_yaml.tunnel_interface.allow_service_snmp | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_snmp_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_snmp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".sshd
    ...    {{ ft_yaml.tunnel_interface.allow_service_ssh | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_ssh_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_ssh

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."allow-service".stun
    ...    {{ ft_yaml.tunnel_interface.allow_service_stun | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.allow_service_stun_variable | default("not_defined") }}
    ...    msg=tunnel_interface.allow_service_stun

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".bind
    ...    {{ ft_yaml.tunnel_interface.bind_loopback_tunnel | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.bind_loopback_tunnel_variable | default("not_defined") }}
    ...    msg=tunnel_interface.bind_loopback_tunnel

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".border
    ...    {{ ft_yaml.tunnel_interface.border | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.border_variable | default("not_defined") }}
    ...    msg=tunnel_interface.border

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".carrier
    ...    {{ ft_yaml.tunnel_interface.carrier | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.carrier_variable | default("not_defined") }}
    ...    msg=tunnel_interface.carrier

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."clear-dont-fragment"
    ...    {{ ft_yaml.tunnel_interface.clear_dont_fragment | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.clear_dont_fragment_variable | default("not_defined") }}
    ...    msg=tunnel_interface.clear_dont_fragment

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".color.value
    ...    {{ ft_yaml.tunnel_interface.color | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.color_variable | default("not_defined") }}
    ...    msg=tunnel_interface.color

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."core-region"
    ...    {{ ft_yaml.tunnel_interface.core_region | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.core_region_variable | default("not_defined") }}
    ...    msg=tunnel_interface.core_region

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."enable-core-region"
    ...    {{ ft_yaml.tunnel_interface.enable_core_region | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.enable_core_region_variable | default("not_defined") }}
    ...    msg=tunnel_interface.enable_core_region

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."exclude-controller-group-list"
    ...    {{ ft_yaml.tunnel_interface.exclude_controller_groups | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.exclude_controller_groups_variable | default("not_defined") }}
    ...    msg=tunnel_interface.exclude_controller_groups

    # Custom handling to detect if GRE encapsulation is enabled
    ${gre_encap}=    Json Search List    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'gre'].encap.vipValue
    IF    ${gre_encap} != []
        ${gre_encap}=    Set Variable If     "${gre_encap}[0]" == "gre"    true    not_defined
    ELSE
        ${gre_encap}=    Set Variable    not_defined
    END
    Should Be Equal As Strings    {{ ft_yaml.tunnel_interface.gre_encapsulation | default("not_defined") | lower() }}    ${gre_encap}    msg=tunnel_interface.gre_encapsulation
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'gre'] | [0].preference
    ...    {{ ft_yaml.tunnel_interface.gre_preference | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.gre_preference_variable | default("not_defined") }}
    ...    msg=tunnel_interface.gre_preference

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'gre'] | [0].weight
    ...    {{ ft_yaml.tunnel_interface.gre_weight | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.gre_weight_variable | default("not_defined") }}
    ...    msg=tunnel_interface.gre_weight

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".group
    ...    {{ ft_yaml.tunnel_interface.group | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.group_variable | default("not_defined") }}
    ...    msg=tunnel_interface.group

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."hello-interval"
    ...    {{ ft_yaml.tunnel_interface.hello_interval | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.hello_interval_variable | default("not_defined") }}
    ...    msg=tunnel_interface.hello_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."hello-tolerance"
    ...    {{ ft_yaml.tunnel_interface.hello_tolerance | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.hello_tolerance_variable | default("not_defined") }}
    ...    msg=tunnel_interface.hello_tolerance

    # Custom handling to detect if IPsec encapsulation is enabled
    ${ipsec_encap}=    Json Search List    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'ipsec'].encap.vipValue
    IF    ${ipsec_encap} != []
        ${ipsec_encap}=    Set Variable If     "${ipsec_encap}[0]" == "ipsec"    true    not_defined
    ELSE
        ${ipsec_encap}=    Set Variable    not_defined
    END
    Should Be Equal As Strings    {{ ft_yaml.tunnel_interface.ipsec_encapsulation | default("not_defined") | lower() }}    ${ipsec_encap}    msg=tunnel_interface.ipsec_encapsulation
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'ipsec'] | [0].preference
    ...    {{ ft_yaml.tunnel_interface.ipsec_preference | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.ipsec_preference_variable | default("not_defined") }}
    ...    msg=tunnel_interface.ipsec_preference

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'ipsec'] | [0].weight
    ...    {{ ft_yaml.tunnel_interface.ipsec_weight | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.ipsec_weight_variable | default("not_defined") }}
    ...    msg=tunnel_interface.ipsec_weight

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."last-resort-circuit"
    ...    {{ ft_yaml.tunnel_interface.last_resort_circuit | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.last_resort_circuit_variable | default("not_defined") }}
    ...    msg=tunnel_interface.last_resort_circuit

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."low-bandwidth-link"
    ...    {{ ft_yaml.tunnel_interface.low_bandwidth_link | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.low_bandwidth_link_variable | default("not_defined") }}
    ...    msg=tunnel_interface.low_bandwidth_link

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."max-control-connections"
    ...    {{ ft_yaml.tunnel_interface.max_control_connections | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.max_control_connections_variable | default("not_defined") }}
    ...    msg=tunnel_interface.max_control_connections

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."nat-refresh-interval"
    ...    {{ ft_yaml.tunnel_interface.nat_refresh_interval | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.nat_refresh_interval_variable | default("not_defined") }}
    ...    msg=tunnel_interface.nat_refresh_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."network-broadcast"
    ...    {{ ft_yaml.tunnel_interface.network_broadcast | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.network_broadcast_variable | default("not_defined") }}
    ...    msg=tunnel_interface.network_broadcast

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."port-hop"
    ...    {{ ft_yaml.tunnel_interface.port_hop | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.port_hop_variable | default("not_defined") }}
    ...    msg=tunnel_interface.port_hop

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."tunnel-tcp-mss-adjust"
    ...    {{ ft_yaml.tunnel_interface.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.tcp_mss_variable | default("not_defined") }}
    ...    msg=tunnel_interface.tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."tunnel-qos".mode
    ...    {{ ft_yaml.tunnel_interface.per_tunnel_qos_mode | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.per_tunnel_qos_mode_variable | default("not_defined") }}
    ...    msg=tunnel_interface.per_tunnel_qos_mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface".color.restrict
    ...    {{ ft_yaml.tunnel_interface.restrict | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.restrict_variable | default("not_defined") }}
    ...    msg=tunnel_interface.restrict

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."secondary-region"
    ...    {{ ft_yaml.tunnel_interface.secondary_region | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.secondary_region_variable | default("not_defined") }}
    ...    msg=tunnel_interface.secondary_region

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."vbond-as-stun-server"
    ...    {{ ft_yaml.tunnel_interface.vbond_as_stun_server | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.vbond_as_stun_server_variable | default("not_defined") }}
    ...    msg=tunnel_interface.vbond_as_stun_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."vmanage-connection-preference"
    ...    {{ ft_yaml.tunnel_interface.vmanage_connection_preference | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.vmanage_connection_preference_variable | default("not_defined") }}
    ...    msg=tunnel_interface.vmanage_connection_preference

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."tunnels-bandwidth"
    ...    {{ ft_yaml.tunnel_interface.per_tunnel_qos_bandwidth_percent | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.per_tunnel_qos_bandwidth_percent_variable | default("not_defined") }}
    ...    msg=tunnel_interface.per_tunnel_qos_bandwidth_percent

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-interface"."propagate-sgt"
    ...    {{ ft_yaml.tunnel_interface.propagate_sgt | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_interface.propagate_sgt_variable | default("not_defined") }}
    ...    msg=tunnel_interface.propagate_sgt

{% endfor %}
{% endif %}