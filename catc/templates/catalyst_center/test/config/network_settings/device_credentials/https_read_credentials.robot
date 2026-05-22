*** Settings ***
Documentation   Verify Device Credentials HTTPS Read Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials

*** Test Cases ***

Get HTTPS Read Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Set Suite Variable   ${r}

{% for https_read_credential in catalyst_center.network_settings.device_credentials.https_read_credentials | default([]) %}
Verify HTTPS Read Credential {{ https_read_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.httpsRead[?(@.description=='{{ https_read_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ https_read_credential.name }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.username   {{ https_read_credential.username }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.port   {{ https_read_credential.port | default(defaults.catalyst_center.network_settings.device_credentials.https_read_credentials.port) }} 
{% endfor %} 