class Rule:
    id = "203"
    description = "Validate aaa feature templates"
    severity = "HIGH"

    # Verify AAA server groups referenced in the server-auth-order field
    @classmethod
    def verify_aaa_groups(cls, inventory):
        configured_server_groups = ['local']
        results = []
        if "aaa_templates" in inventory.get('sdwan', {}).get('edge_feature_templates', {}):
            for template in inventory['sdwan']['edge_feature_templates']['aaa_templates']:
                if "radius_server_groups" in template:
                    for group in template['radius_server_groups']:
                        configured_server_groups.append(group['name'])
                if "tacacs_server_groups" in template:
                    for group in template['tacacs_server_groups']:
                        configured_server_groups.append(group['name'])
                server_auth_group_list = template['authentication_and_authorization_order']
                for group in server_auth_group_list:
                    if group not in configured_server_groups:
                        results.append("sdwan.edge_feature_templates.aaa_templates." + template['name'] + " - Missing the server auth_group: " + str(group))
        return results
    
    @classmethod
    def match(cls, inventory):
        results = []
        results = cls.verify_aaa_groups(inventory)
        return results
