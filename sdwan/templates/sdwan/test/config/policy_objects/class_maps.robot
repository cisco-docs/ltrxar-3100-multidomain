*** Settings ***
Documentation    Verify Class Map Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.class_maps is defined %}

*** Test Cases ***
Get Class Map List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/class
    Set Suite Variable    ${r}

{% for class_map in sdwan.policy_objects.class_maps | default([]) %}

Verify Policy Objects Class Map List {{ class_map.name }}
    ${class_map_id}=    Json Search String    ${r.json()}    data[?name=='{{class_map.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/class/${class_map_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ class_map.name }}    msg=class map name
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].queue    {{ class_map.queue }}    msg=class map queue

{% endfor %}

{% endif %}
