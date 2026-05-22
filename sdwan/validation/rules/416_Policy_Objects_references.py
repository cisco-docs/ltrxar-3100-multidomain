class Rule:
    id = "416"
    description = "Validate policy object references"
    severity = "HIGH"

    #########################################################################################################################################
    # This rule checks if the policy objects referenced in other features/policies are defined in the policy_objects_profile
    # For any additional parameters where the validation is required, update the policy_object_references list below
    # No additional code changes should be required
    # The policy_object_references list has the following details:
    # type - type of the policy object (e.g. ipv4_data_prefix_lists)
    # paths - flattened paths to the location where policy object of this type might be referenced
    #########################################################################################################################################


    policy_object_references = [
        {
            "type": "as_path_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.as_path_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.as_path_list",
            ]
        },
        {
            "type": "expanded_community_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.expanded_community_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.expanded_community_list",
            ]
        },
        {
            "type": "extended_community_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.extended_community_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.extended_community_list",
            ]
        },
        {
            "type": "forwarding_classes",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.app_probe_classes.forwarding_class",
            ]
        },
        {
            "type": "ipv4_data_prefix_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.match_entries.source_data_prefix_list",
                "sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.sequences.match_entries.source_data_prefix_list",
                "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.match_entries.source_data_prefix_list",
            ]
        },
        {
            "type": "ipv4_prefix_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.ipv4_address_prefix_list",
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.ipv4_next_hop_prefix_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.ipv4_address_prefix_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.ipv4_next_hop_prefix_list",
            ]
        },
        {
            "type": "ipv6_data_prefix_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences.match_entries.source_data_prefix_list",
                "sdwan.feature_profiles.system_profiles.ipv6_device_access_policy.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.system_profiles.ipv6_device_access_policy.sequences.match_entries.source_data_prefix_list",
                "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences.match_entries.destination_data_prefix_list",
                "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences.match_entries.source_data_prefix_list",
            ]
        },
        {
            "type": "ipv6_prefix_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.ipv6_address_prefix_list",
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.ipv6_next_hop_prefix_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.ipv6_address_prefix_list",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.ipv6_next_hop_prefix_list",
            ]
        },
        {
            "type": "mirrors",
            "paths": [
                "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.actions.mirror",
                "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences.actions.mirror",
                "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.actions.mirror",
                "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences.actions.mirror",
            ]
        },
        {
            "type": "policers",
            "paths": [
                "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences.actions.policer",
                "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences.actions.policer",
                "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences.actions.policer",
                "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences.actions.policer",
            ]
        },
        {
            "type": "security_advanced_malware_protection_profiles",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles.advanced_malware_protection",
            ]
        },
        {
            "type": "security_intrusion_prevention_profiles",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles.intrusion_prevention",
            ]
        },
        {
            "type": "security_ips_signature_lists",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_intrusion_prevention_profiles.signature_allow_list",
            ]
        },
        {
            "type": "security_url_allow_lists",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles.url_allow_list",
            ]
        },
        {
            "type": "security_url_block_lists",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles.url_block_list",
            ]
        },
        {
            "type": "security_url_filtering_profiles",
            "paths": [
                "sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles.url_filtering",
            ]
        },
        {
            "type": "standard_community_lists",
            "paths": [
                "sdwan.feature_profiles.service_profiles.route_policies.sequences.match_entries.standard_community_lists",
                "sdwan.feature_profiles.transport_profiles.route_policies.sequences.match_entries.standard_community_lists",
            ]
        }
    ]

    @classmethod
    def get_policy_objects(cls, inventory):
        defined_policy_objects = {}
        for object_type, objects in inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {}).items():
            defined_policy_objects[object_type] = [obj['name'] for obj in objects if isinstance(obj, dict) and 'name' in obj]
        return defined_policy_objects
    
    @classmethod
    def validate_references(cls, inventory, full_path, search_path, reference_type, defined_policy_objects):
        results = []
        path_elements = search_path.split(".")
        inv_element = inventory
        for idx, path_element in enumerate(path_elements):
            if isinstance(inv_element, dict) and idx + 1 == len(path_elements):
                # Verify if the required policy object is defined
                required_policy_object = inv_element.get(path_element)
                if required_policy_object:
                    if isinstance(required_policy_object, list):
                        for obj in required_policy_object:
                            if obj not in defined_policy_objects:
                                results.append(f"{reference_type[:-1]} {obj} is referenced in {full_path}.{path_element}, but is not defined in sdwan.feature_profiles.policy_object_profile.{reference_type}")
                    else:
                        if required_policy_object not in defined_policy_objects:
                            results.append(f"{reference_type[:-1]} {required_policy_object} is referenced in {full_path}.{path_element}, but is not defined in sdwan.feature_profiles.policy_object_profile.{reference_type}")
                return results
            elif isinstance(inv_element, dict):
                inv_element = inv_element.get(path_element)
                full_path += path_element if not full_path else "." + path_element
            elif isinstance(inv_element, list):
                for idx2, i in enumerate(inv_element):
                    r = cls.validate_references(i, full_path + f"[{i['name']}]" if isinstance(i, dict) and "name" in i else full_path + f"[{idx2}]", ".".join(path_elements[idx:]),
                                                reference_type, defined_policy_objects)
                    results.extend(r)
        return results

    @classmethod
    def match(cls, inventory):
        results = []
        defined_policy_objects = cls.get_policy_objects(inventory)
        for reference in cls.policy_object_references:
            for path in reference['paths']:
                results.extend(cls.validate_references(inventory, '', path, reference['type'], defined_policy_objects.get(reference['type'], [])))
        return results