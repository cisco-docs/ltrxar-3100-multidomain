*** Settings ***
Documentation   Verify Switching Network Profiles
Suite Setup     Login CatalystCenter
Resource        ../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_profiles   switching

*** Test Cases ***

Get Site Profiles
    ${r}=   GET On Session   CatalystCenter_Session   /api/v1/siteprofile
    Log   Response Status Code: ${r.status_code}
    Set Suite Variable   ${r}

{% for profile in catalyst_center.network_profiles.switching | default([]) %}
Verify switching profile {{ profile.name }}
    ${profile_info}=   Get Value From Json   ${r.json()}   $.response[?(@.name=='{{ profile.name }}')]
    Should Be Equal Value Json String   ${profile_info[0]}   $.name   {{ profile.name }}
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/template-programmer/template
{% for onboarding_template in profile.onboarding_templates | default([]) %}
{% if '#' in onboarding_template %}
{% set project_name = onboarding_template.split('#')[0] %}
{% set template_name = onboarding_template.split('#')[1] %}
    ${onboarding_template}=   Evaluate   [t for t in $r.json() if t.get('name') == '{{ template_name }}' and t.get('projectName') == '{{ project_name }}']
    Should Be Equal Value Json String   ${onboarding_template[0]}   $.name   {{ template_name }}
{% else %}
    ${onboarding_template}=   Get Value From Json   ${r.json()}   $[?(@.name=='{{ onboarding_template }}')]
    Should Be Equal Value Json String   ${onboarding_template[0]}   $.name   {{ onboarding_template }}
{% endif %}
{% endfor %}
{% for dayn_template in profile.dayn_templates | default([]) %}
{% if '#' in dayn_template %}
{% set project_name = dayn_template.split('#')[0] %}
{% set template_name = dayn_template.split('#')[1] %}
    ${dayn_template}=   Evaluate   [t for t in $r.json() if t.get('name') == '{{ template_name }}' and t.get('projectName') == '{{ project_name }}']
    Should Be Equal Value Json String   ${dayn_template[0]}   $.name   {{ template_name }}
{% else %}
    ${dayn_template}=   Get Value From Json   ${r.json()}   $[?(@.name=='{{ dayn_template }}')]
    Should Be Equal Value Json String   ${dayn_template[0]}   $.name   {{ dayn_template }}
{% endif %}
{% endfor %}
{% for site in profile.sites %}
    ${s}=   Get Cached Sites Data
    ${site}=   Get Value From Json   ${s.json()}   $.response[?(@.nameHierarchy=='{{ site }}')]
    ${site_count}=   Get Length   ${site}
    Run Keyword If   ${site_count} > 0   Should Be Equal Value Json String   ${site[0]}   $.nameHierarchy   {{ site }}
{% endfor %}
{% endfor %}
