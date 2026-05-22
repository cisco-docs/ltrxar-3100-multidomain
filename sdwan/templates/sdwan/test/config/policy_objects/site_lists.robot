*** Settings ***
Documentation    Verify Site Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.site_lists is defined %}

*** Test Cases ***
Get Site List(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site
    Set Suite Variable   ${r}

{% for site in sdwan.policy_objects.site_lists | default([]) %}

Verify Policy Objects Site List {{site.name }}
    ${site_id}=    Json Search String    ${r.json()}    data[?name=='{{site.name}}'] | [0].listId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/site/${site_id}
    Should Be Equal Value Json String    ${r_id.json()}    name    {{ site.name }}    msg=site name

{% if site.site_id_ranges is defined %}
{%- set site_range_list = [] -%}
{% for item in site.site_id_ranges | default([]) %}
{%- set test_list = [] -%}
{%- set _ = test_list.append(item.from) -%}
{%- set _ = test_list.append(item.to) -%}
{% set site_id_range_test = '-'.join(test_list | map('string')) %}
{%- set _ = site_range_list.append(site_id_range_test) -%}

{% endfor %}
{% endif %}

{% if site.site_ids is defined and site.site_id_ranges is defined%}
{% set site_string = site.site_ids | map('string') | join(',') %}
{% set new_id_list = site_string.split(',') %}
{% set site_list = new_id_list + site_range_list %}
    ${id_list}=   Create List   {{ site_list | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].siteId   ${id_list}   msg=site ids or ranges are
{% elif site.site_ids is defined %}
    ${list}=   Create List   {{ site.site_ids | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].siteId   ${list}   msg=site ids are
{% elif site.site_id_ranges is defined %}
    ${id_list} =   Create List   {{ site_range_list | join('   ') }}
    Should Be Equal Value Json List   ${r_id.json()}   entries[].siteId   ${id_list}   msg=site id ranges are
{% endif %}

{% endfor %}
{% endif %}
