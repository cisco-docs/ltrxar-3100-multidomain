*** Settings ***
Documentation     Verify Wireless 802.11be Profiles (Wi-Fi 7) in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   dot11be_profiles

*** Test Cases ***

Get Wireless 802.11be Profiles
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/dot11beProfiles
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for dot11be_profile in catalyst_center.wireless.dot11be_profiles | default([]) %}
Verify 802.11be Profile {{ dot11be_profile.name }}
    # Validate that the 802.11be profile exists in the API response
    ${profile_data}=   Get Value From Json   ${r.json()}   $.response[?(@.profileName=='{{ dot11be_profile.name }}')]
    Run Keyword If   not ${profile_data}   Fail   802.11be Profile '{{ dot11be_profile.name }}' not found in API response.

    # Extract the first matching profile from the API response
    ${profile_entry}=   Set Variable   ${profile_data}[0]
    Log To Console   Extracted 802.11be Profile Entry: ${profile_entry}

    # Validate profile name
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.profileName   {{ dot11be_profile.name }}

{% if dot11be_profile.ofdma_down_link is defined or defaults.catalyst_center.wireless.dot11be_profiles.ofdma_down_link is defined %}
    # OFDMA Downlink
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.ofdmaDownLink   {{ dot11be_profile.ofdma_down_link | default(defaults.catalyst_center.wireless.dot11be_profiles.ofdma_down_link) | default(true) }}
{% endif %}

{% if dot11be_profile.ofdma_up_link is defined or defaults.catalyst_center.wireless.dot11be_profiles.ofdma_up_link is defined %}
    # OFDMA Uplink
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.ofdmaUpLink   {{ dot11be_profile.ofdma_up_link | default(defaults.catalyst_center.wireless.dot11be_profiles.ofdma_up_link) | default(true) }}
{% endif %}

{% if dot11be_profile.mu_mimo_down_link is defined or defaults.catalyst_center.wireless.dot11be_profiles.mu_mimo_down_link is defined %}
    # MU-MIMO Downlink
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.muMimoDownLink   {{ dot11be_profile.mu_mimo_down_link | default(defaults.catalyst_center.wireless.dot11be_profiles.mu_mimo_down_link) | default(true) }}
{% endif %}

{% if dot11be_profile.mu_mimo_up_link is defined or defaults.catalyst_center.wireless.dot11be_profiles.mu_mimo_up_link is defined %}
    # MU-MIMO Uplink
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.muMimoUpLink   {{ dot11be_profile.mu_mimo_up_link | default(defaults.catalyst_center.wireless.dot11be_profiles.mu_mimo_up_link) | default(true) }}
{% endif %}

{% if dot11be_profile.ofdma_multi_ru is defined or defaults.catalyst_center.wireless.dot11be_profiles.ofdma_multi_ru is defined %}
    # OFDMA Multi-RU
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.ofdmaMultiRu   {{ dot11be_profile.ofdma_multi_ru | default(defaults.catalyst_center.wireless.dot11be_profiles.ofdma_multi_ru) | default(false) }}
{% endif %}

{% endfor %}
