*** Settings ***
Documentation    Verify VPN Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.vpn_lists is defined %}

*** Test Cases ***
Get Vpn List(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn
    Set Suite Variable   ${r}

{% for vpn in sdwan.policy_objects.vpn_lists | default([]) %}

Verify Policy Objects Vpn List {{ vpn.name }}
    ${vpn_id}=    Json Search String    ${r.json()}    data[?name=='{{vpn.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/vpn/${vpn_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ vpn.name }}

{% if vpn.vpn_id_ranges is defined %}
{%- set vpn_range_list = [] -%}
{% for item in vpn.vpn_id_ranges | default([]) %}
{%- set test_list = [] -%}
{%- set _ = test_list.append(item.from) -%}
{%- set _ = test_list.append(item.to) -%}
{% set vpn_id_range_test = '-'.join(test_list | map('string')) %}
{%- set _ = vpn_range_list.append(vpn_id_range_test) -%}

{% endfor %}
{% endif %}

{% if vpn.vpn_ids is defined and vpn.vpn_id_ranges is defined%}
{% set vpn_string = vpn.vpn_ids | map('string') | join(',') %}
{% set new_id_list = vpn_string.split(',') %}
{% set vpn_list = new_id_list + vpn_range_list %}
    ${id_list}=   Create List   {{ vpn_list | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].vpn  ${id_list}   msg=vpn ids or ranges are
{% elif vpn.vpn_ids is defined %}
    ${list}=   Create List   {{ vpn.vpn_ids | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].vpn  ${list}   msg=vpn ids are
{% elif vpn.vpn_id_ranges is defined %}
    ${id_list}=   Create List   {{ vpn_range_list | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].vpn  ${id_list}   msg=vpn id ranges are
{% endif %}

{% endfor %}
{% endif %}
