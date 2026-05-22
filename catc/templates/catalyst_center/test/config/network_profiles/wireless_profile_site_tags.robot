*** Settings ***
Documentation   Verify Wireless Profile Site Tags
Suite Setup     Login CatalystCenter
Resource        ../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_profiles   wireless   site_tags   site_specific

*** Test Cases ***

Get Wireless Profiles
    ${w}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessProfiles
    Log   Response Status Code: ${w.status_code}
    Set Suite Variable   ${w}

{% for wireless_profile in catalyst_center.network_profiles.wireless | default([]) %}
{% if wireless_profile.site_tags is defined and wireless_profile.site_tags | length > 0 %}
{% for tag in wireless_profile.site_tags | default([]) %}
Verify Site Tag {{ tag.name }} in {{ wireless_profile.name }}
    ${profile_info}=   Get Value From Json   ${w.json()}   $.response[?(@.wirelessProfileName=='{{ wireless_profile.name }}')]
    Run Keyword If   not ${profile_info}   Fail   Wireless Profile '{{ wireless_profile.name }}' not found
    ${profile_id}=   Get From Dictionary   ${profile_info[0]}   id

    ${st}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessProfiles/${profile_id}/siteTags
    Log   Site Tags Response for {{ wireless_profile.name }}: ${st.json()}

    ${tag_data}=   Get Value From Json   ${st.json()}   $.response[?(@.siteTagName=='{{ tag.name }}')]
    Run Keyword If   not ${tag_data}   Fail   Site Tag '{{ tag.name }}' not found in Wireless Profile '{{ wireless_profile.name }}'
    ${tag_entry}=   Set Variable   ${tag_data}[0]

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.siteTagName   {{ tag.name }}

{% if tag.ap_profile_name is defined or defaults.catalyst_center.network_profiles.wireless.site_tags.ap_profile_name is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.apProfileName   {{ tag.ap_profile_name | default(defaults.catalyst_center.network_profiles.wireless.site_tags.ap_profile_name) }}
{% endif %}

{% if tag.flex_profile_name is defined or defaults.catalyst_center.network_profiles.wireless.site_tags.flex_profile_name is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.flexProfileName   {{ tag.flex_profile_name | default(defaults.catalyst_center.network_profiles.wireless.site_tags.flex_profile_name) | default('default-flex-profile') }}
{% endif %}

{% for site in tag.sites | default([]) %}
    ${should_skip_{{ loop.index }}}=   Should Skip Site Validation   {{ site }}
    IF   not ${should_skip_{{ loop.index }}}
        ${s}=   Get Cached Sites Data
        ${site_info}=   Get Value From Json   ${s.json()}   $.response[?(@.nameHierarchy=='{{ site }}')]
        Run Keyword And Continue On Failure   Should Not Be Empty   ${site_info}   Site '{{ site }}' not found in sites list
        ${expected_site_id}=   Get From Dictionary   ${site_info[0]}   id
        ${actual_site_ids}=   Get Value From Json   ${tag_entry}   $.siteIds
        Run Keyword And Continue On Failure   List Should Contain Value   ${actual_site_ids[0]}   ${expected_site_id}   Site '{{ site }}' (ID: ${expected_site_id}) not found in site tag '{{ tag.name }}'
    ELSE
        Log   Site {{ site }} not managed by this deployment state - skipping validation
    END
{% endfor %}

{% endfor %}
{% endif %}
{% endfor %}
