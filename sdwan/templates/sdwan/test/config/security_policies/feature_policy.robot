*** Settings ***
Documentation    Verify feature Policies
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags     sdwan    config    security_policies
Resource         ../../sdwan_common.resource

{% if sdwan.security_policies is defined and sdwan.security_policies.feature_policies is defined %}

*** Test Cases ***

Get Feature Policy List(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/security
    Log   ${r}
    Set Suite Variable   ${r}

    ${z}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/zonebasedfw
    Set Suite Variable    ${z}
    Log    ${z.json()}

    ${p}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/zone
    Set Suite Variable    ${p}
   Log    ${p.json()}

{% for feature_policy in sdwan.security_policies.feature_policies | default([]) %}

Verify Feature Policy List {{ feature_policy.name }}
   ${feature_policy_id}=   Json Search String   ${r.json()}   data[?policyName=='{{ feature_policy.name }}'] | [0].policyId
   ${r_id}=   GET On Session With Retry   sdwan_manager   dataservice/template/policy/security/definition/${feature_policy_id}
   Should Be Equal Value Json String   ${r_id.json()}   policyName   {{ feature_policy.name }}   msg=feature policy name
   Should Be Equal Value Json Special_String   ${r_id.json()}   policyDescription   {{ feature_policy.description | default("not_defined") | normalize_special_string }}   msg=description
   Should Be Equal Value Json String   ${r_id.json()}   policyUseCase   {{ feature_policy.use_case}}   msg=use case
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.tcpSynFloodLimit   {{ feature_policy.additional_settings.firewall.tcp_syn_flood_limit | default("not_defined") }}   msg=tcp sync

{% if feature_policy.additional_settings.firewall.audit_trail is defined and feature_policy.additional_settings.firewall.audit_trail == True %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.auditTrail   on   msg=audit trial
{% elif feature_policy.additional_settings.firewall.audit_trail is defined and feature_policy.additional_settings.firewall.audit_trail == False %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.auditTrail   off   msg=audit trial
{% else %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.auditTrail   not_defined   msg=audit trial
{% endif %}

{% if feature_policy.mode is not defined or feature_policy.mode == "security" %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.highSpeedLogging.vrf   {{ feature_policy.additional_settings.firewall.high_speed_logging.vpn_id | default("not_defined") }}   msg=vpn id
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.highSpeedLogging.serverIp   {{ feature_policy.additional_settings.firewall.high_speed_logging.server_ip | default("not_defined") }}   msg=server ip
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.highSpeedLogging.port   {{ feature_policy.additional_settings.firewall.high_speed_logging.server_port | default("not_defined") }}   msg=server port   

   ${zbf_yaml_data}=   Create List   {{ feature_policy.firewall_policies | default([]) | join('   ') }}
   ${zbf_rest_api_ref_list}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='zoneBasedFW'].definitionId
   ${zbf_name_list}=    Create List
   FOR    ${id}    IN    @{zbf_rest_api_ref_list}
            ${zbf_list_ref_data}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/zonebasedfw/${id}
            ${zbf_name}=    Json Search String    ${zbf_list_ref_data.json()}    name
            Append To List   ${zbf_name_list}    ${zbf_name}
   END
   Lists Should Be Equal    ${zbf_name_list}   ${zbf_yaml_data}    ignore_order=True    msg=zone based firewall list

{% if feature_policy.additional_settings.firewall.match_stats_per_filter is defined and feature_policy.additional_settings.firewall.match_stats_per_filter == True  %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.platformMatch   on   msg=Match Statistics per-filter
{% elif feature_policy.additional_settings.firewall.match_stats_per_filter is defined and feature_policy.additional_settings.firewall.match_stats_per_filter == False %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.platformMatch   off   msg=Match Statistics per-filter
{% else %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.platformMatch   not_defined   msg=Match Statistics per-filter
{% endif %}

{% if feature_policy.additional_settings.firewall.direct_internet_applications is defined and feature_policy.additional_settings.firewall.direct_internet_applications == True  %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.zoneToNozoneInternet   allow   msg=Direct internet applications
{% elif feature_policy.additional_settings.firewall.direct_internet_applications is defined and feature_policy.additional_settings.firewall.direct_internet_applications == False  %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.zoneToNozoneInternet   deny   msg=Direct internet applications
{% else %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.zoneToNozoneInternet   not_defined   msg=Direct internet applications
{% endif %}

{% elif feature_policy.mode == "unified" %}
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.maxIncompleteIcmpLimit   {{ feature_policy.additional_settings.firewall.max_incomplete_icmp_limit | default("not_defined") }}   msg=max incomplete icmp limit
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.maxIncompleteTcpLimit   {{ feature_policy.additional_settings.firewall.max_incomplete_tcp_limit | default("not_defined") }}   msg=max incomplete tcp limit
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.maxIncompleteUdpLimit   {{ feature_policy.additional_settings.firewall.max_incomplete_udp_limit | default("not_defined") }}   msg=max incomplete udp limit
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.sessionReclassifyAllow   {{ feature_policy.additional_settings.firewall.session_reclassify_allow | default("not_defined") }}   msg=session reclassify allow
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.icmpUnreachableAllow   {{ feature_policy.additional_settings.firewall.icmp_unreachable_allow | default("not_defined") }}   msg=icmp unreachable allow
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.unifiedLogging   {{ feature_policy.additional_settings.firewall.unified_logging | default("not_defined") }}   msg=unified logging

{% for firewall_policy in feature_policy.unified_firewall_policies | default([]) %}
   ${firewall_data}=    Json Search    ${z.json()}    data[?name=='{{ firewall_policy.firewall_policy }}'] | [0]
   Should Be Equal Value Json String    ${firewall_data}    name    {{ firewall_policy.firewall_policy }}    msg=firewall_policy.firewall_policy
   ${firewall_id}=    Json Search String    ${firewall_data}    definitionId

   Should Be Equal Value Json List Length    ${r_id.json()}    policyDefinition.assembly[?definitionId=='${firewall_id}'] | [0].entries    {{ firewall_policy.zones | default([]) | length }}    msg=firewall_policy.zones length
   ${u_fp_zones}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?definitionId=='${firewall_id}'] | [0].entries

{% for zp in firewall_policy.zones %}
   IF    '{{ zp.source_zone }}' == 'self_zone'
       ${src_zone_id}=    Set Variable    self
   ELSE
       ${src_zone_id}=    Json Search String    ${p.json()}    data[?name=='{{ zp.source_zone }}'] | [0].listId
   END
   IF    '{{ zp.destination_zone }}' == 'self_zone'
      ${dst_zone_id}=    Set Variable    self
   ELSE
      ${dst_zone_id}=    Json Search String    ${p.json()}    data[?name=='{{ zp.destination_zone }}'] | [0].listId
   END
   ${yamldict_sz_dz}=    Create Dictionary    srcZoneListId=${src_zone_id}    dstZoneListId=${dst_zone_id}
   List Should Contain Value    ${u_fp_zones}    ${yamldict_sz_dz}   msg=zone pair mismatch for firewall policy {{ firewall_policy.firewall_policy }}

{% endfor %}
{% endfor %}
{% endif %}

# | feature_policy.url_filtering_policy is defined | feature_policy.advanced_malware_protection_policy
{% if feature_policy.intrusion_prevention_policy is defined  %}
   ${ips_yaml_id}=   Set Variable  {{ feature_policy.intrusion_prevention_policy }}
   ${ips_rest_api_id}=    Json Search String    ${r_id.json()}    policyDefinition.assembly[?type=='intrusionPrevention'] | [0].definitionId
   IF    $ips_rest_api_id == ''
        Should Be Equal As Strings    {{ feature_policy.intrusion_prevention_policy | default("not_defined") }}    ${ips_rest_api_id}    msg=intrusion prevention policy
   ELSE
        ${ips_rest_api_data}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/intrusionprevention/${ips_rest_api_id}
        Should Be Equal Value Json String    ${ips_rest_api_data.json()}    name    ${ips_yaml_id}    msg=intrusion prevention policy
   END
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.logging[0].serverIP   {{ feature_policy.additional_settings.ips_url_amp.external_syslog_server.server_ip | default("not_defined") }}   msg=External Syslog Server IP
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.logging[0].vpn   {{ feature_policy.additional_settings.ips_url_amp.external_syslog_server.vpn_id | default("not_defined") }}   msg=External Syslog Server VPN
   Should Be Equal Value Json String   ${r_id.json()}   policyDefinition.settings.failureMode  {{ feature_policy.additional_settings.ips_url_amp.failure_mode | default("not_defined") }}   msg=failure mode
{% endif %} 

{% endfor %}

{% endif %}
