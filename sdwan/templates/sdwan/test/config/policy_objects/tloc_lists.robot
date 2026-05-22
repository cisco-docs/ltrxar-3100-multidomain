*** Settings ***
Documentation    Verify TLOC Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.tloc_lists is defined %}

*** Test Cases ***
Get Tloc List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/tloc
    Set Suite Variable    ${r}

{% for tloc in sdwan.policy_objects.tloc_lists | default([]) %}

Verify Policy Objects Tloc List {{ tloc.name }}
    ${tloc_id}=    Json Search String    ${r.json()}    data[?name=='{{tloc.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/tloc/${tloc_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ tloc.name }}    msg=tloc name
    ${tloc_data}=    Json Search List    ${r_id.json()}    entries
    ${tloc_len}=    Get Length    ${tloc_data}
    Should Be Equal As Integers    ${tloc_len}    {{ tloc.tlocs | length }}    msg=tloc entries

{% for item in tloc.tlocs | default([]) %}
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].color    {{ item.color }}    msg=tloc color
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].tloc    {{ item.tloc_ip }}    msg=tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].encap    {{ item.encapsulation }}    msg=tloc encapsulation
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].preference    {{ item.preference | default("not_defined") }}    msg=tloc preference

{% endfor %}

{% endfor %}
{% endif %}
