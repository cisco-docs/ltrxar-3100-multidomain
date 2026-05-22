*** Settings ***
Documentation    Verify Expanded Community List Configuration
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.expanded_community_lists is defined %}

*** Test Cases ***
Get Expanded Community List(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/expandedcommunity
    Set Suite Variable    ${r}

{% for expanded_community in sdwan.policy_objects.expanded_community_lists | default([]) %}

Verify Policy Objects Expanded Community List {{ expanded_community.name }}
    ${expanded_community_id}=    Json Search String    ${r.json()}    data[?name=='{{expanded_community.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/expandedcommunity/${expanded_community_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ expanded_community.name }}    msg=expanded community
    ${com_list}=    Create List    {{ expanded_community.expanded_communities | join('   ') }}
    Should Be Equal Value Json List    ${r_id.json()}    entries[].community    ${com_list}    msg=expanded community list is

{% endfor %}

{% endif %}
