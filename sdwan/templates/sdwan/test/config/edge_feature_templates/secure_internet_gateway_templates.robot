*** Settings ***
Documentation   Verify Secure Internet Gateway Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.secure_internet_gateway_templates is defined %}

*** Test Cases ***
Get Secure Internet Gateway Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_secure_internet_gateway']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.secure_internet_gateway_templates | default([]) %}

Verify Edge Feature Template Secure Internet Gateway Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    # Custom handling for SIG value
    {% if ft_yaml.sig_provider == "umbrella" %}
    {% set sig_value = "secure-internet-gateway-umbrella" %}
    {% elif ft_yaml.sig_provider == "zscaler" %}
    {% set sig_value = "secure-internet-gateway-zscaler" %}
    {% elif ft_yaml.sig_provider == "other" %}
    {% set sig_value = "secure-internet-gateway-other" %}
    {% endif %}
    Should Be Equal Value Json String    ${ft.json()}    interface.vipValue[0]."tunnel-set".vipValue    {{ sig_value }}    msg=sig provider
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tracker-src-ip"
    ...    {{ ft_yaml.tracker_source_ip | default("not_defined") }}
    ...    {{ ft_yaml.tracker_source_ip_variable | default("not_defined") }}
    ...    msg=tracker_source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."umbrella-data-center"."data-center-primary"
    ...    {{ ft_yaml.umbrella_primary_data_center | default("not_defined") }}
    ...    {{ ft_yaml.umbrella_primary_data_center_variable | default("not_defined") }}
    ...    msg=umbrella_primary_data_center

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."umbrella-data-center"."data-center-secondary"
    ...    {{ ft_yaml.umbrella_secondary_data_center | default("not_defined") }}
    ...    {{ ft_yaml.umbrella_secondary_data_center_variable | default("not_defined") }}
    ...    msg=umbrella_secondary_data_center

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".aup."block-internet-until-accepted"
    ...    {{ ft_yaml.zscaler_aup_block_internet_until_accepted | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_aup_block_internet_until_accepted_variable | default("not_defined") }}
    ...    msg=zscaler_aup_block_internet_until_accepted

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".aup.enabled
    ...    {{ ft_yaml.zscaler_aup_enabled | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_aup_enabled_variable | default("not_defined") }}
    ...    msg=zscaler_aup_enabled

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".aup."force-ssl-inspection"
    ...    {{ ft_yaml.zscaler_aup_force_ssl_inspection | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_aup_force_ssl_inspection_variable | default("not_defined") }}
    ...    msg=zscaler_aup_force_ssl_inspection

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".aup.timeout
    ...    {{ ft_yaml.zscaler_aup_timeout | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_aup_timeout_variable | default("not_defined") }}
    ...    msg=zscaler_aup_timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."auth-required"
    ...    {{ ft_yaml.zscaler_authentication_required | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_authentication_required_variable | default("not_defined") }}
    ...    msg=zscaler_authentication_required

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."caution-enabled"
    ...    {{ ft_yaml.zscaler_caution_enabled | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_caution_enabled_variable | default("not_defined") }}
    ...    msg=zscaler_caution_enabled

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."ips-control"
    ...    {{ ft_yaml.zscaler_ips_control_enabled | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_ips_control_enabled_variable | default("not_defined") }}
    ...    msg=zscaler_ips_control_enabled

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."ofw-enabled"
    ...    {{ ft_yaml.zscaler_firewall_enabled | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_firewall_enabled_variable | default("not_defined") }}
    ...    msg=zscaler_firewall_enabled

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."location-name"
    ...    {{ ft_yaml.zscaler_location_name | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_location_name_variable | default("not_defined") }}
    ...    msg=zscaler_location_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".datacenters."primary-data-center"
    ...    {{ ft_yaml.zscaler_primary_data_center | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_primary_data_center_variable | default("not_defined") }}
    ...    msg=zscaler_primary_data_center

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".datacenters."secondary-data-center"
    ...    {{ ft_yaml.zscaler_secondary_data_center | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_secondary_data_center_variable | default("not_defined") }}
    ...    msg=zscaler_secondary_data_center

    # Custom handling for time that requires uppercase
    {% set display_time_unit = ft_yaml.zscaler_surrogate_display_time_unit | upper if ft_yaml.zscaler_surrogate_display_time_unit is defined else "not_defined" %}
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate."display-time-unit"
    ...    {{ display_time_unit }}
    ...    {{ ft_yaml.zscaler_surrogate_display_time_unit_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_display_time_unit
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate."idle-time"
    ...    {{ ft_yaml.zscaler_surrogate_idle_time | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_surrogate_idle_time_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_idle_time

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate.ip
    ...    {{ ft_yaml.zscaler_surrogate_ip | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_surrogate_ip_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate."ip-enforced-for-known-browsers"
    ...    {{ ft_yaml.zscaler_surrogate_ip_enforce_for_known_browsers | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_surrogate_ip_enforce_for_known_browsers_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_ip_enforce_for_known_browsers

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate."refresh-time"
    ...    {{ ft_yaml.zscaler_surrogate_refresh_time | default("not_defined") }}
    ...    {{ ft_yaml.zscaler_surrogate_refresh_time_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_refresh_time

    # Custom handling for time that requires uppercase
    {% set refresh_time_unit = ft_yaml.zscaler_surrogate_refresh_time_unit | upper if ft_yaml.zscaler_surrogate_refresh_time_unit is defined else "not_defined" %}
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings".surrogate."refresh-time-unit"
    ...    {{ refresh_time_unit }}
    ...    {{ ft_yaml.zscaler_surrogate_refresh_time_unit_variable | default("not_defined") }}
    ...    msg=zscaler_surrogate_refresh_time_unit
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."zscaler-location-settings"."xff-forward-enabled"
    ...    {{ ft_yaml.zscaler_xff_forward | default("not_defined") | lower() }}
    ...    {{ ft_yaml.zscaler_xff_forward_variable | default("not_defined") }}
    ...    msg=zscaler_xff_forward

    Should Be Equal Value Json List Length    ${ft.json()}    service.vipValue[0]."ha-pairs"."interface-pair".vipValue    {{ ft_yaml.high_availability_interface_pairs | default([]) | length }}    msg=high_availability_interface_pairs length

{% for ha_pairs in ft_yaml.high_availability_interface_pairs | default([]) %}

    Log    === High Availability Interface Pair {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."ha-pairs"."interface-pair".vipValue[{{loop.index0}}]."active-interface"
    ...    {{ ha_pairs.active_interface | default("not_defined") }}
    ...    {{ ha_pairs.active_interface_variable | default("not_defined") }}
    ...    msg=high_availability_interface_pairs.active_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."ha-pairs"."interface-pair".vipValue[{{loop.index0}}]."active-interface-weight"
    ...    {{ ha_pairs.active_interface_weight | default("not_defined") }}
    ...    {{ ha_pairs.active_interface_weight_variable | default("not_defined") }}
    ...    msg=high_availability_interface_pairs.active_interface_weight

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."ha-pairs"."interface-pair".vipValue[{{loop.index0}}]."backup-interface"
    ...    {{ ha_pairs.backup_interface | default("not_defined") }}
    ...    {{ ha_pairs.backup_interface_variable | default("not_defined") }}
    ...    msg=high_availability_interface_pairs.backup_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    service.vipValue[0]."ha-pairs"."interface-pair".vipValue[{{loop.index0}}]."backup-interface-weight"
    ...    {{ ha_pairs.backup_interface_weight | default("not_defined") }}
    ...    {{ ha_pairs.backup_interface_weight_variable | default("not_defined") }}
    ...    msg=high_availability_interface_pairs.backup_interface_weight

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    interface.vipValue    {{ ft_yaml.interfaces | default([]) | length }}    msg=interfaces length

{% for interface in ft_yaml.interfaces | default([]) %}

    Log    === Interface {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].description
    ...    {{ interface.description | default("not_defined") }}
    ...    {{ interface.description_variable | default("not_defined") }}
    ...    msg=interfaces.description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."dead-peer-detection"."dpd-interval"
    ...    {{ interface.dpd_interval | default("not_defined") }}
    ...    {{ interface.dpd_interval_variable | default("not_defined") }}
    ...    msg=interfaces.dpd_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."dead-peer-detection"."dpd-retries"
    ...    {{ interface.dpd_retries | default("not_defined") }}
    ...    {{ interface.dpd_retries_variable | default("not_defined") }}
    ...    msg=interfaces.dpd_retries

{% if interface.tunnel_type == "ipsec" %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."ike-ciphersuite"
    ...    {{ interface.ike_ciphersuite | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_ciphersuite) if defaults is defined else "not_defined") }}
    ...    {{ interface.ike_ciphersuite_variable | default("not_defined") }}
    ...    msg=interfaces.ike_ciphersuite

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."ike-group"
    ...    {{ interface.ike_group | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_group) if defaults is defined else "not_defined") }}
    ...    {{ interface.ike_group_variable | default("not_defined") }}
    ...    msg=interfaces.ike_group

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."authentication-type"."pre-shared-key"."pre-shared-secret"
    ...    {{ interface.ike_pre_shared_key | default("not_defined") }}
    ...    {{ interface.ike_pre_shared_key_variable | default("not_defined") }}
    ...    msg=interfaces.ike_pre_shared_key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."authentication-type"."pre-shared-key"."ike-local-id"
    ...    {{ interface.ike_pre_shared_key_local_id | default("not_defined") }}
    ...    {{ interface.ike_pre_shared_key_local_id_variable | default("not_defined") }}
    ...    msg=interfaces.ike_pre_shared_key_local_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."authentication-type"."pre-shared-key"."ike-remote-id"
    ...    {{ interface.ike_pre_shared_key_remote_id | default("not_defined") }}
    ...    {{ interface.ike_pre_shared_key_remote_id_variable | default("not_defined") }}
    ...    msg=interfaces.ike_pre_shared_key_remote_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ike."ike-rekey-interval"
    ...    {{ interface.ike_rekey_interval | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_rekey_interval) if defaults is defined else "not_defined") }}
    ...    {{ interface.ike_rekey_interval_variable | default("not_defined") }}
    ...    msg=interfaces.ike_rekey_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ipsec."ipsec-ciphersuite"
    ...    {{ interface.ipsec_ciphersuite | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_ciphersuite) if defaults is defined else "not_defined") }}
    ...    {{ interface.ipsec_ciphersuite_variable | default("not_defined") }}
    ...    msg=interfaces.ipsec_ciphersuite

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ipsec."perfect-forward-secrecy"
    ...    {{ interface.ipsec_perfect_forward_secrecy | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_perfect_forward_secrecy) if defaults is defined else "not_defined") }}
    ...    {{ interface.ipsec_perfect_forward_secrecy_variable | default("not_defined") }}
    ...    msg=interfaces.ipsec_perfect_forward_secrecy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ipsec."ipsec-rekey-interval"
    ...    {{ interface.ipsec_rekey_interval | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_rekey_interval) if defaults is defined else "not_defined") }}
    ...    {{ interface.ipsec_rekey_interval_variable | default("not_defined") }}
    ...    msg=interfaces.ipsec_rekey_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].ipsec."ipsec-replay-window"
    ...    {{ interface.ipsec_replay_window | default((defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_replay_window) if defaults is defined else "not_defined") }}
    ...    {{ interface.ipsec_replay_window_variable | default("not_defined") }}
    ...    msg=interfaces.ipsec_replay_window

{% endif %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].mtu
    ...    {{ interface.mtu | default("not_defined") }}
    ...    {{ interface.mtu_variable | default("not_defined") }}
    ...    msg=interfaces.mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."if-name"
    ...    {{ interface.name | default("not_defined") }}
    ...    {{ interface.name_variable | default("not_defined") }}
    ...    msg=interfaces.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].shutdown
    ...    {{ interface.shutdown | default("not_defined") | lower() }}
    ...    {{ interface.shutdown_variable | default("not_defined") }}
    ...    msg=interfaces.shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."tcp-mss-adjust"
    ...    {{ interface.tcp_mss | default("not_defined") }}
    ...    {{ interface.tcp_mss_variable | default("not_defined") }}
    ...    msg=interfaces.tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."track-enable"
    ...    {{ interface.track | default("not_defined") | lower() }}
    ...    {{ interface.track_variable | default("not_defined") }}
    ...    msg=interfaces.track

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}].tracker
    ...    {{ interface.tracker | default("not_defined") }}
    ...    {{ interface.tracker_variable | default("not_defined") }}
    ...    msg=interfaces.tracker

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."tunnel-dc-preference"
    ...    {{ interface.tunnel_dc_preference | default("not_defined") }}
    ...    {{ interface.tunnel_dc_preference_variable | default("not_defined") }}
    ...    msg=interfaces.tunnel_dc_preference

{% if ft_yaml.sig_provider == "other" %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."tunnel-destination"
    ...    {{ interface.tunnel_destination | default("not_defined") }}
    ...    {{ interface.tunnel_destination_variable | default("not_defined") }}
    ...    msg=interfaces.tunnel_destination

{% endif %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    interface.vipValue[{{loop.index0}}]."tunnel-source-interface"
    ...    {{ interface.tunnel_source_interface | default("not_defined") }}
    ...    {{ interface.tunnel_source_interface_variable | default("not_defined") }}
    ...    msg=interfaces.tunnel_source_interface

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    tracker.vipValue    {{ ft_yaml.trackers | default([]) | length }}    msg=trackers length

{% for tracker in ft_yaml.trackers | default([]) %}

    Log    === Tracker {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker.vipValue[{{loop.index0}}]."endpoint-api-url"
    ...    {{ tracker.endpoint_api_url | default("not_defined") }}
    ...    {{ tracker.endpoint_api_url_variable | default("not_defined") }}
    ...    msg=trackers.endpoint_api_url

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker.vipValue[{{loop.index0}}].interval
    ...    {{ tracker.interval | default("not_defined") }}
    ...    {{ tracker.interval_variable | default("not_defined") }}
    ...    msg=trackers.interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker.vipValue[{{loop.index0}}].multiplier
    ...    {{ tracker.multiplier | default("not_defined") }}
    ...    {{ tracker.multiplier_variable | default("not_defined") }}
    ...    msg=trackers.multiplier

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker.vipValue[{{loop.index0}}].name
    ...    {{ tracker.name | default("not_defined") }}
    ...    {{ tracker.name_variable | default("not_defined") }}
    ...    msg=trackers.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker.vipValue[{{loop.index0}}].threshold
    ...    {{ tracker.threshold | default("not_defined") }}
    ...    {{ tracker.threshold_variable | default("not_defined") }}
    ...    msg=trackers.threshold

{% endfor %}

{% endfor %}

{% endif %}
