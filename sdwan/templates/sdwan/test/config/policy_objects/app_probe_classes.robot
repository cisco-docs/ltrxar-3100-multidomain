*** Settings ***
Documentation    Verify App Probe Classes Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.app_probe_classes is defined %}

*** Test Cases ***
Get App Probe Classes List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/appprobe
    Set Suite Variable    ${r}

{% for app_probe_class in sdwan.policy_objects.app_probe_classes | default([]) %}

Verify Policy Objects App Probe Classes List {{ app_probe_class.name }}
    ${app_probe_class_id}=    Json Search String    ${r.json()}    data[?name=='{{app_probe_class.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/appprobe/${app_probe_class_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ app_probe_class.name }}    msg=app probe class name
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].forwardingClass    {{ app_probe_class.forwarding_class }}    msg=forwarding class
    ${app_data}=    Json Search List    ${r_id.json()}    entries[0].map
    ${app_len}=    Get Length    ${app_data}
    Should Be Equal As Integers    ${app_len}    {{ app_probe_class.mappings | length }}    msg=app probe entries
{% for item in app_probe_class.mappings | default([]) %}
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].map[{{loop.index0}}].color    {{ item.color }}    msg=color
    Should Be Equal Value Json String    ${r_id.json()}    entries[0].map[{{loop.index0}}].dscp    {{ item.dscp }}    msg=dscp
{% endfor %}

{% endfor %}

{% endif %}
