*** Settings ***
Documentation   Verify Network Settings IP Pools Reservations
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   ip_pools    ip_pools_reservations   site_specific

*** Test Cases ***

{% set reservations_dict = {} %}
{% if catalyst_center.sites is defined and catalyst_center.sites.areas is defined %}
{% for site in catalyst_center.sites.areas %}
{% for ip_pool_reservation in site.ip_pools_reservations | default([]) %}
{% set _ = reservations_dict.update({ip_pool_reservation: (site.parent_name ~ '/' ~ site.name) if site.parent_name else site.name}) %}
{% endfor %}
{% endfor %}
{% endif %}
{% if catalyst_center.sites is defined and catalyst_center.sites.buildings is defined %}
{% for building in catalyst_center.sites.buildings %}
{% for ip_pool_reservation in building.ip_pools_reservations | default([]) %}
{% set _ = reservations_dict.update({ip_pool_reservation: (building.parent_name ~ '/' ~ building.name) if building.parent_name else building.name}) %}
{% endfor %}
{% endfor %}
{% endif %}
{% if catalyst_center.sites is defined and catalyst_center.sites.floors is defined %}
{% for floor in catalyst_center.sites.floors %}
{% for ip_pool_reservation in floor.ip_pools_reservations | default([]) %}
{% set _ = reservations_dict.update({ip_pool_reservation: (floor.parent_name ~ '/' ~ floor.name) if floor.parent_name else floor.name}) %}
{% endfor %}
{% endfor %}
{% endif %}

{% for ip_pools in catalyst_center.network_settings.ip_pools | default([]) %}
{% for ip_pool_reservation in ip_pools.ip_pools_reservations | default([]) %}
{% if ip_pool_reservation.name in reservations_dict %}
Verify IP Pool {{ ip_pool_reservation.name }} ({{ ip_pools.ip_address_space }})
    Set Log Level       Debug

    # Check if the site for this reservation should be skipped based on MANAGED_SITES
    ${site_hierarchy}=   Set Variable   {{ reservations_dict[ip_pool_reservation.name] }}
    ${should_skip}=   Should Skip Site Validation   ${site_hierarchy}
    Pass Execution If   ${should_skip}   IP Pool reservation ${site_hierarchy} not managed by this deployment state - skipping validation

    ${sites}=   Get Cached Sites Data
    ${site_id}=   Get Value From Json   ${sites.json()}   $.response[?(@.nameHierarchy=='{{ reservations_dict[ip_pool_reservation.name] }}')]["id"]
    Run Keyword If   not ${site_id}   Fail   Site {{ reservations_dict[ip_pool_reservation.name] }} not found in Catalyst Center - deployment issue
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/reserve-ip-subpool?siteId=${site_id}[0]&groupName={{ip_pool_reservation.name}}
    Should Be Equal Value Json String   ${r.json()}   $.response[0].groupName   {{ ip_pool_reservation.name }}

    # Find the specific IP pool by CIDR (handles both IPv4 and IPv6 pools with same name)
    ${expected_cidr}=   Set Variable   {{ ip_pool_reservation.subnet ~ '/' ~ ip_pool_reservation.prefix_length }}
    ${pool_data}=   Get Value From Json   ${r.json()}   $.response[0].ipPools[?(@.ipPoolCidr=='${expected_cidr}')]
    Run Keyword If   not ${pool_data}   Fail   IP Pool with CIDR ${expected_cidr} not found in group {{ ip_pool_reservation.name }}
    ${pool_entry}=   Set Variable   ${pool_data}[0]

    # Validate IP pool attributes
    Should Be Equal Value Json String   ${pool_entry}   $.ipPoolCidr   {{ ip_pool_reservation.subnet ~ '/' ~ ip_pool_reservation.prefix_length }}
    {% if ip_pool_reservation.gateway is defined %}
    Should Be Equal Value Json String   ${pool_entry}   $.gateways[0]   {{ ip_pool_reservation.gateway }}
    {% endif %}
    Should Be Equal Value Json String   ${r.json()}   $.response[0].type   {{ ip_pool_reservation.type | default(defaults.catalyst_center.network_settings.ip_pools.ip_pools_reservations.type) | lower }}

    # Validate DHCP servers
    {% if ip_pool_reservation.dhcp_servers is defined and ip_pool_reservation.dhcp_servers | length > 0 %}
    ${rec_dhcp_servers_list}=   Get Value From Json   ${pool_entry}   $.dhcpServerIps
    ${exp_dhcp_servers_list}=   Create List   {{ ip_pool_reservation.dhcp_servers | default([]) | join('   ') }}
    Lists Should Be Equal   ${rec_dhcp_servers_list}[0]   ${exp_dhcp_servers_list}   ignore_order=True   msg=dhcp servers
    {% endif %}

    # Validate DNS servers
    {% if ip_pool_reservation.dns_servers is defined and ip_pool_reservation.dns_servers | length > 0 %}
    ${rec_dns_servers_list}=   Get Value From Json   ${pool_entry}   $.dnsServerIps
    ${exp_dns_servers_list}=   Create List   {{ ip_pool_reservation.dns_servers | default([]) | join('   ') }}
    Lists Should Be Equal   ${rec_dns_servers_list}[0]   ${exp_dns_servers_list}   ignore_order=True   msg=dns servers
    {% endif %}

{% endif %}
{% endfor %}
{% endfor %}