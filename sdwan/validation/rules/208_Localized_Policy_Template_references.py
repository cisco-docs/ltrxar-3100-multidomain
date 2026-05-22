class Rule:
    id = "208"
    description = "Verify Localized Policy Definition references in Feature Templates"
    severity = "HIGH"

    # List all the feature templates fields that might reference to localized policy definitions
    # This is a dict with key = feature template field, value = localized policy definition type
    ft_fields_with_local_policy_reference = {
        "route_policy": "route_policies",
        "route_policy_in": "route_policies",
        "route_policy_out": "route_policies",
        "ipv4_egress_access_list": "ipv4_access_control_lists",
        "ipv4_ingress_access_list": "ipv4_access_control_lists",
        "ipv6_egress_access_list": "ipv6_access_control_lists",
        "ipv6_ingress_access_list": "ipv6_access_control_lists",
        "qos_map": "qos_maps",
        "vpn_qos_map": "qos_maps",
        "rewrite_rule": "rewrite_rules",
    }
    # Adding variable option for each key listed above
    ft_fields_with_local_policy_reference.update({k + "_variable": v for k, v in ft_fields_with_local_policy_reference.items()})

    # Feature Templates can be referenced in Device Templates at ['sdwan']['edge_device_templates'] in 3 levels
    feature_template_level1 = ['system_template', 'logging_template', 'ntp_template', 'aaa_template', 'bfd_template', 'omp_template', 'security_template', 'vpn_0_template', 'vpn_512_template', 'vpn_service_templates', 'global_settings_template', 'banner_template', 'snmp_template', 'cli_template', 'switchport_templates', 'thousandeyes_template', 'cellular_controller_templates']

    feature_template_level2 = ['bgp_template', 'ethernet_interface_templates', 'igmp_template', 'ipsec_interface_templates', 'svi_interface_templates', 'multicast_template', 'ospf_template', 'pim_template', 'secure_internet_gateway_template', 'sig_credentials_template', 'container_profile', 'cellular_profile_templates', 'gre_interface_templates', 'cellular_interface_templates']
    
    feature_template_level3 = ['dhcp_server_template']
    
    # Feature Templates defined at ['sdwan']['edge_feature_templates']
    edge_feature_templates = ['bgp_templates', 'ethernet_interface_templates', 'igmp_templates', 'ipsec_interface_templates', 'svi_interface_templates', 'multicast_templates', 'ospf_templates', 'pim_templates', 'secure_internet_gateway_templates', 'sig_credentials_templates','system_templates', 'logging_templates', 'ntp_templates', 'aaa_templates', 'bfd_templates', 'omp_templates', 'security_templates', 'vpn_templates', 'global_settings_templates', 'banner_templates', 'snmp_templates', 'cli_templates', 'switchport_templates', 'thousandeyes_templates', 'dhcp_server_templates', 'secure_app_hosting_templates', 'gre_interface_templates', 'cellular_interface_templates', 'cellular_controller_templates', 'cellular_profile_templates']
    
    # Feature Template keys in ['sdwan']['edge_device_templates'] are mapped to the keys in ['sdwan']['edge_feature_templates']
    # as they are not the same in both the places for all scenarios
    feature_template_mapping = {
        'system_template': 'system_templates',
        'logging_template': 'logging_templates',
        'ntp_template': 'ntp_templates',
        'aaa_template': 'aaa_templates',
        'bfd_template': 'bfd_templates',
        'omp_template': 'omp_templates',
        'security_template': 'security_templates',
        'vpn_0_template': 'vpn_templates',
        'vpn_512_template': 'vpn_templates',
        'vpn_service_templates': 'vpn_templates',
        'global_settings_template': 'global_settings_templates',
        'igmp_template': 'igmp_templates',
        'banner_template': 'banner_templates',
        'snmp_template': 'snmp_templates',
        'cli_template' : 'cli_templates',
        'switchport_templates': 'switchport_templates',
        'thousandeyes_template': 'thousandeyes_templates',
        'bgp_template': 'bgp_templates',
        'ethernet_interface_templates': 'ethernet_interface_templates',
        'ipsec_interface_templates': 'ipsec_interface_templates',
        'svi_interface_templates': 'svi_interface_templates',
        'multicast_template': 'multicast_templates',
        'ospf_template': 'ospf_templates',
        'pim_template': 'pim_templates',
        'secure_internet_gateway_template': 'secure_internet_gateway_templates',
        'sig_credentials_template': 'sig_credentials_templates',
        'dhcp_server_template': 'dhcp_server_templates',
        'container_profile': 'secure_app_hosting_templates',
        'gre_interface_templates': 'gre_interface_templates',
        'cellular_interface_templates': 'cellular_interface_templates',
        'cellular_controller_templates': 'cellular_controller_templates',
        'cellular_profile_templates': 'cellular_profile_templates'
    }

    # Extract the Feature Template names referenced in Device Templates at ['sdwan']['edge_device_templates']
    # Extract the Localized Policy names referenced in Device Templates at ['sdwan']['edge_device_templates']
    @classmethod
    def build_device_template_dict(cls, inventory):
        device_template_dict = {'device_templates': []}
        ## Loop through the device templates
        for device_template in inventory.get("sdwan", {}).get("edge_device_templates", []):
            template = {
                'name': device_template.get('name'), 
                'feature_templates': {},
                'localized_policy': ''
            }
            ## Initialize the list of feature templates for each feature type
            for feature in cls.feature_template_level1:
                template['feature_templates'][feature] = []
            for subfeature in cls.feature_template_level2:
                template['feature_templates'][subfeature] = []
            for subfeature_l3 in cls.feature_template_level3:
                template['feature_templates'][subfeature_l3] = []
            ## Add the localized policy to the result dictionary
            if "localized_policy" in device_template:
                template['localized_policy'] = device_template.get('localized_policy')
            ## Loop through the feature templates in the device template at Level 1
            for feature in cls.feature_template_level1:
                feature_val = device_template.get(feature)
                if feature_val:
                    ## Check if the feature template is a dictionary
                    if isinstance(feature_val, dict):
                        template['feature_templates'][feature].extend([feature_val.get('name')])
                        ## Loop through the feature templates in the device template at Level 2
                        for subfeature in cls.feature_template_level2:
                            subfeature_val = feature_val.get(subfeature)
                            if subfeature_val:
                                if isinstance(subfeature_val, list):
                                    template['feature_templates'][subfeature].extend([subfeat.get('name') for subfeat in subfeature_val if isinstance(subfeat, dict)])
                                    for subfeat in subfeature_val:
                                        ## Loop through the feature templates in the device template at Level 3
                                        for subfeature_l3 in cls.feature_template_level3:
                                            subfeature_val_l3 = subfeat.get(subfeature_l3)
                                            if subfeature_val_l3:
                                                if isinstance(subfeature_val_l3, list):
                                                    template['feature_templates'][subfeature_l3].extend([subfeat.get('name') for subfeat in subfeature_val_l3 if isinstance(subfeat, dict)])
                                                else:
                                                    template['feature_templates'][subfeature_l3].append(subfeature_val_l3)
                                else:
                                    template['feature_templates'][subfeature].append(subfeature_val)
                    ## Check if the feature template is a list
                    elif isinstance(feature_val, list):
                        template['feature_templates'][feature].extend([feat.get('name') for feat in feature_val if isinstance(feat, dict)])
                        for feat in feature_val:
                            ## Loop through the feature templates in the device template at Level 2
                            for subfeature in cls.feature_template_level2:
                                subfeature_val = feat.get(subfeature)
                                if subfeature_val:
                                    if isinstance(subfeature_val, list):
                                        template['feature_templates'][subfeature].extend([subfeat.get('name') for subfeat in subfeature_val if isinstance(subfeat, dict)])
                                        for subfeat in subfeature_val:
                                            ## Loop through the feature templates in the device template at Level 3
                                            for subfeature_l3 in cls.feature_template_level3:
                                                subfeature_val_l3 = subfeat.get(subfeature_l3)
                                                if subfeature_val_l3:
                                                    if isinstance(subfeature_val_l3, list):
                                                        template['feature_templates'][subfeature_l3].extend([subfeat.get('name') for subfeat in subfeature_val_l3 if isinstance(subfeat, dict)])
                                                    else:
                                                        template['feature_templates'][subfeature_l3].append(subfeature_val_l3)
                                    else:
                                        template['feature_templates'][subfeature].append(subfeature_val)
                    else:
                        template['feature_templates'][feature].extend([feature_val])
            device_template_dict['device_templates'].append(template)
        return device_template_dict
    
    @classmethod
    def build_policy_feature_dict(cls, inventory):
        # Build the dictionary of per-type policy definitions in the localized policies
        policy_template_dict = {
        }
        for policy_template in inventory.get('sdwan', {}).get('localized_policies', {}).get('feature_policies', {}):
            policy_template_definitions = {}
            if "definitions" in policy_template:
                for policy_definition_type, policy_definition_names in policy_template['definitions'].items():
                    if not policy_definition_type in policy_template_definitions:
                        policy_template_definitions[policy_definition_type] = []
                    for policy_definition_name in policy_definition_names:
                        policy_template_definitions[policy_definition_type].append(policy_definition_name)
            policy_template_dict[policy_template['name']] = policy_template_definitions
        return policy_template_dict
    
    @classmethod
    def build_feature_template_keys_list(cls, element, feature_template_keys_list=None):
        if feature_template_keys_list is None:
            feature_template_keys_list = []
        if isinstance(element, dict):
            for key, value in element.items():
                if key in cls.ft_fields_with_local_policy_reference.keys():
                    feature_template_keys_list.append({key: value})
                cls.build_feature_template_keys_list(value, feature_template_keys_list)
        elif isinstance(element, list):
            for item in element:
                cls.build_feature_template_keys_list(item, feature_template_keys_list)
        return feature_template_keys_list
    
    @classmethod
    def build_feature_templates_policy_references_dict(cls, inventory):
        feature_templates_policy_references_dict = {}
        for feature_templates in inventory.get("sdwan", {}).get("edge_feature_templates", {}).values():
            for feature_template in feature_templates:
                feature_templates_policy_references_dict[feature_template.get("name")] = cls.build_feature_template_keys_list(feature_template)
        return feature_templates_policy_references_dict

    @classmethod
    def build_references_list(cls, inventory):
        references_list = []
        device_template_dict = cls.build_device_template_dict(inventory)
        feature_templates_policy_references_dict = cls.build_feature_templates_policy_references_dict(inventory)
        policy_dict = cls.build_policy_feature_dict(inventory)
        for device_template in device_template_dict.get("device_templates", []):
            entry = {"name": device_template["name"], 
                     "localized_policy": device_template["localized_policy"],
                     "created_policy_definitions": {},
                     "required_policy_definitions": {}}
            # Find created policy definitions created in localized policy
            if device_template["localized_policy"]:
                entry["created_policy_definitions"] = policy_dict.get(device_template["localized_policy"], {})
            # Find required policy definitions that are required in feature templates
            for feature_templates in device_template.get("feature_templates").values():
                for feature_template_name in feature_templates:
                    for reference in feature_templates_policy_references_dict.get(feature_template_name, []):
                        for reference_type, reference_value in reference.items():
                            if reference_type.endswith('_variable'):
                                reference_type = reference_type[:-9]
                                # If it's variable, resolve variable names from sites
                                if cls.ft_fields_with_local_policy_reference[reference_type] not in entry["required_policy_definitions"]:
                                    entry["required_policy_definitions"][cls.ft_fields_with_local_policy_reference[reference_type]] = []
                                for site in inventory.get('sdwan', {}).get('sites', {}):
                                    for router in site['routers']:
                                        if router.get('device_template'):
                                            if router['device_template'] in device_template["name"]:
                                                if router['device_variables'].get(reference_value) and router['device_variables'].get(reference_value) not in entry["required_policy_definitions"][cls.ft_fields_with_local_policy_reference[reference_type]]:
                                                    entry["required_policy_definitions"][cls.ft_fields_with_local_policy_reference[reference_type]].append(router['device_variables'].get(reference_value))

                            else:
                                # If it's not variable, add global value to reference list
                                if cls.ft_fields_with_local_policy_reference[reference_type] not in entry["required_policy_definitions"]:
                                    entry["required_policy_definitions"][cls.ft_fields_with_local_policy_reference[reference_type]] = []
                                entry["required_policy_definitions"][cls.ft_fields_with_local_policy_reference[reference_type]].append(reference_value)
            references_list.append(entry)
        return references_list

    @classmethod
    def match(cls, inventory):
        results = []
        references_list = cls.build_references_list(inventory)
        for device_template_references in references_list:
            for policy_type, policies_list in device_template_references["required_policy_definitions"].items():
                for policy_name in policies_list:
                    if policy_name not in device_template_references["created_policy_definitions"].get(policy_type, []):
                        results.append(f"Validation Error: {policy_type}:'{policy_name}' is required by device_template:'{device_template_references['name']}' but it is not defined in it's localized policy under [sdwan][localized_policies][feature_policies]<{device_template_references['localized_policy']}>[definitions][{policy_type}]\n")
        return results