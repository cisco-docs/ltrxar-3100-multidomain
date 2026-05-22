*** Settings ***
Documentation    Verify IPv4 Prefix Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.ipv4_prefix_lists is defined %}

*** Test Cases ***
Get IPv4 Prefix List(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/prefix
    Set Suite Variable   ${r}

{% for prefix in sdwan.policy_objects.ipv4_prefix_lists | default([]) %}

Verify Policy Objects IPv4 Prefix List {{ prefix.name }}
    ${ipv4_prefix_id}=    Json Search String    ${r.json()}    data[?name=='{{prefix.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/prefix/${ipv4_prefix_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ prefix.name }}
    ${ipv4_data}=    Json Search List    ${r_id.json()}    entries
    ${ipv4_len}=    Get Length    ${ipv4_data}
    Should Be Equal As Integers    ${ipv4_len}    {{ prefix.entries | length }}    msg=Ipv4 entries
{% for item in prefix.entries | default([]) %}
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].ipPrefix    {{ item.prefix }}    msg=prefix is
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].le    {{ item.le | default("not_defined") }}    msg=prefix le is
    Should Be Equal Value Json String    ${r_id.json()}    entries[{{loop.index0}}].ge    {{ item.ge | default("not_defined") }}    msg=prefix ge is
{% endfor %}

{% endfor %}

{% endif %}
