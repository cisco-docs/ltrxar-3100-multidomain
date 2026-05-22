import re


class Rule:
    id = "303"
    description = "Verify Management IP Variable Resolution"
    severity = "HIGH"

    # Regex pattern to validate IP address (with or without CIDR notation)
    # Matches: 10.1.1.1, 10.1.1.1/32, 192.168.1.100/24, etc.
    IP_PATTERN = re.compile(
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
        r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
        r'(?:/(?:3[0-2]|[12]?[0-9]))?$'
    )

    @classmethod
    def match(cls, inventory):
        """
        Validate management_ip_variable resolution for all routers.

        Resolution priority:
        1. Router-level management_ip_variable (highest priority)
        2. Global sdwan-level management_ip_variable (fallback)

        Validates:
        - If management_ip_variable is specified, the referenced variable
          must exist in the router's device_variables
        - The resolved value must be a valid IP address (with or without CIDR)
        """
        results = []

        sdwan_data = inventory.get('sdwan', {})

        # Get global management_ip_variable (2nd preference)
        global_mgmt_ip_var = sdwan_data.get('management_ip_variable')

        for site in sdwan_data.get('sites', []):
            site_id = site.get('id', 'unknown')

            for router in site.get('routers', []):
                chassis_id = router.get('chassis_id', 'unknown')
                device_vars = router.get('device_variables', {})

                # Determine effective management_ip_variable
                # Router-level takes precedence over global
                router_mgmt_ip_var = router.get('management_ip_variable')
                effective_mgmt_ip_var = router_mgmt_ip_var or global_mgmt_ip_var

                # Skip validation if no management_ip_variable is configured
                if not effective_mgmt_ip_var:
                    continue

                # Determine the source for error messaging
                var_source = "router" if router_mgmt_ip_var else "global"

                # Check if the referenced variable exists in device_variables
                if effective_mgmt_ip_var not in device_vars:
                    results.append(
                        f"{chassis_id} (site {site_id}) - management_ip_variable "
                        f"'{effective_mgmt_ip_var}' ({var_source}) not found in device_variables"
                    )
                    continue

                # Get the resolved value
                resolved_value = device_vars[effective_mgmt_ip_var]

                # Check if the value is empty or None
                if resolved_value is None or str(resolved_value).strip() == '':
                    results.append(
                        f"{chassis_id} (site {site_id}) - management_ip_variable "
                        f"'{effective_mgmt_ip_var}' ({var_source}) has empty value in device_variables"
                    )
                    continue

                # Convert to string for validation
                resolved_str = str(resolved_value)

                # Validate IP address format
                if not cls.IP_PATTERN.match(resolved_str):
                    results.append(
                        f"{chassis_id} (site {site_id}) - management_ip_variable "
                        f"'{effective_mgmt_ip_var}' ({var_source}) resolves to invalid IP: '{resolved_str}'"
                    )

        return results
