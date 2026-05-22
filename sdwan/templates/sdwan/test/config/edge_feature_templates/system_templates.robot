*** Settings ***
Documentation   Verify System Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.system_templates is defined%}

*** Test Cases ***
Get System Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_system']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.system_templates | default([]) %}

Verify Edge Feature Template System Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.system_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "admin-tech-on-failure"
    ...    {{ ft_yaml.admin_tech_on_failure | default("not_defined") | lower }}
    ...    {{ ft_yaml.admin_tech_on_failure_variable | default("not_defined") }}
    ...    msg=admin_tech_on_failure

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "affinity-group"."affinity-group-number"
    ...    {{ ft_yaml.affinity_group_number | default("not_defined") }}
    ...    {{ ft_yaml.affinity_group_number_variable | default("not_defined") }}
    ...    msg=affinity_group_number

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "affinity-group".preference
    ...    {{ ft_yaml.affinity_group_preferences | default("not_defined") }}
    ...    {{ ft_yaml.affinity_group_preferences_variable | default("not_defined") }}
    ...    msg=affinity_group_preferences

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "console-baud-rate"
    ...    {{ ft_yaml.console_baud_rate | default("not_defined") }}
    ...    {{ ft_yaml.console_baud_rate_variable | default("not_defined") }}
    ...    msg=console_baud_rate

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "control-session-pps"
    ...    {{ ft_yaml.control_session_pps | default("not_defined") }}
    ...    {{ ft_yaml.control_session_pps_variable | default("not_defined") }}
    ...    msg=control_session_pps

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "controller-group-list"
    ...    {{ ft_yaml.controller_groups | default("not_defined") }}
    ...    {{ ft_yaml.controller_groups_variable | default("not_defined") }}
    ...    msg=controller_groups

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "device-groups"
    ...    {{ ft_yaml.device_groups | default("not_defined") }}
    ...    {{ ft_yaml.device_groups_variable | default("not_defined") }}
    ...    msg=device_groups

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "enable-mrf-migration"
    ...    {{ ft_yaml.enable_mrf_migration | default("not_defined") }}
    ...    {{ ft_yaml.enable_mrf_migration_variable | default("not_defined") }}
    ...    msg=enable_mrf_migration

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location"."geo-fencing".enable
    ...    {{ ft_yaml.geo_fencing | default("not_defined") | lower }}
    ...    {{ ft_yaml.geo_fencing_variable | default("not_defined") }}
    ...    msg=geo_fencing

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location"."geo-fencing".sms.enable
    ...    {{ ft_yaml.geo_fencing_sms | default("not_defined") | lower }}
    ...    {{ ft_yaml.geo_fencing_sms_variable | default("not_defined") }}
    ...    msg=geo_fencing_sms

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location"."geo-fencing".range
    ...    {{ ft_yaml.geo_fencing_range | default("not_defined") }}
    ...    {{ ft_yaml.geo_fencing_range_variable | default("not_defined") }}
    ...    msg=geo_fencing_range

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "host-name"
    ...    {{ ft_yaml.hostname | default("not_defined") }}
    ...    {{ ft_yaml.hostname_variable | default("not_defined") }}
    ...    msg=hostname

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "idle-timeout"
    ...    {{ ft_yaml.idle_timeout | default("not_defined") }}
    ...    {{ ft_yaml.idle_timeout_variable | default("not_defined") }}
    ...    msg=idle_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "max-omp-sessions"
    ...    {{ ft_yaml.max_omp_sessions | default("not_defined") }}
    ...    {{ ft_yaml.max_omp_sessions_variable | default("not_defined") }}
    ...    msg=max_omp_sessions

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "migration-bgp-community"
    ...    {{ ft_yaml.migration_bgp_community | default("not_defined") }}
    ...    {{ ft_yaml.migration_bgp_community_variable | default("not_defined") }}
    ...    msg=migration_bgp_community

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "multi-tenant"
    ...    {{ ft_yaml.multi_tenant | default("not_defined") | lower }}
    ...    {{ ft_yaml.multi_tenant_variable | default("not_defined") }}
    ...    msg=multi_tenant

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location".latitude
    ...    {{ ft_yaml.latitude | default("not_defined") }}
    ...    {{ ft_yaml.latitude_variable | default("not_defined") }}
    ...    msg=latitude

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location".longitude
    ...    {{ ft_yaml.longitude | default("not_defined") }}
    ...    {{ ft_yaml.longitude_variable | default("not_defined") }}
    ...    msg=longitude

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "location"
    ...    {{ ft_yaml.location | default("not_defined") }}
    ...    {{ ft_yaml.location_variable | default("not_defined") }}
    ...    msg=location

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "on-demand".enable
    ...    {{ ft_yaml.on_demand_tunnel | default("not_defined") | lower }}
    ...    {{ ft_yaml.on_demand_tunnel_variable | default("not_defined") }}
    ...    msg=on_demand_tunnel

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "on-demand"."idle-timeout"
    ...    {{ ft_yaml.on_demand_tunnel_idle_timeout | default("not_defined") }}
    ...    {{ ft_yaml.on_demand_tunnel_idle_timeout_variable | default("not_defined") }}
    ...    msg=on_demand_tunnel_idle_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "overlay-id"
    ...    {{ ft_yaml.overlay_id | default("not_defined") }}
    ...    {{ ft_yaml.overlay_id_variable | default("not_defined") }}
    ...    msg=overlay_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "port-hop"
    ...    {{ ft_yaml.port_hopping | default("not_defined") | lower }}
    ...    {{ ft_yaml.port_hopping_variable | default("not_defined") }}
    ...    msg=port_hopping

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "port-offset"
    ...    {{ ft_yaml.port_offset | default("not_defined") }}
    ...    {{ ft_yaml.port_offset_variable | default("not_defined") }}
    ...    msg=port_offset

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "region-id"
    ...    {{ ft_yaml.region_id | default("not_defined") }}
    ...    {{ ft_yaml.region_id_variable | default("not_defined") }}
    ...    msg=region_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "role"
    ...    {{ ft_yaml.role | default("not_defined") }}
    ...    {{ ft_yaml.role_variable | default("not_defined") }}
    ...    msg=role

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "secondary-region"
    ...    {{ ft_yaml.secondary_region_id | default("not_defined") }}
    ...    {{ ft_yaml.secondary_region_id_variable | default("not_defined") }}
    ...    msg=secondary_region_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "site-id"
    ...    {{ ft_yaml.site_id | default("not_defined") }}
    ...    {{ ft_yaml.site_id_variable | default("not_defined") }}
    ...    msg=site_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "description"
    ...    {{ ft_yaml.system_description | default("not_defined") }}
    ...    {{ ft_yaml.system_description_variable | default("not_defined") }}
    ...    msg=system_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "system-ip"
    ...    {{ ft_yaml.system_ip | default("not_defined") }}
    ...    {{ ft_yaml.system_ip_variable | default("not_defined") }}
    ...    msg=system_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "clock".timezone
    ...    {{ ft_yaml.timezone | default("not_defined") }}
    ...    {{ ft_yaml.timezone_variable | default("not_defined") }}
    ...    msg=timezone

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "track-default-gateway"
    ...    {{ ft_yaml.track_default_gateway | default("not_defined") | lower }}
    ...    {{ ft_yaml.track_default_gateway_variable | default("not_defined") }}
    ...    msg=track_default_gateway

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "track-interface-tag"
    ...    {{ ft_yaml.track_interface_omp_tag | default("not_defined") }}
    ...    {{ ft_yaml.track_interface_omp_tag_variable | default("not_defined") }}
    ...    msg=track_interface_omp_tag

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "track-transport"
    ...    {{ ft_yaml.track_transport | default("not_defined") | lower }}
    ...    {{ ft_yaml.track_transport_variable | default("not_defined") }}
    ...    msg=track_transport

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "transport-gateway"
    ...    {{ ft_yaml.transport_gateway | default("not_defined") | lower }}
    ...    {{ ft_yaml.transport_gateway_variable | default("not_defined") }}
    ...    msg=transport_gateway

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "epfr"
    ...    {{ ft_yaml.enhanced_app_aware_routing | default("not_defined") }}
    ...    {{ ft_yaml.enhanced_app_aware_routing_variable | default("not_defined") }}
    ...    msg=enhanced_app_aware_routing

    Should Be Equal Value Json List Length    ${ft.json()}    "gps-location"."geo-fencing".sms."mobile-number".vipValue    {{ ft_yaml.geo_fencing_sms_phone_numbers | default([]) | length }}    msg=geo_fencing_sms_phone_numbers.length

{% for geo_fencing_phone in ft_yaml.geo_fencing_sms_phone_numbers | default([]) %}

    Log    === Geo Fencing SMS Phone Number {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "gps-location"."geo-fencing".sms."mobile-number".vipValue[{{loop.index0}}].number
    ...    {{ geo_fencing_phone.number | default("not_defined") }}
    ...    {{ geo_fencing_phone.number_variable | default("not_defined") }}
    ...    msg=geo_fencing_sms_phone_numbers.number

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "tracker".vipValue    {{ ft_yaml.endpoint_trackers | default([]) | length }}    msg=endpoint_trackers.length

{% for endpoint_tracker in ft_yaml.endpoint_trackers | default([]) %}

    Log    === Endpoint Tracker {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].name
    ...    {{ endpoint_tracker.name | default("not_defined") }}
    ...    {{ endpoint_tracker.name_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].boolean
    ...    {{ endpoint_tracker.group_criteria | default("not_defined") }}
    ...    {{ endpoint_tracker.group_criteria_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.group_criteria

    # Custom handling for group trackers
    ${endpoint_group_trackers}=    Json Search List    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].elements.vipValue
    IF    ${endpoint_group_trackers} == []
        Should Be Equal Value Json String    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].elements.vipValue    {{ endpoint_tracker.group_trackers | default("not_defined") }}    msg=endpoint_trackers.group_trackers
    ELSE
        ${group_tracker_list}=    Create List    {{ endpoint_tracker.group_trackers | default([]) | join('   ') }}
        Lists Should Be Equal    ${endpoint_group_trackers}    ${group_tracker_list}    ignore_order=True    msg=endpoint_trackers.group_trackers
    END
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}]."endpoint-api-url"
    ...    {{ endpoint_tracker.endpoint_api_url | default("not_defined") }}
    ...    {{ endpoint_tracker.endpoint_api_url_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.endpoint_api_url

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}]."endpoint-dns-name"
    ...    {{ endpoint_tracker.endpoint_dns_name | default("not_defined") }}
    ...    {{ endpoint_tracker.endpoint_dns_name_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.endpoint_dns_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}]."endpoint-ip"
    ...    {{ endpoint_tracker.endpoint_ip | default("not_defined") }}
    ...    {{ endpoint_tracker.endpoint_ip_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.endpoint_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].interval
    ...    {{ endpoint_tracker.interval | default((defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.interval) if defaults is defined else "not_defined") }}
    ...    {{ endpoint_tracker.interval_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].multiplier
    ...    {{ endpoint_tracker.multiplier | default((defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.multiplier) if defaults is defined else "not_defined") }}
    ...    {{ endpoint_tracker.multiplier_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.multiplier

    Should Be Equal Value Json String    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].vipOptional    {{ endpoint_tracker.optional | default("not_defined") }}    msg=endpoint_trackers.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].threshold
    ...    {{ endpoint_tracker.threshold | default((defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.threshold) if defaults is defined else "not_defined") }}
    ...    {{ endpoint_tracker.threshold_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.threshold

    # Custom handling for tracker type
    {% if endpoint_tracker.group_trackers is defined %}
    {% set tracker_type = "tracker-group" %}
    {% else %}
    {% set tracker_type = endpoint_tracker.type | default(defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.type) %}
    {% endif %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker".vipValue[{{loop.index0}}].type
    ...    {{ tracker_type }}
    ...    {{ endpoint_tracker.type_variable | default("not_defined") }}
    ...    msg=endpoint_trackers.type
    # End of custom handling

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    "object-track".vipValue    {{ ft_yaml.object_trackers | default([]) | length }}    msg=object_trackers.length

{% for object_tracker in ft_yaml.object_trackers | default([]) %}

    Log    === Object Tracker {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].boolean
    ...    {{ object_tracker.group_criteria | default("not_defined") }}
    ...    {{ object_tracker.group_criteria_variable | default("not_defined") }}
    ...    msg=object_trackers.group_criteria

    # Custom handling for object group trackers
    ${object_group_trackers}=    Json Search List    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].object.vipValue[].number.vipValue
    IF    ${object_group_trackers} == []
        Should Be Equal Value Json String    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].object.vipValue[].number.vipValue    {{ object_tracker.group_trackers | default("not_defined") }}    msg=object_trackers.group_trackers
    ELSE
        ${r_object_group_trackers}=   Create List
        FOR   ${item}    IN   @{object_group_trackers}
            ${item_int}=   Convert To String   ${item}
            Append To List   ${r_object_group_trackers}   ${item_int}
        END
        ${o_group_tracker}=   Create List   {{ object_tracker.group_trackers | default([]) | join('   ') }}
        Lists Should Be Equal    ${r_object_group_trackers}    ${o_group_tracker}    msg=object_trackers.group_trackers
    END

    Should Be Equal Value Json String    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].boolean.vipVariableName    {{ object_tracker.group_trackers_variable | default("not_defined") }}    msg=object_trackers.group_trackers_variable
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}]."object-number"
    ...    {{ object_tracker.id | default("not_defined") }}
    ...    {{ object_tracker.id_variable | default("not_defined") }}
    ...    msg=object_trackers.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].interface
    ...    {{ object_tracker.interface | default("not_defined") }}
    ...    {{ object_tracker.interface_variable | default("not_defined") }}
    ...    msg=object_trackers.interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].ip
    ...    {{ object_tracker.ip | default("not_defined") }}
    ...    {{ object_tracker.ip_variable | default("not_defined") }}
    ...    msg=object_trackers.ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].mask
    ...    {{ object_tracker.mask | default("not_defined") }}
    ...    {{ object_tracker.mask_variable | default("not_defined") }}
    ...    msg=object_trackers.mask

    Should Be Equal Value Json String    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].vipOptional    {{ object_tracker.optional | default("not_defined") }}    msg=object_trackers.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "object-track".vipValue[{{loop.index0}}].vpn
    ...    {{ object_tracker.vpn_id | default("not_defined") }}
    ...    {{ object_tracker.vpn_id_variable | default("not_defined") }}
    ...    msg=object_trackers.vpn_id

{% endfor %}

{% endfor %}

{% endif %}
