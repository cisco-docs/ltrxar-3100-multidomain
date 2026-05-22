*** Settings ***
Documentation    Verify the Intrusion Prevention Policies
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags     sdwan    config    security_policies
Resource         ../../../sdwan_common.resource

{% if sdwan.security_policies is defined and sdwan.security_policies.definitions is defined and sdwan.security_policies.definitions.intrusion_prevention is defined %}

*** Test Cases ***

Get IPS Policy List(s)
    ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/intrusionprevention
    Log   ${r}
    Set Suite Variable   ${r}


{% for ips_policy in sdwan.security_policies.definitions.intrusion_prevention | default([]) %}

Verify Security Policy IPS List {{ ips_policy.name }}
   ${ips_policy_id}=   Json Search String   ${r.json()}   data[?name=='{{ ips_policy.name }}'] | [0].definitionId
   Run Keyword If    $ips_policy_id == ''    Fail    Intrusion Prevention Policy '{{ ips_policy.name }}' not found
   ${r_id}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/intrusionprevention/${ips_policy_id}
   Should Be Equal Value Json String   ${r_id.json()}   name   {{ ips_policy.name }}   msg=intrusion prevention name
   Should Be Equal Value Json Special_String   ${r_id.json()}   description   {{ ips_policy.description | normalize_special_string }}   msg=description
   Should Be Equal Value Json String   ${r_id.json()}   mode   security   msg=mode
   Should Be Equal Value Json String   ${r_id.json()}   definition.signatureSet   {{ ips_policy.signature_set }}   msg=signature set
   Should Be Equal Value Json String   ${r_id.json()}   definition.inspectionMode   {{ ips_policy.inspection_mode }}   msg=inspection mode
   Should Be Equal Value Json String   ${r_id.json()}   definition.logLevel   {{ ips_policy.log_level }}   msg=log level
   ${target_vpn_list}=   Create List   {{ ips_policy.target_vpns | default([]) | join('   ') }}
   Should Be Equal Value Json List   ${r_id.json()}   definition.targetVpns   ${target_vpn_list}   msg=List of vpn id

{% endfor %}

{% endif %}
