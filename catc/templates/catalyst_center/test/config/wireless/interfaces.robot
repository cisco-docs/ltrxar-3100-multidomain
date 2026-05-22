*** Settings ***
Documentation     Verify Wireless Interfaces in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   interfaces

*** Test Cases ***

Check Wireless Interfaces Configuration in Data Model
    # Check if wireless interfaces are configured in the data model
    {% if catalyst_center.wireless is not defined or catalyst_center.wireless.interfaces is not defined or catalyst_center.wireless.interfaces | length == 0 %}
    Pass Execution   No wireless interfaces configured in data model - skipping wireless interfaces validation tests
    {% else %}
    Log   Found {{ catalyst_center.wireless.interfaces | length }} wireless interface(s) in data model
    {% endif %}

Get Wireless Interfaces
    {% if catalyst_center.wireless is defined and catalyst_center.wireless.interfaces is defined and catalyst_center.wireless.interfaces | length > 0 %}
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/wirelessSettings/interfaces
    Log   Response Status Code: ${r.status_code}
    Log To Console   Wireless Interfaces API Response: ${r.json()}
    Set Suite Variable   ${r}
    {% else %}
    Pass Execution   No wireless interfaces configured in data model - skipping API calls
    {% endif %}

{% for interface in catalyst_center.wireless.interfaces | default([]) %}
Verify Wireless Interface {{ interface.name }}
    # Validate that the wireless interface exists in the API response
    ${interface_data}=   Get Value From Json   ${r.json()}   $.response[?(@.interfaceName=='{{ interface.name }}')]
    ${interface_count}=   Get Length   ${interface_data}
    Run Keyword If   ${interface_count} == 0   Fail   Wireless interface {{ interface.name }} not found in API response.

    # Extract the first matching interface from the API response
    ${interface_entry}=   Set Variable   ${interface_data}[0]
    Log To Console   Extracted Wireless Interface Entry: ${interface_entry}

    # Validate interface name
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${interface_entry}   $.interfaceName   {{ interface.name }}

    # Validate VLAN ID
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${interface_entry}   $.vlanId   {{ interface.vlan_id }}

    Log To Console   Wireless interface {{ interface.name }} validation completed

{% endfor %}

