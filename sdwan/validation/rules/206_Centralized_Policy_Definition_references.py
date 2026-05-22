class Rule:
    id = "206"
    description = "Verify Centralized Policy Definition references"
    severity = "HIGH"
    
    # # Verify Policy Definition Names referenced in the Centralized Policies


    policy_definition_type = [
        'control_policy', 'data_policy'
    ]
    policy_definition_sub_type = [
        'hub_and_spoke_topology', 'mesh_topology', 'vpn_membership', 'custom_control_topology', 'traffic_data', 'cflowd', 'application_aware_routing'
    ] 

    # Extract the Policy Name and Definition Names referenced in the Centralized Policies at ['sdwan']['centralized_policies']['feature_policies']
    @classmethod
    def feature_policies(cls, inventory):
        results = {}
        for fpds in inventory.get('sdwan', {}).get('centralized_policies', {}).get('feature_policies', {}):
            fpdsname = fpds['name']
            fpdsdict = {}
            for x in cls.policy_definition_sub_type:
                try:
                    if x in fpds:
                        fp_definitions = []
                        for pd in fpds[x]:
                            fp_definitions.append(pd['policy_definition'])
                        fpdsdict[x] = fp_definitions
                except KeyError:
                    continue
            results[fpdsname] = fpdsdict
        return results  

    # Extract the Policy Definition Names defined in the Centralized Policies at ['sdwan']['centralized_policies']['definitions'][.][.]
    @classmethod
    def definitions(cls, inventory):
        results = {}
        for w in cls.policy_definition_type:
            for x in cls.policy_definition_sub_type:
                try:
                    definitions = []
                    for ds in inventory['sdwan']['centralized_policies']['definitions'][w][x]:
                        definitions.append(ds['name'])
                        results[x] = definitions
                except KeyError:
                    continue
        return results

    @classmethod
    def _merge_intervals(cls, intervals):
        """Merge overlapping or adjacent (start, end) inclusive intervals."""
        if not intervals:
            return []
        sorted_intervals = sorted(intervals)
        merged = [list(sorted_intervals[0])]
        for start, end in sorted_intervals[1:]:
            if start <= merged[-1][1] + 1:
                merged[-1][1] = max(merged[-1][1], end)
            else:
                merged.append([start, end])
        return [tuple(iv) for iv in merged]

    @classmethod
    def _intervals_subtract(cls, intervals_a, intervals_b):
        """Return intervals in A not covered by B. Both must be merged."""
        if not intervals_a:
            return []
        if not intervals_b:
            return list(intervals_a)
        result = []
        b_idx = 0
        for a_start, a_end in intervals_a:
            current = a_start
            bi = b_idx
            while bi < len(intervals_b) and intervals_b[bi][1] < current:
                bi += 1
            while bi < len(intervals_b) and intervals_b[bi][0] <= a_end:
                b_start, b_end = intervals_b[bi]
                if current < b_start:
                    result.append((current, min(b_start - 1, a_end)))
                current = max(current, b_end + 1)
                bi += 1
            if current <= a_end:
                result.append((current, a_end))
        return result

    @classmethod
    def format_intervals_as_ranges(cls, intervals):
        """Convert merged intervals to readable format like '200-205, 210, 300-305'."""
        if not intervals:
            return ""
        ranges = []
        for start, end in intervals:
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")
        return ", ".join(ranges)

    @classmethod
    def get_sites_as_intervals(cls, inventory, site_lists):
        """Extract all site IDs from given site lists as merged intervals (no expansion)."""
        if not site_lists:
            return []
        site_lists_set = set(site_lists)
        intervals = []
        site_list_objects = inventory.get('sdwan', {}).get('policy_objects', {}).get('site_lists', [])
        for site_list_obj in site_list_objects:
            if site_list_obj.get('name') in site_lists_set:
                for site_id in site_list_obj.get('site_ids', []):
                    intervals.append((site_id, site_id))
                for site_range in site_list_obj.get('site_id_ranges', []):
                    intervals.append((site_range['from'], site_range['to']))
        return cls._merge_intervals(intervals)

    @classmethod
    def verify_cflowd_references(cls, inventory):
        """Verify that sites with cflowd action also have cflowd policy applied."""
        dp_with_cflowd_action = {}  # Map: policy_name -> site_lists where it's applied
        cflowd_pushed_site_lists = []
        
        try:
            # Find traffic data policies with cflowd action
            traffic_data_policies = inventory.get('sdwan', {}).get('centralized_policies', {}).get('definitions', {}).get('data_policy', {}).get('traffic_data', [])
            policies_with_cflowd = set()
            for traffic_dp_def in traffic_data_policies:
                for sequence in traffic_dp_def.get('sequences', []):
                    if sequence.get('actions', {}).get('cflowd'):
                        policies_with_cflowd.add(traffic_dp_def.get('name'))
                        break
            
            # Early return if no cflowd actions defined
            if not policies_with_cflowd:
                return None
            
            centralized_policy = inventory.get('sdwan', {}).get('centralized_policies', {})
            activated_policy = centralized_policy.get('activated_policy')
            
            # Only check the activated policy
            if not activated_policy:
                return None
            
            for feature_policy in centralized_policy.get('feature_policies', []):
                if feature_policy.get('name') == activated_policy:
                    # Sites where traffic data policy with cflowd action is applied
                    for feature_traffic_dp in feature_policy.get('traffic_data', []):
                        policy_def = feature_traffic_dp.get('policy_definition')
                        if policy_def in policies_with_cflowd:
                            site_lists = []
                            for site_region in feature_traffic_dp.get('site_region_vpn', []):
                                site_lists.extend(site_region.get('site_lists', []))
                            dp_with_cflowd_action[policy_def] = site_lists
                    
                    # Sites where cflowd policy is explicitly pushed
                    for feature_traffic_cflowd in feature_policy.get('cflowd', []):
                        cflowd_pushed_site_lists.extend(feature_traffic_cflowd.get('site_lists', []))
                    break  # Found activated policy
            
            # Convert cflowd pushed site lists to intervals
            cflowd_intervals = cls.get_sites_as_intervals(inventory, cflowd_pushed_site_lists)
            
            # Check each data policy with cflowd action
            problematic_policies = {}
            for policy_name, site_lists in dp_with_cflowd_action.items():
                policy_intervals = cls.get_sites_as_intervals(inventory, site_lists)
                
                # Check if this policy has sites missing cflowd policy
                missing_intervals = cls._intervals_subtract(policy_intervals, cflowd_intervals)
                if policy_intervals and missing_intervals:
                    problematic_policies[policy_name] = missing_intervals
            
            # Generate error messages for problematic policies
            if problematic_policies:
                all_missing = []
                for missing in problematic_policies.values():
                    all_missing.extend(missing)
                all_missing = cls._merge_intervals(all_missing)
                
                formatted_sites = cls.format_intervals_as_ranges(all_missing)
                policies_list = ", ".join(f"'{p}'" for p in problematic_policies)
                return [f"Missing cflowd reference: site_ids {formatted_sites} are referenced under traffic data policies {policies_list} with cflowd action but do not have cflowd policy applied under feature policies in the activated policy '{activated_policy}'"]
        
        except KeyError:
            pass
        
        return None

    @classmethod
    def match(cls, inventory):
        # Compare the Policy Definition Names referenced in the Centralized Policies at ['sdwan']['centralized_policies']['feature_policies'] 
        # to the Policy Definition Names defined in the Centralized Policies at ['sdwan']['centralized_policies']['definitions'][.][.]
        # and find the missing definitions
        # Compare the activated policy name at ['sdwan']['centralized_policies']['activated_policy'] 
        # to the Policy Names defined in the Centralized Policies at ['sdwan']['centralized_policies']['feature_policies']
        # and find the missing policy name
        feature_policies = cls.feature_policies(inventory)
        definitions = cls.definitions(inventory)
        missing_definitions = []
        try:
            for z in feature_policies:
                for x in feature_policies[z]:
                    for y in feature_policies[z][x]:
                        if y not in definitions[x]:
                            missing_definitions.append(str("Missing " + x + " definition: '" + y + "' at ['sdwan']['centralized_policies']['definitions'][.]['"+ x + "'] referenced under ['sdwan']['centralized_policies']['feature_policies']['" + z +"']"))
        except KeyError:
            pass
        try:
            if inventory['sdwan']['centralized_policies']['activated_policy']:
                if inventory['sdwan']['centralized_policies']['activated_policy'] not in feature_policies:
                    missing_definitions.append(str("Missing feature policy: '" + inventory['sdwan']['centralized_policies']['activated_policy'] + "' at ['sdwan']['centralized_policies']['feature_policies'] referenced under ['sdwan']['centralized_policies']['activated_policy']" ))
        except KeyError:
            pass

        # Whenever traffic data policy action contains cflowd, verify that the sites where respective traffic data policy is pushed also has cflowd template / data policy applied
        missing_cflowd_ref = cls.verify_cflowd_references(inventory)
        if missing_cflowd_ref:
            missing_definitions.extend(missing_cflowd_ref)

        return missing_definitions
