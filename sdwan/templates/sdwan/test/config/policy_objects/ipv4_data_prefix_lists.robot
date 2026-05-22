*** Settings ***
Documentation    Verify IPv4 Data Prefix Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.ipv4_data_prefix_lists is defined %}

*** Test Cases ***
Get IPv4 Data Prefix List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataprefix
    Set Suite Variable    ${r}

{% for ipv4_data_prefix in sdwan.policy_objects.ipv4_data_prefix_lists | default([]) %}

Verify Policy Objects IPv4 Data Prefix List {{ ipv4_data_prefix.name }}
    ${ipv4_data_prefix_id}=    Json Search String    ${r.json()}    data[?name=='{{ipv4_data_prefix.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataprefix/${ipv4_data_prefix_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ ipv4_data_prefix.name }}
    ${ip_prefix_list}=    Create List    {{ ipv4_data_prefix.prefixes | join('   ') }}
    Should Be Equal Value Json List    ${r_id.json()}    entries[].ipPrefix    ${ip_prefix_list}    msg=ip prefix

{% endfor %}

{% endif %}
