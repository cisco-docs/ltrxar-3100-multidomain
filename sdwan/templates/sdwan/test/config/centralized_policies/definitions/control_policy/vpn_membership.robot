*** Settings ***
Documentation   Verify VPN Membership
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    control_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.control_policy.vpn_membership is defined %}

*** Test Cases ***
Get VPN Membership
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vpnmembershipgroup
    Set Suite Variable    ${r}

{% for vpn_membership in sdwan.centralized_policies.definitions.control_policy.vpn_membership | default([]) %}
Verify Centralized Policies Control Policy VPN Membership {{ vpn_membership.name }}
    ${vpn_membership_id}=    Json Search String    ${r.json()}    data[?name=='{{vpn_membership.name }}'] | [0].definitionId
    Run Keyword If    $vpn_membership_id == ''    Fail    VPN Membership '{{vpn_membership.name}}' not found
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vpnmembershipgroup/${vpn_membership_id}

    Should Be Equal Value Json String    ${r_id.json()}    name    {{ vpn_membership.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    description    {{ vpn_membership.description | normalize_special_string }}    msg=description

    ${group_items}=   Json Search List   ${r_id.json()}   definition.sites
    ${res_groups_length}=    Get Length     ${group_items}
    Should Be Equal As Integers    ${res_groups_length}    {{ vpn_membership.groups | length }}    msg=groups

{% for item in vpn_membership.groups %}
    ${site_list_id}=    Json Search String    ${r_id.json()}    definition.sites[{{loop.index0}}].siteList
    ${site_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/site/${site_list_id}
    Should Be Equal Value Json String    ${site_id.json()}    name    {{ item.site_list }}    msg=Site list {{ item.site_list }} with VPN membership {{ vpn_membership.name }}
{% endfor %}

{% for item in vpn_membership.groups %}
{% set test_list = [] %}
{% for item_vpn in item.vpn_lists %}
{% set _ = test_list.append(item_vpn) %}
{% endfor %}

    ${vpn_list_id}=    Json Search List    ${r_id.json()}    definition.sites[{{loop.index0}}].vpnList
    ${rec_vpn_list}=    Create List

    FOR    ${index}    IN    @{vpn_list_id}
        ${vpn_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/vpn/${index}
        ${vpn_list_name}=    Json Search String    ${vpn_id.json()}    name
        Append To List    ${rec_vpn_list}    ${vpn_list_name}
    END

    ${exp_vpn_list}=   Create List   {{ test_list | join('   ') }}
    Lists Should Be Equal   ${rec_vpn_list}   ${exp_vpn_list}   ignore_order=True   msg=VPN list expexted ${exp_vpn_list} but received ${rec_vpn_list} with VPN membership {{ vpn_membership.name }}

{% endfor %}

{% endfor %}

{% endif %}
