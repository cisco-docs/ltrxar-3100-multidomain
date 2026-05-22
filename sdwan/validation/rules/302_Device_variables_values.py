class Rule:
    id = "302"
    description = "Verify Device Variables Values Against Schema"
    severity = "HIGH"

    # Constants for string manipulation
    VARIABLE_SUFFIX = '_variable'
    VARIABLE_SUFFIX_LEN = 9  # len('_variable')
    PROFILE_SUFFIX = '_profile'
    PROFILE_SUFFIX_LEN = 8  # len('_profile')

    @classmethod
    def find_variable_parameters(cls, obj, variables=None, path=''):
        """
        Recursively find all keys ending with '_variable' and their values (variable names)
        Returns: dict mapping variable_name -> path (str)
        """
        if variables is None:
            variables = {}

        if isinstance(obj, dict):
            for key, value in obj.items():
                # Build the current path
                current_path = f"{path}.{key}" if path else key

                if key.endswith(cls.VARIABLE_SUFFIX) and isinstance(value, str):
                    # Found a variable parameter, extract the original parameter name
                    original_param = key[:-cls.VARIABLE_SUFFIX_LEN]
                    # Build the path to the original parameter (not the _variable one)
                    original_param_path = f"{path}.{original_param}" if path else original_param
                    # Store the path for this variable name
                    variables[value] = original_param_path
                elif isinstance(value, (dict, list)):
                    # Recursively search nested structures
                    cls.find_variable_parameters(value, variables, current_path)
        elif isinstance(obj, list):
            for item in obj:
                if isinstance(item, (dict, list)):
                    # For lists, skip the index in path
                    cls.find_variable_parameters(item, variables, path)

        return variables

    @classmethod
    def navigate_schema(cls, schema, path):
        """Navigate through yamale schema to find validator for a path"""
        parts = path.split('.')
        current_dict = schema.dict
        current_schema = schema

        for part in parts:
            if part in current_dict:
                element = current_dict[part]

                # If it's an Include validator, navigate into it
                if hasattr(element, 'include_name'):
                    include_name = element.include_name
                    if include_name in current_schema.includes:
                        current_schema = current_schema.includes[include_name]
                        current_dict = current_schema.dict
                    else:
                        return None
                # If it's a List validator containing an Include, extract the include
                elif type(element).__name__ == 'List' and hasattr(element, 'validators'):
                    if len(element.validators) > 0:
                        inner = element.validators[0]
                        if hasattr(inner, 'include_name'):
                            include_name = inner.include_name
                            if include_name in current_schema.includes:
                                current_schema = current_schema.includes[include_name]
                                current_dict = current_schema.dict
                            else:
                                return None
                        else:
                            return element
                    else:
                        return element
                else:
                    # This is the final validator
                    return element
            else:
                return None

        return None

    @classmethod
    def build_group_validators(cls, group_dict, profile_validators, filter_func):
        """
        Build validators for a group by collecting from assigned profiles

        Args:
            group_dict: Dictionary containing group configuration
            profile_validators: Dict of {profile_type: {profile_name: {var: validator}}}
            filter_func: Function to determine if a key references a profile

        Returns:
            Dict of {var_name: validator}
        """
        group_validators = {}

        for key, value in group_dict.items():
            if not value or not filter_func(key):
                continue

            # Try to match with profile types by adding _profiles suffix
            profile_type_plural = f"{key}_profiles" if not key.endswith('_profiles') else key

            # For keys ending with _profile, pluralize correctly
            if key.endswith(cls.PROFILE_SUFFIX):
                profile_type = key[:-cls.PROFILE_SUFFIX_LEN]
                profile_type_plural = f"{profile_type}_profiles"

            # Collect validators from this profile if it exists
            if profile_type_plural in profile_validators and value in profile_validators[profile_type_plural]:
                group_validators.update(profile_validators[profile_type_plural][value])

        return group_validators

    @classmethod
    def validate_variables(cls, variables, group_validators):
        """
        Validate a dictionary of variables against group validators

        Returns:
            List of error messages
        """
        invalid_variables = []

        for var_name, var_value in variables.items():
            if var_name not in group_validators:
                continue

            validator = group_validators[var_name]
            if validator is None:
                continue

            # Validate the variable and collect any errors
            errors = cls.validate_variable_value(var_name, var_value, validator)
            invalid_variables.extend(errors)

        return invalid_variables

    @classmethod
    def validate_variable_value(cls, var_name, var_value, validator):
        """
        Validate a single variable value against its validator
        Returns: list of error messages (empty if valid)
        """
        errors = []

        try:
            # Use is_valid() which checks both type and constraints (min/max, etc.)
            is_valid = validator.is_valid(var_value)
            if not is_valid:
                formatted_validator = cls.format_validator(validator)
                errors.append(f"{var_name}: expected {formatted_validator}")
            else:
                # For List validators, also validate each element
                if type(validator).__name__ == 'List' and isinstance(var_value, list):
                    if hasattr(validator, 'validators') and len(validator.validators) > 0:
                        element_validator = validator.validators[0]
                        for element in var_value:
                            if not element_validator.is_valid(element):
                                formatted_validator = cls.format_validator(validator)
                                errors.append(f"{var_name}: expected {formatted_validator}")
                                break  # Only report first invalid element
        except Exception as e:
            errors.append(f"{var_name}: validation error ({e})")

        return errors

    @classmethod
    def format_validator(cls, validator):
        """Format a yamale validator into a human-readable string"""
        if validator is None:
            return "unknown type"

        validator_type = type(validator).__name__

        # Extract constraint parameters from yamale validator
        # Validators store constraints in 'kwargs' attribute or 'args[1]'
        kwargs = {}
        if hasattr(validator, 'kwargs'):
            kwargs = validator.kwargs
        elif hasattr(validator, 'args') and len(validator.args) > 1:
            kwargs = validator.args[1]

        if validator_type == 'Integer':
            if 'min' in kwargs and 'max' in kwargs:
                return f"int({kwargs['min']}-{kwargs['max']})"
            elif 'min' in kwargs:
                return f"int(min={kwargs['min']})"
            elif 'max' in kwargs:
                return f"int(max={kwargs['max']})"
            else:
                return "int"

        elif validator_type == 'String':
            if 'max' in kwargs:
                return f"str(max={kwargs['max']})"
            elif 'min' in kwargs:
                return f"str(min={kwargs['min']})"
            else:
                return "str"

        elif validator_type == 'List':
            # Get inner validator if present
            if hasattr(validator, 'validators') and len(validator.validators) > 0:
                inner = validator.validators[0]
                inner_formatted = cls.format_validator(inner)
                return f"list({inner_formatted})"
            else:
                return "list"

        elif validator_type == 'Boolean':
            return "bool"

        elif validator_type == 'Enum':
            # Extract enum values from the validator
            # Enum validators store each value as a separate arg
            if hasattr(validator, 'args') and len(validator.args) > 0:
                enum_values = validator.args
                total_count = len(enum_values)
                if total_count > 5:
                    # Show first 5 options and indicate there are more
                    first_five = list(enum_values)[:5]
                    remaining = total_count - 5
                    values_str = ', '.join(f"'{v}'" for v in first_five)
                    return f"Enum({values_str}, ... and {remaining} more options)"
                else:
                    # Show all options if 5 or fewer
                    values_str = ', '.join(f"'{v}'" for v in enum_values)
                    return f"Enum({values_str})"
            # If we can't parse it, at least try to truncate the string representation
            str_repr = str(validator)
            if len(str_repr) > 200:
                return str_repr[:200] + '...)'
            return str_repr

        # Fallback to string representation (truncate if too long)
        str_repr = str(validator)
        if len(str_repr) > 200:
            return str_repr[:200] + '...)'
        return str_repr

    @classmethod
    def match(cls, inventory, schema):
        """
        Validate device variables values against their schema definitions
        """
        results = []

        # Step 1: Find all _variable parameters in feature profiles and collect unique paths
        # Format: {profile_type: {profile_name: {var_name: path}}}
        profile_variables = {}
        unique_paths = set()

        for profile_type in inventory.get('sdwan', {}).get('feature_profiles', {}):
            if profile_type not in profile_variables:
                profile_variables[profile_type] = {}

            profiles = inventory['sdwan']['feature_profiles'][profile_type]

            # Handle both list and dict profile types (e.g., policy_object_profile is a dict)
            if isinstance(profiles, dict):
                profiles = [profiles]

            for profile in profiles:
                profile_name = profile.get('name', 'unknown')
                # Build full schema path starting with sdwan.feature_profiles
                base_path = f"sdwan.feature_profiles.{profile_type}"
                profile_vars = cls.find_variable_parameters(profile, path=base_path)

                if profile_vars:
                    # Store path for each variable and collect unique paths
                    profile_variables[profile_type][profile_name] = {}
                    for var_name, path in profile_vars.items():
                        profile_variables[profile_type][profile_name][var_name] = path
                        unique_paths.add(path)

        # Step 2: Resolve validators for each unique path (cache results)
        path_validators = {}
        for path in unique_paths:
            validator = cls.navigate_schema(schema, path)
            path_validators[path] = validator

        # Step 3: Build final structure with resolved validators
        # Format: {profile_type: {profile_name: {var_name: validator}}}
        profile_validators = {}
        for profile_type, profiles in profile_variables.items():
            profile_validators[profile_type] = {}
            for profile_name, vars_dict in profiles.items():
                profile_validators[profile_type][profile_name] = {}
                for var_name, path in vars_dict.items():
                    profile_validators[profile_type][profile_name][var_name] = path_validators[path]

        # Step 4: Build configuration_group validators for all configuration groups
        # Format: {config_group_name: {var_name: validator}}
        configuration_group_validators = {}

        for config_group in inventory.get('sdwan', {}).get('configuration_groups', []):
            group_name = config_group.get('name')
            if not group_name:
                continue

            # Filter: keys ending with _profile, excluding policy_object_profile
            filter_func = lambda k: k.endswith(cls.PROFILE_SUFFIX) and k != 'policy_object_profile'
            group_validators = cls.build_group_validators(config_group, profile_validators, filter_func)

            if group_validators:
                configuration_group_validators[group_name] = group_validators

        # Step 4.5: Build policy_group validators for all policy groups
        # Format: {policy_group_name: {var_name: validator}}
        policy_group_validators = {}

        for policy_group in inventory.get('sdwan', {}).get('policy_groups', []):
            group_name = policy_group.get('name')
            if not group_name:
                continue

            # Filter: all keys except 'name' and 'policy_object_profile'
            filter_func = lambda k: k != 'name' and k != 'policy_object_profile'
            group_validators = cls.build_group_validators(policy_group, profile_validators, filter_func)

            if group_validators:
                policy_group_validators[group_name] = group_validators

        # Step 5: Validate device_variables and policy_variables against their validators
        for site in inventory.get('sdwan', {}).get('sites', []):
            for router in site.get('routers', []):
                chassis_id = router.get('chassis_id', 'unknown')

                # Validate device_variables
                config_group = router.get('configuration_group')
                device_vars = router.get('device_variables')

                if config_group and device_vars and config_group in configuration_group_validators:
                    group_validators = configuration_group_validators[config_group]
                    invalid_variables = cls.validate_variables(device_vars, group_validators)

                    if invalid_variables:
                        results.append(
                            chassis_id + " - invalid device variables values: " + ", ".join(invalid_variables)
                        )

                # Validate policy_variables
                policy_group = router.get('policy_group')
                policy_vars = router.get('policy_variables')

                if policy_group and policy_vars and policy_group in policy_group_validators:
                    group_validators = policy_group_validators[policy_group]
                    invalid_variables = cls.validate_variables(policy_vars, group_validators)

                    if invalid_variables:
                        results.append(
                            chassis_id + " - invalid policy variables values: " + ", ".join(invalid_variables)
                        )

        return results
