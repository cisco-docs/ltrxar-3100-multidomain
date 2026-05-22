*** Settings ***
Documentation    Verify SLA Class Lists
Suite Setup      Login SDWAN Manager
Suite Teardown   Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    classic_policy_objects
Resource         ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.sla_classes is defined %}

*** Test Cases ***
Get Sla Class List(s)
   ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/sla
   Set Suite Variable   ${r}

{% for sla in sdwan.policy_objects.sla_classes | default([]) %}
{% if sla.name is defined %}

Verify Policy Objects SLA Class List {{ sla.name }}
   ${sla_class_id}=    Json Search String    ${r.json()}    data[?name=='{{ sla.name }}'] | [0].listId
   ${sla}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/sla/${sla_class_id}
   Should Be Equal Value Json String    ${sla.json()}    name    {{ sla.name }}    msg=SLA class name
   Should Be Equal Value Json String    ${sla.json()}    entries[0].jitter    {{ sla.jitter_ms | default("not_defined") }}    msg={{ sla.name }}: Jitter
   Should Be Equal Value Json String    ${sla.json()}    entries[0].latency    {{ sla.latency_ms | default("not_defined") }}    msg={{ sla.name }}: Latency
   Should Be Equal Value Json String    ${sla.json()}    entries[0].loss    {{ sla.loss_percentage | default("not_defined") }}    msg={{ sla.name }}: Loss

   ${app_probe_id}=    Json Search String    ${sla.json()}    entries[0].appProbeClass
{% if sla.app_probe_class | default("not_defined") == "not_defined" %}
   Should Be Equal As Strings   ${app_probe_id}  ${EMPTY}  msg={{ sla.name }}: App Probe Class
{% else %}
   ${app_probe_object}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/list/appprobe/${app_probe_id}
   Should Be Equal Value Json String    ${app_probe_object.json()}    name    {{ sla.app_probe_class }}    msg={{ sla.name }}: App Probe Class
{% endif %}

   Should Be Equal Value Json String    ${sla.json()}    entries[0].fallbackBestTunnel.criteria    {{ sla.fallback_best_tunnel_criteria | default("not_defined") }}    msg={{ sla.name }}: Loss Criteria
   Should Be Equal Value Json String    ${sla.json()}    entries[0].fallbackBestTunnel.jitterVariance    {{ sla.fallback_best_tunnel_jitter | default("not_defined") }}    msg={{ sla.name }}: Jitter Variance
   Should Be Equal Value Json String    ${sla.json()}    entries[0].fallbackBestTunnel.latencyVariance    {{ sla.fallback_best_tunnel_latency | default("not_defined") }}    msg={{ sla.name }}: Latency Variance
   Should Be Equal Value Json String    ${sla.json()}    entries[0].fallbackBestTunnel.lossVariance    {{ sla.fallback_best_tunnel_loss | default("not_defined") }}    msg={{ sla.name }}: Loss Variance
{% endif %}

{% endfor %}
{% endif %}
