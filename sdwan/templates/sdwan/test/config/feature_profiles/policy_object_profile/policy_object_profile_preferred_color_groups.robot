*** Settings ***
Documentation   Verify Feature Profile Policy Object Profile Preferred Color Group Lists Configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    policy_object_profile    preferred_color_groups
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles.policy_object_profile.preferred_color_groups is defined %}

*** Test Cases ***
Get Feature Profiles
   ${f}=   GET On Session With Retry   sdwan_manager   /dataservice/v1/feature-profile/sdwan
   Set Suite Variable   ${f}
   Log   ${f.json()}

Get Preferred Color Group List(s)
   ${policy_profile_id}=    Json Search String    ${f.json()}    [?profileType=='policy-object'].profileId | [0]
   ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${policy_profile_id}/preferred-color-group
   Set Suite Variable    ${r}
   Log    ${r.json()}
   Should Be Equal Value Json List Length    ${r.json()}    data    {{ sdwan.feature_profiles.policy_object_profile.get('preferred_color_groups',[]) | length }}    msg=Preferred Color Group Length

{% for p_color_group in sdwan.feature_profiles.policy_object_profile.preferred_color_groups | default([]) %}
   ${pri_color_list}=    Json Search List    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].primaryPreference.colorPreference.value | [0]
   ${primary_colors}=    Create List    {{ p_color_group.primary_colors | join('   ') }}
   Lists Should Be Equal    ${pri_color_list}    ${primary_colors}    ignore_order=True    msg={{ p_color_group.name }}: Primary Colors mismatch
   Should Be Equal Value Json String    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].primaryPreference.pathPreference.value | [0]    {{ p_color_group.primary_path_preference | default("not_defined") }}    msg=Primary Path Preference mismatch for {{ p_color_group.name }}

{% if p_color_group.secondary_colors is defined %}
      ${sec_color_list}=    Json Search List    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].secondaryPreference.colorPreference.value | [0]
      ${secondary_colors}=    Create List    {{ p_color_group.secondary_colors | join('   ') }}
      Lists Should Be Equal    ${sec_color_list}    ${secondary_colors}    ignore_order=True    msg={{ p_color_group.name }}: Secondary Colors mismatch
{% else %}
      ${No_Sec_Colors}=    Json Search    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].secondaryPreference | [0]
      ${No_Sec_Color_Keys}=    Get Dictionary Keys    ${No_Sec_Colors}
      List Should Not Contain Value    ${No_Sec_Color_Keys}    colorPreference
{% endif %}
      Should Be Equal Value Json String    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].secondaryPreference.pathPreference.value | [0]    {{ p_color_group.secondary_path_preference | default("not_defined") }}    msg=Secondary Path Preference mismatch for {{ p_color_group.name }}

{% if p_color_group.tertiary_colors is defined %}
      ${ter_color_list}=    Json Search List    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].tertiaryPreference.colorPreference.value | [0]
      ${tertiary_colors}=    Create List    {{ p_color_group.tertiary_colors | join('   ') }}
      Lists Should Be Equal    ${ter_color_list}    ${tertiary_colors}    ignore_order=True    msg={{ p_color_group.name }}: Tertiary Colors mismatch
{% else %}
      ${No_Ter_Colors}=    Json Search    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].tertiaryPreference | [0]
      ${No_Ter_Color_Keys}=    Get Dictionary Keys    ${No_Ter_Colors}
      List Should Not Contain Value    ${No_Ter_Color_Keys}    colorPreference
{% endif %}
      Should Be Equal Value Json String    ${r.json()}    data[?payload.name=='{{ p_color_group.name }}'].payload.data.entries[0].tertiaryPreference.pathPreference.value | [0]    {{ p_color_group.tertiary_path_preference | default("not_defined") }}    msg=Tertiary Path Preference mismatch for {{ p_color_group.name }}
{% endfor %}
{% endif %}