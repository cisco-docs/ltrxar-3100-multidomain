class Rule:
    id = "415"
    description = "Validate sequences"
    severity = "HIGH"

    #########################################################################################################################################
    # This rule checks if the sequences in features and policies are defined correctly
    # and sequence ids are incremented by 1 starting from 1.
    # For any additional parameters where the validation is required, update the path list below
    # No additional code changes should be required
    ##############################################################################################################################################

    paths = [
        "sdwan.feature_profiles.service_profiles.ipv4_acls.sequences",
        "sdwan.feature_profiles.service_profiles.ipv6_acls.sequences",
        "sdwan.feature_profiles.service_profiles.route_policies.sequences",
        "sdwan.feature_profiles.system_profiles.ipv4_device_access_policy.sequences",
        "sdwan.feature_profiles.system_profiles.ipv6_device_access_policy.sequences",
        "sdwan.feature_profiles.transport_profiles.ipv4_acls.sequences",
        "sdwan.feature_profiles.transport_profiles.ipv6_acls.sequences",
        "sdwan.feature_profiles.transport_profiles.route_policies.sequences"
    ]

    @classmethod
    def validate_sequence(cls, inventory, full_path):
        results = []
        sequences = inventory.get("sequences", [])
        ids = [
            seq.get("id") for seq in sequences if isinstance(seq, dict) and "id" in seq
        ]
        sorted_ids = sorted(ids)
        expected_ids = list(range(1, len(sorted_ids) + 1))
        if sorted_ids and sorted_ids[0] != 1:
            results.append(f"Sequence IDs should start from 1 in {full_path}")
        elif sorted_ids != expected_ids:
            results.append(
                f"Sequence IDs are not sequential in {full_path}. Expected: {expected_ids}, Found: {sorted_ids}"
            )
        return results

    @classmethod
    def match_path(cls, inventory, full_path, search_path):
        results = []
        path_elements = search_path.split(".")
        inv_element = inventory
        if len(path_elements) == 1:
            results.extend(
                cls.validate_sequence(inv_element, f"{full_path}.{path_elements[0]}")
            )
        else:
            for idx, path_element in enumerate(path_elements):
                if isinstance(inv_element, dict) and idx + 1 == len(path_elements):
                    results.extend(
                        cls.validate_sequence(
                            inv_element, f"{full_path}.{path_element}"
                        )
                    )
                elif isinstance(inv_element, dict):
                    inv_element = inv_element.get(path_element)
                    full_path += path_element if not full_path else "." + path_element
                elif isinstance(inv_element, list):
                    for idx2, i in enumerate(inv_element):
                        r = cls.match_path(
                            i,
                            (
                                full_path + f"[{i['name']}]"
                                if isinstance(i, dict) and "name" in i
                                else full_path + f"[{idx2}]"
                            ),
                            ".".join(path_elements[idx:]),
                        )
                        results.extend(r)
                    return results
        return results

    @classmethod
    def match(cls, inventory):
        results = []
        for path in cls.paths:
            r = cls.match_path(inventory, "", path)
            results.extend(r)
        return results