*** Settings ***
Documentation   Verify VPN Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.vpn_templates is defined %}

*** Test Cases ***
Get VPN Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_vpn']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.vpn_templates | default([]) %}

Verify Edge Feature Template VPN Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.vpn_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ecmp-hash-key".layer4
    ...    {{ ft_yaml.enhance_ecmp_keying | default("not_defined") | lower }}
    ...    {{ ft_yaml.enhance_ecmp_keying_variable | default("not_defined") }}
    ...    msg=enhance_ecmp_keying

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    dns.vipValue[?role.vipValue=='primary'] | [0]."dns-addr"
    ...    {{ ft_yaml.ipv4_primary_dns_server | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_primary_dns_server_variable | default("not_defined") }}
    ...    msg=ipv4_primary_dns_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    dns.vipValue[?role.vipValue=='secondary'] | [0]."dns-addr"
    ...    {{ ft_yaml.ipv4_secondary_dns_server | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_secondary_dns_server_variable | default("not_defined") }}
    ...    msg=ipv4_secondary_dns_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dns-ipv6".vipValue[?role.vipValue=='primary'] | [0]."dns-addr"
    ...    {{ ft_yaml.ipv6_primary_dns_server | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_primary_dns_server_variable | default("not_defined") }}
    ...    msg=ipv6_primary_dns_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dns-ipv6".vipValue[?role.vipValue=='secondary'] | [0]."dns-addr"
    ...    {{ ft_yaml.ipv6_secondary_dns_server | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_secondary_dns_server_variable | default("not_defined") }}
    ...    msg=ipv6_secondary_dns_server

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "omp-admin-distance-ipv4"
    ...    {{ ft_yaml.omp_admin_distance_ipv4 | default("not_defined") }}
    ...    {{ ft_yaml.omp_admin_distance_ipv4_variable | default("not_defined") }}
    ...    msg=omp_admin_distance_ipv4

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "omp-admin-distance-ipv6"
    ...    {{ ft_yaml.omp_admin_distance_ipv6 | default("not_defined") }}
    ...    {{ ft_yaml.omp_admin_distance_ipv6_variable | default("not_defined") }}
    ...    msg=omp_admin_distance_ipv6

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "vpn-id"
    ...    {{ ft_yaml.vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.vpn_id_variable | default("not_defined") }}
    ...    msg=vpn_id

    # Custom handling for vpn_name as it might have multiple spaces
    Should Be Equal Value Json Special_String    ${ft.json()}   name.vipValue    {{ ft_yaml.vpn_name | default("not_defined") | normalize_special_string }}    msg=name
    Should Be Equal Value Json String    ${ft.json()}   name.vipVariableName    {{ ft_yaml.vpn_name_variable | default("not_defined") }}    msg=name_variable
    # End of custom handling

    Should Be Equal Value Json List Length    ${ft.json()}    host.vipValue    {{ ft_yaml.ipv4_dns_hosts | default([]) | length + ft_yaml.ipv6_dns_hosts | default([]) | length }}    msg=ipv4_dns_hosts|ipv6_dns_hosts.length

{% for ipv4_host in ft_yaml.ipv4_dns_hosts | default([]) %}

    Log    === IPv4 DNS Host {{loop.index0}} ===
    ${hostname_det}=    Json Search List    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv4_host.hostname }}'].hostname
    Should Not be Empty   ${hostname_det}   msg=ipv4 hostname not present

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv4_host.hostname }}'] | [0].hostname
    ...    {{ ipv4_host.hostname | default("not_defined") }}
    ...    {{ ipv4_host.hostname_variable | default("not_defined") }}
    ...    msg=ipv4_dns_hosts.hostname

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv4_host.hostname }}'] | [0].ip
    ...    {{ ipv4_host.ips | default("not_defined") }}
    ...    {{ ipv4_host.ips_variable | default("not_defined") }}
    ...    msg=ipv4_dns_hosts.ips

    Should Be Equal Value Json String    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv4_host.hostname }}'].vipOptional    {{ ipv4_host.optional | default("not_defined") }}    msg=ipv4_dns_hosts.optional

{% endfor %}

{% for ipv6_host in ft_yaml.ipv6_dns_hosts | default([]) %}

    Log    === IPv6 DNS Host {{loop.index0}} ===
    ${hostname_det}=    Json Search List    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv6_host.hostname }}'].hostname
    Should Not be Empty   ${hostname_det}   msg=ipv6 hostname not present

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv6_host.hostname }}'] | [0].hostname
    ...    {{ ipv6_host.hostname | default("not_defined") }}
    ...    {{ ipv6_host.hostname_variable | default("not_defined") }}
    ...    msg=ipv6_dns_hosts.hostname

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv6_host.hostname }}'] | [0].ip
    ...    {{ ipv6_host.ips | default("not_defined") }}
    ...    {{ ipv6_host.ips_variable | default("not_defined") }}
    ...    msg=ipv6_dns_hosts.ips

    Should Be Equal Value Json String    ${ft.json()}    host.vipValue[?hostname.vipValue=='{{ ipv6_host.hostname }}'].vipOptional    {{ ipv6_host.optional | default("not_defined") }}    msg=ipv6_dns_hosts.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ip."gre-route".vipValue    {{ ft_yaml.ipv4_static_gre_routes | default([]) | length }}    msg=ipv4_static_gre_routes.length

{% for ipv4_gre in ft_yaml.ipv4_static_gre_routes | default([]) %}

    Log    === IPv4 Static GRE Route {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."gre-route".vipValue[{{ loop.index0 }}].interface
    ...    {{ ipv4_gre.interfaces | default("not_defined") }}
    ...    {{ ipv4_gre.interfaces_variable | default("not_defined") }}
    ...    msg=ipv4_static_gre_routes.interfaces

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."gre-route".vipValue[{{ loop.index0 }}].prefix
    ...    {{ ipv4_gre.prefix | default("not_defined") }}
    ...    {{ ipv4_gre.prefix_variable | default("not_defined") }}
    ...    msg=ipv4_static_gre_routes.prefix

    Should Be Equal Value Json String    ${ft.json()}    ip."gre-route".vipValue[{{ loop.index0 }}].vipOptional    {{ ipv4_gre.optional | default("not_defined") }}    msg=ipv4_static_gre_routes.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ip."ipsec-route".vipValue    {{ ft_yaml.ipv4_static_ipsec_routes | default([]) | length }}    msg=ipv4_static_ipsec_routes.length

{% for ipv4_ipsec in ft_yaml.ipv4_static_ipsec_routes | default([]) %}

    Log    === IPv4 Static IPsec Route {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."ipsec-route".vipValue[{{ loop.index0 }}].interface
    ...    {{ ipv4_ipsec.interfaces | default("not_defined") }}
    ...    {{ ipv4_ipsec.interfaces_variable | default("not_defined") }}
    ...    msg=ipv4_static_ipsec_routes.interfaces

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."ipsec-route".vipValue[{{ loop.index0 }}].prefix
    ...    {{ ipv4_ipsec.prefix | default("not_defined") }}
    ...    {{ ipv4_ipsec.prefix_variable | default("not_defined") }}
    ...    msg=ipv4_static_ipsec_routes.prefix

    Should Be Equal Value Json String    ${ft.json()}    ip."ipsec-route".vipValue[{{ loop.index0 }}].vipOptional    {{ ipv4_ipsec.optional | default("not_defined") }}    msg=ipv4_static_ipsec_routes.optional

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ip.route.vipValue    {{ ft_yaml.ipv4_static_routes | default([]) | length }}    msg=ipv4_static_routes.length

{% for v4_route_index in range(ft_yaml.ipv4_static_routes | default([]) | length()) %}

    Log    === IPv4 Static Route {{v4_route_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].dhcp
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dhcp | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dhcp_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.next_hop_dhcp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].null0
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_null0 | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_null0_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.next_hop_null0

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].distance
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_null0_distance | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_null0_distance_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.next_hop_null0_distance

    ${dia_val}=    Json Search List    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].vpn.vipValue

    # Custom handling to check if DIA is enabled or not
{% if ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | default("not_defined") | lower() == "true" %}
    IF    ${dia_val} == []
        ${r_value}=    Set Variable    not_defined
    ELSE
        ${r_value}=    Set Variable If    "${dia_val[0]}" == "0"    true
    END
    Should Be Equal As Strings    ${r_value}    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | lower() }}    msg=ipv4_static_routes.next_hop_dia
{% elif ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | default("not_defined") | lower() == "false" %}
    IF    ${dia_val} == []
        ${r_value}=    Set Variable    false
    ELSE
        ${r_value}=    Set Variable    ${dia_val[0]}
    END
    Should Be Equal As Strings    ${r_value}    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | lower() }}    msg=ipv4_static_routes.next_hop_dia
{% elif ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | default("not_defined") == "not_defined" %}
    Should Be Equal Value Json String    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].vpn.vipValue    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hop_dia | default("not_defined") }}    msg=ipv4_static_routes.next_hop_dia
{% endif %}
    # End of custom handling

    Should Be Equal Value Json String    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].vipOptional    {{ ft_yaml.ipv4_static_routes[v4_route_index].optional | default("not_defined") }}    msg=ipv4_static_routes.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}].prefix
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].prefix | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].prefix_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.prefix

    Should Be Equal Value Json List Length    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop".vipValue    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hops | default([]) | length }}    msg=ipv4_static_routes.next_hops.length

{% for v4_hop_index in range(ft_yaml.ipv4_static_routes[v4_route_index].next_hops | default([]) | length()) %}

    Log    === IPv4 Static Route {{v4_route_index}} Next Hop {{v4_hop_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop".vipValue[{{ v4_hop_index }}].address
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hops[v4_hop_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hops[v4_hop_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.next_hops.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop".vipValue[{{ v4_hop_index }}].distance
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hops[v4_hop_index].distance | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].next_hops[v4_hop_index].distance_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.next_hops.distance

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop-with-track".vipValue    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops | default([]) | length }}    msg=ipv4_static_routes.track_next_hops.length

{% for v4_track_index in range(ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops | default([]) | length()) %}

    Log    === IPv4 Static Route {{v4_route_index}} Track Next Hop {{v4_track_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop-with-track".vipValue[{{ v4_track_index }}].address
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.track_next_hops.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop-with-track".vipValue[{{ v4_track_index }}].distance
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].distance | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].distance_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.track_next_hops.distance

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.route.vipValue[{{ v4_route_index }}]."next-hop-with-track".vipValue[{{ v4_track_index }}].tracker
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].tracker | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_static_routes[v4_route_index].track_next_hops[v4_track_index].tracker_variable | default("not_defined") }}
    ...    msg=ipv4_static_routes.track_next_hops.tracker

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ip."service-route".vipValue    {{ ft_yaml.ipv4_static_service_routes | default([]) | length }}    msg=ipv4_static_service_routes.length

{% for ipv4_service in ft_yaml.ipv4_static_service_routes | default([]) %}

    Log    === IPv4 Static Service Route {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."service-route".vipValue[{{ loop.index0 }}].prefix
    ...    {{ ipv4_service.prefix | default("not_defined") }}
    ...    {{ ipv4_service.prefix_variable | default("not_defined") }}
    ...    msg=ipv4_static_service_routes.prefix

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."service-route".vipValue[{{ loop.index0 }}].service
    ...    {{ ipv4_service.service | default("not_defined") }}
    ...    {{ ipv4_service.service_variable | default("not_defined") }}
    ...    msg=ipv4_static_service_routes.service

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ipv6.route.vipValue    {{ ft_yaml.ipv6_static_routes | default([]) | length }}    msg=ipv6_static_routes.length

{% for v6_route_index in range(ft_yaml.ipv6_static_routes | default([]) | length()) %}

    Log    === IPv6 Static Route {{v6_route_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].nat
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].nat | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].nat_variable | default("not_defined") }}
    ...    msg=ipv6_static_routes.nat

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].null0
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hop_null0 | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hop_null0_variable | default("not_defined") }}
    ...    msg=ipv6_static_routes.next_hop_null0

    ${dia_val}=    Json Search List    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].vpn.vipValue

    # Custom handling to check if DIA is enabled or not
{% if ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | default("not_defined") | lower() == "true" %}
    IF    ${dia_val} == []
        ${r_value}=    Set Variable    not_defined
    ELSE
        ${r_value}=    Set Variable If    "${dia_val[0]}" == "0"    true
    END
    Should Be Equal As Strings    ${r_value}    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | lower() }}    msg=ipv6_static_routes.next_hop_dia
{% elif ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | default("not_defined") | lower() == "false" %}
    IF    ${dia_val} == []
        ${r_value}=    Set Variable    false
    ELSE
        ${r_value}=    Set Variable    ${dia_val[0]}
    END
    Should Be Equal As Strings    ${r_value}    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | lower() }}    msg=ipv6_static_routes.next_hop_dia
{% elif ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | default("not_defined") == "not_defined" %}
    Should Be Equal Value Json String    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].vpn.vipValue    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hop_dia | default("not_defined") }}    msg=ipv6_static_routes.next_hop_dia
{% endif %}
    # End of custom handling

    Should Be Equal Value Json String    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].vipOptional    {{ ft_yaml.ipv6_static_routes[v6_route_index].optional | default("not_defined") }}    msg=ipv6_static_routes.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}].prefix
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].prefix | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].prefix_variable | default("not_defined") }}
    ...    msg=ipv6_static_routes.prefix

    Should Be Equal Value Json List Length    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}]."next-hop".vipValue    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hops | default([]) | length }}    msg=ipv6_static_routes.next_hops.length

{% for v6_hop_index in range(ft_yaml.ipv6_static_routes[v6_route_index].next_hops | default([]) | length()) %}

    Log    === IPv6 Static Route {{v6_route_index}} Next Hop {{v6_hop_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}]."next-hop".vipValue[{{ v6_hop_index }}].address
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hops[v6_hop_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hops[v6_hop_index].address_variable | default("not_defined") }}
    ...    msg=ipv6_static_routes.next_hops.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.route.vipValue[{{ v6_route_index }}]."next-hop".vipValue[{{ v6_hop_index }}].distance
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hops[v6_hop_index].distance | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_static_routes[v6_route_index].next_hops[v6_hop_index].distance_variable | default("not_defined") }}
    ...    msg=ipv6_static_routes.next_hops.distance

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    nat.natpool.vipValue    {{ ft_yaml.nat_pools | default([]) | length }}    msg=nat_pools.length

{% for nat_pool in ft_yaml.nat_pools | default([]) %}

    Log    === NAT Pool {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}].direction
    ...    {{ nat_pool.direction | default("not_defined") }}
    ...    {{ nat_pool.direction_variable | default("not_defined") }}
    ...    msg=nat_pools.direction

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}].name
    ...    {{ nat_pool.id | default("not_defined") }}
    ...    {{ nat_pool.id_variable | default("not_defined") }}
    ...    msg=nat_pools.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}].overload
    ...    {{ nat_pool.overload | default("not_defined") | lower }}
    ...    {{ nat_pool.overload_variable | default("not_defined") }}
    ...    msg=nat_pools.overload

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}]."prefix-length"
    ...    {{ nat_pool.prefix_length | default("not_defined") }}
    ...    {{ nat_pool.prefix_length_variable | default("not_defined") }}
    ...    msg=nat_pools.prefix_length

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}]."range-start"
    ...    {{ nat_pool.range_start | default("not_defined") }}
    ...    {{ nat_pool.range_start_variable | default("not_defined") }}
    ...    msg=nat_pools.range_start

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}]."range-end"
    ...    {{ nat_pool.range_end | default("not_defined") }}
    ...    {{ nat_pool.range_end_variable | default("not_defined") }}
    ...    msg=nat_pools.range_end

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.natpool.vipValue[{{ loop.index0 }}]."tracker-id"
    ...    {{ nat_pool.tracker_id | default("not_defined") }}
    ...    {{ nat_pool.tracker_id_variable | default("not_defined") }}
    ...    msg=nat_pools.tracker_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    nat64.v4.pool.vipValue    {{ ft_yaml.nat64_pools | default([]) | length }}    msg=nat64_pools.length

{% for nat64_pool in ft_yaml.nat64_pools | default([]) %}

    Log    === NAT64 Pool {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat64.v4.pool.vipValue[{{ loop.index0 }}].name
    ...    {{ nat64_pool.name | default("not_defined") }}
    ...    {{ nat64_pool.name_variable | default("not_defined") }}
    ...    msg=nat64_pools.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat64.v4.pool.vipValue[{{ loop.index0 }}].overload
    ...    {{ nat64_pool.overload | default("not_defined") | lower }}
    ...    {{ nat64_pool.overload_variable | default("not_defined") }}
    ...    msg=nat64_pools.overload

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat64.v4.pool.vipValue[{{ loop.index0 }}]."start-address"
    ...    {{ nat64_pool.range_start | default("not_defined") }}
    ...    {{ nat64_pool.range_start_variable | default("not_defined") }}
    ...    msg=nat64_pools.range_start

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat64.v4.pool.vipValue[{{ loop.index0 }}]."end-address"
    ...    {{ nat64_pool.range_end | default("not_defined") }}
    ...    {{ nat64_pool.range_end_variable | default("not_defined") }}
    ...    msg=nat64_pools.range_end

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    omp.advertise.vipValue    {{ ft_yaml.omp_advertise_ipv4_routes | default([]) | length }}    msg=omp_advertise_ipv4_routes.length

{% for v4_omp_index in range(ft_yaml.omp_advertise_ipv4_routes | default([]) | length()) %}

    Log    === IPv4 OMP Advertise Route {{v4_omp_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}].protocol
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].protocol_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv4_routes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}]."route-policy"
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].route_policy_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv4_routes.route_policy

    Should Be Equal Value Json List Length    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}]."prefix-list".vipValue    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks | default([]) | length }}    msg=omp_advertise_ipv4_routes.networks.length

{% for v4_omp_net_index in range(ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks | default([]) | length()) %}

    Log    === IPv4 OMP Advertise Route {{v4_omp_index}} Network {{v4_omp_net_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}]."prefix-list".vipValue[{{ v4_omp_net_index }}]."aggregate-only"
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks[v4_omp_net_index].aggregate_only | default("not_defined") | lower }}
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks[v4_omp_net_index].aggregate_only_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv4_routes.networks.aggregate_only

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}]."prefix-list".vipValue[{{ v4_omp_net_index }}]."prefix-entry"
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks[v4_omp_net_index].prefix | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks[v4_omp_net_index].prefix_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv4_routes.networks.prefix

    Should Be Equal Value Json String    ${ft.json()}    omp.advertise.vipValue[{{ v4_omp_index }}]."prefix-list".vipValue[{{ v4_omp_net_index }}].vipOptional    {{ ft_yaml.omp_advertise_ipv4_routes[v4_omp_index].networks[v4_omp_net_index].optional | default("not_defined") }}    msg=omp_advertise_ipv4_routes.networks.optional

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    omp."ipv6-advertise".vipValue    {{ ft_yaml.omp_advertise_ipv6_routes | default([]) | length }}    msg=omp_advertise_ipv6_routes.length

{% for v6_omp_index in range(ft_yaml.omp_advertise_ipv6_routes | default([]) | length()) %}

    Log    === IPv6 OMP Advertise Route {{v6_omp_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}].protocol
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].protocol_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv6_routes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}]."route-policy"
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].route_policy_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv6_routes.route_policy

    Should Be Equal Value Json List Length    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}]."prefix-list".vipValue    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks | default([]) | length }}    msg=omp_advertise_ipv6_routes.networks.length

{% for v6_omp_net_index in range(ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks | default([]) | length()) %}

    Log    === IPv6 OMP Advertise Route {{v6_omp_index}} Network {{v6_omp_net_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}]."prefix-list".vipValue[{{ v6_omp_net_index }}]."aggregate-only"
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks[v6_omp_net_index].aggregate_only | default("not_defined") | lower }}
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks[v6_omp_net_index].aggregate_only_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv6_routes.networks.aggregate_only

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}]."prefix-list".vipValue[{{ v6_omp_net_index }}]."prefix-entry"
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks[v6_omp_net_index].prefix | default("not_defined") }}
    ...    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks[v6_omp_net_index].prefix_variable | default("not_defined") }}
    ...    msg=omp_advertise_ipv6_routes.networks.prefix

    Should Be Equal Value Json String    ${ft.json()}    omp."ipv6-advertise".vipValue[{{ v6_omp_index }}]."prefix-list".vipValue[{{ v6_omp_net_index }}].vipOptional    {{ ft_yaml.omp_advertise_ipv6_routes[v6_omp_index].networks[v6_omp_net_index].optional | default("not_defined") }}    msg=omp_advertise_ipv6_routes.networks.optional

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    nat."port-forward".vipValue    {{ ft_yaml.port_forwarding_rules | default([]) | length }}    msg=port_forwarding_rules.length

{% for port_fw in ft_yaml.port_forwarding_rules | default([]) %}

    Log    === NAT Port Forwarding Rule {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."pool-name"
    ...    {{ port_fw.nat_pool_id | default("not_defined") }}
    ...    {{ port_fw.nat_pool_id_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.nat_pool_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}].proto
    ...    {{ port_fw.protocol | default("not_defined") }}
    ...    {{ port_fw.protocol_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."source-ip"
    ...    {{ port_fw.source_ip | default("not_defined") }}
    ...    {{ port_fw.source_ip_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."source-port"
    ...    {{ port_fw.source_port | default("not_defined") }}
    ...    {{ port_fw.source_port_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.source_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."translate-ip"
    ...    {{ port_fw.translate_ip | default("not_defined") }}
    ...    {{ port_fw.translate_ip_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.translate_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."port-forward".vipValue[{{ loop.index0 }}]."translate-port"
    ...    {{ port_fw.translate_port | default("not_defined") }}
    ...    {{ port_fw.translate_port_variable | default("not_defined") }}
    ...    msg=port_forwarding_rules.translate_port

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "route-export".vipValue    {{ ft_yaml.route_global_exports | default([]) | length }}    msg=route_global_exports.length

{% for rt_gl_exp_index in range(ft_yaml.route_global_exports | default([]) | length()) %}

    Log    === Route Global Export {{rt_gl_exp_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-export".vipValue[{{ rt_gl_exp_index }}].protocol
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].protocol_variable | default("not_defined") }}
    ...    msg=route_global_exports.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-export".vipValue[{{ rt_gl_exp_index }}]."route-policy"
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_global_exports.route_policy

    Should Be Equal Value Json List Length    ${ft.json()}    "route-export".vipValue[{{ rt_gl_exp_index }}].redistribute.vipValue    {{ ft_yaml.route_global_exports[rt_gl_exp_index].redistributes | default([]) | length }}    msg=route_global_exports.redistributes.length

{% for rt_gl_exp_red_index in range(ft_yaml.route_global_exports[rt_gl_exp_index].redistributes | default([]) | length()) %}

    Log    === Route Global Export {{rt_gl_exp_index}} Redistribute {{rt_gl_exp_red_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-export".vipValue[{{ rt_gl_exp_index }}].redistribute.vipValue[{{ rt_gl_exp_red_index }}].protocol
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].redistributes[rt_gl_exp_red_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].redistributes[rt_gl_exp_red_index].protocol_variable | default("not_defined") }}
    ...    msg=route_global_exports.redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-export".vipValue[{{ rt_gl_exp_index }}].redistribute.vipValue[{{ rt_gl_exp_red_index }}]."route-policy"
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].redistributes[rt_gl_exp_red_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_global_exports[rt_gl_exp_index].redistributes[rt_gl_exp_red_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_global_exports.redistributes.route_policy

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "route-import".vipValue    {{ ft_yaml.route_global_imports | default([]) | length }}    msg=route_global_imports.length

{% for rt_gl_imp_index in range(ft_yaml.route_global_imports | default([]) | length()) %}

    Log    === Route Global Import {{rt_gl_imp_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import".vipValue[{{ rt_gl_imp_index }}].protocol
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].protocol_variable | default("not_defined") }}
    ...    msg=route_global_imports.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import".vipValue[{{ rt_gl_imp_index }}]."route-policy"
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_global_imports.route_policy

    Should Be Equal Value Json List Length    ${ft.json()}    "route-import".vipValue[{{ rt_gl_imp_index }}].redistribute.vipValue    {{ ft_yaml.route_global_imports[rt_gl_imp_index].redistributes | default([]) | length }}    msg=route_global_imports.redistributes.length

{% for rt_gl_imp_red_index in range(ft_yaml.route_global_imports[rt_gl_imp_index].redistributes | default([]) | length()) %}

    Log    === Route Global Import {{rt_gl_imp_index}} Redistribute {{rt_gl_imp_red_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import".vipValue[{{ rt_gl_imp_index }}].redistribute.vipValue[{{ rt_gl_imp_red_index }}].protocol
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].redistributes[rt_gl_imp_red_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].redistributes[rt_gl_imp_red_index].protocol_variable | default("not_defined") }}
    ...    msg=route_global_imports.redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import".vipValue[{{ rt_gl_imp_index }}].redistribute.vipValue[{{ rt_gl_imp_red_index }}]."route-policy"
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].redistributes[rt_gl_imp_red_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_global_imports[rt_gl_imp_index].redistributes[rt_gl_imp_red_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_global_imports.redistributes.route_policy

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "route-import-from".vipValue    {{ ft_yaml.route_vpn_imports | default([]) | length }}    msg=route_vpn_imports.length

{% for rt_vpn_imp_index in range(ft_yaml.route_vpn_imports | default([]) | length()) %}

    Log    === Route VPN Import {{rt_vpn_imp_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}].protocol
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].protocol_variable | default("not_defined") }}
    ...    msg=route_vpn_imports.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}]."route-policy"
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_vpn_imports.route_policy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}]."source-vpn"
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].source_vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].source_vpn_id_variable | default("not_defined") }}
    ...    msg=route_vpn_imports.source_vpn_id

    Should Be Equal Value Json List Length    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}].redistribute.vipValue    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes | default([]) | length }}    msg=route_vpn_imports.redistributes.length

{% for rt_vpn_imp_red_index in range(ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes | default([]) | length()) %}

    Log    === Route VPN Import {{rt_vpn_imp_index}} Redistribute {{rt_vpn_imp_red_index}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}].redistribute.vipValue[{{ rt_vpn_imp_red_index }}].protocol
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes[rt_vpn_imp_red_index].protocol | default("not_defined") }}
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes[rt_vpn_imp_red_index].protocol_variable | default("not_defined") }}
    ...    msg=route_vpn_imports.redistributes.protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "route-import-from".vipValue[{{ rt_vpn_imp_index }}].redistribute.vipValue[{{ rt_vpn_imp_red_index }}]."route-policy"
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes[rt_vpn_imp_red_index].route_policy | default("not_defined") }}
    ...    {{ ft_yaml.route_vpn_imports[rt_vpn_imp_index].redistributes[rt_vpn_imp_red_index].route_policy_variable | default("not_defined") }}
    ...    msg=route_vpn_imports.redistributes.route_policy

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    service.vipValue    {{ ft_yaml.services | default([]) | length }}    msg=services.length

{% for service in ft_yaml.services | default([]) %}

    Log    === Service {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[{{ loop.index0 }}].address
    ...    {{ service.addresses | default("not_defined") }}
    ...    {{ service.addresses_variable | default("not_defined") }}
    ...    msg=services.addresses_variable

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[{{ loop.index0 }}]."svc-type"
    ...    {{ service.service_type | default("not_defined") }}
    ...    {{ service.service_type_variable | default("not_defined") }}
    ...    msg=services.service_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[{{ loop.index0 }}]."track-enable"
    ...    {{ service.track_enable | default("not_defined") | lower }}
    ...    {{ service.track_enable_variable | default("not_defined") }}
    ...    msg=services.track_enable

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    nat.static.vipValue    {{ ft_yaml.static_nat_rules | default([]) | length }}    msg=static_nat_rules.length

{% for st_nat_rule in ft_yaml.static_nat_rules | default([]) %}

    Log    === Static NAT Rule {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."static-nat-direction"
    ...    {{ st_nat_rule.direction | default("not_defined") }}
    ...    {{ st_nat_rule.direction_variable | default("not_defined") }}
    ...    msg=static_nat_rules.direction

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."pool-name"
    ...    {{ st_nat_rule.nat_pool_id | default("not_defined") }}
    ...    {{ st_nat_rule.nat_pool_id_variable | default("not_defined") }}
    ...    msg=static_nat_rules.nat_pool_id

    Should Be Equal Value Json String    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}].vipOptional    {{ st_nat_rule.optional | default("not_defined") }}    msg=static_nat_rules.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."source-ip"
    ...    {{ st_nat_rule.source_ip | default("not_defined") }}
    ...    {{ st_nat_rule.source_ip_variable | default("not_defined") }}
    ...    msg=static_nat_rules.source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."tracker-id"
    ...    {{ st_nat_rule.tracker_id | default("not_defined") }}
    ...    {{ st_nat_rule.tracker_id_variable | default("not_defined") }}
    ...    msg=static_nat_rules.tracker_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat.static.vipValue[{{ loop.index0 }}]."translate-ip"
    ...    {{ st_nat_rule.translate_ip | default("not_defined") }}
    ...    {{ st_nat_rule.translate_ip_variable | default("not_defined") }}
    ...    msg=static_nat_rules.translate_ip

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    nat."subnet-static".vipValue    {{ ft_yaml.static_nat_subnet_rules | default([]) | length }}    msg=static_nat_subnet_rules.length

{% for st_nat_sub_rule in ft_yaml.static_nat_subnet_rules | default([]) %}

    Log    === Static NAT Subnet Rule {{loop.index0}} ===

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}]."static-nat-direction"
    ...    {{ st_nat_sub_rule.direction | default("not_defined") }}
    ...    {{ st_nat_sub_rule.direction_variable | default("not_defined") }}
    ...    msg=static_nat_subnet_rules.direction

    Should Be Equal Value Json String    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}].vipOptional    {{ st_nat_sub_rule.optional | default("not_defined") }}    msg=static_nat_subnet_rules.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}]."prefix-length"
    ...    {{ st_nat_sub_rule.prefix_length | default("not_defined") }}
    ...    {{ st_nat_sub_rule.prefix_length_variable | default("not_defined") }}
    ...    msg=static_nat_subnet_rules.prefix_length

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}]."source-ip-subnet"
    ...    {{ st_nat_sub_rule.source_ip_subnet | default("not_defined") }}
    ...    {{ st_nat_sub_rule.source_ip_subnet_variable | default("not_defined") }}
    ...    msg=static_nat_subnet_rules.source_ip_subnet

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}]."tracker-id"
    ...    {{ st_nat_sub_rule.tracker_id | default("not_defined") }}
    ...    {{ st_nat_sub_rule.tracker_id_variable | default("not_defined") }}
    ...    msg=static_nat_subnet_rules.tracker_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    nat."subnet-static".vipValue[{{ loop.index0 }}]."translate-ip-subnet"
    ...    {{ st_nat_sub_rule.translate_ip_subnet | default("not_defined") }}
    ...    {{ st_nat_sub_rule.translate_ip_subnet_variable | default("not_defined") }}
    ...    msg=static_nat_subnet_rules.translate_ip_subnet

{% endfor %}

{% endfor %}

{% endif %}
