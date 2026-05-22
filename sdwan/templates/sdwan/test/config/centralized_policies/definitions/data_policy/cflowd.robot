*** Settings ***
Documentation   Verify Cflowd Policy
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    data_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.data_policy.cflowd is defined %}

*** Test Cases ***
Get Cflowd Policy
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/cflowd
    Set Suite Variable    ${r}

{% for cflowd in sdwan.centralized_policies.definitions.data_policy.cflowd | default([]) %}

Verify Centralized Policies Data Policy Cflowd {{ cflowd.name }}
    ${cflowd_id}=    Json Search String    ${r.json()}    data[?name=='{{cflowd.name }}'] | [0].definitionId
    Run Keyword If    $cflowd_id == 'not_defined'    Fail    Cflowd Policy '{{cflowd.name}}' not found
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/cflowd/${cflowd_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ cflowd.name }}    msg=cflowd name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ cflowd.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    definition.flowActiveTimeout    {{ cflowd.active_flow_timeout | default("not_defined") }}    msg=cflowd active flow timeout
    Should Be Equal Value Json String    ${r_id.json()}    definition.flowInactiveTimeout    {{ cflowd.inactive_flow_timeout | default("not_defined") }}    msg=cflowd inactive flow timeout
    Should Be Equal Value Json String    ${r_id.json()}    definition.flowSamplingInterval    {{ cflowd.sampling_interval | default("not_defined") }}    msg=cflowd sampling interval
    Should Be Equal Value Json String    ${r_id.json()}    definition.templateRefresh    {{ cflowd.flow_refresh | default("not_defined") }}    msg=cflowd flow refresh
    Should Be Equal Value Json String    ${r_id.json()}    definition.protocol    {{ cflowd.protocol | default(defaults.sdwan.centralized_policies.definitions.data_policy.cflowd.protocol) | default("not_defined") }}    msg=cflowd protocol
    Should Be Equal Value Json String    ${r_id.json()}    definition.customizedIpv4RecordFields.collectTos    {{ cflowd.tos | default(defaults.sdwan.centralized_policies.definitions.data_policy.cflowd.tos) | default("not_defined") }}    msg=cflowd tos
    Should Be Equal Value Json String    ${r_id.json()}    definition.customizedIpv4RecordFields.collectDscpOutput    {{ cflowd.remarked_dscp | default(defaults.sdwan.centralized_policies.definitions.data_policy.cflowd.remarked_dscp) | default("not_defined") }}    msg=cflowd remarked dscp

{% for collector in cflowd.collectors | default([]) %}
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].vpn    {{ collector.vpn }}    msg=cflowd collector vpn
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].address    {{ collector.ip_address }}    msg=cflowd collector ip address
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].port    {{ collector.port }}    msg=cflowd collector port
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].transport    {{ collector.transport }}    msg=cflowd collector transport
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].sourceInterface    {{ collector.source_interface }}    msg=cflowd collector source interface
    Should Be Equal Value Json String    ${r_id.json()}    definition.collectors[{{loop.index0}}].exportSpread    {{ collector.export_spreading | default("not_defined") }}    msg=cflowd collector export spreading
{% endfor %}

{% endfor %}

{% endif %}
