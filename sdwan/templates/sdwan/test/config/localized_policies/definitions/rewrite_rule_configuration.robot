*** Settings ***
Documentation   Verify Rewrite Rule Configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    localized_policies
Resource        ../../../sdwan_common.resource

{% if sdwan.localized_policies is defined and sdwan.localized_policies.definitions is defined and sdwan.localized_policies.definitions.rewrite_rules is defined %}

*** Test Cases ***
Get Rewrite Rule Configurations
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/rewriterule
    Set Suite Variable    ${r}

{% for rewrite_rule in sdwan.localized_policies.definitions.rewrite_rules | default([]) %}

Verify Rewrite Rule Configuration {{ rewrite_rule.name }}
    ${rewrite_rule_id}=   Json Search String   ${r.json()}   data[?name=='{{ rewrite_rule.name }}'] | [0].definitionId
    Run Keyword If    $rewrite_rule_id == ''    Fail    Rewrite Rule '{{ rewrite_rule.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/rewriterule/${rewrite_rule_id}

    Should Be Equal Value Json String    ${r_id.json()}    name    {{ rewrite_rule.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ rewrite_rule.description | normalize_special_string }}    msg=description

    Should Be Equal Value Json List Length   ${r_id.json()}    definition.rules    {{ rewrite_rule.rules | length }}    msg=rewrite rule length

{% for rule in rewrite_rule.rules | default([]) %}
    ${rule_class_id}=   Json Search String   ${r_id.json()}   definition.rules[{{loop.index0}}].class
    ${class_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/class/${rule_class_id}
    Should Be Equal Value Json String    ${class_id.json()}    name    {{ rule.class }}    msg=rule class
    Should Be Equal Value Json String    ${r_id.json()}    definition.rules[{{loop.index0}}].dscp    {{ rule.dscp }}    msg=rule dscp
    Should Be Equal Value Json String    ${r_id.json()}    definition.rules[{{loop.index0}}].layer2Cos    {{ rule.layer2_cos | default("not_defined") }}    msg=layer2 cos
    Should Be Equal Value Json String    ${r_id.json()}    definition.rules[{{loop.index0}}].plp    {{ rule.priority }}    msg=rule priority
{% endfor %}

{% endfor %}

{% endif %}
