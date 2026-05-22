import jmespath

class Rule:
    id = "309"
    description = "Security Policy Advance Validations"
    severity = "HIGH"

    @classmethod
    def ip_type_validation(cls,inventory):
        # This function validated ip_type field cannot be ipv6 when mode is security for a Zone Based Firewall Policy
        result = []
        for zbfw_p in inventory.get('sdwan',{}).get('security_policies',{}).get('definitions',{}).get('zone_based_firewall',[]):
            if zbfw_p.get('mode',"security") == "security":
                for rule in zbfw_p.get('rules',[]):
                    if rule.get('ip_type', None) == "ipv6":
                        result.append(f"The Zone Based Firewall Policy {zbfw_p.get('name')} with mode {zbfw_p.get('mode','security')} has an invalid ip_type: {rule.get('ip_type')} under Rule {rule.get('id')} : {rule.get('name')}")
        return result

    @classmethod
    def port_protocol_validation(cls, inventory):
        # This function checks if source/destination ports are specified only when the protocol is TCP (6) or UDP (17).
        result = []
        path = "sdwan.security_policies.definitions.zone_based_firewall[].rules[].match_criterias[]"
        match_criteria = jmespath.search(path, inventory)
        if match_criteria is None:
            match_criteria = []
        for idx, criteria in enumerate(match_criteria):
            protocols = criteria.get("protocols")
            source_port_ranges = criteria.get("source_port_ranges")
            destination_port_ranges = criteria.get("destination_port_ranges")
            source_ports = criteria.get("source_ports")
            destination_ports = criteria.get("destination_ports")
            source_port_lists = criteria.get("source_port_lists")
            destination_port_lists = criteria.get("destination_port_lists")
            #if (source_ports or destination_ports or source_port_ranges or destination_port_ranges) and protocols: # Previous checks without Port Lists
            if (source_ports or destination_ports or source_port_ranges or destination_port_ranges or source_port_lists or destination_port_lists) and protocols:
              if not any(protocol == 6 or protocol == 17 for protocol in protocols):  # 6 for TCP, 17 for UDP
                result.append(f"ERROR in {path}[{idx}] , invalid value of {protocols} . REASON: Source/Destination ports can only be specified when protocol has atleast one of TCP (6) or UDP (17)")
        return result

    @classmethod
    def validate_element_not_present(cls, inventory, should_not_be_present):
        # This function checks if certain elements are not present in the inventory based on the provided paths.
        result = []
        for mode, validations in should_not_be_present.items():
            for validation in validations:
                path = validation["path"]
                element = validation["element"]
                found_elements = jmespath.search(f"{path}.{element}", inventory)
                if found_elements:
                    path_results = jmespath.search(path, inventory)
                    if path_results is None:
                        path_results = []
                    for idx, rule in enumerate(path_results):
                        if element in rule and rule[element] is not None:
                            result.append(f"ERROR in {path}[{idx}].{element} , invalid value of {element} : {rule[element]} . Element '{element}' should not be present in mode '{mode}'")
        return result

    @classmethod
    def match(cls, inventory):
        results = []

        '''
        The below task does Advanced Regex Validation for Security Policy which validates if a field which should not present \
        in the respective mode (security, unified) is present in the datamodel \
        '''
        should_not_be_present =  {
            "security": [
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall.high_speed_logging",
                    "element": "source_interface"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "max_incomplete_icmp_limit"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "max_incomplete_tcp_limit"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "max_incomplete_udp_limit"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "unified_logging"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "session_reclassify_allow"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')].additional_settings.firewall",
                    "element": "icmp_unreachable_allow"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode!='unified')]",
                    "element": "unified_firewall_policies"
                },
            ],
            "unified":[
                {
                    "path": "sdwan.security_policies.definitions.zone_based_firewall[?(@.mode=='unified')]",
                    "element": "zone_pairs"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode=='unified')].additional_settings.firewall",
                    "element": "direct_internet_applications"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode=='unified')].additional_settings.firewall",
                    "element": "match_stats_per_filter"
                },
                {
                    "path": "sdwan.security_policies.feature_policies[?(@.mode=='unified')]",
                    "element": "firewall_policies"
                }
            ]
        }

        results = cls.validate_element_not_present(inventory, should_not_be_present)

        '''
        Below code block is an advance validation to verify both port related parameters (source, destination port related fields) and protocol can co-exist only if protocol is 'tcp' or 'udp' i.e. 6 or 17
        '''
        results = results + cls.port_protocol_validation(inventory)

        '''
        Below code block is an advance validation to verify if ip_type field under every rule is ipv4 or not specified for a security policy with mode security.
        This is because, ip_type cannot be ipv6 for Security Policy with mode security
        '''
        results = results + cls.ip_type_validation(inventory)

        '''
        Future Security Policy rules can be appended here
        '''

        return results
