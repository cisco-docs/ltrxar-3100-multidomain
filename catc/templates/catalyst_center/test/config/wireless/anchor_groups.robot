*** Settings ***
Documentation     Verify Wireless Anchor Groups in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   anchor_groups

*** Test Cases ***

Get Wireless Anchor Groups
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/anchorGroups
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for anchor_group in catalyst_center.wireless.anchor_groups | default([]) %}
Verify Anchor Group {{ anchor_group.name }}
    ${group_data}=   Get Value From Json   ${r.json()}   $.response[?(@.anchorGroupName=='{{ anchor_group.name }}')]
    Run Keyword If   not ${group_data}   Fail   Anchor Group '{{ anchor_group.name }}' not found in API response.

    ${group_entry}=   Set Variable   ${group_data}[0]
    Log To Console   Extracted Anchor Group Entry: ${group_entry}

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${group_entry}   $.anchorGroupName   {{ anchor_group.name }}

{% if anchor_group.mobility_anchors is defined %}
    ${anchors}=   Get Value From Json   ${group_entry}   $.mobilityAnchors
    ${anchors_list}=   Set Variable   ${anchors}[0]
    ${anchors_count}=   Get Length   ${anchors_list}
    Should Be Equal As Integers   ${anchors_count}   {{ anchor_group.mobility_anchors | length }}

{% for anchor in anchor_group.mobility_anchors %}
    ${anchor_entry}=   Set Variable   ${anchors_list}[{{ loop.index0 }}]
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${anchor_entry}   $.ipAddress   {{ anchor.ip_address }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${anchor_entry}   $.anchorPriority   {{ anchor.anchor_priority }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${anchor_entry}   $.managedAnchorWlc   {{ anchor.managed_anchor_wlc | default(defaults.catalyst_center.wireless.anchor_groups.mobility_anchors.managed_anchor_wlc) }}

{% if anchor.peer_device_type is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${anchor_entry}   $.peerDeviceType   {{ anchor.peer_device_type | default(defaults.catalyst_center.wireless.anchor_groups.mobility_anchors.peer_device_type) }}
{% endif %}

{% if anchor.mac_address is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${anchor_entry}   $.macAddress   {{ anchor.mac_address }}
{% endif %}

{% if anchor.mobility_group_name is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${anchor_entry}   $.mobilityGroupName   {{ anchor.mobility_group_name }}
{% endif %}

{% endfor %}
{% endif %}

{% endfor %}
