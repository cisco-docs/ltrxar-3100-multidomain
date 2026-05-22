class Rule:
    id = "418"
    description = "Validate application priority profile features (QoS and Traffic Policy)"
    severity = "HIGH"
    #########################################################################################################################################
    # Application Priority Profile Validation
    # Validates both QoS policies and Traffic Policies within Application Priority profiles
    # - QoS: Queue assignments, bandwidth allocation, drop types
    # - Traffic Policy: Complex dependencies, protocol constraints, ICMP/next_hop requirements etc
    #########################################################################################################################################
    # ============================================================================
    # QoS Policy Validations
    # ============================================================================

    @classmethod
    def validate_qos_policies(cls, feature_profile, forwarding_classes, results):
        """Validate QoS policy configurations"""
        for qos_policy in feature_profile.get("qos_policies", []):
            # Get queue numbers for all forwarding classes used in this QoS policy
            used_queues = {}
            bandwidth_sum = 0

            for index, scheduler in enumerate(qos_policy.get("qos_schedulers", [])):
                fc_name = scheduler.get("forwarding_class")
                queue = forwarding_classes.get(fc_name)
                bandwidth_sum += scheduler.get("bandwidth_percent", 0)
                if fc_name in forwarding_classes:
                    used_queues.setdefault(queue, []).append(fc_name)
                if queue == 0:
                    # queue 0 can only use drops type tail-drop
                    if scheduler.get("drops") != "tail-drop":
                        results.append(
                            f"Forwarding class {fc_name} uses queue 0 but drops type is not tail-drop "
                            f"in sdwan.feature_profiles.application_priority_profiles[{feature_profile['name']}]"
                            f".qos_policies[{qos_policy['name']}].qos_schedulers[{index}]"
                        )
            # Check if any queue number is used by more than one forwarding class
            for queue, classes in used_queues.items():
                if len(classes) > 1:
                    results.append(
                        f"Forwarding classes {classes} share the same queue number "
                        f"in sdwan.feature_profiles.application_priority_profiles[{feature_profile['name']}]"
                        f".qos_policies[{qos_policy['name']}].qos_schedulers"
                    )

            if bandwidth_sum != 100:
                results.append(
                    f"The sum of bandwidth_percent for all qos_schedulers must equal 100, but it is {bandwidth_sum} "
                    f"in sdwan.feature_profiles.application_priority_profiles[{feature_profile['name']}]"
                    f".qos_policies[{qos_policy['name']}].qos_schedulers"
                )
    # ============================================================================
    # Traffic Policy Validations 
    # ============================================================================

    @classmethod
    def validate_next_hop_dependencies(cls, sequence, seq_path):
        """Validate next_hop protocol matching and loose dependency requirements"""
        results = []
        protocol = sequence.get("protocol", "ipv4")
        actions = sequence.get("actions", {})
        if "next_hop_ipv4" in actions:
            if protocol != "ipv4":
                results.append(f"'next_hop_ipv4' requires 'protocol' to be 'ipv4' (current: '{protocol}') in {seq_path}")
        if "next_hop_ipv6" in actions:
            if protocol != "ipv6":
                results.append(f"'next_hop_ipv6' requires 'protocol' to be 'ipv6' (current: '{protocol}') in {seq_path}")
        if actions.get("next_hop_loose"):
            if "next_hop_ipv4" not in actions and "next_hop_ipv6" not in actions:
                results.append(f"'next_hop_loose' requires either 'next_hop_ipv4' or 'next_hop_ipv6' in {seq_path}")

        return results

    @classmethod
    def validate_icmp_protocol_dependency(cls, sequence, seq_path):
        """Validate that ICMP messages match sequence protocol and protocol number"""
        results = []
        protocol = sequence.get("protocol", "ipv4")
        match_entries = sequence.get("match_entries", {})
        protocols = match_entries.get("protocols", [])
        # icmp_messages requires protocol=ipv4 AND protocols contains "1"
        if "icmp_messages" in match_entries:
            if protocol not in ["ipv4", "all"]:
                results.append(f"'icmp_messages' requires 'protocol' to be 'ipv4' or 'all' (current: '{protocol}') in {seq_path}")
            if "1" not in protocols and 1 not in protocols:
                results.append(f"'icmp_messages' requires 'protocols' to contain '1' (ICMP protocol number) in {seq_path}")
        # icmp6_messages requires protocol=ipv6 AND protocols contains "58"
        if "icmp6_messages" in match_entries:
            if protocol not in ["ipv6", "all"]:
                results.append(f"'icmp6_messages' requires 'protocol' to be 'ipv6' or 'all' (current: '{protocol}') in {seq_path}")
            if "58" not in protocols and 58 not in protocols:
                results.append(f"'icmp6_messages' requires 'protocols' to contain '58' (ICMPv6 protocol number) in {seq_path}")

        return results

    @classmethod
    def validate_ip_type_prefix_list_restriction(cls, sequence, seq_path):
        """Validate that protocol='all' cannot use version-specific prefix lists"""
        results = []

        if sequence.get("protocol") == "all":
            match_entries = sequence.get("match_entries", {})
            prohibited_fields = [
                "source_data_ipv4_prefix_list", "source_data_ipv6_prefix_list",
                "destination_data_ipv4_prefix_list", "destination_data_ipv6_prefix_list"
            ]
            for field in prohibited_fields:
                if field in match_entries:
                    results.append(f"'protocol=all' cannot use '{field}' in {seq_path}")
        return results
    
    @classmethod
    def validate_standalone_vpn_dependency(cls, actions, seq_path):
        """Validate that standalone vpn requires next_hop or tloc"""
        results = []
        service = actions.get("service", {})
        service_chain = actions.get("service_chain", {})
        if "vpn" in actions and "vpn" not in service and "vpn" not in service_chain:
            has_next_hop = "next_hop_ipv4" in actions or "next_hop_ipv6" in actions
            tloc = actions.get("tloc", {})
            has_tloc = "ip" in tloc or "list" in tloc
            if not (has_next_hop or has_tloc):
                results.append(f"Standalone 'vpn' requires either ('next_hop_ipv4' or 'next_hop_ipv6') or tloc configuration in {seq_path}")
        return results

    @classmethod
    def validate_cloud_action_dependencies(cls, actions, seq_path):
        """Validate cloud_saas requires cloud_probe and counter_name; cloud_probe requires counter_name"""
        results = []
        # If cloud_saas is configured, both cloud_probe and counter_name are REQUIRED
        if actions.get("cloud_saas"):
            if "cloud_probe" not in actions:
                results.append(f"'cloud_saas' requires 'cloud_probe' action in {seq_path}")
            if "counter_name" not in actions:
                results.append(f"'cloud_saas' requires 'counter_name' action in {seq_path}")
        # If cloud_probe is configured (standalone), counter_name is REQUIRED
        if actions.get("cloud_probe") and "counter_name" not in actions:
            results.append(f"'cloud_probe' requires 'counter_name' action in {seq_path}")

        return results

    @classmethod
    def validate_fallback_to_routing_dependency(cls, actions, seq_path):
        """Validate fallback_to_routing requires sig_sse"""
        results = []
        sig_sse = actions.get("sig_sse", {})
        if sig_sse.get("fallback_to_routing"):
            has_sig_or_sse = sig_sse.get("internet_gateway") or sig_sse.get("service_edge")
            if not has_sig_or_sse:
                results.append(f"'sig_sse.fallback_to_routing' requires 'sig_sse.internet_gateway' or 'sig_sse.service_edge' in {seq_path}")
        return results

    @classmethod
    def validate_cloud_action_semantic_conflicts(cls, actions, seq_path):
        """Validate cloud actions cannot combine with local traffic manipulation"""
        results = []
        has_cloud = actions.get("cloud_saas") or actions.get("cloud_probe")
        if not has_cloud:
            return results
        prohibited = {
            "sla_class": "SLA class steering",
            "nat_vpn": "NAT VPN configuration",
            "nat_pool": "NAT pool configuration",
            "cflowd": "flow monitoring",
            "sig_sse": "Secure Internet Gateway/Service Edge",
        }

        for param, description in prohibited.items():
            if param in actions:
                results.append(
                    f"Cloud actions (cloud_saas/cloud_probe) cannot combine with '{param}' "
                    f"({description}). Cloud routing is incompatible with local traffic manipulation. "
                    f"In {seq_path}"
                )
        return results

    @classmethod
    def validate_service_chain_dependencies(cls, actions, seq_path):
        """Validate service_chain conditional dependencies

        Note: Required fields (type, local, fallback_to_routing, vpn) are validated by Rule 405.
              This function only validates complex conditional logic.
              tloc_ip and tloc_list are optional but mutually exclusive
              (mutual exclusivity is checked in validate_tloc_dependencies)

        NOTE: Provider uses 'service_chain_fallback_to_routing' with INVERTED semantics from API's 'restrict':
              - API 'restrict=true' (no fallback) → Provider 'fallback_to_routing=false'
              - API 'restrict=false' (allow fallback) → Provider 'fallback_to_routing=true'
        """
        results = []
        service_chain = actions.get("service_chain", {})

        if service_chain:
            # Conditional restrictions based on local value (complex logic - stays in Rule 418)
            if service_chain.get("local") is True:
                # When local=true, cannot have tloc options
                if "tloc_ip" in service_chain or "tloc_list" in service_chain:
                    results.append(f"'service_chain' with 'local=true' cannot have 'tloc_ip' or 'tloc_list' in {seq_path}")
            # tloc_ip and tloc_list are optional when local=false (mutual exclusivity handled elsewhere)
        return results

    @classmethod
    def validate_tloc_dependencies(cls, actions, seq_path):
        """Validate TLOC action requirements and mutual exclusivity

        Validates:
        - tloc action requires vpn action
        - tloc.ip requires color and encapsulation
        - service.tloc_ip requires tloc_color and tloc_encapsulation
        - service_chain.tloc_ip requires tloc_color and tloc_encapsulation
        - tloc_list is mutually exclusive with manual TLOC attributes
        - local_tloc requires colors when restrict or encapsulation is used
        """
        results = []
        tloc = actions.get("tloc", {})
        if tloc:  # If tloc action is present (any attribute)
            # Require vpn when tloc action is used
            if "vpn" not in actions:
                results.append(f"'tloc' action requires 'vpn' in {seq_path}")
            # Mutual exclusivity: list vs manual attributes
            if "list" in tloc:
                manual_attrs = []
                if "ip" in tloc:
                    manual_attrs.append("ip")
                if "color" in tloc:
                    manual_attrs.append("color")
                if "encapsulation" in tloc:
                    manual_attrs.append("encapsulation")

                if manual_attrs:
                    results.append(
                        f"'tloc.list' is mutually exclusive with manual TLOC attributes. "
                        f"Found 'tloc.list' with {', '.join([f'tloc.{attr}' for attr in manual_attrs])} in {seq_path}"
                    )
            # Manual tloc.ip requires color and encapsulation
            if "ip" in tloc:
                if "color" not in tloc:
                    results.append(f"'tloc.ip' requires 'tloc.color' in {seq_path}")
                if "encapsulation" not in tloc:
                    results.append(f"'tloc.ip' requires 'tloc.encapsulation' in {seq_path}")
        service = actions.get("service", {})
        # Mutual exclusivity: tloc_list vs manual attributes
        if "tloc_list" in service:
            manual_attrs = []
            if "tloc_ip" in service:
                manual_attrs.append("tloc_ip")
            if "tloc_color" in service:
                manual_attrs.append("tloc_color")
            if "tloc_encapsulation" in service:
                manual_attrs.append("tloc_encapsulation")

            if manual_attrs:
                results.append(
                    f"'service.tloc_list' is mutually exclusive with manual TLOC attributes. "
                    f"Found 'service.tloc_list' with {', '.join([f'service.{attr}' for attr in manual_attrs])} in {seq_path}"
                )
        if "tloc_ip" in service:
            if "tloc_color" not in service:
                results.append(f"'service.tloc_ip' requires 'service.tloc_color' in {seq_path}")
            if "tloc_encapsulation" not in service:
                results.append(f"'service.tloc_ip' requires 'service.tloc_encapsulation' in {seq_path}")
        service_chain = actions.get("service_chain", {})
        # Mutual exclusivity: tloc_list vs manual attributes
        if "tloc_list" in service_chain:
            manual_attrs = []
            if "tloc_ip" in service_chain:
                manual_attrs.append("tloc_ip")
            if "tloc_color" in service_chain:
                manual_attrs.append("tloc_color")
            if "tloc_encapsulation" in service_chain:
                manual_attrs.append("tloc_encapsulation")

            if manual_attrs:
                results.append(
                    f"'service_chain.tloc_list' is mutually exclusive with manual TLOC attributes. "
                    f"Found 'service_chain.tloc_list' with {', '.join([f'service_chain.{attr}' for attr in manual_attrs])} in {seq_path}"
                )
        # Manual tloc_ip requires tloc_color and tloc_encapsulation
        if "tloc_ip" in service_chain:
            if "tloc_color" not in service_chain:
                results.append(f"'service_chain.tloc_ip' requires 'service_chain.tloc_color' in {seq_path}")
            if "tloc_encapsulation" not in service_chain:
                results.append(f"'service_chain.tloc_ip' requires 'service_chain.tloc_encapsulation' in {seq_path}")
        # Local tloc dependencies
        local_tloc = actions.get("local_tloc", {})
        if "restrict" in local_tloc or "encapsulation" in local_tloc:
            if "colors" not in local_tloc:
                results.append(f"'local_tloc' configuration requires 'colors' in {seq_path}")
        return results

    @classmethod
    def validate_redirect_dns_conditional(cls, actions, seq_path):
        """Validate redirect_dns_target matches redirect_dns_type type"""
        results = []
        redirect_dns_type = actions.get("redirect_dns_type")
        redirect_dns_target = actions.get("redirect_dns_target")

        if redirect_dns_type and redirect_dns_target:
            import re
            # IP address pattern (same as schema)
            ip_pattern = re.compile(r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')

            if redirect_dns_type == "ip-address":
                # Value must be an IP address
                if not ip_pattern.match(redirect_dns_target):
                    results.append(f"'redirect_dns_type=ip-address' requires 'redirect_dns_target' to be a valid IPv4 address, got '{redirect_dns_target}' in {seq_path}")

            elif redirect_dns_type == "dns-host":
                # Value must be 'umbrella' or 'host'
                if redirect_dns_target not in ["umbrella", "host"]:
                    results.append(f"'redirect_dns_type=dns-host' requires 'redirect_dns_target' to be 'umbrella' or 'host', got '{redirect_dns_target}' in {seq_path}")

        return results

    @classmethod
    def validate_loss_correction_dependencies(cls, actions, seq_path):
        """Validate loss_correction requires type and threshold compatibility"""
        results = []
        # Check if any loss correction parameter is used
        has_loss_correction = any(key.startswith("loss_correct") for key in actions.keys())

        if has_loss_correction:
            # loss_correct_type is required when any loss correction parameter exists
            if "loss_correct_type" not in actions:
                results.append(f"Loss correction parameters require 'loss_correct_type' in {seq_path}")
        # Threshold compatibility check
        if "loss_correct_fec_threshold" in actions:
            loss_type = actions.get("loss_correct_type")
            if loss_type not in [None, "fec-adaptive"]:
                results.append(f"'loss_correct_fec_threshold' can only be used with 'loss_correct_type: fec-adaptive' in {seq_path}")
        return results

    @classmethod
    def validate_nat_dependencies(cls, actions, seq_path):
        """Validate NAT bypass rules"""
        results = []
        nat_vpn = actions.get("nat_vpn", {})

        if nat_vpn.get("bypass") is True:
            if "dia_pools" in nat_vpn or "dia_interfaces" in nat_vpn:
                results.append(f"'nat_vpn.bypass=true' cannot have 'dia_pools' or 'dia_interfaces' in {seq_path}")
        return results

    @classmethod
    def validate_sse_dependencies(cls, actions, seq_path):
        """Validate SSE (Secure Service Edge) requires service_edge_instance when service_edge is enabled"""
        results = []
        sig_sse = actions.get("sig_sse", {})
        # If service_edge is enabled, service_edge_instance is REQUIRED
        if sig_sse.get("service_edge"):
            if "service_edge_instance" not in sig_sse:
                results.append(f"'sig_sse.service_edge' requires 'sig_sse.service_edge_instance' in {seq_path}")

        return results

    @classmethod
    def validate_redirect_dns_match_requirement(cls, match_entries, actions, seq_path):
        """Validate redirect_dns action requires dns match"""
        results = []
        has_redirect_dns = "redirect_dns_type" in actions or "redirect_dns_target" in actions

        if has_redirect_dns:
            has_dns_match = "dns" in match_entries or "dns_application_list" in match_entries
            if not has_dns_match:
                results.append(f"'redirect_dns' action requires 'dns' or 'dns_application_list' in match criteria in {seq_path}")
        return results

    @classmethod
    def validate_cloud_action_match_requirement(cls, match_entries, actions, seq_path):
        """Validate cloud actions require app_list match"""
        results = []
        has_cloud_action = actions.get("cloud_saas") or actions.get("cloud_probe")

        if has_cloud_action:
            has_app_list = "application_list" in match_entries
            if not has_app_list:
                results.append(f"'cloud_saas' or 'cloud_probe' action requires 'application_list' in match criteria in {seq_path}")
        return results

    @classmethod
    def validate_service_areas_office365_requirement(cls, match_entries, seq_path):
        """Validate service_areas and traffic_category require application_list 'office365_apps'"""
        results = []
        # service_areas can only be used with office365_apps application list
        if "service_areas" in match_entries:
            app_list = match_entries.get("application_list", "")
            if app_list != "office365_apps":
                results.append(
                    f"'service_areas' can only be used with 'office365_apps' application list. "
                    f"Current application_list: '{app_list if app_list else 'none'}' in {seq_path}"
                )
        # traffic_category can only be used with office365_apps application list
        if "traffic_category" in match_entries:
            app_list = match_entries.get("application_list", "")
            if app_list != "office365_apps":
                results.append(
                    f"'traffic_category' can only be used with 'office365_apps' application list. "
                    f"Current application_list: '{app_list if app_list else 'none'}' in {seq_path}"
                )

        return results

    @classmethod
    def validate_drop_action_restrictions(cls, sequence, seq_path):
        """Validate base_action=drop restrictions"""
        results = []
        if sequence.get("base_action") == "drop":
            actions = sequence.get("actions", {})

            prohibited_actions = [
                "sla_class", "backup_sla_preferred_colors", "cflowd", "nat_pool",
                "redirect_dns_type", "redirect_dns_target", "loss_correct_type",
                "cloud_saas", "dscp", "forwarding_class", "local_tloc_list",
                "preferred_color_group", "preferred_remote_colors", "next_hop_ipv4",
                "next_hop_ipv6", "next_hop_loose", "policer_list", "service",
                "service_chain", "tloc", "vpn", "appqoe_optimization", "sig_sse"
            ]

            for param in prohibited_actions:
                if param in actions:
                    results.append(f"'base_action=drop' cannot use '{param}' in {seq_path}")

        return results

    @classmethod
    def validate_traffic_policy_vpn_constraints(cls, feature_profile, lan_vpn_names):
        """Validate all VPN level constraints for traffic policies

        Validates:
        1. VPNs within a single policy are unique (no duplicates in vpns list)
        2. VPN+direction combinations are unique across policies (allows same VPN with different directions)
        3. VPN names reference existing lan_vpns from service_profiles
        """
        results = []
        profile_name = feature_profile.get("name", "unknown")
        # Track VPN+direction combinations across policies
        vpn_direction_map = {}  # key: (vpn, direction), value: policy_name

        for traffic_policy in feature_profile.get("traffic_policies", []):
            policy_name = traffic_policy.get("name", "unknown")
            direction = traffic_policy.get("direction")
            vpns = traffic_policy.get("vpns", [])

            # Check 1: Validate VPNs are unique within this policy's vpns list
            seen_vpns = set()
            duplicates = set()

            for vpn in vpns:
                if vpn in seen_vpns:
                    duplicates.add(vpn)
                else:
                    seen_vpns.add(vpn)

            if duplicates:
                results.append(
                    f"Traffic policy 'vpns' list contains duplicate VPN(s): {sorted(list(duplicates))}. "
                    f"Each VPN must appear only once in the list. "
                    f"In sdwan.feature_profiles.application_priority_profiles[{profile_name}].traffic_policies[{policy_name}].vpns"
                )

            # Check 2 & 3: For each unique VPN in this policy
            for vpn in vpns:
                # Check 2: VPN+direction uniqueness across policies
                key = (vpn, direction)
                if key in vpn_direction_map:
                    existing_policy = vpn_direction_map[key]
                    results.append(
                        f"Traffic policy already exists for vpn '{vpn}' and direction '{direction}'. "
                        f"Policy '{policy_name}' conflicts with existing policy '{existing_policy}' "
                        f"in sdwan.feature_profiles.application_priority_profiles[{profile_name}].traffic_policies"
                    )
                else:
                    vpn_direction_map[key] = policy_name

                # Check 3: VPN name exists in service_profiles.lan_vpns
                if vpn not in lan_vpn_names:
                    results.append(
                        f"Traffic policy references VPN '{vpn}' which does not exist in service_profiles.lan_vpns. "
                        f"Available LAN VPN names: {sorted(list(lan_vpn_names)) if lan_vpn_names else 'none'}. "
                        f"In sdwan.feature_profiles.application_priority_profiles[{profile_name}].traffic_policies[{policy_name}].vpns"
                    )

        return results

    @classmethod
    def validate_sla_class_unique_colors(cls, actions, seq_path):
        """Validate SLA class color lists have unique items (no duplicates)"""
        results = []
        sla_class = actions.get("sla_class", {})

        # Check preferred_colors for duplicates
        preferred_colors = sla_class.get("preferred_colors", [])
        if preferred_colors and len(preferred_colors) != len(set(preferred_colors)):
            duplicates = [color for color in set(preferred_colors) if preferred_colors.count(color) > 1]
            results.append(
                f"SLA class 'preferred_colors' contains duplicate color(s): {sorted(duplicates)}. "
                f"Each color must appear only once. "
                f"In {seq_path}.actions.sla_class.preferred_colors"
            )

        # Check preferred_remote_colors for duplicates
        preferred_remote_colors = sla_class.get("preferred_remote_colors", [])
        if preferred_remote_colors and len(preferred_remote_colors) != len(set(preferred_remote_colors)):
            duplicates = [color for color in set(preferred_remote_colors) if preferred_remote_colors.count(color) > 1]
            results.append(
                f"SLA class 'preferred_remote_colors' contains duplicate color(s): {sorted(duplicates)}. "
                f"Each color must appear only once. "
                f"In {seq_path}.actions.sla_class.preferred_remote_colors"
            )

        return results

    @classmethod
    def validate_traffic_policies(cls, feature_profile, lan_vpn_names, results):
        """Validate traffic policy configurations"""
        profile_name = feature_profile.get("name", "unknown")
        # Validate policy-level VPN constraints (uniqueness, direction, and references)
        results.extend(cls.validate_traffic_policy_vpn_constraints(feature_profile, lan_vpn_names))

        for traffic_policy in feature_profile.get("traffic_policies", []):
            policy_name = traffic_policy.get("name", "unknown")
            policy_path = f"sdwan.feature_profiles.application_priority_profiles[{profile_name}].traffic_policies[{policy_name}]"

            for seq_idx, sequence in enumerate(traffic_policy.get("sequences", [])):
                seq_name = sequence.get("sequence_name", seq_idx)
                seq_path = f"{policy_path}.sequences[{seq_name}]"
                match_entries = sequence.get("match_entries", {})
                actions = sequence.get("actions", {})
                results.extend(cls.validate_ip_type_prefix_list_restriction(sequence, seq_path))
                results.extend(cls.validate_next_hop_dependencies(sequence, seq_path))
                results.extend(cls.validate_icmp_protocol_dependency(sequence, seq_path))
                results.extend(cls.validate_drop_action_restrictions(sequence, seq_path))
                results.extend(cls.validate_cloud_action_dependencies(actions, seq_path))
                results.extend(cls.validate_cloud_action_semantic_conflicts(actions, seq_path))
                results.extend(cls.validate_fallback_to_routing_dependency(actions, seq_path))
                results.extend(cls.validate_nat_dependencies(actions, seq_path))
                results.extend(cls.validate_sse_dependencies(actions, seq_path))
                results.extend(cls.validate_standalone_vpn_dependency(actions, seq_path))
                results.extend(cls.validate_service_chain_dependencies(actions, seq_path))
                results.extend(cls.validate_tloc_dependencies(actions, seq_path))
                results.extend(cls.validate_loss_correction_dependencies(actions, seq_path))
                results.extend(cls.validate_redirect_dns_conditional(actions, seq_path))
                results.extend(cls.validate_redirect_dns_match_requirement(match_entries, actions, seq_path))
                results.extend(cls.validate_cloud_action_match_requirement(match_entries, actions, seq_path))
                results.extend(cls.validate_service_areas_office365_requirement(match_entries, seq_path))
                results.extend(cls.validate_sla_class_unique_colors(actions, seq_path))
    # ============================================================================
    # Main Entry Point
    # ============================================================================

    @classmethod
    def match(cls, inventory):
        """Validate all Application Priority profile features (QoS and Traffic Policy)"""
        results = []
        # Get forwarding classes for QoS validation
        forwarding_classes = {
            fc["name"]: fc["queue"]
            for fc in inventory.get("sdwan", {}).get("feature_profiles", {}).get("policy_object_profile", {}).get("forwarding_classes", [])
        }

        # Collect all LAN VPN names from service_profiles for VPN reference validation
        lan_vpn_names = set()
        for service_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            for lan_vpn in service_profile.get("lan_vpns", []):
                vpn_name = lan_vpn.get("name")
                if vpn_name:
                    lan_vpn_names.add(vpn_name)

        # Validate both QoS and Traffic Policy
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("application_priority_profiles", []):
            cls.validate_qos_policies(feature_profile, forwarding_classes, results)
            cls.validate_traffic_policies(feature_profile, lan_vpn_names, results)

        return results
