*** Settings ***
Documentation   Verify Device Credentials SNMPv2 Write Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials

*** Test Cases ***

Get SNMPv2 Write Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Set Suite Variable   ${r}

{% for snmpv2_write_credential in catalyst_center.network_settings.device_credentials.snmpv2_write_credentials | default([]) %}
Verify SNMPv2 Write Credential {{ snmpv2_write_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.snmpV2cWrite[?(@.description=='{{ snmpv2_write_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ snmpv2_write_credential.name }}
{% endfor %} 
