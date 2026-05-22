*** Settings ***
Documentation   Verify SNMP Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.snmp_templates is defined%}

*** Test Cases ***
Get SNMP Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_snmp']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.snmp_templates | default([]) %}

Verify Edge Feature Template SNMP Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.snmp_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    contact
    ...    {{ ft_yaml.contact | default("not_defined") }}
    ...    {{ ft_yaml.contact_variable | default("not_defined") }}
    ...    msg=contact

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    location
    ...    {{ ft_yaml.location | default("not_defined") }}
    ...    {{ ft_yaml.location_variable | default("not_defined") }}
    ...    msg=location

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json List Length    ${ft.json()}    community.vipValue    {{ ft_yaml.communities | default([]) | length }}    msg=communities length

{% for snmp_community in ft_yaml.communities | default([]) %}

    Log    === Community {{loop.index0}} ===

    # Custom handling for authorization as in data model is true/false and in API is "read-only" or not present
    {% if snmp_community.authorization_read_only is defined and snmp_community.authorization_read_only %}
        {% set authorization = "read-only" %}
    {% elif defaults.sdwan.edge_feature_templates.snmp_templates.communities.authorization_read_only is defined and defaults.sdwan.edge_feature_templates.snmp_templates.communities.authorization_read_only %}
        {% set authorization = "read-only" %}
    {% else %}
        {% set authorization = "not_defined" %}
    {% endif %}
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    community.vipValue[{{loop.index0}}].authorization
    ...    {{ authorization }}
    ...    {{ snmp_community.authorization_read_only_variable | default("not_defined") }}
    ...    msg=communities.authorization_read_only
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    community.vipValue[{{loop.index0}}].name
    ...    {{ snmp_community.name | default("not_defined") }}
    ...    {{ snmp_community.name_variable | default("not_defined") }}
    ...    msg=communities.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    community.vipValue[{{loop.index0}}].view
    ...    {{ snmp_community.view | default("not_defined") }}
    ...    {{ snmp_community.view_variable | default("not_defined") }}
    ...    msg=communities.view

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    group.vipValue    {{ ft_yaml.groups | default([]) | length }}    msg=groups length

{% for snmp_group in ft_yaml.groups | default([]) %}

    Log    === Group {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    group.vipValue[{{loop.index0}}].name
    ...    {{ snmp_group.name | default("not_defined") }}
    ...    {{ snmp_group.name_variable | default("not_defined") }}
    ...    msg=groups.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    group.vipValue[{{loop.index0}}]."security-level"
    ...    {{ snmp_group.security_level | default("not_defined") }}
    ...    {{ snmp_group.security_level_variable | default("not_defined") }}
    ...    msg=groups.security_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    group.vipValue[{{loop.index0}}].view
    ...    {{ snmp_group.view | default("not_defined") }}
    ...    {{ snmp_group.view_variable | default("not_defined") }}
    ...    msg=groups.view

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    trap.target.vipValue    {{ ft_yaml.trap_target_servers | default([]) | length }}    msg=trap_target_servers length

{% for snmp_trap_target_server in ft_yaml.trap_target_servers | default([]) %}

    Log    === Trap Target Server {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}]."community-name"
    ...    {{ snmp_trap_target_server.community_name | default("not_defined") }}
    ...    {{ snmp_trap_target_server.community_name_variable | default("not_defined") }}
    ...    msg=trap_target_servers.community_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}].ip
    ...    {{ snmp_trap_target_server.ip | default("not_defined") }}
    ...    {{ snmp_trap_target_server.ip_variable | default("not_defined") }}
    ...    msg=trap_target_servers.ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}]."source-interface"
    ...    {{ snmp_trap_target_server.source_interface | default("not_defined") }}
    ...    {{ snmp_trap_target_server.source_interface_variable | default("not_defined") }}
    ...    msg=trap_target_servers.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}].port
    ...    {{ snmp_trap_target_server.udp_port | default("not_defined") }}
    ...    {{ snmp_trap_target_server.udp_port_variable | default("not_defined") }}
    ...    msg=trap_target_servers.udp_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}].user
    ...    {{ snmp_trap_target_server.user | default("not_defined") }}
    ...    {{ snmp_trap_target_server.user_variable | default("not_defined") }}
    ...    msg=trap_target_servers.user

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trap.target.vipValue[{{loop.index0}}]."vpn-id"
    ...    {{ snmp_trap_target_server.vpn_id | default("not_defined") }}
    ...    {{ snmp_trap_target_server.vpn_id_variable | default("not_defined") }}
    ...    msg=trap_target_servers.vpn_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    user.vipValue    {{ ft_yaml.users | default([]) | length }}    msg=users length

{% for user in ft_yaml.users | default([]) %}

    Log    === User {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}]."auth-password"
    ...    {{ user.authentication_password | default("not_defined") }}
    ...    {{ user.authentication_password_variable | default("not_defined") }}
    ...    msg=users.authentication_password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}].auth
    ...    {{ user.authentication_protocol | default("not_defined") }}
    ...    {{ user.authentication_protocol_variable | default("not_defined") }}
    ...    msg=users.authentication_protocol

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}].name
    ...    {{ user.name | default("not_defined") }}
    ...    {{ user.name_variable | default("not_defined") }}
    ...    msg=users.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}].group
    ...    {{ user.group | default("not_defined") }}
    ...    {{ user.group_variable | default("not_defined") }}
    ...    msg=users.group

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}]."priv-password"
    ...    {{ user.privacy_password | default("not_defined") }}
    ...    {{ user.privacy_password_variable | default("not_defined") }}
    ...    msg=users.privacy_password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    user.vipValue[{{loop.index0}}].priv
    ...    {{ user.privacy_protocol | default("not_defined") }}
    ...    {{ user.privacy_protocol_variable | default("not_defined") }}
    ...    msg=users.privacy_protocol

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    view.vipValue    {{ ft_yaml.views | default([]) | length }}    msg=views length

{% for view_index in range(ft_yaml.views | default([]) | length()) %}

    Log    === View {{view_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    view.vipValue[{{view_index}}].name
    ...    {{ ft_yaml.views[view_index].name | default("not_defined") }}
    ...    {{ ft_yaml.views[view_index].name_variable | default("not_defined") }}
    ...    msg=views.name

    Should Be Equal Value Json List Length    ${ft.json()}    view.vipValue[{{view_index}}].oid.vipValue    {{ ft_yaml.views[view_index].oids | default([]) | length }}    msg=views.oids length

{% for oid_index in range(ft_yaml.views[view_index].oids | default([]) | length()) %}

    Log    === View {{view_index}} OID {{oid_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    view.vipValue[{{view_index}}].oid.vipValue[{{oid_index}}].id
    ...    {{ ft_yaml.views[view_index].oids[oid_index].id | default("not_defined") }}
    ...    {{ ft_yaml.views[view_index].oids[oid_index].id_variable | default("not_defined") }}
    ...    msg=views.oids.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    view.vipValue[{{view_index}}].oid.vipValue[{{oid_index}}].exclude
    ...    {{ ft_yaml.views[view_index].oids[oid_index].exclude | default("not_defined") }}
    ...    {{ ft_yaml.views[view_index].oids[oid_index].exclude_variable | default("not_defined") }}
    ...    msg=views.oids.exclude

{% endfor %}

{% endfor %}

{% endfor %}

{% endif %}
