import re

class Rule:
    id = "301"
    description = "Verify Device Variables"
    severity = "HIGH"
    
    # Verify Device Variables
    # Get Feature Tempate Variables
    # Get Security Policy Definition Variables
    @classmethod
    def get_feature_vars(cls, key, object):
        results = []
        if isinstance(object, dict):
            for key, obj in object.items():
                explore_obj = cls.get_feature_vars(key, obj)
                for entry in explore_obj:
                    if not entry in results:
                        results.append(entry)
        elif isinstance(object, list):
            for obj in object:
                explore_obj = cls.get_feature_vars("", obj)
                for entry in explore_obj:
                    if not entry in results:
                        results.append(entry)
        elif isinstance(object, (str, int)):
            if key.endswith("_variable"):
                results.append(object)
            # Find vars in CLI templates
            elif isinstance(object, str) and "{{" in object:
                vars = re.findall(r"{{.*?}}", object)
                for var in vars:
                    var_name = re.sub(r"{{|}}|\s", "", var)
                    results.append(var_name)
        return(results)

    @classmethod
    def get_device_feature_templates_policies(cls, object, inventory='none'):
        feature_template_types_in_device_template = ["aaa_template", "banner_template", "bfd_template", "bgp_template", "cli_template", "dhcp_server_template", "ethernet_interface_templates", "global_settings_template", "igmp_template", "ipsec_interface_templates", "logging_template", "multicast_template", "ntp_template", "omp_template", "ospf_template", "pim_template", "secure_internet_gateway_template", "security_template", "sig_credentials_template", "snmp_template", "svi_interface_templates", "switchport_templates", "system_template", "thousandeyes_template", "vpn_0_template", "vpn_512_template", "vpn_service_templates", "gre_interface_templates", "cellular_interface_templates", "cellular_controller_templates", "cellular_profile_templates"]
        feature_policy_types_in_device_template = ["security_policy"]
        definitions_in_feature_policy = ["firewall_policies","unified_firewall_policies"]
        definitions_in_localized_policy = ["ipv4_access_control_lists", "ipv4_device_access_policies", "ipv6_access_control_lists", "ipv6_device_access_policies", "rewrite_rules", "route_policies", "qos_maps"]
        results = []
        if isinstance(object, dict):
            if "name" in object and "description" not in object:
                results.append(object['name'])
            for key, obj in object.items():
                if key in feature_template_types_in_device_template:
                    if isinstance(obj, str):
                        results.append(obj)
                    elif isinstance(obj, dict):
                        explore_obj = cls.get_device_feature_templates_policies(obj)
                        if isinstance(explore_obj, list):
                            for entry in explore_obj:
                                if not entry in results:
                                    results.append(entry)
                    elif isinstance(obj, list):
                        for obj_entry in obj:
                            explore_obj = cls.get_device_feature_templates_policies(obj_entry)
                            if isinstance(explore_obj, list):
                                for entry in explore_obj:
                                    if not entry in results:
                                        results.append(entry)
                elif key in feature_policy_types_in_device_template:
                    if isinstance(obj, dict) and 'name' in obj:
                        security_policy_name = obj['name']
                        # Find the specific security policy by name
                        for fp in inventory.get('sdwan', {}).get('security_policies', {}).get('feature_policies', {}):
                            if fp.get('name') == security_policy_name:
                                for policy_key, policy_obj in fp.items():
                                    if policy_key in definitions_in_feature_policy:
                                        if fp.get('mode','security') == 'security': # This is for Security Policy with mode Security
                                            if isinstance(policy_obj, str):
                                                if not policy_obj in results:
                                                    results.append(policy_obj)
                                            elif isinstance(policy_obj, list):
                                                for obj_entry in policy_obj:
                                                    if not obj_entry in results:
                                                        results.append(obj_entry)
                                        if fp.get('mode','security') == 'unified': # This is for Security Policy with mode Unified
                                            for upolicy_obj in policy_obj:
                                                if isinstance(upolicy_obj, dict):
                                                    for key2, obj2 in upolicy_obj.items():
                                                        if key2 == 'firewall_policy':
                                                            if isinstance(obj2, str):
                                                                if not obj2 in results:
                                                                    results.append(obj2)
                                break
                elif key == "localized_policy":
                    for lp in inventory.get('sdwan', {}).get('localized_policies', {}).get('feature_policies', {}):
                        if lp["name"] != obj:
                            continue
                        for key, obj in lp.get('definitions', {}).items():
                            if key in definitions_in_localized_policy:
                                if isinstance(obj, str):
                                    if not obj in results:
                                        results.append(obj)
                                elif isinstance(obj, list):
                                    for obj_entry in obj:
                                        if not obj_entry in results:
                                            results.append(obj_entry)
                        break
        return(results)

    @classmethod
    def is_security_policy_variable(cls, feature_template_name, inventory):
        """
        Check if a feature template belongs to security policy definitions
        """
        # Check in security_policies definitions
        for type in inventory.get('sdwan', {}).get('security_policies', {}).get('definitions', {}):
            for template in inventory['sdwan']['security_policies']['definitions'][type]:
                if template.get('name') == feature_template_name:
                    return True
        return False

    @classmethod
    def check_variable_exists(cls, var, device_variables, security_policy_vars):
        """
        Check if a variable exists in device_variables, accounting for vedgePolicy/ prefix
        for security policy variables only
        """
        # Check direct match first
        if var in device_variables:
            return True, var
        
        # Check with vedgePolicy/ prefix ONLY for security policy variables
        if var in security_policy_vars:
            vedge_policy_var = f"vedgePolicy/{var}"
            if vedge_policy_var in device_variables:
                return True, vedge_policy_var
            
        return False, None

    @classmethod
    def verify_device_vars(cls, inventory):
        feature_var_dict = {}
        device_template_var_dict = {}
        results = []
        # Get the list of variables per feature template
        for type in inventory.get('sdwan', {}).get('edge_feature_templates', {}):
            for template in inventory['sdwan']['edge_feature_templates'][type]:
                template_vars = cls.get_feature_vars("", template)
                feature_var_dict[template['name']] = template_vars
        # Get the list of variables per security policy definition
        for type in inventory.get('sdwan', {}).get('security_policies', {}).get('definitions', {}):
            for template in inventory['sdwan']['security_policies']['definitions'][type]:
                template_vars = cls.get_feature_vars("", template)
                feature_var_dict[template['name']] = template_vars
        for type in inventory.get('sdwan', {}).get('localized_policies', {}).get('definitions', {}):
            for template in inventory['sdwan']['localized_policies']['definitions'][type]:
                template_vars = cls.get_feature_vars("", template)
                feature_var_dict[template['name']] = template_vars
        # Determine the list of variables for each device template
        device_template_security_vars_dict = {}  # Track which variables come from security policies
        for deviceTemplate in inventory.get('sdwan', {}).get('edge_device_templates', {}):
            device_template_vars = []
            device_template_security_vars = set()
            # Retrieve the list of feature templates in the device template
            feature_template_list = cls.get_device_feature_templates_policies(deviceTemplate, inventory)
            for feature_template in feature_template_list:
                if feature_template in feature_var_dict:
                    for var in feature_var_dict[feature_template]:
                        device_template_vars.append(var)
                        # Check if this variable comes from a security policy
                        if cls.is_security_policy_variable(feature_template, inventory):
                            device_template_security_vars.add(var)
                else:
                    results.append("Feature template/policy not found: " + feature_template)
            device_template_var_dict[deviceTemplate['name']] = device_template_vars
            device_template_security_vars_dict[deviceTemplate['name']] = device_template_security_vars
        


        # Verify the presence of the required device variables in each site and router
        for site in inventory.get('sdwan', {}).get('sites', {}):
            for router in site['routers']:
                # Verify missing vars in the router
                if 'device_template' in router:
                    if "model" not in router:
                        results.append(router['chassis_id'] + " - missing model")
                    if router['device_template'] in device_template_var_dict:
                        security_policy_vars = device_template_security_vars_dict.get(router['device_template'], set())
                        for var in device_template_var_dict[router['device_template']]:
                            var_exists, matched_var = cls.check_variable_exists(var, router['device_variables'], security_policy_vars)
                            if not var_exists:
                                results.append(router['chassis_id'] + " - " + router['device_template'] + " - missing variable: " + var)
                            # Verify empty vars in the router
                            elif router['device_variables'].get(matched_var) is None or str(router['device_variables'].get(matched_var)).strip() == '':
                                results.append(router['chassis_id'] + " - " + router['device_template'] + " - empty variable value: " + var)
                        
                        # Verify if the router has unnecessary vars - can the severity be set to warning or minor?
                        required_vars = set(device_template_var_dict[router['device_template']])
                        # Add vedgePolicy/ prefixed versions ONLY for security policy vars to the acceptable set
                        acceptable_vars = required_vars.copy()
                        for req_var in security_policy_vars:
                            acceptable_vars.add(f"vedgePolicy/{req_var}")

                        for var in router['device_variables']:
                            # Remove vedgePolicy/ prefix for comparison if it exists
                            base_var = var.replace("vedgePolicy/", "") if var.startswith("vedgePolicy/") else var
                            if base_var not in required_vars and var not in acceptable_vars:
                                results.append(router['chassis_id'] + " - " + router['device_template'] + " - unnecessary variable: " + var)
                    else:
                        results.append("Router device template not found: " + router['device_template'])
        return results

    @classmethod
    def match(cls, inventory):
        results = []
        results = cls.verify_device_vars(inventory)
        return results