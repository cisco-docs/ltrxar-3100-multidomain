*** Settings ***
Documentation   Verify SVI Interface Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.svi_interface_templates is defined %}

*** Test Cases ***
Get SVI Interface Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='vpn-interface-svi']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.svi_interface_templates | default([]) %}

Verify Edge Feature Template SVI Interface Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.svi_interface_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "arp-timeout"
    ...    {{ ft_yaml.arp_timeout | default("not_defined") }}
    ...    {{ ft_yaml.arp_timeout_variable | default("not_defined") }}
    ...    msg=arp_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    description
    ...    {{ ft_yaml.interface_description | default("not_defined") }}
    ...    {{ ft_yaml.interface_description_variable | default("not_defined") }}
    ...    msg=interface_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "if-name"
    ...    {{ ft_yaml.interface_name | default("not_defined") }}
    ...    {{ ft_yaml.interface_name_variable | default("not_defined") }}
    ...    msg=interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ip-directed-broadcast"
    ...    {{ ft_yaml.ip_directed_broadcast | default("not_defined") | lower }}
    ...    {{ ft_yaml.ip_directed_broadcast_variable | default("not_defined") }}
    ...    msg=ip_directed_broadcast

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    mtu
    ...    {{ ft_yaml.ip_mtu | default("not_defined") }}
    ...    {{ ft_yaml.ip_mtu_variable | default("not_defined") }}
    ...    msg=ip_mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.address
    ...    {{ ft_yaml.ipv4_address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_address_variable | default("not_defined") }}
    ...    msg=ipv4_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dhcp-helper"
    ...    {{ ft_yaml.ipv4_dhcp_helpers | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_dhcp_helpers_variable | default("not_defined") }}
    ...    msg=ipv4_dhcp_helpers_variable

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv4_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv4_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6.address
    ...    {{ ft_yaml.ipv6_address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_address_variable | default("not_defined") }}
    ...    msg=ipv6_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='out'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_egress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_egress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_egress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."access-list".vipValue[?direction.vipValue=='in'] | [0]."acl-name"
    ...    {{ ft_yaml.ipv6_ingress_access_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_ingress_access_list_variable | default("not_defined") }}
    ...    msg=ipv6_ingress_access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "intrf-mtu"
    ...    {{ ft_yaml.mtu | default("not_defined") }}
    ...    {{ ft_yaml.mtu_variable | default("not_defined") }}
    ...    msg=mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") | lower }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tcp-mss-adjust"
    ...    {{ ft_yaml.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tcp_mss_variable | default("not_defined") }}
    ...    msg=tcp_mss

    Should Be Equal Value Json List Length    ${ft.json()}    ip."secondary-address".vipValue    {{ ft_yaml.ipv4_secondary_addresses | default([]) | length }}    msg=ipv4 secondary addresses length

{% for ipv4 in ft_yaml.ipv4_secondary_addresses | default([]) %}

    Log    === IPv4 Secondary Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip."secondary-address".vipValue[{{loop.index0}}].address
    ...    {{ ipv4.address | default("not_defined") }}
    ...    {{ ipv4.address_variable | default("not_defined") }}
    ...    msg=ipv4_secondary_addresses.address

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    vrrp.vipValue    {{ ft_yaml.ipv4_vrrp_groups | default([]) | length }}    msg=ipv4 vrrp groups length

{% for vrrp_index in range(ft_yaml.ipv4_vrrp_groups | default([]) | length()) %}

    Log    === IPv4 VRRP Group {{vrrp_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}].ipv4.address
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."grp-id"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].id | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].id_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.id

    Should Be Equal Value Json String    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}].vipOptional    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].optional | default("not_defined") }}    msg=ipv4_vrrp_groups.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}].priority
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].priority | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].priority_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.priority

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}].timer
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].timer | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].timer_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.timer

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."tloc-change-pref"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tloc_preference_change | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tloc_preference_change_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tloc_preference_change

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}].value
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tloc_preference_change_value | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tloc_preference_change_value_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tloc_preference_change_value

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."track-prefix-list"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].track_prefix_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].track_prefix_list_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.track_prefix_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."track-omp"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].track_omp | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].track_omp_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.track_omp

    Should Be Equal Value Json List Length    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."ipv4-secondary".vipValue    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].secondary_addresses | length }}    msg=ipv4 vrrp group secondary addresses length

{% for sec_add_index in range(ft_yaml.ipv4_vrrp_groups[vrrp_index].secondary_addresses | default([]) | length()) %}

    Log    === IPv4 VRRP Group {{vrrp_index}} Secondary Address {{sec_add_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."ipv4-secondary".vipValue[{{ sec_add_index }}].address
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].secondary_addresses[sec_add_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].secondary_addresses[sec_add_index].address_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.secondary_addresses.address

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."tracking-object".vipValue    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects | length }}    msg=tracking objects length

{% for track_obj_index in range(ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects | default([]) | length()) %}

    Log    === IPv4 VRRP Group {{vrrp_index}} Tracking Object {{track_obj_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."tracking-object".vipValue[{{ track_obj_index }}]."track-action"
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].action | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].action_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.action

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."tracking-object".vipValue[{{ track_obj_index }}].decrement
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].decrement_value | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].decrement_value_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.decrement_value

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    vrrp.vipValue[{{ vrrp_index }}]."tracking-object".vipValue[{{ track_obj_index }}].name
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].id | default("not_defined") }}
    ...    {{ ft_yaml.ipv4_vrrp_groups[vrrp_index].tracking_objects[track_obj_index].id_variable | default("not_defined") }}
    ...    msg=ipv4_vrrp_groups.tracking_objects.id

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue    {{ ft_yaml.ipv6_dhcp_helpers | default([]) | length }}    msg=ipv6 dhcp helpers length

{% for ipv6_dhcp_helper in ft_yaml.ipv6_dhcp_helpers | default([]) %}

    Log    === IPv6 DHCP Helper {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue[{{loop.index0}}].address
    ...    {{ ipv6_dhcp_helper.address | default("not_defined") }}
    ...    {{ ipv6_dhcp_helper.address_variable | default("not_defined") }}
    ...    msg=ipv6_dhcp_helpers.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."dhcp-helper-v6".vipValue[{{loop.index0}}].vpn
    ...    {{ ipv6_dhcp_helper.vpn_id | default("not_defined") }}
    ...    {{ ipv6_dhcp_helper.vpn_id_variable | default("not_defined") }}
    ...    msg=ipv6_dhcp_helpers.vpn_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    ipv6."secondary-address".vipValue    {{ ft_yaml.ipv6_secondary_addresses | default([]) | length }}    msg=ipv6 secondary addresses length

{% for ipv6 in ft_yaml.ipv6_secondary_addresses | default([]) %}

    Log    === IPv6 Secondary Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipv6."secondary-address".vipValue[{{loop.index0}}].address
    ...    {{ ipv6.address | default("not_defined") }}
    ...    {{ ipv6.address_variable | default("not_defined") }}
    ...    msg=ipv6_secondary_addresses.address

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "ipv6-vrrp".vipValue    {{ ft_yaml.ipv6_vrrp_groups | default([]) | length }}    msg=ipv6 vrrp groups length

{% for ipv6_vrrp_index in range(ft_yaml.ipv6_vrrp_groups | default([]) | length()) %}

    Log    === IPv6 VRRP Group {{ipv6_vrrp_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}]."grp-id"
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].id | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].id_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}].ipv6.vipValue[0].prefix
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].global_prefix | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].global_prefix_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.global_prefix

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}].ipv6.vipValue[0]."ipv6-link-local"
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].link_local_address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].link_local_address_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.link_local_address

    Should Be Equal Value Json String    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}].vipOptional    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].optional | default("not_defined") }}    msg=ipv6_vrrp_groups.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}].priority
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].priority | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].priority_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.priority

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}].timer
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].timer | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].timer_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.timer

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}]."track-prefix-list"
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].track_prefix_list | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].track_prefix_list_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.track_prefix_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}]."track-omp"
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].track_omp | default("not_defined") | lower }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].track_omp_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.track_omp

    Should Be Equal Value Json List Length    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}]."ipv6-secondary".vipValue    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].secondary_addresses | length }}    msg=ipv6 vrrp group secondary addresses length

{% for ipv6_sec_add_index in range(ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].secondary_addresses | default([]) | length()) %}

    Log    === IPv6 VRRP Group {{ipv6_vrrp_index}} Secondary Address {{ipv6_sec_add_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "ipv6-vrrp".vipValue[{{ ipv6_vrrp_index }}]."ipv6-secondary".vipValue[{{ ipv6_sec_add_index }}].prefix
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].secondary_addresses[ipv6_sec_add_index].address | default("not_defined") }}
    ...    {{ ft_yaml.ipv6_vrrp_groups[ipv6_vrrp_index].secondary_addresses[ipv6_sec_add_index].address_variable | default("not_defined") }}
    ...    msg=ipv6_vrrp_groups.secondary_addresses.address

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    arp.ip.vipValue    {{ ft_yaml.static_arps | default([]) | length }}    msg=static arps length

{% for arp in ft_yaml.static_arps | default([]) %}

    Log    === Static ARP {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{loop.index0}}].addr
    ...    {{ arp.ip_address | default("not_defined") }}
    ...    {{ arp.ip_address_variable | default("not_defined") }}
    ...    msg=static_arps.ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    arp.ip.vipValue[{{loop.index0}}].mac
    ...    {{ arp.mac_address | default("not_defined") }}
    ...    {{ arp.mac_address_variable | default("not_defined") }}
    ...    msg=static_arps.mac_address

    Should Be Equal Value Json String    ${ft.json()}    arp.ip.vipValue[{{loop.index0}}].vipOptional    {{ arp.optional | default("not_defined") }}    msg=static_arps.optional

{% endfor %}

{% endfor %}

{% endif %}
