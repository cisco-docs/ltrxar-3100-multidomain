*** Settings ***
Documentation     Verify Wireless RF Profiles in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   rf_profiles

*** Test Cases ***

Get Wireless RF Profiles
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/rfProfiles
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for rf_profile in catalyst_center.wireless.rf_profiles | default([]) %}
Verify RF Profile {{ rf_profile.name }}
    # Validate that the RF profile exists in the API response
    ${rf_profile_data}=   Get Value From Json   ${r.json()}   $.response[?(@.rfProfileName=='{{ rf_profile.name }}')]
    Run Keyword If   not ${rf_profile_data}   Fail   RF Profile {{ rf_profile.name }} not found in API response.

    # Extract the first matching RF profile from the API response
    ${rf_profile_entry}=   Set Variable   ${rf_profile_data}[0]
    Log To Console   Extracted RF Profile Entry: ${rf_profile_entry}

    # Validate basic RF profile attributes
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.rfProfileName   {{ rf_profile.name }}
    {% if rf_profile.default_rf_profile is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${rf_profile_entry}   $.defaultRfProfile   {{ rf_profile.default_rf_profile | default(defaults.catalyst_center.wireless.rf_profiles.default_rf_profile) | default(false) }}
    {% endif %}
    {% if rf_profile.enable_radio_type_a is defined or defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_a is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${rf_profile_entry}   $.enableRadioTypeA   {{ rf_profile.enable_radio_type_a | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_a) | default(true) }}
    {% endif %}    
    {% if rf_profile.enable_radio_type_b is defined or defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_b is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${rf_profile_entry}   $.enableRadioTypeB   {{ rf_profile.enable_radio_type_b | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_b) | default(true) }}
    {% endif %}
    {% if rf_profile.enable_radio_type_c is defined or defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_c is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${rf_profile_entry}   $.enableRadioType6GHz   {{ rf_profile.enable_radio_type_c | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_c) | default(false) }}
    {% endif %}
    {% if rf_profile.enable_custom is defined or defaults.catalyst_center.wireless.rf_profiles.enable_custom is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${rf_profile_entry}   $.enableCustom   {{ rf_profile.enable_custom | default(defaults.catalyst_center.wireless.rf_profiles.enable_custom) | default(false) }}
    {% endif %}

    # Validate Radio Type A Properties (5GHz)
    {% if rf_profile.enable_radio_type_a | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_a) | default(true) %}
    {% if rf_profile.radio_type_a_properties is defined %}
    Log To Console   Validating Radio Type A Properties for {{ rf_profile.name }}
    {% if rf_profile.radio_type_a_properties.parent_profile is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeAProperties.parentProfile   {{ rf_profile.radio_type_a_properties.parent_profile }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.radio_channels is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeAProperties.radioChannels   {{ rf_profile.radio_type_a_properties.radio_channels }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeAProperties.dataRates   {{ rf_profile.radio_type_a_properties.data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.mandatory_data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeAProperties.mandatoryDataRates   {{ rf_profile.radio_type_a_properties.mandatory_data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.power_threshold_v1 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeAProperties.powerThresholdV1   {{ rf_profile.radio_type_a_properties.power_threshold_v1 }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.rx_sop_threshold is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeAProperties.rxSopThreshold   {{ rf_profile.radio_type_a_properties.rx_sop_threshold }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.min_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeAProperties.minPowerLevel   {{ rf_profile.radio_type_a_properties.min_power_level }}
    {% endif %}
    {% if rf_profile.radio_type_a_properties.max_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeAProperties.maxPowerLevel   {{ rf_profile.radio_type_a_properties.max_power_level }}
    {% endif %}
    {% endif %}
    {% endif %}

    # Validate Radio Type B Properties (2.4GHz)
    {% if rf_profile.enable_radio_type_b | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_b) | default(true) %}
    {% if rf_profile.radio_type_b_properties is defined %}
    Log To Console   Validating Radio Type B Properties for {{ rf_profile.name }}
    {% if rf_profile.radio_type_b_properties.parent_profile is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeBProperties.parentProfile   {{ rf_profile.radio_type_b_properties.parent_profile }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.radio_channels is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeBProperties.radioChannels   {{ rf_profile.radio_type_b_properties.radio_channels }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeBProperties.dataRates   {{ rf_profile.radio_type_b_properties.data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.mandatory_data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeBProperties.mandatoryDataRates   {{ rf_profile.radio_type_b_properties.mandatory_data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.power_threshold_v1 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeBProperties.powerThresholdV1   {{ rf_profile.radio_type_b_properties.power_threshold_v1 }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.rx_sop_threshold is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioTypeBProperties.rxSopThreshold   {{ rf_profile.radio_type_b_properties.rx_sop_threshold }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.min_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeBProperties.minPowerLevel   {{ rf_profile.radio_type_b_properties.min_power_level }}
    {% endif %}
    {% if rf_profile.radio_type_b_properties.max_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioTypeBProperties.maxPowerLevel   {{ rf_profile.radio_type_b_properties.max_power_level }}
    {% endif %}
    {% endif %}
    {% endif %}

    # Validate Radio Type C Properties (6GHz)
    {% if rf_profile.enable_radio_type_c | default(defaults.catalyst_center.wireless.rf_profiles.enable_radio_type_c) | default(false) %}
    {% if rf_profile.radio_type_c_properties is defined %}
    Log To Console   Validating Radio Type C Properties for {{ rf_profile.name }}
    {% if rf_profile.radio_type_c_properties.parent_profile is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioType6GHzProperties.parentProfile   {{ rf_profile.radio_type_c_properties.parent_profile }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.radio_channels is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioType6GHzProperties.radioChannels   {{ rf_profile.radio_type_c_properties.radio_channels }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioType6GHzProperties.dataRates   {{ rf_profile.radio_type_c_properties.data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.mandatory_data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioType6GHzProperties.mandatoryDataRates   {{ rf_profile.radio_type_c_properties.mandatory_data_rates }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.power_threshold_v1 is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioType6GHzProperties.powerThresholdV1   {{ rf_profile.radio_type_c_properties.power_threshold_v1 }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.rx_sop_threshold is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rf_profile_entry}   $.radioType6GHzProperties.rxSopThreshold   {{ rf_profile.radio_type_c_properties.rx_sop_threshold }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.min_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioType6GHzProperties.minPowerLevel   {{ rf_profile.radio_type_c_properties.min_power_level }}
    {% endif %}
    {% if rf_profile.radio_type_c_properties.max_power_level is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${rf_profile_entry}   $.radioType6GHzProperties.maxPowerLevel   {{ rf_profile.radio_type_c_properties.max_power_level }}
    {% endif %}
    {% endif %}
    {% endif %}

{% endfor %}
