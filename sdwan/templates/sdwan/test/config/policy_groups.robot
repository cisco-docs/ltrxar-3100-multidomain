*** Settings ***
Documentation   Verify Policy Group Configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    policy_groups
Resource        ../sdwan_common.resource

{% if sdwan.policy_groups is defined %}

*** Test Cases ***
Get Policy Groups
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/policy-group
    Set Suite Variable    ${r}

{% for policy_group in sdwan.policy_groups | default([]) %}

Verify Policy Group {{ policy_group.name }}
    ${pol}=    Json Search    ${r.json()}    [?name=='{{ policy_group.name }}'] | [0]
    Run Keyword If    $pol is None    Fail    Policy Group '{{ policy_group.name }}' should be present on the Manager
    ${pol_id}=    Json Search String    ${pol}    id

    Should Be Equal Value Json String    ${pol}    name    {{ policy_group.name }}    msg=name
    Should Be Equal Value Json Special_String    ${pol}    description    {{ policy_group.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json String    ${pol}    profiles[?type=='application-priority'] | [0].name    {{ policy_group.application_priority | default('not_defined') }}    msg=application_priority

{% endfor %}

{% endif %}
