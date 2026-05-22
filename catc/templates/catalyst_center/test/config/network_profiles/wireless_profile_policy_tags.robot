*** Settings ***
Documentation   Verify Wireless Profile Policy Tags
Suite Setup     Login CatalystCenter
Resource        ../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_profiles   wireless   policy_tags   site_specific

*** Test Cases ***

Get Wireless Profiles
    ${w}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessProfiles
    Log   Response Status Code: ${w.status_code}
    Set Suite Variable   ${w}

{% for wireless_profile in catalyst_center.network_profiles.wireless | default([]) %}
{% if wireless_profile.policy_tags is defined and wireless_profile.policy_tags | length > 0 %}
{% for tag in wireless_profile.policy_tags | default([]) %}
Verify Policy Tag {{ tag.name }} in {{ wireless_profile.name }}
    ${profile_info}=   Get Value From Json   ${w.json()}   $.response[?(@.wirelessProfileName=='{{ wireless_profile.name }}')]
    Run Keyword If   not ${profile_info}   Fail   Wireless Profile '{{ wireless_profile.name }}' not found
    ${profile_id}=   Get From Dictionary   ${profile_info[0]}   id

    ${pt}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessProfiles/${profile_id}/policyTags
    Log   Policy Tags Response for {{ wireless_profile.name }}: ${pt.json()}

    ${tag_data}=   Get Value From Json   ${pt.json()}   $.response[?(@.policyTagName=='{{ tag.name }}')]
    Run Keyword If   not ${tag_data}   Fail   Policy Tag '{{ tag.name }}' not found in Wireless Profile '{{ wireless_profile.name }}'
    ${tag_entry}=   Set Variable   ${tag_data}[0]

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.policyTagName   {{ tag.name }}

{% if tag.ap_zones is defined and tag.ap_zones | length > 0 %}
{% for zone in tag.ap_zones %}
    ${ap_zones_list}=   Get Value From Json   ${tag_entry}   $.apZones
    Run Keyword And Continue On Failure   List Should Contain Value   ${ap_zones_list[0]}   {{ zone }}   AP Zone '{{ zone }}' not found in policy tag '{{ tag.name }}'
{% endfor %}
{% endif %}

{% for site in tag.sites | default([]) %}
    ${should_skip_{{ loop.index }}}=   Should Skip Site Validation   {{ site }}
    IF   not ${should_skip_{{ loop.index }}}
        ${s}=   Get Cached Sites Data
        ${site_info}=   Get Value From Json   ${s.json()}   $.response[?(@.nameHierarchy=='{{ site }}')]
        Run Keyword And Continue On Failure   Should Not Be Empty   ${site_info}   Site '{{ site }}' not found in sites list
        ${expected_site_id}=   Get From Dictionary   ${site_info[0]}   id
        ${actual_site_ids}=   Get Value From Json   ${tag_entry}   $.siteIds
        Run Keyword And Continue On Failure   List Should Contain Value   ${actual_site_ids[0]}   ${expected_site_id}   Site '{{ site }}' (ID: ${expected_site_id}) not found in policy tag '{{ tag.name }}'
    ELSE
        Log   Site {{ site }} not managed by this deployment state - skipping validation
    END
{% endfor %}

{% endfor %}
{% endif %}
{% endfor %}
