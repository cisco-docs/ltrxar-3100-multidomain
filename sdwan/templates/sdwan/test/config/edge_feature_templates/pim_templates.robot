*** Settings ***
Documentation   Verify PIM Feature Templates
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates.pim_templates is defined %}

*** Test Cases ***
Get PIM Feature Templates
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature
    ${r}=    Json Search List    ${r.json()}    data[?templateType=='cedge_pim']
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.pim_templates | default([]) %}

Verify Edge Feature Template PIM Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Json Search    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0]
    Run Keyword If    $ft_summary_json is None    Fail    Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.pim_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Json Search List    ${ft_summary_json}    deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Json Search String    ${r}    [?templateName=='{{ ft_yaml.name }}'] | [0].templateId
    ${ft}=    GET On Session With Retry    sdwan_manager    /dataservice/template/feature/definition/${ft_id}

    # SSM Fields
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim.ssm.default
    ...    {{ ft_yaml.ssm_default | default("not_defined") }}
    ...    {{ ft_yaml.ssm_default_variable | default("not_defined") }}
    ...    msg=ssm_default

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim.ssm.range
    ...    {{ ft_yaml.ssm_access_list_range | default("not_defined") }}
    ...    {{ ft_yaml.ssm_access_list_range_variable | default("not_defined") }}
    ...    msg=ssm_access_list_range

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."auto-rp"
    ...    {{ ft_yaml.auto_rp | default("not_defined") }}
    ...    {{ ft_yaml.auto_rp_variable | default("not_defined") }}
    ...    msg=auto_rp

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."spt-threshold"
    ...    {{ ft_yaml.spt_threshold | default("not_defined") }}
    ...    {{ ft_yaml.spt_threshold_variable | default("not_defined") }}
    ...    msg=spt_threshold

    # RP Announce
    Should Be Equal Value Json List Length    ${ft.json()}    pim."send-rp-announce"."send-rp-announce-list".vipValue    {{ ft_yaml.rp_announces | default([]) | length }}    msg=rp_announces length

    {% for rp_announce in ft_yaml.rp_announces | default([]) %}
    Log    === RP Announce {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."send-rp-announce"."send-rp-announce-list".vipValue[{{ loop.index0 }}]."if-name"
    ...    {{ rp_announce.interface_name | default("not_defined") }}
    ...    {{ rp_announce.interface_name_variable | default("not_defined") }}
    ...    msg=rp_announces.interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."send-rp-announce"."send-rp-announce-list".vipValue[{{ loop.index0 }}].scope
    ...    {{ rp_announce.scope | default("not_defined") }}
    ...    {{ rp_announce.scope_variable | default("not_defined") }}
    ...    msg=rp_announces.scope

    Should Be Equal Value Json String    ${ft.json()}    pim."send-rp-announce"."send-rp-announce-list".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ rp_announce.optional | default("not_defined") }}
    ...    msg=rp_announces.optional

    {% endfor %}

    # RP Discovery
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."send-rp-discovery"."if-name"
    ...    {{ ft_yaml.rp_discovery_interface | default("not_defined") }}
    ...    {{ ft_yaml.rp_discovery_interface_variable | default("not_defined") }}
    ...    msg=rp_discovery_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."send-rp-discovery".scope
    ...    {{ ft_yaml.rp_discovery_scope | default("not_defined") }}
    ...    {{ ft_yaml.rp_discovery_scope_variable | default("not_defined") }}
    ...    msg=rp_discovery_scope

    # RP Address
    Should Be Equal Value Json List Length    ${ft.json()}    pim."rp-addr".vipValue    {{ ft_yaml.rp_addresses | default([]) | length }}    msg=rp_addresses length

    {% for rp_address in ft_yaml.rp_addresses | default([]) %}
    Log    === RP Address {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-addr".vipValue[{{ loop.index0 }}].address
    ...    {{ rp_address.ip_address | default("not_defined") }}
    ...    {{ rp_address.ip_address_variable | default("not_defined") }}
    ...    msg=rp_addresses.ip_address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-addr".vipValue[{{ loop.index0 }}]."access-list"
    ...    {{ rp_address.access_list | default("not_defined") }}
    ...    {{ rp_address.access_list_variable | default("not_defined") }}
    ...    msg=rp_addresses.access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-addr".vipValue[{{ loop.index0 }}].override
    ...    {{ rp_address.override | default("not_defined") }}
    ...    {{ rp_address.override_variable | default("not_defined") }}
    ...    msg=rp_addresses.override

    Should Be Equal Value Json String    ${ft.json()}    pim."rp-addr".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ rp_address.optional | default("not_defined") }}
    ...    msg=rp_addresses.optional

    {% endfor %}

    # RP Candidate
    Should Be Equal Value Json List Length    ${ft.json()}    pim."rp-candidate".vipValue    {{ ft_yaml.rp_candidates | default([]) | length }}    msg=rp_candidates length

    {% for rp_candidate in ft_yaml.rp_candidates | default([]) %}
    Log    === RP Candidate {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-candidate".vipValue[{{ loop.index0 }}]."pim-interface-name"
    ...    {{ rp_candidate.interface_name | default("not_defined") }}
    ...    {{ rp_candidate.interface_name_variable | default("not_defined") }}
    ...    msg=rp_candidates.interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-candidate".vipValue[{{ loop.index0 }}]."group-list"
    ...    {{ rp_candidate.access_list | default("not_defined") }}
    ...    {{ rp_candidate.access_list_variable | default("not_defined") }}
    ...    msg=rp_candidates.access_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-candidate".vipValue[{{ loop.index0 }}].interval
    ...    {{ rp_candidate.interval | default("not_defined") }}
    ...    {{ rp_candidate.interval_variable | default("not_defined") }}
    ...    msg=rp_candidates.interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."rp-candidate".vipValue[{{ loop.index0 }}].priority
    ...    {{ rp_candidate.priority | default("not_defined") }}
    ...    {{ rp_candidate.priority_variable | default("not_defined") }}
    ...    msg=rp_candidates.priority

    Should Be Equal Value Json String    ${ft.json()}    pim."rp-candidate".vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ rp_candidate.optional | default("not_defined") }}
    ...    msg=rp_candidates.optional

    {% endfor %}

    # BSR Candidate
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."bsr-candidate"."bsr-interface-name"
    ...    {{ ft_yaml.bsr_candidate_interface | default("not_defined") }}
    ...    {{ ft_yaml.bsr_candidate_interface_variable | default("not_defined") }}
    ...    msg=bsr_candidate_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."bsr-candidate".mask
    ...    {{ ft_yaml.bsr_candidate_hash_mask_length | default("not_defined") }}
    ...    {{ ft_yaml.bsr_candidate_hash_mask_length_variable | default("not_defined") }}
    ...    msg=bsr_candidate_hash_mask_length

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."bsr-candidate".priority
    ...    {{ ft_yaml.bsr_candidate_priority | default("not_defined") }}
    ...    {{ ft_yaml.bsr_candidate_priority_variable | default("not_defined") }}
    ...    msg=bsr_candidate_priority

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim."bsr-candidate"."accept-rp-candidate"
    ...    {{ ft_yaml.bsr_candidate_rp_access_list | default("not_defined") }}
    ...    {{ ft_yaml.bsr_candidate_rp_access_list_variable | default("not_defined") }}
    ...    msg=bsr_candidate_rp_access_list

    # Interfaces
    Should Be Equal Value Json List Length    ${ft.json()}    pim.interface.vipValue    {{ ft_yaml.interfaces | default([]) | length }}    msg=interfaces length

    {% for interface in ft_yaml.interfaces | default([]) %}
    Log    === Interface {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim.interface.vipValue[{{ loop.index0 }}].name
    ...    {{ interface.interface_name | default("not_defined") }}
    ...    {{ interface.interface_name_variable | default("not_defined") }}
    ...    msg=interfaces.interface_name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim.interface.vipValue[{{ loop.index0 }}]."join-prune-interval"
    ...    {{ interface.join_prune_interval | default("not_defined") }}
    ...    {{ interface.join_prune_interval_variable | default("not_defined") }}
    ...    msg=interfaces.join_prune_interval

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    pim.interface.vipValue[{{ loop.index0 }}]."query-interval"
    ...    {{ interface.query_interval | default("not_defined") }}
    ...    {{ interface.query_interval_variable | default("not_defined") }}
    ...    msg=interfaces.query_interval

    Should Be Equal Value Json String    ${ft.json()}    pim.interface.vipValue[{{ loop.index0 }}].vipOptional
    ...    {{ interface.optional | default("not_defined") }}
    ...    msg=interfaces.optional

    {% endfor %}
{% endfor %}
{% endif %}
