class Rule:
    id = "412"
    description = "Validate trackers"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        # Verify service IPv4 trackers have required parameters and dependencies
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            for tracker in feature_profile.get("ipv4_trackers", []):
                if ("endpoint_protocol" in tracker or "endpoint_protocol_variable" in tracker) and "endpoint_ip" not in tracker and "endpoint_ip_variable" not in tracker:
                    results.append(f'Parameter endpoint_protocol/endpoint_protocol_variable is defined but endpoint_ip/endpoint_ip_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].ipv4_trackers[{tracker["name"]}]')
                if ("endpoint_port" in tracker or "endpoint_port_variable" in tracker) and "endpoint_ip" not in tracker and "endpoint_ip_variable" not in tracker:
                    results.append(f'Parameter endpoint_port/endpoint_port_variable is defined but endpoint_ip/endpoint_ip_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].ipv4_trackers[{tracker["name"]}]')
                if ("endpoint_protocol" in tracker or "endpoint_protocol_variable" in tracker) and "endpoint_port" not in tracker and "endpoint_port_variable" not in tracker:
                    results.append(f'Parameter endpoint_protocol/endpoint_protocol_variable is defined but endpoint_port/endpoint_port_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].ipv4_trackers[{tracker["name"]}]')
                if ("endpoint_port" in tracker or "endpoint_port_variable" in tracker) and "endpoint_protocol" not in tracker and "endpoint_protocol_variable" not in tracker:
                    results.append(f'Parameter endpoint_port/endpoint_port_variable is defined but endpoint_protocol/endpoint_protocol_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].ipv4_trackers[{tracker["name"]}]')
        # Validate service ipv4 trackers referenced in service ipv4 tracker group are defined
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            ipv4_tracker_feature_names = [tracker["name"] for tracker in feature_profile.get("ipv4_trackers", [])]
            for ipv4_tracker_group in feature_profile.get("ipv4_tracker_groups", []):
                for index, tracker_feature_name in enumerate(ipv4_tracker_group.get("trackers", [])):
                    if tracker_feature_name not in ipv4_tracker_feature_names:
                        results.append(f'IPv4 Service Tracker Feature {tracker_feature_name} is not defined, but is referenced in sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].ipv4_tracker_groups[{ipv4_tracker_group["name"]}].trackers[{index}]')
        # Verify service object trackers have required parameters and dependencies
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            for tracker in feature_profile.get("object_trackers", []):
                if tracker.get("type", "") == "Interface":
                    if "interface_name" not in tracker and "interface_name_variable" not in tracker: 
                        results.append(f'Object Tracker Type is Interface but interface_name or interface_name_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
                    not_allowed_parameters = ["route_ip", "route_ip_variable", "route_mask", "route_mask_variable", "vpn_id", "vpn_id_variable"]
                    for parameter in not_allowed_parameters:
                        if parameter in tracker:
                            results.append(f'Object Tracker Type is Interface but {parameter} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
                if tracker.get("type", "") == "SIG":
                    not_allowed_parameters = ["interface_name", "interface_name_variable", "route_ip", "route_ip_variable", "route_mask", "route_mask_variable", "vpn_id", "vpn_id_variable"]
                    for parameter in not_allowed_parameters:
                        if parameter in tracker:
                            results.append(f'Object Tracker Type is SIG but {parameter} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
                if tracker.get("type", "") == "Route":
                    if "route_ip" not in tracker and "route_ip_variable" not in tracker:
                        results.append(f'Object Tracker Type is Route but route_ip or route_ip_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
                    if "route_mask" not in tracker and "route_mask_variable" not in tracker:
                        results.append(f'Object Tracker Type is Route but route_mask or route_mask_variable is not defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
                    not_allowed_parameters = ["interface_name", "interface_name_variable"]
                    for parameter in not_allowed_parameters:
                        if parameter in tracker:
                            results.append(f'Object Tracker Type is Route but {parameter} is defined in the sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_trackers[{tracker["id"]}]')
        # Validate service object trackers referenced in service object tracker group are defined
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("service_profiles", []):
            object_tracker_feature_names = [tracker["name"] for tracker in feature_profile.get("object_trackers", [])]
            for object_tracker_group in feature_profile.get("object_tracker_groups", []):
                for index, tracker_feature_name in enumerate(object_tracker_group.get("trackers", [])):
                    if tracker_feature_name not in object_tracker_feature_names:
                        results.append(f'Service Object Tracker Feature {tracker_feature_name} is not defined, but is referenced in sdwan.feature_profiles.service_profiles[{feature_profile["name"]}].object_tracker_groups[{object_tracker_group["name"]}].trackers[{index}]')

        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("transport_profiles", []):
            # Validate transport ipv4 trackers referenced in transport ipv4 tracker group are defined
            ipv4_tracker_feature_names = [tracker["name"] for tracker in feature_profile.get("ipv4_trackers", [])]
            for ipv4_tracker_group in feature_profile.get("ipv4_tracker_groups", []):
                for index, tracker_feature_name in enumerate(ipv4_tracker_group.get("trackers", [])):
                    if tracker_feature_name not in ipv4_tracker_feature_names:
                        results.append(f'IPv4 Transport Tracker Feature {tracker_feature_name} is not defined, but is referenced in sdwan.feature_profiles.transport_profiles[{feature_profile["name"]}].ipv4_tracker_groups[{ipv4_tracker_group["name"]}].trackers[{index}]')
            # Verify transport IPv4 trackers have respective parameter value as per endpoint_tracker_type
            for tracker in feature_profile.get("ipv4_trackers", []):
                if ( tracker.get("endpoint_tracker_type", "http") == "http" ) and ( "interval" in tracker and ( not ( 20 <= tracker.get("interval") <= 600 ) ) ):
                    results.append(f'Parameter interval value should be between 20 and 600 when endpoint_tracker_type is http in sdwan.feature_profiles.transport_profiles[{feature_profile["name"]}].ipv4_trackers[{tracker["name"]}]')
        for feature_profile in inventory.get("sdwan", {}).get("feature_profiles", {}).get("transport_profiles", []):
            # Validate transport ipv6 trackers referenced in transport ipv6 tracker group are defined
            ipv6_tracker_feature_names = [tracker["name"] for tracker in feature_profile.get("ipv6_trackers", [])]
            for ipv6_tracker_group in feature_profile.get("ipv6_tracker_groups", []):
                for index, tracker_feature_name in enumerate(ipv6_tracker_group.get("trackers", [])):
                    if tracker_feature_name not in ipv6_tracker_feature_names:
                        results.append(f'IPv6 Transport Tracker Feature {tracker_feature_name} is not defined, but is referenced in sdwan.feature_profiles.transport_profiles[{feature_profile["name"]}].ipv6_tracker_groups[{ipv6_tracker_group["name"]}].trackers[{index}]')
            # Verify transport IPv6 trackers have respective parameter value as per endpoint_tracker_type
            for ipv6_tracker in feature_profile.get("ipv6_trackers", []):
                if ( ipv6_tracker.get("endpoint_tracker_type", "http") == "http" ) and ( "interval" in ipv6_tracker and ( not ( 20 <= ipv6_tracker.get("interval") <= 600 ) ) ):
                    results.append(f'Parameter interval value should be between 20 and 600 when endpoint_tracker_type is http in sdwan.feature_profiles.transport_profiles[{feature_profile["name"]}].ipv6_trackers[{ipv6_tracker["name"]}]')
        return results