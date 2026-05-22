*** Settings ***
Documentation   Verify Device Credentials CLI Credentials
Suite Setup     Login CatalystCenter
Resource        ../../../catalyst_center_common.resource
Default Tags    config   catalyst_center   network_settings   device_credentials   cli_credentials

*** Test Cases ***

Get CLI Credentials
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v2/global-credential
    Log   Response Status Code: ${r.status_code}
    Set Suite Variable   ${r}

{% for cli_credential in catalyst_center.network_settings.device_credentials.cli_credentials | default([]) %}
Verify cli credential {{ cli_credential.name }}
    ${cred_info}=   Get Value From Json   ${r.json()}   $.response.cliCredential[?(@.description=='{{ cli_credential.name }}')]
    Should Be Equal Value Json String   ${cred_info[0]}   $.description   {{ cli_credential.name }}
    Should Be Equal Value Json String   ${cred_info[0]}   $.username   {{ cli_credential.username }}
{% endfor %} 
