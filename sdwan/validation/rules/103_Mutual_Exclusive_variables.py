import jmespath
import ruamel.yaml

class Rule:
    id = "103"
    description = "Verify if any mutually exclusive variables are defined"
    severity = "HIGH"
    
    #########################################################################################################################################
    # List of the mutually exclusive variables at different paths of the Data Model
    # This checks if variable1 and variable2 are defined in the provided object path
    # For any additional paths where the validation is required, add the mutually exclusive variables to the below list
    # No additional code changes should be required
    # The mutually exclusive variables are defined in the list with the following details:
    # 1. object_jmes_path: Path to the Flattened data of the feature in the Data Model, where the mutually exclusive variables could be defined. 
    #       example: "sdwan.policy_objects.zones" (zones is already a simple list, so no need to flatten it further)
    #       example: "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]" (flatten the list of sequences in the custom_control_topology)
    #       do not flatten with trailing [] if the object is not a list
    # 2. variable1_jmes_path: Path to the variable1 in the Data Model. Leave empty if the primary variable is at the root level
    #       example: "actions.service"
    #       example: ""                 (if the primary variable is at the root level already)
    # 3. variable1: The list of the name of variables which should be mutually exclusive with variable2
    #       example: ['vpn_ids']
    # 4. variable2_jmes_path: Path to the variable2 in the Data Model. Leave empty if the secondary variable is at the root level
    #       example: "match_criterias"
    #       example: ""                 (if the secondary variable is at the root level already)
    # 5. variable2: The list of the name of variables which should be mutually exclusive with variable1
    # For every variable in the variable1 list, every variable in the variable2 list will be checked
    #
    ## Sample List
    # Outcome: The below list will check if the variables 'tloc' and 'tloc_list' are defined in the 'actions.service' object of the 'sequences' list of the 'custom_control_topology' object
    # mutually_exclusive_variables_list = [
    #     {
    #         'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
    #         'variable1_jmes_path' : 'actions.service', 
    #         'variable1' : ['tloc'],
    #         'variable2_jmes_path' : 'actions.service',
    #         'variable2' : ['tloc_list'],
    #     },
    # ]
    # 2. Mutually exclusive value and set of variables at different paths of the Data Model 
    #  Checks if a specific parameter is configured and variables (mutually exclusive) are defined in the provided object path
    #  The mutually exclusive value and set of variables are defined in the same list 'mutually_exclusive_variables_list' with the following details:
    #       object_jmes_path: Path to the Flattened data of the feature in the Data Model, where the mutually exclusive value and variables could be defined with addition of a filter for value.
    #       example below checks if sequence type of control policy is set as 'route' (defined in the jmes filter: ?type=='route') then match criterias defined in the 'variables' are not allowed.
    #       variables_jmes_path: Path to the variables in the Data Model. Leave empty if the variable is at the root level
    # mutually_exclusive_variables_list = [
    #     {
    #        'object_jmes_path': "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[?type=='route'] | []",
    #        'variables_jmes_path' : 'match_criterias', 
    #        'variables' : ['group_id','domain_id'],
    #        'type': 'mut_exclusive_value'
    #     },
    # ]
    # 
    #########################################################################################################################################
    

    mutually_exclusive_variables_list = [
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'actions.service', 
            'variable1' : ['tloc'],
            'variable2_jmes_path' : 'actions.service',
            'variable2' : ['tloc_list'],
        },
        {
            'object_jmes_path': 'sdwan.policy_objects.zones',
            'variable1_jmes_path' : '', 
            'variable1' : ['vpn_ids'],
            'variable2_jmes_path' : '',
            'variable2' : ['interfaces'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.application_aware_routing[*].sequences[]',
            'variable1_jmes_path' : 'actions.sla_class_list', 
            'variable1' : ['preferred_colors'],
            'variable2_jmes_path' : 'actions.sla_class_list',
            'variable2' : ['preferred_color_group'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'actions.service', 
            'variable1' : ['tloc'],
            'variable2_jmes_path' : 'actions.service',
            'variable2' : ['tloc_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'actions', 
            'variable1' : ['tloc'],
            'variable2_jmes_path' : 'actions',
            'variable2' : ['tloc_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'actions', 
            'variable1' : ['service'],
            'variable2_jmes_path' : 'actions',
            'variable2' : ['tloc'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path': 'actions', 
            'variable1': ['service'],
            'variable2_jmes_path': 'actions',
            'variable2': ['tloc', 'vpn'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'actions', 
            'variable1' : ['nat_pool'],
            'variable2_jmes_path' : 'actions',
            'variable2' : ['nat_vpn'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'actions', 
            'variable1' : ['local_tloc_list'],
            'variable2_jmes_path' : 'actions',
            'variable2' : ['preferred_color_group'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['tloc'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['tloc_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['vpn'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['vpn_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.application_aware_routing[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['source_data_prefix'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['source_data_prefix_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.application_aware_routing[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['destination_data_prefix'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['destination_data_prefix_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['source_data_prefix'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['source_data_prefix_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['destination_data_prefix'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['destination_data_prefix_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['site_id'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['site_list','region_id', 'region_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['site_list'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['site_id', 'region_id', 'region_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['region_id'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['site_id', 'site_list','region_list'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[]',
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['region_list'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['site_id', 'site_list','region_id'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.gre_interface_templates',
            'variable1_jmes_path' : '', 
            'variable1' : ['tunnel_source_interface'],
            'variable2_jmes_path' : '',
            'variable2' : ['tunnel_source_interface_variable', 'tunnel_source_ip','tunnel_source_ip_variable'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.gre_interface_templates',
            'variable1_jmes_path' : '', 
            'variable1' : ['tunnel_source_interface_variable'],
            'variable2_jmes_path' : '',
            'variable2' : ['tunnel_source_interface', 'tunnel_source_ip','tunnel_source_ip_variable'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.gre_interface_templates',
            'variable1_jmes_path' : '', 
            'variable1' : ['tunnel_source_ip'],
            'variable2_jmes_path' : '',
            'variable2' : ['tunnel_source_interface', 'tunnel_source_interface_variable','tunnel_source_ip_variable'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.gre_interface_templates',
            'variable1_jmes_path' : '', 
            'variable1' : ['tunnel_source_ip_variable'],
            'variable2_jmes_path' : '',
            'variable2' : ['tunnel_source_interface', 'tunnel_source_interface_variable','tunnel_source_ip'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.feature_policies[*].traffic_data[].site_region_vpn[]',
            'variable1_jmes_path' : '', 
            'variable1' : ['site_lists'],
            'variable2_jmes_path' : '',
            'variable2' : ['region_list','region'],
        },
        {
            'object_jmes_path': 'sdwan.centralized_policies.feature_policies[*].traffic_data[].site_region_vpn[]',
            'variable1_jmes_path' : '', 
            'variable1' : ['region_list'],
            'variable2_jmes_path' : '',
            'variable2' : ['region'],
        },
        {
            'object_jmes_path': "sdwan.security_policies.definitions.zone_based_firewall[].rules[]",
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['source_port_lists'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['source_ports','source_port_ranges']
        },
        {
            'object_jmes_path': "sdwan.security_policies.definitions.zone_based_firewall[].rules[]",
            'variable1_jmes_path' : 'match_criterias', 
            'variable1' : ['destination_port_lists'],
            'variable2_jmes_path' : 'match_criterias',
            'variable2' : ['destination_ports','destination_port_ranges']
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[?type=='route'] | []",
            'variables_jmes_path' : 'match_criterias', 
            'variables' : ['group_id','domain_id'],
            'type': 'mut_exclusive_value'
        },    
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[?type=='tloc'] | []",
            'variables_jmes_path' : 'match_criterias', 
            'variables' : ['community','community_additive','origin','path_type','vpn_list','vpn','ipv4_prefix_list'],
            'type': 'mut_exclusive_value'
        },   
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[?type=='tloc'] | []",
            'variables_jmes_path' : 'actions', 
            'variables' : ['community_list','expanded_community_list','tloc','tloc_list','tloc_action','service','export_to_vpn_list'],
            'type': 'mut_exclusive_value'
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.control_policy.custom_control_topology[*].sequences[?ip_type=='all' && type=='route'] | []",
            'variables_jmes_path' : 'match_criterias', 
            'variables' : ['ipv4_prefix_list'],
            'type': 'mut_exclusive_value'
        }, 
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[?type=='application_firewall' || type=='qos' || type=='service_chaining' || type=='traffic_engineering'] | []",
            'variables_jmes_path' : 'match_criterias', 
            'variables' : ['dns_application_list','dns','traffic_to','destination_region'],
            'type': 'mut_exclusive_value'
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[?type=='application_firewall'] | []",
            'variables_jmes_path' : 'actions', 
            'variables' : ['cflowd','sig','redirect_dns','loss_correction','nat_pool','nat_vpn','appqoe_optimization','dscp','forwarding_class','local_tloc_list','next_hop','preferred_color_group','policer_list','service','tloc','tloc_list','vpn'],
            'type': 'mut_exclusive_value'
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[?type=='qos'] | []",
            'variables_jmes_path' : 'actions', 
            'variables' : ['cflowd','sig','redirect_dns','nat_pool','nat_vpn','appqoe_optimization','local_tloc_list','next_hop','preferred_color_group','service','tloc','tloc_list','vpn'],
            'type': 'mut_exclusive_value'
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[?type=='service_chaining'] | []",
            'variables_jmes_path' : 'actions', 
            'variables' : ['cflowd','sig','redirect_dns','loss_correction','nat_pool','nat_vpn','appqoe_optimization','dscp','forwarding_class','local_tloc_list','next_hop','preferred_color_group','policer_list'],
            'type': 'mut_exclusive_value'
        },
        {
            'object_jmes_path': "sdwan.centralized_policies.definitions.data_policy.traffic_data[*].sequences[?type=='traffic_engineering'] | []",
            'variables_jmes_path' : 'actions', 
            'variables' : ['cflowd','sig','redirect_dns','loss_correction','nat_pool','nat_vpn','appqoe_optimization','dscp','forwarding_class','preferred_color_group','policer_list','service'],
            'type': 'mut_exclusive_value'
        },
    ]


    @classmethod
    def check_parameters(cls, data, path=""):
        # This function checks if the any parameter is defined as global and variable at the same time
        results = []
        if isinstance(data, dict):
            for key, value in data.items():
                new_path = f"{path}.{key}" if path else key
                if key.endswith("_variable") and key[:-9] in data:
                    results.append(f'Mutually exclusive parameters {key[:-9]} and {key} are defined in the {path}')
                results.extend(cls.check_parameters(value, new_path))
        elif isinstance(data, list):
            for index, value in enumerate(data):
                if isinstance(value, dict) or isinstance(value, ruamel.yaml.comments.CommentedMap):
                    path_extenstion = value.get("name", index)
                else:
                    path_extenstion = index
                new_path = f"{path}[{path_extenstion}]"
                results.extend(cls.check_parameters(value, new_path))
        return results
    

    # Loop through the mutually_exclusive_variables_list and check if the mutually exclusive variables are defined
    @classmethod
    def match(cls, inventory):
        results = []
        # Loop over all parameters and report if the same parameter is defined as global and variable at the same time
        results.extend(cls.check_parameters(inventory.get("sdwan", {}).get("edge_feature_templates", {})))
        # Loop through the mutually_exclusive_variables_list
        for each_exclusion_item in cls.mutually_exclusive_variables_list:
            try:
                data = jmespath.search(each_exclusion_item.get('object_jmes_path', "*"), inventory)
                if each_exclusion_item.get('type') == 'mut_exclusive_value':
                    # Extract the data from the Data Model using the object_jmes_path
                    if data is not None:
                        # Loop through the data
                        if isinstance(data, dict):
                            data = [data]
                        for each_data in data:
                            # Process data for the exclusive parameter use-case with filter
                                if each_exclusion_item.get('variables_jmes_path') == "":
                                    model_data = each_data
                                else:
                                    model_data = jmespath.search(each_exclusion_item.get('variables_jmes_path'), each_data)
                                if model_data is not None:
                                    for test_var in each_exclusion_item.get('variables', []):
                                        if test_var in model_data:

                                            results.append('Mutually exclusive parameter setting and variable defined at ' + each_exclusion_item.get('object_jmes_path', "*" ) + ' ' + test_var + ' not allowed')
                else:            
                # Extract the data from the Data Model using the object_jmes_path
                    if data is not None:
                        # Loop through the data
                        if isinstance(data, dict):
                            data = [data]
                        for each_data in data:
                            # Extract the primary data further only if variable1_jmes_path is defined. Else use the data as is
                            if each_exclusion_item.get('variable1_jmes_path') == "":
                                primary_data = each_data
                            else:
                                primary_data = jmespath.search(each_exclusion_item.get('variable1_jmes_path'), each_data)
                            # Extract the secondary data further only if variable2_jmes_path is defined. Else use the data as is
                            if each_exclusion_item.get('variable2_jmes_path') == "":
                                secondary_data = each_data
                            else:
                                secondary_data = jmespath.search(each_exclusion_item.get('variable2_jmes_path'), each_data)
                            # Check if the primary and secondary data are not None
                            if primary_data is not None and secondary_data is not None:
                                # Loop through the primary and secondary variable list and check if the variables are defined in primary and secondary data
                                for each_pri_var in each_exclusion_item.get('variable1', []):
                                    for each_sec_var in each_exclusion_item.get('variable2', []):
                                        if each_pri_var in primary_data and each_sec_var in secondary_data:
                                            results.append('Mutually exclusive variables defined at ' + each_exclusion_item.get('object_jmes_path', "*") + ' .Only one is allowed. ' + str(each_pri_var) + ":" +  str(primary_data[each_pri_var]) + ' or ' +  str(each_sec_var) + ":" + str(secondary_data[each_sec_var])) 
            except KeyError:
                pass
        return results
