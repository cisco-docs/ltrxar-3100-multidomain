*** Settings ***
Documentation   Verify System Feature Profile Configuration NTP
Name            System Profiles NTP
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    ntp
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_ntp_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.ntp is defined %}
  {% set _ = profile_ntp_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ntp_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.ntp is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} NTP Feature {{ profile.ntp.name | default(defaults.sdwan.feature_profiles.system_profiles.ntp.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_ntp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/ntp
    ${system_ntp}=    Json Search    ${system_ntp_res.json()}    data[0].payload
    Run Keyword If    $system_ntp is None    Fail    Feature '{{ profile.ntp.name | default(defaults.sdwan.feature_profiles.system_profiles.ntp.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_ntp}

    Should Be Equal Value Json String    ${system_ntp}    name    {{ profile.ntp.name | default(defaults.sdwan.feature_profiles.system_profiles.ntp.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_ntp}    description    {{ profile.ntp.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${system_ntp}    data.leader.enable    {{ profile.ntp.authoritative_ntp_server | default("not_defined") }}    {{ profile.ntp.authoritative_ntp_server_variable| default('not_defined') }}    msg=authoritative_ntp_server
    Should Be Equal Value Json Yaml    ${system_ntp}    data.leader.stratum    {{ profile.ntp.authoritative_ntp_server_stratum | default("not_defined") }}    {{ profile.ntp.authoritative_ntp_server_stratum_variable| default('not_defined') }}    msg=authoritative_ntp_server_stratum
    Should Be Equal Value Json Yaml    ${system_ntp}    data.leader.source    {{ profile.ntp.authoritative_ntp_server_source_interface | default("not_defined") }}    {{ profile.ntp.authoritative_ntp_server_source_interface_variable| default('not_defined') }}    msg=authoritative_ntp_server_source_interface

    Should Be Equal Value Json Yaml    ${system_ntp}    data.authentication.trustedKeys    {{ profile.ntp.trusted_keys | default("not_defined") }}    {{ profile.ntp.trusted_keys_variable| default('not_defined') }}    msg=trusted_keys

    Should Be Equal Value Json List Length    ${system_ntp}    data.authentication.authenticationKeys    {{ profile.ntp.get('authentication_keys', []) | length }}    msg=authentication_keys_count

{% if profile.ntp.authentication_keys is defined and profile.ntp.get('authentication_keys', [])|length > 0 %}
    Log  === Authentication Keys ===
{% for key_entry in profile.ntp.authentication_keys | default([]) %}

    Should Be Equal Value Json Yaml    ${system_ntp}    data.authentication.authenticationKeys[{{ loop.index0 }}].keyId    {{ key_entry.id | default("not_defined") }}    {{ key_entry.id_variable| default('not_defined') }}    msg=id
    Should Be Equal Value Json Yaml    ${system_ntp}    data.authentication.authenticationKeys[{{ loop.index0 }}].md5Value    {{ key_entry.md5_value | default("not_defined") }}    {{ key_entry.md5_value_variable| default('not_defined') }}    msg=md5_value

{% endfor %}
{% endif %}
    Should Be Equal Value Json List Length    ${system_ntp}    data.server    {{ profile.ntp.get('servers', []) | length }}    msg=servers_count

{% if profile.ntp.servers is defined and profile.ntp.get('servers', [])|length > 0 %}
    Log  === NTP Servers ===
{% for server_entry in profile.ntp.servers | default([]) %}

    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].key    {{ server_entry.authentication_key | default("not_defined") }}    {{ server_entry.authentication_key_variable| default('not_defined') }}    msg=authentication_key
    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].name    {{ server_entry.hostname_ip | default("not_defined") }}    {{ server_entry.hostname_ip_variable| default('not_defined') }}    msg=hostname_ip
    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].prefer    {{ server_entry.prefer | default("not_defined") }}    {{ server_entry.prefer_variable| default('not_defined') }}    msg=prefer
    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].vpn    {{ server_entry.vpn_id | default("not_defined") }}    {{ server_entry.vpn_id_variable| default('not_defined') }}    msg=vpn_id
    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].version    {{ server_entry.ntp_version | default("not_defined") }}    {{ server_entry.ntp_version_variable| default('not_defined') }}    msg=ntp_version
    Should Be Equal Value Json Yaml    ${system_ntp}    data.server[{{ loop.index0 }}].sourceInterface    {{ server_entry.source_interface | default("not_defined") }}    {{ server_entry.source_interface_variable| default('not_defined') }}    msg=source_interface

{% endfor %}
{% endif %}
{% endif %}
{% endfor %}

{% endif %}

{% endif %}