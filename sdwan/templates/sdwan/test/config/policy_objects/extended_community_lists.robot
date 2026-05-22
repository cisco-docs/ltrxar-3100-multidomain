*** Settings ***
Documentation    Verify Extended Community List Configuration
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.extended_community_lists is defined %}

*** Test Cases ***
Get Extended Community List(s)
   ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/extcommunity
   Set Suite Variable    ${r}

{% for extended_community in sdwan.policy_objects.extended_community_lists | default([]) %}

Verify Policy Objects Extended Community List {{ extended_community.name }}
   ${extended_community_id}=    Json Search String    ${r.json()}    data[?name=='{{extended_community.name}}'] | [0].listId
   ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/extcommunity/${extended_community_id}
   Should Be Equal Value Json String    ${r_id.json()}    name    {{ extended_community.name }}    msg=extended community
   ${com_list}=    Create List    {{ extended_community.extended_communities | join('   ') }}
   Should Be Equal Value Json List    ${r_id.json()}    entries[].community    ${com_list}    msg=extended community list is

{% endfor %}

{% endif %}
