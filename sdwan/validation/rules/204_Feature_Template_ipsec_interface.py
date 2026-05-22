class Rule:
    id = "204"
    description = "Validate ipsec_interface feature templates"
    severity = "HIGH"

    # Verify that either the tunnel-source or the tunnel-source-interface is set
    @classmethod
    def verify_tunnel_source(cls, inventory):
        results = []
        if "ipsec_interface_templates" in inventory.get('sdwan', {}).get('edge_feature_templates', {}):
            for template in inventory['sdwan']['edge_feature_templates']['ipsec_interface_templates']:
                if 'tunnel_source_ip' in template and 'tunnel_source_ip_variable' in template:
                    results.append("sdwan.edge_feature_templates.ipsec_interface_templates." + template['name'] + " - tunnel_source_ip and tunnel_source_ip_variable cannot be configured together")                        
                if 'tunnel_source_interface' in template and 'tunnel_source_interface_variable' in template:
                    results.append("sdwan.edge_feature_templates.ipsec_interface_templates." + template['name'] + " - tunnel_source_interface and tunnel_source_interface_variable cannot be configured together")                        
                if ('tunnel_source_ip' in template and 'tunnel_source_interface' in template) or \
                   ('tunnel_source_ip' in template and 'tunnel_source_interface_variable' in template) or \
                   ('tunnel_source_ip_variable' in template and 'tunnel_source_interface' in template) or \
                   ('tunnel_source_ip_variable' in template and 'tunnel_source_interface_variable' in template):
                    results.append("sdwan.edge_feature_templates.ipsec_interface_templates." + template['name'] + " - duplicate tunnel source parameters")                        
                elif "tunnel_source_ip" in template or "tunnel_source_interface" in template or \
                     "tunnel_source_ip_variable" in template or "tunnel_source_interface_variable" in template:
                    pass
                else:
                    results.append("sdwan.edge_feature_templates.ipsec_interface_templates." + template['name'] + " - missing tunnel source parameter")                        
        return results
    
    @classmethod
    def match(cls, inventory):
        results = []
        results = cls.verify_tunnel_source(inventory)
        return results
