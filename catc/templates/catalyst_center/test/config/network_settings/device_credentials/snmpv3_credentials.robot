*** Settings ***
Documentation   Verify Device Credentials SNMPv3 Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials

*** Test Cases ***

Get SNMPv3 Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Set Suite Variable   ${r}

{% for snmpv3_credential in catalyst_center.network_settings.device_credentials.snmpv3_credentials | default([]) %}
Verify SNMPv3 Credential {{ snmpv3_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.snmpV3[?(@.description=='{{ snmpv3_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ snmpv3_credential.name }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.authType   {{ snmpv3_credential.auth_type | default(defaults.catalyst_center.network_settings.device_credentials.snmpv3_credentials.auth_type) }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.privacyType   {{ snmpv3_credential.privacy_type | default(defaults.catalyst_center.network_settings.device_credentials.snmpv3_credentials.privacy_type) }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.snmpMode   {{ snmpv3_credential.snmp_mode }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.username   {{ snmpv3_credential.username }}
{% endfor %} 