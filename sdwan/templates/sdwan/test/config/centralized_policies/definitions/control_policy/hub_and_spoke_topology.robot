*** Settings ***
Documentation   Verify Hub And Spoke Topology
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    control_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.control_policy.hub_and_spoke_topology is defined %}

*** Test Cases ***
Get Hub And Spoke Topology(s)
   ${r}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/hubandspoke
   Set Suite Variable    ${r}

{% for topology in sdwan.centralized_policies.definitions.control_policy.hub_and_spoke_topology | default([]) %}

Verify Centralized Policies Color Hub and Spoke Topology {{ topology.name }}
   ${topo_id}=  Json Search String   ${r.json()}   data[?name=='{{ topology.name }}'] | [0].definitionId
   Run Keyword If    $topo_id == ''    Fail    Hub and Spoke Topology '{{ topology.name }}' not found
   ${topo}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/definition/hubandspoke/${topo_id}
   Should Be Equal Value Json String   ${topo.json()}   name   {{ topology.name }}    msg=Topology
   Should Be Equal Value Json Special_String   ${r.json()}   data[?name=='{{ topology.name }}'] | [0].description   {{ topology.description | normalize_special_string }}  msg={{ topology.name }}: Description

   ${vpn_list_id}=  Json Search String   ${topo.json()}   vpnList
   IF    $vpn_list_id != ''
      ${vpn_list}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/vpn/${vpn_list_id}
      Should Be Equal Value Json String   ${vpn_list.json()}   name   {{ topology.vpn_list }}   msg={{ topology.name }}: vpn list
   END
   Should Be Equal Value Json List Length   ${topo.json()}   definition.subDefinitions  {{ topology.hub_and_spoke_sites | length }}  msg={{ topology.name }}: Site group numbers
{% for site_group in topology.hub_and_spoke_sites | default([]) %}

   Should Be Equal Value Json String   ${topo.json()}   definition.subDefinitions[{{loop.index0}}].name   {{ site_group.name }}      msg={{ topology.name }} Topology's: {{ site_group.name }} Site group
   ${site_group_value}=   Json Search List   ${topo.json()}   definition.subDefinitions[{{loop.index0}}].spokes

   ${spoke_length}=   Get Length   ${site_group_value}
   Should Be Equal As Integers    ${spoke_length}    {{ site_group.spokes | length }}    msg={{ site_group.name }}: No. of Spoke
   Should Be Equal Value Json String   ${topo.json()}   definition.subDefinitions[{{loop.index0}}].equalPreference   {{ site_group.equal_preference | default("not_defined") }}   msg={{ topology.name }} Topology's {{ site_group.name }} Site group's: Equal Preference
   Should Be Equal Value Json String   ${topo.json()}   definition.subDefinitions[{{loop.index0}}].advertiseTloc   {{ site_group.advertise_tloc | default("not_defined") }}   msg={{ topology.name }} Topology's {{ site_group.name }} Site group's: Advertise Tloc

   ${tloc_id}=   Json Search String   ${topo.json()}   definition.subDefinitions[{{loop.index0}}].tlocList
{% if site_group.tloc_list | default("not_defined") | string() == "not_defined" %}
   Should Be Equal As Strings   ${tloc_id}   ${EMPTY}   msg={{ topology.name }} Topology's {{ site_group.name }} Site group's: Tloc
{% else %}
   ${tloc}=   GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/tloc/${tloc_id}
   Should Be Equal Value Json String   ${tloc.json()}   name   {{ site_group.tloc_list | default("not_defined") }}  msg={{ topology.name }} Topology's {{ site_group.name }} Site group's: Tloc
{% endif %}

{% for spoke in site_group.spokes | default([]) %}

   ${sites}=  GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${site_group_value[{{loop.index0}}]['siteList']}
   Should Be Equal Value Json String   ${sites.json()}   name   {{ spoke.site_list | default("not_defined") }}   msg={{ topology.name }} Topology's {{ site_group.name }} Site group's: Spoke {{ spoke.site_list | default("not_defined") }}
   ${hub_ids}=   Set Variable    ${site_group_value[{{loop.index0}}]['hubs']}
   ${hub_numbers}=   Get Length   ${hub_ids}
   Should Be Equal As Integers    ${hub_numbers}   {{ spoke.hubs | length }}   msg={{ site_group.name }}: Spoke's hub numbers

{% for hubs in spoke.hubs | default([]) %}

   ${hub_site}=   Json Search String   ${hub_ids}   [{{loop.index0}}].siteList
   ${hub_site_name}=  GET On Session With Retry   sdwan_manager   /dataservice/template/policy/list/site/${hub_site}
   Should Be Equal Value Json String   ${hub_site_name.json()}   name   {{ hubs.site_list }}  msg={{ spoke.site_list | default("not_defined") }} Spokes's:{{ hubs.site_list }} Hub site

{% if hubs.ipv4_prefix_lists | default("not_defined") | string() != "not_defined" %}
   Should Be Equal Value Json List Length   ${hub_ids}  [{{loop.index0}}].prefixLists  {{ hubs.ipv4_prefix_lists | length }}    msg={{ hubs.site_list }} Hub site's:IPv4 prefixes length
   ${prefix_id}=   Json Search List   ${hub_ids}   [{{loop.index0}}].prefixLists
{% for ipv4_prefix in hubs.ipv4_prefix_lists %}
   ${prefix_name}=  GET On Session With Retry   sdwan_manager      /dataservice/template/policy/list/prefix/${prefix_id[{{loop.index0}}]}
   Should Be Equal Value Json String   ${prefix_name.json()}   name   {{ ipv4_prefix }}    msg={{ hubs.site_list }} Hub site's:IPv4 Prefix
{% endfor %}

{% else %}
   ${prefix_id}=   Json Search List   ${hub_ids}   [{{loop.index0}}].prefixLists
   ${outer_empty}=    Run Keyword And Return Status   Should Be Empty   ${prefix_id}   msg={{ hubs.site_list }} Hub site's:IPv4 prefix
   IF   $outer_empty == ${True}
      Log  $outer_empty
   ELSE
      Fail   msg={{ hubs.site_list }} Hub site's:IPv4 prefix should be empty but got: ${prefix_id}
   END
{% endif %}

{% if hubs.ipv6_prefix_lists | default("not_defined") | string() != "not_defined" %}
   Should Be Equal Value Json List Length   ${hub_ids}   [{{loop.index0}}].ipv6PrefixLists  {{ hubs.ipv6_prefix_lists | length }}    msg={{ hubs.site_list }} Hub site's: IPv6 prefixes
   ${ipv6_prefix_id}=   Json Search List   ${hub_ids}   [{{loop.index0}}].ipv6PrefixLists
{% for ipv6_prefix in hubs.ipv6_prefix_lists %}
   ${ipv6_prefix_name}=  GET On Session With Retry   sdwan_manager      /dataservice/template/policy/list/ipv6prefix/${ipv6_prefix_id[{{loop.index0}}]}
   Should Be Equal Value Json String   ${ipv6_prefix_name.json()}   name   {{ ipv6_prefix }}    msg={{ hubs.site_list }} Hub site's: IPv6 Prefix

{% endfor %}

{% else %}
   ${ipv6_prefix_id}=   Json Search List   ${hub_ids}   [{{loop.index0}}].ipv6PrefixLists
   ${outer_empty}=    Run Keyword And Return Status   Should Be Empty   ${ipv6_prefix_id}    msg={{ hubs.site_list }} Hub site's:IPv6 prefix
   IF   $outer_empty == ${True}
      Log  $outer_empty
   ELSE
      Fail   msg={{ hubs.site_list }} Hub site's:IPv6 prefix should be empty but got: ${ipv6_prefix_id}
   END
{% endif %}

{% endfor %}

{% endfor %}

{% endfor %}

{% endfor %}
{% endif %}
