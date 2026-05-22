class Rule:
    id = "417"
    description = "Validate policy object features"
    severity = "HIGH"

    @classmethod
    def validate_ports(cls, ports):
        # The Advanced regex validation logic
        for port in ports:
            port_str = str(port)
            if "-" in port_str:
                start, end = port_str.split("-")
                if not (start.isdigit() and end.isdigit() and 0 <= int(start) < int(end) <= 65535):
                    return False
            else:
                if not (port_str.isdigit() and 0 <= int(port_str) <= 65535):
                    return False
        return True

    @classmethod
    def security_policy_objects_validation(cls, inventory):
        result = []
        policy_object_profile = inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {})

        # Validate Security Local Application List feature
        for security_local_app_list in policy_object_profile.get("security_local_application_lists", []):
            # Application list must have at least one of applications or application_families configured
            if "applications" not in security_local_app_list and "application_families" not in security_local_app_list:
                result.append(f"Security local application list '{security_local_app_list['name']}' must have at least one of applications or application_families configured in sdwan.feature_profiles.policy_object_profile.security_local_application_lists[{security_local_app_list['name']}]")

        # Validate Security Port Lists
        for security_port_list in policy_object_profile.get("security_port_lists", []):
            '''
            sub check 1 -- Validate that each port entry in the port list contain's number between range 0 to 65535 or \
                it can also be in a range format X-Y where X < Y
            '''
            if not cls.validate_ports(security_port_list["ports"]):
                result.append(f"Invalid port list format. Expecting values in range 0-65535 for sdwan.feature_profiles.policy_object_profile.security_port_lists[{security_port_list['name']}]")
        
        # Validate Security Advanced Inspection Profile
        for security_advanced_inspection_profile in policy_object_profile.get("security_advanced_inspection_profiles", []):
            # at least one of [advanced_malware_protection, intrusion_prevention, url_filtering] should be defined
            if not security_advanced_inspection_profile.get("advanced_malware_protection") and not security_advanced_inspection_profile.get("intrusion_prevention") and not security_advanced_inspection_profile.get("url_filtering"):
                result.append(f"Security advanced inspection profile '{security_advanced_inspection_profile['name']}' must have at least one of advanced_malware_protection, intrusion_prevention or url_filtering defined in sdwan.feature_profiles.policy_object_profile.security_advanced_inspection_profiles[{security_advanced_inspection_profile['name']}]")

        # Validate Security Advanced Malware Protection Profile feature
        for security_advanced_malware_protection_profile in policy_object_profile.get("security_advanced_malware_protection_profiles", []):
            # Only when file_analysis is enabled, file_analysis_alert_log_level, tg_cloud_region and file_analysis_file_types should be defined
            if security_advanced_malware_protection_profile.get("file_analysis", False):
                if "file_analysis_alert_log_level" not in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' must have file_analysis_alert_log_level defined when file_analysis is enabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
                if "tg_cloud_region" not in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' must have tg_cloud_region defined when file_analysis is enabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
                if "file_analysis_file_types" not in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' must have file_analysis_file_types defined when file_analysis is enabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
                # At least one file type should be defined
                elif not security_advanced_malware_protection_profile["file_analysis_file_types"]:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' must have at least one file type defined in file_analysis_file_types when file_analysis is enabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
            else:
                if "file_analysis_alert_log_level" in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' should not have file_analysis_alert_log_level defined when file_analysis is disabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
                if "tg_cloud_region" in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' should not have tg_cloud_region defined when file_analysis is disabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")
                if "file_analysis_file_types" in security_advanced_malware_protection_profile:
                    result.append(f"Security advanced malware protection '{security_advanced_malware_protection_profile['name']}' should not have file_analysis_file_types defined when file_analysis is disabled in sdwan.feature_profiles.policy_object_profile.security_advanced_malware_protection_profiles[{security_advanced_malware_protection_profile['name']}]")

        # Validate Security Geo Location Lists
        for security_geo_list in policy_object_profile.get("security_geo_location_lists", []):
            # sub check -- Validate atleast if one country code or continent code is configured
            if not security_geo_list.get("country_codes", []) and not security_geo_list.get("continent_codes", []):
                result.append(f"Security Geo Location List '{security_geo_list['name']}' must have at least one country_codes or continent_codes configured in sdwan.feature_profiles.policy_object_profile.security_geo_location_lists[{security_geo_list['name']}]")
        
        # Validate Security URL Filtering Profile
        for security_url_filtering_profile in policy_object_profile.get("security_url_filtering_profiles", []):
            # redirect_url should only be defined when block_page_action is set to redirect-url
            if security_url_filtering_profile.get("block_page_action") == "redirect-url":
                if "redirect_url" not in security_url_filtering_profile:
                    result.append(f"Security URL Filtering Profile '{security_url_filtering_profile['name']}' must have redirect_url defined when block_page_action is set to redirect-url in sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles[{security_url_filtering_profile['name']}]")
            else:
                if "redirect_url" in security_url_filtering_profile:
                    result.append(f"Security URL Filtering Profile '{security_url_filtering_profile['name']}' should not have redirect_url defined when block_page_action is not set to redirect-url in sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles[{security_url_filtering_profile['name']}]")

            # alerts should only be defined when enable_alerts is set to true
            if security_url_filtering_profile.get("enable_alerts", False):
                if "alerts" not in security_url_filtering_profile:
                    result.append(f"Security URL Filtering Profile '{security_url_filtering_profile['name']}' must have alerts defined when enable_alerts is set to true in sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles[{security_url_filtering_profile['name']}]")
            else:
                if "alerts" in security_url_filtering_profile:
                    result.append(f"Security URL Filtering Profile '{security_url_filtering_profile['name']}' should not have alerts defined when enable_alerts is set to false in sdwan.feature_profiles.policy_object_profile.security_url_filtering_profiles[{security_url_filtering_profile['name']}]")

        # Validate Security Zones
        defined_lan_vpns = [vpn.get('name') for profile in inventory.get('sdwan', {}).get('feature_profiles', {}).get('service_profiles', []) for vpn in profile.get('lan_vpns', [])]
        for security_zone in policy_object_profile.get("security_zones", []):
            # only one of vpns or interfaces should be configured
            if ("vpns" in security_zone and "interfaces" in security_zone) or ("vpns" not in security_zone and "interfaces" not in security_zone):
                result.append(f"Security Zone '{security_zone['name']}' must have either vpns or interfaces configured in sdwan.feature_profiles.policy_object_profile.security_zones[{security_zone['name']}]")

            # Check for duplicate VPNs
            if "vpns" in security_zone:
                vpns = security_zone.get("vpns", [])
                if len(vpns) != len(set(vpns)):
                    result.append(f"Security Zone '{security_zone['name']}' has duplicate VPNs in sdwan.feature_profiles.policy_object_profile.security_zones[{security_zone['name']}]")

                # Validate VPN references exist in service_profiles.lan_vpns
                for vpn in vpns:
                    if vpn not in defined_lan_vpns:
                        result.append(f"Security Zone '{security_zone['name']}' references undefined VPN '{vpn}' in sdwan.feature_profiles.policy_object_profile.security_zones[{security_zone['name']}]")

            # Check for duplicate interfaces
            if "interfaces" in security_zone:
                interfaces = security_zone.get("interfaces", [])
                if len(interfaces) != len(set(interfaces)):
                    result.append(f"Security Zone '{security_zone['name']}' has duplicate interfaces in sdwan.feature_profiles.policy_object_profile.security_zones[{security_zone['name']}]")

        return result

    @classmethod
    def match(cls, inventory):
        results = []

        # Validate application_list feature
        for application_list in inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {}).get("application_lists", []):
            # Application list must have either applications or application_families configured, always one of those.
            if ("applications" not in application_list and "application_families" not in application_list) or ("applications" in application_list and "application_families" in application_list):
                results.append(f"Application list '{application_list['name']}' must have either applications or application_families configured in the sdwan.feature_profiles.policy_object_profile.application_lists[{application_list['name']}]")
                
        # Validate app_probe_classes feature
        inventory_policy_objects = inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {})
        for app_probe_class in inventory_policy_objects.get("app_probe_classes", []):
            if app_probe_class.get('forwarding_class', None):
                first_class_match = next((item for item in inventory_policy_objects.get("forwarding_classes", []) if item.get('name') == app_probe_class['forwarding_class']), None)
                if not first_class_match:
                    results.append(f"The forwarding class '{app_probe_class['forwarding_class']}' in app_probe_class '{app_probe_class['name']}' is not defined in sdwan.feature_profiles.policy_object_profile.forwarding_classes")
        
        # Validate Preferred Color Group feature - Tertiary Colors should not be configured without configuring Secondary Colors
        for preferred_color_group in inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {}).get("preferred_color_groups", []):
            if "tertiary_colors" in preferred_color_group and "secondary_colors" not in preferred_color_group:
                results.append(f"Preferred color group '{preferred_color_group['name']}' has tertiary_colors configured without secondary_colors in sdwan.feature_profiles.policy_object_profile.preferred_color_groups[{preferred_color_group['name']}]")
        
        # Validate SLA Class feature:
        # at least one value among latency, jitter or loss is required;
        # if fallback_best_tunnel_criteria contains jitter, fallback_best_tunnel_jitter_variance must be defined;
        # if fallback_best_tunnel_criteria contains latency, fallback_best_tunnel_latency_variance must be defined;
        # if fallback_best_tunnel_criteria contains loss, fallback_best_tunnel_loss_variance must be defined.
        for sla_class in inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {}).get("sla_classes", []):
            if 'jitter_ms' not in sla_class and 'latency_ms' not in sla_class and 'loss_percentage' not in sla_class:
                results.append(f"SLA class '{sla_class['name']}' must have at least one of jitter_ms, latency_ms or loss_percentage defined in sdwan.feature_profiles.policy_object_profile.sla_classes[{sla_class['name']}]")
            if sla_class.get('fallback_best_tunnel_criteria', None):
                criteria = sla_class['fallback_best_tunnel_criteria']
                if 'jitter' in criteria and 'fallback_best_tunnel_jitter_variance' not in sla_class:
                    results.append(f"SLA class '{sla_class['name']}' has 'jitter' in fallback_best_tunnel_criteria but fallback_best_tunnel_jitter_variance is not defined in sdwan.feature_profiles.policy_object_profile.sla_classes[{sla_class['name']}]")
                if 'latency' in criteria and 'fallback_best_tunnel_latency_variance' not in sla_class:
                    results.append(f"SLA class '{sla_class['name']}' has 'latency' in fallback_best_tunnel_criteria but fallback_best_tunnel_latency_variance is not defined in sdwan.feature_profiles.policy_object_profile.sla_classes[{sla_class['name']}]")
                if 'loss' in criteria and 'fallback_best_tunnel_loss_variance' not in sla_class:
                    results.append(f"SLA class '{sla_class['name']}' has 'loss' in fallback_best_tunnel_criteria but fallback_best_tunnel_loss_variance is not defined in sdwan.feature_profiles.policy_object_profile.sla_classes[{sla_class['name']}]")

        # Validate Security Policy Objects
        results += cls.security_policy_objects_validation(inventory)

        return results
