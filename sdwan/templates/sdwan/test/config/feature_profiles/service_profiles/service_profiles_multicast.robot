*** Settings ***
Documentation   Verify Service Feature Profile Configuration Multicast Features
Name            Service Profiles Multicast Features
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    multicast
Resource        ../../../sdwan_common.resource


{% set profile_multicast_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', {}) %}
{% if profile.multicast_features is defined %}
{% set _ = profile_multicast_list.append(profile.name) %}
{% endif %}
{% endfor %}

{% if profile_multicast_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}

Get Policy Object Profile
    ${r_po}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object
    Set Suite Variable    ${r_po}

Get IPv4 Prefix Lists
    ${profile}=    Json Search    ${r_po.json()}    [?profileName=='{{ sdwan.feature_profiles.policy_object_profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ sdwan.feature_profiles.policy_object_profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${ipv4_prefix_raw}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/policy-object/${profile_id}/prefix
    Set Suite Variable    ${ipv4_prefix_raw}

{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.multicast_features is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} Multicast Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId
    Set Suite Variable    ${profile_id}
    ${service_multicast_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/routing/multicast
    Set Suite Variable    ${service_multicast_res}
    ${service_multicast}=    Json Search List    ${service_multicast_res.json()}    data[].payload
    Run Keyword If    $service_multicast == []    Fail    Multicast feature(s) expected to be configured within the service profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${service_multicast}


{% for multicast in profile.multicast_features | default([]) %}
    Log    === Multicast: {{ multicast.name }} ===

    ${service_multicast_feature}=    Json Search    ${service_multicast}    [?name=='{{ multicast.name }}'] | [0]
    Run Keyword If    $service_multicast_feature is None    Fail    Multicast feature '{{ multicast.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String    ${service_multicast_feature}    name    {{ multicast.name }}    msg=name
    Should Be Equal Value Json Special_String    ${service_multicast_feature}    description    {{ multicast.description | default('not_defined') | normalize_special_string }}    msg=description

    # basic
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.basic.sptOnly    {{ multicast.spt_only | default('not_defined') }}    {{ multicast.spt_only_variable | default('not_defined') }}    msg=multicast.spt_only
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.basic.localConfig.local    {{ multicast.local_replicator | default('not_defined') }}    {{ multicast.local_replicator_variable | default('not_defined') }}    msg=multicast.local_replicator
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.basic.localConfig.threshold    {{ multicast.threshold | default('not_defined') }}    {{ multicast.threshold_variable | default('not_defined') }}    msg=multicast.threshold

    # igmp
    Log    =====IGMP Interfaces=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.igmp.interface     {{ multicast.get('igmp_interfaces', []) | length }}    msg=multicast.igmp_interfaces length
{% if multicast.igmp_interfaces is defined and multicast.get('igmp_interfaces', [])|length > 0 %}
{% for igmp_interface in multicast.igmp_interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.igmp.interface[{{ loop.index0 }}].interfaceName    {{ igmp_interface.interface_name | default('not_defined') }}    {{ igmp_interface.interface_name_variable | default('not_defined') }}    msg=multicast.igmp_interfaces.interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.igmp.interface[{{ loop.index0 }}].version    {{ igmp_interface.version | default('not_defined') }}    not_defined    msg=multicast.igmp_interfaces.version

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.igmp.interface[{{ loop.index0 }}].joinGroup     {{ igmp_interface.get('join_groups', []) | length }}    msg=multicast.join_groups length
{% for join_group in igmp_interface.join_groups | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.igmp.interface[${outer_loop_index}].joinGroup[{{ loop.index0 }}].groupAddress    {{ join_group.group_address | default('not_defined') }}    {{ join_group.group_address_variable | default('not_defined') }}    msg=multicast.join_groups.group_address
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.igmp.interface[${outer_loop_index}].joinGroup[{{ loop.index0 }}].sourceAddress    {{ join_group.source_address | default('not_defined') }}    {{ join_group.source_address_variable | default('not_defined') }}    msg=multicast.join_groups.source_address
{% endfor %}

{% endfor %}
{% endif %}

    # pim
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.ssm.ssmRangeConfig.enableSSMFlag    {{ multicast.pim_source_specific_multicast | default('not_defined') }}    not_defined    msg=pim_source_specific_multicast
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.ssm.ssmRangeConfig.range    {{ multicast.pim_source_specific_multicast_access_list | default('not_defined') }}    {{ multicast.pim_source_specific_multicast_access_list_variable | default('not_defined') }}    msg=pim_source_specific_multicast_access_list
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.ssm.sptThreshold   {{ multicast.pim_spt_threshold | default('not_defined') }}    {{ multicast.pim_spt_threshold_variable | default('not_defined') }}    msg=pim_spt_threshold

    Log    ===== PIM Interfaces=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.interface     {{ multicast.get('pim_interfaces', []) | length }}    msg=pim_interfaces length
{% if multicast.pim_interfaces is defined and multicast.get('pim_interfaces', [])|length > 0 %}
{% for pim_interface in multicast.pim_interfaces | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.interface[{{ loop.index0 }}].interfaceName    {{ pim_interface.interface_name | default('not_defined') }}    {{ pim_interface.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.interface[{{ loop.index0 }}].queryInterval    {{ pim_interface.query_interval | default('not_defined') }}    {{ pim_interface.query_interval_variable | default('not_defined') }}    msg=query_interval
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.interface[{{ loop.index0 }}].joinPruneInterval    {{ pim_interface.join_prune_interval | default('not_defined') }}    {{ pim_interface.join_prune_interval_variable | default('not_defined') }}    msg=join_prune_interval
{% endfor %}
{% endif %}

    # staticRpAddresses
    Log    ===== PIM staticRpAddresses=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.rpAddr     {{ multicast.get('static_rp_addresses', []) | length }}    msg=static_rp_addresses length
{% if multicast.static_rp_addresses is defined and multicast.get('static_rp_addresses', [])|length > 0 %}
{% for static_rp_address in multicast.static_rp_addresses | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.rpAddr[{{ loop.index0 }}].address    {{ static_rp_address.ip_address | default('not_defined') }}    {{ static_rp_address.ip_address_variable | default('not_defined') }}    msg=ip_address
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.rpAddr[{{ loop.index0 }}].accessList    {{ static_rp_address.access_list | default('not_defined') }}    {{ static_rp_address.access_list_variable | default('not_defined') }}    msg=access_list
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.rpAddr[{{ loop.index0 }}].override    {{ static_rp_address.override | default('not_defined') }}    {{ static_rp_address.override_variable | default('not_defined') }}    msg=override
{% endfor %}
{% endif %}

    # autoRp
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.autoRp.enableAutoRPFlag    {{ multicast.auto_rp | default('not_defined') }}    {{ multicast.auto_rp_variable | default('not_defined') }}    msg=auto_rp

    # RpAnnounce
    Log    ===== PIM RpAnnounce=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.autoRp.sendRpAnnounceList     {{ multicast.get('auto_rp_announces', []) | length }}    msg=auto_rp_announces length
{% if multicast.auto_rp_announces is defined and multicast.get('auto_rp_announces', [])|length > 0 %}
{% for auto_rp_announce in multicast.auto_rp_announces | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.autoRp.sendRpAnnounceList[{{ loop.index0 }}].interfaceName    {{ auto_rp_announce.interface_name | default('not_defined') }}    {{ auto_rp_announce.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.autoRp.sendRpAnnounceList[{{ loop.index0 }}].scope    {{ auto_rp_announce.scope | default('not_defined') }}    {{ auto_rp_announce.scope_variable | default('not_defined') }}    msg=scope
{% endfor %}
{% endif %}

    # RpDiscovery
    Log    ===== PIM RpDiscovery=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.autoRp.sendRpDiscovery     {{ multicast.get('auto_rp_discoveries', []) | length }}    msg=auto_rp_discoveries length
{% if multicast.auto_rp_discoveries is defined and multicast.get('auto_rp_discoveries', [])|length > 0 %}
{% for auto_rp_discover in multicast.auto_rp_discoveries | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.autoRp.sendRpDiscovery[{{ loop.index0 }}].interfaceName    {{ auto_rp_discover.interface_name | default('not_defined') }}    {{ auto_rp_discover.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.autoRp.sendRpDiscovery[{{ loop.index0 }}].scope    {{ auto_rp_discover.scope | default('not_defined') }}    {{ auto_rp_discover.scope_variable | default('not_defined') }}    msg=scope
{% endfor %}
{% endif %}

    # pimBsr rpCandidate
    Log    ===== PIM BSR RpCandidate=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.pimBsr.rpCandidate     {{ multicast.get('pim_bsr_rp_candidates', []) | length }}    msg=pim_bsr_rp_candidates length
{% if multicast.pim_bsr_rp_candidates is defined and multicast.get('pim_bsr_rp_candidates', [])|length > 0 %}
{% for pim_bsr_rp_candidate in multicast.pim_bsr_rp_candidates | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.rpCandidate[{{ loop.index0 }}].interfaceName    {{ pim_bsr_rp_candidate.interface_name | default('not_defined') }}    {{ pim_bsr_rp_candidate.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.rpCandidate[{{ loop.index0 }}].groupList    {{ pim_bsr_rp_candidate.access_list | default('not_defined') }}    {{ pim_bsr_rp_candidate.access_list_variable | default('not_defined') }}    msg=access_list
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.rpCandidate[{{ loop.index0 }}].interval    {{ pim_bsr_rp_candidate.interval | default('not_defined') }}    {{ pim_bsr_rp_candidate.interval_variable | default('not_defined') }}    msg=interval
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.rpCandidate[{{ loop.index0 }}].priority    {{ pim_bsr_rp_candidate.priority | default('not_defined') }}    {{ pim_bsr_rp_candidate.priority_variable | default('not_defined') }}    msg=priority
{% endfor %}
{% endif %}

    # pimBsr bsrCandidate
    Log    ===== PIM BSR RpCandidate=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.pim.pimBsr.bsrCandidate     {{ multicast.get('pim_bsr_candidates', []) | length }}    msg=pim_bsr_candidates length
{% if multicast.pim_bsr_candidates is defined and multicast.get('pim_bsr_candidates', [])|length > 0 %}
{% for pim_bsr_candidate in multicast.pim_bsr_candidates | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.bsrCandidate[{{ loop.index0 }}].interfaceName    {{ pim_bsr_candidate.interface_name | default('not_defined') }}    {{ pim_bsr_candidate.interface_name_variable | default('not_defined') }}    msg=interface_name
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.bsrCandidate[{{ loop.index0 }}].mask    {{ pim_bsr_candidate.hash_mask_length | default('not_defined') }}    {{ pim_bsr_candidate.hash_mask_length_variable | default('not_defined') }}    msg=hash_mask_length
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.bsrCandidate[{{ loop.index0 }}].acceptRpCandidate    {{ pim_bsr_candidate.accept_candidate_access_list | default('not_defined') }}    {{ pim_bsr_candidate.accept_candidate_access_list_variable | default('not_defined') }}    msg=accept_candidate_access_list
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.pim.pimBsr.bsrCandidate[{{ loop.index0 }}].priority    {{ pim_bsr_candidate.priority | default('not_defined') }}    {{ pim_bsr_candidate.priority_variable | default('not_defined') }}    msg=priority
{% endfor %}
{% endif %}

    # msdp
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.originatorId    {{ multicast.msdp_originator_id | default('not_defined') }}    {{ multicast.msdp_originator_id_variable | default('not_defined') }}    msg=msdp_originator_id
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.refreshTimer    {{ multicast.msdp_connection_retry_interval | default('not_defined') }}    {{ multicast.msdp_connection_retry_interval_variable | default('not_defined') }}    msg=msdp_connection_retry_interval

    Log    ===== MSDP Groups=====
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.msdp.msdpList     {{ multicast.get('msdp_mesh_groups', []) | length }}    msg=msdp_mesh_groups length
{% if multicast.msdp_mesh_groups is defined and multicast.get('msdp_mesh_groups', [])|length > 0 %}
{% for msdp_mesh_group in multicast.msdp_mesh_groups | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[{{ loop.index0 }}].meshGroup    {{ msdp_mesh_group.name | default('not_defined') }}    {{ msdp_mesh_group.name_variable | default('not_defined') }}    msg=name

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
    Should Be Equal Value Json List Length    ${service_multicast_feature}    data.msdp.msdpList[{{ loop.index0 }}].peer     {{ msdp_mesh_group.get('peers', []) | length }}    msg=peers length
{% for peer in msdp_mesh_group.peers | default([]) %}
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].peerIp    {{ peer.peer_ip | default('not_defined') }}    {{ peer.peer_ip_variable | default('not_defined') }}    msg=peer_ip
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].connectSourceIntf    {{ peer.connection_source_interface | default('not_defined') }}    {{ peer.connection_source_interface_variable | default('not_defined') }}    msg=connection_source_interface
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].remoteAs    {{ peer.remote_as | default('not_defined') }}    {{ peer.remote_as_variable | default('not_defined') }}    msg=remote_as
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].password    {{ peer.peer_authentication_password | default('not_defined') }}    {{ peer.peer_authentication_password_variable | default('not_defined') }}    msg=peer_authentication_password
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].keepaliveInterval    {{ peer.keepalive_interval | default('not_defined') }}    {{ peer.keepalive_interval_variable | default('not_defined') }}    msg=keepalive_interval
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].keepaliveHoldTime    {{ peer.keepalive_hold_time | default('not_defined') }}    {{ peer.keepalive_hold_time_variable | default('not_defined') }}    msg=keepalive_hold_time
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].saLimit    {{ peer.sa_limit | default('not_defined') }}    {{ peer.sa_limit_variable | default('not_defined') }}    msg=sa_limit
    Should Be Equal Value Json Yaml    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].default.defaultPeer    {{ peer.default_peer | default('not_defined') }}    not_defined    msg=default_peer

    Should Be Equal Referenced Object Name    ${service_multicast_feature}    data.msdp.msdpList[${outer_loop_index}].peer[{{ loop.index0 }}].default.prefixList.refId.value    ${ipv4_prefix_raw.json()}    {{ peer.prefix_list | default('not_defined') }}    msdp.peers.prefix_list

{% endfor %}

{% endfor %}
{% endif %}



{% endfor %}


{% endif %}
{% endfor %}


{% endif %}