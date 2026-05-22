class Rule:
    id = "419"
    description = "Validate NGFW security policy sequences, zone constraints, and AIP/app_hosting consistency"
    severity = "HIGH"

    # SD-WAN Manager enforces a max of 3 individual values per direction per sequence.
    # Each item in a list and each scalar reference counts as 1 value.
    # Source direction includes all source_* types plus protocol/app neutral types.
    # Destination direction includes only destination_* types.
    _SOURCE_MATCH_ENTRIES = {
        "source_data_ipv4_prefix_lists": "list",
        "source_data_ipv4_prefixes": "list",
        "source_geo_location_lists": "list",
        "source_geo_locations": "list",
        "source_identity_lists": "list",
        "source_identity_users": "list",
        "source_identity_usergroups": "list",
        "source_port_lists": "list",
        "source_ports": "list",
        "source_scalable_group_tag_lists": "list",
        "protocol_name_lists": "list",
        "protocol_names": "list",
        "protocols": "list",
        "application_list": "scalar",
    }

    _DESTINATION_MATCH_ENTRIES = {
        "destination_data_ipv4_prefix_lists": "list",
        "destination_data_ipv4_prefixes": "list",
        "destination_fqdn_lists": "list",
        "destination_fqdns": "list",
        "destination_geo_location_lists": "list",
        "destination_geo_locations": "list",
        "destination_port_lists": "list",
        "destination_ports": "list",
        "destination_scalable_group_tag_lists": "list",
    }

    _MAX_DIRECTION_OBJECT_COUNT = 3

    @classmethod
    def _count_direction_values(cls, match_entries, direction_map):
        """Sum individual values across all match entry types for a direction."""
        total = 0
        for key, kind in direction_map.items():
            val = match_entries.get(key)
            if val is None:
                continue
            if kind == "list" and isinstance(val, list):
                total += len(val)
            else:
                total += 1
        return total

    @classmethod
    def _validate_sequence_ids(cls, policy, path):
        results = []
        seq_ids = [
            seq.get("sequence_id")
            for seq in policy.get("sequences", [])
            if seq.get("sequence_id") is not None
        ]
        sorted_ids = sorted(seq_ids)
        expected_ids = list(range(1, len(sorted_ids) + 1))
        if sorted_ids and sorted_ids[0] != 1:
            results.append(
                f"sequence_id values must start from 1 in {path} "
                f"(found first id: {sorted_ids[0]})"
            )
        elif sorted_ids != expected_ids:
            results.append(
                f"sequence_id values are not sequential in {path} "
                f"(expected: {expected_ids}, found: {sorted_ids})"
            )
        return results

    @classmethod
    def _validate_sequence_name_uniqueness(cls, policy, path):
        results = []
        seen_names = {}
        for seq in policy.get("sequences", []):
            seq_name = seq.get("sequence_name")
            if seq_name is None:
                continue
            if seq_name in seen_names:
                results.append(f"Duplicate sequence_name '{seq_name}' in {path}")
            else:
                seen_names[seq_name] = True
        return results

    @classmethod
    def _validate_policy_zone_constraints(cls, policy, path):
        results = []
        src_zone = policy.get("source_zone")
        dst_zones = policy.get("destination_zones") or []

        if src_zone and src_zone in dst_zones:
            results.append(
                f"source_zone '{src_zone}' also appears in destination_zones "
                f"— a zone cannot be both source and destination in {path}"
            )

        if dst_zones and "untrusted" in dst_zones and len(dst_zones) > 1:
            others = [z for z in dst_zones if z != "untrusted"]
            results.append(
                f"destination_zones contains 'untrusted' mixed with other zones {others} "
                f"— untrusted cannot coexist with other destination zones in {path}"
            )

        return results

    @classmethod
    def _validate_profile_zone_pair_uniqueness(
        cls, policy, path, profile_path, seen_profile_pairs
    ):
        results = []
        src_zone = policy.get("source_zone")
        dst_zones = policy.get("destination_zones") or []
        if src_zone:
            policy_name = policy.get("name", "<unnamed>")
            for dst in dst_zones:
                pair = (src_zone, dst)
                if pair in seen_profile_pairs:
                    results.append(
                        f"Zone pair (source_zone='{src_zone}', destination_zone='{dst}') in {path} "
                        f"is already used by policy '{seen_profile_pairs[pair]}' in {profile_path}"
                    )
                else:
                    seen_profile_pairs[pair] = policy_name
        return results

    @classmethod
    def _validate_direction_object_counts(cls, match_entries, seq_path):
        results = []
        source_count = cls._count_direction_values(match_entries, cls._SOURCE_MATCH_ENTRIES)
        if source_count > cls._MAX_DIRECTION_OBJECT_COUNT:
            results.append(
                f"match_entries exceeds SD-WAN Manager source object count limit of "
                f"{cls._MAX_DIRECTION_OBJECT_COUNT} (found {source_count} source values) "
                f"in {seq_path} — reduce the total number of items across all "
                f"source-direction match entries; each list item and scalar reference "
                f"counts as 1 (source types: source_*, protocol_names, protocols, "
                f"protocol_name_lists, application_list)"
            )

        dest_count = cls._count_direction_values(match_entries, cls._DESTINATION_MATCH_ENTRIES)
        if dest_count > cls._MAX_DIRECTION_OBJECT_COUNT:
            results.append(
                f"match_entries exceeds SD-WAN Manager destination object count limit of "
                f"{cls._MAX_DIRECTION_OBJECT_COUNT} (found {dest_count} destination values) "
                f"in {seq_path} — reduce the total number of items across all "
                f"destination-direction match entries; each list item and scalar reference "
                f"counts as 1 (destination types: destination_*)"
            )

        return results

    @classmethod
    def _validate_sequence(cls, seq, path):
        results = []
        seq_id = seq.get("sequence_id", "<unknown>")
        seq_path = f"{path}.sequences[{seq_id}]"
        base_action = seq.get("base_action")
        actions = seq.get("actions") or {}
        aip = actions.get("advanced_inspection_profile")
        match_entries = seq.get("match_entries") or {}

        if aip and base_action != "inspect":
            results.append(
                f"actions.advanced_inspection_profile is defined but base_action is '{base_action}' "
                f"(must be 'inspect') in {seq_path}"
            )

        results.extend(cls._validate_direction_object_counts(match_entries, seq_path))
        return results, bool(aip)

    @classmethod
    def _validate_profile_settings(cls, profile, profile_path, aip_active):
        results = []
        settings = profile.get("settings") or {}
        app_hosting = settings.get("app_hosting")
        failure_mode = settings.get("failure_mode")

        if settings.get("advanced_inspection_profile"):
            aip_active = True

        if aip_active:
            if app_hosting is None:
                results.append(
                    f"AIP is active but settings.app_hosting is not defined in {profile_path} "
                    f"— app_hosting (nat, download_url_database_on_device, resource_profile) "
                    f"must be configured when an advanced_inspection_profile is in use"
                )
            if failure_mode is None:
                results.append(
                    f"AIP is active but settings.failure_mode is not defined in {profile_path} "
                    f"— failure_mode must be configured when an advanced_inspection_profile is in use"
                )
        elif app_hosting is not None:
            results.append(
                f"settings.app_hosting is defined but no advanced_inspection_profile (AIP) is active "
                f"in {profile_path} — app_hosting has no effect without UTD/AIP"
            )

        if app_hosting is not None:
            app_hosting_path = f"{profile_path}.settings.app_hosting"
            for required_field in ("nat", "download_url_database_on_device", "resource_profile"):
                variable_field = f"{required_field}_variable"
                has_value = app_hosting.get(required_field) is not None
                has_variable = app_hosting.get(variable_field) is not None
                if not has_value and not has_variable:
                    results.append(
                        f"{app_hosting_path}.{required_field} is required when app_hosting is defined "
                        f"(provide either {required_field} or {variable_field})"
                    )

        return results

    @classmethod
    def match(cls, inventory):
        results = []
        for profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("ngfw_security_profiles", []):
            profile_name = profile.get("name", "<unnamed>")
            profile_path = f"sdwan.feature_profiles.ngfw_security_profiles[{profile_name}]"
            aip_active = False
            seen_profile_pairs = {}

            for policy in profile.get("policies", []):
                policy_name = policy.get("name", "<unnamed>")
                path = f"{profile_path}.policies[{policy_name}]"
                results.extend(cls._validate_sequence_ids(policy, path))
                results.extend(cls._validate_sequence_name_uniqueness(policy, path))
                results.extend(cls._validate_policy_zone_constraints(policy, path))
                results.extend(
                    cls._validate_profile_zone_pair_uniqueness(
                        policy, path, profile_path, seen_profile_pairs
                    )
                )

                for seq in policy.get("sequences", []):
                    seq_results, seq_has_aip = cls._validate_sequence(seq, path)
                    results.extend(seq_results)
                    if seq_has_aip:
                        aip_active = True

            results.extend(cls._validate_profile_settings(profile, profile_path, aip_active))

        return results
