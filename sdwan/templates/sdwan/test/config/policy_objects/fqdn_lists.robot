*** Settings ***
Documentation    Verify FQDN Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.fqdn_lists is defined %}

*** Test cases ***
Get fqdn lists
    ${r}=   GET On Session With Retry   sdwan_manager   dataservice/template/policy/list/fqdn
    Log   ${r}
    Set Suite Variable   ${r}

{% for fqdns in sdwan.policy_objects.fqdn_lists | default([]) %}

Verify FQDN List(s) {{ fqdns.name }}
    ${fqdn_id}=    Json Search String    ${r.json()}    data[?name=='{{fqdns.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/fqdn/${fqdn_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ fqdns.name }}    msg=fqdn_list_name
    ${fqdn_list}=    Create List    {{ fqdns.fqdns | default([]) | join('   ') }}
    Should Be Equal Value Json List    ${r_id.json()}    entries[].pattern    ${fqdn_list}    msg=fqdn_list_entries
    
    

{% endfor %}

{% endif %}