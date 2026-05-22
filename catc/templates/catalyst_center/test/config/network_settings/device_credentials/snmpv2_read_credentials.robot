*** Settings ***
Documentation   Verify Device Credentials SNMPv2 Read Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials

*** Test Cases ***

Get SNMPv2 Read Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Set Suite Variable   ${r}

{% for snmpv2_read_credential in catalyst_center.network_settings.device_credentials.snmpv2_read_credentials | default([]) %}
Verify SNMPv2 Read Credential {{ snmpv2_read_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.snmpV2cRead[?(@.description=='{{ snmpv2_read_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ snmpv2_read_credential.name }}
{% endfor %} 
