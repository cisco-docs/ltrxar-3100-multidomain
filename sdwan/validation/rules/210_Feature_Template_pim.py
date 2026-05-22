import jmespath
class Rule:
    id = "210"
    description = "Feature Template PIM Validation"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        interface_validation_ref_path = [
            'rp_candidates[].interface_name',
            'bsr_candidate_interface',
            'rp_discovery_interface',
        ]
        additional_validation_for_list = [
            {
                'field': 'interfaces',
                'only_variable_if_optional': ['interface_name'],
                'unique_fields': ['interface_name', 'interface_name_variable']
            },
            {
                'field': 'rp_addresses',
                'only_variable_if_optional': ['access_list', 'ip_address'],
                'unique_fields': ['access_list', 'access_list_variable']
            },
            {
                'field': 'rp_candidates',
                'only_variable_if_optional': ['interface_name'],
                'unique_fields': ['interface_name', 'interface_name_variable']
            },
            {
                'field': 'rp_announces',
                'only_variable_if_optional': ['interface_name'],
                'unique_fields': ['interface_name', 'interface_name_variable']
            }
        ]
        
        for pim_template in inventory.get("sdwan", {}).get("edge_feature_templates", {}).get("pim_templates", []):
            interfaces = [i.get("interface_name") for i in pim_template.get("interfaces", [])]
            # Auto RP validation.
            auto_rp = pim_template.get("auto_rp", False)
            if auto_rp:
                # BSR candidate should not be defined when auto_rp is enabled.
                bsr_fields = ['bsr_candidate_interface', 'bsr_candidate_hash_mask_length', 'bsr_candidate_priority', 'bsr_candidate_rp_access_list']
                for field in bsr_fields:
                    if field in pim_template:
                        results.append(f"The PIM template '{pim_template.get('name')}' should not have BSR candidates fields ({', '.join(bsr_fields)}) when auto_rp is enabled.")
                    break
            else:
                # RP announces and RP discovery should not be defined when auto_rp is disabled.
                rp_fields = ['rp_discovery_interface', 'rp_discovery_scope', 'rp_announces']
                for field in rp_fields:
                    if field in pim_template:
                        results.append(f"The PIM template '{pim_template.get('name')}' should not have RP announces and RP discovery fields ({', '.join(rp_fields)}) when auto_rp is disabled.")
                        break
            # The interface_name in rp_candidates, bsr_candidate_interface and rp_discovery must match one of the defined interfaces in the same PIM template.
            for path in interface_validation_ref_path:
                data = jmespath.search(path, pim_template)
                if data:
                    if type(data) is not list:
                        data = [data]
                    for each_data_val in data:
                        if len(interfaces) == 0:
                            results.append(f"The PIM template {pim_template.get('name')} must have at least one interface defined if {path} is defined.")
                        elif each_data_val not in interfaces:
                            results.append(f"The PIM template '{pim_template.get('name')}' has an {path} '{each_data_val}' that does not match any of the defined interfaces in same PIM template.")
            # Additional list validation.
            for field_item in additional_validation_for_list:
                if field_item['field'] in pim_template:
                    find_optional = []
                    for item in pim_template.get(field_item['field'], []):
                        # Uniqueness check - fields that must be unique across all entries in the list.
                        for key in item.keys():
                            if key in field_item['unique_fields']:
                                if len([filtered.get(key) for filtered in pim_template.get(field_item['field'], []) if filtered.get(key) == item[key]]) > 1:
                                    results.append(f"The PIM template '{pim_template.get('name')}' contains duplicate entries in the '{field_item['field']}' for the field '{key}'. Each entry must be unique.")
                        # Optional key check - fields that must be variable if the entry is optional.
                        if item.get("optional", False):
                            for var_field in field_item.get('only_variable_if_optional', []):
                                if (var_field in item and not item.get(f"{var_field}_variable", False)) or (var_field in item and item.get(f"{var_field}_variable", False)):
                                    results.append(f"The PIM template '{pim_template.get('name')}' contains an optional entry in the '{field_item['field']}' where the field '{var_field}' must be defined only as a variable.")
                            find_optional.append(item)
                    # Optional key check - only one optional entry is allowed per list.
                    if len(find_optional) > 1:
                        results.append(f"The PIM template '{pim_template.get('name')}' contains multiple optional entries in the '{field_item['field']}'. Only one optional entry is allowed per list.")

        # The device template referencing PIM templates must not reference PIM templates with mixed auto_rp settings.
        for device_template in inventory.get("sdwan", {}).get("edge_device_templates", []):
            pim_templates = [vpn_service.get("pim_template") for vpn_service in device_template.get("vpn_service_templates", []) if vpn_service.get("pim_template")]
            auto_rp_enabled_per_device = []
            for pim_template in inventory.get("sdwan", {}).get("edge_feature_templates", {}).get("pim_templates", []):
                if pim_template.get("name") in pim_templates:
                    auto_rp_enabled_per_device.append(pim_template.get("auto_rp", False))
            all_auto_rp_same = all(x == auto_rp_enabled_per_device[0] for x in auto_rp_enabled_per_device)
            if not all_auto_rp_same:
                results.append(f"The device template '{device_template.get('name')}' references PIM templates with mixed auto_rp settings. All referenced PIM templates must have the same auto_rp configuration.")
        return results
