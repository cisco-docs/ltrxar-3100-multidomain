import re
import jmespath


class Rule:
    id = "401"
    description = "Verify Configuration Groups"
    severity = "HIGH"

    # Flattened path to variable that (if configured) is required to be filled during config group deployment

    # Note: Below list is the list of required variables in all supported versions of the SDWAN manager.
    generic_required_variables_paths = [
        "sdwan.feature_profiles.other_profiles.thousandeyes.account_group_token_variable",
        "sdwan.feature_profiles.other_profiles.ucse.cimc_default_gateway_variable",
        "sdwan.feature_profiles.other_profiles.ucse.cimc_ipv4_address_variable",
        "sdwan.feature_profiles.other_profiles.ucse.interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.as_number_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_number_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_restart_interval_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_threshold_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_number_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_restart_interval_variable",
        "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_threshold_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.options.ascii_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.options.code_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.options.hex_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.options.ip_addresses_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.pool_network_address_variable",
        "sdwan.feature_profiles.service_profiles.dhcp_servers.pool_subnet_mask_variable",
        "sdwan.feature_profiles.service_profiles.eigrp_features.autonomous_system_id_variable",
        "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.actions.service_chain_name_variable",
        "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.match_entries.destination_data_prefix_variable",
        "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.match_entries.source_data_prefix_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ip_directed_broadcast_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv6_vrrp_groups.id_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.shutdown_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_destination_ipv4_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_destination_ipv6_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_source_interface_loopback_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_source_interface_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_source_ipv4_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.gre_interfaces.tunnel_source_ipv6_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_interfaces.ike_preshared_key_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_export_route_targets.route_target_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_import_route_targets.route_target_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_omp_advertise_routes.aggregates.aggregate_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_omp_advertise_routes.aggregates.subnet_mask_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_omp_advertise_routes.networks.network_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_omp_advertise_routes.networks.subnet_mask_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_omp_advertise_routes.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_export_route_targets.route_target_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_import_route_targets.route_target_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_omp_advertise_routes.aggregates.aggregate_prefix_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_omp_advertise_routes.networks.prefix_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_omp_advertise_routes.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.nat64_pools.name_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.nat64_pools.overload_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.nat64_pools.range_end_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.nat64_pools.range_start_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_from_global.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_from_global.redistributions.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_from_service.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_from_service.redistributions.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_from_service.source_vpn_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_to_global.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.route_leaks_to_global.redistributions.protocol_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.service_routes.network_address_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.service_routes.subnet_mask_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.services.ipv4_addresses_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.services.service_type_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.services.track_enable_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.svi_interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.vpn_id_variable",
        "sdwan.feature_profiles.service_profiles.lan_vpns.vpn_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.auto_rp_announces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.auto_rp_announces.scope_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.auto_rp_discoveries.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.auto_rp_discoveries.scope_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.igmp_interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.igmp_interfaces.join_groups.group_address_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.msdp_mesh_groups.peers.peer_ip_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.pim_bsr_candidates.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.pim_bsr_rp_candidates.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.pim_interfaces.interface_name_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.static_rp_addresses.access_list_variable",
        "sdwan.feature_profiles.service_profiles.multicast_features.static_rp_addresses.ip_address_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.interfaces.authentication_ipsec_key_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.interfaces.authentication_ipsec_spi_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.ranges.network_address_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.ranges.subnet_mask_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.interfaces.authentication_ipsec_key_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.interfaces.authentication_ipsec_spi_variable",
        "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.interfaces.name_variable",
        "sdwan.feature_profiles.service_profiles.switchport_features.static_mac_addresses.mac_address_variable",
        "sdwan.feature_profiles.service_profiles.switchport_features.static_mac_addresses.vlan_id_variable",
        "sdwan.feature_profiles.system_profiles.aaa.users.name_variable",
        "sdwan.feature_profiles.system_profiles.aaa.users.password_variable",
        "sdwan.feature_profiles.system_profiles.aaa.users.public_key_chains.key_variable",
        "sdwan.feature_profiles.system_profiles.banner.login_variable",
        "sdwan.feature_profiles.system_profiles.banner.motd_variable",
        "sdwan.feature_profiles.system_profiles.basic.admin_tech_on_failure_variable",
        "sdwan.feature_profiles.system_profiles.basic.device_groups_variable",
        "sdwan.feature_profiles.system_profiles.basic.latitude_variable",
        "sdwan.feature_profiles.system_profiles.basic.location_variable",
        "sdwan.feature_profiles.system_profiles.basic.longitude_variable",
        "sdwan.feature_profiles.system_profiles.basic.max_omp_sessions_variable",
        "sdwan.feature_profiles.system_profiles.basic.on_demand_tunnel_variable",
        "sdwan.feature_profiles.system_profiles.basic.port_hopping_variable",
        "sdwan.feature_profiles.system_profiles.basic.system_description_variable",
        "sdwan.feature_profiles.system_profiles.basic.timezone_variable",
        "sdwan.feature_profiles.system_profiles.basic.tracker_dia_stabilize_status_variable",
        "sdwan.feature_profiles.system_profiles.bfd.colors.color_variable",
        "sdwan.feature_profiles.system_profiles.bfd.colors.path_mtu_discovery_variable",
        "sdwan.feature_profiles.system_profiles.global.arp_proxy_variable",
        "sdwan.feature_profiles.system_profiles.global.cdp_variable",
        "sdwan.feature_profiles.system_profiles.global.domain_lookup_variable",
        "sdwan.feature_profiles.system_profiles.global.ftp_passive_variable",
        "sdwan.feature_profiles.system_profiles.global.http_server_variable",
        "sdwan.feature_profiles.system_profiles.global.https_server_variable",
        "sdwan.feature_profiles.system_profiles.global.lldp_variable",
        "sdwan.feature_profiles.system_profiles.global.rsh_rcp_variable",
        "sdwan.feature_profiles.system_profiles.global.telnet_outbound_variable",
        "sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.sequences.match_entries.destination_data_prefixes_variable",
        "sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.sequences.match_entries.source_data_prefixes_variable",
        "sdwan.feature_profiles.system_profiles.logging.disk_file_rotate_variable",
        "sdwan.feature_profiles.system_profiles.logging.disk_file_size_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv4_servers.hostname_ip_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv4_servers.severity_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv4_servers.tls_enable_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv4_servers.vpn_id_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv6_servers.hostname_ip_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv6_servers.severity_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv6_servers.tls_enable_variable",
        "sdwan.feature_profiles.system_profiles.logging.ipv6_servers.vpn_id_variable",
        "sdwan.feature_profiles.system_profiles.logging.tls_profiles.name_variable",
        "sdwan.feature_profiles.system_profiles.ntp.authentication_keys.id_variable",
        "sdwan.feature_profiles.system_profiles.ntp.authentication_keys.md5_value_variable",
        "sdwan.feature_profiles.system_profiles.ntp.servers.hostname_ip_variable",
        "sdwan.feature_profiles.system_profiles.ntp.servers.ntp_version_variable",
        "sdwan.feature_profiles.system_profiles.ntp.servers.prefer_variable",
        "sdwan.feature_profiles.system_profiles.ntp.servers.vpn_id_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_bgp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_connected_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_eigrp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_isis_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_lisp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_ospf_v3_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_ospf_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv4_static_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_bgp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_connected_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_eigrp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_isis_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_lisp_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_ospf_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertise_ipv6_static_variable",
        "sdwan.feature_profiles.system_profiles.omp.advertisement_interval_variable",
        "sdwan.feature_profiles.system_profiles.omp.ecmp_limit_variable",
        "sdwan.feature_profiles.system_profiles.omp.eor_timer_variable",
        "sdwan.feature_profiles.system_profiles.omp.graceful_restart_timer_variable",
        "sdwan.feature_profiles.system_profiles.omp.graceful_restart_variable",
        "sdwan.feature_profiles.system_profiles.omp.holdtime_variable",
        "sdwan.feature_profiles.system_profiles.omp.omp_admin_distance_ipv4_variable",
        "sdwan.feature_profiles.system_profiles.omp.omp_admin_distance_ipv6_variable",
        "sdwan.feature_profiles.system_profiles.omp.overlay_as_variable",
        "sdwan.feature_profiles.system_profiles.omp.send_path_limit_variable",
        "sdwan.feature_profiles.system_profiles.omp.shutdown_variable",
        "sdwan.feature_profiles.system_profiles.security.keys.key_string_variable",
        "sdwan.feature_profiles.system_profiles.security.keys.receiver_id_variable",
        "sdwan.feature_profiles.system_profiles.security.keys.send_id_variable",
        "sdwan.feature_profiles.system_profiles.snmp.communities.name_variable",
        "sdwan.feature_profiles.system_profiles.snmp.communities.view_variable",
        "sdwan.feature_profiles.system_profiles.snmp.group.view_variable",
        "sdwan.feature_profiles.system_profiles.snmp.trap_target_servers.ip_variable",
        "sdwan.feature_profiles.system_profiles.snmp.trap_target_servers.port_variable",
        "sdwan.feature_profiles.system_profiles.snmp.trap_target_servers.vpn_id_variable",
        "sdwan.feature_profiles.system_profiles.snmp.user.group_variable",
        "sdwan.feature_profiles.system_profiles.snmp.views.oids.id_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.as_number_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_number_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_restart_interval_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.address_families.maximum_prefixes_threshold_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_number_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_restart_interval_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.address_families.maximum_prefixes_threshold_variable",
        "sdwan.feature_profiles.transport_profiles.bgp_features.mpls_interfaces.name_variable",
        "sdwan.feature_profiles.transport_profiles.cellular_controllers.cellular_id_variable",
        "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.actions.service_chain_name_variable",
        "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.match_entries.destination_data_prefix_variable",
        "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.match_entries.source_data_prefix_variable",
        "sdwan.feature_profiles.transport_profiles.ipv4_tracker_groups.tracker_name_variable",
        "sdwan.feature_profiles.transport_profiles.ipv4_trackers.tracker_name_variable",
        "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences.actions.service_chain_name_variable",
        "sdwan.feature_profiles.transport_profiles.ipv6_tracker_groups.tracker_name_variable",
        "sdwan.feature_profiles.transport_profiles.ipv6_trackers.tracker_name_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.arp_entries.ip_address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.arp_entries.mac_address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.arp_timeout_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.interface_name_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ip_directed_broadcast_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ip_mtu_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_dhcp_distance_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_secondary_addresses.address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_secondary_addresses.subnet_mask_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_subnet_mask_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv6_address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.load_interval_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.shutdown_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.host_mappings.hostname_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.host_mappings.ip_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_routes.network_address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_routes.next_hops.address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_routes.next_hops.administrative_distance_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv4_routes.subnet_mask_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv6_routes.next_hops.address_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv6_routes.next_hops.administrative_distance_variable",
        "sdwan.feature_profiles.transport_profiles.management_vpn.ipv6_routes.prefix_variable",
        "sdwan.feature_profiles.transport_profiles.ospf_features.areas.number_variable",
        "sdwan.feature_profiles.transport_profiles.ospf_features.redistributes.protocol_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.cellular_interfaces.interface_description_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.cellular_interfaces.interface_name_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.cellular_interfaces.ipv4_nat_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.cellular_interfaces.shutdown_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.enhance_ecmp_keying_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.arp_entries.ip_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.arp_entries.mac_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.interface_description_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.interface_name_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_dhcp_distance_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_pool_overload_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_pool_prefix_length_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_pool_range_end_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_pool_range_start_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_static_entries.source_ip_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_static_entries.source_vpn_id_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_static_entries.translate_ip_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_tcp_timeout_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_udp_timeout_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_secondary_addresses.address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_secondary_addresses.subnet_mask_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_subnet_mask_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_nat66_static_entries.source_prefix_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_nat66_static_entries.source_vpn_id_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_nat66_static_entries.translate_prefix_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_secondary_addresses.address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.shutdown_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.interface_name_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_destination_ipv4_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_destination_ipv6_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_source_interface_loopback_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_source_interface_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_source_ipv4_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.gre_interfaces.tunnel_source_ipv6_address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.host_mappings.hostname_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.host_mappings.ips_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ipsec_interfaces.ike_preshared_key_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ipsec_interfaces.interface_name_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ipv6_routes.next_hops.address_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ipv6_routes.next_hops.administrative_distance_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.ipv6_routes.prefix_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.nat_64_v4_pools.name_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.nat_64_v4_pools.overload_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.nat_64_v4_pools.range_end_variable",
        "sdwan.feature_profiles.transport_profiles.wan_vpn.nat_64_v4_pools.range_start_variable",
    ]

    # Note: Below list is the list of required variables only in specific versions of the SDWAN manager.
    version_specific_required_variables_paths = [
        {
            "version": "<20.18.0",
            "paths": [
                "sdwan.feature_profiles.other_profiles.thousandeyes.pac_proxy_url_variable",
                "sdwan.feature_profiles.other_profiles.thousandeyes.static_proxy_host_variable",
                "sdwan.feature_profiles.other_profiles.thousandeyes.static_proxy_port_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_aggregate_addresses.network_address_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_aggregate_addresses.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_neighbors.address_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_neighbors.remote_as_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_networks.network_address_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_networks.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv4_redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_aggregate_addresses.prefix_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_neighbors.address_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_neighbors.remote_as_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_networks.prefix_variable",
                "sdwan.feature_profiles.service_profiles.bgp_features.ipv6_redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.dhcp_servers.static_leases.ip_address_variable",
                "sdwan.feature_profiles.service_profiles.dhcp_servers.static_leases.mac_address_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.interfaces.name_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.interfaces.summary_addresses.network_address_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.interfaces.summary_addresses.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.networks.network_address_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.networks.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.eigrp_features.redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.ipv4_trackers.tracker_name_variable",
                "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences.actions.service_chain_name_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.arp_entries.ip_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.arp_entries.mac_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.arp_timeout_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.interface_name_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ip_mtu_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_secondary_addresses.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_secondary_addresses.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_vrrp_groups.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_vrrp_groups.id_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_vrrp_groups.secondary_addresses.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_vrrp_groups.secondary_addresses.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv6_dhcp_secondary_addresses.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv6_secondary_addresses.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv6_vrrp_groups.link_local_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.load_interval_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.gre_routes.interfaces_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.gre_routes.network_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.gre_routes.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.host_mappings.hostname_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.host_mappings.ips_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_routes.interfaces_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_routes.network_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipsec_routes.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.network_address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.next_hops.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.next_hops_with_tracker.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.static_route_interface.interface_name_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.static_route_interface.next_hops.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.static_route_interface.next_hops.administrative_distance_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv4_static_routes.subnet_mask_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.next_hops.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.prefix_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.static_route_interface.interface_name_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.static_route_interface.next_hops.address_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ipv6_static_routes.static_route_interface.next_hops.administrative_distance_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.direction_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.id_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.overload_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.prefix_length_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.range_end_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_pools.range_start_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.nat_pool_id_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.protocol_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.source_ip_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.source_port_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.translate_ip_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.nat_port_forwards.translate_port_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_entries.direction_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_entries.nat_pool_id_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_entries.source_ip_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_entries.translate_ip_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_subnets.direction_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_subnets.prefix_length_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_subnets.source_ip_subnet_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.static_nat_subnets.translated_source_ip_subnet_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.svi_interfaces.arp_timeout_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.svi_interfaces.ip_directed_broadcast_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.svi_interfaces.shutdown_variable",
                "sdwan.feature_profiles.service_profiles.multicast_features.local_replicator_variable",
                "sdwan.feature_profiles.service_profiles.multicast_features.pim_interfaces.join_prune_interval_variable",
                "sdwan.feature_profiles.service_profiles.multicast_features.pim_interfaces.query_interval_variable",
                "sdwan.feature_profiles.service_profiles.multicast_features.spt_only_variable",
                "sdwan.feature_profiles.service_profiles.ospf_features.areas.number_variable",
                "sdwan.feature_profiles.service_profiles.ospf_features.redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.interfaces.name_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.number_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.areas.ranges.no_advertise_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features.redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.number_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.ranges.no_advertise_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.areas.ranges.prefix_variable",
                "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features.redistributes.protocol_variable",
                "sdwan.feature_profiles.service_profiles.switchport_features.interfaces.name_variable",
                "sdwan.feature_profiles.service_profiles.switchport_features.static_mac_addresses.interface_name_variable",
                "sdwan.feature_profiles.system_profiles.aaa.authorization_config_commands_variable",
                "sdwan.feature_profiles.system_profiles.aaa.authorization_console_variable",
                "sdwan.feature_profiles.system_profiles.aaa.dot1x_accounting_variable",
                "sdwan.feature_profiles.system_profiles.aaa.dot1x_authentication_variable",
                "sdwan.feature_profiles.system_profiles.aaa.radius_groups.servers.key_variable",
                "sdwan.feature_profiles.system_profiles.aaa.tacacs_groups.servers.key_variable",
                "sdwan.feature_profiles.system_profiles.basic.affinity_per_vrfs.affinity_group_number_variable",
                "sdwan.feature_profiles.system_profiles.basic.affinity_per_vrfs.vrf_range_variable",
                "sdwan.feature_profiles.system_profiles.basic.console_baud_rate_variable",
                "sdwan.feature_profiles.system_profiles.basic.on_demand_tunnel_idle_timeout_variable",
                "sdwan.feature_profiles.system_profiles.basic.overlay_id_variable",
                "sdwan.feature_profiles.system_profiles.basic.port_offset_variable",
                "sdwan.feature_profiles.system_profiles.bfd.colors.default_dscp_variable",
                "sdwan.feature_profiles.system_profiles.bfd.colors.hello_interval_variable",
                "sdwan.feature_profiles.system_profiles.bfd.colors.multiplier_variable",
                "sdwan.feature_profiles.system_profiles.bfd.default_dscp_variable",
                "sdwan.feature_profiles.system_profiles.bfd.multiplier_variable",
                "sdwan.feature_profiles.system_profiles.bfd.poll_interval_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_aggregate_addresses.network_address_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_aggregate_addresses.subnet_mask_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.address_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_neighbors.remote_as_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_networks.network_address_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_networks.subnet_mask_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv4_redistributes.protocol_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_aggregate_addresses.prefix_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.address_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_neighbors.remote_as_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_networks.prefix_variable",
                "sdwan.feature_profiles.transport_profiles.bgp_features.ipv6_redistributes.protocol_variable",
                "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_nat_type_variable",
            ]
        },
        {
            "version": ">=20.18.0",
            "paths": [
                "sdwan.feature_profiles.other_profiles.thousandeyes.vpn_id_variable",
            ]
        }
    ]

    # List of features where variables are required only if feature is associated
    # feature_path is the path to the feature definition in the data model
    # associate_jmes_paths are the jmes path to where the feature might be associated when used
    associated_features = [
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.bgp_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].bgp"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.dhcp_servers",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.service_profiles[].lan_vpns[].ethernet_interfaces[].dhcp_server",
                "sdwan.feature_profiles.service_profiles[].lan_vpns[].ipsec_interfaces[].dhcp_server",
                "sdwan.feature_profiles.service_profiles[].lan_vpns[].svi_interfaces[].dhcp_server",
            ]
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.eigrp_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].eigrp"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ipv4_acls",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.service_profiles[].lan_vpns[].ethernet_interfaces[].ipv4_egress_acl",
                "sdwan.feature_profiles.service_profiles[].lan_vpns[].ethernet_interfaces[].ipv4_ingress_acl",
                ],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ipv4_trackers",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].ethernet_interfaces[].ipv4_tracker"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ipv4_tracker_groups",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].ethernet_interfaces[].ipv4_tracker_group"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.multicast_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].multicast"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ospf_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].ospf"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ospfv3_ipv4_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].ospfv3_ipv4"],
        },
        {
            "feature_path": "sdwan.feature_profiles.service_profiles.ospfv3_ipv6_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.service_profiles[].lan_vpns[].ospfv3_ipv6"],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ipv4_acls",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv4_egress_acl",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv4_ingress_acl",
            ],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.bgp_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.transport_profiles[].wan_vpn.bgp"],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ospf_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.transport_profiles[].wan_vpn.ospf"],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ospfv3_ipv4_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.transport_profiles[].wan_vpn.ospfv3_ipv4"],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ospfv3_ipv6_features",
            "associate_jmes_paths": ["sdwan.feature_profiles.transport_profiles[].wan_vpn.ospfv3_ipv6"],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ipv4_trackers",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.cellular_interfaces[].ipv4_tracker",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv4_tracker",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.gre_interfaces[].ipv4_tracker",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ipsec_interfaces[].ipv4_tracker",
            ],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ipv4_tracker_groups",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.cellular_interfaces[].ipv4_tracker_group",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv4_tracker_group",
            ],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ipv6_trackers",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.cellular_interfaces[].ipv6_tracker",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv6_tracker",
            ],
        },
        {
            "feature_path": "sdwan.feature_profiles.transport_profiles.ipv6_tracker_groups",
            "associate_jmes_paths": [
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.cellular_interfaces[].ipv6_tracker_group",
                "sdwan.feature_profiles.transport_profiles[].wan_vpn.ethernet_interfaces[].ipv6_tracker_group",
            ],
        },
    ]

    # Here is the minimum required set of configuration group feature profile parcels for a deployment.
    # Schema: '<profile_key_in_configuration_group>:<profile_key_in_feature_profiles>':'<list_of_required_parcel_names>'
    # Sample-1: 'system_profile:system_profiles':['aaa', 'basic']'
    # Sample-2: 'policy_object_profile:policy_object_profile':['application_lists']'
    req_profile_parcels_for_deploy = {
        'system_profile:system_profiles': [
            'aaa',
            'basic',
            'bfd',
            'global',
            'logging',
            'omp'
        ],
        'transport_profile:transport_profiles': [
            'wan_vpn'
        ]
    }

    @classmethod
    def get_configuration_group_variables(cls, inventory, configuration_group):
        # Get all variables from all profiles assigned to a configuration group
        # and return them as a list of dictionaries with flat_path, full_path and variable name
        # Example: [{'variable_name': 'vpn10_static_lease_mac1',
        # 'flat_path': 'sdwan.feature_profiles.service_profiles.dhcp_servers.static_leases.mac_address_variable',
        # 'full_path': 'sdwan.feature_profiles.service_profiles[service1].dhcp_servers[dhcp-server-vpn11].static_leases[0].mac_address_variable'}]
        variables = []
        for key, value in configuration_group.items():
            if key.endswith("_profile"):
                profile = next(
                    (
                        p
                        for p in inventory.get("sdwan", {})
                        .get("feature_profiles", {})
                        .get(f"{key}s", [])
                        if p.get("name") == value
                    ),
                    None,
                )
                if profile:

                    def iterate_nested_dict(d, flat_path="", full_path=""):
                        if isinstance(d, dict):
                            for k, v in d.items():
                                new_flat_path = f"{flat_path}.{k}".lstrip(".")
                                new_full_path = f"{full_path}.{k}".lstrip(".")
                                if k.endswith("_variable"):
                                    variables.append(
                                        {
                                            "variable_name": v,
                                            "flat_path": new_flat_path,
                                            "full_path": new_full_path,
                                        }
                                    )
                                iterate_nested_dict(v, new_flat_path, new_full_path)
                        elif isinstance(d, list):
                            for i, item in enumerate(d):
                                new_flat_path = flat_path
                                new_full_path = (
                                    f"{full_path}[{item['name']}]"
                                    if isinstance(item, dict) and "name" in item
                                    else f"{full_path}[{i}]"
                                )
                                iterate_nested_dict(item, new_flat_path, new_full_path)

                    iterate_nested_dict(
                        profile,
                        f"sdwan.feature_profiles.{key}s",
                        f"sdwan.feature_profiles.{key}s[{value}]",
                    )
        return variables

    @classmethod
    def get_required_variables(
        cls, inventory, configuration_group_variables, chassis_id, configuration_groups_tags, router_tags
    ):
        required_variables = configuration_group_variables or []
        # Filter variables for features that are not supported by this device model
        # e.g. if the device model is C8000V, variables for TE and UCSE should not be in required variables list
        if all(
            model not in chassis_id
            for model in [
                "ISR-4221X",
                "ISR-4321",
                "ISR-4331",
                "ISR-4351",
                "ISR-4431",
                "ISR-4451-X",
                "ISR-4461",
                "C8200-1N-4T",
                "C8200L-1N-4T",
                "C8300-1N1S-4T2X",
                "C8300-1N1S-6T",
                "C8300-2N2S-6T",
                "C8300-2N2S-4T2X",
                "C8330-1N1S-4M2X",
                "C8375-E-G2",
                "C8330-6TM4SX",
                "C8330-6TM4X",
                "C8351-G2",
                "C8330X-6TM4SX",
                "C8330X-6TM4X",
                "C8355-G2",
                "ISR1100X-6G-XE",
                "C8500-12X4QC",
                "C8530-12X4QC",
                "C8570-G2",
                "C8500-12X",
                "C8530-12X",
                "C8550-G2",
                "C8500L-8S4X",
                "C8530L-8S8X4Y",
                "C8475-G2",
                "C8530L-8S2X2Y",
                "C8455-G2",
                "ASR-1001-X",
                "ASR-1002-X",
                "ASR-1006-X",
                "ASR-1001-HX",
                "ASR-1002-HX",
                "C1111X-8P",
                "C1121X-8P",
                "C1121X-8PLTEP",
                "C1121X-8PLTEPW",
                "C1126X-8PLTEP",
                "C1127X-8PLTEP",
                "C1127X-8PMLTEP",
                "C1131X-8PLTEPW",
                "C1131X-8PW",
                "C1161X-8P",
                "C1161X-8PLTEP",
                "C8131X-1C-8T2S",
                "C8151-G2",
                "C8131X-1C-8P2S",
                "C8161-G2",
                "C8230X-8M2X",
                "C8235-G2",
                "C8230E-8TM2X",
                "C8231-G2",
                "C8230-1N-2M2X",
                "C8231-E-G2",
                "C8230X-1N-2M2X",
                "C8235-E-G2",
            ]
        ):
            required_variables = [
                var
                for var in configuration_group_variables
                if "sdwan.feature_profiles.other_profiles.thousandeyes."
                not in var["flat_path"]
            ]
        if all(
            model not in chassis_id
            for model in [
                "C8300-2N2S-4T2X",
                "C8330-1N1S-4M2X",
                "C8375-E-G2",
                "C8330-6TM4SX",
                "C8330-6TM4X",
                "C8351-G2",
                "C8330X-6TM4SX",
                "C8330X-6TM4X",
                "C8355-G2",
                "C8300-1N1S-4T2X",
                "C8230E-8TM2X",
                "C8231-G2",
                "C8230X-8M2X",
                "C8235-G2",
                "C8230-1N-2M2X",
                "C8231-E-G2",
                "C8230X-1N-2M2X",
                "C8235-E-G2",
                "C8300-2N2S-6T",
                "ISR-4451-X",
                "C8300-1N1S-6T",
                "ISR-4461",
                "ISR-4351",
                "ISR-4431",
                "ISR-4321",
                "ISR-4331",
                "ISR-4221",
                "ISR-4221X",
            ]
        ):
            required_variables = [
                var
                for var in required_variables
                if "sdwan.feature_profiles.other_profiles.ucse." not in var["flat_path"]
            ]

        # For dual device configuration group
        # Filter variables for features that are not assigned to this device
        for tag in configuration_groups_tags:
            if tag["name"] not in router_tags:
                # If tag is not present, for each feature remove variables for this feature
                for feature_name in tag.get("features", []):
                    required_variables = [
                        var
                        for var in required_variables
                        if f"[{feature_name}]" not in var["full_path"]
                    ]

        # # Filter variables for features that are not assigned
        # e.g. if dhcp server feature is not associated with any interface,
        # dhcp server variables should not be in required variables list
        for associated_feature in cls.associated_features:
            variables_to_remove = []
            for var in required_variables:
                if associated_feature["feature_path"] in var["flat_path"]:
                    profile_name, feature_name = re.findall(
                        r"\[([^\]]+)\]", var["full_path"]
                    )[:2]
                    # Check if feature is found in any of the associate_jmes_paths
                    feature_found = False
                    for associate_path in associated_feature["associate_jmes_paths"]:
                        search_path = associate_path.replace(
                            "[]", f"[?name == '{profile_name}']", 1
                        )
                        found_feature_names = jmespath.search(search_path, inventory)
                        if found_feature_names and feature_name in found_feature_names:
                            feature_found = True
                            break

                    if not feature_found:
                        variables_to_remove.append(var)
            for var in variables_to_remove:
                required_variables.remove(var)

        return required_variables

    @staticmethod
    def version_matches(manager_version, condition):
        """Return True if manager_version satisfies the condition string.

        condition can be: <X.Y  <=X.Y  >X.Y  >=X.Y  or X.Y (exact match).
        """
        m = re.match(r'^(<=|>=|<|>)?([\d]+(?:\.[\d]+)*)$', str(condition).strip())
        if not m or not manager_version:
            return False
        operator = m.group(1) or "=="
        def parse(v):
            parts = tuple(int(x) for x in str(v).split("."))
            return parts + (0,) * (3 - len(parts))
        try:
            mgr, cond = parse(manager_version), parse(m.group(2))
        except ValueError:
            return False
        return (
            mgr < cond  if operator == "<"  else
            mgr <= cond if operator == "<=" else
            mgr > cond  if operator == ">"  else
            mgr >= cond if operator == ">=" else
            mgr == cond
        )

    @classmethod
    def match(cls, inventory):
        required_variables_paths = list(cls.generic_required_variables_paths)
        if inventory.get("sdwan", {}).get("manager_version"):
            for version_specific_required_variables_path in cls.version_specific_required_variables_paths:
                if cls.version_matches(inventory.get("sdwan", {}).get("manager_version"), version_specific_required_variables_path["version"]):
                    required_variables_paths.extend(version_specific_required_variables_path["paths"])
        results = []
        profile_types = [
            "cli",
            "other",
            "policy_object",
            "service",
            "system",
            "transport",
        ]
        # Create a dict where key is profile type and value is a list of profile names that exists for this profile type
        existing_profiles_names = {profile_type: [] for profile_type in profile_types}
        # Create a dict that holds variables for each configuration group
        configuration_group_variables = {}
        for profile_type in profile_types:
            if (
                inventory.get("sdwan", {})
                .get("feature_profiles", {})
                .get(f"{profile_type}_profiles", {})
            ):
                for profile in (
                    inventory.get("sdwan", {})
                    .get("feature_profiles", {})
                    .get(f"{profile_type}_profiles", {})
                ):
                    profile_name = profile.get("name")
                    existing_profiles_names[profile_type].append(profile_name)
        policy_object_profile = (
            inventory.get("sdwan", {})
            .get("feature_profiles", {})
            .get(f"policy_object_profile", {})
        )
        if policy_object_profile:
            profile_name = policy_object_profile.get("name", "policy_objects")
            existing_profiles_names["policy_object"] = [profile_name]
        if inventory.get("sdwan", {}).get("configuration_groups", {}):
            for configuration_group in inventory.get("sdwan", {}).get(
                "configuration_groups", {}
            ):
                for profile_type in profile_types:
                    if configuration_group.get(f"{profile_type}_profile", None):
                        # Validate if profiles that are referenced exists
                        if (
                            configuration_group.get(f"{profile_type}_profile")
                            not in existing_profiles_names[profile_type]
                        ):
                            results.append(
                                f"Configuration Group '{configuration_group.get('name')}' references a {profile_type} profile '{configuration_group.get(f'{profile_type}_profile')}' that does not exist under sdwan.feature_profiles.{profile_type}_profiles"
                            )

                configuration_group_variables[configuration_group.get("name")] = (
                    cls.get_configuration_group_variables(
                        inventory, configuration_group
                    )
                )

        # Verify the presence of the required device variables in each site and router
        for site in inventory.get("sdwan", {}).get("sites", {}):
            for router in site["routers"]:
                if "configuration_group" in router:
                    # Verify if configuration group exists
                    configuration_group_name = router.get("configuration_group")
                    configuration_group = next(
                        (
                            cg
                            for cg in inventory.get("sdwan", {}).get("configuration_groups", {})
                            if cg.get("name") == configuration_group_name
                        ),
                        None,
                    )
                    if not configuration_group:
                        results.append(
                            router["chassis_id"]
                            + " - configuration group '"
                            + configuration_group_name
                            + "' does not exist"
                        )
                        continue
                    # If this is dual devie configuration group, device needs to have correct tag assigned
                    if configuration_group.get("device_tags"):
                        configuration_group_tags = list(configuration_group.get("device_tags"))
                        router_tags = list(router.get("tags", []))
                        if router.get("topology_label"):
                            router_tags.append(router["topology_label"])
                        if not any(
                            tag["name"] in router_tags for tag in configuration_group_tags
                        ):
                            results.append(
                                router["chassis_id"]
                                + " - configuration group \""
                                + configuration_group_name
                                + "\" requires "
                                + " or ".join(f'"{tag["name"]}"' for tag in configuration_group_tags)
                                + " tag (20.15) or topology_label (20.18+) to be set on the router"
                            )
                    # Verify missing vars in the router
                    cli_profile_variables = []
                    missing_variables = []
                    unnecessary_variables = []
                    if (
                        "device_variables" not in router
                        and router.get("configuration_group_deploy", True) == True
                    ):
                        results.append(
                            router["chassis_id"]
                            + " - configuration_group_deploy is true but router is missing device variables"
                        )
                    elif "device_variables" in router:
                        # Verify variables that are always required
                        for required_variable in [
                            "system_ip",
                            "host_name",
                            "site_id",
                            "pseudo_commit_timer",
                        ]:
                            if required_variable not in router["device_variables"]:
                                missing_variables.append(required_variable)
                        # Verify variables that are required for this configuration group for this device
                        required_variables = cls.get_required_variables(
                            inventory,
                            configuration_group_variables.get(
                                router["configuration_group"]
                            ),
                            router["chassis_id"],
                            configuration_group.get("device_tags", []),
                            [router["topology_label"]] if router.get("topology_label") else router.get("tags", []),
                        )
                        for variable in required_variables:
                            if (
                                variable["flat_path"] in required_variables_paths
                                and variable["variable_name"]
                                not in router["device_variables"]
                            ):
                                # missing_variables.append(variable['variable_name'] + f' ({variable["path"]})')
                                missing_variables.append(variable["variable_name"])
                        # Verify CLI profile variables
                        if configuration_group.get("cli_profile"):
                            cli_profile = next(
                                (
                                    p
                                    for p in inventory.get("sdwan", {})
                                    .get("feature_profiles", {})
                                    .get("cli_profiles", [])
                                    if p.get("name")
                                    == configuration_group["cli_profile"]
                                ),
                                None,
                            )
                            if cli_profile and cli_profile.get("config", {}).get("cli_configuration"):
                                vars = re.findall(
                                    r"{{.*?}}",
                                    cli_profile["config"]["cli_configuration"],
                                )
                                for var in vars:
                                    var_name = re.sub(r"{{|}}|\s", "", var)
                                    cli_profile_variables.append(var_name)
                                    if var_name not in router["device_variables"]:
                                        missing_variables.append(var_name)
                        # Verify unnecessary variables
                        for variable in router["device_variables"]:
                            feature_profile_variables = [
                                v["variable_name"] for v in required_variables
                            ]
                            if (
                                variable not in feature_profile_variables
                                and variable not in cli_profile_variables
                                and variable
                                not in [
                                    "system_ip",
                                    "host_name",
                                    "site_id",
                                    "region_id",
                                    "pseudo_commit_timer",
                                    "ipv6_strict_control",
                                ]
                            ):
                                unnecessary_variables.append(variable)
                    if missing_variables:
                        results.append(
                            router["chassis_id"]
                            + " - missing required variables: "
                            + ", ".join(missing_variables)
                        )
                    if unnecessary_variables:
                        results.append(
                            router["chassis_id"]
                            + " - unnecessary variables: "
                            + ", ".join(unnecessary_variables)
                        )
                    for cli_var in cli_profile_variables:
                        if cli_var in feature_profile_variables:
                            results.append(
                                router["chassis_id"]
                                + f" - duplicated device variable name '{cli_var}' is not allowed in CLI and non-CLI feature profiles"
                            )

                # Validate that if configuration_group_deploy is true, minimum required profiles and parcels defined for deployment.
                if 'configuration_group' in router and router.get('configuration_group_deploy', True):
                    config_group_name = router.get('configuration_group')
                    config_group = next((cg for cg in inventory.get('sdwan', {}).get('configuration_groups', []) if cg.get('name') == config_group_name), None)
                    if config_group:
                            for (feature_profile_type, parcels) in  cls.req_profile_parcels_for_deploy.items():
                                cfg_grp_profile_type, feature_profile_type = feature_profile_type.split(':')
                                # Verify if minimal required profile is assigned
                                if cfg_grp_profile_type not in config_group:
                                    results.append(f"sdwan.sites.{site['id']}.routers.{router['chassis_id']} - configuration_group '{config_group_name}' is missing required profile: {cfg_grp_profile_type} for deployment.")
                                elif feature_profile_type and parcels:
                                    # Verify if minimal required profile features is created
                                    feature_profiles = inventory.get('sdwan', {}).get('feature_profiles', {}).get(feature_profile_type, [])
                                    feature_profiles = feature_profiles if isinstance(feature_profiles, list) else [feature_profiles]
                                    find_profile = next((p for p in feature_profiles if p.get('name') == config_group.get(cfg_grp_profile_type)), None)
                                    if find_profile:
                                        missing_parcels = [p for p in parcels if p not in find_profile.keys()]
                                        if missing_parcels:
                                            results.append(f"sdwan.sites.{site['id']}.routers.{router['chassis_id']} - configuration_group '{config_group_name}' is missing required '{cfg_grp_profile_type}' features: " + ", ".join(missing_parcels) + " for deployment.")
                                    # Additional checks for transport profile
                                    if feature_profile_type == 'transport_profiles':
                                        # Verify ethernet interface config
                                        transport_profile_name = config_group.get('transport_profile')
                                        transport_profile = next((tp for tp in feature_profiles if tp.get('name') == transport_profile_name), None)
                                        if transport_profile:
                                            ethernet_interfaces = transport_profile.get('wan_vpn', {}).get('ethernet_interfaces', [])
                                            if not ethernet_interfaces:
                                                results.append(f"sdwan.sites.{site['id']}.routers.{router['chassis_id']} - transport profile '{transport_profile_name}' is missing ethernet_interfaces configuration for deployment.")
                                            else:
                                                # Verify at least one active ethernet interface with tunnel_interface configured
                                                found_active_interface = False
                                                for interface in ethernet_interfaces:
                                                    if "shutdown" in interface:
                                                        if interface.get('shutdown', True) == False and 'tunnel_interface' in interface:
                                                            found_active_interface = True
                                                            break
                                                    elif "shutdown_variable" in interface:
                                                        shutdown_var_name = interface.get('shutdown_variable')
                                                        # Check if shutdown variable is defined and set to false
                                                        shutdown_var = next(
                                                            (var_value for var_name, var_value in router.get("device_variables", {}).items() if var_name == shutdown_var_name), 
                                                            None
                                                        )
                                                        if shutdown_var is not None and shutdown_var == False and 'tunnel_interface' in interface:
                                                            found_active_interface = True
                                                            break
                                                if not found_active_interface:
                                                    results.append(f"sdwan.sites.{site['id']}.routers.{router['chassis_id']} - transport profile '{transport_profile_name}' does not have any active (shutdown: false) ethernet_interface with tunnel_interface configured for deployment.")
        return results
