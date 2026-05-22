*** Settings ***
Documentation    Verify IPv6 Data Prefix List Configuration
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.ipv6_data_prefix_lists is defined %}

*** Test Cases ***
Get IPv6 Data Prefix List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataipv6prefix
    Set Suite Variable    ${r}

{% for prefix in sdwan.policy_objects.ipv6_data_prefix_lists | default([]) %}

Verify Policy Objects IPv6 Data Prefix List {{ prefix.name }}
    ${ipv6_data_prefix_id}=    Json Search String    ${r.json()}    data[?name=='{{prefix.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataipv6prefix/${ipv6_data_prefix_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ prefix.name }}
    ${ipv6_list}=    Create List    {{ prefix.prefixes | join('   ') }}
    Should Be Equal Value Json List    ${r_id.json()}    entries[].ipv6Prefix    ${ipv6_list}    msg=ipv6 data prefix list is

{% endfor %}

{% endif %}
