*** Settings ***
Documentation     Verify Authentication and Policy Servers in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   system_settings   authentication_policy_servers

*** Test Cases ***

Get Authentication and Policy Servers
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/authentication-policy-servers
    Log   Response Status Code: ${r.status_code}
    Log To Console   Authentication and Policy Servers API Response: ${r.json()}
    Set Suite Variable   ${r}

{% if catalyst_center.system_settings.authentication_and_policy_servers.ise is defined %}
Verify ISE Server
    Log To Console   Validating ISE server configuration

    # Find ISE server entry in API response
    ${ise_entry}=   Get Value From Json   ${r.json()}   $.response[?(@.isIseEnabled==true)]
    Run Keyword If   not ${ise_entry}   Fail   ISE server not found in API response
    ${ise_server}=   Set Variable   ${ise_entry}[0]

    # Validate basic ISE server attributes
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response[?(@.isIseEnabled==true)].ipAddress   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.ip_address }}
    
    # Validate protocol (can be RADIUS, TACACS, or RADIUS_TACACS)
    ${protocol}=   Get Value From Json   ${ise_server}   $.protocol
    ${protocol_valid}=   Evaluate   "${protocol}[0]" in ["RADIUS", "TACACS", "RADIUS_TACACS"]
    Run Keyword And Continue On Failure   Should Be True   ${protocol_valid}   msg=Protocol should be RADIUS, TACACS, or RADIUS_TACACS, got ${protocol}[0]
    
    # Validate ISE enabled flags (comparing boolean values)
    ${is_ise_enabled}=   Get Value From Json   ${ise_server}   $.isIseEnabled
    ${ise_enabled}=   Get Value From Json   ${ise_server}   $.iseEnabled
    Run Keyword And Continue On Failure   Should Be True   ${is_ise_enabled}[0]   msg=isIseEnabled should be True
    Run Keyword And Continue On Failure   Should Be True   ${ise_enabled}[0]   msg=iseEnabled should be True
    
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response[?(@.isIseEnabled==true)].retries   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.retries }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response[?(@.isIseEnabled==true)].timeoutSeconds   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.timeout }}

    # Validate pxGrid settings
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.pxgrid_enabled is defined %}
    ${pxgrid_enabled}=   Get Value From Json   ${ise_server}   $.pxgridEnabled
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.pxgrid_enabled %}
    Run Keyword And Continue On Failure   Should Be True   ${pxgrid_enabled}[0]   msg=pxgridEnabled should be True
    {% else %}
    Run Keyword And Continue On Failure   Should Not Be True   ${pxgrid_enabled}[0]   msg=pxgridEnabled should be False
    {% endif %}
    {% endif %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.use_catc_cert_for_pxgrid is defined %}
    ${use_dnac_cert}=   Get Value From Json   ${ise_server}   $.useDnacCertForPxgrid
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.use_catc_cert_for_pxgrid %}
    Run Keyword And Continue On Failure   Should Be True   ${use_dnac_cert}[0]   msg=useDnacCertForPxgrid should be True
    {% else %}
    Run Keyword And Continue On Failure   Should Not Be True   ${use_dnac_cert}[0]   msg=useDnacCertForPxgrid should be False
    {% endif %}
    {% endif %}

    # Validate protocol settings
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols is defined %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.tacacs is defined %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.tacacs.port is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response[?(@.isIseEnabled==true)].port   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.tacacs.port }}
    {% endif %}
    {% endif %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius is defined %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius.authentication_port is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response[?(@.isIseEnabled==true)].authenticationPort   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius.authentication_port }}
    {% endif %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius.accounting_port is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response[?(@.isIseEnabled==true)].accountingPort   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius.accounting_port }}
    {% endif %}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.protocols.radius.enable_key_wrap is defined %}
    # Validate key wrap is enabled (encryptionScheme should be KEYWRAP)
    ${encryption_scheme}=   Get Value From Json   ${ise_server}   $.encryptionScheme
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${encryption_scheme}[0]   KEYWRAP   msg=Encryption scheme should be KEYWRAP when key wrap is enabled
    {% endif %}
    {% endif %}
    {% endif %}

    # Validate ISE integration details (ciscoIseDtos)
    ${cisco_ise_dtos}=   Get Value From Json   ${ise_server}   $.ciscoIseDtos
    Run Keyword If   not ${cisco_ise_dtos}   Fail   No Cisco ISE DTOs found in API response
    ${ise_dtos_list}=   Set Variable   ${cisco_ise_dtos}[0]

    # Find PRIMARY ISE entry
    ${primary_ise}=   Set Variable   ${None}
    FOR   ${dto}   IN   @{ise_dtos_list}
        ${dto_role}=   Get From Dictionary   ${dto}   role
        IF   '${dto_role}' == 'PRIMARY'
            ${primary_ise}=   Set Variable   ${dto}
            BREAK
        END
    END
    Run Keyword If   ${primary_ise} is ${None}   Fail   PRIMARY ISE entry not found in ciscoIseDtos

    # Validate PRIMARY ISE details
    ${primary_ip}=   Get From Dictionary   ${primary_ise}   ipAddress
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${primary_ip}   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.ip_address }}
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.username is defined %}
    ${primary_username}=   Get From Dictionary   ${primary_ise}   userName
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${primary_username}   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.username }}
    {% endif %}
    ${primary_trust_state}=   Get From Dictionary   ${primary_ise}   trustState
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${primary_trust_state}   TRUSTED

    # Find PXGRID ISE entry (if pxGrid is enabled)
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.pxgrid_enabled | default(false) %}
    ${pxgrid_ise}=   Set Variable   ${None}
    FOR   ${dto}   IN   @{ise_dtos_list}
        ${dto_role}=   Get From Dictionary   ${dto}   role
        IF   '${dto_role}' == 'PXGRID'
            ${pxgrid_ise}=   Set Variable   ${dto}
            BREAK
        END
    END
    Run Keyword If   ${pxgrid_ise} is ${None}   Fail   PXGRID ISE entry not found in ciscoIseDtos

    # Validate PXGRID ISE details
    {% if catalyst_center.system_settings.authentication_and_policy_servers.ise.fqdn is defined %}
    ${pxgrid_fqdn}=   Get From Dictionary   ${pxgrid_ise}   fqdn
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${pxgrid_fqdn}   {{ catalyst_center.system_settings.authentication_and_policy_servers.ise.fqdn }}
    {% endif %}
    ${pxgrid_trust_state}=   Get From Dictionary   ${pxgrid_ise}   trustState
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${pxgrid_trust_state}   TRUSTED
    {% endif %}

{% endif %}

{% for aaa_server in catalyst_center.system_settings.authentication_and_policy_servers.aaa | default([]) %}
Verify AAA Server {{ aaa_server.ip_address }}
    Log To Console   Validating AAA server {{ aaa_server.ip_address }}

    # Find AAA server entry in API response (filter by IP, then check isIseEnabled)
    ${all_servers_with_ip}=   Get Value From Json   ${r.json()}   $.response[?(@.ipAddress=='{{ aaa_server.ip_address }}')]
    
    # Check if server exists
    ${server_found}=   Evaluate   len(${all_servers_with_ip}) > 0
    Run Keyword If   not ${server_found}   Fail   AAA server {{ aaa_server.ip_address }} not found in API response
    
    # Filter for non-ISE servers
    ${aaa_server_entry}=   Set Variable   ${None}
    FOR   ${server}   IN   @{all_servers_with_ip}
        ${is_ise}=   Get From Dictionary   ${server}   isIseEnabled
        IF   not ${is_ise}
            ${aaa_server_entry}=   Set Variable   ${server}
            BREAK
        END
    END
    Run Keyword If   ${aaa_server_entry} is ${None}   Fail   AAA server {{ aaa_server.ip_address }} is ISE-enabled, expected non-ISE AAA server

    # Validate basic AAA server attributes
    ${aaa_ip}=   Get From Dictionary   ${aaa_server_entry}   ipAddress
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${aaa_ip}   {{ aaa_server.ip_address }}
    
    ${aaa_protocol}=   Get From Dictionary   ${aaa_server_entry}   protocol
    ${protocol_valid}=   Evaluate   "${aaa_protocol}" in ["RADIUS", "TACACS", "RADIUS_TACACS"]
    Run Keyword And Continue On Failure   Should Be True   ${protocol_valid}   msg=Protocol should be RADIUS, TACACS, or RADIUS_TACACS, got ${aaa_protocol}
    
    ${aaa_is_ise}=   Get From Dictionary   ${aaa_server_entry}   isIseEnabled
    Run Keyword And Continue On Failure   Should Not Be True   ${aaa_is_ise}   msg=isIseEnabled should be False for AAA server
    
    ${aaa_retries}=   Get From Dictionary   ${aaa_server_entry}   retries
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${aaa_retries}   {{ aaa_server.retries }}
    
    ${aaa_timeout}=   Get From Dictionary   ${aaa_server_entry}   timeoutSeconds
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${aaa_timeout}   {{ aaa_server.timeout }}

    # Validate protocol settings
    {% if aaa_server.protocols.tacacs is defined %}
    {% if aaa_server.protocols.tacacs.port is defined %}
    ${aaa_port}=   Get From Dictionary   ${aaa_server_entry}   port
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${aaa_port}   {{ aaa_server.protocols.tacacs.port }}
    {% endif %}
    {% endif %}
    {% if aaa_server.protocols.radius is defined %}
    {% if aaa_server.protocols.radius.authentication_port is defined %}
    ${aaa_auth_port}=   Get From Dictionary   ${aaa_server_entry}   authenticationPort
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${aaa_auth_port}   {{ aaa_server.protocols.radius.authentication_port }}
    {% endif %}
    {% if aaa_server.protocols.radius.accounting_port is defined %}
    ${aaa_acct_port}=   Get From Dictionary   ${aaa_server_entry}   accountingPort
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${aaa_acct_port}   {{ aaa_server.protocols.radius.accounting_port }}
    {% endif %}
    {% if aaa_server.protocols.radius.enable_key_wrap is defined %}
    # Validate key wrap is enabled (encryptionScheme should be KEYWRAP)
    ${aaa_encryption_scheme}=   Get From Dictionary   ${aaa_server_entry}   encryptionScheme
    Run Keyword And Continue On Failure   Should Be Equal As Strings   ${aaa_encryption_scheme}   KEYWRAP   msg=Encryption scheme should be KEYWRAP when key wrap is enabled for AAA server {{ aaa_server.ip_address }}
    {% endif %}
    {% endif %}

{% endfor %}
