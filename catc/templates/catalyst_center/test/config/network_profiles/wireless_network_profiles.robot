*** Settings ***
Documentation   Verify Wireless Network Profiles
Suite Setup     Login CatalystCenter
Resource        ../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_profiles   wireless   site_specific

*** Test Cases ***

Get Wireless Profiles
    ${w}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessProfiles
    Log   Response Status Code: ${w.status_code}
    Set Suite Variable   ${w}

Get 802.11be Profiles
    ${dot11be}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/dot11beProfiles
    Log   Response Status Code: ${dot11be.status_code}
    Set Suite Variable   ${dot11be}



{% for wireless_profile in catalyst_center.network_profiles.wireless | default([]) %}
Verify wireless profile {{ wireless_profile.name }}
    ${profile_info}=   Get Value From Json   ${w.json()}   $.response[?(@.wirelessProfileName=='{{ wireless_profile.name }}')]
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_info[0]}   $.wirelessProfileName   {{ wireless_profile.name }}
    
    # Get profile ID and site assignments once per profile
    ${profile_id}=   Get From Dictionary   ${profile_info[0]}   id
    ${a}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/networkProfilesForSites/${profile_id}/siteAssignments
    Log   Profile ID: ${profile_id} - Site Assignments Response: ${a.json()}
    ${assigned_site_ids}=   Get Value From Json   ${a.json()}   $.response[*].id

{% for ssid in wireless_profile.ssid_details | default([]) %}
    # === SSID Basic Information ===
    ${ssid_info}=   Get Value From Json   ${profile_info[0]}   $.ssidDetails[?(@.ssidName=='{{ ssid.name }}')]
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_info[0]}   $.ssidName   {{ ssid.name }}
    
    # === Always Validate Fields ===
    
    # Fabric Configuration (Boolean - Always validate)
    ${expected_fabric}=   Set Variable   {{ ssid.enable_fabric | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.enable_fabric) | default('false') }}
    ${expected_fabric_bool}=   Evaluate   '${expected_fabric}'.lower() == 'true'
    ${actual_fabric}=   Get From Dictionary   ${ssid_info[0]}   enableFabric
    Run Keyword And Continue On Failure   Should Be Equal   ${actual_fabric}   ${expected_fabric_bool}

    # WLAN Profile Name (String - Always validate with precise truncation)
{% set max_profile_length = 29 %}
{% set suffix = '_profile' %}
{% set max_ssid_length = max_profile_length - suffix|length %}
{% set truncated_ssid = ssid.name[:max_ssid_length] %}
    ${expected_wlan_profile}=   Set Variable   {{ ssid.wlan_profile_name | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.wlan_profile_name) | default(truncated_ssid + suffix) }}
    ${actual_wlan_profile}=   Get Value From Json   ${ssid_info[0]}   $.wlanProfileName
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${actual_wlan_profile[0]}   ${expected_wlan_profile}

    # Policy Profile Name (String - Always validate with precise truncation)
{% set truncated_ssid_policy = ssid.name[:max_ssid_length] %}
    ${expected_policy_profile}=   Set Variable   {{ ssid.policy_profile_name | default(truncated_ssid_policy + suffix) }}
    ${actual_policy_profile}=   Get Value From Json   ${ssid_info[0]}   $.policyProfileName
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${actual_policy_profile[0]}   ${expected_policy_profile}

{% set fabric_enabled = (ssid.enable_fabric | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.enable_fabric) | default('false') | string).lower() == 'true' %}

{% if not fabric_enabled %}
    # === FABRIC DISABLED - Conditional Field Validation ===
    
{% if ssid.interface_name is defined or defaults.catalyst_center.network_profiles.wireless.ssid_details.interface_name is defined %}
    # Interface Name (String - Only when fabric disabled and defined)
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_info[0]}   $.interfaceName   {{ ssid.interface_name | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.interface_name) }}
{% endif %}

{% if ssid.vlan_group_name is defined or defaults.catalyst_center.network_profiles.wireless.ssid_details.vlan_group_name is defined %}
    # VLAN Group Name (String - Only when fabric disabled and defined)
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_info[0]}   $.vlanGroupName   {{ ssid.vlan_group_name | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.vlan_group_name) }}
{% endif %}

{% if ssid.anchor_group_name is defined or defaults.catalyst_center.network_profiles.wireless.ssid_details.anchor_group_name is defined %}
    # === Anchor Group Configuration (Mutually Exclusive with Flex Connect) ===
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_info[0]}   $.anchorGroupName   {{ ssid.anchor_group_name | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.anchor_group_name) }}
{% else %}
    # === Flex Connect Configuration (When no anchor group) ===
    
    # Flex Connect Enable (Boolean)
    ${expected_flex}=   Set Variable   {{ ssid.enable_flex_connect | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.enable_flex_connect) | default('false') }}
    ${expected_flex_bool}=   Evaluate   '${expected_flex}'.lower() == 'true'
    ${flex_connect_obj}=   Get From Dictionary   ${ssid_info[0]}   flexConnect
    ${actual_flex}=   Get From Dictionary   ${flex_connect_obj}   enableFlexConnect
    Run Keyword And Continue On Failure   Should Be Equal   ${actual_flex}   ${expected_flex_bool}

{% set flex_enabled = (ssid.enable_flex_connect | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.enable_flex_connect) | default('false') | string).lower() == 'true' %}
{% if flex_enabled and (ssid.local_to_vlan is defined or defaults.catalyst_center.network_profiles.wireless.ssid_details.local_to_vlan is defined) %}
    # Local to VLAN (Integer - Only when fabric disabled, no anchor group, flex enabled, and defined)
    ${expected_vlan}=   Convert To Integer   {{ ssid.local_to_vlan | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.local_to_vlan) | default(1) }}
    ${actual_vlan}=   Get From Dictionary   ${flex_connect_obj}   localToVlan
    Run Keyword And Continue On Failure   Should Be Equal As Integers   ${actual_vlan}   ${expected_vlan}
{% endif %}
{% endif %}

{% else %}
    # === FABRIC ENABLED - Skip Interface, VLAN Group, Anchor Group, and Flex Connect validation ===
    Log   Fabric enabled - skipping interfaceName, vlanGroupName, anchorGroupName, and flexConnect validation
{% endif %}

{% if ssid.dot11be_profile_name is defined or defaults.catalyst_center.network_profiles.wireless.ssid_details.dot11be_profile_name is defined %}
    # 802.11be Profile (Wi-Fi 7) - Validate that profile exists and is correctly assigned
    # First verify the profile exists in the 802.11be profiles API
    ${expected_dot11be_profile_name}=   Set Variable   {{ ssid.dot11be_profile_name | default(defaults.catalyst_center.network_profiles.wireless.ssid_details.dot11be_profile_name) }}
    ${dot11be_profile_data}=   Get Value From Json   ${dot11be.json()}   $.response[?(@.profileName=='${expected_dot11be_profile_name}')]
    Run Keyword And Continue On Failure   Should Not Be Empty   ${dot11be_profile_data}   802.11be profile '${expected_dot11be_profile_name}' not found in wirelessSettings/dot11beProfiles API
    
    # Get the expected profile ID from the 802.11be profiles API
    ${expected_dot11be_profile_id}=   Get Value From Json   ${dot11be_profile_data[0]}   $.id
    
    # Verify the SSID has the correct dot11beProfileId assigned
    ${actual_dot11be_profile_id}=   Get Value From Json   ${ssid_info[0]}   $.dot11beProfileId
    Run Keyword And Continue On Failure   Should Not Be Empty   ${actual_dot11be_profile_id}   802.11be profile '${expected_dot11be_profile_name}' should be assigned but dot11beProfileId is empty in wireless profile
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${actual_dot11be_profile_id[0]}   ${expected_dot11be_profile_id[0]}   802.11be profile ID mismatch: expected ${expected_dot11be_profile_id[0]} but got ${actual_dot11be_profile_id[0]}
{% endif %}

{% endfor %}

{% if wireless_profile.additional_interfaces is defined or defaults.catalyst_center.network_profiles.wireless.additional_interfaces is defined %}
    # Additional Interfaces (Array - Profile level)
    ${expected_interfaces}=   Create List{% for iface in wireless_profile.additional_interfaces | default(defaults.catalyst_center.network_profiles.wireless.additional_interfaces) | default([]) %}   {{ iface }}{% endfor %}

    ${actual_interfaces}=   Get From Dictionary   ${profile_info[0]}   additionalInterfaces
    Run Keyword And Continue On Failure   Lists Should Be Equal   ${actual_interfaces}   ${expected_interfaces}
{% endif %}

{% for site in wireless_profile.sites | default([]) %}
    # Site Assignment Validation using Network Profile Site Assignments API
    # Check if this site should be skipped based on MANAGED_SITES
    ${should_skip_{{ loop.index }}}=   Should Skip Site Validation   {{ site }}
    IF   not ${should_skip_{{ loop.index }}}
        # Get site ID from site hierarchy path (using cached sites data)
        ${s}=   Get Cached Sites Data
        ${site_info}=   Get Value From Json   ${s.json()}   $.response[?(@.nameHierarchy=='{{ site }}')]
        Run Keyword And Continue On Failure   Should Not Be Empty   ${site_info}   Site '{{ site }}' not found in sites list
        ${expected_site_id}=   Get From Dictionary   ${site_info[0]}   id
        
        # Validate that the site is assigned to this network profile
        List Should Contain Value   ${assigned_site_ids}   ${expected_site_id}   Site '{{ site }}' (ID: ${expected_site_id}) is not assigned to wireless profile '{{ wireless_profile.name }}'
    ELSE
        Log   Site {{ site }} not managed by this deployment state - skipping validation
    END
{% endfor %}

{% endfor %}
