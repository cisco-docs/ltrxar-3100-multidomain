class Rule:
    id = "205"
    description = "Verify Localized Policy Definition references"
    severity = "HIGH"

    paths = []
    # Verify Policy Definition Names referenced in the Localized Policies
    localized_policy_definition_types = ['ipv4_access_control_lists', 'ipv4_device_access_policies', 'ipv6_access_control_lists', 'ipv6_device_access_policies', 'rewrite_rules', 'route_policies', 'qos_maps']
    for type in localized_policy_definition_types:
        paths.append({
            "key": str("sdwan.localized_policies.definitions." + type + ".name"),
            "references": [
                str("policy_templates.policy_definitions." + type)
            ]
        })
    # Create mapping of definition matching fields to the object names
    field_to_object_type = {
        'prefix_list': 'ipv4_prefix_lists',
        'standard_community_lists': 'standard_community_lists',
        'expanded_community_list': 'expanded_community_lists',
        'extended_community_list': 'extended_community_lists',
        'as_path_list': 'as_path_lists',
        }
    
    data_prefix_fields = ['destination_data_prefix_list', 'source_data_prefix_list']

    @classmethod
    def build_policy_object_name_dict(cls, inventory):
        # Build a dictionary of all available policy object names by type
        obj_dict = {}
        policy_objects = inventory.get('sdwan', {}).get('policy_objects', {})
        for obj_type, obj_list in policy_objects.items():
            obj_dict[obj_type] = set()
            if obj_list:
                for obj in obj_list:
                    if isinstance(obj, dict) and 'name' in obj:
                        obj_dict[obj_type].add(obj['name'])
        return obj_dict
    
    @classmethod
    def get_data_prefix_obj_type(cls, def_type):
        if def_type in ['ipv4_access_control_lists', 'ipv4_device_access_policies']:
            return 'ipv4_data_prefix_lists'
        elif def_type in ['ipv6_access_control_lists', 'ipv6_device_access_policies']:
            return 'ipv6_data_prefix_lists'
        return None
        
    @classmethod
    def build_policy_feature_dict(cls, inventory):
        # Build the dictionary of per-type policy definitions in the localized policies
        policy_template_dict = {
            "policy_templates": []
        }
        for policy_template in inventory.get('sdwan', {}).get('localized_policies', {}).get('feature_policies', {}):
            policy_template_definitions = {}
            if "definitions" in policy_template:
                for policy_definition_type, policy_definition_names in policy_template['definitions'].items():
                    if not policy_definition_type in policy_template_definitions:
                        policy_template_definitions[policy_definition_type] = []
                    for policy_definition_name in policy_definition_names:
                        policy_template_definitions[policy_definition_type].append(policy_definition_name)
            policy_template_dict['policy_templates'].append({
                "name": policy_template['name'],
                "policy_definitions": policy_template_definitions
                })
        return policy_template_dict

    @classmethod
    def match_path(cls, inventory, full_path, search_path, targets):
        results = []
        path_elements = search_path.split(".")
        inv_element = inventory
        for idx, path_element in enumerate(path_elements):
            if isinstance(inv_element, dict):
                inv_element = inv_element.get(path_element)
            elif isinstance(inv_element, list):
                for i in inv_element:
                    r = cls.match_path(
                        i, full_path, ".".join(path_elements[idx:]), targets
                    )
                    results.extend(r)
                return results
            if inv_element is None:
                return results
        if isinstance(inv_element, list):
            for e in inv_element:
                if str(e) not in targets:
                    results.append(full_path + " - " + str(e))
        elif str(inv_element) not in targets:
            results.append(full_path + " - " + str(inv_element))
        return results

    @classmethod
    def match(cls, inventory):
        policy_template_dict = cls.build_policy_feature_dict(inventory)
        results = []
        for path in cls.paths:
            key_elements = path["key"].split(".")
            try:
                element = inventory
                for k in key_elements[:-1]:
                    element = element[k]
                keys = [str(obj.get(key_elements[-1])) for obj in element]
            except KeyError:
                continue
            for ref in path["references"]:
                r = cls.match_path(policy_template_dict, ref, ref, keys)
                results.extend(r)
        # --- Policy object reference in definition check ---
        obj_dict = cls.build_policy_object_name_dict(inventory)
        definitions = inventory.get('sdwan', {}).get('localized_policies', {}).get('definitions', {})
        for def_type, def_list in definitions.items():
            for definition in def_list:
                def_name = definition.get('name', f"<unnamed {def_type}>")
                # Sequences for ACLs, device access policies, route policies
                for seq in definition.get('sequences', []):
                    match = seq.get('match_criterias', {})
                    # Data prefix lists (IPv4/IPv6)
                    for field in cls.data_prefix_fields:
                        if field in match:
                            obj_type = cls.get_data_prefix_obj_type(def_type)
                            if obj_type:
                                values = match[field] if isinstance(match[field], list) else [match[field]]
                                defined_names = obj_dict.get(obj_type, set())
                                for v in values:
                                    if v not in defined_names:
                                        results.append(f"policy_objects.{obj_type} missing referenced object: '{v}' in definition '{def_name}'")
                    # Other reference fields
                    for field, obj_type in cls.field_to_object_type.items():
                        if field in match:
                            values = match[field] if isinstance(match[field], list) else [match[field]]
                            defined_names = obj_dict.get(obj_type, set())
                            for v in values:
                                if v not in defined_names:
                                    results.append(f"policy_objects.{obj_type} missing referenced object: '{v}' in definition '{def_name}'")
                # QoS maps: check qos_schedulers/class_map
                if def_type == 'qos_maps' and 'qos_schedulers' in definition:
                    for sched in definition['qos_schedulers']:
                        queue = sched.get('queue')
                        if 'class_map' not in sched:
                            if queue != 0:
                                results.append(f"class_map is required for queue {queue} in qos_maps definition '{def_name}' (only queue 0 may omit class_map in data model)")
                        else:
                            # Validate reference if class_map is present
                            v = sched['class_map']
                            defined_names = obj_dict.get('class_maps', set())
                            if v not in defined_names:
                                results.append(f"policy_objects.class_maps missing referenced object: '{v}' in definition '{def_name}'")
        return results