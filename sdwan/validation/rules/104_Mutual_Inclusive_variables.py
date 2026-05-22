import jmespath
class Rule:
    id = "104"
    description = "Verify if any mutually dependent variables are defined"
    severity = "HIGH"
    
    #########################################################################################################################################
    # List of the mutually dependent variables at different paths of the Data Model
    # This checks if child variables without a parent variable are defined in the provided object path
    # For any additional paths where the validation is required, add the mutually dependent variables to the below list
    # No additional code changes should be required
    # The mutually dependent variables are defined in the list with the following details:
    # 1. object_jmes_path: Path to the Flattened data of the feature in the Data Model, where the mutually dependency on variables could be defined. 
    #       example: "sdwan.edge_feature_templates.ethernet_interface_templates[*].ipv4_vrrp_groups[]" (VRRP configuration block on an interface feature template)
    #       example: "sdwan.edge_feature_templates.ethernet_interface_templates[]" (flatten the list interfaces' config)
    #       do not flatten with trailing [] if the object is not a list
    # 2. parent_jmes_path: The name of the parent variable which should be enabled before declaring the child variables.
    #       example: ['tloc_preference_change']
    # 3. parent_variable_requirement: A list of possible values required on the parent variable so that child variables can be declared, multiple values are expected if the default value is same as the required value.
    #       example: [False, None]
    # 4. variable_jmes_path: List containing the path to the child variables in the Data Model which is dependent on the Parent variable. As many child variables as required can be added on the list.
    #       example: ['tloc_preference_change_value_variable', 'tloc_preference_change_value']
    #
    ## Sample List
    # Outcome: The below list will check if the parent variable 'tloc_preference_change' is defined in the 'sdwan.edge_feature_templates.ethernet_interface_templates[*].ipv4_vrrp_groups[]' object. If 'parent_variable_requirement' condition is met: it will allow 
    # 'variable1_jmes_path' or 'variable2_jmes_path' in the data model. If no, it will throw an error.
    # mutually_inclusive_variables_list = [
    #   {
    #        'object_jmes_path': 'sdwan.edge_feature_templates.ethernet_interface_templates[*].ipv4_vrrp_groups[]',
    #        'parent_jmes_path' : 'track_omp', 
    #        'parent_variable_requirement' : [False, None],
    #        'variables_jmes_path' : ['track_prefix_list'],
    #    },
    # ]
    #########################################################################################################################################
    

    mutually_inclusive_variables_list = [
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.ethernet_interface_templates[*].ipv4_vrrp_groups[]',
            'parent_jmes_path' : 'tloc_preference_change', 
            'parent_variable_requirement' : [True],
            'variables_jmes_path' : ['tloc_preference_change_value_variable', 'tloc_preference_change_value'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.ethernet_interface_templates[*].ipv4_vrrp_groups[]',
            'parent_jmes_path' : 'track_omp', 
            'parent_variable_requirement' : [False, None],
            'variables_jmes_path' : ['track_prefix_list'],
        },
        {
            'object_jmes_path': 'sdwan.edge_feature_templates.ethernet_interface_templates[]',
            'parent_jmes_path' : 'ipv4_nat', 
            'parent_variable_requirement' : [True],
            'variables_jmes_path' : ['ipv4_nat_type'],
        },
        {
            'object_jmes_path': 'sdwan.localized_policies.definitions.route_policies[].sequences[]',
            'parent_jmes_path' : 'match_criterias.standard_community_lists_criteria', 
            'parent_variable_requirement' : ['or', 'and', 'exact'],
            'variables_jmes_path' : ['match_criterias.standard_community_lists'],
        },
    ]

    # Loop through the mutually_inclusive_variables_list and check if the mutually inclusive variables are defined
    @classmethod
    def match(cls, inventory):
        results = []
        # Loop through the mutually_inclusive_variables_list
        for each_inclusion_item in cls.mutually_inclusive_variables_list:
            data_model_path = each_inclusion_item.get('object_jmes_path')
            try:
                # Extract the data from the Data Model using the object_jmes_path
                data = jmespath.search(each_inclusion_item.get('object_jmes_path'), inventory)
                if data is not None:
                    # Loop through the data
                    if isinstance(data, dict):
                        data = [data]
                    for each_data in data:
                        # Extract the Parent data further only if parent_jmes_path is defined. Else use the data as is
                        if each_inclusion_item.get('parent_jmes_path') == "":
                            parent_data = each_data
                            parent_data_variable = each_inclusion_item.get('parent_jmes_path')
                        else:
                            parent_data = jmespath.search(each_inclusion_item.get('parent_jmes_path'), each_data)
                            parent_data_variable = each_inclusion_item.get('parent_jmes_path')
                        # Extract the child data for the variableX_jmes_path defined. Else use the data as is
                        for varName in each_inclusion_item.get('variables_jmes_path'):
                            # Extract the Parent data further only if parent_jmes_path is defined. Else use the data as is
                            if varName == "":
                                child_data = each_data
                                child_data_variable = varName
                            else:
                                child_data = jmespath.search(varName, each_data)
                                child_data_variable = varName
                            parent_variable = each_inclusion_item.get('parent_variable_requirement')
                            # Check if the Parent is not a valid value and child data is declared
                            if parent_data not in parent_variable and child_data is not None:
                                if parent_data is None:
                                    results.append('On Data model path ' + data_model_path + ', the parent variable ' + parent_data_variable + ' is not set, but value ' + str(child_data_variable) + ' is declared.')
                                else:
                                    results.append('On Data model path ' + data_model_path + ', the parent variable ' + parent_data_variable + ' is set to: \"' + str(parent_data) + '", and value ' + str(child_data_variable) + ' is declared.')
            except KeyError:
                pass
        return results