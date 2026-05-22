*** Settings ***
Documentation    Verify Policers List
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.policers is defined %}

*** Test Cases ***
Get Policers List
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/policer
    Set Suite Variable    ${r}

{% for policer in sdwan.policy_objects.policers | default([]) %}

Verify Policy Objects Policer list {{ policer.name }}
    ${policer_id}=    Json Search String    ${r.json()}    data[?name=='{{policer.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/policer/${policer_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ policer.name }}    msg=policer name
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].burst    {{ policer.burst_bytes }}    msg=policer burst bytes
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].exceed    {{ policer.exceed_action }}    msg=policer exceed action
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].rate    {{ policer.rate_bps }}    msg=policer rate bps

{% endfor %}

{% endif %}
