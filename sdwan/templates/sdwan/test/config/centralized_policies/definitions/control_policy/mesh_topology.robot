*** Settings ***
Documentation   Verify Mesh Topology
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    control_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.control_policy.mesh_topology is defined%}

*** Test Cases ***
Get Mesh Topology
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/mesh
    Set Suite Variable    ${r}

{% for mesh in sdwan.centralized_policies.definitions.control_policy.mesh_topology | default([]) %}

Verify Centralized Policies Control Policy Mesh Topology {{ mesh.name }}
    ${mesh_id}=    Json Search String    ${r.json()}    data[?name=='{{ mesh.name }}'] | [0].definitionId
    Run Keyword If    $mesh_id == ''    Fail    Mesh Topology '{{ mesh.name }}' not found
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/mesh/${mesh_id}

    Should Be Equal Value Json String    ${r_id.json()}    name    {{ mesh.name }}    msg=mesh name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ mesh.description | normalize_special_string }}    msg=description

    ${mesh_vpn_id}=    Json Search String    ${r_id.json()}    definition.vpnList
    ${vpn_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${mesh_vpn_id}
    Should Be Equal Value Json String    ${vpn_data.json()}    name    {{ mesh.vpn_list }}    msg=mesh vpn list

    ${mesh_group_items}=   Json Search List   ${r_id.json()}   definition.regions
    ${res_groups_length}=    Get Length     ${mesh_group_items}
    Should Be Equal As Integers    ${res_groups_length}    {{ mesh.mesh_groups | length }}    msg=mesh groups

{% for mesh_group in mesh.mesh_groups %}

    Should Be Equal Value Json String    ${r_id.json()}    definition.regions[{{loop.index0}}].name    {{ mesh_group.name }}    msg=mesh group name

    ${site_list_id}=    Json Search List    ${r_id.json()}    definition.regions[{{loop.index0}}].siteLists
    ${rec_site_list}=    Create List

    FOR    ${index}    IN    @{site_list_id}
        ${site_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/site/${index}
        ${site_list_name}=    Json Search String    ${site_id.json()}    name
        Append To List    ${rec_site_list}    ${site_list_name}
    END

    ${exp_site_list}=   Create List   {{ mesh_group.site_lists  | default(["not_defined"]) | join('   ') }}
    Lists Should Be Equal   ${rec_site_list}   ${exp_site_list}   ignore_order=True   msg=Site list expexted ${exp_site_list} but received ${rec_site_list} with Mesh {{ mesh.name }}

{% endfor %}

{% endfor %}

{% endif %}
