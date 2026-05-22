class Rule:
    id = "308"
    description = "Security Policy objects Advance Validation"
    severity = "HIGH"

    @classmethod
    def validate_ports(cls, ports):
        # The advanced regex validation logic
        for port in ports:
            port_str = str(port)
            if "-" in port_str:
                start, end = port_str.split("-")
                if not (start.isdigit() and end.isdigit() and 0 <= int(start) < int(end) <= 65535):
                    return False
            else:
                if not (port_str.isdigit() and 0 <= int(port_str) <= 65535):
                    return False
        return True

    @classmethod
    def match(cls, inventory):
        results = []
        
        '''
        The below task does Advanced Regex Validation for Port Lists to contain number \
        between range 0 to 65535 or it can also be in a range format X-Y where X < Y \
        '''
        for port_list in inventory.get("sdwan", {}).get("policy_objects", {}).get("port_lists", []):
            if not cls.validate_ports(port_list["ports"]):
                results.append({"port_list": port_list["name"], "error": "Invalid port list format. Expecting values in range 0-65535"})

        '''
        Security Policy object rules in future can be appended here
        '''

        return results