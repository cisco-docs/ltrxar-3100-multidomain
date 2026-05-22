*** Settings **
Documentation    Verify Router Policy Configuration
Suite Setup    Login SDWAN Manager
Suite Teardown    Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    localized_policies
Resource    ../../../sdwan_common.resource

{% if sdwan.localized_policies.definitions.route_policies is defined %}

*** Test Cases ***
Get Route Policy
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vedgeroute
    Set Suite Variable    ${r}

{% for route_policy in sdwan.localized_policies.definitions.route_policies | default([]) %}

Verify Localized Policies Route Policy {{ route_policy.name }}
    ${route_policy_id}=   Json Search String   ${r.json()}   data[?name=='{{ route_policy.name }}'] | [0].definitionId
    Run Keyword If    $route_policy_id == ''    Fail    Route Policy '{{ route_policy.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/vedgeroute/${route_policy_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ route_policy.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ route_policy.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    defaultAction.type    {{ route_policy.default_action }}    msg=default action type

    Should Be Equal Value Json List Length    ${r_id.json()}    sequences    {{ route_policy.sequences | default([]) | length }}    msg=sequences

{% for sequence in route_policy.sequences | default([]) %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceId    {{ sequence.id }}    msg=id
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceName    {{ sequence.name | default((defaults.sdwan.localized_policies.definitions.route_policies.sequences.name) if defaults is defined else "not_defined") }}    msg=name
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].sequenceIpType    {{ sequence.ip_type | default((defaults.sdwan.localized_policies.definitions.route_policies.sequences.ip_type) if defaults is defined else "not_defined") }}    msg=ip type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].baseAction    {{ sequence.base_action }}    msg=base action

    ${as_path_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='asPath'] | [0].ref
    IF    $as_path_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='asPath'] | [0].ref    {{ sequence.match_criterias.as_path_list | default("not_defined") }}    msg=as path list
    ELSE
        ${as_path_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/aspath/${as_path_id}
        Should Be Equal Value Json String    ${as_path_match_id.json()}    name    {{ sequence.match_criterias.as_path_list | default("not_defined") }}    msg=as path list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='localPreference'] | [0].value    {{ sequence.match_criterias.bgp_local_preference | default("not_defined") }}    msg=bgp local preference

    ${expanded_c_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='expandedCommunity'] | [0].ref
    IF    $expanded_c_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='expandedCommunity'] | [0].ref    {{ sequence.match_criterias.expanded_community_list | default("not_defined") }}    msg=expanded community list
    ELSE
        ${expanded_c_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/expandedcommunity/${expanded_c_id}
        Should Be Equal Value Json String    ${expanded_c_match_id.json()}    name    {{ sequence.match_criterias.expanded_community_list | default("not_defined") }}    msg=expanded community list
    END
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='expandedCommunityInline'] | [0].vipVariableName    {{ sequence.match_criterias.expanded_community_list_variable | default("not_defined") }}    msg=expanded community list variable

    ${extended_c_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='extCommunity'] | [0].ref
    IF    $extended_c_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='extCommunity'] | [0].ref    {{ sequence.match_criterias.extended_community_list | default("not_defined") }}    msg=extended community list
    ELSE
        ${extended_c_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/extcommunity/${extended_c_id}
        Should Be Equal Value Json String    ${extended_c_match_id.json()}    name    {{ sequence.match_criterias.extended_community_list | default("not_defined") }}    msg=extended community list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='metric'] | [0].value    {{ sequence.match_criterias.metric | default("not_defined") }}    msg=metric

    ${next_hop_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='nextHop'] | [0].ref
    IF    $next_hop_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='nextHop'] | [0].ref    {{ sequence.match_criterias.next_hop_prefix_list | default("not_defined") }}    msg=next hop prefix list
    ELSE
        ${next_hop_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/prefix/${next_hop_id}
        Should Be Equal Value Json String    ${next_hop_match_id.json()}    name    {{ sequence.match_criterias.next_hop_prefix_list | default("not_defined") }}    msg=next hop prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='ompTag'] | [0].value    {{ sequence.match_criterias.omp_tag | default("not_defined") }}    msg=omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='origin'] | [0].value    {{ sequence.match_criterias.origin | default("not_defined") }}    msg=origin
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='ospfTag'] | [0].value    {{ sequence.match_criterias.ospf_tag | default("not_defined") }}    msg=ospf tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='peer'] | [0].value    {{ sequence.match_criterias.peer | default("not_defined") }}    msg=peer

    ${prefix_list_id}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='address'] | [0].ref 
    IF    $prefix_list_id == ''
        Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='address'] | [0].ref    {{ sequence.match_criterias.prefix_list | default("not_defined") }}    msg=prefix list
    ELSE
        ${prefix_list_match_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/prefix/${prefix_list_id}
        Should Be Equal Value Json String    ${prefix_list_match_id.json()}    name    {{ sequence.match_criterias.prefix_list | default("not_defined") }}    msg=prefix list
    END

    ${standard_c_list}=    Json Search    ${r_id.json()}    sequences[{{loop.index0}}].match.entries[?field=='advancedCommunity' || field=='community'] | [0]
    ${advanced_c_list}=    Json Search List    ${standard_c_list}    refs
    IF    ${advanced_c_list} != []
        ${advanced_c_list}=    Evaluate    list(__import__('itertools').chain.from_iterable($advanced_c_list))
    END
    ${community_list}=   Json Search List    ${standard_c_list}    ref
    ${c_list_refs} =    Combine Lists    ${advanced_c_list}    ${community_list}
    IF   $c_list_refs != []
        Should Be Equal Value Json List Length    ${c_list_refs}    @    {{ (sequence.match_criterias.standard_community_lists | default([])) | length }}    msg=standard community list length
        ${exp_community_list}=    Create List    {{ (sequence.match_criterias.standard_community_lists | default([])) | join('   ') }}
        FOR    ${id}    IN    @{c_list_refs}
            ${list}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/community/${id}
            ${c_name}=    Json Search String    ${list.json()}    name
            List Should Contain Value    ${exp_community_list}    ${c_name}    msg=standard community lists
        END
    ELSE
        Should Be Equal As Strings    {{ sequence.match_criterias.standard_community_lists | default("not_defined") }}    not_defined    msg=standard community list
    END
    Should Be Equal Value Json String    ${standard_c_list}    matchFlag    {{ sequence.match_criterias.standard_community_lists_criteria | default("not_defined") }}    msg=standard community lists criteria

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='aggregator'] | [0].value.aggregator    {{ (sequence.actions | default({})).aggregator | default("not_defined") }}    msg=aggregator
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='aggregator'] | [0].value.ipAddress    {{ (sequence.actions | default({})).aggregator_ip | default("not_defined") }}    msg=aggregator ip
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='atomicAggregate'] | [0].value    {{ ((sequence.actions | default({})).atomic_aggregate | default("not_defined") | lower) if (sequence.actions | default({})).atomic_aggregate | default("not_defined") != "not_defined" else "not_defined" }}    msg=atomic aggregate

{% if (sequence.actions | default({})).communities | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='community'] | [0].value    {{ (sequence.actions | default({})).communities | default("not_defined") }}    msg=no communities defined
{% else %}
    ${com_list}=    Create List    {{ (sequence.actions | default({})).communities | default([]) | join('   ') }}
    ${community}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='community'] | [0].value
    ${rec_com_list}=    Split String    ${community}
    Lists Should Be Equal    ${rec_com_list}    ${com_list}    ignore_order=True    msg=communities
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='community'] | [0].vipVariableName    {{ (sequence.actions | default({})).community_variable | default("not_defined") }}    msg=community variable

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='communityAdditive'] | [0].value    {{ ((sequence.actions | default({})).community_additive | default("not_defined") | lower) if (sequence.actions | default({})).community_additive | default("not_defined") != "not_defined" else "not_defined" }}    msg=community additive

{% if (sequence.actions | default({})).exclude_as_paths | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='asPath'] | [0].value.exclude    {{ (sequence.actions | default({})).exclude_as_paths | default("not_defined") }}    msg=no exclude as path defined
{% else %}
    ${exclude_as_path_list}=    Create List    {{ (sequence.actions | default({})).exclude_as_paths | default([]) | join('   ') }}
    ${path}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='asPath'] | [0].value.exclude
    ${rec_path}=    Split String    ${path}
    Lists Should Be Equal    ${rec_path}    ${exclude_as_path_list}    ignore_order=True    msg=exclude as paths
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='localPreference'] | [0].value    {{ (sequence.actions | default({})).local_preference | default("not_defined") }}    msg=local preference
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='metric'] | [0].value    {{ (sequence.actions | default({})).metric | default("not_defined") }}    msg=metric
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='metricType'] | [0].value    {{ (sequence.actions | default({})).metric_type | default("not_defined") }}    msg=metric type
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='nextHop'] | [0].value    {{ (sequence.actions | default({})).next_hop | default("not_defined") }}    msg=next hop
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='ompTag'] | [0].value     {{ (sequence.actions | default({})).omp_tag | default("not_defined") }}    msg=omp tag
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='origin'] | [0].value     {{ (sequence.actions | default({})).origin | default("not_defined") }}    msg=origin
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='originator'] | [0].value     {{ (sequence.actions | default({})).originator | default("not_defined") }}    msg=originator
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='ospfTag'] | [0].value     {{ (sequence.actions | default({})).ospf_tag | default("not_defined") }}    msg=ospf tag

{% if (sequence.actions | default({})).prepend_as_paths | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='asPath'].value.prepend    {{ (sequence.actions | default({})).prepend_as_paths | default("not_defined") }}    msg=no prepend as path defined
{% else %}
    ${prepend_as_path_list}=    Create List    {{ (sequence.actions | default({})).prepend_as_paths | default([]) | join('   ') }}
    ${pre_path}=    Json Search String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='asPath'].value.prepend
    ${rec_pre_path}=    Split String    ${pre_path}
    Lists Should Be Equal    ${rec_pre_path}    ${prepend_as_path_list}    ignore_order=True    msg=prepend as paths
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    sequences[{{loop.index0}}].actions[?type=='set'] | [0].parameter[?field=='weight'] | [0].value    {{ (sequence.actions | default({})).weight | default("not_defined") }}    msg=weight

{% endfor %}

{% endfor %}

{% endif %}
