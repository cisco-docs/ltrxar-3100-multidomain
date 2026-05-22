class Rule:
    id = "102"
    description = "Verify global unique keys"
    severity = "HIGH"

    # Verify unique keys in the following fields:
    # - Router Hostnames
    # - Router Chassis_id
    # - Router System IPs
    paths = [
        "sdwan.sites.routers.chassis_id",
        "sdwan.sites.routers.device_variables.system_hostname",
        "sdwan.sites.routers.device_variables.system_ip",
    ]

    @classmethod
    def match_path(cls, inventory, full_path, search_path):
        values = []
        results = []
        path_elements = search_path.split(".")
        inv_element = inventory
        for idx, path_element in enumerate(path_elements[:-1]):
            if isinstance(inv_element, dict):
                inv_element = inv_element.get(path_element)
            elif isinstance(inv_element, list):
                for i in inv_element:
                    v,r = cls.match_path(i, full_path, ".".join(path_elements[idx:]))
                    values.extend(v)
                    results.extend(r)
                for i in range(0, len(values)):    
                    for j in range(i+1, len(values)):    
                        if(values[i] == values[j]): 
                            results.append(full_path + " - " + str(values[j]))
                return values, results
            if inv_element is None:
                return values, results
        if isinstance(inv_element, list):
            for i in inv_element:
                if not isinstance(i, dict):
                    continue
                value = i.get(path_elements[-1])
                if isinstance(value, list):
                    values = []
                    for v in value:
                        if v not in values:
                            values.append(v)
                        else:
                            results.append(full_path + " - " + str(v))
                elif value:
                    if value not in values:
                        values.append(value)
                    else:
                        results.append(full_path + " - " + str(value))
        elif isinstance(inv_element, dict):
            list_element = inv_element.get(path_elements[-1])
            if isinstance(list_element, list):
                for value in list_element:
                    if value:
                        if value not in values:
                            values.append(value)
                        else:
                            results.append(full_path + " - " + str(value))
            elif isinstance(list_element, str):
                values.append(list_element)
            elif isinstance(list_element, int):
                values.append(list_element)
            elif isinstance(list_element, bool):
                values.append(list_element)
        return values, results
    
    @classmethod
    def match(cls, inventory):
        results = []
        for path in cls.paths:
            v,r = cls.match_path(inventory, path, path)
            results.extend(r)
        return results
