*** Settings ***
Documentation   Verify IPsec Interface Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.ipsec_interface_templates is defined %}

*** Test Cases ***
Get IPsec Interface Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_vpn_interface_ipsec']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.ipsec_interface_templates | default([]) %}

Verify Edge Feature Template IPsec Interface Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.ipsec_interface_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    application
    ...    {{ ft_yaml.application | default("not_defined") }}
    ...    {{ ft_yaml.application_variable | default("not_defined") }}
    ...    msg=application

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "clear-dont-fragment"
    ...    {{ ft_yaml.clear_dont_fragment | default("not_defined") }}
    ...    {{ ft_yaml.clear_dont_fragment_variable | default("not_defined") }}
    ...    msg=clear_dont_fragment

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dead-peer-detection"."dpd-interval"
    ...    {{ ft_yaml.dead_peer_detection_interval | default("not_defined") }}
    ...    {{ ft_yaml.dead_peer_detection_interval_variable | default("not_defined") }}
    ...    msg=dead_peer_detection_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "dead-peer-detection"."dpd-retries"
    ...    {{ ft_yaml.dead_peer_detection_retries | default("not_defined") }}
    ...    {{ ft_yaml.dead_peer_detection_retries_variable | default("not_defined") }}
    ...    msg=dead_peer_detection_retries

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    description
    ...    {{ ft_yaml.interface_description | default("not_defined") }}
    ...    {{ ft_yaml.interface_description_variable | default("not_defined") }}
    ...    msg=interface_description

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "if-name"
    ...    {{ ft_yaml.interface_name | default("not_defined") }}
    ...    {{ ft_yaml.interface_name_variable | default("not_defined") }}
    ...    msg=interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ip.address
    ...    {{ ft_yaml.ip_address | default("not_defined") }}
    ...    {{ ft_yaml.ip_address_variable | default("not_defined") }}
    ...    msg=ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    mtu
    ...    {{ ft_yaml.mtu | default("not_defined") }}
    ...    {{ ft_yaml.mtu_variable | default("not_defined") }}
    ...    msg=mtu

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    shutdown
    ...    {{ ft_yaml.shutdown | default("not_defined") }}
    ...    {{ ft_yaml.shutdown_variable | default("not_defined") }}
    ...    msg=shutdown

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tcp-mss-adjust"
    ...    {{ ft_yaml.tcp_mss | default("not_defined") }}
    ...    {{ ft_yaml.tcp_mss_variable | default("not_defined") }}
    ...    msg=tcp_mss

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    tracker
    ...    {{ ft_yaml.tracker | default("not_defined") }}
    ...    {{ ft_yaml.tracker_variable | default("not_defined") }}
    ...    msg=tracker

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-destination"
    ...    {{ ft_yaml.tunnel_destination | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_destination_variable | default("not_defined") }}
    ...    msg=tunnel_destination

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-source-interface"
    ...    {{ ft_yaml.tunnel_source_interface | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_source_interface_variable | default("not_defined") }}
    ...    msg=tunnel_source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    "tunnel-source"
    ...    {{ ft_yaml.tunnel_source_ip | default("not_defined") }}
    ...    {{ ft_yaml.tunnel_source_ip_variable | default("not_defined") }}
    ...    msg=tunnel_source_ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."ike-ciphersuite"
    ...    {{ ft_yaml.ike.ciphersuite | default("not_defined") }}
    ...    {{ ft_yaml.ike.ciphersuite_variable | default("not_defined") }}
    ...    msg=ike.ciphersuite

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."ike-group"
    ...    {{ ft_yaml.ike.group | default("not_defined") }}
    ...    {{ ft_yaml.ike.group_variable | default("not_defined") }}
    ...    msg=ike.group

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."ike-mode"
    ...    {{ ft_yaml.ike.mode | default("not_defined") }}
    ...    {{ ft_yaml.ike.mode_variable | default("not_defined") }}
    ...    msg=ike.mode

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."authentication-type"."pre-shared-key"."pre-shared-secret"
    ...    {{ ft_yaml.ike.pre_shared_key | default("not_defined") }}
    ...    {{ ft_yaml.ike.pre_shared_key_variable | default("not_defined") }}
    ...    msg=ike.pre_shared_key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."authentication-type"."pre-shared-key"."ike-local-id"
    ...    {{ ft_yaml.ike.pre_shared_key_local_id | default("not_defined") }}
    ...    {{ ft_yaml.ike.pre_shared_key_local_id_variable | default("not_defined") }}
    ...    msg=ike.pre_shared_key_local_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."authentication-type"."pre-shared-key"."ike-remote-id"
    ...    {{ ft_yaml.ike.pre_shared_key_remote_id | default("not_defined") }}
    ...    {{ ft_yaml.ike.pre_shared_key_remote_id_variable | default("not_defined") }}
    ...    msg=ike.pre_shared_key_remote_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."ike-rekey-interval"
    ...    {{ ft_yaml.ike.rekey_interval | default("not_defined") }}
    ...    {{ ft_yaml.ike.rekey_interval_variable | default("not_defined") }}
    ...    msg=ike.rekey_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ike."ike-version"
    ...    {{ ft_yaml.ike.version | default("not_defined") }}
    ...    {{ ft_yaml.ike.version_variable | default("not_defined") }}
    ...    msg=ike.version

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."ipsec-ciphersuite"
    ...    {{ ft_yaml.ipsec.ciphersuite | default("not_defined") }}
    ...    {{ ft_yaml.ipsec.ciphersuite_variable | default("not_defined") }}
    ...    msg=ipsec.ciphersuite

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."perfect-forward-secrecy"
    ...    {{ ft_yaml.ipsec.perfect_forward_secrecy | default("not_defined") }}
    ...    {{ ft_yaml.ipsec.perfect_forward_secrecy_variable | default("not_defined") }}
    ...    msg=ipsec.perfect_forward_secrecy

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."ipsec-rekey-interval"
    ...    {{ ft_yaml.ipsec.rekey_interval | default("not_defined") }}
    ...    {{ ft_yaml.ipsec.rekey_interval_variable | default("not_defined") }}
    ...    msg=ipsec.rekey_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."ipsec-replay-window"
    ...    {{ ft_yaml.ipsec.replay_window | default("not_defined") }}
    ...    {{ ft_yaml.ipsec.replay_window_variable | default("not_defined") }}
    ...    msg=ipsec.replay_window

{% endfor %}

{% endif %}
