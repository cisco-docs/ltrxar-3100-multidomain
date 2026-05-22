*** Settings ***
Documentation     Verify Network Server Settings for All Sites
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   network_settings   network_servers

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
    {% if net.get('network', None) %}
        {% set network_name = net['network'] %}
        {% set network = (catalyst_center.network_settings.network | selectattr('name','equalto',network_name) | list)[0] %}
        {% set site_hierarchy = (site.parent_name ~ '/' ~ site.name) if site.parent_name else site.name %}
        {% set is_global = (site_hierarchy == 'Global') %}
Verify Network Server Settings for {{ site.type }} {{ site_hierarchy }}
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

{% if network.get('dns_servers', None) or network.get('domain_name', None) %}
    # Validate DNS settings
    ${dns}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/dnsSettings?_inherited=true
    Log   Response Status Code (DNS): ${dns.status_code}
    Log To Console   DNS API Response: ${dns.json()}
    
{% if network.get('domain_name', None) %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${dns.json()}   $.response.dns.domainName   {{ network.domain_name | default(defaults.catalyst_center.network_settings.network.domain_name) }}
{% endif %}
{% if network.get('dns_servers', None) %}
    ${api_dns_servers}=   Get Value From Json   ${dns.json()}   $.response.dns.dnsServers
    ${model_dns_servers}=   Create List   {{ network.dns_servers | join('   ') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${dns.json()}   $.response.dns.dnsServers   ${model_dns_servers}
{% endif %}
{% endif %}

{% if network.get('dhcp_servers', None) %}
    # Validate DHCP settings
    ${dhcp}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/dhcpSettings?_inherited=true
    Log   Response Status Code (DHCP): ${dhcp.status_code}
    Log To Console   DHCP API Response: ${dhcp.json()}
    
    ${model_dhcp_servers}=   Create List   {{ network.dhcp_servers | default(defaults.catalyst_center.network_settings.network.dhcp_servers) | join('   ') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${dhcp.json()}   $.response.dhcp.servers   ${model_dhcp_servers}
{% endif %}

{% if network.get('ntp_servers', None) %}
    # Validate NTP settings
    ${ntp}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/ntpSettings?_inherited=true
    Log   Response Status Code (NTP): ${ntp.status_code}
    Log To Console   NTP API Response: ${ntp.json()}
    
    ${model_ntp_servers}=   Create List   {{ network.ntp_servers | default(defaults.catalyst_center.network_settings.network.ntp_servers) | join('   ') }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json List   ${ntp.json()}   $.response.ntp.servers   ${model_ntp_servers}
{% endif %}

{% if network.get('timezone', None) %}
    # Validate timezone settings
    ${timezone}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/timeZoneSettings?_inherited=true
    Log   Response Status Code (Timezone): ${timezone.status_code}
    Log To Console   Timezone API Response: ${timezone.json()}
    
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${timezone.json()}   $.response.timeZone.identifier   {{ network.timezone | default(defaults.catalyst_center.network_settings.network.timezone) }}
{% endif %}

{% if network.get('banner', None) %}
    # Validate banner settings
    ${banner}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/sites/${site_id}/bannerSettings?_inherited=true
    Log   Response Status Code (Banner): ${banner.status_code}
    Log To Console   Banner API Response: ${banner.json()}
    
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${banner.json()}   $.response.banner.message   {{ network.banner | default(defaults.catalyst_center.network_settings.network.banner) }}
{% endif %}

    {% endif %}
{% endfor %}
