*** Settings ***
Documentation   Verify DHCP Server Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.dhcp_server_templates is defined %}

*** Test Cases ***
Get DHCP Server Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_dhcp_server']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.dhcp_server_templates | default([]) %}

Verify Edge Feature Template DHCP Server Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.dhcp_server_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "address-pool"
    ...    {{ ft_yaml.address_pool | default("not_defined") }}
    ...    {{ ft_yaml.address_pool_variable | default("not_defined") }}
    ...    msg=address_pool

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "options"."default-gateway"
    ...    {{ ft_yaml.default_gateway | default("not_defined") }}
    ...    {{ ft_yaml.default_gateway_variable | default("not_defined") }}
    ...    msg=default_gateway

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "options"."dns-servers"
    ...    {{ ft_yaml.dns_servers | default("not_defined") }}
    ...    {{ ft_yaml.dns_servers_variable | default("not_defined") }}
    ...    msg=dns_servers

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "options"."domain-name"
    ...    {{ ft_yaml.domain_name | default("not_defined") }}
    ...    {{ ft_yaml.domain_name_variable | default("not_defined") }}
    ...    msg=domain_name

    # Need custom handling as single JSON field is represented by two data model fields (exclude_addresses and exclude_addresses_ranges)
    ${exclude_addresses}=    Create List
    {% for exclude_address in ft_yaml.exclude_addresses | default([]) %}
    Append To List    ${exclude_addresses}    {{ exclude_address }}
    {% endfor %}

    {% for exclude_address_range in ft_yaml.exclude_addresses_ranges | default([]) %}
    {% set test_list = [] %}
    {% set _ = test_list.append(exclude_address_range.from) %}
    {% set _ = test_list.append(exclude_address_range.to) %}
    {% set address_range = '-'.join(test_list | map('string')) %}
    Append To List    ${exclude_addresses}    {{ address_range }}
    {% endfor %}

    ${exclude_addresses}=    Set Variable If    ${exclude_addresses} == []    not_defined    ${exclude_addresses}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    exclude
    ...    ${exclude_addresses}
    ...    {{ ft_yaml.exclude_addresses_variable | default("not_defined") }}
    ...    msg=exclude_addresses|exclude_addresses_ranges
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "options"."interface-mtu"
    ...    {{ ft_yaml.interface_mtu | default("not_defined") }}
    ...    {{ ft_yaml.interface_mtu_variable | default("not_defined") }}
    ...    msg=interface_mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "lease-time"
    ...    {{ ft_yaml.lease_time | default("not_defined") }}
    ...    {{ ft_yaml.lease_time_variable | default("not_defined") }}
    ...    msg=lease_time

    Should Be Equal Value Json List Length    ${ft.json()}    options."option-code".vipValue    {{ ft_yaml.options | default([]) | length }}    msg=options length

{% for option in ft_yaml.options | default([]) %}

    Log    === Option {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    options."option-code".vipValue[{{loop.index0}}].code
    ...    {{ option.option_code | default("not_defined") }}
    ...    {{ option.option_code_variable | default("not_defined") }}
    ...    msg=options.option_code

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    options."option-code".vipValue[{{loop.index0}}].ascii
    ...    {{ option.ascii | default("not_defined") }}
    ...    {{ option.ascii_variable | default("not_defined") }}
    ...    msg=options.ascii

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    options."option-code".vipValue[{{loop.index0}}].hex
    ...    {{ option.hex | default("not_defined") }}
    ...    {{ option.hex_variable | default("not_defined") }}
    ...    msg=options.hex

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    options."option-code".vipValue[{{loop.index0}}].ip
    ...    {{ option.ip_addresses | default("not_defined") }}
    ...    {{ option.ip_addresses_variable | default("not_defined") }}
    ...    msg=options.ip_addresses

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "static-lease".vipValue    {{ ft_yaml.static_leases | default([]) | length }}    msg=static_leases length

{% for static_lease in ft_yaml.static_leases | default([]) %}

    Log    === Static Lease {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-lease".vipValue[{{loop.index0}}].ip
    ...    {{ static_lease.ip_address | default("not_defined") }}
    ...    {{ static_lease.ip_address_variable | default("not_defined") }}
    ...    msg=static_leases.ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-lease".vipValue[{{loop.index0}}]."mac-address"
    ...    {{ static_lease.mac_address | default("not_defined") }}
    ...    {{ static_lease.mac_address_variable | default("not_defined") }}
    ...    msg=static_leases.mac_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "static-lease".vipValue[{{loop.index0}}]."host-name"
    ...    {{ static_lease.hostname | default("not_defined") }}
    ...    {{ static_lease.hostname_variable | default("not_defined") }}
    ...    msg=static_leases.hostname

    Should Be Equal Value Json String    ${ft.json()}    "static-lease".vipValue[{{loop.index0}}].vipOptional
    ...    {{ static_lease.optional | default("not_defined") }}
    ...    msg=static_leases.optional

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tftp-servers"
    ...    {{ ft_yaml.tftp_servers | default("not_defined") }}
    ...    {{ ft_yaml.tftp_servers_variable | default("not_defined") }}
    ...    msg=tftp_servers

{% endfor %}

{% endif %}
