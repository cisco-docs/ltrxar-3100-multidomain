class Rule:
    id = "209"
    description = "Feature Template Security Internet Gateway Validation"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        
        '''
        The below task does Advanced Validation for SIG feature template with Generic/Other SIG provider \
        This ensures that the SIG Template with Generic/Other SIG Provider must have either tunnel_destination or tunnel_destination_variable defined in each interface.
        '''
        for sig_template in inventory.get("sdwan", {}).get("edge_feature_templates", {}).get("secure_internet_gateway_templates", []):
                for interface in sig_template.get("interfaces",{}):
                    if sig_template.get("sig_provider", "").lower() == "umbrella" or sig_template.get("sig_provider", "").lower() == "zscaler":
                        if "tunnel_dc_preference" in interface.keys():
                            pass
                        else:
                            results.append(
                                {
                                    "item": f"sdwan.edge_feature_templates.secure_internet_gateway_templates.{sig_template.get('name')}.interfaces",
                                    "message": f"SIG Template {sig_template.get('name')} with Umbrella/Zscaler Provider must have tunnel_dc_preference defined in each interface.",
                                }
                            )                         
                    elif sig_template.get("sig_provider", "").lower() == "other":
                        if "tunnel_destination" in interface.keys() or "tunnel_destination_variable" in interface.keys():
                            pass
                        else:
                            results.append(
                                {
                                    "item": f"sdwan.edge_feature_templates.secure_internet_gateway_templates.{sig_template.get('name')}.interfaces",
                                    "message": f"SIG Template {sig_template.get('name')} with Generic/Other SIG Provider must have either tunnel_destination or tunnel_destination_variable defined in each interface.",
                                }
                            )


        '''
        Future Secure Internet Gateway Feature template rules can be appended here
        '''

        return results