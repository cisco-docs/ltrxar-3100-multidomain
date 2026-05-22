*** Settings ***
Documentation    Verify Preferred Color Group Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource
Library         String

{% if sdwan.policy_objects is defined and sdwan.policy_objects.preferred_color_groups is defined %}

*** Test Cases ***
Get Preferred Color Group List(s)
   ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/preferredcolorgroup
   Set Suite Variable   ${r}

{% for color_group in sdwan.policy_objects.preferred_color_groups | default([]) %}

Verify Policy Objects Preferred Color Group List {{ color_group.name }}
   ${color_group_id}=    Json Search String    ${r.json()}    data[?name=='{{ color_group.name }}'] | [0].listId
   ${cg_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/preferredcolorgroup/${color_group_id}
   Set Suite Variable    ${cg_id}
   Should Be Equal Value Json String    ${cg_id.json()}    name    {{ color_group.name }}    msg=color group name

   ${color_group}=    Json Search String    ${cg_id.json()}    entries[0].primaryPreference.colorPreference
   ${color_group_list}=    Split String    ${color_group}
   ${primary_colors}=    Create List    {{ color_group.primary_colors | join('   ') }}
   Lists Should Be Equal   ${primary_colors}   ${color_group_list}   ignore_order=True   msg={{ color_group.name }}: Primary Colors mismatch
   Should Be Equal Value Json String   ${cg_id.json()}   entries[0].primaryPreference.pathPreference   {{ color_group.primary_path | default("not_defined") }}   msg={{ color_group.name }}: Primary Path Preference

{% if color_group.secondary_colors is defined %}
   ${color_group}=    Json Search String    ${cg_id.json()}    entries[0].secondaryPreference.colorPreference
   ${color_group_list}=    Split String    ${color_group}
   ${secondary_colors}=    Create List    {{ color_group.secondary_colors | join('   ') }}
   Lists Should Be Equal   ${secondary_colors}   ${color_group_list}   ignore_order=True   msg={{ color_group.name }}: Secondary Colors mismatch
{% else %}
   Should Be Equal Value Json String   ${cg_id.json()}   entries[0].secondaryPreference.colorPreference   not_defined   msg={{ color_group.name }}: Secondary Colors
{% endif %}
   Should Be Equal Value Json String   ${cg_id.json()}   entries[0].secondaryPreference.pathPreference   {{ color_group.secondary_path | default("not_defined") }}   msg={{ color_group.name }}: Secondary Path Preference
{% if color_group.tertiary_colors is defined %}
   ${color_group}=    Json Search String    ${cg_id.json()}    entries[0].tertiaryPreference.colorPreference
   ${color_group_list}=    Split String    ${color_group}
   ${tertiary_colors}=    Create List    {{ color_group.tertiary_colors | join('   ') }}
   Lists Should Be Equal   ${tertiary_colors}  ${color_group_list}   ignore_order=True   msg={{ color_group.name }}: Tertiary Colors mismatch
{% else %}
   Should Be Equal Value Json String   ${cg_id.json()}   entries[0].tertiaryPreference.colorPreference   not_defined   msg={{ color_group.name }}: Tertiary Colors
{% endif %}
   Should Be Equal Value Json String   ${cg_id.json()}   entries[0].tertiaryPreference.pathPreference   {{ color_group.tertiary_path | default("not_defined") }}   msg={{ color_group.name }}: Teritiary Path preference
{% endfor %}
{% endif %}
