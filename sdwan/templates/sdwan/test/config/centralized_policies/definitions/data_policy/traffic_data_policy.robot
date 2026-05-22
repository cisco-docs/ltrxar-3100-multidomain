*** Settings ***
Documentation   Verify Traffic Data Policy in Traffic Policy configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    data_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.data_policy.traffic_data is defined%}

*** Test Cases ***
Get Traffic Data Policy(s)
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/data
    Set Suite Variable    ${r}

{% for traffic_policy in sdwan.centralized_policies.definitions.data_policy.traffic_data | default([]) %}

Verify Centralized Policy Data Policy Traffic Data {{ traffic_policy.name }}
    ${traffic_data_policy_id}=    Json Search String    ${r.json()}    data[?name=='{{traffic_policy.name }}'] | [0].definitionId
    Run Keyword If    $traffic_data_policy_id == ''    Fail    Traffic Data Policy '{{traffic_policy.name}}' not found
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/data/${traffic_data_policy_id}

    Should Be Equal Value Json String    ${r_id.json()}    name    {{ traffic_policy.name }}    msg=traffic data policy name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ traffic_policy.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    defaultAction.type    {{ traffic_policy.default_action_type }}    msg=default action type

{% for item in traffic_policy.sequences | default([]) %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceId   {{ item.id }}    msg=traffic data policy sequence id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].baseAction   {{ item.base_action }}    msg=base action
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceName   {{ item.name }}    msg=sequence name
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceIpType   {{ item.ip_type | default(defaults.sdwan.centralized_policies.definitions.data_policy.traffic_data.sequences.ip_type) }}    msg=sequence ip type

{% set type = ({"qos":"qos", "service_chaining":"serviceChaining", "traffic_engineering":"trafficEngineering", "application_firewall":"applicationFirewall", "custom":"data"}) %}
{% set item_type = (item.type | default(defaults.sdwan.centralized_policies.definitions.data_policy.traffic_data.sequences.type)) %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceType   {{ type[item_type] }}    msg=sequence type- {{ item_type }}

    ${app_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='appList'] | [0].ref
    IF    $app_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='appList'] | [0].ref    {{ item.match_criterias.application_list | default("not_defined") }}    msg=application list
    ELSE
        ${r_app_list_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/app/${app_list_id}
        Should Be Equal Value Json String    ${r_app_list_id.json()}    name    {{ item.match_criterias.application_list | default("not_defined") }}    msg=application list
    END
    
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='dscp'] | [0].value    {{ item.match_criterias.dscp | default("not_defined") }}    msg=dscp
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='packetLength'] | [0].value    {{ item.match_criterias.packet_length | default("not_defined") }}    msg=packet length
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='plp'] | [0].value    {{ item.match_criterias.plp | default("not_defined") }}    msg=plp

    ${proto}=   Json Search String   ${r_id.json()}   sequences[{{loop.index0}}].match.entries[?field=='protocol'] | [0].value
    IF    $proto == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='protocol'] | [0].value    {{ item.match_criterias.protocols | default("not_defined") }}    msg=protocols list
    ELSE
        ${protocol_list}=    Create List    {{ item.match_criterias.protocols | default([]) | join('   ') }}
        ${proto_list}=  Split String    ${proto}
        Lists Should Be Equal   ${proto_list}   ${protocol_list}   ignore_order=True    msg=protocols list
    END

    ${prefix_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceDataPrefixList'] | [0].ref
    IF    $prefix_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceDataPrefixList'] | [0].ref    {{ item.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    ELSE
        ${r_prefix_list_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataprefix/${prefix_list_id}
        Should Be Equal Value Json String    ${r_prefix_list_id.json()}    name    {{ item.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    END
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourceIp'] | [0].value    {{ item.match_criterias.source_data_prefix | default("not_defined") }}    msg=source data prefix

{% set source_port_range_list = [] %}
{% for item in item.match_criterias.source_port_ranges | default([]) %}
    {% set test_list = [] %}
    {% set _ = test_list.append(item.from) %}
    {% set _ = test_list.append(item.to) %}
    {% set source_port_range_test = '-'.join(test_list | map('string')) %}
    {% set _ = source_port_range_list.append(source_port_range_test) %}   
{% endfor %}

{% if item.match_criterias.source_ports is defined and item.match_criterias.source_port_ranges is defined%}
{% set req_source_port = item.match_criterias.source_ports  %}
{% set source_string = req_source_port | map('string') | join(',') %}
{% set new_sorce_port_list = source_string.split(',') %}
{% set source_list = new_sorce_port_list + source_port_range_list %}
    ${list}=   Create List   {{ source_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source ports and ranges
{% elif item.match_criterias.source_ports is defined %}
    ${list}=   Create List   {{ item.match_criterias.source_ports | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source ports
{% elif item.match_criterias.source_port_ranges is defined %}
    ${list} =   Create List   {{ source_port_range_list | join('   ') }}
    ${r_sourceport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value
    ${sourceport_list}=    Split String    ${r_sourceport}
    Lists Should Be Equal    ${list}    ${sourceport_list}    msg=source ports ranges
{% else %}
    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value    {{ item.match_criterias.source_ports | default("not_defined") }}    msg=source ports
    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='sourcePort'] | [0].value    {{ item.match_criterias.source_port_ranges | default("not_defined") }}    msg=source port ranges
{% endif %}

    ${d_prefix_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationDataPrefixList'] | [0].ref
    IF    $d_prefix_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationDataPrefixList'] | [0].ref    {{ item.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    ELSE
        ${d_prefix_list}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/dataprefix/${d_prefix_list_id}
        Should Be Equal Value Json String     ${d_prefix_list.json()}    name    {{ item.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    END

    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationIp'] | [0].value    {{ item.match_criterias.destination_data_prefix | default("not_defined") }}    msg=destination data prefix
    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tcp'] | [0].value    {{ item.match_criterias.tcp | default("not_defined") }}    msg=tcp

{% set destination_port_range_list = [] %}
{% for item in item.match_criterias.destination_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.from) %}
{% set _ = test_list.append(item.to) %}
{% set destination_port_range_test = '-'.join(test_list | map('string')) %}
{% set _ = destination_port_range_list.append(destination_port_range_test) %}   
{% endfor %}

{% if item.match_criterias.destination_ports is defined and item.match_criterias.destination_port_ranges is defined %}
{% set req_destination_port = item.match_criterias.destination_ports  %}
{% set destination_string = req_destination_port | map('string') | join(',') %}
{% set new_dest_port_list = destination_string.split(',') %}
{% set destination_list = new_dest_port_list + destination_port_range_list %}
    ${list}=   Create List   {{ destination_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${list}    ${destinationport_list}    msg=destination ports and ranges
{% elif item.match_criterias.destination_ports is defined %}
    ${list}=   Create List   {{ item.match_criterias.destination_ports | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports
{% elif item.match_criterias.destination_port_ranges is defined %}
    ${list} =   Create List   {{ destination_port_range_list | join('   ') }}
    ${r_destinationport}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value
    ${destinationport_list}=    Split String    ${r_destinationport}
    Lists Should Be Equal    ${list}    ${destinationport_list}    msg=destination ports ranges
{% else %}
    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value    {{ item.match_criterias.destination_ports | default("not_defined") }}    msg=destination ports
    Should Be Equal Value Json String     ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='destinationPort'] | [0].value    {{ item.match_criterias.destination_port_ranges | default("not_defined") }}    msg=destination port ranges
{% endif %}

{% if item.actions.log is defined and item.actions.log == True | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     log    msg=log
{% elif item.actions.log is defined and item.actions.log == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     not_defined    msg=log
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='log'] | [0].type     {{ item.actions.log | default("not_defined") }}    msg=log
{% endif %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='count'] | [0].parameter    {{ item.actions.counter_name | default("not_defined") }}    msg=counter name

{% if item_type == "custom" %}
    ${dns_app_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='dnsAppList'] | [0].ref
    IF    $dns_app_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='dnsAppList'] | [0].ref    {{ item.match_criterias.dns_application_list | default("not_defined") }}    msg=dns application list
    ELSE
        ${r_dns_app_list_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/app/${dns_app_list_id}
        Should Be Equal Value Json String    ${r_dns_app_list_id.json()}    name    {{ item.match_criterias.dns_application_list | default("not_defined") }}    msg=dns application list
    END

    Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].match.entries[?field=='dns'] | [0].value   {{ item.match_criterias.dns | default("not_defined") }}    msg=dns
    Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].match.entries[?field=='trafficTo'] | [0].value   {{ item.match_criterias.traffic_to | default("not_defined") }}    msg=traffic to
    Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].match.entries[?field=='destinationRegion'] | [0].value   {{ item.match_criterias.destination_region | default("not_defined") }}    msg=destination region

{% if item.actions.cflowd is defined and item.actions.cflowd == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='cflowd'] | [0].parameter         msg=cflowd
{% elif item.actions.cflowd is defined and item.actions.cflowd == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='cflowd'] | [0].parameter     not_defined    msg=cflowd
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='cflowd'] | [0].parameter     {{ item.actions.cflowd | default("not_defined") }}    msg=cflowd
{% endif %}

{% if item.actions.sig is defined and item.actions.sig.enabled == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='sig'] | [0].parameter         msg=sig
{% elif item.actions.sig is defined and item.actions.sig.enabled == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='sig'] | [0].parameter    not_defined    msg=sig
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='sig'] | [0].parameter    {{ item.actions.sig.enabled | default("not_defined") }}    msg=sig
{% endif %}

{% if item.actions.sig is defined and item.actions.sig.fallback_to_routing | default("not_defined") == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='fallbackToRouting'] | [0].parameter         msg=fallback to routing
{% elif item.actions.sig is defined and item.actions.sig.fallback_to_routing | default("not_defined") == False %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='fallbackToRouting'] | [0].parameter    not_defined    msg=fallback to routing
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='fallbackToRouting'] | [0].parameter    {{ item.actions.sig.fallback_to_routing | default("not_defined") }}    msg=fallback to routing
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='redirectDns'] | [0].parameter.field    {{ item.actions.redirect_dns.type | default("not_defined") }}     msg=redirection dns type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='redirectDns'] | [0].parameter.value    {{ item.actions.redirect_dns.ip_address | default("not_defined") }}     msg=redirection dns ip address
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='nat'] | [0].parameter[?field=='useVpn'] | [0].value    {{ item.actions.nat_vpn.vpn_id | default("not_defined") }}     msg=nat vpn id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='nat'] | [0].parameter[?field=='fallback'] | [0].value    {{ item.actions.nat_vpn.nat_vpn_fallback | default("not_defined") | lower() }}     msg=nat vpn fallback
    # Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='nat'] | [0].parameter[?field=='pool'] | [0].value    {{ item.actions.nat_pool | default("not_defined") }}     msg=nat pool id

{% if item.actions.appqoe_optimization.tcp is defined and item.actions.appqoe_optimization.tcp == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='tcpOptimization'] | [0].parameter         msg=tcp Optimization
{% elif item.actions.appqoe_optimization.tcp is defined and item.actions.appqoe_optimization.tcp == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='tcpOptimization'] | [0].parameter     not_defined    msg=tcp Optimization
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='tcpOptimization'] | [0].parameter     {{ item.actions.appqoe_optimization.tcp | default("not_defined") }}    msg=tcp Optimization
{% endif %}

{% if item.actions.appqoe_optimization.dre is defined and item.actions.appqoe_optimization.dre == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='dreOptimization'] | [0].parameter         msg=dre Optimization
{% elif item.actions.appqoe_optimization.dre is defined and item.actions.appqoe_optimization.dre == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='dreOptimization'] | [0].parameter     not_defined    msg=dre Optimization
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='dreOptimization'] | [0].parameter     {{ item.actions.appqoe_optimization.dre | default("not_defined") }}    msg=dre Optimization
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='serviceNodeGroup'] | [0].parameter     {{ item.actions.appqoe_optimization.service_node_group | default("not_defined") }}    msg=service node group
    ${color_group_id}=   Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='preferredColorGroup'] | [0].ref
    IF    $color_group_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='preferredColorGroup'] | [0].ref    {{ item.actions.preferred_color_group | default("not_defined") }}    msg=preferred color group
    ELSE
        ${cg_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/preferredcolorgroup/${color_group_id}
        Should Be Equal Value Json String    ${cg_id.json()}    name     {{ item.actions.preferred_color_group | default("not_defined") }}    msg=preferred color group
    END

{% endif %}

{% if item_type == "service_chaining" or item_type == "traffic_engineering" or item_type == "custom" %}

    ${tloc_id}=   Json Search String   ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tlocList'] | [0].ref
    IF    $tloc_id == ''
        Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tlocList'] | [0].ref    {{ item.actions.tloc_list | default("not_defined") }}    msg=tloc list
    ELSE
        ${r_tloc_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_id}
        Should Be Equal Value Json String    ${r_tloc_id.json()}    name    {{ item.actions.tloc_list | default("not_defined") }}    msg=tloc list
    END

{% if item.actions.tloc is defined %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.ip    {{ item.actions.tloc.ip }}    msg=tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.color    {{ item.actions.tloc.color }}    msg=tloc color
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.encap    {{ item.actions.tloc.encap }}    msg=tloc encap
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0]     not_defined    msg=tloc
{% endif %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='vpn'] | [0].value    {{ item.actions.vpn | default("not_defined") }}    msg=vpn
{% endif %}

{% if item_type == "service_chaining" or item_type == "custom" %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.type    {{ item.actions.service.type | default("not_defined") }}    msg=service type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.vpn    {{ item.actions.service.vpn | default("not_defined") }}    msg=service vpn

    ${tloc_id}=   Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.tlocList.ref
    IF    $tloc_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.tlocList.ref    {{ item.actions.service.tloc_list | default("not_defined") }}    msg=service tloc list
    ELSE
        ${r_tloc_id}=   GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/tloc/${tloc_id}
        Should Be Equal Value Json String    ${r_tloc_id.json()}    name    {{ item.actions.service.tloc_list | default("not_defined") }}    msg=service tloc list
    END

{% if item.actions.service.local is defined and item.actions.service.local == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.local        msg=service local
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.local    {{ item.actions.service.local | default("not_defined") }}    msg=service local
{% endif %}

{% if item.actions.service.restrict is defined and item.actions.service.restrict == True %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.restrict        msg=service restrict
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.restrict    {{ item.actions.service.restrict | default("not_defined") }}    msg=service restrict
{% endif %}

{% endif %}

{% if item_type == "qos" or item_type == "custom" %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='dscp'] | [0].value    {{ item.actions.dscp | default("not_defined") }}    msg=dscp
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='forwardingClass'] | [0].value    {{ item.actions.forwarding_class | default("not_defined") }}    msg=forwarding class
{% if item.actions.loss_correction is defined %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='lossProtect'] | [0].parameter    {{ item.actions.loss_correction.type | default("not_defined") }}    msg=loss correction type
{% if item.actions.loss_correction.type == "fecAlways" %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='lossProtectFec'] | [0].parameter    fecAlways    msg=fec always
{% elif item.actions.loss_correction.type == "packetDuplication" %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='lossProtectPktDup'] | [0].parameter    packetDuplication    msg=packet duplication
{% elif item.actions.loss_correction.type == "fecAdaptive" %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='lossProtectFec'] | [0].parameter    fecAdaptive    msg=fec adaptive
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='lossProtectFec'] | [0].value    {{ item.actions.loss_correction.loss_threshold_percentage | default("not_defined") }}    msg=loss threshold percentage
{% endif %}
{% endif %}

    ${policer_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='policer'] | [0].ref
    IF    $policer_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='policer'] | [0].ref    {{ item.actions.policer_list | default("not_defined") }}    msg=policer list
    ELSE
        ${r_policer_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/policer/${policer_list_id}
        Should Be Equal Value Json String    ${r_policer_id.json()}    name    {{ item.actions.policer_list | default("not_defined") }}    msg=policer list
    END
{% endif %}

{% if item_type == "traffic_engineering" or item_type == "custom" %}
{% if item.actions.local_tloc_list is defined %}
    ${color_list}=   Json Search String   ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.color
    IF    $color_list == ''
        Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.color    {{ item.actions.local_tloc_list.colors | default("not_defined") }}    msg=local tloc color
    ELSE
        ${local_tloc_color_list}=  Split String    ${color_list}
        ${local_tloc_color}=    Create List    {{ item.actions.local_tloc_list.colors | join('   ') }}
        Lists Should Be Equal   ${local_tloc_color_list}   ${local_tloc_color}    ignore_order=True    msg=local tloc color
    END

    ${encap_list}=   Json Search String   ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.encap
    IF    $encap_list == ''
        Should Be Equal Value Json String    ${r_id.json()}   sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.encap    {{ item.actions.local_tloc_list.encaps | default("not_defined") }}    msg=local tloc encap
    ELSE
        ${local_tloc_encap_list}=  Split String    ${encap_list}
        ${local_tloc_encap}=    Create List    {{ item.actions.local_tloc_list.encaps | default([]) | join('   ') }}
        Lists Should Be Equal   ${local_tloc_encap_list}   ${local_tloc_encap}    ignore_order=True    msg=local tloc encap
    END

{% if item.actions.local_tloc_list.restrict is defined and item.actions.local_tloc_list.restrict == True | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.restrict        msg=restrict
{% elif item.actions.local_tloc_list.restrict is defined and item.actions.local_tloc_list.restrict == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.restrict     not_defined    msg=restrict
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localTlocList'] | [0].value.restrict     {{ item.actions.local_tloc_list.restrict | default("not_defined") }}    msg=restrict
{% endif %}
{% endif %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHop'] | [0].value    {{ item.actions.next_hop.ip_address | default("not_defined") }}    msg=next hop ip

{% if item.actions.next_hop.when_next_hop_is_not_available is defined and item.actions.next_hop.when_next_hop_is_not_available == "route_table_entry" | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHopLoose'] | [0].value    true    msg=nexthop
{% elif item.actions.next_hop.when_next_hop_is_not_available is defined and item.actions.next_hop.when_next_hop_is_not_available == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHopLoose'] | [0].value    false    msg=nexthop
{% else %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHopLoose'] | [0].value    {{ item.actions.next_hop.when_next_hop_is_not_available | default("not_defined") }}    msg=nexthop
{% endif %}
{% endif %}

{% endfor %}
{% endfor %}
{% endif %}
