*** Settings ***
Documentation    Verify Port Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects.port_lists is defined %}

*** Test cases ***
Get Port Lists(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/port
    Log   ${r}
    Set Suite Variable   ${r}

Check Number of Port Lists Entries(s)
    ${yaml_port_lists}=    Create List    {{ sdwan.policy_objects.port_lists | default([]) | join('   ') }}
    ${yaml_port_lists_length}=    Get Length    ${yaml_port_lists}
    ${actual_port_lists}=    Json Search List    ${r.json()}    data
    Length Should Be    ${actual_port_lists}    ${yaml_port_lists_length}    msg=Number_of_port_lists_mismatch

{% for port_list in sdwan.policy_objects.port_lists | default([]) %}

Verify Port List Values {{port_list.name}}
    ${Actual_plist_values}=    Json Search List    ${r.json()}    data[?name=='{{port_list.name}}'].entries[].port
    ${yaml_plist_values}=    Create List    {{ port_list.ports | default([]) | join('   ') }}
    Log    ${yaml_plist_values}
    Lists Should Be Equal    ${yaml_plist_values}    ${Actual_plist_values}

{% endfor %}

{% endif %}
