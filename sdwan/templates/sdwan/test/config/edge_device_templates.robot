*** Settings ***
Documentation    Verify Device Templates
Suite Setup      Login SDWAN Manager
Default Tags     sdwan    config    edge_device_templates
Resource         ../sdwan_common.resource

{% if sdwan.edge_device_templates is defined%}

*** Test Cases ***
Get Edge Device template
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/device
    Set Suite Variable    ${r}

{% for edt in sdwan.edge_device_templates | default([]) %}

Verify Edge Device Templates {{ edt.name }}
    ${template_id}=    Json Search String    ${r.json()}    data[?templateName=='{{ edt.name }}'] | [0].templateId
    Run Keyword If    $template_id == ''    Fail    Edge Device Template '{{ edt.name }}' not found
    ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/device/object/${template_id}
    Should Be Equal Value Json String    ${r_id.json()}    templateName    {{ edt.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    templateDescription    {{ edt.description | normalize_special_string }}    msg=description

{% set device_model = "vedge-" ~ edt.device_model %}
    Should Be Equal Value Json String    ${r_id.json()}    deviceType    {{ device_model }}    msg=device model

    ${templates_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/feature
    Set Suite Variable    ${templates_id}

    ${system_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_system'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${system_temp_id}'] | [0].templateName    {{ edt.system_template }}    msg=system template

    ${logging_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_system'] | [0].subTemplates[?templateType=='cisco_logging'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${logging_temp_id}'] | [0].templateName    {{ edt.logging_template }}    msg=logging template

    ${ntp_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_system'] | [0].subTemplates[?templateType=='cisco_ntp'] | [0].templateId
    ${ntp_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${ntp_temp_id}'] | [0].templateName
    ${ntp_template_name}=    Set Variable If    '${ntp_template_name}' == ''    not_defined    ${ntp_template_name}
    Should Be Equal As Strings    {{ edt.ntp_template | default("not_defined") }}    ${ntp_template_name}    msg=ntp template

    ${aaa_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cedge_aaa'] | [0].templateId
    ${aaa_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${aaa_temp_id}'] | [0].templateName
    ${aaa_template_name}=    Set Variable If    '${aaa_template_name}' == ''    not_defined    ${aaa_template_name}
    Should Be Equal As Strings    {{ edt.aaa_template | default("not_defined") }}    ${aaa_template_name}    msg=aaa template

    ${bfd_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_bfd'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${bfd_temp_id}'] | [0].templateName    {{ edt.bfd_template }}    msg=bfd template

    ${omp_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_omp'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${omp_temp_id}'] | [0].templateName    {{ edt.omp_template }}    msg=omp template

    ${security_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_security'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${security_temp_id}'] | [0].templateName    {{ edt.security_template }}    msg=security template

    ${global_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cedge_global'] | [0].templateId
    Should Be Equal Value Json String    ${templates_id.json()}    data[?templateId=='${global_temp_id}'] | [0].templateName    {{ edt.global_settings_template }}    msg=global settings template

    ${banner_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_banner'] | [0].templateId
    ${banner_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${banner_temp_id}'] | [0].templateName
    ${banner_template_name}=    Set Variable If    '${banner_template_name}' == ''    not_defined    ${banner_template_name}
    Should Be Equal As Strings    {{ edt.banner_template | default("not_defined") }}    ${banner_template_name}    msg=banner template

    ${snmp_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_snmp'] | [0].templateId
    ${snmp_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${snmp_temp_id}'] | [0].templateName
    ${snmp_template_name}=    Set Variable If    '${snmp_template_name}' == ''    not_defined    ${snmp_template_name}
    Should Be Equal As Strings    {{ edt.snmp_template | default("not_defined") }}    ${snmp_template_name}    msg=snmp template

    ${cli_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cli-template'] | [0].templateId
    ${cli_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${cli_temp_id}'] | [0].templateName
    ${cli_template_name}=    Set Variable If    '${cli_template_name}' == ''    not_defined    ${cli_template_name}
    Should Be Equal As Strings    {{ edt.cli_template | default("not_defined") }}    ${cli_template_name}    msg=cli template

    ${lp_policy_id}=    Json Search String    ${r_id.json()}    policyId
    IF    $lp_policy_id == ''
        Should Be Equal As Strings    {{ edt.localized_policy | default("not_defined") }}    not_defined    msg=localized policy
    ELSE
        ${localized_pilicies}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/vedge/definition/${lp_policy_id}
        Should Be Equal Value Json String    ${localized_pilicies.json()}    policyName    {{ edt.localized_policy | default("not_defined") }}    msg=localized policy
    END

    ${sp_policy_id}=    Json Search String    ${r_id.json()}    securityPolicyId
    ${sp_policy_id}=    Set Variable If    '${sp_policy_id}' == ''    not_defined    ${sp_policy_id}
    IF    $sp_policy_id == 'not_defined'
        Should Be Equal As Strings    {{ edt.security_policy.name | default("not_defined") }}    ${sp_policy_id}    msg=security policy
    ELSE
        ${security_policies}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/security/definition/${sp_policy_id}
        Should Be Equal Value Json String    ${security_policies.json()}    policyName    {{ edt.security_policy.name | default("not_defined") }}    msg=security policy
    END

    ${utd_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='virtual-application-utd'] | [0].templateId
    ${utd_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${utd_id}'] | [0].templateName
    ${utd_template_name}=    Set Variable If    '${utd_template_name}' == ''    not_defined    ${utd_template_name}
    Should Be Equal As Strings    {{ edt.security_policy.container_profile | default("not_defined") }}    ${utd_template_name}    msg=container profile

{% set exp_switchport_templates = [] %}
{% for item in edt.switchport_templates | default([]) %}
{% set _ = exp_switchport_templates.append(item.name) %}
{% endfor %}

{% if edt.switchport_templates is defined %}
    ${exp_switchport_templates} =   Create List   {{ exp_switchport_templates | join('   ') }}
    ${switchport_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='switchport'] | [0].templateId
    ${rec_switchport_templates}=    Json Search List    ${templates_id.json()}    data[?templateId=='${switchport_temp_id}'].templateName
    Lists Should Be Equal    ${rec_switchport_templates}    ${exp_switchport_templates}    msg=switchport templates
{% else %}
    ${switchport_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='switchport'] | [0].templateId
    ${switchport_temp_id}=    Set Variable If    '${switchport_temp_id}' == ''    not_defined    ${switchport_temp_id}
    Should Be Equal As Strings    {{ edt.switchport_templates | default("not_defined") }}    ${switchport_temp_id}    msg=switchport templates
{% endif %}

    ${thousandeyes_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_thousandeyes'] | [0].templateId
    ${thousandeyes_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${thousandeyes_temp_id}'] | [0].templateName
    ${thousandeyes_template_name}=    Set Variable If    '${thousandeyes_template_name}' == ''    not_defined    ${thousandeyes_template_name}
    Should Be Equal As Strings    {{ edt.thousandeyes_template | default("not_defined") }}    ${thousandeyes_template_name}    msg=thousandeyes template

{% set vpn0_templates_list = [] %}
{% set vpn512_templates_list = [] %}
{% set _ = vpn0_templates_list.append(edt.vpn_0_template.name) %}
{% set _ = vpn512_templates_list.append(edt.vpn_512_template.name) %}
{% set vpn0_512_list = vpn0_templates_list + vpn512_templates_list %}

{% if edt.vpn_service_templates is defined %}
{% set rec_vpn_service_templates_list = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.name) %}
{% set vpn_service_templates_test = ','.join(test_list | map('string')) %}
{% set _ = rec_vpn_service_templates_list.append(vpn_service_templates_test) %}
{% set vpn_templates_list = rec_vpn_service_templates_list + vpn0_512_list %}
    ${list}=   Create List   {{ vpn_templates_list | join('   ') }}
{% endfor %}
{% else %}
    ${list}=   Create List   {{ vpn0_512_list | join('   ') }}
{% endif %}
    Set Suite Variable    ${list}

    ${rec_vpn_names}=    Create List
    ${vpn_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'].templateId
    FOR    ${id}    IN    @{vpn_temp_id}
        ${rec_vpn_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_vpn_names}    ${rec_vpn_template_name}
    END
    Lists Should Be Equal    ${rec_vpn_names}    ${list}    ignore_order=True    msg=vpn templates

    FOR    ${vpn_name}    IN    @{rec_vpn_names}
        IF    '${vpn_name}' == '{{ edt.vpn_0_template.name }}'
            ${sig_temp_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'] | [0].subTemplates[?templateType=='cisco_secure_internet_gateway'] | [0].templateId
            ${sig_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${sig_temp_id}'] | [0].templateName
            ${sig_template_name}=    Set Variable If    '${sig_template_name}' == ''    not_defined    ${sig_template_name}
            Should Be Equal As Strings    {{ edt.vpn_0_template.secure_internet_gateway_template | default("not_defined") }}    ${sig_template_name}    msg=secure internet gateway template

            ${sig_credentials_template_id}=    Json Search String    ${r_id.json()}    generalTemplates[?templateType=='cisco_sig_credentials'] | [0].templateId
            ${sig_credentials_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${sig_credentials_template_id}'] | [0].templateName
            ${sig_credentials_template_name}=    Set Variable If    '${sig_credentials_template_name}' == ''    not_defined    ${sig_credentials_template_name}
            Should Be Equal As Strings    {{ edt.vpn_0_template.sig_credentials_template | default("not_defined") }}    ${sig_credentials_template_name}    msg=sig credentials template
        END
    END

{% set rec_vpn0_bgp_template = [] %}
{% if edt.vpn_0_template.bgp_template is defined %}
{% set _ = rec_vpn0_bgp_template.append(edt.vpn_0_template.bgp_template) %}
{% endif %}
{% set rec_vpn_service_bgp_template = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% set test_list = [] %}
{% if item.bgp_template is defined %}
{% set _ = test_list.append(item.bgp_template) %}
{% endif %}
{% set vpn_service_bgp_templates_test = ','.join(test_list | map('string')) %}
{% set _ = rec_vpn_service_bgp_template.append(vpn_service_bgp_templates_test) %}
{% endfor %}

{% set rec_bgp_templates = rec_vpn_service_bgp_template + rec_vpn0_bgp_template %}
    ${bgp_temp_list}=   Create List   {{ rec_bgp_templates | join('   ') }}
    Set Suite Variable    ${bgp_temp_list}

    ${rec_bgp_temp_list}=    Create List
    ${bgp_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cisco_bgp'][].templateId
    FOR    ${id}    IN    @{bgp_temp_id}
        ${rec_bgp_temp_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_bgp_temp_list}    ${rec_bgp_temp_name}
    END
    Lists Should Be Equal    ${rec_bgp_temp_list}    ${bgp_temp_list}    ignore_order=True    msg=bgp templates


    Log    =====Multicast=====
{% set vpn_service_multicast_template = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% set test_list = [] %}
{% if item.multicast_template is defined %}
{% set _ = test_list.append(item.multicast_template) %}
{% endif %}
{% set vpn_service_multicast_templates_test = ','.join(test_list | map('string')) %}
{% set _ = vpn_service_multicast_template.append(vpn_service_multicast_templates_test) %}
{% endfor %}

{% set rec_multicast_templates = vpn_service_multicast_template %}
    ${multicast_temp_list}=   Create List   {{ rec_multicast_templates | join('   ') }}
    Set Suite Variable    ${multicast_temp_list}

    ${rec_multicast_temp_list}=    Create List
    ${multicast_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cedge_multicast'][].templateId
    FOR    ${id}    IN    @{multicast_temp_id}
        ${rec_multicast_temp_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_multicast_temp_list}    ${rec_multicast_temp_name}
    END
    Log    From API:${rec_multicast_temp_list}
    Log    From YAML:${multicast_temp_list}
    Lists Should Be Equal    ${rec_multicast_temp_list}    ${multicast_temp_list}    ignore_order=True    msg=multicast templates

    Log    =====PIM=====
{% set vpn_service_pim_template = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% set test_list = [] %}
{% if item.pim_template is defined %}
{% set _ = test_list.append(item.pim_template) %}
{% endif %}
{% set vpn_service_pim_templates_test = ','.join(test_list | map('string')) %}
{% set _ = vpn_service_pim_template.append(vpn_service_pim_templates_test) %}
{% endfor %}

{% set rec_pim_templates = vpn_service_pim_template %}
    ${pim_temp_list}=   Create List   {{ rec_pim_templates | join('   ') }}
    Set Suite Variable    ${pim_temp_list}

    ${rec_pim_temp_list}=    Create List
    ${pim_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cedge_pim'][].templateId
    FOR    ${id}    IN    @{pim_temp_id}
        ${rec_pim_temp_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_pim_temp_list}    ${rec_pim_temp_name}
    END
    Log    From API:${rec_pim_temp_list}
    Log    From YAML:${pim_temp_list}
    Lists Should Be Equal    ${rec_pim_temp_list}    ${pim_temp_list}    ignore_order=True    msg=pim templates

{% set rec_vpn0_ospf_template = [] %}
{% if edt.vpn_0_template.ospf_template is defined %}
{% set _ = rec_vpn0_ospf_template.append(edt.vpn_0_template.ospf_template) %}
{% endif %}
{% set rec_vpn_service_ospf_template = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% set test_list = [] %}
{% if item.ospf_template is defined %}
{% set _ = test_list.append(item.ospf_template) %}
{% endif %}
{% set vpn_service_ospf_templates_test = ','.join(test_list | map('string')) %}
{% set _ = rec_vpn_service_ospf_template.append(vpn_service_ospf_templates_test) %}
{% endfor %}

{% set rec_ospf_templates = rec_vpn_service_ospf_template + rec_vpn0_ospf_template %}
    ${ospf_temp_list}=   Create List   {{ rec_ospf_templates | join('   ') }}
    Set Suite Variable    ${ospf_temp_list}

    ${rec_ospf_temp_list}=    Create List
    ${ospf_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cisco_ospf'][].templateId
    FOR    ${id}    IN    @{ospf_temp_id}
        ${rec_ospf_temp_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_ospf_temp_list}    ${rec_ospf_temp_name}
    END
    Lists Should Be Equal    ${rec_ospf_temp_list}    ${ospf_temp_list}    ignore_order=True    msg=ospf templates

{% set rec_vpn0_ethernet_interface_templates = [] %}
{% for item in edt.vpn_0_template.ethernet_interface_templates | default([]) %}
{% set _ = rec_vpn0_ethernet_interface_templates.append(item.name) %}
{% endfor %}

{% set rec_vpn512_ethernet_interface_templates = [] %}
{% for item in edt.vpn_512_template.ethernet_interface_templates | default([]) %}
{% set _ = rec_vpn512_ethernet_interface_templates.append(item.name) %}
{% endfor %}

{% set vpn0_512_ethernet_templates_list = rec_vpn512_ethernet_interface_templates + rec_vpn0_ethernet_interface_templates %}
    ${vpn_list}=   Create List   {{ vpn0_512_ethernet_templates_list | join('   ') }}
    Set Suite Variable    ${vpn_list}

{% set rec_vpn_service_ethernet_interface_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for eit_index in range(item.ethernet_interface_templates | default([]) | length()) %}
{% set _ = rec_vpn_service_ethernet_interface_templates.append(item.ethernet_interface_templates[eit_index].name) %}
{% endfor %}
{% endfor %}
    ${vpn_sei_temp_list}=   Create List   {{ rec_vpn_service_ethernet_interface_templates | join('   ') }}
    Set Suite Variable    ${vpn_sei_temp_list}

    ${exp_eit_names}=    Combine Lists    ${vpn_sei_temp_list}    ${vpn_list}
    ${rec_eit_names}=    Create List
    ${eit_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cisco_vpn_interface'][].templateId
    FOR    ${id}    IN    @{eit_temp_id}
        ${rec_eit_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_eit_names}    ${rec_eit_template_name}
    END
    Lists Should Be Equal    ${rec_eit_names}    ${exp_eit_names}    ignore_order=True    msg=ethernet interface templates

{% set rec_vpn0_ipsec_interface_templates = [] %}
{% for item in edt.vpn_0_template.ipsec_interface_templates | default([]) %}
{% set _ = rec_vpn0_ipsec_interface_templates.append(item.name) %}
{% endfor %}

{% set rec_vpn_service_ipsec_interface_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for ipsec_index in range(item.ipsec_interface_templates | default([]) | length()) %}
{% set _ = rec_vpn_service_ipsec_interface_templates.append(item.ipsec_interface_templates[ipsec_index].name) %}
{% endfor %}
{% endfor %}

{% set exp_ipsec_interface_templates = rec_vpn_service_ipsec_interface_templates + rec_vpn0_ipsec_interface_templates %}
    ${list}=   Create List   {{ exp_ipsec_interface_templates | join('   ') }}
    ${rec_ipsec_temp_names}=    Create List
    ${ipsec_int_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cisco_vpn_interface_ipsec'][].templateId
    FOR    ${id}    IN    @{ipsec_int_temp_id}
        ${rec_ipsec_int_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_ipsec_temp_names}    ${rec_ipsec_int_template_name}
    END
    Lists Should Be Equal    ${rec_ipsec_temp_names}    ${list}    ignore_order=True    msg=ipsec interface templates

{% set rec_vpn0_svi_interface_templates = [] %}
{% for item in edt.vpn_0_template.svi_interface_templates | default([]) %}
{% set _ = rec_vpn0_svi_interface_templates.append(item.name) %}
{% endfor %}

{% set rec_vpn512_svi_interface_templates = [] %}
{% for item in edt.vpn_512_template.svi_interface_templates | default([]) %}
{% set _ = rec_vpn512_svi_interface_templates.append(item.name) %}
{% endfor %}

{% set vpn0_512_svi_templates_list = rec_vpn512_svi_interface_templates + rec_vpn0_svi_interface_templates %}
    ${vpn0_512_svi_templates}=   Create List   {{ vpn0_512_svi_templates_list | join('   ') }}
    Set Suite Variable    ${vpn0_512_svi_templates}

{% set rec_vpn_service_svi_interface_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for svitemp_index in range(item.svi_interface_templates | default([]) | length()) %}
{% set _ = rec_vpn_service_svi_interface_templates.append(item.svi_interface_templates[svitemp_index].name) %}
{% endfor %}
{% endfor %}
    ${vpn_svi_intf_temp_list}=   Create List   {{ rec_vpn_service_svi_interface_templates | join('   ') }}
    Set Suite Variable    ${vpn_svi_intf_temp_list}

    ${exp_svi_int_temp_names}=    Combine Lists    ${vpn_svi_intf_temp_list}    ${vpn0_512_svi_templates}
    ${rec_svi_int_temp_names}=    Create List
    ${svi_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='vpn-interface-svi'][].templateId
    FOR    ${id}    IN    @{svi_temp_id}
        ${rec_svi_intf_template_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_svi_int_temp_names}    ${rec_svi_intf_template_name}
    END
    Lists Should Be Equal    ${rec_svi_int_temp_names}    ${exp_svi_int_temp_names}    ignore_order=True    msg=svi interface templates

{% set rec_vpn0_dhcp_server_template = [] %}
{% for item in edt.vpn_0_template.ipsec_interface_templates | default([]) %}
{% if item.dhcp_server_template is defined %}
{% set _ = rec_vpn0_dhcp_server_template.append(item.dhcp_server_template) %}
{% endif %}
{% endfor %}

{% set rec_eit_dhcp_server_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for dhcp_index in range(item.ethernet_interface_templates | default([]) | length()) %}
{% if item.ethernet_interface_templates[dhcp_index].dhcp_server_template is defined %}
{% set _ = rec_eit_dhcp_server_templates.append(item.ethernet_interface_templates[dhcp_index].dhcp_server_template) %}
{% endif %}
{% endfor %}
{% endfor %}

{% set rec_ipsec_dhcp_server_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for dhcp_index in range(item.ipsec_interface_templates | default([]) | length()) %}
{% if item.ipsec_interface_templates[dhcp_index].dhcp_server_template is defined %}
{% set _ = rec_ipsec_dhcp_server_templates.append(item.ipsec_interface_templates[dhcp_index].dhcp_server_template) %}
{% endif %}
{% endfor %}
{% endfor %}

{% set rec_svi_dhcp_server_templates = [] %}
{% for item in edt.vpn_service_templates | default([]) %}
{% for dhcp_index in range(item.svi_interface_templates | default([]) | length()) %}
{% if item.svi_interface_templates[dhcp_index].dhcp_server_template is defined %}
{% set _ = rec_svi_dhcp_server_templates.append(item.svi_interface_templates[dhcp_index].dhcp_server_template) %}
{% endif %}
{% endfor %}
{% endfor %}

{% set dhcp_server_template_names = rec_svi_dhcp_server_templates + rec_ipsec_dhcp_server_templates + rec_eit_dhcp_server_templates + rec_vpn0_dhcp_server_template %}
    ${dhcp_servers_list}=   Create List   {{ dhcp_server_template_names | join('   ') }}
    Set Suite Variable    ${dhcp_servers_list}

    ${rec_dhcp_servers_list}=    Create List
    ${dhcp_servers_temp_id}=    Json Search List    ${r_id.json()}    generalTemplates[?templateType=='cisco_vpn'][].subTemplates[?templateType=='cisco_dhcp_server'][].templateId
    FOR    ${id}    IN    @{dhcp_servers_temp_id}
        ${rec_dhcp_server_name}=    Json Search String    ${templates_id.json()}    data[?templateId=='${id}'] | [0].templateName
        Append To List    ${rec_dhcp_servers_list}    ${rec_dhcp_server_name}
    END
    Lists Should Be Equal    ${rec_dhcp_servers_list}    ${dhcp_servers_list}    ignore_order=True    msg=dhcp server template

{% endfor %}

{% endif %}
