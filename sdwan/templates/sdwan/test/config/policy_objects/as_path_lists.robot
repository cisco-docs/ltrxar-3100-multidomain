*** Settings ***
Documentation    Verify As Path Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.as_path_lists is defined %}

*** Test Cases ***
Get As Path List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/aspath
    Set Suite Variable    ${r}

{% for as_path_list in sdwan.policy_objects.as_path_lists | default([]) %}

Verify Policy Objects As Path List {{ as_path_list.name }}
    ${as_path_list_id}=    Json Search String    ${r.json()}    data[?name=='{{as_path_list.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/aspath/${as_path_list_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ as_path_list.name }}    msg=as path name
    ${aspath_list}=    Create List    {{ as_path_list.as_paths | join('   ') }}
    Should Be Equal Value Json List    ${r_id.json()}    entries[].asPath    ${aspath_list}    msg=as path lists

{% endfor %}

{% endif %}
