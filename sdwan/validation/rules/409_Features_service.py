class Rule:
    id = "409"
    description = "Validate service features"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            # Validate dhcp_servers feature options
            for dhcp_server in feature_profile.get("dhcp_servers", []):
                for index, option in enumerate(dhcp_server.get("options", [])):
                    if all(option.get(key) is None for key in ["hex", "ascii", "ip_addresses"]):
                        results.append(f"dhcp option type (one of: ascii, ip_address, hex) is required, but not defined in the sdwan.feature_profiles.service_profile[{feature_profile['name']}].dhcp_servers[{dhcp_server['name']}].options[{index}]")
            # Validate bgp features
            for bgp in feature_profile.get("bgp_features", []):
                as_number = bgp.get("as_number", "as_number")
                for neighbor_family_type in ["ipv4_neighbors", "ipv6_neighbors"]:
                    for index, neighbor in enumerate(bgp.get(neighbor_family_type, [])):
                        if neighbor.get("local_as", "local_as") == as_number:
                            results.append(f"local_as is the same as as_number {as_number} in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}]")
                        # Check for duplicate family_type in neighbor.address_families
                        family_types = [af.get("family_type") for af in neighbor.get("address_families", []) if "family_type" in af]
                        duplicates = set([ft for ft in family_types if family_types.count(ft) > 1])
                        for dup in duplicates:
                            results.append(
                                f"Duplicate family_type '{dup}' found in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}].address_families"
                            )
                        # Validate maximum_prefixes_reach_policy
                        for index, address_family in enumerate(neighbor.get("address_families", [])):
                            reach_policy = address_family.get("maximum_prefixes_reach_policy", "off")
                            family_type = address_family.get('family_type')
                            base_path = f"sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].{neighbor_family_type}[{index}].address_families[{family_type}]"
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
                # In IPv4 redistributes specific options are only valid for certain protocols. 
                for index, redistribute in enumerate(bgp.get("ipv4_redistributes", [])):
                    if redistribute.get("protocol") != "omp" and ("translate_rib_metric" in redistribute or "translate_rib_metric_variable" in redistribute):
                        results.append(f"translate_rib_metric or translate_rib_metric_variable is defined but protocol is not set to omp in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv4_redistributes[{index}]")
                    if redistribute.get("protocol") != "ospf":
                        if "ospf_match_route" in redistribute or "ospf_match_route_variable" in redistribute:
                            results.append(f"ospf_match_route or ospf_match_route_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv4_redistributes[{index}]")                            
                # In IPv6 redistributes specific options are only valid for certain protocols. 
                for index, redistribute in enumerate(bgp.get("ipv6_redistributes", [])):
                    if redistribute.get("protocol") != "omp" and ("translate_rib_metric" in redistribute or "translate_rib_metric_variable" in redistribute):
                        results.append(f"translate_rib_metric or translate_rib_metric_variable is defined but protocol is not set to omp in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv6_redistributes[{index}]")
                    if redistribute.get("protocol") != "ospf":
                        if "metric" in redistribute or "metric_variable" in redistribute:
                            results.append(f"metric or metric_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv6_redistributes[{index}]")
                        if "ospf_match_route" in redistribute or "ospf_match_route_variable" in redistribute:
                            results.append(f"ospf_match_route or ospf_match_route_variable is defined but protocol is not set to ospf in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].bgp_features[{bgp['name']}].ipv6_redistributes[{index}]")
            # Validate eigrp features
            for eigrp in feature_profile.get("eigrp_features", []):
                # if authentication type is md5, md5_keys must be defined, and key_id/key_id_variable and key_string/key_string_variable must be defined in each md5_key
                if eigrp.get("authentication_type", "none") == "md5":
                    if "md5_keys" not in eigrp:
                        results.append(f"authentication_type is md5 but md5_keys is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].eigrp_features[{eigrp['name']}]")
                    else:
                        for index, md5_key in enumerate(eigrp["md5_keys"]):
                            if "key_id" not in md5_key and "key_id_variable" not in md5_key:
                                results.append(f"authentication_type is md5 but key_id is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].eigrp_features[{eigrp['name']}]")
                            if "key_string" not in md5_key and "key_string_variable" not in md5_key:
                                results.append(f"authentication_type is md5 but key_string is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].eigrp_features[{eigrp['name']}]")
                # if authentication type is hmac-sha-256, hmac_authentication_key/hmac_authentication_key_variable must be defined
                elif eigrp.get("authentication_type", "none") == "hmac-sha-256":
                    if "hmac_authentication_key" not in eigrp and "hmac_authentication_key_variable" not in eigrp:
                        results.append(f"authentication_type is hmac-sha-256 but hmac_authentication_key is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].eigrp_features[{eigrp['name']}]")

            # Validate multicast features
            for multicast in feature_profile.get("multicast_features", []):
                # Basic configuration
                # threshold or threshold_variable should not be defined when local_replicator is false
                if multicast.get("local_replicator", False) == False:
                    forbidden_options = ["threshold", "threshold_variable"]
                    for option in forbidden_options:
                        if option in multicast:
                            results.append(f"local_replicator is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].multicast_features[{multicast['name']}]")
                # PIM
                # pim_source_specific_multicast_access_list or pim_source_specific_multicast_access_list_variable should not be defined when pim_source_specific_multicast is false
                if multicast.get("pim_source_specific_multicast", False) == False:
                    forbidden_options = ["pim_source_specific_multicast_access_list", "pim_source_specific_multicast_access_list_variable"]
                    for option in forbidden_options:
                        if option in multicast:
                            results.append(f"pim_source_specific_multicast is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].multicast_features[{multicast['name']}]")

                # auto_rp_announces and auto_rp_discoveries should not be defined when auto_rp is false
                if multicast.get("auto_rp", False) == False:
                    forbidden_options = ["auto_rp_announces", "auto_rp_discoveries"]
                    for option in forbidden_options:
                        if option in multicast:
                            results.append(f"auto_rp is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].multicast_features[{multicast['name']}]")
                # IGMP
                # join_groups.source_address or join_groups.source_address_variable should be defined only when version is 3 and join_groups is defined
                for index1,igmp_interface in enumerate(multicast.get("igmp_interfaces", [])):
                    if igmp_interface.get("version", 2) != 3:
                        for index2, join_group in enumerate(igmp_interface.get("join_groups", [])):
                            forbidden_options = ["source_address", "source_address_variable"]
                            for option in forbidden_options:
                                if option in join_group:
                                    results.append(f"version is not 3, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].multicast_features[{multicast['name']}].igmp_interfaces[{index1}].join_groups[{index2}]")
                # MSDP
                # peers.prefix_list should be defined only when peers.default_peer is true
                for index1, msdp_mesh_group in enumerate(multicast.get("msdp_mesh_groups", [])):
                    for index2, peer in enumerate(msdp_mesh_group.get("peers", [])):
                        if peer.get("default_peer", False) == False and "prefix_list" in peer:
                            results.append(f"default_peer is false, but prefix_list is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].multicast_features[{multicast['name']}].msdp_mesh_groups[{index1}].peers[{index2}]")
    
            # Validate ospf features
            for ospf in feature_profile.get("ospf_features", []):
                if ospf.get("default_originate", False) == False:
                    forbidden_options = ["default_originate_always", "default_originate_always_variable", "default_originate_metric", "default_originate_metric_variable", "default_originate_metric_type", "default_originate_metric_type_variable"]
                    for option in forbidden_options:
                        if option in ospf:
                            results.append(f"default_originate is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}]")
                if ospf.get("router_lsa_advertisement_type", "none") != "on-startup" and "router_lsa_advertisement_time" in ospf:
                    results.append(f"router_lsa_advertisement_time is defined but router_lsa_advertisement_type is not set to on-startup in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}]")
                for area_index, area in enumerate(ospf.get("areas", [])):
                    if area.get("number") == 0:
                        forbidden_options = ["type", "no_summary", "no_summary_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area number is 0, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area_index}]")
                    for interface_index, interface in enumerate(area.get("interfaces", [])):
                        if interface.get("authentication_type", "none") == "md5":
                            if "authentication_message_digest_key" not in interface and "authentication_message_digest_key_variable" not in interface:
                                results.append(f"authentication_type is md5 but authentication_message_digest_key is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area.get('number', area_index)}].interfaces[{interface.get('name', interface_index)}]")
                            if "authentication_message_digest_key_id" not in interface and "authentication_message_digest_key_id_variable" not in interface:
                                results.append(f"authentication_type is md5 but authentication_message_digest_key_id is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].areas[{area.get('number', area_index)}].interfaces[{interface.get('name', interface_index)}]")
                for index, redistribute in enumerate(ospf.get("redistributes", [])):
                    if redistribute.get("protocol") != "omp" and ("translate_rib_metric" in redistribute or "translate_rib_metric_variable" in redistribute):
                        results.append(f"translate_rib_metric is defined but protocol is not set to omp in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].redistributes[{index}]")
                    if redistribute.get("protocol") != "nat" and ("dia" in redistribute or "dia_variable" in redistribute):
                        results.append(f"dia is defined but protocol is not set to nat in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospf_features[{ospf['name']}].redistributes[{index}]")

            # Validate ospfv3_ipv4 features
            for ospf in feature_profile.get("ospfv3_ipv4_features", []):
                if ospf.get("default_originate", False) == False:
                    forbidden_options = ["default_originate_always", "default_originate_always_variable", "default_originate_metric", "default_originate_metric_variable", "default_originate_metric_type", "default_originate_metric_type_variable"]
                    for option in forbidden_options:
                        if option in ospf:
                            results.append(f"default_originate is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}]")
                
                if ospf.get("router_lsa_action", "none") != "on-startup" and ("router_lsa_on_startup_time" in ospf or "router_lsa_on_startup_time_variable" in ospf):
                    results.append(f"router_lsa_on_startup_time is defined but router_lsa_action is not set to on-startup in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}]")

                for area_index, area in enumerate(ospf.get("areas", [])):
                    if area.get("number") == 0:
                        forbidden_options = ["type", "no_summary", "no_summary_variable", "always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area number is 0, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].areas[{area_index}]")
                    elif area.get("type") == "normal":
                        forbidden_options = ["no_summary", "no_summary_variable", "always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area type is normal, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].areas[{area_index}]")
                    elif area.get("type") == "stub":
                        forbidden_options = ["always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area type is stub, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].areas[{area_index}]")
                    for interface_index, interface in enumerate(area.get("interfaces", [])):
                        if interface.get("authentication_type", "no-auth") == "no-auth":
                            forbidden_options = ["authentication_ipsec_spi", "authentication_ipsec_spi_variable", "authentication_ipsec_key", "authentication_ipsec_key_variable"]
                            for option in forbidden_options:
                                if option in interface:
                                    results.append(f"interface authentication_type is no-auth, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].areas[{area_index}].interfaces[{interface_index}]")

                for index, redistribute in enumerate(ospf.get("redistributes", [])):
                    if redistribute.get("protocol") != "omp" and ("translate_rib_metric" in redistribute or "translate_rib_metric_variable" in redistribute):
                        results.append(f"translate_rib_metric is defined but protocol is not set to omp in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].redistributes[{index}]")
                    if redistribute.get("protocol") != "nat-route" and ("nat_dia" in redistribute or "nat_dia_variable" in redistribute):
                        results.append(f"nat_dia is defined but protocol is not set to nat-route in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv4_features[{ospf['name']}].redistributes[{index}]")
            
            # Validate ospfv3_ipv6 features
            for ospf in feature_profile.get("ospfv3_ipv6_features", []):
                if ospf.get("default_originate", False) == False:
                    forbidden_options = ["default_originate_always", "default_originate_always_variable", "default_originate_metric", "default_originate_metric_variable", "default_originate_metric_type", "default_originate_metric_type_variable"]
                    for option in forbidden_options:
                        if option in ospf:
                            results.append(f"default_originate is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}]")
                
                if ospf.get("router_lsa_action", "none") != "on-startup" and "router_lsa_on_startup_time" in ospf:
                    results.append(f"router_lsa_on_startup_time is defined but router_lsa_action is not set to on-startup in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}]")

                for area_index, area in enumerate(ospf.get("areas", [])):
                    if area.get("number") == 0:
                        forbidden_options = ["type", "no_summary", "no_summary_variable", "always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area number is 0, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}].areas[{area_index}]")
                    elif area.get("type") == "normal":
                        forbidden_options = ["no_summary", "no_summary_variable", "always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area type is normal, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}].areas[{area_index}]")
                    elif area.get("type") == "stub":
                        forbidden_options = ["always_translate", "always_translate_variable"]
                        for option in forbidden_options:
                            if option in area:
                                results.append(f"area type is stub, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}].areas[{area_index}]")
                    for interface_index, interface in enumerate(area.get("interfaces", [])):
                        if interface.get("authentication_type", "no-auth") == "no-auth":
                            forbidden_options = ["authentication_ipsec_spi", "authentication_ipsec_spi_variable", "authentication_ipsec_key", "authentication_ipsec_key_variable"]
                            for option in forbidden_options:
                                if option in interface:
                                    results.append(f"interface authentication_type is no-auth, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}].areas[{area_index}].interfaces[{interface_index}]")

                for index, redistribute in enumerate(ospf.get("redistributes", [])):
                    if redistribute.get("protocol") != "omp" and ("translate_rib_metric" in redistribute or "translate_rib_metric_variable" in redistribute):
                        results.append(f"translate_rib_metric is defined but protocol is not set to omp in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].ospfv3_ipv6_features[{ospf['name']}].redistributes[{index}]")

            # Validate lan_vpns features
            for lan_vpn in feature_profile.get("lan_vpns", []):
                if ("ipv4_primary_dns_address" not in lan_vpn and "ipv4_primary_dns_address_variable" not in lan_vpn) and ("ipv4_secondary_dns_address" in lan_vpn or "ipv4_secondary_dns_address_variable" in lan_vpn):
                    results.append(f"ipv4_secondary_dns_address is defined but ipv4_primary_dns_address is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}]")
                if ("ipv6_primary_dns_address" not in lan_vpn and "ipv6_primary_dns_address_variable" not in lan_vpn) and ("ipv6_secondary_dns_address" in lan_vpn or "ipv6_secondary_dns_address_variable" in lan_vpn):
                    results.append(f"ipv6_secondary_dns_address is defined but ipv6_primary_dns_address is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}]")  
                # Validate ipv4_static_routes
                for index, route in enumerate(lan_vpn.get("ipv4_static_routes", [])):
                    gateway = route.get("gateway", "nexthop")
                    if gateway != "nexthop" and ("next_hops" in route or "next_hops_with_tracker" in route):
                        results.append(f"next_hops list is present but gateway is set to {gateway} in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{index}]")
                    if gateway == "nexthop" and not ("next_hops" in route or "next_hops_with_tracker" in route):
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{index}]")
                    if gateway == "interface" and "static_route_interface" not in route:
                        results.append(f"gateway is set to interface but static_route_interface is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{index}]")
                    if gateway != "interface" and "static_route_interface" in route:
                        results.append(f"static_route_interface is present but gateway is set to {gateway} in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{index}]")
                    if gateway != "null0" and ("administrative_distance" in route or "administrative_distance_variable" in route):
                        results.append(f"administrative_distance is defined but gateway is not set to null0 in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{index}]")
                # Validate ipv6_static_routes
                for index, route in enumerate(lan_vpn.get("ipv6_static_routes", [])):
                    gateway = route.get("gateway", "nexthop")
                    if gateway != "nat" and (route.get("nat") or route.get("nat_variable")):
                        results.append(f"nat option is defined but gateway is not set to nat in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                    if gateway == "nat" and not (route.get("nat") or route.get("nat_variable")):
                        results.append(f"gateway is set to nat but nat option is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                    if gateway != "nexthop" and "next_hops" in route:
                        results.append(f"next_hops list is present but gateway is set to {gateway} in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                    if gateway == "nexthop" and "next_hops" not in route:
                        results.append(f"next_hops list is not present but gateway is set to nexthop in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                    if gateway == "interface" and "static_route_interface" not in route:
                        results.append(f"gateway is set to interface but static_route_interface is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                    if gateway != "interface" and "static_route_interface" in route:
                        results.append(f"static_route_interface is present but gateway is set to {gateway} in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_static_routes[{index}]")
                # Check network and aggregate protocols in ipv4_omp_advertise_routes
                for route_index, route in enumerate(lan_vpn.get("ipv4_omp_advertise_routes", [])):
                    protocol = route.get("protocol")
                    if protocol == "network" and "networks" not in route:
                        results.append(
                            f"'networks' attribute is required for protocol 'network' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_omp_advertise_routes[{route_index}]")
                    elif protocol == "aggregate" and "aggregates" not in route:
                        results.append(
                            f"'aggregates' attribute is required for protocol 'aggregate' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_omp_advertise_routes[{route_index}]")
                    elif protocol != "network" and "networks" in route:
                        results.append(
                            f"'networks' attribute is not allowed for protocol '{protocol}' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_omp_advertise_routes[{route_index}]")
                    elif protocol != "aggregate" and "aggregates" in route:
                        results.append(
                            f"'aggregates' attribute is not allowed for protocol '{protocol}' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_omp_advertise_routes[{route_index}]")
                # Check network and aggregate protocols in ipv6_omp_advertise_routes
                for route_index, route in enumerate(lan_vpn.get("ipv6_omp_advertise_routes", [])):
                    protocol = route.get("protocol")
                    if protocol == "Network" and "networks" not in route:
                        results.append( f"'networks' attribute is required for protocol 'network' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_omp_advertise_routes[{route_index}]")
                    elif protocol == "Aggregate" and "aggregates" not in route:
                        results.append(f"'aggregates' attribute is required for protocol 'aggregate' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_omp_advertise_routes[{route_index}]")
                    elif protocol != "Network" and "networks" in route:
                        results.append(f"'networks' attribute is not allowed for protocol '{protocol}' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_omp_advertise_routes[{route_index}]")
                    elif protocol !=  "Aggregate" and  "aggregates" in route:
                        results.append(f"'aggregates' attribute is not allowed for protocol '{protocol}' in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv6_omp_advertise_routes[{route_index}]")
                    
                # Validate ethernet interfaces
                for ethernet_interface in lan_vpn.get("ethernet_interfaces", []):
                    if ethernet_interface.get("port_channel_member_interface") != True and not any(parameter in ethernet_interface for parameter in ["ipv4_address_type", "ipv4_address_type_variable", "ipv6_address_type", "ipv6_address_type_variable"]):
                        results.append(f"At least one of ['ipv4_address_type', 'ipv6_address_type'] must be defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv4_address_type_variable"):
                        mandatory_parameters = ["ipv4_address_variable", "ipv4_subnet_mask_variable", "ipv4_dhcp_distance_variable"]
                        for param in mandatory_parameters:
                            if param not in ethernet_interface:
                                results.append(f"{param} must be defined when ipv4_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        for secondary_address in ethernet_interface.get("ipv4_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv4_secondary_addresses.address is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                            if secondary_address.get("subnet_mask"):
                                results.append(f"ipv4_secondary_addresses.subnet_mask is not allowed when ipv4_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]") 
                    if ethernet_interface.get("ipv4_address_type") == "static":
                        if "ipv4_dhcp_distance" in ethernet_interface or "ipv4_dhcp_distance_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is static but ipv4_dhcp_distance is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv4_address_type") == "dynamic":
                        if "ipv4_address" in ethernet_interface or "ipv4_address_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_address is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_subnet_mask" in ethernet_interface or "ipv4_subnet_mask_variable" in ethernet_interface:
                            results.append(f"ipv4_address_type is dynamic but static ipv4_subnet_mask is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv4_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv4_secondary_addresses is defined but ipv4_address_type is dynamic in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type_variable"):
                        if "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_variable must be defined when ipv6_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("ipv6_address_type") == "static":
                        if "ipv6_address" not in ethernet_interface and "ipv6_address_variable" not in ethernet_interface:
                            results.append(f"ipv6_address_type is static but ipv6_address is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv6_dynamic_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv6_dynamic_secondary_addresses is defined but ipv6_address_type is static in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv6_address_type") == "dynamic":
                        if "ipv6_address" in ethernet_interface or "ipv6_address_variable" in ethernet_interface:
                            results.append(f"ipv6_address_type is dynamic but static ipv6_address is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if "ipv6_static_secondary_addresses" in ethernet_interface:
                            results.append(f"ipv6_static_secondary_addresses is defined but ipv6_address_type is dynamic in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    elif ethernet_interface.get("ipv6_address_type_variable"):
                        for secondary_address in ethernet_interface.get("ipv6_dynamic_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv6_dynamic_secondary_addresses.address is not allowed when ipv6_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        for secondary_address in ethernet_interface.get("ipv6_static_secondary_addresses", []):
                            if secondary_address.get("address"):
                                results.append(f"ipv6_static_secondary_addresses.address is not allowed when ipv6_address_type_variable is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("autonegotiate") and ethernet_interface.get("speed"):
                        results.append(f"autonegotiate is true but speed is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    for vrrp_group in ethernet_interface.get("ipv4_vrrp_groups", []):
                        if "tloc_preference_change_value" in vrrp_group and not vrrp_group.get("tloc_preference_change"):
                            results.append(f"tloc_preference_change_value is defined but tloc_preference_change is not present or false in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}].ipv4_vrrp_groups")
                    if ethernet_interface.get("port_channel_member_interface"):
                        forbidden_options = ["ipv4_address_type", "ipv6_address_type", "arp_timeout", "arp_entries", "icmp_redirect_disable", "interface_mtu", "ip_directed_broadcast", "ip_mtu", "ipv4_dhcp_helpers", "ipv4_vrrp_groups", "ipv6_vrrp_groups", "mac_address", "shaping_rate", "tcp_mss", "trustsec_enable_enforced_propogation", "trustsec_enable_sgt_propogation", "trustsec_enforced_sgt", "trustsec_propogate", "trustsec_sgt", "xconnect"]
                        for option in forbidden_options:
                            if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                results.append(f"port_channel_member_interface is true but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    if ethernet_interface.get("port_channel_interface"):
                        for option in ["duplex", "media_type", "speed", "mac_address"]:
                            if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                results.append(f"port_channel_interface is true but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                        if ethernet_interface.get("port_channel_subinterface", False) == False:
                            for option in ["port_channel_subinterface_primary_interface_name", "port_channel_subinterface_secondary_interface_name"]:
                                if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                    results.append(f"port_channel_subinterface is false/not set but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                            if ethernet_interface.get("port_channel_mode", "lacp") == "static":
                                forbidden_options = ["port_channel_lacp_fast_switchover", "port_channel_lacp_max_bundle", "port_channel_lacp_min_bundle"]
                                for option in forbidden_options:
                                    if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                        results.append(f"port_channel_mode is static but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                                for member_link in ethernet_interface.get("port_channel_member_links", []):
                                    forbidden_options = ["lacp_mode", "lacp_port_priority", "lacp_rate"]
                                    for option in forbidden_options:
                                        if option in member_link or f"{option}_variable" in member_link:
                                            results.append(f"port_channel_mode is static but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}].port_channel_member_links[{member_link.get('interface_feature_name', '')}]")
                        else:
                            for option in ["port_channel_lacp_fast_switchover", "port_channel_lacp_max_bundle", "port_channel_lacp_min_bundle", "port_channel_load_balance", "port_channel_qos_aggregate", "port_channel_mode", "port_channel_member_links"]:
                                if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                    results.append(f"port_channel_subinterface is true but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                    else:
                        forbidden_options = [
                            "port_channel_lacp_fast_switchover",
                            "port_channel_lacp_max_bundle",
                            "port_channel_lacp_min_bundle",
                            "port_channel_load_balance",
                            "port_channel_qos_aggregate",
                            "port_channel_mode",
                            "port_channel_subinterface",
                            "port_channel_subinterface_primary_interface_name",
                            "port_channel_subinterface_secondary_interface_name",
                            "port_channel_member_links",
                        ]
                        for option in forbidden_options:
                            if option in ethernet_interface or f"{option}_variable" in ethernet_interface:
                                results.append(f"port_channel_interface is false/not set but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('name', '')}]")
                # Validate gre interfaces
                for gre_interface in lan_vpn.get("gre_interfaces", []):
                    # if tunnel_mode is ipv6, one of [tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable, tunnel_source_interface, tunnel_source_interface_variable, tunnel_source_interface_loopback, tunnel_source_interface_loopback_variable], one of [tunnel_destination_ipv6_address, tunnel_destination_ipv6_address_variable] must be defined
                    #    [tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_destination_ipv4_address, tunnel_destination_ipv4_address_variable] should not be defined
                    if gre_interface.get("tunnel_mode", "ipv4") == "ipv6":
                        if not (gre_interface.get("tunnel_source_ipv6_address") or gre_interface.get("tunnel_source_ipv6_address_variable") or gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")):
                            results.append(f"tunnel_mode is ipv6 but no tunnel source is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                        if not (gre_interface.get("tunnel_destination_ipv6_address") or gre_interface.get("tunnel_destination_ipv6_address_variable")):
                            results.append(f"tunnel_mode is ipv6 but no tunnel destination is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                        forbidden_options = ["tunnel_source_ipv4_address", "tunnel_source_ipv4_address_variable", "tunnel_destination_ipv4_address", "tunnel_destination_ipv4_address_variable"]
                        for option in forbidden_options:
                            if option in gre_interface:
                                results.append(f"tunnel_mode is ipv6 but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                    else:
                        # tunnel_mode is ipv4
                        if not (gre_interface.get("tunnel_source_ipv4_address") or gre_interface.get("tunnel_source_ipv4_address_variable") or gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")):
                            results.append(f"tunnel_mode is ipv4 but no tunnel source is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                        if not (gre_interface.get("tunnel_destination_ipv4_address") or gre_interface.get("tunnel_destination_ipv4_address_variable")):
                            results.append(f"tunnel_mode is ipv4 but no tunnel destination is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                        forbidden_options = ["tunnel_source_ipv6_address", "tunnel_source_ipv6_address_variable", "tunnel_destination_ipv6_address", "tunnel_destination_ipv6_address_variable"]
                        for option in forbidden_options:
                            if option in gre_interface:
                                results.append(f"tunnel_mode is ipv4 but {option} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")
                    
                    # if one of [tunnel_source_interface, tunnel_source_interface_variable, tunnel_source_interface_loopback, tunnel_source_interface_loopback_variable] is defined, [tunnel_route_via_loopback, tunnel_route_via_loopback_variable, tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable] should not be defined
                    forbidden_options = ["tunnel_route_via_loopback", "tunnel_route_via_loopback_variable", "tunnel_source_ipv4_address", "tunnel_source_ipv4_address_variable", "tunnel_source_ipv6_address", "tunnel_source_ipv6_address_variable"]
                    if (gre_interface.get("tunnel_source_interface") or gre_interface.get("tunnel_source_interface_variable") or gre_interface.get("tunnel_source_interface_loopback") or gre_interface.get("tunnel_source_interface_loopback_variable")) and any(option in gre_interface for option in forbidden_options):
                        results.append(f"tunnel source is an interface, but tunnel_route_via_loopback or static tunnel source is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].gre_interfaces[{gre_interface.get('name', '')}]")

                # Validate ipsec interfaces
                for ipsec_interface in lan_vpn.get("ipsec_interfaces", []):
                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv4":
                        if not (ipsec_interface.get("ipv4_address", False) or ipsec_interface.get("ipv4_subnet_mask", False) or ipsec_interface.get("ipv4_address_variable", False) or ipsec_interface.get("ipv4_subnet_mask_variable", False)):
                            results.append(f"At least one complete pair must be defined: (ipv4_address + ipv4_subnet_mask) OR (ipv4_address_variable + ipv4_subnet_mask_variable) in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv4_address", False) and not ipsec_interface.get("ipv4_subnet_mask", False):
                            results.append(f"ipv4_address is defined but ipv4_subnet_mask is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        elif ipsec_interface.get("ipv4_address_variable", False) and not ipsec_interface.get("ipv4_subnet_mask_variable", False):
                            results.append(f"ipv4_address_variable is defined but ipv4_subnet_mask_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if (ipsec_interface.get("ipv4_subnet_mask", False) and not ipsec_interface.get("ipv4_address", False)) or (ipsec_interface.get("ipv4_subnet_mask_variable", False) and not ipsec_interface.get("ipv4_address_variable", False)):
                            results.append(f"ipv4_subnet_mask or ipv4_subnet_mask_variable is defined but respective ipv4_address or ipv4_address_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False)):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable which is a mandatory field when tunnel_mode is ipv4, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv4, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False):
                            results.append(f"ipv6_address or ipv6_address_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_mtu", False) or ipsec_interface.get("ipv6_mtu_variable", False):
                            results.append(f"ipv6_mtu or ipv6_mtu_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv6_tcp_mss", False) or ipsec_interface.get("ipv6_tcp_mss_variable", False):
                            results.append(f"ipv6_tcp_mss or ipv6_tcp_mss_variable is defined but tunnel_mode is not ipv6 or ipv4-v6overlay in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                    else:
                        if ipsec_interface.get("ipv4_address", False) or ipsec_interface.get("ipv4_address_variable", False) or ipsec_interface.get("ipv4_subnet_mask", False) or ipsec_interface.get("ipv4_subnet_mask_variable", False):
                            results.append(f"ipv4_address, ipv4_subnet_mask or ipv4_address_variable, ipv4_subnet_mask_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv4_mtu", False) or ipsec_interface.get("ipv4_mtu_variable", False):
                            results.append(f"ipv4_mtu or ipv4_mtu_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("ipv4_tcp_mss", False) or ipsec_interface.get("ipv4_tcp_mss_variable", False):
                            results.append(f"ipv4_tcp_mss or ipv4_tcp_mss_variable is defined but tunnel_mode is not ipv4 in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")

                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv6":
                        if not (ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False)):
                            results.append(f"ipv6_address or ipv6_address_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv6_address", False) or ipsec_interface.get("tunnel_destination_ipv6_address_variable", False)):
                            results.append(f"tunnel_destination_ipv6_address or tunnel_destination_ipv6_address_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv6_address", False) or ipsec_interface.get("tunnel_source_ipv6_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv6_address, tunnel_source_ipv6_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv6, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable is defined but tunnel_mode is not ipv4 or ipv4-v6overlay in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False):
                            results.append(f"tunnel_source_ipv4_address or tunnel_source_ipv4_address_variable is defined but tunnel_mode is not ipv4 or ipv4-v6overlay in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                    else:
                        if ipsec_interface.get("tunnel_destination_ipv6_address", False) or ipsec_interface.get("tunnel_destination_ipv6_address_variable", False):
                            results.append(f"tunnel_destination_ipv6_address or tunnel_destination_ipv6_address_variable is defined but tunnel_mode is not ipv6 in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if ipsec_interface.get("tunnel_source_ipv6_address", False) or ipsec_interface.get("tunnel_source_ipv6_address_variable", False):
                            results.append(f"tunnel_source_ipv6_address or tunnel_source_ipv6_address_variable is defined but tunnel_mode is not ipv6 in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")

                    if ipsec_interface.get("tunnel_mode", "ipv4") == "ipv4-v6overlay":
                        if not (ipsec_interface.get("ipv6_address", False) or ipsec_interface.get("ipv6_address_variable", False)):
                            results.append(f"ipv6_address or ipv6_address_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_destination_ipv4_address", False) or ipsec_interface.get("tunnel_destination_ipv4_address_variable", False)):
                            results.append(f"tunnel_destination_ipv4_address or tunnel_destination_ipv4_address_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")
                        if not (ipsec_interface.get("tunnel_source_ipv4_address", False) or ipsec_interface.get("tunnel_source_ipv4_address_variable", False) or ipsec_interface.get("tunnel_source_interface", False) or ipsec_interface.get("tunnel_source_interface_variable", False)):
                            results.append(f"One of tunnel_source_ipv4_address, tunnel_source_ipv4_address_variable, tunnel_source_interface or tunnel_source_interface_variable which is a mandatory field when tunnel_mode is ipv4-v6overlay, is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipsec_interfaces[{ipsec_interface.get('name')}]")

                nat_pools_present = bool(lan_vpn.get("nat_pools"))
                if lan_vpn.get("nat_port_forwards") and not nat_pools_present:
                    results.append(f"nat_port_forwards is defined but nat_pools is not present in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}]")
                if lan_vpn.get("static_nat_entries") and not nat_pools_present:
                    results.append(f"static_nat_entries is defined but nat_pools is not present in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}]")
                if lan_vpn.get("static_nat_subnets") and not nat_pools_present:
                    results.append(f"static_nat_subnets is defined but nat_pools is not present in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}]")

                # Validate service_routes: sse_instance cannot be configured when service is sig
                for route_index, route in enumerate(lan_vpn.get("service_routes", [])):
                    service = route.get("service") or route.get("service_variable")
                    sse_instance = route.get("sse_instance") or route.get("sse_instance_variable")

                    if service and service.lower() == "sig" and sse_instance:
                        results.append(f"sse_instance is defined but service is set to 'sig' - these are mutually exclusive in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].service_routes[{route_index}]")
                
                # Validate SVI interfaces
                for svi_interface in lan_vpn.get("svi_interfaces", []):
                    for vrrp_group in svi_interface.get("ipv4_vrrp_groups", []):
                        # tloc_preference_change_value should be defined when tloc_preference_change is true
                        if vrrp_group.get("tloc_preference_change", False) == True and "tloc_preference_change_value" not in vrrp_group:
                            results.append(f"tloc_preference_change is true but tloc_preference_change_value is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups[{vrrp_group.get('id', '')}]")
                        # tloc_preference_change_value should not be defined when tloc_preference_change is false or not present
                        elif vrrp_group.get("tloc_preference_change", False) == False and "tloc_preference_change_value" in vrrp_group:
                            results.append(f"tloc_preference_change_value is defined but tloc_preference_change is not present or false in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups[{vrrp_group.get('id', '')}]")
                        
                        # prefix_list should not be defined when track_omp is true
                        if vrrp_group.get("track_omp", False) == True and "prefix_list" in vrrp_group:
                            results.append(f"prefix_list is defined but track_omp is true in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups[{vrrp_group.get('id', '')}]")
                        
                        for tracking_object in vrrp_group.get("tracking_objects", []):
                            # decrement_value should be defined only when action is decrement
                            if tracking_object.get("action") == "decrement" and "decrement_value" not in tracking_object:
                                results.append(f"action is decrement but decrement_value is not defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups[{vrrp_group.get('id', '')}].tracking_objects")
                            elif tracking_object.get("action") != "decrement" and "decrement_value" in tracking_object:
                                results.append(f"decrement_value is defined but action is not set to decrement in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups[{vrrp_group.get('id', '')}].tracking_objects")
            
            # Validate switchport features
            for switchport in feature_profile.get("switchport_features", []):
                for interface_index, interface in enumerate(switchport.get("interfaces", [])):

                    if interface.get("mode", "none") == "access":
                        forbidden_options = ["trunk_allowed_vlans", "trunk_allowed_vlans_variable", "trunk_native_vlan", "trunk_native_vlan_variable"]
                        for option in forbidden_options:
                            if option in interface:
                                results.append(f"interface mode is access, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].switchport_features[{switchport['name']}].interfaces[{interface_index}]")
                    elif interface.get("mode", "none") == "trunk":
                        forbidden_options = ["access_vlan", "access_vlan_variable"]
                        for option in forbidden_options:
                            if option in interface:
                                results.append(f"interface mode is trunk, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].switchport_features[{switchport['name']}].interfaces[{interface_index}]")

                    # [pae_enable, pae_enable_variable, mac_authentication_bypass, mac_authentication_bypass_variable, host_mode, host_mode_variable, enable_periodic_reauth, enable_periodic_reauth_variable, 
                    #  control_direction, control_direction_variable, restricted_vlan, restricted_vlan_variable, guest_vlan, guest_vlan_variable, critical_vlan, critical_vlan_variable,
                    #  enable_voice, enable_voice_variable, port_control, port_control_variable] should not be defined, if enable_dot1x is false
                    if not interface.get("enable_dot1x", True):
                        forbidden_options = [
                            "pae_enable", "pae_enable_variable", "mac_authentication_bypass", "mac_authentication_bypass_variable",
                            "host_mode", "host_mode_variable", "enable_periodic_reauth", "enable_periodic_reauth_variable",
                            "control_direction", "control_direction_variable", "restricted_vlan", "restricted_vlan_variable",
                            "guest_vlan", "guest_vlan_variable", "critical_vlan", "critical_vlan_variable",
                            "enable_voice", "enable_voice_variable", "port_control", "port_control_variable"
                        ]
                        for option in forbidden_options:
                            if option in interface:
                                results.append(f"enable_dot1x is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].switchport_features[{switchport['name']}].interfaces[{interface_index}]")
                    
                    # inactivity or inactivity_variable, reauthentication or reauthentication_variable should not be defined, if enable_periodic_reauth is false
                    if not interface.get("enable_periodic_reauth", False):
                        forbidden_options = ["inactivity", "inactivity_variable", "reauthentication", "reauthentication_variable"]
                        for option in forbidden_options:
                            if option in interface:
                                results.append(f"enable_periodic_reauth is false, but {option} is defined in sdwan.feature_profiles.service_profiles[{feature_profile['name']}].switchport_features[{switchport['name']}].interfaces[{interface_index}]")

        return results
