*** Settings ***
Documentation   Verify Device Credentials HTTPS Write Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials

*** Test Cases ***

Get HTTPS Write Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Set Suite Variable   ${r}

{% for https_write_credential in catalyst_center.network_settings.device_credentials.https_write_credentials | default([]) %}
Verify HTTPS Write Credential {{ https_write_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.httpsWrite[?(@.description=='{{ https_write_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ https_write_credential.name }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.username   {{ https_write_credential.username }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.port   {{ https_write_credential.port | default(defaults.catalyst_center.network_settings.device_credentials.https_write_credentials.port) }}  
{% endfor %} 