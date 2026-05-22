class Rule:
    id = "307"
    description = "Verify Security Policy object references"
    severity = "HIGH"
    
    # # Verify Policy Definition have the referenced policy objects available
    policy_definition_type = [
        'zone_based_firewall', 
    ]

    policy_definition_sub_branches = [
        'match_criterias', 'actions'
    ]

    """
    For Any future lists which are referenced in policy_definition_type (Example: Zone Based Firewall) \
        under every sequence of the policy definition sub branches i.e. 'match_criterias', 'actions' \
        Add the new list name used in Security Policy and its corresponding policy object type in the policy_object_reference dictionary below. \

    The policy_object_reference dictionary below maps the list names to their corresponding policy object types.
    Example:
    policy_object_reference = \
        {
        'The key field in the Security Policy :
        'The key field in policy object (sdwan.policy_objects.definitions)'
        }
    where 'The key field in the Security Policy' corresponds to keys below \
        (sdwan.security_policies.definitions.zone_based_firewall[*].rules[*].match_criterias[.] or sdwan.security_policies.definitions.zone_based_firewall[*].rules[*].actions[.])'
        and
        'The key field in policy object' corresponds to keys below \
        (sdwan.policy_objects.)
    """

    policy_object_reference = {
        'source_data_prefix_lists': 'ipv4_data_prefix_lists',
        'destination_data_prefix_lists': 'ipv4_data_prefix_lists',
        'source_fqdn_lists': 'fqdn_lists',
        'destination_fqdn_lists': 'fqdn_lists',
        'local_application_list': 'local_application_lists',
        'source_zone': 'zones',
        'destination_zone': 'zones',
        'source_port_lists': 'port_lists',
        'destination_port_lists': 'port_lists'
    }

    # Extract the Policy Object Names defined in the Policy Objects at ['sdwan']['policy_objects'][.]
    @classmethod
    def policy_objects(cls, inventory):
        results = {}
        for pot in cls.policy_object_reference:
            results[pot] = []
            try:
                for pobjs in inventory.get('sdwan', {}).get('policy_objects', {}).get(cls.policy_object_reference[pot], {}):
                    results[pot].append(pobjs['name'])
            except KeyError:
                continue
        return results

    # Create a standardized dictionary for the results
    @classmethod
    def make_dict(cls, name, rule, objtype, policy_objects_name, pdtype, obj, objname):
        result_dict = {}
        result_dict['name'] = name
        result_dict['rule'] = rule
        result_dict['type'] = objtype
        result_dict['policy_objects_name'] = policy_objects_name
        result_dict['pdtype'] = pdtype
        # result_dict['pdsubtype'] = pdsubtype
        result_dict[str(obj)] = objname
        return result_dict

    # Extract the Policy Definition Names defined in the Security Policies at the following paths
    # ['sdwan']['centralized_policies']['definitions'][.]
    @classmethod
    def definitions(cls, inventory):
        results = []
        # Loop through each of the Policy objects relevant for Security Policies
        for pot in cls.policy_object_reference:
            # Loop through each of the Policy Definition types
            for w in cls.policy_definition_type:
                # Policy objects in policy definition
                try:
                    for ds in inventory.get('sdwan', {}).get('security_policies', {}).get('definitions', {}).get(w ,{}):
                        # Policy objects under paths in policy_definition_sub_branches
                        if "rules" in ds:
                            for seq in ds['rules']:
                                for y in cls.policy_definition_sub_branches:
                                    if y in seq:
                                        if pot in seq[y]:
                                            results.append(cls.make_dict(ds['name'], seq['name'], pot, cls.policy_object_reference[pot], w, pot, seq[y][pot]))
                except KeyError:
                    continue
        return results
    
    @classmethod
    def unified_security_policy_references(cls, inventory):
        results = []
        # This function will validate if respective policy object references and firewall policy references are approriate in unified security policies
        for unified_sec_policy in inventory.get('sdwan', {}).get('security_policies', {}).get('feature_policies', {}):
                if unified_sec_policy.get('mode', 'security') == 'unified':
                    for u_firewall_policy in unified_sec_policy.get('unified_firewall_policies', []):
                        firewall_policy = u_firewall_policy.get('firewall_policy', None)
                        if firewall_policy and firewall_policy not in [ fp.get('name', '') for fp in inventory.get('sdwan', {}).get('security_policies', {}).get('definitions', {}).get('zone_based_firewall', []) if fp.get('mode','security') == 'unified']:
                            results.append(f"Missing or invalid firewall_policy reference '{firewall_policy}' in unified security policy '{unified_sec_policy.get('name', '')}'")
                        for zp in u_firewall_policy.get('zones',[]):
                            source_zone = zp.get('source_zone', None)
                            destination_zone = zp.get('destination_zone', None)
                            if source_zone and source_zone not in [ z.get('name', '') for z in inventory.get('sdwan', {}).get('policy_objects', {}).get('zones', []) ] and source_zone != 'self_zone':
                                results.append(f"Missing or invalid source_zone reference '{source_zone}' in unified security policy '{unified_sec_policy.get('name', '')}' under firewall policy '{u_firewall_policy.get('firewall_policy','')}'")
                            if destination_zone and destination_zone not in [ z.get('name', '') for z in inventory.get('sdwan', {}).get('policy_objects', {}).get('zones', []) ] and destination_zone != 'self_zone':
                                results.append(f"Missing or invalid destination_zone reference '{destination_zone}' in unified security policy '{unified_sec_policy.get('name', '')}' under firewall policy '{u_firewall_policy.get('firewall_policy','')}'")
        return results

    @classmethod
    def match(cls, inventory):

        # Compare the Policy objects referenced in the Security Policies at ['sdwan']['security_policies']['definitions'][.] 
        # to the Policy objects defined in the Policy Objects at ['sdwan']['policy_objects'][.] and find the missing Policy Objects
        results = []
        definitions = cls.definitions(inventory)
        policy_objects = cls.policy_objects(inventory)
        missing_policy_objects = []
        for x in definitions:
            if isinstance(x[str(x['type'])], list): 
                z = x[str(x['type'])]
            else: 
                z = [x[str(x['type'])]]
            for y in z:
                if y not in policy_objects[x['type']]:
                    missing_policy_objects.append(str("Missing Policy object " + str(y) + " of type " + str(cls.policy_object_reference[x['type']]) + " referenced under " + str(x['pdtype']) + " " + str(x['name'])))
        
        results = missing_policy_objects + cls.unified_security_policy_references(inventory)

        return results
