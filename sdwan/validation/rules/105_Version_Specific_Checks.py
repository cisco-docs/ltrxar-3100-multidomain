class Rule:
    id = "105"
    description = "Version Specific Checks"
    severity = "HIGH"

    #########################################################################################################################################
    # Some parameters are only supported starting from a specific manager version.
    # This rule checks if unsupported parameters are used with an incompatible manager version.
    # For any additional version-gated parameters, add the path to the paths list of the relevant minimum_version entry
    # (or add a new entry if the minimum_version differs). No additional code changes should be required.
    # Note: custom version checks (not related to unsupported parameters) can be added directly to match function too
    #########################################################################################################################################

    unsupported_parameters = [
        {
            "minimum_version": "20.18",
            "paths": [
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv4_address_type_variable",
                "sdwan.feature_profiles.service_profiles.lan_vpns.ethernet_interfaces.ipv6_address_type_variable",
                "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv4_address_type_variable",
                "sdwan.feature_profiles.transport_profiles.management_vpn.ethernet_interfaces.ipv6_address_type_variable",
                "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv4_address_type_variable",
                "sdwan.feature_profiles.transport_profiles.wan_vpn.ethernet_interfaces.ipv6_address_type_variable",
            ],
        },
    ]

    @classmethod
    def match_path(cls, inventory, full_path, search_path):
        results = []
        path_elements = search_path.split(".")
        inv_element = inventory

        if len(path_elements) == 1:
            # Base case: check if this unsupported key is present
            if path_elements[0] in inv_element:
                results.append(
                    full_path + ("." if full_path else "") + path_elements[0]
                )
        else:
            for idx, path_element in enumerate(path_elements):
                if isinstance(inv_element, dict) and idx + 1 == len(path_elements):
                    # Last path element: report if key is present
                    if path_element in inv_element:
                        results.append(
                            full_path + ("." if full_path else "") + path_element
                        )
                elif isinstance(inv_element, dict):
                    inv_element = inv_element.get(path_element)
                    full_path += path_element if not full_path else "." + path_element
                elif isinstance(inv_element, list):
                    for idx2, i in enumerate(inv_element):
                        label = (
                            f"[{i['name']}]"
                            if isinstance(i, dict) and "name" in i
                            else f"[{idx2}]"
                        )
                        r = cls.match_path(
                            i, full_path + label, ".".join(path_elements[idx:])
                        )
                        results.extend(r)
                    return results

        return results

    @classmethod
    def _version_is_below(cls, manager_version, minimum_version):
        manager_parts = str(manager_version).split(".")
        minimum_parts = str(minimum_version).split(".")
        for m, n in zip(manager_parts, minimum_parts):
            if int(m) < int(n):
                return True
            if int(m) > int(n):
                return False
        return False

    @classmethod
    def match_unsupported_parameters(cls, inventory, manager_version):
        results = []
        for feature in cls.unsupported_parameters:
            if cls._version_is_below(manager_version, feature["minimum_version"]):
                for path in feature["paths"]:
                    for found_path in cls.match_path(inventory, "", path):
                        results.append(
                            f"{found_path} is not supported in manager version "
                            f"{manager_version} (requires {feature['minimum_version']} or higher)"
                        )
        return results

    @classmethod
    def match(cls, inventory):
        results = []

        manager_version = inventory.get("sdwan", {}).get("manager_version")
        if not manager_version:
            return results

        results.extend(cls.match_unsupported_parameters(inventory, manager_version))

        return results
