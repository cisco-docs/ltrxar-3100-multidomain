*** Settings ***
Documentation   Verify Feature Policies
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies
Resource        ../../sdwan_common.resource

{% if sdwan.centralized_policies.feature_policies is defined%}

*** Test Cases ***
Get Feature Policies
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/vsmart
    Set Suite Variable    ${r}

{% for fp in sdwan.centralized_policies.feature_policies | default([]) %}

Verify Centralized Policies Feature Policies {{ fp.name }}
    ${fp_id}=    Json Search String    ${r.json()}    data[?policyName=='{{ fp.name }}'] | [0].policyId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/vsmart/definition/${fp_id}

    Should Be Equal Value Json String    ${r_id.json()}    policyName    {{ fp.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    policyDescription    {{ fp.description | normalize_special_string }}    msg=description
    
    # hub and spoke topology
    ${hs_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='hubAndSpoke'][].definitionId
    ${hs_ids_length}=    Get Length    ${hs_ids_list}
    Should Be Equal As Integers    ${hs_ids_length}    {{ fp.hub_and_spoke_topology | default([]) | length }}    msg=hub and spoke topology length

    ${hs_dict}=    Create Dictionary
    {% for hs_index in range(fp.hub_and_spoke_topology | default([]) | length()) %}
    ${hst_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/hubandspoke/${hs_ids_list[{{ hs_index }}]}
    ${hst_name}=    Json Search String    ${hst_id.json()}    name
    ${hs_dict}[${hst_name}]=    Set Variable    ${hs_ids_list[{{ hs_index }}]}
    {% endfor %}

{% for fp_hub_and_spoke in fp.hub_and_spoke_topology | default([]) %}
    ${fp_hub_and_spoke_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/hubandspoke/${hs_dict["{{ fp_hub_and_spoke.policy_definition }}"]}
    Should Be Equal Value Json String    ${fp_hub_and_spoke_id.json()}    name    {{ fp_hub_and_spoke.policy_definition }}    msg=hub and spoke topology name
{% endfor %}

    # mesh topology
    ${mesh_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='mesh'][].definitionId
    ${mesh_ids_length}=    Get Length    ${mesh_ids_list}
    Should Be Equal As Integers    ${mesh_ids_length}    {{ fp.mesh_topology | default([]) | length }}    msg=mesh topology length

    ${mesh_dict}=    Create Dictionary
    {% for mesh_index in range(fp.mesh_topology | default([]) | length()) %}
    ${mesh_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/mesh/${mesh_ids_list[{{ mesh_index }}]}
    ${mesh_name}=    Json Search String    ${mesh_id.json()}    name
    ${mesh_dict}[${mesh_name}]=    Set Variable    ${mesh_ids_list[{{ mesh_index }}]}
    {% endfor %}

{% for fp_mesh in fp.mesh_topology | default([]) %}
    ${mesh_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/mesh/${mesh_dict["{{ fp_mesh.policy_definition }}"]}
    Should Be Equal Value Json String    ${mesh_id.json()}    name    {{ fp_mesh.policy_definition }}    msg=mesh topology name
{% endfor %}

    # vpn membership group
    ${vpn_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='vpnMembershipGroup'][].definitionId
    ${vpn_ids_length}=    Get Length    ${vpn_ids_list}
    Should Be Equal As Integers    ${vpn_ids_length}    {{ fp.vpn_membership | default([]) | length }}    msg=vpn membership length

    ${vpn_dict}=    Create Dictionary
    {% for vpn_index in range(fp.vpn_membership | default([]) | length()) %}
    ${vpn_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vpnmembershipgroup/${vpn_ids_list[{{ vpn_index }}]}
    ${vpn_name}=    Json Search String    ${vpn_id.json()}    name
    ${vpn_dict}[${vpn_name}]=    Set Variable    ${vpn_ids_list[{{ vpn_index }}]}
    {% endfor %}

{% for fp_vpn in fp.vpn_membership | default([]) %}
    ${vpn_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vpnmembershipgroup/${vpn_dict["{{ fp_vpn.policy_definition }}"]}
    Should Be Equal Value Json String    ${vpn_id.json()}    name    {{ fp_vpn.policy_definition }}    msg=vpn membership name
{% endfor %}

    # cflowd
    ${cflowd_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='cflowd'][].definitionId
    ${cflowd_ids_length}=    Get Length    ${cflowd_ids_list}
    Should Be Equal As Integers    ${cflowd_ids_length}    {{ fp.cflowd | default([]) | length }}    msg=cflowd length
    
    ${cflowd_dict}=    Create Dictionary
    {% for cflowd_index in range(fp.cflowd | default([]) | length()) %}
    ${cflowd_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/cflowd/${cflowd_ids_list[{{ cflowd_index }}]}
    ${cflowd_name}=    Json Search String    ${cflowd_id.json()}    name
    ${cflowd_dict}[${cflowd_name}]=    Set Variable    ${cflowd_ids_list[{{ cflowd_index }}]}
    {% endfor %}

{% for cflowd in fp.cflowd | default([]) %}
    ${cflowd_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/cflowd/${cflowd_dict["{{ cflowd.policy_definition }}"]}
    Should Be Equal Value Json String    ${cflowd_id.json()}    name    {{ cflowd.policy_definition }}    msg=cflowd name

    # cflowd Site List
    ${cflowd_site_list_raw}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='cflowd' && definitionId=='${cflowd_dict["{{ cflowd.policy_definition }}"]}'] | [0].entries[].siteLists
    IF    ${cflowd_site_list_raw} == []
        ${cflowd_site_list_length}=    Set Variable    0
        ${cflowd_site_list}=    Create List
    ELSE
        ${cflowd_site_list}=    Evaluate    list(__import__('itertools').chain.from_iterable($cflowd_site_list_raw))
        ${cflowd_site_list_length} =    Get Length    ${cflowd_site_list}
    END
    Log    ${cflowd_site_list}
    ${site_list_name}=    Create List
    FOR    ${id}    IN    @{cflowd_site_list}
        ${site_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${id}
        ${site_list_id_name}=    Json Search String    ${site_list_id.json()}    name
        Append To List    ${site_list_name}    ${site_list_id_name}
    END
    Log    ${site_list_name}
    ${exp_cflowd_site_list}=    Create List    {{ cflowd.site_lists | default([]) | join('   ') }}
    Lists Should Be Equal    ${site_list_name}    ${exp_cflowd_site_list}    ignore_order=True    msg=cflowd site lists for {{ cflowd.policy_definition }}
{% endfor %}

    # custom control topology
    ${cct_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='control'][].definitionId
    ${cct_ids_length}=    Get Length    ${cct_ids_list}
    Should Be Equal As Integers    ${cct_ids_length}    {{ fp.custom_control_topology | default([]) | length }}    msg=custom control topology length
    ${cct_dict}=    Create Dictionary
    {% for cct_index in range(fp.custom_control_topology | default([]) | length()) %}
    ${cctt_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/control/${cct_ids_list[{{ cct_index }}]}
    ${cct_name}=    Json Search String    ${cctt_id.json()}    name
    ${cct_dict}[${cct_name}]=    Set Variable    ${cct_ids_list[{{ cct_index }}]}
    {% endfor %}

{% for cct_policy in fp.custom_control_topology | default([]) %}
    ${cct_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/control/${cct_dict["{{ cct_policy.policy_definition }}"]}
    Should Be Equal Value Json String    ${cct_id.json()}    name    {{ cct_policy.policy_definition }}    msg=custom control topology name

    # custom control topology Site List In
    ${cct_sr_sl_id_in_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='in'] | [0].siteLists
    IF    ${cct_sr_sl_id_in_list} == []
        ${cct_sr_sl_id_in_list_length}=    Set Variable    0
    ELSE
        ${cct_sr_sl_id_in_list_length} =    Get Length    ${cct_sr_sl_id_in_list}
    END
    Should Be Equal As Integers    ${cct_sr_sl_id_in_list_length}    {{ (cct_policy.site_region | default({})).site_lists_in | default([]) | length }}    msg=custom control topology site lists in length for {{ cct_policy.policy_definition }}
    ${cct_sr_sl_id_in_name_list}=    Create List
    FOR    ${cct_sr_sl_id_in}    IN    @{cct_sr_sl_id_in_list}
        ${site_list_in_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${cct_sr_sl_id_in}
        ${site_in_name}=    Json Search String    ${site_list_in_id.json()}    name
        Append To List    ${cct_sr_sl_id_in_name_list}    ${site_in_name}
    END
    ${exp_cct_sr_sl_id_in}=    Create List    {{ (cct_policy.site_region | default({})).site_lists_in | default([]) | join('   ') }}
    Lists Should Be Equal    ${cct_sr_sl_id_in_name_list}    ${exp_cct_sr_sl_id_in}    ignore_order=True    msg=custom control topology site lists in for {{ cct_policy.policy_definition }}
    
    # custom control topology Site List Out
    ${cct_sr_sl_id_out_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='out'] | [0].siteLists
    IF    ${cct_sr_sl_id_out_list} == []
        ${cct_sr_sl_id_out_list_length}=    Set Variable    0
    ELSE
        ${cct_sr_sl_id_out_list_length} =    Get Length    ${cct_sr_sl_id_out_list}
    END
    Should Be Equal As Integers    ${cct_sr_sl_id_out_list_length}    {{ (cct_policy.site_region | default({})).site_lists_out | default([]) | length }}    msg=custom control topology site lists out length for {{ cct_policy.policy_definition }}
    ${cct_sr_sl_id_out_name_list}=    Create List
    FOR    ${cct_sr_sl_id_out}    IN    @{cct_sr_sl_id_out_list}
        ${site_list_out_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${cct_sr_sl_id_out}
        ${site_out_name}=    Json Search String    ${site_list_out_id.json()}    name
        Append To List    ${cct_sr_sl_id_out_name_list}    ${site_out_name}
    END
    ${exp_cct_sr_sl_id_out}=    Create List    {{ (cct_policy.site_region | default({})).site_lists_out | default([]) | join('   ') }}
    Lists Should Be Equal    ${cct_sr_sl_id_out_name_list}    ${exp_cct_sr_sl_id_out}    ignore_order=True    msg=custom control topology site lists out for {{ cct_policy.policy_definition }}

    # custom control topology Region List In
    ${cct_sr_rl_id_in_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='in'] | [0].regionLists
    IF    ${cct_sr_rl_id_in_list} == []
        ${cct_sr_rl_id_in_list_length}=    Set Variable    0
    ELSE
        ${cct_sr_rl_id_in_list_length} =    Get Length    ${cct_sr_rl_id_in_list}
    END
    Should Be Equal As Integers    ${cct_sr_rl_id_in_list_length}    {{ (cct_policy.site_region | default({})).region_lists_in | default([]) | length }}    msg=custom control topology region lists in length for {{ cct_policy.policy_definition }}
    ${cct_sr_rl_id_in_name_list}=    Create List
    FOR    ${cct_sr_rl_id_in}    IN    @{cct_sr_rl_id_in_list}
        ${rl_in_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${cct_sr_rl_id_in}
        ${rl_in_name}=    Json Search String    ${rl_in_id.json()}    name
        Append To List    ${cct_sr_rl_id_in_name_list}    ${rl_in_name}
    END
    ${exp_cct_sr_rl_id_in}=    Create List    {{ (cct_policy.site_region | default({})).region_lists_in | default([]) | join('   ') }}
    Lists Should Be Equal    ${cct_sr_rl_id_in_name_list}    ${exp_cct_sr_rl_id_in}    ignore_order=True    msg=custom control topology region lists in for {{ cct_policy.policy_definition }}

    # custom control topology Region List Out
    ${cct_sr_rl_id_out_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='out'] | [0].regionLists
    IF    ${cct_sr_rl_id_out_list} == []
        ${cct_sr_rl_id_out_list_length}=    Set Variable    0
    ELSE
        ${cct_sr_rl_id_out_list_length} =    Get Length    ${cct_sr_rl_id_out_list}
    END
    Should Be Equal As Integers    ${cct_sr_rl_id_out_list_length}    {{ (cct_policy.site_region | default({})).region_lists_out | default([]) | length }}    msg=custom control topology region lists out length for {{ cct_policy.policy_definition }}
    ${cct_sr_rl_id_out_name_list}=    Create List
    FOR    ${cct_sr_rl_id_out}    IN    @{cct_sr_rl_id_out_list}
        ${rl_out_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${cct_sr_rl_id_out}
        ${rl_out_name}=    Json Search String    ${rl_out_id.json()}    name
        Append To List    ${cct_sr_rl_id_out_name_list}    ${rl_out_name}
    END
    ${exp_cct_sr_rl_id_out}=    Create List    {{ (cct_policy.site_region | default({})).region_lists_out | default([]) | join('   ') }}
    Lists Should Be Equal    ${cct_sr_rl_id_out_name_list}    ${exp_cct_sr_rl_id_out}    ignore_order=True    msg=custom control topology region lists out for {{ cct_policy.policy_definition }}

    # custom control topology Region In
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='in'] | [0].regionIds[0]    {{ (cct_policy.site_region | default({})).region_in | default("not_defined") }}    msg=custom control topology region in for {{ cct_policy.policy_definition }}
    
    # custom control topology Region Out
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.assembly[?type=='control' && definitionId=='${cct_dict["{{ cct_policy.policy_definition }}"]}'] | [0].entries[?direction=='out'] | [0].regionIds[0]    {{ (cct_policy.site_region | default({})).region_out | default("not_defined") }}    msg=custom control topology region out for {{ cct_policy.policy_definition }}
{% endfor %}

    # application aware routing
    ${aar_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='appRoute'][].definitionId
    ${aar_ids_length}=    Get Length    ${aar_ids_list}
    Should Be Equal As Integers    ${aar_ids_length}    {{ fp.application_aware_routing | default([]) | length }}    msg=application aware routing length
    ${aar_dict}=    Create Dictionary
    {% for aar_index in range(fp.application_aware_routing | default([]) | length()) %}
    ${aar_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/approute/${aar_ids_list[{{ aar_index }}]}
    ${aar_name}=    Json Search String    ${aar_id.json()}    name
    ${aar_dict}[${aar_name}]=    Set Variable    ${aar_ids_list[{{ aar_index }}]}
    {% endfor %}

{% for fp_app_route in fp.application_aware_routing | default([]) %}
    ${aar_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/approute/${aar_dict["{{ fp_app_route.policy_definition }}"]}
    Should Be Equal Value Json String    ${aar_id.json()}    name    {{ fp_app_route.policy_definition }}    msg=application aware routing name

    # application aware routing Site List
    ${aar_sl_id_list_raw}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='appRoute' && definitionId=='${aar_dict["{{ fp_app_route.policy_definition }}"]}'] | [0].entries[].siteLists
    IF    ${aar_sl_id_list_raw} == []
        ${aar_sl_id_list_length}=    Set Variable    0
        ${aar_sl_id_list}=    Create List
    ELSE
        ${aar_sl_id_list}=    Evaluate    list(__import__('itertools').chain.from_iterable($aar_sl_id_list_raw))
        ${aar_sl_id_list_length} =    Get Length    ${aar_sl_id_list}
    END
    Should Be Equal As Integers    ${aar_sl_id_list_length}    {{ (fp_app_route.site_region_vpn | default({})).site_lists | default([]) | length }}    msg=application aware routing site lists length for {{ fp_app_route.policy_definition }}
    ${aar_sl_id_name_list}=    Create List
    FOR    ${id}    IN    @{aar_sl_id_list}
        ${site_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${id}
        ${site_list_name}=    Json Search String    ${site_list_id.json()}    name
        Append To List    ${aar_sl_id_name_list}    ${site_list_name}
    END
    ${exp_aar_sl_id}=    Create List    {{ (fp_app_route.site_region_vpn | default({})).site_lists | default([]) | join('   ') }}
    Lists Should Be Equal    ${aar_sl_id_name_list}    ${exp_aar_sl_id}    ignore_order=True    msg=application aware routing site lists for {{ fp_app_route.policy_definition }}

    # application aware routing Region List
    ${aar_rl_id_list_raw}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='appRoute' && definitionId=='${aar_dict["{{ fp_app_route.policy_definition }}"]}'] | [0].entries[].regionLists
    IF    ${aar_rl_id_list_raw} == []
        ${aar_rl_id_list_length}=    Set Variable    0
        ${aar_rl_id_list}=    Create List
    ELSE
        ${aar_rl_id_list}=    Evaluate    list(__import__('itertools').chain.from_iterable($aar_rl_id_list_raw))
        ${aar_rl_id_list_length} =    Get Length    ${aar_rl_id_list}
    END
    ${aar_rl_id_name_list}=    Create List
    FOR    ${id}    IN    @{aar_rl_id_list}
        ${region_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${id}
        ${region_list_name}=    Json Search String    ${region_list_id.json()}    name
        Append To List    ${aar_rl_id_name_list}    ${region_list_name}
    END
    {% if (fp_app_route.site_region_vpn | default({})).region_list | default([]) == [] %}
    ${exp_aar_rl_id}=    Create List
    {% else %}
    ${exp_aar_rl_id}=    Create List    {{ (fp_app_route.site_region_vpn | default({})).region_list }}
    {% endif %}
    Lists Should Be Equal    ${aar_rl_id_name_list}    ${exp_aar_rl_id}    ignore_order=True    msg=application aware routing region list for {{ fp_app_route.policy_definition }}

    # application aware routing vpn lists
    ${aar_vl_id_list_raw}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='appRoute' && definitionId=='${aar_dict["{{ fp_app_route.policy_definition }}"]}'] | [0].entries[].vpnLists
    IF    ${aar_vl_id_list_raw} == []
        ${aar_vl_id_list_length}=    Set Variable    0
        ${aar_vl_id_list}=    Create List
    ELSE
        ${aar_vl_id_list}=    Evaluate    list(__import__('itertools').chain.from_iterable($aar_vl_id_list_raw))
        ${aar_vl_id_list_length} =    Get Length    ${aar_vl_id_list}
    END
    Should Be Equal As Integers    ${aar_vl_id_list_length}    {{ (fp_app_route.site_region_vpn | default({})).vpn_lists | default([]) | length }}    msg=application aware routing vpn lists length for {{ fp_app_route.policy_definition }}
    ${aar_vl_id_name_list}=    Create List
    FOR    ${id}    IN    @{aar_vl_id_list}
        ${vpn_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${id}
        ${vpn_list_name}=    Json Search String    ${vpn_list_id.json()}    name
        Append To List    ${aar_vl_id_name_list}    ${vpn_list_name}
    END
    ${exp_aar_vl_id}=    Create List    {{ (fp_app_route.site_region_vpn | default({})).vpn_lists | default([]) | join('   ') }}
    Lists Should Be Equal    ${aar_vl_id_name_list}    ${exp_aar_vl_id}    ignore_order=True    msg=application aware routing vpn lists for {{ fp_app_route.policy_definition }}

    # application aware routing region
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.assembly[?type=='appRoute' && definitionId=='${aar_dict["{{ fp_app_route.policy_definition }}"]}'] | [0].entries[*].regionIds[0]    {{ (fp_app_route.site_region_vpn | default({})).region | default("not_defined") }}    msg=application aware routing region for {{ fp_app_route.policy_definition }}
{% endfor %}

    # traffic data
    ${td_ids_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='data'][].definitionId
    ${td_ids_length}=    Get Length    ${td_ids_list}
    Should Be Equal As Integers    ${td_ids_length}    {{ fp.traffic_data | default([]) | length }}    msg=traffic data length
    ${td_dict}=    Create Dictionary
    {% for td_index in range(fp.traffic_data | default([]) | length()) %}
    ${td_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/data/${td_ids_list[{{ td_index }}]}
    ${td_name}=    Json Search String    ${td_id.json()}    name
    ${td_dict}[${td_name}]=    Set Variable    ${td_ids_list[{{ td_index }}]}
    {% endfor %}

{% for fp_traffic_data in fp.traffic_data | default([]) %}
    ${td_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/data/${td_dict["{{ fp_traffic_data.policy_definition }}"]}
    Should Be Equal Value Json String    ${td_id.json()}    name    {{ fp_traffic_data.policy_definition }}    msg=traffic data name

{% for srv in fp_traffic_data.site_region_vpn | default([]) %}
    # traffic data Site List
    ${td_sr_sl_id_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='data' && definitionId=='${td_dict["{{ fp_traffic_data.policy_definition }}"]}'] | [0].entries[?direction=='{{ srv.direction }}'] | [0].siteLists
    IF    ${td_sr_sl_id_list} == []
        ${td_sr_sl_id_list_length}=    Set Variable    0
    ELSE
        ${td_sr_sl_id_list_length} =    Get Length    ${td_sr_sl_id_list}
    END
    Should Be Equal As Integers    ${td_sr_sl_id_list_length}    {{ srv.site_lists | default([]) | length }}    msg=traffic data site lists length for {{ fp_traffic_data.policy_definition }}
    ${td_sr_sl_id_name_list}=    Create List
    FOR    ${id}    IN    @{td_sr_sl_id_list}
        ${site_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${id}
        ${site_list_name}=    Json Search String    ${site_list_id.json()}    name
        Append To List    ${td_sr_sl_id_name_list}    ${site_list_name}
    END
    ${exp_td_sr_sl_id}=    Create List    {{ srv.site_lists | default([]) | join('   ') }}
    Lists Should Be Equal    ${td_sr_sl_id_name_list}    ${exp_td_sr_sl_id}    ignore_order=True    msg=traffic data site lists for {{ fp_traffic_data.policy_definition }} and direction {{ srv.direction }}

    # traffic data vpn lists
    ${td_sr_vl_id_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='data' && definitionId=='${td_dict["{{ fp_traffic_data.policy_definition }}"]}'] | [0].entries[?direction=='{{ srv.direction }}'] | [0].vpnLists
    IF    ${td_sr_vl_id_list} == []
        ${td_sr_vl_id_list_length}=    Set Variable    0
    ELSE
        ${td_sr_vl_id_list_length} =    Get Length    ${td_sr_vl_id_list}
    END
    Should Be Equal As Integers    ${td_sr_vl_id_list_length}    {{ srv.vpn_lists | default([]) | length }}    msg=traffic data vpn lists length for {{ fp_traffic_data.policy_definition }}
    ${td_sr_vl_id_name_list}=    Create List
    FOR    ${id}    IN    @{td_sr_vl_id_list}
        ${vpn_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${id}
        ${vpn_list_name}=    Json Search String    ${vpn_list_id.json()}    name
        Append To List    ${td_sr_vl_id_name_list}    ${vpn_list_name}
    END
    ${exp_td_sr_vl_id}=    Create List    {{ srv.vpn_lists | default([]) | join('   ') }}
    Lists Should Be Equal    ${td_sr_vl_id_name_list}    ${exp_td_sr_vl_id}    ignore_order=True    msg=traffic data vpn lists for {{ fp_traffic_data.policy_definition }} and direction {{ srv.direction }}

    # traffic data region list
    ${td_sr_rl_id_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='data' && definitionId=='${td_dict["{{ fp_traffic_data.policy_definition }}"]}'] | [0].entries[?direction=='{{ srv.direction }}'] | [0].regionLists
    IF    ${td_sr_rl_id_list} == []
        ${td_sr_rl_id_list_length}=    Set Variable    0
    ELSE
        ${td_sr_rl_id_list_length} =    Get Length    ${td_sr_rl_id_list}
    END
    ${td_sr_rl_id_name_list}=    Create List
    FOR    ${id}    IN    @{td_sr_rl_id_list}
        ${region_list_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/region/${id}
        ${region_list_name}=    Json Search String    ${region_list_id.json()}    name
        Append To List    ${td_sr_rl_id_name_list}    ${region_list_name}
    END
    {% if (srv.region_list | default([])) == [] %}
    ${exp_td_sr_rl_id}=    Create List
    {% else %}
    ${exp_td_sr_rl_id}=    Create List    {{ srv.region_list }}
    {% endif %}
    Lists Should Be Equal    ${td_sr_rl_id_name_list}    ${exp_td_sr_rl_id}    ignore_order=True    msg=traffic data region list for {{ fp_traffic_data.policy_definition }} and direction {{ srv.direction }}

    # traffic data region
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.assembly[?type=='data' && definitionId=='${td_dict["{{ fp_traffic_data.policy_definition }}"]}'] | [0].entries[?direction=='{{ srv.direction }}'] | [0].regionIds[0]    {{ srv.region | default("not_defined") }}    msg=traffic data region for {{ fp_traffic_data.policy_definition }} and direction {{ srv.direction }}
    
    # traffic data direction
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.assembly[?type=='data' && definitionId=='${td_dict["{{ fp_traffic_data.policy_definition }}"]}'] | [0].entries[?direction=='{{ srv.direction }}'] | [0].direction    {{ srv.direction }}    msg=traffic data direction for {{ fp_traffic_data.policy_definition }} and direction {{ srv.direction }}

{% endfor %}

{% endfor %}

{% endfor %}

{% endif %}