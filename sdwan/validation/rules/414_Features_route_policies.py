class Rule:
    id = "414"
    description = "Validate route policies"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        for profile_type in ["transport_profiles", "service_profiles"]:
            for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get(profile_type, []):
                for route_policy in feature_profile.get("route_policies", []):
                    for index, sequence in enumerate(route_policy.get("sequences", [])):
                        # Validate when base action is "reject" then actions should not be defined
                        if sequence.get("base_action") == "reject" and sequence.get("actions"):
                            results.append(f'Base action is reject but actions are defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}]')
                        protocol = sequence.get("protocol", "ipv4")
                        match_entries = sequence.get("match_entries", {})
                        match_entries_types = match_entries.keys()
                        # Validate that configured match_entries are allowed for the configured protocol
                        conflicting_match_entries_types = {
                            "ipv4": ["ipv6_address_prefix_list", "ipv6_next_hop_prefix_list"],
                            "ipv6": ["ipv4_address_prefix_list", "ipv4_next_hop_prefix_list"],
                            "both": ["ipv4_address_prefix_list", "ipv6_address_prefix_list", "ipv4_next_hop_prefix_list", "ipv6_next_hop_prefix_list"]
                        }
                        for entry_type in conflicting_match_entries_types.get(protocol, []):
                            if entry_type in match_entries_types:
                                results.append(f'Protocol is {protocol} but {entry_type} is defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].match_entries')
                        # Validate that configured actions are allowed for the configured protocol
                        actions = sequence.get("actions", {})
                        actions_types = actions.keys()
                        conflicting_actions_types = {
                            "ipv4": ["ipv6_next_hop"],
                            "ipv6": ["ipv4_next_hop"],
                            "both": ["ipv4_next_hop", "ipv6_next_hop"]
                        }
                        for action_type in conflicting_actions_types.get(protocol, []):
                            if action_type in actions_types:
                                results.append(f'Protocol is {protocol} but {action_type} is defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].actions')
                        # Validate that when standard_community_lists_criteria is defined, then standard_community_list should be defined and vice versa
                        if "standard_community_lists_criteria" in match_entries_types and "standard_community_lists" not in match_entries_types:
                            results.append(f'standard_community_lists_criteria is defined but standard_community_lists is not defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].match_entries')
                        if "standard_community_lists" in match_entries_types and "standard_community_lists_criteria" not in match_entries_types:
                            results.append(f'standard_community_lists is defined but standard_community_lists_criteria is not defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].match_entries')
                        # Validate action communities_additive is configured only when communities or communities_variable is defined in actions
                        if "communities_additive" in actions_types and "communities" not in actions_types and "communities_variable" not in actions_types:
                            results.append(f'Action communities_additive is defined but communities or communities_variable is not defined in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].actions')
                        # Validate that the standard_community_lists and expanded_community_list are not defined at the same time
                        if "standard_community_lists" in match_entries_types and "expanded_community_list" in match_entries_types:
                            results.append(f'standard_community_lists and expanded_community_list are defined at the same time in sdwan.feature_profiles.{profile_type}[{feature_profile["name"]}].route_policies[{route_policy["name"]}].sequences[{index}].match_entries')
        return results