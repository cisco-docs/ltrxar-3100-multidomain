import re

class Rule:
    id = "403"
    description = "Verify Feature Profile unique names and unique feature names within profiles"
    severity = "HIGH"

    # In get_features_names function, we extract feature names by iterating over profile and finding all "name" keys
    # However sometimes "name" key is used for other purposes, e.g. aaa.users.name and needs not to be saved as feature name
    # This is a list of partial paths where name key is used for other purposes than feature name
    skip_name_paths = [
        "aaa.users",
        "bgp_features.mpls_interfaces",
        "ipv4_acls.sequences",
        "ipv4_device_access_policy.sequences",
        "ipv6_acls.sequences",
        "ipv6_device_access_policy.sequences",
        "logging.tls_profiles",
        "ospf_features.areas.interfaces",
        "ospfv3_ipv4_features.areas.interfaces",
        "ospfv3_ipv6_features.areas.interfaces",
        "route_policies.sequences",
        "snmp.communities",
        "snmp.views",
        "switchport_features.interfaces"
    ]

    @classmethod
    def get_features_names(cls, item, path, features, skip_key=True):
        # Get all feature names from a feature profile
        # This returns a dict with feature name as key and list of paths where this name is used as value
        if isinstance(item, dict):
            for key, value in item.items():
                flat_path = re.sub(r'\[.*?\]', '', path)
                if (
                    key == "name"
                    and skip_key is False
                    and not any(skip_path in flat_path for skip_path in cls.skip_name_paths)
                ):
                    if value in features:
                        features[value].append(path + ".name")
                    else:
                        features[value] = [path + ".name"]
                cls.get_features_names(value, f"{path}.{key}", features, False)
        elif isinstance(item, list):
            for index, element in enumerate(item):
                cls.get_features_names(
                    element,
                    (
                        path + f"[{element['name']}]"
                        if isinstance(element, dict) and "name" in element
                        else path + f"[{index}]"
                    ),
                    features,
                    False,
                )
        return features

    @classmethod
    def match(cls, inventory):
        results = []
        profile_names = []
        profile_types = [
            "cli",
            "other",
            "service",
            "system",
            "transport",
        ]
        # Create a dict where key is profile type and value is a dict with profile name as key and feature names with paths as value
        existing_feature_names_per_profile = {
            profile_type: {} for profile_type in profile_types
        }
        for profile_type in profile_types:
            for profile in inventory.get('sdwan', {}).get('feature_profiles', {}).get(f"{profile_type}_profiles", []):
                profile_names.append(profile['name'])
                existing_feature_names_per_profile[profile_type][profile['name']] = (
                    cls.get_features_names(
                        profile,
                        f"sdwan.feature_profiles.{profile_type}_profiles[{profile['name']}]",
                        {},
                    )
                )
        non_unique_names = [name for name in set(profile_names) if profile_names.count(name) > 1]
        for name in non_unique_names:
            results.append(f"Feature Profile name '{name}' is not unique")
        
        # Validate if feature names are unique within feature profiles
        # Create a dict with key as feature name and value as list of paths where this name is used
        # If name will have more than one path it means that this name is used for more than one feature
        for profile_type in profile_types:
            for profile in (
                inventory.get("sdwan", {})
                .get("feature_profiles", {})
                .get(f"{profile_type}_profiles", {})
            ):
                features = {}
                profile_name = profile.get("name")
                for (
                    feature_name,
                    feature_paths,
                ) in existing_feature_names_per_profile[profile_type][
                    profile_name
                ].items():
                    if feature_name in features:
                        features[feature_name].extend(feature_paths)
                    else:
                        features[feature_name] = feature_paths
                for feature_name, feature_paths in features.items():
                    if len(feature_paths) > 1:
                        results.append(
                            f"Duplicate feature name '{feature_name}' under paths: {', '.join(feature_paths)}"
                        )

        return results