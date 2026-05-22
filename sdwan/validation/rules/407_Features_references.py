class Rule:
    id = "407"
    description = "Validate features references"
    severity = "HIGH"

    @classmethod
    def verify_acl_references(cls, inventory):
        results = []
        feature_profiles_types = ["service_profiles", "transport_profiles"]
        acls_definition = ["ipv4_acls", "ipv6_acls"]
        acls_references = ["ipv4_ingress_acl", "ipv4_egress_acl", "ipv6_ingress_acl", "ipv6_egress_acl"]

        for feature_profile_type in feature_profiles_types:
             
            for profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get(feature_profile_type, []):
                defined_acls = {}
                # Collect defined ACLs
                for acl_def in acls_definition:
                    defined_acls[acl_def] = []
                    for acl in profile.get(acl_def, []):
                        defined_acls[acl_def].append(acl["name"])

                # Validate ACL references
                if feature_profile_type == "transport_profiles":
                    for interface in profile.get("wan_vpn", {}).get("cellular_interfaces", []):
                            for acl_ref in acls_references:
                                if interface.get(acl_ref, None):
                                    acl_type = "ipv4_acls" if "ipv4" in acl_ref else "ipv6_acls"
                                    if interface.get(acl_ref) not in defined_acls[acl_type]:
                                        results.append(f"{acl_ref} {interface.get(acl_ref)} is not defined in sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].{acl_type}, but is referenced in the sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].wan_vpn.cellular_interfaces[{interface['name']}]")
                    for interface in profile.get("wan_vpn", {}).get("ethernet_interfaces", []):
                            for acl_ref in acls_references:
                                if interface.get(acl_ref, None):
                                    acl_type = "ipv4_acls" if "ipv4" in acl_ref else "ipv6_acls"
                                    if interface.get(acl_ref) not in defined_acls[acl_type]:
                                        results.append(f"{acl_ref} {interface.get(acl_ref)} is not defined in sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].{acl_type}, but is referenced in the sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].wan_vpn.ethernet_interfaces[{interface['name']}]")
                elif feature_profile_type == "service_profiles":
                    for lan_vpn in profile.get("lan_vpns", []):
                        for interface in lan_vpn.get("ethernet_interfaces", []):
                            for acl_ref in acls_references:
                                if interface.get(acl_ref, None):
                                    acl_type = "ipv4_acls" if "ipv4" in acl_ref else "ipv6_acls"
                                    if interface.get(acl_ref) not in defined_acls[acl_type]:
                                        results.append(f"{acl_ref} {interface.get(acl_ref)} is not defined in sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].{acl_type}, but is referenced in the sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].lan_vpns[{lan_vpn['name']}].ethernet_interfaces[{interface['name']}]")
                        for svi_interface in lan_vpn.get("svi_interfaces", []):
                            for acl_ref in acls_references:
                                if svi_interface.get(acl_ref, None):
                                    acl_type = "ipv4_acls" if "ipv4" in acl_ref else "ipv6_acls"
                                    if svi_interface.get(acl_ref) not in defined_acls[acl_type]:
                                        results.append(f"{acl_ref} {svi_interface.get(acl_ref)} is not defined in sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].{acl_type}, but is referenced in the sdwan.feature_profiles.{feature_profile_type}[{profile['name']}].lan_vpns[{lan_vpn['name']}].svi_interfaces[{svi_interface.get('name', '')}]")
                        
        return results

    @classmethod
    def verify_application_priority_policy_object_references(cls, inventory):
        """Validate that policy objects referenced in Application Priority Traffic Policies exist"""
        results = []
        policy_object_profile = inventory.get("sdwan", {}).get("feature_profiles", {}).get("policy_object_profile", {})
        defined_policy_objects = {
            "application_lists": [obj["name"] for obj in policy_object_profile.get("application_lists", [])],
            "ipv4_data_prefix_lists": [obj["name"] for obj in policy_object_profile.get("ipv4_data_prefix_lists", [])],
            "ipv6_data_prefix_lists": [obj["name"] for obj in policy_object_profile.get("ipv6_data_prefix_lists", [])],
            "sla_classes": [obj["name"] for obj in policy_object_profile.get("sla_classes", [])],
            "preferred_color_groups": [obj["name"] for obj in policy_object_profile.get("preferred_color_groups", [])],
            "tloc_lists": [obj["name"] for obj in policy_object_profile.get("tloc_lists", [])],
            "policers": [obj["name"] for obj in policy_object_profile.get("policers", [])],
            "forwarding_classes": [obj["name"] for obj in policy_object_profile.get("forwarding_classes", [])]
        }

        # Validate references in Application Priority Traffic Policies
        for app_priority_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("application_priority_profiles", []):
            profile_name = app_priority_profile.get("name", "unknown")

            for traffic_policy in app_priority_profile.get("traffic_policies", []):
                policy_name = traffic_policy.get("name", "unknown")
                for seq_idx, sequence in enumerate(traffic_policy.get("sequences", [])):
                    seq_name = sequence.get("sequence_name", seq_idx)
                    seq_path = f"sdwan.feature_profiles.application_priority_profiles[{profile_name}].traffic_policies[{policy_name}].sequences[{seq_name}]"
                    match_entries = sequence.get("match_entries", {})
                    actions = sequence.get("actions", {})
                    # Validate application list references in match entries
                    for field in ["application_list", "dns_application_list", "saas_application_list"]:
                        if match_entries.get(field):
                            ref_name = match_entries[field]
                            if ref_name not in defined_policy_objects["application_lists"]:
                                results.append(
                                    f"Application list '{ref_name}' is referenced in {seq_path}.match_entries.{field}, "
                                    f"but is not defined in sdwan.feature_profiles.policy_object_profile.application_lists"
                                )
                    # Validate IPv4 data prefix list references
                    for field in ["source_data_ipv4_prefix_list", "destination_data_ipv4_prefix_list"]:
                        if match_entries.get(field):
                            ref_name = match_entries[field]
                            if ref_name not in defined_policy_objects["ipv4_data_prefix_lists"]:
                                results.append(
                                    f"IPv4 data prefix list '{ref_name}' is referenced in {seq_path}.match_entries.{field}, "
                                    f"but is not defined in sdwan.feature_profiles.policy_object_profile.ipv4_data_prefix_lists"
                                )
                    # Validate IPv6 data prefix list references
                    for field in ["source_data_ipv6_prefix_list", "destination_data_ipv6_prefix_list"]:
                        if match_entries.get(field):
                            ref_name = match_entries[field]
                            if ref_name not in defined_policy_objects["ipv6_data_prefix_lists"]:
                                results.append(
                                    f"IPv6 data prefix list '{ref_name}' is referenced in {seq_path}.match_entries.{field}, "
                                    f"but is not defined in sdwan.feature_profiles.policy_object_profile.ipv6_data_prefix_lists"
                                )
                    # Validate SLA class and preferred color group references in SLA class (single object)
                    sla_class = actions.get("sla_class", {})
                    if sla_class.get("sla_class_list"):
                        ref_name = sla_class["sla_class_list"]
                        if ref_name not in defined_policy_objects["sla_classes"]:
                            results.append(
                                f"SLA class '{ref_name}' is referenced in {seq_path}.actions.sla_class.sla_class_list, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.sla_classes"
                            )
                    if sla_class.get("preferred_color_group"):
                        ref_name = sla_class["preferred_color_group"]
                        if ref_name not in defined_policy_objects["preferred_color_groups"]:
                            results.append(
                                f"Preferred color group '{ref_name}' is referenced in {seq_path}.actions.sla_class.preferred_color_group, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.preferred_color_groups"
                            )
                    # Validate action-level policy object references
                    if actions.get("preferred_color_group"):
                        ref_name = actions["preferred_color_group"]
                        if ref_name not in defined_policy_objects["preferred_color_groups"]:
                            results.append(
                                f"Preferred color group '{ref_name}' is referenced in {seq_path}.actions.preferred_color_group, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.preferred_color_groups"
                            )
                    if actions.get("policer_list"):
                        ref_name = actions["policer_list"]
                        if ref_name not in defined_policy_objects["policers"]:
                            results.append(
                                f"Policer '{ref_name}' is referenced in {seq_path}.actions.policer_list, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.policers"
                            )
                    if actions.get("forwarding_class"):
                        ref_name = actions["forwarding_class"]
                        if ref_name not in defined_policy_objects["forwarding_classes"]:
                            results.append(
                                f"Forwarding class '{ref_name}' is referenced in {seq_path}.actions.forwarding_class, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.forwarding_classes"
                            )
                    # Validate TLOC list references in service action
                    service = actions.get("service", {})
                    if service.get("tloc_list"):
                        ref_name = service["tloc_list"]
                        if ref_name not in defined_policy_objects["tloc_lists"]:
                            results.append(
                                f"TLOC list '{ref_name}' is referenced in {seq_path}.actions.service.tloc_list, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.tloc_lists"
                            )
                    # Validate TLOC list references in service_chain action
                    service_chain = actions.get("service_chain", {})
                    if service_chain.get("tloc_list"):
                        ref_name = service_chain["tloc_list"]
                        if ref_name not in defined_policy_objects["tloc_lists"]:
                            results.append(
                                f"TLOC list '{ref_name}' is referenced in {seq_path}.actions.service_chain.tloc_list, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.tloc_lists"
                            )
                    # Validate TLOC list references in direct tloc action
                    tloc = actions.get("tloc", {})
                    if tloc.get("list"):
                        ref_name = tloc["list"]
                        if ref_name not in defined_policy_objects["tloc_lists"]:
                            results.append(
                                f"TLOC list '{ref_name}' is referenced in {seq_path}.actions.tloc.list, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.tloc_lists"
                            )

        return results

    @classmethod
    def verify_ngfw_security_policy_object_references(cls, inventory):
        """Validate that policy objects referenced in NGFW Security profiles exist"""
        results = []
        policy_object_profile = inventory.get("sdwan", {}).get("feature_profiles", {}).get("policy_object_profile", {})
        defined_policy_objects = {
            "security_local_application_lists": [obj["name"] for obj in policy_object_profile.get("security_local_application_lists", [])],
            "security_data_ipv4_prefix_lists": [obj["name"] for obj in policy_object_profile.get("security_data_ipv4_prefix_lists", [])],
            "security_fqdn_lists": [obj["name"] for obj in policy_object_profile.get("security_fqdn_lists", [])],
            "security_geo_location_lists": [obj["name"] for obj in policy_object_profile.get("security_geo_location_lists", [])],
            "security_port_lists": [obj["name"] for obj in policy_object_profile.get("security_port_lists", [])],
            "security_protocol_lists": [obj["name"] for obj in policy_object_profile.get("security_protocol_lists", [])],
            "security_advanced_inspection_profiles": [obj["name"] for obj in policy_object_profile.get("security_advanced_inspection_profiles", [])],
            "security_zones": [obj["name"] for obj in policy_object_profile.get("security_zones", [])],
        }
        _zone_enum_literals = {"self", "no_zone", "untrusted"}

        for ngfw_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("ngfw_security_profiles", []):
            profile_name = ngfw_profile.get("name", "unknown")
            profile_path = f"sdwan.feature_profiles.ngfw_security_profiles[{profile_name}]"

            # Validate settings references
            settings = ngfw_profile.get("settings", {})
            if settings:
                aip = settings.get("advanced_inspection_profile")
                if aip and aip not in defined_policy_objects["security_advanced_inspection_profiles"]:
                    results.append(
                        f"Advanced inspection profile '{aip}' is referenced in "
                        f"{profile_path}.settings.advanced_inspection_profile, "
                        f"but is not defined in sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles"
                    )
            # Validate policy references
            for policy in ngfw_profile.get("policies", []):
                policy_name = policy.get("name", "unknown")
                policy_path = f"{profile_path}.policies[{policy_name}]"
                # Validate zone references
                source_zone = policy.get("source_zone")
                if source_zone and source_zone not in _zone_enum_literals:
                    if source_zone not in defined_policy_objects["security_zones"]:
                        results.append(
                            f"Security zone '{source_zone}' is referenced in "
                            f"{policy_path}.source_zone, "
                            f"but is not defined in sdwan.feature_profiles.policy_object_profile.security_zones"
                        )
                for dest_zone in policy.get("destination_zones", []):
                    if dest_zone not in _zone_enum_literals:
                        if dest_zone not in defined_policy_objects["security_zones"]:
                            results.append(
                                f"Security zone '{dest_zone}' is referenced in "
                                f"{policy_path}.destination_zones, "
                                f"but is not defined in sdwan.feature_profiles.policy_object_profile.security_zones"
                            )
                # Validate sequence references
                for seq_idx, sequence in enumerate(policy.get("sequences", [])):
                    seq_name = sequence.get("sequence_name", seq_idx)
                    seq_path = f"{policy_path}.sequences[{seq_name}]"
                    match_entries = sequence.get("match_entries", {})
                    actions = sequence.get("actions", {})
                    # Scalar match entry references
                    app_list = match_entries.get("application_list")
                    if app_list and app_list not in defined_policy_objects["security_local_application_lists"]:
                        results.append(
                            f"Security local application list '{app_list}' is referenced in "
                            f"{seq_path}.match_entries.application_list, "
                            f"but is not defined in sdwan.feature_profiles.policy_object_profile.security_local_application_lists"
                        )
                    # List match entry references
                    list_ref_fields = {
                        "source_data_ipv4_prefix_lists": "security_data_ipv4_prefix_lists",
                        "destination_data_ipv4_prefix_lists": "security_data_ipv4_prefix_lists",
                        "destination_fqdn_lists": "security_fqdn_lists",
                        "source_geo_location_lists": "security_geo_location_lists",
                        "destination_geo_location_lists": "security_geo_location_lists",
                        "source_port_lists": "security_port_lists",
                        "destination_port_lists": "security_port_lists",
                        "protocol_name_lists": "security_protocol_lists",
                    }
                    for field, obj_type in list_ref_fields.items():
                        for ref_name in match_entries.get(field, []):
                            if ref_name not in defined_policy_objects[obj_type]:
                                results.append(
                                    f"Policy object '{ref_name}' is referenced in "
                                    f"{seq_path}.match_entries.{field}, "
                                    f"but is not defined in sdwan.feature_profiles.policy_object_profile.{obj_type}"
                                )
                    # Action references
                    aip = actions.get("advanced_inspection_profile")
                    if aip and aip not in defined_policy_objects["security_advanced_inspection_profiles"]:
                        results.append(
                            f"Advanced inspection profile '{aip}' is referenced in "
                            f"{seq_path}.actions.advanced_inspection_profile, "
                            f"but is not defined in sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles"
                        )

        return results

    @classmethod
    def match(cls, inventory):
        results = []
        for service_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            defined_elements = {}
            feature_types = ["bgp_features", "dhcp_servers", "eigrp_features", "ipv4_trackers", "ipv4_tracker_groups", "multicast_features", "route_policies", "object_trackers", "object_tracker_groups", "ospf_features", "ospfv3_ipv4_features", "ospfv3_ipv6_features"]
            # Check which elements are defined
            for feature_type in feature_types:
                defined_elements[feature_type] = []
                for element in service_profile.get(feature_type, []):
                    defined_elements[feature_type].append(element["name"])
            # Validate route policy references in bgp_features
            for bgp_feature in service_profile.get("bgp_features", []):
                for ipv4_neighbor in bgp_feature.get("ipv4_neighbors", []):
                    for af in ipv4_neighbor.get("address_families", []):
                        if af.get("route_policy_in") and af["route_policy_in"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_in']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_neighbors[{ipv4_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                        if af.get("route_policy_out") and af["route_policy_out"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_out']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_neighbors[{ipv4_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                if bgp_feature.get("ipv4_table_map_route_policy") and bgp_feature["ipv4_table_map_route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{bgp_feature['ipv4_table_map_route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_table_map_route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for redistribute in bgp_feature.get("ipv4_redistributes", []):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_redistributes, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for ipv6_neighbor in bgp_feature.get("ipv6_neighbors", []):
                    for af in ipv6_neighbor.get("address_families", []):
                        if af.get("route_policy_in") and af["route_policy_in"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_in']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_neighbors[{ipv6_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                        if af.get("route_policy_out") and af["route_policy_out"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_out']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_neighbors[{ipv6_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                if bgp_feature.get("ipv6_table_map_route_policy") and bgp_feature["ipv6_table_map_route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{bgp_feature['ipv6_table_map_route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_table_map_route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for redistribute in bgp_feature.get("ipv6_redistributes", []):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_redistributes, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
            # Validate route policy references in eigrp_features
            for eigrp_feature in service_profile.get("eigrp_features", []):
                if eigrp_feature.get("route_policy") and eigrp_feature["route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{eigrp_feature['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].eigrp_features[{eigrp_feature['name']}].route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for index, redistribute in enumerate(eigrp_feature.get("redistributes", [])):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].eigrp_features[{eigrp_feature['name']}].redistributes[{index}], but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
            # Validate route policy references in ospf_features
            for ospf_feature in service_profile.get("ospf_features", []):
                if ospf_feature.get("route_policy") and ospf_feature["route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{ospf_feature['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospf_features[{ospf_feature['name']}].route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for index, redistribute in enumerate(ospf_feature.get("redistributes", [])):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospf_features[{ospf_feature['name']}].redistributes[{index}], but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
            # Validate route policy references in ospfv3_ipv4_features
            for ospfv3_ipv4_feature in service_profile.get("ospfv3_ipv4_features", []):
                if ospfv3_ipv4_feature.get("route_policy") and ospfv3_ipv4_feature["route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{ospfv3_ipv4_feature['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv4_features[{ospfv3_ipv4_feature['name']}].route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for index, redistribute in enumerate(ospfv3_ipv4_feature.get("redistributes", [])):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv4_features[{ospfv3_ipv4_feature['name']}].redistributes[{index}], but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
            # Validate route policy references in ospfv3_ipv6_features
            for ospfv3_feature in service_profile.get("ospfv3_ipv6_features", []):
                if ospfv3_feature.get("route_policy") and ospfv3_feature["route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{ospfv3_feature['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv6_features[{ospfv3_feature['name']}].route_policy, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
                for index, redistribute in enumerate(ospfv3_feature.get("redistributes", [])):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv6_features[{ospfv3_feature['name']}].redistributes[{index}], but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].route_policies")
            for lan_vpn in service_profile.get("lan_vpns", []):
                # Validate tracker references in lan_vpns static routes 
                for route in lan_vpn.get("ipv4_static_routes", []):
                    for nh in route.get("next_hops_with_tracker", []):
                        if nh.get("tracker") and nh.get("tracker") not in defined_elements["ipv4_trackers"] and nh.get("tracker") not in defined_elements["ipv4_tracker_groups"]:
                            results.append(f"IPv4 Tracker (Group) {nh['tracker']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ipv4_static_routes[{route.get('network_address', '')}].next_hops_with_tracker[{nh.get('address', '')}]")
                # Validate route_policy in OMP advertise routes (IPv4 and IPv6)
                for route_type in ["ipv4_omp_advertise_routes", "ipv6_omp_advertise_routes"]:
                    for protocol in lan_vpn.get(route_type, []):
                        if protocol.get("protocol") in ["network", "aggregate", "Network", "Aggregate"]:
                            continue
                        if "route_policy" in protocol and protocol["route_policy"] not in defined_elements["route_policies"]:
                            results.append(
                                f"Route Policy {protocol['route_policy']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].{route_type}[{protocol.get('protocol', '')}]")
                # Validate route_policy
                for leak_block in ["route_leaks_to_global", "route_leaks_from_global", "route_leaks_from_service"]:
                    for leak in lan_vpn.get(leak_block, []):
                        if "route_policy" in leak and leak["route_policy"] not in defined_elements["route_policies"]:
                            results.append(
                                f"Route Policy {leak['route_policy']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].{leak_block}" )
                        for rd in leak.get("redistributions", []):
                            if "route_policy" in rd and rd["route_policy"] not in defined_elements["route_policies"]:
                                results.append(
                                    f"Route Policy {rd['route_policy']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                    f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].{leak_block}[redistributions]")   
                # Validate tracker_object (group) references in nat_pools and static_nat
                for tracker_block in ["nat_pools", "static_nat_entries"]:
                    for item in lan_vpn.get(tracker_block, []):
                        if "tracker_object" in item and item["tracker_object"] not in defined_elements["object_trackers"] and item["tracker_object"] not in defined_elements["object_tracker_groups"]:
                            results.append(
                                f"Object Tracker (Group) {item['tracker_object']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].{tracker_block}")
                # Validate tracker references in ethernet interfaces
                for ethernet_interface in lan_vpn.get("ethernet_interfaces", []):
                    if ethernet_interface.get("ipv4_tracker") and ethernet_interface["ipv4_tracker"] not in defined_elements["ipv4_trackers"]:
                        results.append(
                            f"IPv4 Tracker {ethernet_interface['ipv4_tracker']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ipv4_trackers, "
                            f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('interface_name', '')}].ipv4_tracker")
                    if ethernet_interface.get("ipv4_tracker_group") and ethernet_interface["ipv4_tracker_group"] not in defined_elements["ipv4_tracker_groups"]:
                        results.append(
                            f"IPv4 Tracker Group {ethernet_interface['ipv4_tracker_group']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ipv4_tracker_groups, "
                            f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('interface_name', '')}].ipv4_tracker_group")
                    for vrrp_group in ethernet_interface.get("ipv4_vrrp_groups", []):
                        for tracking_object in vrrp_group.get("tracking_objects", []):
                            if "tracker_object" in tracking_object:
                                if tracking_object["tracker_object"] not in defined_elements["object_trackers"] and tracking_object["tracker_object"] not in defined_elements["object_tracker_groups"]:
                                    results.append(
                                        f"Object Tracker (Group) {tracking_object['tracker_object']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                        f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ethernet_interfaces[{ethernet_interface.get('interface_name', '')}].ipv4_vrrp_groups.tracking_objects")
                                            # Validate BGP reference in WAN VPN
                # Validate routing protocol references
                attached_bgp = lan_vpn.get("bgp", {})
                if attached_bgp and attached_bgp not in defined_elements["bgp_features"]:
                    results.append(f"BGP feature '{attached_bgp}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].bgp, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].bgp_features")
                attached_eigrp = lan_vpn.get("eigrp", {})
                if attached_eigrp and attached_eigrp not in defined_elements["eigrp_features"]:
                    results.append(f"EIGRP feature '{attached_eigrp}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].eigrp, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].eigrp_features")
                attached_multicast = lan_vpn.get("multicast", {})
                if attached_multicast and attached_multicast not in defined_elements["multicast_features"]:
                    results.append(f"Multicast feature '{attached_multicast}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].multicast, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].multicast_features")
                attached_ospf = lan_vpn.get("ospf", {})
                if attached_ospf and attached_ospf not in defined_elements["ospf_features"]:
                    results.append(f"OSPF feature '{attached_ospf}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ospf, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospf_features")
                attached_ospfv3_ipv6 = lan_vpn.get("ospfv3_ipv6", {})
                if attached_ospfv3_ipv6 and attached_ospfv3_ipv6 not in defined_elements["ospfv3_ipv6_features"]:
                    results.append(f"OSPFv3 IPv6 feature '{attached_ospfv3_ipv6}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ospfv3_ipv6, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv6_features")
                attached_ospfv3_ipv4 = lan_vpn.get("ospfv3_ipv4", {})
                if attached_ospfv3_ipv4 and attached_ospfv3_ipv4 not in defined_elements["ospfv3_ipv4_features"]:
                    results.append(f"OSPFv3 IPv4 feature '{attached_ospfv3_ipv4}' is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].ospfv3_ipv4, but is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}].ospfv3_ipv4_features")
                
                # Validate SVI interfaces references
                for svi_interface in lan_vpn.get("svi_interfaces", []):
                    # Validate tracker references
                    for vrrp_group in svi_interface.get("ipv4_vrrp_groups", []):
                        for tracking_object in vrrp_group.get("tracking_objects", []):
                            if "tracker_object" in tracking_object:
                                if tracking_object.get("tracker_object") not in defined_elements["object_trackers"] and tracking_object.get("tracker_object") not in defined_elements["object_tracker_groups"]:
                                    results.append(
                                        f"Object Tracker (Group) {tracking_object['tracker_object']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                                        f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].ipv4_vrrp_groups.tracking_objects")
                    # Validate DHCP server references
                    if svi_interface.get("dhcp_server") and svi_interface["dhcp_server"] not in defined_elements["dhcp_servers"]:
                        results.append(
                            f"DHCP Server {svi_interface['dhcp_server']} is not defined in sdwan.feature_profiles.service_profiles[{service_profile['name']}], "
                            f"but is referenced in sdwan.feature_profiles.service_profiles[{service_profile['name']}].lan_vpns[{lan_vpn.get('name', '')}].svi_interfaces[{svi_interface.get('name', '')}].dhcp_server")

        # Validate transport profiles
        for transport_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("transport_profiles", []):
            defined_elements = {}
            feature_types = ["bgp_features", "ipv4_trackers", "ipv4_tracker_groups", "ipv6_trackers", "ipv6_tracker_groups", "ospf_features", "route_policies"]
            # Check which elements are defined
            for feature_type in feature_types:
                defined_elements[feature_type] = []
                for element in transport_profile.get(feature_type, []):
                    defined_elements[feature_type].append(element["name"])
            # Validate route policy references in bgp_features
            for bgp_feature in transport_profile.get("bgp_features", []):
                for ipv4_neighbor in bgp_feature.get("ipv4_neighbors", []):
                    for af in ipv4_neighbor.get("address_families", []):
                        if af.get("route_policy_in") and af["route_policy_in"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_in']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_neighbors[{ipv4_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                        if af.get("route_policy_out") and af["route_policy_out"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_out']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_neighbors[{ipv4_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                if bgp_feature.get("ipv4_table_map_route_policy") and bgp_feature["ipv4_table_map_route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{bgp_feature['ipv4_table_map_route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_table_map_route_policy, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                for redistribute in bgp_feature.get("ipv4_redistributes", []):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv4_redistributes, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                for ipv6_neighbor in bgp_feature.get("ipv6_neighbors", []):
                    for af in ipv6_neighbor.get("address_families", []):
                        if af.get("route_policy_in") and af["route_policy_in"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_in']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_neighbors[{ipv6_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                        if af.get("route_policy_out") and af["route_policy_out"] not in defined_elements["route_policies"]:
                            results.append(f"Route policy '{af['route_policy_out']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_neighbors[{ipv6_neighbor['name']}].address_families, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                if bgp_feature.get("ipv6_table_map_route_policy") and bgp_feature["ipv6_table_map_route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{bgp_feature['ipv6_table_map_route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_table_map_route_policy, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                for redistribute in bgp_feature.get("ipv6_redistributes", []):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features[{bgp_feature['name']}].ipv6_redistributes, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
            # Validate route policy references in ospf_features
            for ospf_feature in transport_profile.get("ospf_features", []):
                if ospf_feature.get("route_policy") and ospf_feature["route_policy"] not in defined_elements["route_policies"]:
                    results.append(f"Route policy '{ospf_feature['route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ospf_features[{ospf_feature['name']}].route_policy, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
                for index, redistribute in enumerate(ospf_feature.get("redistributes", [])):
                    if redistribute.get("route_policy") and redistribute["route_policy"] not in defined_elements["route_policies"]:
                        results.append(f"Route policy '{redistribute['route_policy']}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ospf_features[{ospf_feature['name']}].redistributes[{index}], but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].route_policies")
            # Validate references in wan_vpn
            wan_vpn = transport_profile.get("wan_vpn", {})
            if wan_vpn:
                # Validate BGP reference in WAN VPN
                attached_bgp = wan_vpn.get("bgp", {})
                if attached_bgp and attached_bgp not in defined_elements["bgp_features"]:
                    results.append(f"BGP feature '{attached_bgp}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.bgp, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].bgp_features")
                # Validate OSPF reference in WAN VPN
                attached_ospf = wan_vpn.get("ospf", {})
                if attached_ospf and attached_ospf not in defined_elements["ospf_features"]:
                    results.append(f"OSPF feature '{attached_ospf}' is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.ospf, but is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ospf_features")
            
            # Validate references in wan_vpn cellular_interfaces
            for cellular_interface in transport_profile.get("wan_vpn", {}).get("cellular_interfaces", []):
                if cellular_interface.get("ipv4_tracker") and cellular_interface["ipv4_tracker"] not in defined_elements["ipv4_trackers"]:
                    results.append(
                        f"IPv4 Tracker {cellular_interface['ipv4_tracker']} is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ipv4_trackers, "
                        f"but is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name', '')}].ipv4_tracker")
                
                if cellular_interface.get("ipv4_tracker_group") and cellular_interface["ipv4_tracker_group"] not in defined_elements["ipv4_tracker_groups"]:
                    results.append(
                        f"IPv4 Tracker Group {cellular_interface['ipv4_tracker_group']} is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ipv4_tracker_groups, "
                        f"but is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.cellular_interfaces[{cellular_interface.get('name', '')}].ipv4_tracker_group")
            
            # Validate references in wan_vpn ethernet interfaces
            for interface in transport_profile.get("wan_vpn", {}).get("ethernet_interfaces", []):
                for feature_type in feature_types:
                    if interface.get(feature_type) and interface.get(feature_type) not in defined_elements[feature_type]:
                        results.append(f"{feature_type} {interface.get(feature_type)} is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].{feature_type}s, but is referenced in the sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.ethernet_interfaces[{interface['name']}]")
            
            # Validate references in wan_vpn gre_interfaces
            for gre_interface in transport_profile.get("wan_vpn", {}).get("gre_interfaces", []):
                if gre_interface.get("ipv4_tracker") and gre_interface["ipv4_tracker"] not in defined_elements["ipv4_trackers"]:
                    results.append(
                        f"IPv4 Tracker {gre_interface['ipv4_tracker']} is not defined in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].ipv4_trackers, "
                        f"but is referenced in sdwan.feature_profiles.transport_profiles[{transport_profile['name']}].wan_vpn.gre_interfaces[{gre_interface.get('name', '')}].ipv4_tracker")

        results += cls.verify_acl_references(inventory)
        results += cls.verify_application_priority_policy_object_references(inventory)
        results += cls.verify_ngfw_security_policy_object_references(inventory)

        return results

