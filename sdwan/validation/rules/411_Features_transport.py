class Rule:
    id = "411"
    description = "Validate transport features"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("transport_profiles", []):
            # Validate bgp features
            for bgp in feature_profile.get("bgp_features", []):
                as_number = bgp.get("as_number", "as_number")
                for neighbor_family_type in ["ipv4_neighbors", "ipv6_neighbors"]:
                    for index, neighbor in enumerate(bgp.get(neighbor_family_type, [])):
                        if neighbor.get("local_as", "local_as") == as_number:
                            results.append(f"local_as is the same as as_number {as_number} in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}]")
                        # Check for duplicate family_type in neighbor.address_families
                        family_types = [af.get("family_type") for af in neighbor.get("address_families", []) if "family_type" in af]
                        duplicates = set([ft for ft in family_types if family_types.count(ft) > 1])
                        for dup in duplicates:
                            results.append(
                                f"Duplicate family_type '{dup}' found in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}].address_families"
                            )
                        # Validate maximum_prefixes_reach_policy
                        for index, address_family in enumerate(neighbor.get("address_families", [])):
                            reach_policy = address_family.get("maximum_prefixes_reach_policy", "off")
                            family_type = address_family.get('family_type')
                            base_path = f"sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}].address_families[{family_type}]"
                            # Define required and forbidden fields for each policy
                            policy_requirements = {
                                "off": {
                                    "forbidden": [
                                        "maximum_prefixes_number", "maximum_prefixes_number_variable",
                                        "maximum_prefixes_restart_interval", "maximum_prefixes_restart_interval_variable",
                                        "maximum_prefixes_threshold", "maximum_prefixes_threshold_variable"
                                    ],
                                    "required": []
                                },
                                "restart": {
                                    "forbidden": [],
                                    "required": [
                                        ("maximum_prefixes_number", "maximum_prefixes_number_variable"),
                                        ("maximum_prefixes_restart_interval", "maximum_prefixes_restart_interval_variable")
                                    ]
                                },
                                "warning-only": {
                                    "forbidden": [
                                        "maximum_prefixes_restart_interval", "maximum_prefixes_restart_interval_variable"
                                    ],
                                    "required": [
                                        ("maximum_prefixes_number", "maximum_prefixes_number_variable")
                                    ]
                                },
                                "disable-peer": {
                                    "forbidden": [
                                        "maximum_prefixes_restart_interval", "maximum_prefixes_restart_interval_variable"
                                    ],
                                    "required": [
                                        ("maximum_prefixes_number", "maximum_prefixes_number_variable")
                                    ]
                                }
                            }
                            reqs = policy_requirements.get(reach_policy, policy_requirements["off"])
                            # Check forbidden fields
                            for param in reqs["forbidden"]:
                                if param in address_family:
                                    results.append(f"maximum_prefixes_reach_policy is {reach_policy}, but {param} is defined in {base_path}")
                            # Check required fields (at least one of the tuple must be present)
                            for required_group in reqs["required"]:
                                if not any(field in address_family for field in required_group):
                                    results.append(f"maximum_prefixes_reach_policy is {reach_policy}, but {required_group[0]} is not defined in {base_path}")
                # In IPv4 redistributes, ospf_match_route or ospf_match_route_variable can only be defined when protocol is ospf
                for index, redistribute in enumerate(bgp.get("ipv4_redistributes", [])):
                    if redistribute.get("protocol") != "ospf":
                        if "ospf_match_route" in redistribute or "ospf_match_route_variable" in redistribute:
                            results.append(f"ospf_match_route or ospf_match_route_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv4_redistributes[{index}]")
                # In IPv6 redistributes, metric or metric_variable, ospf_match_route or ospf_match_route_variable can only be defined when protocol is ospf
                for index, redistribute in enumerate(bgp.get("ipv6_redistributes", [])):
                    if redistribute.get("protocol") != "ospf":
                        if "metric" in redistribute or "metric_variable" in redistribute:
                            results.append(f"metric or metric_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv6_redistributes[{index}]")
                        if "ospf_match_route" in redistribute or "ospf_match_route_variable" in redistribute:
                            results.append(f"ospf_match_route or ospf_match_route_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv6_redistributes[{index}]")
            # Validate ospf features
            for ospf in feature_profile.get("ospf_features", []):
                if ospf.get("default_originate", False) == False:
                    forbidden_options = ["default_originate_always", "default_originate_always_variable", "default_originate_metric", "default_originate_metric_variable", "default_originate_metric_type", "default_originate_metric_type_variable"]
                    for option in forbidden_options:
                        if option in ospf:
                            results.append(f"default_originate is false, but {option} is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}]")
                if ospf.get("router_lsa_advertisement_type", "none") != "on-startup" and "router_lsa_advertisement_time" in ospf:
                    results.append(f"router_lsa_advertisement_time is defined but router_lsa_advertisement_type is not set to on-startup in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}]")
                for area_index, area in enumerate(ospf.get("areas", [])):
                    if area.get("number") == 0:
                        forbidden_options = ["type", "no_summary", "no_summary_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area number is 0, but {option} is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area_index}]")
                    for interface_index, interface in enumerate(area.get("interfaces", [])):
                        if interface.get("authentication_type", "none") == "md5":
                            if "authentication_message_digest_key" not in interface and "authentication_message_digest_key_variable" not in interface:
                                results.append(f"authentication_type is md5 but authentication_message_digest_key is not defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area.get('number', area_index)}].interfaces[{interface.get('name', interface_index)}]")
                            if "authentication_message_digest_key_id" not in interface and "authentication_message_digest_key_id_variable" not in interface:
                                results.append(f"authentication_type is md5 but authentication_message_digest_key_id is not defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area.get('number', area_index)}].interfaces[{interface.get('name', interface_index)}]")
                for index, redistribute in enumerate(ospf.get("redistributes", [])):
                    if redistribute.get("protocol") != "nat" and ("dia" in redistribute or "dia_variable" in redistribute):
                        results.append(f"dia is defined but protocol is not set to nat in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].redistributes[{index}]")
            # Validate cellular_profile feature
            for cellular_profile in feature_profile.get("cellular_profiles", []):
                # If authentication is Enabled: authentication_type, username, and password must be present
                if cellular_profile.get("authentication_enable", False):
                    if not cellular_profile.get("authentication_type"):
                        results.append(f"authentication is enabled, but authentication_type is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
                    if not cellular_profile.get("profile_username") and not cellular_profile.get("profile_username_variable"):
                        results.append(f"authentication is enabled, but username is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
                    if not cellular_profile.get("profile_password") and not cellular_profile.get("profile_password_variable"):
                        results.append(f"authentication is enabled, but password is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
                else:
                    # If authentication is Disabled or not present: authentication_type, username, and password should not be present
                    if cellular_profile.get("authentication_type"):
                        results.append(f"authentication is disabled, but authentication_type is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
                    if cellular_profile.get("profile_username") or cellular_profile.get("profile_username_variable"):
                        results.append(f"authentication is disabled, but username is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
                    if cellular_profile.get("profile_password") or cellular_profile.get("profile_password_variable"):
                        results.append(f"authentication is disabled, but password is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].cellular_profiles[{cellular_profile['name']}]")
            # Validate gps feature
            for gps in feature_profile.get("gps_features", []):
                if not gps.get("nmea_enable"):
                    if gps.get("nmea_source_address") or gps.get("nmea_destination_address") or gps.get("nmea_destination_port"):
                        results.append(f"nmea is disabled, but nmea_source_address, nmea_destination_address or nmea_destination_port is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].gps[{gps['name']}]")
            # Validate management_vpn feature
            management_vpn_feature = feature_profile.get("management_vpn", {})
            if management_vpn_feature:
                if ("ipv4_primary_dns_address" not in management_vpn_feature and "ipv4_primary_dns_address_variable" not in management_vpn_feature) and ("ipv4_secondary_dns_address" in management_vpn_feature or "ipv4_secondary_dns_address_variable" in management_vpn_feature):
                    results.append(f"ipv4_secondary_dns_address is defined but ipv4_primary_dns_address is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn")
                for index, route in enumerate(management_vpn_feature.get("ipv4_static_routes", {})):
                    if route.get("gateway", "nexthop") != "null0" and "administrative_distance" in route or "administrative_distance_variable" in route:
                        results.append(f"administrative_distance is defined but gateway is not null0 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv4_static_routes[{index}]")
                    if route.get("gateway", "nexthop") != "nexthop" and "next_hops" in route:
                        results.append(f"next_hops list is present but gateway is set to {route.get('gateway', 'nextHop')} in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv4_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nexthop" and "next_hops" not in route:
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv4_static_routes[{index}]")
                for index, route in enumerate(management_vpn_feature.get("ipv6_static_routes", {})):
                    if route.get("gateway", "nexthop") != "nat" and route.get("nat"):
                        results.append(f"nat option is defined but gateway is not set to nat in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nat" and not route.get("nat"):
                        results.append(f"gateway is set to nat but nat option is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") != "nexthop" and "next_hops" in route:
                        results.append(f"next_hops list is present but gateway is set to {route.get('gateway', 'nextHop')} in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nexthop" and "next_hops" not in route:
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ipv6_static_routes[{index}]")
                for ethernet_interface in management_vpn_feature.get("ethernet_interfaces", []):
                    if not any(parameter in ethernet_interface for parameter in ["ipv4_address_type", "ipv4_address_type_variable"]):
                        results.append(f"At least one of ['ipv4_address_type', 'ipv4_address_type_variable'] must be defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv4_address_type_variable"):
                        mandatory_parameters = ["ipv4_address_variable", "ipv4_subnet_mask_variable", "ipv4_dhcp_distance_variable"]
                        for param in mandatory_parameters:
                            if param not in ethernet_interface:
                                results.append(f"{param} must be defined when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        for secondary_address in ethernet_interface.get("ipv4_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv4_secondary_addresses.address is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                            if secondary_address.get("subnet_mask"):
                                results.append(f"ipv4_secondary_addresses.subnet_mask is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv4_address_type") == "static":
                        if "ipv4_dhcp_distance" in ethernet_interface or "ipv4_dhcp_distance_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is static but ipv4_dhcp_distance is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv4_address_type") == "dynamic":
                        if "ipv4_address" in ethernet_interface or "ipv4_address_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_address is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_subnet_mask" in ethernet_interface or "ipv4_subnet_mask_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_subnet_mask is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv4_secondary_addresses is defined but ipv4_address_type is dynamic in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type_variable"):
                        if "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_variable must be defined when ipv6_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type") == "static":
                        if "ipv6_address" not in ethernet_interface and "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_type is static but ipv6_address is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("autonegotiate") and ethernet_interface.get("speed"):
                        results.append(f"autonegotiate is true but speed is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].management_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
            # Validate wan_vpn feature
            wan_vpn_feature = feature_profile.get("wan_vpn", {})
            if wan_vpn_feature:
                if ("ipv4_primary_dns_address" not in wan_vpn_feature and "ipv4_primary_dns_address_variable" not in wan_vpn_feature) and ("ipv4_secondary_dns_address" in wan_vpn_feature or "ipv4_secondary_dns_address_variable" in wan_vpn_feature):
                    results.append(f"ipv4_secondary_dns_address is defined but ipv4_primary_dns_address is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn")
                for index, route in enumerate(wan_vpn_feature.get("ipv4_static_routes", {})):
                    if route.get("gateway", "nexthop") != "null0" and "administrative_distance" in route or "administrative_distance_variable" in route:
                        results.append(f"administrative_distance is defined but gateway is not null0 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv4_static_routes[{index}]")
                    if route.get("gateway", "nexthop") != "nexthop" and "next_hops" in route:
                        results.append(f"next_hops list is present but gateway is set to {route.get('gateway', 'nextHop')} in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv4_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nexthop" and "next_hops" not in route:
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv4_static_routes[{index}]")
                for index, route in enumerate(wan_vpn_feature.get("ipv6_static_routes", {})):
                    if route.get("gateway", "nexthop") != "nat" and route.get("nat"):
                        results.append(f"nat option is defined but gateway is not set to nat in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nat" and not route.get("nat"):
                        results.append(f"gateway is set to nat but nat option is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") != "nexthop" and "next_hops" in route:
                        results.append(f"next_hops list is present but gateway is set to {route.get('gateway', 'nextHop')} in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv6_static_routes[{index}]")
                    if route.get("gateway", "nexthop") == "nexthop" and "next_hops" not in route:
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipv6_static_routes[{index}]")
                
                # Validate cellular interfaces
                for cellular_interface in wan_vpn_feature.get("cellular_interfaces", []):
                    if cellular_interface.get("adaptive_qos", False) == False:
                        if cellular_interface.get("adaptive_qos_period") or cellular_interface.get("adaptive_qos_period_variable"):
                            results.append(f"adaptive_qos is false but adaptive_qos_period is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                        if cellular_interface.get("adaptive_qos_shaping_rate_downstream"):
                            results.append(f"adaptive_qos is false but adaptive_qos_shaping_rate_downstream is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                        if cellular_interface.get("adaptive_qos_shaping_rate_upstream"):
                            results.append(f"adaptive_qos is false but adaptive_qos_shaping_rate_upstream is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")

                    # if ipv4_nat is false, then [ipv4_nat_tcp_timeout, ipv4_nat_tcp_timeout_variable, ipv4_nat_udp_timeout, ipv4_nat_udp_timeout_variable] should not be defined
                    if cellular_interface.get("ipv4_nat", False) == False:
                        forbidden_options = ["ipv4_nat_tcp_timeout", "ipv4_nat_tcp_timeout_variable", "ipv4_nat_udp_timeout", "ipv4_nat_udp_timeout_variable"]
                        for option in forbidden_options:
                            if option in cellular_interface:
                                results.append(f"ipv4_nat is false but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                    
                    tunnel_interface = cellular_interface.get("tunnel_interface", {})
                    if tunnel_interface:
                        if tunnel_interface.get("gre_encapsulation", False) == False:
                            if tunnel_interface.get("gre_preference") or tunnel_interface.get("gre_preference_variable"):
                                results.append(f"gre_encapsulation is false but gre_preference is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                            if tunnel_interface.get("gre_weight") or tunnel_interface.get("gre_weight_variable"):
                                results.append(f"gre_encapsulation is false but gre_weight is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                        if tunnel_interface.get("ipsec_encapsulation", True) == False:
                            if tunnel_interface.get("ipsec_preference") or tunnel_interface.get("ipsec_preference_variable"):
                                results.append(f"ipsec_encapsulation is false but ipsec_preference is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                            if tunnel_interface.get("ipsec_weight") or tunnel_interface.get("ipsec_weight_variable"):
                                results.append(f"ipsec_encapsulation is false but ipsec_weight is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                        if tunnel_interface.get("per_tunnel_qos", False) == False:
                            if tunnel_interface.get("per_tunnel_qos_mode") or tunnel_interface.get("per_tunnel_qos_mode_variable"):
                                results.append(f"per_tunnel_qos is false but per_tunnel_qos_mode is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                        else:
                            if not tunnel_interface.get("per_tunnel_qos_mode") and not tunnel_interface.get("per_tunnel_qos_mode_variable"):
                                results.append(f"per_tunnel_qos is true but per_tunnel_qos_mode is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name')}]")
                
                for ethernet_interface in wan_vpn_feature.get("ethernet_interfaces", []):
                    if ethernet_interface.get("port_channel_member_interface") != True and not any(parameter in ethernet_interface for parameter in ["ipv4_address_type", "ipv4_address_type_variable", "ipv6_address_type", "ipv6_address_type_variable"]):
                        results.append(f"At least one of ['ipv4_address_type', 'ipv6_address_type'] must be defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv4_address_type_variable"):
                        mandatory_parameters = ["ipv4_address_variable", "ipv4_subnet_mask_variable", "ipv4_dhcp_distance_variable"]
                        for param in mandatory_parameters:
                            if param not in ethernet_interface:
                                results.append(f"{param} must be defined when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        for secondary_address in ethernet_interface.get("ipv4_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv4_secondary_addresses.address is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                            if secondary_address.get("subnet_mask"):
                                results.append(f"ipv4_secondary_addresses.subnet_mask is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv4_address_type") == "static":
                        if "ipv4_dhcp_distance" in ethernet_interface or "ipv4_dhcp_distance_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is static but ipv4_dhcp_distance is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv4_address_type") == "dynamic":
                        if "ipv4_address" in ethernet_interface or "ipv4_address_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_address is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_subnet_mask" in ethernet_interface or "ipv4_subnet_mask_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_subnet_mask is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv4_secondary_addresses is defined but ipv4_address_type is dynamic in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type_variable"):
                        if "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_variable must be defined when ipv6_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type") == "static":
                        if "ipv6_address" not in ethernet_interface and "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_type is static but ipv6_address is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv6_dynamic_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv6_dynamic_secondary_addresses is defined but ipv6_address_type is static in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv6_address_type") == "dynamic":
                        if "ipv6_address" in ethernet_interface or "ipv6_address_variable" in ethernet_interface:
                            results.append(f"ipv6_address_type is dynamic but static ipv6_address is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv6_static_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv6_static_secondary_addresses is defined but ipv6_address_type is dynamic in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv6_address_type_variable"):
                        for secondary_address in ethernet_interface.get("ipv6_dynamic_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv6_dynamic_secondary_addresses.address is not allowed when ipv6_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        for secondary_address in ethernet_interface.get("ipv6_static_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv6_static_secondary_addresses.address is not allowed when ipv6_address_type_variable is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("adaptive_qos", False) == False:
                        if ethernet_interface.get("adaptive_qos_period") or ethernet_interface.get("adaptive_qos_period_variable"):
                            results.append(f"adaptive_qos is false but adaptive_qos_period is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        if ethernet_interface.get("adaptive_qos_shaping_rate_downstream"):
                            results.append(f"adaptive_qos is false but adaptive_qos_shaping_rate_downstream is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        if ethernet_interface.get("adaptive_qos_shaping_rate_upstream"):
                            results.append(f"adaptive_qos is false but adaptive_qos_shaping_rate_upstream is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    if ethernet_interface.get("port_channel_member_interface"):
                        forbidden_options = ["ipv4_address_type", "ipv6_address_type", "tunnel_interface", "ipv4_nat", "ipv6_nat"]
                        for option in forbidden_options:
                            if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                results.append(f"port_channel_member_interface is true but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    if ethernet_interface.get("port_channel_interface"):
                        if ethernet_interface.get("port_channel_subinterface", False) == False:
                            if ethernet_interface.get("port_channel_mode", "lacp") == "static":
                                forbidden_options = ["port_channel_lacp_fast_switchover", "port_channel_lacp_max_bundle", "port_channel_lacp_min_bundle"]
                                for option in forbidden_options:
                                    if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                        results.append(f"port_channel_mode is static but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                                for member_link in ethernet_interface.get("port_channel_member_links", []):
                                    forbidden_options = ["lacp_mode", "lacp_port_priority", "lacp_rate"]
                                    for option in forbidden_options:
                                        if option in member_link or f"{option}_variable" in member_link:
                                            results.append(f"port_channel_mode is static but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}].{member_link.get('name', 'member_link')}]")
                        else:
                            for option in ["port_channel_lacp_fast_switchover", "port_channel_lacp_max_bundle", "port_channel_lacp_min_bundle", "port_channel_load_balance", "port_channel_qos_aggregate", "port_channel_mode", "port_channel_member_links"]:
                                if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                    results.append(f"port_channel_subinterface is true but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    else:
                        forbidden_options = [
                            "port_channel_lacp_fast_switchover",
                            "port_channel_lacp_max_bundle",
                            "port_channel_lacp_min_bundle",
                            "port_channel_load_balance",
                            "port_channel_qos_aggregate",
                            "port_channel_mode",
                            "port_channel_subinterface",
                            "port_channel_member_links",
                        ]
                        for option in forbidden_options:
                            if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                results.append(f"port_channel_interface is false but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    if ethernet_interface.get("ipv4_nat", False) == False:
                        for key in ethernet_interface.keys():
                            if key.startswith("ipv4_nat_"):
                                results.append(f"ipv4_nat is false but {key} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    else:
                        if (ethernet_interface.get("ipv4_nat_loopback_interface") or ethernet_interface.get("ipv4_nat_loopback_interface_variable")) and ethernet_interface.get("ipv4_nat_type", "inteface") != "loopback":
                            results.append(f"ipv4_nat_loopback_interface is defined but ipv4_nat_type is not loopback in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        nat_pool_parameters = ["ipv4_nat_pool_overload", "ipv4_nat_pool_overload_variable", "ipv4_nat_pool_prefix_length", "ipv4_nat_pool_prefix_length_variable", "ipv4_nat_pool_range_end", "ipv4_nat_pool_range_end_variable", "ipv4_nat_pool_range_start", "ipv4_nat_pool_range_start_variable"]
                        for parameter in nat_pool_parameters:
                            if ethernet_interface.get(parameter) and ethernet_interface.get("ipv4_nat_type", "interface") != "pool":
                                results.append(f"{parameter} is defined but ipv4_nat_type is not pool in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    if ethernet_interface.get("ipv6_nat", False) == False:
                        for key in ethernet_interface.keys():
                            if key.startswith("ipv6_nat") or key.startswith("ipv6_nat66"):
                                results.append(f"ipv6_nat is false but {key} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    if ethernet_interface.get("autonegotiate") and ethernet_interface.get("speed"):
                        results.append(f"autonegotiate is true but speed is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                    tunnel_interface = ethernet_interface.get("tunnel_interface", {})
                    if tunnel_interface:
                        if tunnel_interface.get("gre_encapsulation", False) == False:
                            if tunnel_interface.get("gre_preference") or tunnel_interface.get("gre_preference_variable"):
                                results.append(f"gre_encapsulation is false but gre_preference is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                            if tunnel_interface.get("gre_weight") or tunnel_interface.get("gre_weight_variable"):
                                results.append(f"gre_encapsulation is false but gre_weight is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        if tunnel_interface.get("ipsec_encapsulation", True) == False:
                            if tunnel_interface.get("ipsec_preference") or tunnel_interface.get("ipsec_preference_variable"):
                                results.append(f"ipsec_encapsulation is false but ipsec_preference is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                            if tunnel_interface.get("ipsec_weight") or tunnel_interface.get("ipsec_weight_variable"):
                                results.append(f"ipsec_encapsulation is false but ipsec_weight is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        if tunnel_interface.get("per_tunnel_qos", False) == False:
                            if tunnel_interface.get("per_tunnel_qos_mode") or tunnel_interface.get("per_tunnel_qos_mode_variable"):
                                results.append(f"per_tunnel_qos is false but per_tunnel_qos_mode is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                            if tunnel_interface.get("per_tunnel_qos_bandwidth_percent") or tunnel_interface.get("per_tunnel_qos_bandwidth_percent_variable"):
                                results.append(f"per_tunnel_qos is false but per_tunnel_qos_bandwidth_percent is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        else:
                            if tunnel_interface.get("per_tunnel_qos_mode") and ethernet_interface.get("adaptive_qos"):
                                results.append(f"Mutually exclusive parameters tunnel_interface.per_tunnel_qos_mode and adaptive_qos are is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{interface.get('name')}]")
                        if tunnel_interface.get("per_tunnel_qos_bandwidth_percent") and tunnel_interface.get("per_tunnel_qos_mode") != "hub":
                                results.append(f"per_tunnel_qos_bandwidth_percent is defined but per_tunnel_qos_mode is not hub in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{ethernet_interface.get('name')}]")
                        if tunnel_interface.get("mrf_enable_core_region"):
                            if not tunnel_interface.get("mrf_core_region_type"):
                                results.append(f"mrf_enable_core_region is true but mrf_core_region_type is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{interface.get('name')}]")
                        else:
                            if tunnel_interface.get("mrf_core_region_type"):
                                results.append(f"mrf_enable_core_region is false but mrf_core_region_type is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{interface.get('name')}]")
                        if tunnel_interface.get("mrf_enable_secondary_region"):
                            if not tunnel_interface.get("mrf_secondary_region_type"):
                                results.append(f"mrf_enable_secondary_region is true but mrf_secondary_region_type is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{interface.get('name')}]")
                        else:
                            if tunnel_interface.get("mrf_secondary_region_type"):
                                results.append(f"mrf_enable_secondary_region is false but mrf_secondary_region_type is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ethernet_interfaces[{interface.get('name')}]")
                
                # Validate gre interfaces
                for gre_interface in wan_vpn_feature.get("gre_interfaces", []):
                    # if tunnel_mode is ipv6, one of [tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable, tunnel_source_interface, tunnel_source_interface_variable, tunnel_source_interface_loopback, tunnel_source_interface_loopback_variable], one of [tunnel_destination_ipv6_address, tunnel_destination_ipv6_address_variable] must be defined
                    #    [tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_destination_ipv4_address, tunnel_destination_ipv4_address_variable] should not be defined
                    if gre_interface.get("tunnel_mode", "ipv4") == "ipv6":
                        if not (gre_interface.get("tunnel_source_ipv6_address") or gre_interface.get("tunnel_source_ipv6_address_variable") or gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")):
                            results.append(f"tunnel_mode is ipv6 but no tunnel source is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")
                        if not (gre_interface.get("tunnel_destination_ipv6_address") or gre_interface.get("tunnel_destination_ipv6_address_variable")):
                            results.append(f"tunnel_mode is ipv6 but no tunnel destination is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")
                        forbidden_options = ["tunnel_source_ipv4_address", "tunnel_source_ipv4_address_variable", "tunnel_destination_ipv4_address", "tunnel_destination_ipv4_address_variable"]
                        for option in forbidden_options:
                            if option in gre_interface:
                                results.append(f"tunnel_mode is ipv6 but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")
                    else:
                        # tunnel_mode is ipv4
                        if not (gre_interface.get("tunnel_source_ipv4_address") or gre_interface.get("tunnel_source_ipv4_address_variable") or gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")):
                            results.append(f"tunnel_mode is ipv4 but no tunnel source is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")
                        if not (gre_interface.get("tunnel_destination_ipv4_address") or gre_interface.get("tunnel_destination_ipv4_address_variable")):
                            results.append(f"tunnel_mode is ipv4 but no tunnel destination is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")
                        forbidden_options = ["tunnel_source_ipv6_address", "tunnel_source_ipv6_address_variable", "tunnel_destination_ipv6_address", "tunnel_destination_ipv6_address_variable"]
                        for option in forbidden_options:
                            if option in gre_interface:
                                results.append(f"tunnel_mode is ipv4 but {option} is defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")

                    # if one of [tunnel_source_interface, tunnel_source_interface_variable, tunnel_source_interface_loopback, tunnel_source_interface_loopback_variable] is defined, [tunnel_route_via_loopback, tunnel_route_via_loopback_variable, tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable] should not be defined
                    forbidden_options = ["tunnel_route_via_loopback", "tunnel_route_via_loopback_variable", "tunnel_source_ipv4_address", "tunnel_source_ipv4_address_variable", "tunnel_source_ipv6_address", "tunnel_source_ipv6_address_variable"]
                    if (gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")) and any(option in gre_interface for option in forbidden_options):
                        results.append(f"tunnel source is an interface, but tunnel_route_via_loopback or static tunnel source is defined in sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}]")

                for ipsec_interface in wan_vpn_feature.get("ipsec_interfaces", []):
                    # when tunnel_mode is ipv4
                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv4":
                        # For ipv4 tunnel mode, if ipv4_address is defined, then ipv4_subnet_mask must also be defined, also if ipv4_address_variable is defined, then ipv4_subnet_mask_variable must also be defined
                        # Additionally, ipv4_subnet_mask and ipv4_subnet_mask_variable should not be defined as standalone without ipv4_address or ipv4_address_variable
                        if ipsec_interface.get("ipv4_address", False) and not ipsec_interface.get("ipv4_subnet_mask", False):
                            results.append(f"ipv4_address is defined but ipv4_subnet_mask is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        elif ipsec_interface.get("ipv4_address_variable", False) and not ipsec_interface.get("ipv4_subnet_mask_variable", False):
                            results.append(f"ipv4_address_variable is defined but ipv4_subnet_mask_variable is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if (ipsec_interface.get("ipv4_subnet_mask", False) and not ipsec_interface.get("ipv4_address", False)) or (ipsec_interface.get("ipv4_subnet_mask_variable", False) and not ipsec_interface.get("ipv4_address_variable", False)):
                            results.append(f"ipv4_subnet_mask or ipv4_subnet_mask_variable is defined but respective ipv4_address or ipv4_address_variable is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False)):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable which is a mandatory field when tunnel_mode is ipv4, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv4, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False):
                            results.append(f"ipv6_address or ipv6_address_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_mtu", False) or ipsec_interface.get("ipv6_mtu_variable", False):
                            results.append(f"ipv6_mtu or ipv6_mtu_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_tcp_mss", False) or ipsec_interface.get("ipv6_tcp_mss_variable", False):
                            results.append(f"ipv6_tcp_mss or ipv6_tcp_mss_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                    else:
                        if ipsec_interface.get("ipv4_address", False) or ipsec_interface.get("ipv4_address_variable", False) or ipsec_interface.get("ipv4_subnet_mask", False) or ipsec_interface.get("ipv4_subnet_mask_variable", False):
                            results.append(f"ipv4_address, ipv4_subnet_mask or ipv4_address_variable, ipv4_subnet_mask_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv4_mtu", False) or ipsec_interface.get("ipv4_mtu_variable", False):
                            results.append(f"ipv4_mtu or ipv4_mtu_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv4_tcp_mss", False) or ipsec_interface.get("ipv4_tcp_mss_variable", False):
                            results.append(f"ipv4_tcp_mss or ipv4_tcp_mss_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                            
                    # when tunnel_mode is ipv6
                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv6":
                        if not (ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False)):
                            results.append(f"ipv6_address or ipv6_address_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv6_address", False) or ipsec_interface.get("tunnel_destination_ipv6_address_variable", False)):
                            results.append(f"tunnel_destination_ipv6_address or tunnel_destination_ipv6_address_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv6_address", False) or ipsec_interface.get("tunnel_source_ipv6_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable is defined but tunnel_mode is not ipv4 or ipv4-v6overlay in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False):
                            results.append(f"tunnel_source_ipv4_address or tunnel_source_ipv4_address_variable is defined but tunnel_mode is not ipv4 or ipv4-v6overlay in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                    else:
                        if ipsec_interface.get("tunnel_destination_ipv6_address", False) or ipsec_interface.get("tunnel_destination_ipv6_address_variable", False):
                            results.append(f"tunnel_destination_ipv6_address or tunnel_destination_ipv6_address_variable is defined but tunnel_mode is not ipv6 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_source_ipv6_address", False) or ipsec_interface.get("tunnel_source_ipv6_address_variable", False):
                            results.append(f"tunnel_source_ipv6_address or tunnel_source_ipv6_address_variable is defined but tunnel_mode is not ipv6 in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")

                    # when tunnel_mode is ipv4-v6overlay
                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv4-v6overlay":
                        if not (ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False)):
                            results.append(f"ipv6_address or ipv6_address_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False)):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.transport_profiles[{feature_profile['name']}].wan_vpn.ipsec_interfaces[{ipsec_interface.get('name')}]")

        return results
