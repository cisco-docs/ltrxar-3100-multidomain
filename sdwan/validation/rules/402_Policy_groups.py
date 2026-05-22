import re
import jmespath


class Rule:
    id = "402"
    description = "Verify Policy Groups"
    severity = "HIGH"

    # Flattened path to variable that (if configured) is required to be filled during config group deployment
    required_variables_paths = [
        "sdwan.feature_profiles.application_priority_profiles.qos_policies.target_interfaces_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.match_entries.destination_data_ipv4_prefixes_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.match_entries.destination_fqdns_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.match_entries.destination_ports_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.match_entries.source_data_ipv4_prefixes_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.policies.sequences.match_entries.source_ports_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.settings.app_hosting.download_url_database_on_device_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.settings.app_hosting.nat_variable",
        "sdwan.feature_profiles.ngfw_security_profiles.settings.app_hosting.resource_profile_variable",
    ]

    # In get_features_names function, we extract feature names by iterating over profile and finding all "name" keys
    # However sometimes "name" key is used for other purposes, e.g. aaa.users.name and needs not to be saved as feature name
    # This is a list of partial paths where name key is used for other purposes than feature name
    skip_name_paths = []

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
    def get_policy_group_variables(cls, inventory, policy_group):
        # Get all variables from all profiles assigned to a policy group
        # and return them as a list of dictionaries with flat_path, full_path and variable name
        # Example: [{'variable_name': 'vpn10_static_lease_mac1',
        # 'flat_path': 'sdwan.feature_profiles.application_priority_profiles.qos_policies.target_interfaces_variable',
        # 'full_path': 'sdwan.feature_profiles.application_priority_profiles[app1].qos_policies[qos1].target_interfaces_variable'}]
        variables = []
        for key, value in policy_group.items():
            if key not in ["name", "description"]:
                profile = next(
                    (
                        p
                        for p in inventory.get("sdwan", {})
                        .get("feature_profiles", {})
                        .get(f"{key}_profiles", [])
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
                        f"sdwan.feature_profiles.{key}_profiles",
                        f"sdwan.feature_profiles.{key}_profiles[{value}]",
                    )
        return variables

    @classmethod
    def get_required_variables(
        cls, inventory, policy_group_variables, chassis_id
    ):
        required_variables = policy_group_variables or []
        return required_variables

    @classmethod
    def match(cls, inventory):
        results = []
        profile_types = [
            "application_priority",
            "ngfw_security",
        ]
        # Create a dict where key is profile type and value is a list of profile names that exists for this profile type
        existing_profiles_names = {profile_type: [] for profile_type in profile_types}
        # Create a dict where key is profile type and value is a dict with profile name as key and feature names with paths as value
        existing_feature_names_per_profile = {
            profile_type: {} for profile_type in profile_types
        }
        # Create a dict that holds variables for each policy group
        policy_group_variables = {}
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
                    existing_feature_names_per_profile[profile_type][profile_name] = (
                        cls.get_features_names(
                            profile,
                            f"sdwan.feature_profiles.{profile_type}_profiles[{profile_name}]",
                            {},
                        )
                    )
        if inventory.get("sdwan", {}).get("policy_groups", {}):
            for policy_group in inventory.get("sdwan", {}).get(
                "policy_groups", {}
            ):
                features = {}
                for profile_type in profile_types:
                    if policy_group.get(profile_type, None):
                        # Validate if profiles that are referenced exists
                        if (
                            policy_group.get(profile_type)
                            not in existing_profiles_names[profile_type]
                        ):
                            results.append(
                                f"Policy Group '{policy_group.get('name')}' references a {profile_type} profile '{policy_group.get(f'{profile_type}')}' that does not exist under sdwan.feature_profiles.{profile_type}_profiles"
                            )
                        else:
                            # Validate if feature names are not overlaping accross profiles that are used in this policy group
                            # Create a dict with key as feature name and value as list of paths where this name is used
                            # If name will have more than one path it means that this name is used for more than one feature
                            profile_name = policy_group.get(
                                f"{profile_type}"
                            )
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
                                        f"Duplicate feature name '{feature_name}' in policy group '{policy_group.get('name')}' under paths: {', '.join(feature_paths)}"
                                    )
                policy_group_variables[policy_group.get("name")] = (
                    cls.get_policy_group_variables(
                        inventory, policy_group
                    )
                )

        # Verify the presence of the required device variables in each site and router
        for site in inventory.get("sdwan", {}).get("sites", {}):
            for router in site["routers"]:
                if "policy_group" in router:
                    # Verify if policy group exists
                    policy_group_name = router.get("policy_group")
                    policy_group = next(
                        (
                            pg
                            for pg in inventory.get("sdwan", {}).get("policy_groups", {})
                            if pg.get("name") == policy_group_name
                        ),
                        None,
                    )
                    if not policy_group:
                        results.append(
                            router["chassis_id"]
                            + " - policy group '"
                            + policy_group_name
                            + "' does not exist"
                        )
                        return results
                    # if not router.get("configuration_group", None) and not router.get("configuration_group_deploy", True):
                    if not router.get("configuration_group", None):
                        results.append(
                            router["chassis_id"]
                            + " - policy group assigned but no configuration group assigned"
                        )
                        return results
                    if router.get("policy_group_deploy", True) and not router.get("configuration_group_deploy", True):
                        results.append(
                            router["chassis_id"]
                            + " - policy group deploy is true but configuration group deploy is false"
                        )
                        return results
                    # Verify missing vars in the router
                    missing_variables = []
                    unnecessary_variables = []
                    required_variables = cls.get_required_variables(
                        inventory,
                        policy_group_variables.get(
                            router["policy_group"]
                        ),
                        router["chassis_id"],
                    )
                    for variable in required_variables:
                        if (
                            variable["flat_path"] in cls.required_variables_paths
                            and variable["variable_name"]
                            not in router.get("policy_variables", {})
                        ):
                            # missing_variables.append(variable['variable_name'] + f' ({variable["path"]})')
                            missing_variables.append(variable["variable_name"])
                    # Verify unnecessary variables
                    for variable in router.get("policy_variables", {}):
                        feature_profile_variables = [
                            v["variable_name"] for v in required_variables
                        ]
                        if (
                            variable not in feature_profile_variables
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
        return results
