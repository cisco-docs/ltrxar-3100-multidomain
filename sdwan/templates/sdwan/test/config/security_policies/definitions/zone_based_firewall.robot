*** Settings ***
Documentation    Verify Zone Based Firewall
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags     sdwan    config    security_policies
Resource         ../../../sdwan_common.resource

{% if sdwan.security_policies is defined and sdwan.security_policies.definitions is defined and sdwan.security_policies.definitions.zone_based_firewall is defined %}

*** Test Cases ***
Get Zone Based Firewall
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/zonebasedfw
    Set Suite Variable    ${r}

{% for zbf in sdwan.security_policies.definitions.zone_based_firewall | default([]) %}

Verify Security Policies Zone Based Firewall {{ zbf.name }}
    ${zbf_id}=   Json Search String   ${r.json()}   data[?name=='{{ zbf.name }}'] | [0].definitionId
    Run Keyword If    $zbf_id == ''    Fail    Zone Based Firewall Policy '{{ zbf.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/zonebasedfw/${zbf_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ zbf.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ zbf.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    definition.defaultAction.type    {{ zbf.default_action_type }}    msg=default action type

{% set rule_ids = [] %}
{% for rule in zbf.rules | default([]) %}
{% set _ = rule_ids.append(rule.id) %}
{% endfor %}

    ${r_rule_ids}=   Json Search List   ${r_id.json()}   definition.sequences[].sequenceId
    ${r_rule_ids_count}=    Get Length    ${r_rule_ids}
    Should Be Equal As Integers    ${r_rule_ids_count}    {{ rule_ids | length }}    msg=Expected {{ rule_ids | length }} but got ${r_rule_ids_count} rules in the zone based firewall
    
{% for rule in zbf.rules | default([]) %} 
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].sequenceId    {{ rule.id }}    msg= rule id
    Should Be Equal Value Json Special_String    ${r_id.json()}   definition.sequences[{{loop.index0}}].sequenceName  {{ rule.name | normalize_special_string }}    msg=rule name
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].baseAction    {{ rule.base_action }}    msg=base action
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceIp'] | [0].value    {{ rule.match_criterias.source_ip_prefix | default("not_defined") }}    msg=source ip prefix
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceFqdn'] | [0].value    {{ rule.match_criterias.source_fqdn | default("not_defined") }}    msg=source fqdn
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationIp'] | [0].value    {{ rule.match_criterias.destination_ip_prefix | default("not_defined") }}    msg=destination ip prefix
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationFqdn'] | [0].value    {{ rule.match_criterias.destination_fqdn | default("not_defined") }}    msg=destination fqdn
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceIp'] | [0].vipVariableName    {{ rule.match_criterias.source_ip_prefix_variable | default("not_defined") }}    msg=source ip prefix variable
    Should Be Equal Value Json String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationIp'] | [0].vipVariableName    {{ rule.match_criterias.destination_ip_prefix_variable | default("not_defined") }}    msg=destination ip prefix variable

{% if zbf.mode is not defined or zbf.mode == "security" %}
    ${app_list_id}=   Json Search String   ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='appList'] | [0].ref
    IF    $app_list_id == ''
       Should Be Equal Value Json String   ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='appList'] | [0].ref   {{ rule.match_criterias.local_application_list | default("not_defined") }}    msg=local application list
    ELSE
       ${r_app_list_id}=    GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/localapp/${app_list_id}
        Should Be Equal Value Json String    ${r_app_list_id.json()}   name   {{ rule.match_criterias.local_application_list | default("not_defined") }}    msg=local application list
    END
{% elif zbf.mode == "unified" %}
    ${app_list_id}=   Json Search String   ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='appListFlat'] | [0].ref
    IF    $app_list_id == ''
       Should Be Equal Value Json String   ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='appListFlat'] | [0].ref   {{ rule.match_criterias.local_application_list | default("not_defined") }}    msg=local application list
    ELSE
       ${r_app_list_id}=    GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/localapp/${app_list_id}
        Should Be Equal Value Json String    ${r_app_list_id.json()}   name   {{ rule.match_criterias.local_application_list | default("not_defined") }}    msg=local application list
    END
{% endif %}

{% if rule.actions is defined and rule.actions.log is defined and rule.actions.log == True %}
{% if (zbf.mode | default(defaults.sdwan.security_policies.definitions.zone_based_firewall.mode)) == "security" %}
    Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     log    msg= log
{% elif (zbf.mode | default(defaults.sdwan.security_policies.definitions.zone_based_firewall.mode)) == "unified" %}
    Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].actions[?type=='connectionEvents'] | [0].type     connectionEvents    msg= log
{% endif %}
{% elif rule.actions is defined and rule.actions.log is defined and rule.actions.log == False %}
    Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     false    msg= log
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     not_defined    msg= log
{% endif %}

    ${source_fqdn_lists_data_api_ref_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceFqdnList'] | [0].ref
    IF    $source_fqdn_lists_data_api_ref_list == ''
         Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourceFqdnList'] | [0].ref    {{ rule.match_criterias.source_fqdn_lists | default("not_defined") }}    msg=source fqdn lists
    ELSE
         ${source_fqdn_lists_yaml}=   Create List   {{ rule.match_criterias.source_fqdn_lists | default([]) | join('   ') }}
         ${id_string}=   Set Variable   ${source_fqdn_lists_data_api_ref_list}
         ${ids}=    Split String    ${id_string}
         ${source_fqdn_lists_name_list}=    Create List
         FOR    ${id}    IN    @{ids}
            ${source_fqdn_lists_ref_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/fqdn/${id}
            ${source_fqdn_lists_name}=    Json Search String    ${source_fqdn_lists_ref_data.json()}    name
            Append To List   ${source_fqdn_lists_name_list}    ${source_fqdn_lists_name}
         END
         Lists Should Be Equal    ${source_fqdn_lists_name_list}    ${source_fqdn_lists_yaml}    ignore_order=True    msg=source fqdn lists
    
    END

    ${source_data_prefix_lists_data_api_ref_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceDataPrefixList'] | [0].ref
    IF    $source_data_prefix_lists_data_api_ref_list == ''
         Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourceDataPrefixList'] | [0].ref    {{ rule.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    ELSE
         ${source_data_prefix_lists_yaml}=   Create List   {{ rule.match_criterias.source_data_prefix_lists | default([]) | join('   ') }}
         ${id_string}=   Set Variable   ${source_data_prefix_lists_data_api_ref_list}
         ${ids}=    Split String    ${id_string}
         ${source_data_prefix_lists_name_list}=    Create List
         FOR    ${id}    IN    @{ids}
            ${source_data_prefix_lists_ref_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/dataprefix/${id}
            ${source_data_prefix_lists_name}=    Json Search String    ${source_data_prefix_lists_ref_data.json()}    name
            Append To List   ${source_data_prefix_lists_name_list}    ${source_data_prefix_lists_name}
         END
         Lists Should Be Equal    ${source_data_prefix_lists_name_list}    ${source_data_prefix_lists_yaml}    ignore_order=True    msg=source data prefix list
    
    END

    ${destination_data_prefix_lists_data_api_ref_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationDataPrefixList'] | [0].ref
    IF    $destination_data_prefix_lists_data_api_ref_list == ''
         Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationDataPrefixList'] | [0].ref    {{ rule.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    ELSE
         ${destination_data_prefix_lists_yaml}=   Create List   {{ rule.match_criterias.destination_data_prefix_lists | default([]) | join('   ') }}
         ${id_string}=   Set Variable   ${destination_data_prefix_lists_data_api_ref_list}
         ${ids}=    Split String    ${id_string}
         ${destination_data_prefix_lists_name_list}=    Create List
         FOR    ${id}    IN    @{ids}
            ${destination_data_prefix_lists_ref_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/dataprefix/${id}
            ${destination_data_prefix_lists_name}=    Json Search String    ${destination_data_prefix_lists_ref_data.json()}    name
            Append To List   ${destination_data_prefix_lists_name_list}    ${destination_data_prefix_lists_name}
         END
         Lists Should Be Equal    ${destination_data_prefix_lists_name_list}    ${destination_data_prefix_lists_yaml}    ignore_order=True    msg=destination data prefix list
    
    END

    ${destination_fqdn_lists_data_api_ref_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationFqdnList'] | [0].ref
    IF    $destination_fqdn_lists_data_api_ref_list == ''
         Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationFqdnList'] | [0].ref    {{ rule.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=destination fqdn list
    ELSE
         ${destination_fqdn_lists_yaml}=   Create List   {{ rule.match_criterias.destination_fqdn_lists | default([]) | join('   ') }}
         ${id_string}=   Set Variable   ${destination_fqdn_lists_data_api_ref_list}
         ${ids}=    Split String    ${id_string}
         ${destination_fqdn_lists_name_list}=    Create List
         FOR    ${id}    IN    @{ids}
            ${destination_fqdn_lists_ref_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/fqdn/${id}
            ${destination_fqdn_lists_name}=    Json Search String    ${destination_fqdn_lists_ref_data.json()}    name
            Append To List   ${destination_fqdn_lists_name_list}    ${destination_fqdn_lists_name}
         END
         Lists Should Be Equal    ${destination_fqdn_lists_name_list}    ${destination_fqdn_lists_yaml}    ignore_order=True    msg=destination fqdn list
    
    END

    ${protocol_names_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='protocolName'] | [0].value
    IF    $protocol_names_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='protocolName'] | [0].value    {{ rule.match_criterias.protocol_names | default("not_defined") }}    msg=protocol name
    ELSE
        ${protocol_names_list}=    Create List    {{ rule.match_criterias.protocol_names | default([]) | join('   ') }}
        ${protocol_names_value}=  Split String    ${protocol_names_data_api_value_list}
        Lists Should Be Equal   ${protocol_names_value}   ${protocol_names_list}   ignore_order=True    msg=protocol name
    END

    ${protocols_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='protocol'] | [0].value
    IF    $protocols_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='protocol'] | [0].value    {{ rule.match_criterias.protocols | default("not_defined") }}    msg=protocol
    ELSE
        ${protocols_list}=    Create List    {{ rule.match_criterias.protocols | default([]) | join('   ') }}
        ${protocols_value}=  Split String    ${protocols_data_api_value_list}
        Lists Should Be Equal   ${protocols_value}   ${protocols_list}   ignore_order=True    msg=protocol
    END

    ${source_geo_locations_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='sourceGeoLocation'] | [0].value
    IF    $source_geo_locations_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourceGeoLocation'] | [0].value    {{ rule.match_criterias.source_geo_locations | default("not_defined") }}    msg=source geo location
    ELSE
        ${source_geo_locations_list}=    Create List    {{ rule.match_criterias.source_geo_locations | default([]) | join('   ') }}
        ${source_geo_locations_value}=  Split String    ${source_geo_locations_data_api_value_list}
        Lists Should Be Equal   ${source_geo_locations_value}   ${source_geo_locations_list}   ignore_order=True    msg=source geo location
    END

    ${destination_geo_locations_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[{{loop.index0}}].match.entries[?field=='destinationGeoLocation'] | [0].value
    IF    $destination_geo_locations_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationGeoLocation'] | [0].value    {{ rule.match_criterias.destination_geo_locations | default("not_defined") }}    msg=destination geo location
    ELSE
        ${destination_geo_locations_list}=    Create List    {{ rule.match_criterias.destination_geo_locations | default([]) | join('   ') }}
        ${destination_geo_locations_value}=  Split String    ${destination_geo_locations_data_api_value_list}
        Lists Should Be Equal   ${destination_geo_locations_value}   ${destination_geo_locations_list}   ignore_order=True    msg=destination geo location
    END

    ${port_lists}=    GET On Session With Retry    sdwan_manager    dataservice/template/policy/list/port

    ${source_port_lists_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[?sequenceId==`{{ rule.id }}`] | [0].match.entries[?field=='sourcePortList'] | [0].ref
    IF    $source_port_lists_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[?sequenceId==`{{ rule.id }}`] | [0].match.entries[?field=='sourcePortList'] | [0].ref    {{ rule.match_criterias.source_port_lists | default("not_defined") }}    msg=source port list
    ELSE
        ${source_port_yaml_list}=    Create List    {{ rule.match_criterias.source_port_lists | default([]) | join('   ') }}
        ${source_port_api_lists_ids}=  Split String    ${source_port_lists_data_api_value_list}
        ${source_port_api_lists}=    Create List
        FOR    ${id}    IN    @{source_port_api_lists_ids}
            ${port}=    Json Search String    ${port_lists.json()}    data[?listId=='${id}'] | [0].name
            Append To List    ${source_port_api_lists}    ${port}
        END
        Lists Should Be Equal   ${source_port_api_lists}   ${source_port_yaml_list}   ignore_order=True    msg=source port list
    END

    ${destination_port_lists_data_api_value_list}=   Json Search String    ${r_id.json()}   definition.sequences[?sequenceId==`{{ rule.id }}`] | [0].match.entries[?field=='destinationPortList'] | [0].ref
    IF    $destination_port_lists_data_api_value_list == ''
        Should Be Equal Value Json String    ${r_id.json()}    definition.sequences[?sequenceId==`{{ rule.id }}`] | [0].match.entries[?field=='destinationPortList'] | [0].ref    {{ rule.match_criterias.destination_port_lists | default("not_defined") }}    msg=destination port list
    ELSE
        ${destination_port_yaml_list}=    Create List    {{ rule.match_criterias.destination_port_lists | default([]) | join('   ') }}
        ${destination_port_api_lists_ids}=  Split String    ${destination_port_lists_data_api_value_list}
        ${destination_port_api_lists}=    Create List
        FOR    ${id}    IN    @{destination_port_api_lists_ids}
            ${port}=    Json Search String    ${port_lists.json()}    data[?listId=='${id}'] | [0].name
            Append To List    ${destination_port_api_lists}    ${port}
        END
        Lists Should Be Equal   ${destination_port_api_lists}   ${destination_port_yaml_list}   ignore_order=True    msg=destination port list
    END

{% set source_port_range_list = [] %}
{% for source_port_range in rule.match_criterias.source_port_ranges | default([]) %}
    {% set test_list = [] %}
    {% set _ = test_list.append(source_port_range.from) %}
    {% set _ = test_list.append(source_port_range.to) %}
    {% set source_port_range_test = '-'.join(test_list | map('string')) %}
    {% set _ = source_port_range_list.append(source_port_range_test) %}   
{% endfor %}
{% if rule.match_criterias.source_ports is defined and rule.match_criterias.source_port_ranges is defined%}
{% set req_source_port = rule.match_criterias.source_ports  %}
{% set source_string = req_source_port | map('string') | join(',') %}
{% set new_sorce_port_list = source_string.split(',') %}
{% set source_list = new_sorce_port_list + source_port_range_list %}
    ${list}=   Create List   {{ source_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source port and source port range
{% elif rule.match_criterias.source_ports is defined %}
    ${list}=   Create List   {{ rule.match_criterias.source_ports | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source port
{% elif rule.match_criterias.source_port_ranges is defined %}
    ${list} =   Create List   {{ source_port_range_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source port range
{% else %}
    Should Be Equal Value Json String     ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value    {{ rule.match_criterias.source_ports | default("not_defined") }}    msg=source port
    Should Be Equal Value Json String     ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value    {{ rule.match_criterias.source_port_ranges | default("not_defined") }}    msg=source port range
{% endif %}

{% set destination_port_ranges_list = [] %}
{% for destination_port_ranges in rule.match_criterias.destination_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(destination_port_ranges.from) %}
{% set _ = test_list.append(destination_port_ranges.to) %}
{% set destination_port_ranges_test = '-'.join(test_list | map('string')) %}
{% set _ = destination_port_ranges_list.append(destination_port_ranges_test) %}
{% endfor %}

{% if rule.match_criterias.destination_ports is defined and rule.match_criterias.destination_port_ranges is defined%}
{% set req_destination_port = rule.match_criterias.destination_ports  %}
{% set destination_string = req_destination_port | map('string') | join(',') %}
{% set new_dest_port_list = destination_string.split(',') %}
{% set destination_list = new_dest_port_list + destination_port_ranges_list %}
    ${list}=   Create List   {{ destination_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination port and destination port ranges
{% elif rule.match_criterias.destination_ports is defined %}
    ${list}=   Create List   {{ rule.match_criterias.destination_ports | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination port
{% elif rule.match_criterias.destination_port_ranges is defined %}
    ${list} =   Create List   {{ destination_port_ranges_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    definition.sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination port ranges
{% endif %}
{% endfor %}

{% for zone_pair in zbf.zone_pairs | default([]) %} 
{% if zone_pair.destination_zone is defined and zone_pair.destination_zone == 'self_zone' %}
    Should Be Equal Value Json String   ${r_id.json()}   definition.entries[{{loop.index0}}].destinationZone   self    msg=destination zone
{% else %}
    ${destination_zone_id}=   Json Search String   ${r_id.json()}   definition.entries[{{loop.index0}}].destinationZone
    IF    $destination_zone_id == ''
       Should Be Equal Value Json String   ${r_id.json()}   definition.entries[{{loop.index0}}].destinationZone   {{ zone_pair.destination_zone | default("not_defined") }}    msg=destination zone
    ELSE
       ${r_destination_zone_id}=    GET On Session With Retry   sdwan_manager   dataservice/template/policy/list/zone/${destination_zone_id}
        Should Be Equal Value Json String    ${r_destination_zone_id.json()}   name   {{ zone_pair.destination_zone | default("not_defined") }}    msg=destination zone
    END
{% endif %}

{% if zone_pair.source_zone is defined and zone_pair.source_zone == 'self_zone' %}
    Should Be Equal Value Json String   ${r_id.json()}   definition.entries[{{loop.index0}}].sourceZone   self    msg=source zone
{% else %}
    ${source_zone_id}=   Json Search String   ${r_id.json()}   definition.entries[{{loop.index0}}].sourceZone
    IF    $source_zone_id == ''
       Should Be Equal Value Json String   ${r_id.json()}   definition.entries[{{loop.index0}}].sourceZone   {{ zone_pair.source_zone | default("not_defined") }}    msg=source zone
    ELSE
       ${r_source_zone_id}=    GET On Session With Retry   sdwan_manager   dataservice/template/policy/list/zone/${source_zone_id}
        Should Be Equal Value Json String    ${r_source_zone_id.json()}   name   {{ zone_pair.source_zone | default("not_defined") }}    msg=source zone
    END   

{% endif %}

{% endfor %}

{% endfor %}

{% endif %}
