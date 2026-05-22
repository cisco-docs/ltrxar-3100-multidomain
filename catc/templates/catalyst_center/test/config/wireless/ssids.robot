*** Settings ***
Documentation     Verify Wireless SSIDs in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   ssids

*** Test Cases ***

Get Global Site ID
    ${s}=   Get Cached Sites Data
    ${global_site_data}=   Get Value From Json   ${s.json()}   $.response[?(@.name=='Global')]
    Run Keyword If   not ${global_site_data}   Fail   Global site not found in sites list
    ${global_site_entry}=   Set Variable   ${global_site_data}[0]
    ${site_type}=   Get From Dictionary   ${global_site_entry}   type
    Run Keyword If   '${site_type}' != 'global'   Fail   Found site named 'Global' but type is '${site_type}', expected 'global'
    ${global_site_id}=   Get From Dictionary   ${global_site_entry}   id
    Set Suite Variable   ${GLOBAL_SITE_ID}   ${global_site_id}
    Log To Console   Global Site ID: ${GLOBAL_SITE_ID}

Get Wireless SSIDs
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/sites/${GLOBAL_SITE_ID}/wirelessSettings/ssids
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for ssid in catalyst_center.wireless.ssids | default([]) %}
Verify SSID {{ ssid.name }}
    # Validate that the SSID exists in the API response
    ${ssid_data}=   Get Value From Json   ${r.json()}   $.response[?(@.ssid=='{{ ssid.name }}')]
    Run Keyword If   not ${ssid_data}   Fail   SSID {{ ssid.name }} not found in API response.

    # Extract the first matching SSID from the API response
    ${ssid_entry}=   Set Variable   ${ssid_data}[0]
    Log To Console   Extracted SSID Entry: ${ssid_entry}

    # Validate basic SSID attributes
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.ssid   {{ ssid.name }}
    {% if ssid.wlan_type is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.wlanType   {{ ssid.wlan_type | default(defaults.catalyst_center.wireless.ssids.wlan_type) }}
    {% endif %}
    {% if ssid.auth_type is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.authType   {{ ssid.auth_type | default(defaults.catalyst_center.wireless.ssids.auth_type) }}
    {% endif %}
    {% if ssid.ssid_radio_type is defined %}
        {% set radio_type = ssid.ssid_radio_type | default(defaults.catalyst_center.wireless.ssids.ssid_radio_type) %}
        {% if radio_type == 'Triple Band' %}
            {% set expected_value = 'Triple band operation\\(2.4GHz, 5GHz and 6GHz\\)' %}
        {% elif radio_type == '2.4GHz and 5GHz' %}
            {% set expected_value = '2.4 and 5 GHz' %}
        {% elif radio_type == '2.4GHz and 6GHz' %}
            {% set expected_value = '2.4 and 6 GHz' %}
        {% elif radio_type == '5GHz and 6GHz' %}
            {% set expected_value = '5 and 6 GHz' %}
        {% elif radio_type == '2.4GHz' %}
            {% set expected_value = '2.4GHz only' %}
        {% elif radio_type == '5GHz' %}
            {% set expected_value = '5GHz only' %}
        {% elif radio_type == '6GHz' %}
            {% set expected_value = '6GHz only' %}
        {% else %}
            {% set expected_value = radio_type %}
        {% endif %}
        Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.ssidRadioType   {{ expected_value }}
    {% endif %}


    # Validate boolean attributes
    {% if ssid.enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isEnabled   {{ ssid.enabled | default(defaults.catalyst_center.wireless.ssids.enabled) | default(true) }}
    {% endif %}
    {% if ssid.broadcast_ssid is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isBroadcastSSID   {{ ssid.broadcast_ssid | default(defaults.catalyst_center.wireless.ssids.broadcast_ssid) | default(true) }}
    {% endif %}
    {% if ssid.fast_lane is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isFastLaneEnabled   {{ ssid.fast_lane | default(defaults.catalyst_center.wireless.ssids.fast_lane) | default(false) }}
    {% endif %}
    {% if ssid.mac_filtering is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isMacFilteringEnabled   {{ ssid.mac_filtering | default(defaults.catalyst_center.wireless.ssids.mac_filtering) | default(false) }}
    {% endif %}
    {% if ssid.random_mac_filter is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isRandomMacFilterEnabled   {{ ssid.random_mac_filter | default(defaults.catalyst_center.wireless.ssids.random_mac_filter) | default(false) }}
    {% endif %}
    {% if ssid.ap_beacon_protection is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isApBeaconProtectionEnabled   {{ ssid.ap_beacon_protection | default(defaults.catalyst_center.wireless.ssids.ap_beacon_protection) | default(false) }}
    {% endif %}
    {% if ssid.posturing is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isPosturingEnabled   {{ ssid.posturing | default(defaults.catalyst_center.wireless.ssids.posturing) | default(false) }}
    {% endif %}

    # Validate authentication key settings
    {% if ssid.auth_key8021x is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKey8021x   {{ ssid.auth_key8021x | default(defaults.catalyst_center.wireless.ssids.auth_key8021x) | default(false) }}
    {% endif %}

    {% if ssid.auth_key8021x_sha256 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKey8021x_SHA256   {{ ssid.auth_key8021x_sha256 | default(defaults.catalyst_center.wireless.ssids.auth_key8021x_sha256) | default(false) }}
    {% endif %}

    {% if ssid.auth_key_sae is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKeySae   {{ ssid.auth_key_sae | default(defaults.catalyst_center.wireless.ssids.auth_key_sae) | default(false) }}
    {% endif %}

    {% if ssid.auth_key_sae_ext_plus_ft is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKeySaeExtPlusFT   {{ ssid.auth_key_sae_ext_plus_ft | default(defaults.catalyst_center.wireless.ssids.auth_key_sae_ext_plus_ft) | default(false) }}
    {% endif %}

    {% if ssid.auth_key_psk is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKeyPSK   {{ ssid.auth_key_psk | default(defaults.catalyst_center.wireless.ssids.auth_key_psk) | default(false) }}
    {% endif %}

    {% if ssid.auth_key_psk_plus_ft is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKeyPSKPlusFT   {{ ssid.auth_key_psk_plus_ft | default(defaults.catalyst_center.wireless.ssids.auth_key_psk_plus_ft) | default(false) }}
    {% endif %}
    
    {% if ssid.auth_key_suite_b1921x is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isAuthKeySuiteB1921x   {{ ssid.auth_key_suite_b1921x | default(defaults.catalyst_center.wireless.ssids.auth_key_suite_b1921x) | default(false) }}
    {% endif %}

    # Validate cipher suite settings
    {% if ssid.rsn_cipher_suite_ccmp128 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.rsnCipherSuiteCcmp128   {{ ssid.rsn_cipher_suite_ccmp128 | default(defaults.catalyst_center.wireless.ssids.rsn_cipher_suite_ccmp128) | default(false) }}
    {% endif %}
    {% if ssid.rsn_cipher_suite_gcmp256 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.rsnCipherSuiteGcmp256   {{ ssid.rsn_cipher_suite_gcmp256 | default(defaults.catalyst_center.wireless.ssids.rsn_cipher_suite_gcmp256) | default(false) }}
    {% endif %}

    # Validate QoS settings
    {% if ssid.egress_qos is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.egressQos   {{ ssid.egress_qos | default(defaults.catalyst_center.wireless.ssids.egress_qos) }}
    {% endif %}
    {% if ssid.ingress_qos is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.ingressQos   {{ ssid.ingress_qos | default(defaults.catalyst_center.wireless.ssids.ingress_qos) }}
    {% endif %}

    # Validate policy settings
    {% if ssid.ghz24_policy is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.ghz24Policy   {{ ssid.ghz24_policy | default(defaults.catalyst_center.wireless.ssids.ghz24_policy) }}
    {% endif %}
    {% if ssid.fast_transition is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.fastTransition   {{ ssid.fast_transition | default(defaults.catalyst_center.wireless.ssids.fast_transition) }}
    {% endif %}

    # Validate AAA settings
    {% if ssid.aaa_override is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.aaaOverride   {{ ssid.aaa_override | default(defaults.catalyst_center.wireless.ssids.aaa_override) | default(false) }}
    {% endif %}
    {% if ssid.auth_servers is defined %}
    ${expected_auth_servers}=   Create List{% for server in ssid.auth_servers | default(defaults.catalyst_center.wireless.ssids.auth_servers) | default([]) %}   {{ server }}{% endfor %}

    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${ssid_entry}   $.authServers   ${expected_auth_servers}
    {% endif %}
    {% if ssid.acct_servers is defined %}
    ${expected_acct_servers}=   Create List{% for server in ssid.acct_servers | default(defaults.catalyst_center.wireless.ssids.acct_servers) | default([]) %}   {{ server }}{% endfor %}

    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${ssid_entry}   $.acctServers   ${expected_acct_servers}
    {% endif %}

    # Validate CCKM settings
    {% if ssid.cckm is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isCckmEnabled   {{ ssid.cckm | default(defaults.catalyst_center.wireless.ssids.cckm) | default(false) }}
    {% endif %}
    {% if ssid.cckm_tsf_tolerance is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.cckmTsfTolerance   {{ ssid.cckm_tsf_tolerance | default(defaults.catalyst_center.wireless.ssids.cckm_tsf_tolerance) }}
    {% endif %}

    # Validate L3 authentication type
    {% if ssid.l3_auth_type is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.l3AuthType   {{ ssid.l3_auth_type | default(defaults.catalyst_center.wireless.ssids.l3_auth_type) }}
    {% endif %}

    # Validate hex passphrase setting
    {% if ssid.hex is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.isHex   {{ ssid.hex | default(defaults.catalyst_center.wireless.ssids.hex) | default(false) }}
    {% endif %}

    # Validate management frame protection
    {% if ssid.mft_client_protection is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.managementFrameProtectionClientprotection   {{ ssid.mft_client_protection | default(defaults.catalyst_center.wireless.ssids.mft_client_protection) }}
    {% endif %}
    {% if ssid.protected_management_frame is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${ssid_entry}   $.protectedManagementFrame   {{ ssid.protected_management_frame | default(defaults.catalyst_center.wireless.ssids.protected_management_frame) }}
    {% endif %}

    # Validate session and timeout settings
    {% if ssid.session_timeout_enable is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.sessionTimeOutEnable   {{ ssid.session_timeout_enable | default(defaults.catalyst_center.wireless.ssids.session_timeout_enable) | default(false) }}
    {% endif %}
    {% if ssid.session_timeout is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.sessionTimeOut   {{ ssid.session_timeout | default(defaults.catalyst_center.wireless.ssids.session_timeout) }}
    {% endif %}

    # Validate client settings
    {% if ssid.client_exclusion is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.clientExclusionEnable   {{ ssid.client_exclusion | default(defaults.catalyst_center.wireless.ssids.client_exclusion) | default(false) }}
    {% endif %}
    {% if ssid.client_exclusion_timeout is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.clientExclusionTimeout   {{ ssid.client_exclusion_timeout | default(defaults.catalyst_center.wireless.ssids.client_exclusion_timeout) }}
    {% endif %}
    {% if ssid.basic_service_set_max_idle is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.basicServiceSetMaxIdleEnable   {{ ssid.basic_service_set_max_idle | default(defaults.catalyst_center.wireless.ssids.basic_service_set_max_idle) | default(false) }}
    {% endif %}
    {% if ssid.basic_service_set_client_idle_timeout is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.basicServiceSetClientIdleTimeout   {{ ssid.basic_service_set_client_idle_timeout | default(defaults.catalyst_center.wireless.ssids.basic_service_set_client_idle_timeout) }}
    {% endif %}
    {% if ssid.sleeping_client_timeout is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.sleepingClientTimeout   {{ ssid.sleeping_client_timeout | default(defaults.catalyst_center.wireless.ssids.sleeping_client_timeout) }}
    {% endif %}
    {% if ssid.client_rate_limit is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${ssid_entry}   $.clientRateLimit   {{ ssid.client_rate_limit | default(defaults.catalyst_center.wireless.ssids.client_rate_limit) }}
    {% endif %}

    # Validate advanced settings
    {% if ssid.directed_multicast_service is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.directedMulticastServiceEnable   {{ ssid.directed_multicast_service | default(defaults.catalyst_center.wireless.ssids.directed_multicast_service) | default(false) }}
    {% endif %}
    {% if ssid.neighbor_list is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.neighborListEnable   {{ ssid.neighbor_list | default(defaults.catalyst_center.wireless.ssids.neighbor_list) | default(false) }}
    {% endif %}
    {% if ssid.coverage_hole_detection is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${ssid_entry}   $.coverageHoleDetectionEnable   {{ ssid.coverage_hole_detection | default(defaults.catalyst_center.wireless.ssids.coverage_hole_detection) | default(false) }}
    {% endif %}

    # Validate NAS options
    {% if ssid.nas_options is defined %}
    ${expected_nas_options}=   Create List{% for option in ssid.nas_options | default(defaults.catalyst_center.wireless.ssids.nas_options) | default([]) %}   {{ option }}{% endfor %}

    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${ssid_entry}   $.nasOptions   ${expected_nas_options}
    {% endif %}

{% endfor %}
