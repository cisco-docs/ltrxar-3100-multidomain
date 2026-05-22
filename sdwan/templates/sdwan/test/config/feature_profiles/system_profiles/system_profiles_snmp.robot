*** Settings ***
Documentation   Verify System Feature Profile Configuration SNMP
Name            System Profiles SNMP
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    snmp
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_snmp_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.snmp is defined %}
  {% set _ = profile_snmp_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_snmp_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.snmp is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} SNMP Feature {{ profile.snmp.name | default(defaults.sdwan.feature_profiles.system_profiles.snmp.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_snmp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/snmp
    ${system_snmp}=    Json Search    ${system_snmp_res.json()}    data[0].payload
    Run Keyword If    $system_snmp is None    Fail    Feature '{{ profile.snmp.name | default(defaults.sdwan.feature_profiles.system_profiles.snmp.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_snmp}

    Should Be Equal Value Json String    ${system_snmp}    name    {{ profile.snmp.name | default(defaults.sdwan.feature_profiles.system_profiles.snmp.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_snmp}    description    {{ profile.snmp.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json List Length    ${system_snmp}    data.community    {{ profile.snmp.get('communities', []) | length }}    msg=communities length
{% if profile.snmp.communities is defined and profile.snmp.get('communities', []) | length > 0 %}
    Log     === Communities List ===
{% for snmp_community in profile.snmp.communities | default([]) %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.community[{{ loop.index0 }}].authorization    {{ snmp_community.authorization | default('not_defined') }}    {{ snmp_community.authorization_variable | default('not_defined') }}    msg=authorization
    Should Be Equal Value Json Yaml    ${system_snmp}    data.community[{{ loop.index0 }}].userLabel    {{ snmp_community.user_label | default('not_defined') }}    not_defined    msg=user label
    Should Be Equal Value Json Yaml    ${system_snmp}    data.community[{{ loop.index0 }}].view    {{ snmp_community.view | default('not_defined') }}    {{ snmp_community.view_variable | default('not_defined') }}    msg=view

    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Should Be Equal Value Json Yaml    ${system_snmp[0]}    $.data.community[{{ loop.index0 }}].name    {{ snmp_community.name | default('not_defined') }}    not_defined    msg=name    var_msg=not_defined

{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.contact    {{ profile.snmp.contact_person | default('not_defined') }}    {{ profile.snmp.contact_person_variable | default('not_defined') }}    msg=contact person

    Should Be Equal Value Json List Length    ${system_snmp}    data.group    {{ profile.snmp.get('groups', []) | length }}    msg=groups length
{% if profile.snmp.groups is defined and profile.snmp.get('groups', []) | length > 0 %}
    Log     === Groups List ===
{% for snmp_group in profile.snmp.groups | default([]) %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.group[{{ loop.index0 }}].name    {{ snmp_group.name | default('not_defined') }}    not_defined    msg=name
    Should Be Equal Value Json Yaml    ${system_snmp}    data.group[{{ loop.index0 }}].securityLevel    {{ snmp_group.security_level | default('not_defined') }}    not_defined    msg=security level
    Should Be Equal Value Json Yaml    ${system_snmp}    data.group[{{ loop.index0 }}].view    {{ snmp_group.view | default('not_defined') }}    {{ snmp_group.view_variable | default('not_defined') }}    msg=view
    
{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.location    {{ profile.snmp.location | default('not_defined') }}    {{ profile.snmp.location_variable | default('not_defined') }}    msg=location
    Should Be Equal Value Json Yaml    ${system_snmp}    data.shutdown    {{ profile.snmp.shutdown | default('not_defined') }}    {{ profile.snmp.shutdown_variable | default('not_defined') }}    msg=shutdown

    Should Be Equal Value Json List Length    ${system_snmp}    data.target    {{ profile.snmp.get('trap_target_servers', []) | length }}    msg=trap target servers length
{% if profile.snmp.trap_target_servers is defined and profile.snmp.get('trap_target_servers', []) | length > 0 %}
    Log     === Trap Target Servers List ===
{% for snmp_target in profile.snmp.trap_target_servers | default([]) %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].ip    {{ snmp_target.ip | default('not_defined') }}    {{ snmp_target.ip_variable	 | default('not_defined') }}    msg=ip
    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].port    {{ snmp_target.port | default('not_defined') }}    {{ snmp_target.port_variable | default('not_defined') }}    msg=port
    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].sourceInterface    {{ snmp_target.source_interface | default('not_defined') }}    {{ snmp_target.source_interface_variable | default('not_defined') }}    msg=source interface
    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].user    {{ snmp_target.user | default('not_defined') }}    {{ snmp_target.user_variable | default('not_defined') }}    msg=user
    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].userLabel    {{ snmp_target.user_label | default('not_defined') }}    not_defined    msg=user label
    Should Be Equal Value Json Yaml    ${system_snmp}    data.target[{{ loop.index0 }}].vpnId    {{ snmp_target.vpn_id | default('not_defined') }}    {{ snmp_target.vpn_id_variable | default('not_defined') }}    msg=vpn id
    
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${system_snmp}    data.user    {{ profile.snmp.get('users', []) | length }}    msg=users length
{% if profile.snmp.users is defined and profile.snmp.get('users', []) | length > 0 %}
    Log     === Users List ===
{% for snmp_user in profile.snmp.users | default([]) %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.user[{{ loop.index0 }}].auth    {{ snmp_user.authentication_protocol | default('not_defined') }}    {{ snmp_user.authentication_protocol_variable | default('not_defined') }}    msg=authentication protocol
    Should Be Equal Value Json Yaml    ${system_snmp}    data.user[{{ loop.index0 }}].group    {{ snmp_user.group | default('not_defined') }}    {{ snmp_user.group_variable | default('not_defined') }}    msg=group
    Should Be Equal Value Json Yaml    ${system_snmp}    data.user[{{ loop.index0 }}].name    {{ snmp_user.name | default('not_defined') }}    not_defined    msg=name
    Should Be Equal Value Json Yaml    ${system_snmp}    data.user[{{ loop.index0 }}].priv    {{ snmp_user.privacy_protocol | default('not_defined') }}    {{ snmp_user.privacy_protocol_variable | default('not_defined') }}    msg=privacy protocol

    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Should Be Equal Value Json Yaml    ${system_snmp[0]}    $.data.user[{{ loop.index0 }}].authPassword    {{ snmp_user.authentication_password | default('not_defined') }}    {{ snmp_user.authentication_password_variable | default('not_defined') }}    msg=authentication password    var_msg=authentication password variable
    # Should Be Equal Value Json Yaml    ${system_snmp[0]}    $.data.user[{{ loop.index0 }}].privPassword    {{ snmp_user.privacy_password | default('not_defined') }}    {{ snmp_user.privacy_password_variable | default('not_defined') }}    msg=privacy password    var_msg=privacy password variable
    
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${system_snmp}    data.view    {{ profile.snmp.get('views', []) | length }}    msg=views length
{% if profile.snmp.views is defined and profile.snmp.get('views', []) | length > 0 %}
    Log     === Views List ===
{% for snmp_view in profile.snmp.views | default([]) %}

    Should Be Equal Value Json Yaml    ${system_snmp}    data.view[{{ loop.index0 }}].name    {{ snmp_view.name | default('not_defined') }}    not_defined    msg=name

    Should Be Equal Value Json List Length    ${system_snmp}    data.view[{{ loop.index0 }}].oid    {{ snmp_view.oids | length }}    msg=oids length
    {% for snmp_view_oid in snmp_view.oids | default([]) %}

        Should Be Equal Value Json Yaml    ${system_snmp}    data.view[{{ loop.index0 }}].oid[{{ loop.index0 }}].exclude    {{ snmp_view_oid.exclude | default('not_defined') }}    {{ snmp_view_oid.exclude_variable	 | default('not_defined') }}    msg=exclude
        Should Be Equal Value Json Yaml    ${system_snmp}    data.view[{{ loop.index0 }}].oid[{{ loop.index0 }}].id    {{ snmp_view_oid.id | default('not_defined') }}    {{ snmp_view_oid.id_variable	 | default('not_defined') }}    msg=id

    {% endfor %}
    
{% endfor %}
{% endif %}


{% endif %}
{% endfor %}

{% endif %}

{% endif %}
