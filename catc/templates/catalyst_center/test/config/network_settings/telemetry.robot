*** Settings ***
Documentation     Verify Telemetry Settings for All Sites
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   network_settings   telemetry

*** Test Cases ***

{% set all_sites = [] %}
{% if catalyst_center.sites is defined %}
{% for area in catalyst_center.sites.areas | default([]) %}
    {% set _ = all_sites.append({'type': 'Area', 'name': area.name, 'parent_name': area.get('parent_name',''), 'network_settings': area.get('network_settings', {})}) %}
{% endfor %}
{% for building in catalyst_center.sites.buildings | default([]) %}
    {% set _ = all_sites.append({'type': 'Building', 'name': building.name, 'parent_name': building.get('parent_name',''), 'network_settings': building.get('network_settings', {})}) %}
{% endfor %}
{% for floor in catalyst_center.sites.floors | default([]) %}
    {% set _ = all_sites.append({'type': 'Floor', 'name': floor.name, 'parent_name': floor.get('parent_name',''), 'network_settings': floor.get('network_settings', {})}) %}
{% endfor %}
{% endif %}

{% for site in all_sites %}
    {% set net = site.network_settings %}
    {% if net.get('telemetry', None) %}
        {% set telemetry_name = net['telemetry'] %}
        {% set telemetry = (catalyst_center.network_settings.telemetry | selectattr('name','equalto',telemetry_name) | list)[0] if telemetry_name is string else net['telemetry'] %}
        {% set site_hierarchy = (site.parent_name ~ '/' ~ site.name) if site.parent_name else site.name %}
        {% set is_global = (site_hierarchy == 'Global') %}
Verify Telemetry Settings for {{ site.type }} {{ site_hierarchy }}
{% if not is_global %}
    [Tags]   site_specific
{% endif %}

    # Validate that the site exists in the Sites API response
    ${site_hierarchy}=   Set Variable   {{ site_hierarchy }}

    # Check if this site should be skipped based on MANAGED_SITES
    ${should_skip}=   Should Skip Site Validation   ${site_hierarchy}
    Pass Execution If   ${should_skip}   {{ site.type }} ${site_hierarchy} not managed by this deployment state - skipping validation

    ${s}=   Get Cached Sites Data
    # For Global site, use name field; for others, use nameHierarchy field
    ${site_data}=   Run Keyword If   '${site_hierarchy}' == 'Global'   Get Value From Json   ${s.json()}   $.response[?(@.name=='Global')]
    ...   ELSE   Get Value From Json   ${s.json()}   $.response[?(@.nameHierarchy=='${site_hierarchy}')]
    Log To Console   Site data for ${site_hierarchy}: ${site_data}
    Run Keyword If   not ${site_data}   Fail   {{ site.type }} ${site_hierarchy} not found in Sites API response.
    
    # Extract site information
    ${site_entry}=   Set Variable   ${site_data}[0]
    ${site_id}=   Get From Dictionary   ${site_entry}   id
    Log To Console   Site ID for ${site_hierarchy}: ${site_id}

    # Get telemetry settings for this site
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/telemetrySettings?_inherited=true
    Log   Response Status Code (Telemetry): ${r.status_code}
    Log To Console   Telemetry API Response: ${r.json()}
    Run Keyword And Continue On Failure   Should Be Equal As Integers   ${r.status_code}   200

    # Validate basic telemetry settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.wiredDataCollection.enableWiredDataCollection      {{ telemetry.wired_data_collection | default(defaults.catalyst_center.network_settings.telemetry.wired_data_collection) }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.wirelessTelemetry.enableWirelessTelemetry         {{ telemetry.wireless_telemetry | default(defaults.catalyst_center.network_settings.telemetry.wireless_telemetry) }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.applicationVisibility.enableOnWiredAccessDevices   {{ telemetry.enable_netflow_collector_on_devices | default(defaults.catalyst_center.network_settings.telemetry.enable_netflow_collector_on_devices) }}

{% if telemetry.catalyst_center_as_network_collector | default(defaults.catalyst_center.network_settings.telemetry.catalyst_center_as_network_collector) %}
    # Validate built-in collector settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.applicationVisibility.collector.collectorType   Builtin
{% else %}
    # Validate external collector settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.applicationVisibility.collector.collectorType   TelemetryBrokerOrUDPDirector
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.applicationVisibility.collector.address          {{ telemetry.netflow_collector_ip_address | default(defaults.catalyst_center.network_settings.telemetry.netflow_collector_ip_address) }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.applicationVisibility.collector.port             {{ telemetry.netflow_collector_port | default(defaults.catalyst_center.network_settings.telemetry.netflow_collector_port) }}
{% endif %}

    # Validate SNMP trap server settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.snmpTraps.useBuiltinTrapServer   {{ telemetry.catalyst_center_as_snmp_server | default(defaults.catalyst_center.network_settings.telemetry.catalyst_center_as_snmp_server) }}
{% if telemetry.snmp_servers is defined %}
    ${model_snmp_servers}=   Create List   {{ telemetry.snmp_servers | join('   ') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${r.json()}   $.response.snmpTraps.externalTrapServers   ${model_snmp_servers}
{% endif %}

    # Validate syslog server settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.syslogs.useBuiltinSyslogServer   {{ telemetry.catalyst_center_as_syslog_server | default(defaults.catalyst_center.network_settings.telemetry.catalyst_center_as_syslog_server) }}
{% if telemetry.syslog_servers is defined %}
    ${model_syslog_servers}=   Create List   {{ telemetry.syslog_servers | join('   ') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${r.json()}   $.response.syslogs.externalSyslogServers   ${model_syslog_servers}
{% endif %}

    {% endif %}
{% endfor %}
