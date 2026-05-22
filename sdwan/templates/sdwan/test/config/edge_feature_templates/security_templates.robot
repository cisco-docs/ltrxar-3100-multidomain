*** Settings ***
Documentation   Verify Security Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.security_templates is defined %}

*** Test Cases ***
Get Security Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cisco_security']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.security_templates | default([]) %}

Verify Edge Feature Template Security Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.security_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    # Custom handling of authentication types that require mapping
    Should Be Equal Value Json List Length    ${ft.json()}    ipsec."authentication-type".vipValue    {{ ft_yaml.authentication_types | default([]) | length }}    msg=authentication types length

    {% set lookup_auth_type = ({"esp":"sha1-hmac", "ip-udp-esp":"ah-sha1-hmac", "ip-udp-esp-no-id":"ah-no-id", "none":"none"}) %}
    {% set auth_type_list_local = [] %}
    {% for item in ft_yaml.authentication_types | default([]) %}
        {% set _ = auth_type_list_local.append(lookup_auth_type.get(item, "not_defined")) %}
    {% endfor %}
    ${auth_type_list_local}=   Create List   {{ auth_type_list_local | join('   ') }}
    ${auth_type_list_remote}=    Json Search List    ${ft.json()}    ipsec."authentication-type".vipValue
    ${not_defined_list}=    Create List
    ${auth_type_list_remote}=    Set Variable If    ${auth_type_list_remote} == []    ${not_defined_list}    ${auth_type_list_remote}
    Lists Should Be Equal    ${auth_type_list_remote}    ${auth_type_list_local}    ignore_order=True    msg=authentication types
    Should Be Equal Value Json String    ${ft.json()}    ipsec."authentication-type".vipVariableName    {{ ft_yaml.authentication_types_variable | default("not_defined") }}    msg=authentication types variable
    # End of custom handling

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."extended-ar-window"
    ...    {{ ft_yaml.extended_anti_replay_window | default("not_defined") }}
    ...    {{ ft_yaml.extended_anti_replay_window_variable | default("not_defined") }}
    ...    msg=extended_anti_replay_window

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."pairwise-keying"
    ...    {{ ft_yaml.pairwise_keying | default("not_defined") | lower }}
    ...    {{ ft_yaml.pairwise_keying_variable | default("not_defined") }}
    ...    msg=pairwise_keying

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec.rekey
    ...    {{ ft_yaml.rekey_interval | default("not_defined") }}
    ...    {{ ft_yaml.rekey_interval_variable | default("not_defined") }}
    ...    msg=rekey_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    ipsec."replay-window"
    ...    {{ ft_yaml.replay_window | default("not_defined") }}
    ...    {{ ft_yaml.replay_window_variable | default("not_defined") }}
    ...    msg=replay_window

    Should Be Equal Value Json List Length    ${ft.json()}    trustsec.keychain.vipValue    {{ ft_yaml.key_chains | default([]) | length }}    msg=key_chains length

{% for key_chain in ft_yaml.key_chains | default([]) %}

    Log    === Key Chain {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.keychain.vipValue[{{loop.index0}}].name
    ...    {{ key_chain.name | default("not_defined") }}
    ...    {{ key_chain.name_variable | default("not_defined") }}
    ...    msg=key_chains.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    trustsec.keychain.vipValue[{{loop.index0}}].keyid
    ...    {{ key_chain.key_id | default("not_defined") }}
    ...    {{ key_chain.key_id_variable | default("not_defined") }}
    ...    msg=key_chains.key_id

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    key.vipValue    {{ ft_yaml.get('keys', []) | length }}    msg=keys length

{% for security_key in ft_yaml.get('keys', []) %}

    Log    === Security Key {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-ao-mismatch"
    ...    {{ security_key.accept_ao_mismatch | default("not_defined") | lower }}
    ...    {{ security_key.accept_ao_mismatch_variable | default("not_defined") }}
    ...    msg=keys.accept_ao_mismatch

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-lifetime"."lifetime-group-v1".local
    ...    {{ security_key.accept_lifetime | default("not_defined") | lower }}
    ...    {{ security_key.accept_lifetime_variable | default("not_defined") }}
    ...    msg=keys.accept_lifetime

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-lifetime"."lifetime-group-v1".duration
    ...    {{ security_key.accept_lifetime_duration_seconds | default("not_defined") }}
    ...    {{ security_key.accept_lifetime_duration_variable | default("not_defined") }}
    ...    msg=keys.accept_lifetime_duration_seconds

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-lifetime"."lifetime-group-v1"."end-epoch"
    ...    {{ security_key.accept_lifetime_end_time_epoch | default("not_defined") }}
    ...    {{ security_key.accept_lifetime_end_time_epoch_variable | default("not_defined") }}
    ...    msg=keys.accept_lifetime_end_time_epoch

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-lifetime"."lifetime-group-v1"."end-choice"
    ...    {{ security_key.accept_lifetime_end_time_format | default("not_defined") }}
    ...    {{ security_key.accept_lifetime_end_time_format_variable | default("not_defined") }}
    ...    msg=keys.accept_lifetime_end_time_format

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."accept-lifetime"."lifetime-group-v1"."start-epoch"
    ...    {{ security_key.accept_lifetime_start_time_epoch | default("not_defined") }}
    ...    {{ security_key.accept_lifetime_start_time_epoch_variable | default("not_defined") }}
    ...    msg=keys.accept_lifetime_start_time_epoch

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."cryptographic-algorithm-choice".tcp
    ...    {{ security_key.crypto_algorithm | default("not_defined") }}
    ...    {{ security_key.crypto_algorithm_variable | default("not_defined") }}
    ...    msg=keys.crypto_algorithm

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}].id
    ...    {{ security_key.id | default("not_defined") }}
    ...    {{ security_key.id_variable | default("not_defined") }}
    ...    msg=keys.id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."include-tcp-options"
    ...    {{ security_key.include_tcp_options | default("not_defined") | lower }}
    ...    {{ security_key.include_tcp_options_variable | default("not_defined") }}
    ...    msg=keys.include_tcp_options

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."chain-name"
    ...    {{ security_key.key_chain_name | default("not_defined") }}
    ...    {{ security_key.key_chain_name_variable | default("not_defined") }}
    ...    msg=keys.key_chain_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."key-string"
    ...    {{ security_key.key_string | default("not_defined") }}
    ...    {{ security_key.key_string_variable | default("not_defined") }}
    ...    msg=keys.key_string

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-id"
    ...    {{ security_key.send_id | default("not_defined") }}
    ...    {{ security_key.send_id_variable | default("not_defined") }}
    ...    msg=keys.send_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-lifetime"."lifetime-group-v1".local
    ...    {{ security_key.send_lifetime | default("not_defined") | lower }}
    ...    {{ security_key.send_lifetime_variable | default("not_defined") }}
    ...    msg=keys.send_lifetime

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-lifetime"."lifetime-group-v1".duration
    ...    {{ security_key.send_lifetime_duration_seconds | default("not_defined") }}
    ...    {{ security_key.send_lifetime_duration_variable | default("not_defined") }}
    ...    msg=keys.send_lifetime_duration_seconds

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-lifetime"."lifetime-group-v1"."end-epoch"
    ...    {{ security_key.send_lifetime_end_time_epoch | default("not_defined") }}
    ...    {{ security_key.send_lifetime_end_time_epoch_variable | default("not_defined") }}
    ...    msg=keys.send_lifetime_end_time_epoch

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-lifetime"."lifetime-group-v1"."end-choice"
    ...    {{ security_key.send_lifetime_end_time_format | default("not_defined") }}
    ...    {{ security_key.send_lifetime_end_time_format_variable | default("not_defined") }}
    ...    msg=keys.send_lifetime_end_time_format

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."send-lifetime"."lifetime-group-v1"."start-epoch"
    ...    {{ security_key.send_lifetime_start_time_epoch | default("not_defined") }}
    ...    {{ security_key.send_lifetime_start_time_epoch_variable | default("not_defined") }}
    ...    msg=keys.send_lifetime_start_time_epoch

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    key.vipValue[{{loop.index0}}]."recv-id"
    ...    {{ security_key.receive_id | default("not_defined") }}
    ...    {{ security_key.receive_id_variable | default("not_defined") }}
    ...    msg=keys.receive_id

{% endfor %}

{% endfor %}

{% endif %}
