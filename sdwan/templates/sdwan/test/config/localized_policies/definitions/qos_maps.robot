*** Settings ***
Documentation   Verify QoS Map
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    localized_policies
Resource        ../../../sdwan_common.resource

{% if sdwan.localized_policies is defined and sdwan.localized_policies.definitions is defined and sdwan.localized_policies.definitions.qos_maps is defined %}

*** Test Cases ***
Get QoS Map
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/qosmap
    Set Suite Variable    ${r}

{% for qos_map in sdwan.localized_policies.definitions.qos_maps | default([]) %}

Verify Localized Policies QoS Map {{ qos_map.name }}
    ${def_id}=    Json Search String    ${r.json()}    data[?name=='{{qos_map.name }}'] | [0].definitionId
    Run Keyword If    $def_id == ''    Fail    QoS Map '{{qos_map.name}}' not found
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/qosmap/${def_id}

    Should Be Equal Value Json String    ${r_id.json()}    name    {{ qos_map.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ qos_map.description | normalize_special_string }}    msg=description

    Should Be Equal Value Json List Length    ${r_id.json()}    definition.qosSchedulers    {{ qos_map.qos_schedulers | length }}    msg=qos schedulers

{% for qos in qos_map.qos_schedulers | default([]) %}

    ${qos_scheduler}=    Json Search    ${r_id.json()}    definition.qosSchedulers[?queue=='{{ qos.queue }}'] | [0]
    Run Keyword If    $qos_scheduler is None    Fail    QoS Map {{ qos_map.name }} scheduler for queue {{ qos.queue }} should be present on the Manager

    Should Be Equal Value Json String    ${qos_scheduler}    queue    {{ qos.queue }}    msg=queue

    ${qos_class_id}=    Json Search String    ${qos_scheduler}    classMapRef
    IF    $qos_class_id == '' or $qos_class_id == ''
        Should Be Equal Value Json Special_String    ${qos_scheduler}    classMapRef    {{ qos.get("class_map", "not_defined") }}    msg=class map
    ELSE
        ${qos_class_details}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/class/${qos_class_id}
        Should Be Equal Value Json String    ${qos_class_details.json()}    name    {{ qos.get("class_map", "not_defined") }}    msg=class map
    END

    Should Be Equal Value Json String    ${qos_scheduler}    bandwidthPercent    {{ qos.bandwidth_percent }}    msg=bandwidth percent
    Should Be Equal Value Json String    ${qos_scheduler}    bufferPercent    {{ qos.buffer_percent }}    msg=buffer percent
    Should Be Equal Value Json String    ${qos_scheduler}    burst    {{ qos.burst_bytes | default("not_defined") }}    msg=burst bytes
    Should Be Equal Value Json String    ${qos_scheduler}    scheduling    {{ qos.scheduling_type }}    msg=scheduling type
    Should Be Equal Value Json String    ${qos_scheduler}    drops    {{ qos.drop_type }}    msg=drop type

{% endfor %}

{% endfor %}

{% endif %}
