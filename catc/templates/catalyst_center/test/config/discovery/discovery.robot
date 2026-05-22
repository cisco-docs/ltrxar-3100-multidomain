*** Settings ***
Documentation     Verify Discovery Configurations in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   inventory   discovery

*** Test Cases ***

Check Discovery Configuration in Data Model
    # Check if any discoveries are configured in the data model
    {% set discovery_list = catalyst_center.inventory.discovery | default([]) %}
    {% if not discovery_list %}
    Pass Execution   No discoveries configured in data model - skipping discovery validation tests
    {% else %}
    Log   Found {{ discovery_list | length }} discovery configuration(s) in data model
    {% endif %}

Get Discovery Configurations
    # Only execute if discoveries are configured in data model
    {% if catalyst_center.inventory.discovery | default([]) %}
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/discovery/1/100
    ${g}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Log   Response Status Code (Discovery): ${r.status_code}
    Log   Response Status Code (Global Credential): ${g.status_code}
    Log To Console   Discovery API Response: ${r.json()}
    Log To Console   Global Credential API Response: ${g.json()}
    Set Suite Variable   ${r}
    Set Suite Variable   ${g}
    {% else %}
    Pass Execution   No discoveries configured in data model - skipping API calls
    {% endif %}

{% for discovery in catalyst_center.inventory.discovery | default([]) %}
Verify Discovery {{ discovery.name }}

    # Validate that the discovery exists in the API response
    ${discovery_data}=   Get Value From Json   ${r.json()}   $.response[?(@.name=='{{ discovery.name }}')]
    Log To Console   Discovery data: ${discovery_data}
    Run Keyword If   not ${discovery_data}   Fail   Discovery {{ discovery.name }} not found in Discovery API response.

    # Extract the matching discovery
    ${discovery_entry}=   Set Variable   ${discovery_data}[0]
    Log To Console   Extracted Discovery Entry: ${discovery_entry}

    # Validate discovery attributes
    Should Be Equal As Strings   ${discovery_entry['name']}   {{ discovery.name }}
    # Handle API issue: "Multi Range" type is returned as "Range" in GET response
    {% if (discovery.type | default(defaults.catalyst_center.inventory.discovery.type)) == 'Multi Range' %}
    Should Be Equal As Strings   ${discovery_entry['discoveryType']}   Range
    {% else %}
    Should Be Equal As Strings   ${discovery_entry['discoveryType']}   {{ discovery.type | default(defaults.catalyst_center.inventory.discovery.type) }}
    {% endif %}
    Should Be Equal As Strings   ${discovery_entry['ipAddressList']}   {{ discovery.ip_address_list | default(defaults.catalyst_center.inventory.discovery.ip_address_list) }}
    Should Be Equal As Strings   ${discovery_entry['protocolOrder']}   {{ discovery.protocol_order | default(defaults.catalyst_center.inventory.discovery.protocol_order) }}
    Should Be Equal As Strings   ${discovery_entry['preferredMgmtIPMethod']}   {{ discovery.preferred_mgmt_ip_method | default(defaults.catalyst_center.inventory.discovery.preferred_mgmt_ip_method) | default('None') }}
    
    # Validate optional timeout attribute
    {% if discovery.time_out is defined or defaults.catalyst_center.inventory.discovery.time_out is defined %}
    Should Be Equal As Numbers   ${discovery_entry['timeOut']}   {{ discovery.time_out | default(defaults.catalyst_center.inventory.discovery.time_out) }}
    {% endif %}
    
    # Validate optional retry count attribute
    {% if discovery.retry is defined or defaults.catalyst_center.inventory.discovery.retry is defined %}
    Should Be Equal As Numbers   ${discovery_entry['retryCount']}   {{ discovery.retry | default(defaults.catalyst_center.inventory.discovery.retry) }}
    {% endif %}
    
    # Validate optional netconf port attribute
    {% if discovery.netconf_port is defined or defaults.catalyst_center.inventory.discovery.netconf_port is defined %}
    Should Be Equal As Strings   ${discovery_entry['netconfPort']}   {{ discovery.netconf_port | default(defaults.catalyst_center.inventory.discovery.netconf_port) }}
    {% endif %}
    
    # Validate optional CDP level attribute
    {% if discovery.cdp_level is defined or defaults.catalyst_center.inventory.discovery.cdp_level is defined %}
    Should Be Equal As Numbers   ${discovery_entry['cdpLevel']}   {{ discovery.cdp_level | default(defaults.catalyst_center.inventory.discovery.cdp_level) }}
    {% endif %}

    # Validate optional LLDP level attribute
    {% if discovery.lldp_level is defined or defaults.catalyst_center.inventory.discovery.lldp_level is defined %}
    Should Be Equal As Numbers   ${discovery_entry['lldpLevel']}   {{ discovery.lldp_level | default(defaults.catalyst_center.inventory.discovery.lldp_level) }}
    {% endif %}

    # Validate global credentials
    {% for credential_name in discovery.global_credential_list %}
    # Search for credential across all credential types
    ${cli_credential_data}=   Get Value From Json   ${g.json()}   $.response.cliCredential[?(@.description=='{{ credential_name }}')]
    ${snmpv2_read_credential_data}=   Get Value From Json   ${g.json()}   $.response.snmpV2cRead[?(@.description=='{{ credential_name }}')]
    ${snmpv2_write_credential_data}=   Get Value From Json   ${g.json()}   $.response.snmpV2cWrite[?(@.description=='{{ credential_name }}')]
    ${snmpv3_credential_data}=   Get Value From Json   ${g.json()}   $.response.snmpV3[?(@.description=='{{ credential_name }}')]
    ${https_read_credential_data}=   Get Value From Json   ${g.json()}   $.response.httpsRead[?(@.description=='{{ credential_name }}')]
    ${https_write_credential_data}=   Get Value From Json   ${g.json()}   $.response.httpsWrite[?(@.description=='{{ credential_name }}')]
    ${netconf_credential_data}=   Get Value From Json   ${g.json()}   $.response.netconfCredential[?(@.description=='{{ credential_name }}')]

    # Determine which credential type was found and set variables accordingly
    IF    ${cli_credential_data}
        ${credential_data}=   Set Variable   ${cli_credential_data}
        ${credential_type}=   Set Variable   CLI
    ELSE IF    ${snmpv2_read_credential_data}
        ${credential_data}=   Set Variable   ${snmpv2_read_credential_data}
        ${credential_type}=   Set Variable   SNMP v2 Read
    ELSE IF    ${snmpv2_write_credential_data}
        ${credential_data}=   Set Variable   ${snmpv2_write_credential_data}
        ${credential_type}=   Set Variable   SNMP v2 Write
    ELSE IF    ${snmpv3_credential_data}
        ${credential_data}=   Set Variable   ${snmpv3_credential_data}
        ${credential_type}=   Set Variable   SNMP v3
    ELSE IF    ${https_read_credential_data}
        ${credential_data}=   Set Variable   ${https_read_credential_data}
        ${credential_type}=   Set Variable   HTTPS Read
    ELSE IF    ${https_write_credential_data}
        ${credential_data}=   Set Variable   ${https_write_credential_data}
        ${credential_type}=   Set Variable   HTTPS Write
    ELSE IF    ${netconf_credential_data}
        ${credential_data}=   Set Variable   ${netconf_credential_data}
        ${credential_type}=   Set Variable   NETCONF
    ELSE
        ${credential_data}=   Set Variable   ${EMPTY}
        ${credential_type}=   Set Variable   Not Found
    END

    Log To Console   Credential data for {{ credential_name }} (${credential_type}): ${credential_data}
    Run Keyword If   not ${credential_data}   Fail   Global credential {{ credential_name }} not found in any credential type in Global Credential API response.

    # Extract the credential ID
    ${credential_entry}=   Set Variable   ${credential_data}[0]
    ${credential_id}=   Set Variable   ${credential_entry['id']}
    Log To Console   Extracted Credential ID for {{ credential_name }}: ${credential_id}

    # Verify the credential ID is in the discovery's globalCredentialIdList
    Log To Console   Verifying credential ID ${credential_id} is in globalCredentialIdList: ${discovery_entry['globalCredentialIdList']}
    List Should Contain Value   ${discovery_entry['globalCredentialIdList']}   ${credential_id}   Credential {{ credential_name }} (${credential_type} - ID: ${credential_id}) not found in discovery's globalCredentialIdList: ${discovery_entry['globalCredentialIdList']}

    {% endfor %}
{% endfor %}
