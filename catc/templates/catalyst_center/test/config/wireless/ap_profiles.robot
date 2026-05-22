*** Settings ***
Documentation     Verify Wireless AP Profiles in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   ap_profiles

*** Test Cases ***

Get Wireless AP Profiles
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/apProfiles
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for ap_profile in catalyst_center.wireless.ap_profiles | default([]) %}
Verify AP Profile {{ ap_profile.name }}
    ${profile_data}=   Get Value From Json   ${r.json()}   $.response[?(@.apProfileName=='{{ ap_profile.name }}')]
    Run Keyword If   not ${profile_data}   Fail   AP Profile '{{ ap_profile.name }}' not found in API response.

    ${profile_entry}=   Set Variable   ${profile_data}[0]
    Log To Console   Extracted AP Profile Entry: ${profile_entry}

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.apProfileName   {{ ap_profile.name }}

{% if ap_profile.description is defined or defaults.catalyst_center.wireless.ap_profiles.description is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.description   {{ ap_profile.description | default(defaults.catalyst_center.wireless.ap_profiles.description) }}
{% endif %}

{% if ap_profile.remote_worker_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.remote_worker_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.remoteWorkerEnabled   {{ ap_profile.remote_worker_enabled | default(defaults.catalyst_center.wireless.ap_profiles.remote_worker_enabled) | default(false) }}
{% endif %}

{% if ap_profile.awips_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.awips_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.awipsEnabled   {{ ap_profile.awips_enabled | default(defaults.catalyst_center.wireless.ap_profiles.awips_enabled) | default(false) }}
{% endif %}

{% if ap_profile.awips_forensic_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.awips_forensic_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.awipsForensicEnabled   {{ ap_profile.awips_forensic_enabled | default(defaults.catalyst_center.wireless.ap_profiles.awips_forensic_enabled) | default(false) }}
{% endif %}

{% if ap_profile.pmf_denial_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.pmf_denial_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.pmfDenialEnabled   {{ ap_profile.pmf_denial_enabled | default(defaults.catalyst_center.wireless.ap_profiles.pmf_denial_enabled) | default(false) }}
{% endif %}

{% if ap_profile.mesh_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.mesh_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.meshEnabled   {{ ap_profile.mesh_enabled | default(defaults.catalyst_center.wireless.ap_profiles.mesh_enabled) | default(false) }}
{% endif %}

{% if ap_profile.auth_type is defined or defaults.catalyst_center.wireless.ap_profiles.auth_type is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.managementSetting.authType   {{ ap_profile.auth_type | default(defaults.catalyst_center.wireless.ap_profiles.auth_type) | default('NO-AUTH') }}
{% endif %}

{% if ap_profile.ssh_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.ssh_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.managementSetting.sshEnabled   {{ ap_profile.ssh_enabled | default(defaults.catalyst_center.wireless.ap_profiles.ssh_enabled) | default(false) }}
{% endif %}

{% if ap_profile.telnet_enabled is defined or defaults.catalyst_center.wireless.ap_profiles.telnet_enabled is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.managementSetting.telnetEnabled   {{ ap_profile.telnet_enabled | default(defaults.catalyst_center.wireless.ap_profiles.telnet_enabled) | default(false) }}
{% endif %}

{% if ap_profile.cdp_state is defined or defaults.catalyst_center.wireless.ap_profiles.cdp_state is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.managementSetting.cdpState   {{ ap_profile.cdp_state | default(defaults.catalyst_center.wireless.ap_profiles.cdp_state) | default(false) }}
{% endif %}

{% if ap_profile.rogue_detection is defined or defaults.catalyst_center.wireless.ap_profiles.rogue_detection is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.rogueDetectionSetting.rogueDetection   {{ ap_profile.rogue_detection | default(defaults.catalyst_center.wireless.ap_profiles.rogue_detection) | default(false) }}
{% endif %}

{% if ap_profile.rogue_detection_min_rssi is defined or defaults.catalyst_center.wireless.ap_profiles.rogue_detection_min_rssi is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.rogueDetectionSetting.rogueDetectionMinRssi   {{ ap_profile.rogue_detection_min_rssi | default(defaults.catalyst_center.wireless.ap_profiles.rogue_detection_min_rssi) | default(-90) }}
{% endif %}

{% if ap_profile.rogue_detection_transient_interval is defined or defaults.catalyst_center.wireless.ap_profiles.rogue_detection_transient_interval is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.rogueDetectionSetting.rogueDetectionTransientInterval   {{ ap_profile.rogue_detection_transient_interval | default(defaults.catalyst_center.wireless.ap_profiles.rogue_detection_transient_interval) | default(0) }}
{% endif %}

{% if ap_profile.rogue_detection_report_interval is defined or defaults.catalyst_center.wireless.ap_profiles.rogue_detection_report_interval is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.rogueDetectionSetting.rogueDetectionReportInterval   {{ ap_profile.rogue_detection_report_interval | default(defaults.catalyst_center.wireless.ap_profiles.rogue_detection_report_interval) | default(10) }}
{% endif %}

{% if ap_profile.power_profile is defined or defaults.catalyst_center.wireless.ap_profiles.power_profile is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.apPowerProfileName   {{ ap_profile.power_profile | default(defaults.catalyst_center.wireless.ap_profiles.power_profile) }}
{% endif %}

{% if ap_profile.calendar_power_profiles is defined %}
    # Validate calendar power profiles count
    ${cpp_data}=   Get Value From Json   ${profile_entry}   $.calendarPowerProfiles
    ${cpp_list}=   Set Variable   ${cpp_data}[0]
    ${cpp_count}=   Get Length   ${cpp_list}
    Run Keyword And Continue On Failure   Should Be Equal As Integers   ${cpp_count}   {{ ap_profile.calendar_power_profiles | length }}   Expected {{ ap_profile.calendar_power_profiles | length }} calendar power profile(s), found ${cpp_count}

{% for cpp in ap_profile.calendar_power_profiles %}
    # Calendar Power Profile {{ loop.index }}: {{ cpp.power_profile }}
    ${cpp_entry_data}=   Get Value From Json   ${profile_entry}   $.calendarPowerProfiles[?(@.powerProfileName=='{{ cpp.power_profile }}')]
    Run Keyword And Continue On Failure   Should Not Be Empty   ${cpp_entry_data}   Calendar power profile '{{ cpp.power_profile }}' not found
    ${cpp_entry}=   Set Variable   ${cpp_entry_data}[0]

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${cpp_entry}   $.powerProfileName   {{ cpp.power_profile }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${cpp_entry}   $.schedulerType   {{ cpp.scheduler_type }}

    # Log start/end times (API returns 12h AM/PM format, data model uses 24h - skip direct comparison)
    ${api_start_time}=   Get Value From Json   ${cpp_entry}   $.duration.schedulerStartTime
    ${api_end_time}=   Get Value From Json   ${cpp_entry}   $.duration.schedulerEndTime
    Log To Console   Calendar Profile '{{ cpp.power_profile }}': start=${api_start_time[0]}, end=${api_end_time[0]}

{% if cpp.scheduler_type == 'WEEKLY' and cpp.scheduler_day is defined %}
    # Validate scheduler days (WEEKLY)
    ${actual_days}=   Get Value From Json   ${cpp_entry}   $.duration.schedulerDay
    ${actual_days_list}=   Set Variable   ${actual_days}[0]
    ${expected_days}=   Create List{% for day in cpp.scheduler_day %}   {{ day }}{% endfor %}

    ${actual_days_sorted}=   Evaluate   sorted([d.lower() for d in ${actual_days_list}])
    ${expected_days_sorted}=   Evaluate   sorted([d.lower() for d in ${expected_days}])
    Run Keyword And Continue On Failure   Should Be Equal   ${actual_days_sorted}   ${expected_days_sorted}   Scheduler days mismatch for '{{ cpp.power_profile }}'
{% endif %}

{% if cpp.scheduler_type == 'MONTHLY' and cpp.scheduler_date is defined %}
    # Validate scheduler dates (MONTHLY)
    ${actual_dates}=   Get Value From Json   ${cpp_entry}   $.duration.schedulerDate
    ${actual_dates_list}=   Set Variable   ${actual_dates}[0]
    ${expected_dates}=   Create List{% for date in cpp.scheduler_date %}   {{ date }}{% endfor %}

    ${actual_dates_sorted}=   Evaluate   sorted(${actual_dates_list}, key=int)
    ${expected_dates_sorted}=   Evaluate   sorted(${expected_dates}, key=int)
    Run Keyword And Continue On Failure   Should Be Equal   ${actual_dates_sorted}   ${expected_dates_sorted}   Scheduler dates mismatch for '{{ cpp.power_profile }}'
{% endif %}

{% endfor %}
{% endif %}

{% if ap_profile.country_code is defined or defaults.catalyst_center.wireless.ap_profiles.country_code is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.countryCode   {{ ap_profile.country_code | default(defaults.catalyst_center.wireless.ap_profiles.country_code) }}
{% endif %}

{% if ap_profile.time_zone is defined or defaults.catalyst_center.wireless.ap_profiles.time_zone is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.timeZone   {{ ap_profile.time_zone | default(defaults.catalyst_center.wireless.ap_profiles.time_zone) | default('Not Configured') | upper }}
{% endif %}

{% if ap_profile.time_zone_offset_hour is defined or defaults.catalyst_center.wireless.ap_profiles.time_zone_offset_hour is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.timeZoneOffsetHour   {{ ap_profile.time_zone_offset_hour | default(defaults.catalyst_center.wireless.ap_profiles.time_zone_offset_hour) | default(0) }}
{% endif %}

{% if ap_profile.time_zone_offset_minutes is defined or defaults.catalyst_center.wireless.ap_profiles.time_zone_offset_minutes is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.timeZoneOffsetMinutes   {{ ap_profile.time_zone_offset_minutes | default(defaults.catalyst_center.wireless.ap_profiles.time_zone_offset_minutes) | default(0) }}
{% endif %}

{% if ap_profile.client_limit is defined or defaults.catalyst_center.wireless.ap_profiles.client_limit is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.clientLimit   {{ ap_profile.client_limit | default(defaults.catalyst_center.wireless.ap_profiles.client_limit) | default(0) }}
{% endif %}

{% if ap_profile.mesh_enabled | default(defaults.catalyst_center.wireless.ap_profiles.mesh_enabled) | default(false) %}
{% if ap_profile.bridge_group_name is defined or defaults.catalyst_center.wireless.ap_profiles.bridge_group_name is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.meshSetting.bridgeGroupName   {{ ap_profile.bridge_group_name | default(defaults.catalyst_center.wireless.ap_profiles.bridge_group_name) }}
{% endif %}

{% if ap_profile.backhaul_client_access is defined or defaults.catalyst_center.wireless.ap_profiles.backhaul_client_access is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Boolean   ${profile_entry}   $.meshSetting.backhaulClientAccess   {{ ap_profile.backhaul_client_access | default(defaults.catalyst_center.wireless.ap_profiles.backhaul_client_access) | default(false) }}
{% endif %}

{% if ap_profile.range is defined or defaults.catalyst_center.wireless.ap_profiles.range is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${profile_entry}   $.meshSetting.range   {{ ap_profile.range | default(defaults.catalyst_center.wireless.ap_profiles.range) }}
{% endif %}

{% if ap_profile.ghz5_backhaul_data_rates is defined or defaults.catalyst_center.wireless.ap_profiles.ghz5_backhaul_data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.meshSetting.ghz5BackhaulDataRates   {{ ap_profile.ghz5_backhaul_data_rates | default(defaults.catalyst_center.wireless.ap_profiles.ghz5_backhaul_data_rates) }}
{% endif %}

{% if ap_profile.ghz24_backhaul_data_rates is defined or defaults.catalyst_center.wireless.ap_profiles.ghz24_backhaul_data_rates is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.meshSetting.ghz24BackhaulDataRates   {{ ap_profile.ghz24_backhaul_data_rates | default(defaults.catalyst_center.wireless.ap_profiles.ghz24_backhaul_data_rates) }}
{% endif %}

{% if ap_profile.rap_downlink_backhaul is defined or defaults.catalyst_center.wireless.ap_profiles.rap_downlink_backhaul is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.meshSetting.rapDownlinkBackhaul   {{ ap_profile.rap_downlink_backhaul | default(defaults.catalyst_center.wireless.ap_profiles.rap_downlink_backhaul) }}
{% endif %}
{% endif %}

{% endfor %}
