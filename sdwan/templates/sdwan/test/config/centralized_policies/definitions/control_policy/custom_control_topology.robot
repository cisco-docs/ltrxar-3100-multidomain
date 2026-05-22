*** Settings ***
Documentation   Verify Custom Control Topology
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    control_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.control_policy.custom_control_topology is defined %}

*** Test Cases ***
Get Custom Control Topology
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/control
    Set Suite Variable    ${r}

{% for cct in sdwan.centralized_policies.definitions.control_policy.custom_control_topology | default([]) %}

Verify Centralized Policies Control Policy Custom Control Topology {{ cct.name }}
    ${cct_id}=   Json Search String   ${r.json()}   data[?name=='{{ cct.name }}'] | [0].definitionId
    Run Keyword If    $cct_id == ''    Fail    Custom Control Topology '{{ cct.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/control/${cct_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ cct.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ cct.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    defaultAction.type    {{ cct.default_action_type }}    msg=default action type

    Should Be Equal Value Json List Length    ${r_id.json()}    sequences    {{ cct.sequences | default([]) | length }}    msg=sequences length

{% for sequence in cct.sequences | default([]) %}

{% if sequence.type == 'tloc' %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].baseAction    {{ sequence.base_action }}    msg=tloc base action
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceId    {{ sequence.id }}    msg=tloc id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceName    {{ sequence.name }}    msg=tloc name
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceIpType    {{ sequence.ip_type | default(defaults.sdwan.centralized_policies.definitions.control_policy.custom_control_topology.sequences.ip_type) }}    msg=tloc ip type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceType    {{ sequence.type }}    msg=tloc type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='carrier'] | [0].value    {{ sequence.match_criterias.carrier | default("not_defined") }}    msg=tloc carrier

    ${color_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='colorList'] | [0].ref
    IF    $color_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='colorList'] | [0].ref    {{ sequence.match_criterias.color_list | default("not_defined") }}    msg=tloc color list
    ELSE
        ${color_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/color/${color_list_ref_id}
        Should Be Equal Value Json String    ${color_list_match_id.json()}    name    {{ sequence.match_criterias.color_list | default("not_defined") }}    msg=tloc color list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='domainId'] | [0].value    {{ sequence.match_criterias.domain_id | default("not_defined") }}    msg=tloc domain id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='groupId'] | [0].value    {{ sequence.match_criterias.group_id | default("not_defined") }}    msg=tloc group id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='ompTag'] | [0].value    {{ sequence.match_criterias.omp_tag | default("not_defined") }}    msg=tloc omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='originator'] | [0].value    {{ sequence.match_criterias.originator | default("not_defined") }}    msg=tloc originator
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='preference'] | [0].value    {{ sequence.match_criterias.preference | default("not_defined") }}    msg=tloc preference

    ${site_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteList'] | [0].ref
    IF    $site_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteList'] | [0].ref    {{ sequence.match_criterias.site_list | default("not_defined") }}    msg=tloc site list
    ELSE
        ${site_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${site_list_ref_id}
        Should Be Equal Value Json String    ${site_list_match_id.json()}    name    {{ sequence.match_criterias.site_list | default("not_defined") }}    msg=tloc site list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteId'] | [0].value    {{ sequence.match_criterias.site_id | default("not_defined") }}    msg=tloc site id

    ${region_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionList'] | [0].ref
    IF    $region_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionList'] | [0].ref    {{ (sequence.match_criterias | default({})).region_list | default("not_defined") }}    msg=tloc region list
    ELSE
        ${region_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${region_list_ref_id}
        Should Be Equal Value Json String    ${region_list_match_id.json()}    name    {{ (sequence.match_criterias | default({})).region_list | default("not_defined") }}    msg=tloc region list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionId'] | [0].value    {{ sequence.match_criterias.region_id | default("not_defined") }}    msg=tloc region id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='role'] | [0].value    {{ sequence.match_criterias.role | default("not_defined") }}    msg=tloc role

    ${tloc_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tlocList'] | [0].ref
    IF    $tloc_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tlocList'] | [0].ref    {{ sequence.match_criterias.tloc_list | default("not_defined") }}    msg=tloc list
    ELSE
        ${tloc_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_list_ref_id}
        Should Be Equal Value Json String    ${tloc_list_match_id.json()}    name    {{ sequence.match_criterias.tloc_list | default("not_defined") }}    msg=tloc list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.ip    {{ sequence.match_criterias.tloc.ip | default("not_defined") }}    msg=tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.color    {{ sequence.match_criterias.tloc.color | default("not_defined") }}    msg=tloc color
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.encap    {{ sequence.match_criterias.tloc.encap | default("not_defined") }}    msg=tloc encap
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='ompTag'] | [0].value   {{ sequence.actions.omp_tag | default("not_defined") }}    msg=tloc actions omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='preference'] | [0].value    {{ sequence.actions.preference | default("not_defined") }}    msg=tloc actions preference

{% else %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].baseAction    {{ sequence.base_action }}    msg=route base action
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceId    {{ sequence.id }}    msg=route id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceName    {{ sequence.name }}    msg=route name
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceIpType    {{ sequence.ip_type | default(defaults.sdwan.centralized_policies.definitions.control_policy.custom_control_topology.sequences.ip_type) }}    msg=route ip type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceType    {{ sequence.type }}    msg=route type

    ${color_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='colorList'] | [0].ref
    IF    $color_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='colorList'] | [0].ref    {{ sequence.match_criterias.color_list | default("not_defined") }}    msg=route color list
    ELSE
        ${color_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/color/${color_list_ref_id}
        Should Be Equal Value Json String    ${color_list_match_id.json()}    name    {{ sequence.match_criterias.color_list | default("not_defined") }}    msg=route color list
    END

    ${community_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='community'] | [0].ref
    IF    $community_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='community'] | [0].ref    {{ sequence.match_criterias.community_list | default("not_defined") }}    msg=route match criteria community list
    ELSE
        ${community_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/community/${community_list_ref_id}
        Should Be Equal Value Json String    ${community_list_match_id.json()}    name    {{ sequence.match_criterias.community_list | default("not_defined") }}    msg=route match criteria community list
    END

    ${expanded_community_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='expandedCommunity'] | [0].ref
    IF    $expanded_community_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='expandedCommunity'] | [0].ref    {{ sequence.match_criterias.expanded_community_list | default("not_defined") }}    msg=route expanded community list
    ELSE
        ${expanded_community_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/expandedcommunity/${expanded_community_list_ref_id}
        Should Be Equal Value Json String    ${expanded_community_list_match_id.json()}    name    {{ sequence.match_criterias.expanded_community_list | default("not_defined") }}    msg=route expanded community list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='ompTag'] | [0].value    {{ sequence.match_criterias.omp_tag | default("not_defined") }}    msg=route omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='origin'] | [0].value    {{ sequence.match_criterias.origin | default("not_defined") }}    msg=route origin
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='originator'] | [0].value    {{ sequence.match_criterias.originator | default("not_defined") }}    msg=route originator
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='preference'] | [0].value    {{ sequence.match_criterias.preference | default("not_defined") }}    msg=route preference

    ${site_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteList'] | [0].ref
    IF    $site_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteList'] | [0].ref    {{ sequence.match_criterias.site_list | default("not_defined") }}    msg=route site list
    ELSE
        ${site_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${site_list_ref_id}
        Should Be Equal Value Json String    ${site_list_match_id.json()}    name    {{ sequence.match_criterias.site_list | default("not_defined") }}    msg=route site list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='siteId'] | [0].value    {{ sequence.match_criterias.site_id | default("not_defined") }}    msg=route site id

    ${region_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionList'] | [0].ref
    IF    $region_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionList'] | [0].ref    {{ (sequence.match_criterias | default({})).region_list | default("not_defined") }}    msg=route region list
    ELSE
        ${region_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${region_list_ref_id}
        Should Be Equal Value Json String    ${region_list_match_id.json()}    name    {{ (sequence.match_criterias | default({})).region_list | default("not_defined") }}    msg=route region list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='regionId'] | [0].value    {{ sequence.match_criterias.region_id | default("not_defined") }}    msg=route region id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='role'] | [0].value    {{ sequence.match_criterias.role | default("not_defined") }}    msg=route role 
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='pathType'] | [0].value    {{ sequence.match_criterias.path_type | default("not_defined") }}    msg=route path type

    ${tloc_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tlocList'] | [0].ref
    IF    $tloc_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tlocList'] | [0].ref    {{ sequence.match_criterias.tloc_list | default("not_defined") }}    msg=route tloc list
    ELSE
        ${tloc_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_list_ref_id}
        Should Be Equal Value Json String    ${tloc_list_match_id.json()}    name    {{ sequence.match_criterias.tloc_list | default("not_defined") }}    msg=route tloc list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.ip    {{ sequence.match_criterias.tloc.ip | default("not_defined") }}    msg=route tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.color    {{ sequence.match_criterias.tloc.color | default("not_defined") }}    msg=route tloc color
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='tloc'] | [0].value.encap    {{ sequence.match_criterias.tloc.encap | default("not_defined") }}    msg=route tloc encap

    ${vpn_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='vpnList'] | [0].ref
    IF    $vpn_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='vpnList'] | [0].ref    {{ sequence.match_criterias.vpn_list | default("not_defined") }}    msg=route vpn list
    ELSE
        ${vpn_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${vpn_list_ref_id}
        Should Be Equal Value Json String    ${vpn_list_match_id.json()}    name    {{ sequence.match_criterias.vpn_list | default("not_defined") }}    msg=route vpn list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='vpn'] | [0].value    {{ sequence.match_criterias.vpn | default("not_defined") }}    msg=route vpn

    ${ipv4_prefix_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='prefixList'] | [0].ref
    IF    $ipv4_prefix_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='prefixList'] | [0].ref    {{ sequence.match_criterias.ipv4_prefix_list | default("not_defined") }}    msg=route ipv4 prefix list
    ELSE
        ${ipv4_prefix_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/prefix/${ipv4_prefix_list_ref_id}
        Should Be Equal Value Json String    ${ipv4_prefix_list_match_id.json()}    name    {{ sequence.match_criterias.ipv4_prefix_list | default("not_defined") }}    msg=route ipv4 prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='community'] | [0].value    {{ sequence.actions.community | default("not_defined") }}    msg=route community
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='communityAdditive'] | [0].value    {{ sequence.actions.community_additive | default("not_defined") | lower }}    msg=route community additive
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='ompTag'] | [0].value    {{ sequence.actions.omp_tag | default("not_defined") }}    msg=route actions omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='preference'] | [0].value    {{ sequence.actions.preference | default("not_defined") }}    msg=route actions preference
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.ip    {{ sequence.actions.tloc.ip | default("not_defined") }}    msg=route tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.color    {{ sequence.actions.tloc.color | default("not_defined") }}    msg=route tloc color
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tloc'] | [0].value.encap    {{ sequence.actions.tloc.encap | default("not_defined") }}    msg=route tloc encap

    ${tloc_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tlocList'] | [0].ref
    IF    $tloc_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tlocList'] | [0].ref    {{ sequence.actions.tloc_list | default("not_defined") }}    msg=route tloc list
    ELSE
        ${tloc_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_list_ref_id}
        Should Be Equal Value Json String    ${tloc_list_match_id.json()}    name    {{ sequence.actions.tloc_list | default("not_defined") }}    msg=route tloc list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='tlocAction'] | [0].value   {{ sequence.actions.tloc_action | default("not_defined") }}    msg=route tloc action
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.type   {{ sequence.actions.service.type | default("not_defined") }}    msg=route service type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.vpn   {{ sequence.actions.service.vpn | default("not_defined") }}    msg=route service vpn
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.tloc.ip    {{ sequence.actions.service.tloc.ip | default("not_defined") }}    msg=route service tloc ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.tloc.color   {{ sequence.actions.service.tloc.color | default("not_defined") }}    msg=route service tloc color
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value.tloc.encap     {{ sequence.actions.service.tloc.encap | default("not_defined") }}    msg=route service tloc encap

    ${tloc_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value[?field=='tlocList'] | [0].ref
    IF    $tloc_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='service'] | [0].value[?field=='tlocList'] | [0].ref    {{ sequence.actions.service.tloc_list | default("not_defined") }}    msg=route service tloc list
    ELSE
        ${tloc_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_list_ref_id}
        Should Be Equal Value Json String    ${tloc_list_match_id.json()}    name    {{ sequence.actions.service.tloc_list | default("not_defined") }}    msg=route service tloc list
    END

    ${export_to_vpn_list_ref_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='exportTo'] | [0].parameter.ref
    IF    $export_to_vpn_list_ref_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='exportTo'] | [0].parameter.ref    {{ sequence.actions.export_to_vpn_list | default("not_defined") }}    msg=route export to vpn list
    ELSE
        ${export_to_vpn_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${export_to_vpn_list_ref_id}
        Should Be Equal Value Json String    ${export_to_vpn_list_match_id.json()}    name    {{ sequence.actions.export_to_vpn_list | default("not_defined") }}    msg=route export to vpn list
    END

{% endif %}

{% endfor %}

{% endfor %}

{% endif %}
