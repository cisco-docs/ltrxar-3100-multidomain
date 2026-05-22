*** Settings ***
Documentation   Verify IPv6 Access Control Lists
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    localized_policies
Resource        ../../../sdwan_common.resource

{% if sdwan.localized_policies is defined and sdwan.localized_policies.definitions is defined and sdwan.localized_policies.definitions.ipv6_access_control_lists is defined %}

*** Test Cases ***
Get IPv6 Access Control Lists
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/aclv6
    Set Suite Variable    ${r}

{% for ipv6_acl in sdwan.localized_policies.definitions.ipv6_access_control_lists | default([]) %}

Verify Localized Policies IPv6 Access Control Lists {{ ipv6_acl.name }}
    ${ipv6_acl_id}=   Json Search String   ${r.json()}   data[?name=='{{ ipv6_acl.name }}'] | [0].definitionId
    Run Keyword If    $ipv6_acl_id == ''    Fail    IPv6 ACL '{{ ipv6_acl.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/aclv6/${ipv6_acl_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ ipv6_acl.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ ipv6_acl.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    defaultAction.type    {{ ipv6_acl.default_action }}    msg=default action type

    Should Be Equal Value Json List Length    ${r_id.json()}    sequences    {{ ipv6_acl.sequences | default([]) | length }}    msg=sequences

{% for sequence in ipv6_acl.sequences | default([]) %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceId    {{ sequence.id }}    msg=id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceName    {{ sequence.name | default("Access Control List") }}    msg=name
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].baseAction    {{ sequence.base_action }}    msg=base action

    ${class_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='class'] | [0].ref
    IF    $class_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='class'] | [0].ref    {{ sequence.match_criterias.class | default("not_defined") }}    msg=class
    ELSE
        ${class_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/class/${class_id}
        Should Be Equal Value Json String    ${class_match_id.json()}    name    {{ sequence.match_criterias.class | default("not_defined") }}    msg=class
    END

    ${ddpl_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationDataIpv6PrefixList'] | [0].ref
    IF    $ddpl_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationDataIpv6PrefixList'] | [0].ref    {{ sequence.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    ELSE
        ${ddpl_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/dataipv6prefix/${ddpl_id}
        Should Be Equal Value Json String    ${ddpl_match_id.json()}    name    {{ sequence.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationIpv6'] | [0].value    {{ sequence.match_criterias.destination_ip_prefix | default("not_defined") }}    msg=destination ip prefix

{% set destination_port_range_list = [] %}
{% for item in sequence.match_criterias.destination_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.from) %}
{% set _ = test_list.append(item.to) %}
{% set destination_port_range_test = '-'.join(test_list | map('string')) %}
{% set _ = destination_port_range_list.append(destination_port_range_test) %}
{% endfor %}

{% if sequence.match_criterias.destination_ports is defined and sequence.match_criterias.destination_port_ranges is defined%}
{% set req_destination_port = sequence.match_criterias.destination_ports  %}
{% set destination_string = req_destination_port | map('string') | join(',') %}
{% set new_dest_port_list = destination_string.split(',') %}
{% set destination_list = new_dest_port_list + destination_port_range_list %}
    ${list}=   Create List   {{ destination_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports and ranges
{% elif sequence.match_criterias.destination_ports is defined %}
    ${list}=   Create List   {{ sequence.match_criterias.destination_ports | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports
{% elif sequence.match_criterias.destination_port_ranges is defined %}
    ${list} =   Create List   {{ destination_port_range_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports ranges
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='nextHeader'] | [0].value    {{ sequence.match_criterias.next_header | default("not_defined") }}    msg=next header
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='packetLength'] | [0].value    {{ sequence.match_criterias.packet_length | default("not_defined") }}    msg=packet length
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='plp'] | [0].value    {{ sequence.match_criterias.priority | default("not_defined") }}    msg=priority

    ${sdpl_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceDataIpv6PrefixList'] | [0].ref
    IF    $sdpl_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceDataIpv6PrefixList'] | [0].ref    {{ sequence.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    ELSE
        ${sdpl_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/dataipv6prefix/${sdpl_id}
        Should Be Equal Value Json String    ${sdpl_match_id.json()}    name    {{ sequence.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceIpv6'] | [0].value    {{ sequence.match_criterias.source_ip_prefix | default("not_defined") }}    msg=source ip prefix

{% set source_port_range_list = [] %}
{% for item in sequence.match_criterias.source_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.from) %}
{% set _ = test_list.append(item.to) %}
{% set source_port_range_test = '-'.join(test_list | map('string')) %}
{% set _ = source_port_range_list.append(source_port_range_test) %}
{% endfor %}

{% if sequence.match_criterias.source_ports is defined and sequence.match_criterias.source_port_ranges is defined%}
{% set req_source_port = sequence.match_criterias.source_ports  %}
{% set source_string = req_source_port | map('string') | join(',') %}
{% set new_source_port_list = source_string.split(',') %}
{% set source_list = new_source_port_list + source_port_range_list %}
    ${list}=   Create List   {{ source_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports and ranges
{% elif sequence.match_criterias.source_ports is defined %}
    ${list}=   Create List   {{ sequence.match_criterias.source_ports | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports
{% elif sequence.match_criterias.source_port_ranges is defined %}
    ${list} =   Create List   {{ source_port_range_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports ranges
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tcp'] | [0].value    {{ sequence.match_criterias.tcp | default("not_defined") }}    msg=tcp
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='trafficClass'] | [0].value    {{ sequence.match_criterias.traffic_class | default("not_defined") }}    msg=traffic class

    ${class_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='class'] | [0].parameter.ref
    IF    $class_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='class'] | [0].parameter.ref    {{ sequence.actions.class | default("not_defined") }}    msg=class
    ELSE
        ${class_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/class/${class_id}
        Should Be Equal Value Json String    ${class_match_id.json()}    name    {{ sequence.actions.class | default("not_defined") }}    msg=class
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='count'] | [0].parameter    {{ sequence.actions.counter_name | default("not_defined") }}    msg=counter name

{% if sequence.actions.log is defined and sequence.actions.log == True | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     log    msg=log is activated
{% elif sequence.actions.log is not defined or sequence.actions.log == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     not_defined    msg=log is not defined or value is false
{% endif %}

    ${mirror_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='mirror'] | [0].parameter.ref
    IF    $mirror_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='mirror'] | [0].parameter.ref    {{ sequence.actions.mirror_list | default("not_defined") }}    msg=mirror list
    ELSE
        ${match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/mirror/${mirror_list_id}
        Should Be Equal Value Json String    ${match_id.json()}    name    {{ sequence.actions.mirror_list | default("not_defined") }}    msg=mirror list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHop'] | [0].value    {{ sequence.actions.next_hop | default("not_defined") }}    msg=nextHop

    ${policer_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='policer'] | [0].parameter.ref
    IF    $policer_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='policer'] | [0].parameter.ref    {{ sequence.actions.policer | default("not_defined") }}    msg=policer
    ELSE
        ${match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/policer/${policer_id}
        Should Be Equal Value Json String    ${match_id.json()}    name    {{ sequence.actions.policer | default("not_defined") }}    msg=policer
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='trafficClass'] | [0].value    {{ sequence.actions.traffic_class | default("not_defined") }}    msg=traffic class

{% endfor %}

{% endfor %}

{% endif %}
