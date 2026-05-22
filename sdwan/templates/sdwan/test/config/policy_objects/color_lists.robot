*** Settings ***
Documentation    Verify Color Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.color_lists is defined %}

*** Test Cases ***
Get Color List(s)
   ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/color
   Set Suite Variable   ${r}

{% for obj_name in sdwan.policy_objects.color_lists | default([]) %}

Verify Policy Objects Color List {{ obj_name.name }}
    ${color_obj_id}=    Json Search String    ${r.json()}    data[?name=='{{ obj_name.name }}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/color/${color_obj_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ obj_name.name }}
    ${req_color_list}=    Create List    {{ obj_name.colors | join('   ') }}
    ${color_entries}=    Json Search List    ${r_id.json()}    entries[].color
    Should Be Equal Value Json List    ${r_id.json()}    entries[].color    ${req_color_list}    msg=colors are

{% endfor %}
{% endif %}
