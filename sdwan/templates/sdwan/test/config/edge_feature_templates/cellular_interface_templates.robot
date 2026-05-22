*** Settings ***
Documentation   Verify Cellular Interface Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.cellular_interface_templates is defined %}

*** Test Cases ***
Get Cellular Interface Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='vpn-cedge-interface-cellular']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.cellular_interface_templates | default([]) %}

Verify Edge Feature Template Cellular Interface Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.cellular_interface_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "if-name"
    ...    {{ ft_yaml.interface_name | default("not_defined") }}
    ...    {{ ft_yaml.interface_name_variable | default("not_defined") }}
    ...    msg=interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    description
    ...    {{ ft_yaml.interface_description | default("not_defined") }}
    ...    {{ ft_yaml.interface_description_variable | default("not_defined") }}
    ...    msg=interface_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dhcp-helper"
    ...    {{ ft_yaml.dhcp_helpers | default("not_defined") }}
    ...    {{ ft_yaml.dhcp_helpers_variable | default("not_defined") }}
    ...    msg=dhcp_helpers

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "bandwidth-downstream"
    ...    {{ ft_yaml.bandwidth_downstream | default("not_defined") }}
    ...    {{ ft_yaml.bandwidth_downstream_variable | default("not_defined") }}
    ...    msg=bandwidth_downstream

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "bandwidth-upstream"
    ...    {{ ft_yaml.bandwidth_upstream | default("not_defined") }}
    ...    {{ ft_yaml.bandwidth_upstream_variable | default("not_defined") }}
    ...    msg=bandwidth_upstream

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    mtu
    ...    {{ ft_yaml.ip_mtu | default("not_defined") }}
    ...    {{ ft_yaml.ip_mtu_variable | default("not_defined") }}
    ...    msg=ip_mtu

    # Custom handling for NAT as there is no single field in JSON describing if NAT is enabled or not
    ${nat_json}=    Json Search List    ${ft.json()}    nat.*.vipType
    ${nat_json}=    Set Variable If    ${nat_json} == []    not_defined    True
    Should Be Equal As Strings    ${nat_json}    {{ ft_yaml.nat | default("not_defined") }}    msg=nat
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.refresh
    ...    {{ ft_yaml.nat_refresh_mode | default("not_defined") }}
    ...    {{ ft_yaml.nat_refresh_mode_variable | default("not_defined") }}
    ...    msg=nat_refresh_mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."tcp-timeout"
    ...    {{ ft_yaml.nat_tcp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.nat_tcp_timeout_variable | default("not_defined") }}
    ...    msg=nat_tcp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."udp-timeout"
    ...    {{ ft_yaml.nat_udp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.nat_udp_timeout_variable | default("not_defined") }}
    ...    msg=nat_udp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."block-icmp-error"
    ...    {{ ft_yaml.nat_block_icmp | default("not_defined") }}
    ...    {{ ft_yaml.nat_block_icmp_variable | default("not_defined") }}
    ...    msg=nat_block_icmp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."respond-to-ping"
    ...    {{ ft_yaml.nat_respond_to_ping | default("not_defined") }}
    ...    {{ ft_yaml.nat_respond_to_ping_variable | default("not_defined") }}
    ...    msg=nat_respond_to_ping

    Should Be Equal Value Json List Length    ${ft.json()}    nat."port-forward".vipValue    {{ ft_yaml.nat_port_forwarding_rules | default([]) | length }}    msg=nat_port_forwarding_rules length
    {% for port_fw in ft_yaml.nat_port_forwarding_rules | default([]) %}

    Log    === NAT Port Forwarding Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."port-start"
    ...    {{ port_fw.port_range_start | default("not_defined") }}
    ...    {{ port_fw.port_range_start_variable | default("not_defined") }}
    ...    msg=nat_port_forwarding_rules.port_range_start

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."port-end"
    ...    {{ port_fw.port_range_end | default("not_defined") }}
    ...    {{ port_fw.port_range_end_variable | default("not_defined") }}
    ...    msg=nat_port_forwarding_rules.port_range_end

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}].proto
    ...    {{ port_fw.protocol | default("not_defined") }}
    ...    {{ port_fw.protocol_variable | default("not_defined") }}
    ...    msg=nat_port_forwarding_rules.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."private-vpn"
    ...    {{ port_fw.vpn | default("not_defined") }}
    ...    {{ port_fw.vpn_variable | default("not_defined") }}
    ...    msg=nat_port_forwarding_rules.vpn

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."private-ip-address"
    ...    {{ port_fw.private_ip | default("not_defined") }}
    ...    {{ port_fw.private_ip_variable | default("not_defined") }}
    ...    msg=nat_port_forwarding_rules.private_ip
    {% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".period
    ...    {{ ft_yaml.adaptive_qos_period | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_period_variable | default("not_defined") }}
    ...    msg=adaptive_qos_period

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream."bandwidth-down"
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.default | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.default_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream_default

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream.range.dmax
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.maximum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.maximum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream_maximum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".downstream.range.dmin
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.minimum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_downstream.minimum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_downstream_minimum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream."bandwidth-up"
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.default | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.default_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream_default

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream.range.umax
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.maximum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.maximum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream_maximum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-adaptive".upstream.range.umin
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.minimum | default("not_defined") }}
    ...    {{ ft_yaml.adaptive_qos_shaping_rate_upstream.minimum_variable | default("not_defined") }}
    ...    msg=adaptive_qos_shaping_rate_upstream_minimum

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "shaping-rate"
    ...    {{ ft_yaml.shaping_rate | default("not_defined") }}
    ...    {{ ft_yaml.shaping_rate_variable | default("not_defined") }}
    ...    msg=shaping_rate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-map"
    ...    {{ ft_yaml.qos_map | default("not_defined") }}
    ...    {{ ft_yaml.qos_map_variable | default("not_defined") }}
    ...    msg=qos_map

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "qos-map-vpn"
    ...    {{ ft_yaml.vpn_qos_map | default("not_defined") }}
    ...    {{ ft_yaml.vpn_qos_map_variable | default("not_defined") }}
    ...    msg=vpn_qos_map

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "rewrite-rule"."rule-name"
    ...    {{ ft_yaml.rewrite_rule | default("not_defined") }}
    ...    {{ ft_yaml.rewrite_rule_variable | default("not_defined") }}
    ...    msg=rewrite_rule

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    policer.vipValue[?direction.vipValue=='in'] | [0]."policer-name"
    ...    {{ ft_yaml.ingress_policer_name | default("not_defined") }}
    ...    {{ ft_yaml.ingress_policer_name_variable | default("not_defined") }}
    ...    msg=ingress_policer_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    policer.vipValue[?direction.vipValue=='out'] | [0]."policer-name"
    ...    {{ ft_yaml.egress_policer_name | default("not_defined") }}
    ...    {{ ft_yaml.egress_policer_name_variable | default("not_defined") }}
    ...    msg=egress_policer_name

    Should Be Equal Value Json List Length    ${ft.json()}    arp.ip.vipValue    {{ ft_yaml.static_arps | default([]) | length }}    msg=static_arps length
    {% for static_arp in ft_yaml.static_arps | default([]) %}

    Log    === Static ARP Entry {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].addr
    ...    {{ static_arp.ip_address | default("not_defined") }}
    ...    {{ static_arp.ip_address_variable | default("not_defined") }}
    ...    msg=static_arps.ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].mac
    ...    {{ static_arp.mac_address | default("not_defined") }}
    ...    {{ static_arp.mac_address_variable | default("not_defined") }}
    ...    msg=static_arps.mac_address

    Should Be Equal Value Json String    ${ft.json()}    arp.ip.vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ static_arp.optional | default("not_defined") }}
    ...    msg=static_arps.optional

    {% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pmtu
    ...    {{ ft_yaml.path_mtu_discovery | default("not_defined") }}
    ...    {{ ft_yaml.path_mtu_discovery_variable | default("not_defined") }}
    ...    msg=path_mtu_discovery

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tcp-mss-adjust"
    ...    {{ ft_yaml.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tcp_mss_variable | default("not_defined") }}
    ...    msg=tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "clear-dont-fragment"
    ...    {{ ft_yaml.clear_dont_fragment | default("not_defined") }}
    ...    {{ ft_yaml.clear_dont_fragment_variable | default("not_defined") }}
    ...    msg=clear_dont_fragment

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-ingress-qos"
    ...    {{ ft_yaml.static_ingress_qos | default("not_defined") }}
    ...    {{ ft_yaml.static_ingress_qos_variable | default("not_defined") }}
    ...    msg=static_ingress_qos

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    autonegotiate
    ...    {{ ft_yaml.autonegotiate | default("not_defined") }}
    ...    {{ ft_yaml.autonegotiate_variable | default("not_defined") }}
    ...    msg=autonegotiate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tloc-extension"
    ...    {{ ft_yaml.tloc_extension | default("not_defined") }}
    ...    {{ ft_yaml.tloc_extension_variable | default("not_defined") }}
    ...    msg=tloc_extension

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker"
    ...    {{ ft_yaml.tracker | default("not_defined") }}
    ...    {{ ft_yaml.tracker_variable | default("not_defined") }}
    ...    msg=tracker

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ip-directed-broadcast"
    ...    {{ ft_yaml.ip_directed_broadcast | default("not_defined") }}
    ...    {{ ft_yaml.ip_directed_broadcast_variable | default("not_defined") }}
    ...    msg=ip_directed_broadcast

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

    # Custom handling to detect if gre/ipsec encaps are enabled
    ${gre_encap}=    Json Search List    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'gre'].encap.vipValue
    IF    ${gre_encap} != []
        ${gre_encap}=    Set Variable If     "${gre_encap}[0]" == "gre"    true    not_defined
    ELSE
        ${gre_encap}=    Set Variable    not_defined
    END
    Should Be Equal As Strings    {{ ft_yaml.tunnel_interface.gre_encapsulation | default("not_defined") | lower() }}    ${gre_encap}    msg=tunnel_interface.gre_encapsulation expected: '{{ ft_yaml.tunnel_interface.gre_encapsulation | default("not_defined")  | lower() }}' and got: ${gre_encap}
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

    # Custom handling to detect if ipsec encap is enabled
    ${ipsec_encap}=    Json Search List    ${ft.json()}    "tunnel-interface".encapsulation.vipValue[?encap.vipValue == 'ipsec'].encap.vipValue
    IF    ${ipsec_encap} != []
        ${ipsec_encap}=    Set Variable If     "${ipsec_encap}[0]" == "ipsec"    true    not_defined
    ELSE
        ${ipsec_encap}=    Set Variable    not_defined
    END
    Should Be Equal As Strings    {{ ft_yaml.tunnel_interface.ipsec_encapsulation | default("not_defined") | lower() }}    ${ipsec_encap}    msg=tunnel_interface.ipsec_encapsulation expected: '{{ ft_yaml.tunnel_interface.ipsec_encapsulation | default("not_defined") | lower() }}' and got: ${ipsec_encap}
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

{% endfor %}

{% endif %}