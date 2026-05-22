*** Settings ***
Documentation     Verify Network Settings AAA Servers
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   network_settings   aaa_servers   aaa_settings

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
    {% if net.get('aaa_servers', None) %}
        {% set aaa_name = net['aaa_servers'] %}
        {% set aaa_server = (catalyst_center.network_settings.aaa_servers | selectattr('name','equalto',aaa_name) | list)[0] %}
        {% set site_hierarchy = (site.parent_name ~ '/' ~ site.name) if site.parent_name else site.name %}
        {% set is_global = (site_hierarchy == 'Global') %}
Verify AAA Settings for {{ site.type }} {{ site_hierarchy }}
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

    # Get AAA settings for this site
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/aaaSettings?_inherited=true
    Log   Response Status Code (AAA Settings): ${r.status_code}
    Log To Console   AAA Settings API Response: ${r.json()}
    Run Keyword And Continue On Failure   Should Be Equal As Integers   ${r.status_code}   200

    # Validate AAA Network settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaNetwork.serverType         {{ aaa_server.network_aaa.server_type | default(defaults.catalyst_center.network_settings.aaa_servers.network_aaa.server_type) | default('') }}
    # the following line was blocked due to api defect
    # Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaNetwork.protocol           {{ aaa_server.network_aaa.protocol | default(defaults.catalyst_center.network_settings.aaa_servers.network_aaa.protocol) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaNetwork.primaryServerIp    {{ aaa_server.network_aaa.primary_ip | default(defaults.catalyst_center.network_settings.aaa_servers.network_aaa.primary_ip) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaNetwork.secondaryServerIp  {{ aaa_server.network_aaa.secondary_ip | default(defaults.catalyst_center.network_settings.aaa_servers.network_aaa.secondary_ip) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaNetwork.pan                {{ aaa_server.network_aaa.pan | default(defaults.catalyst_center.network_settings.aaa_servers.network_aaa.pan) | default('') }}

    # Validate AAA Client and Endpoint settings
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaClient.serverType          {{ aaa_server.client_and_endpoint_aaa.server_type | default(defaults.catalyst_center.network_settings.aaa_servers.client_and_endpoint_aaa.server_type) | default('') }}
    # the following line was blocked due to api defect
    # Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaClient.protocol            {{ aaa_server.client_and_endpoint_aaa.protocol | default(defaults.catalyst_center.network_settings.aaa_servers.client_and_endpoint_aaa.protocol) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaClient.primaryServerIp     {{ aaa_server.client_and_endpoint_aaa.primary_ip | default(defaults.catalyst_center.network_settings.aaa_servers.client_and_endpoint_aaa.primary_ip) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaClient.secondaryServerIp   {{ aaa_server.client_and_endpoint_aaa.secondary_ip | default(defaults.catalyst_center.network_settings.aaa_servers.client_and_endpoint_aaa.secondary_ip) | default('') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.aaaClient.pan                 {{ aaa_server.client_and_endpoint_aaa.pan | default(defaults.catalyst_center.network_settings.aaa_servers.client_and_endpoint_aaa.pan) | default('') }}

    {% endif %}
{% endfor %}
