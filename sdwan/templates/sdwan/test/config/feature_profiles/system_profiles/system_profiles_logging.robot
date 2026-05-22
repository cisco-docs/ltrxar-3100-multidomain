*** Settings ***
Name            System Profiles Logging
Documentation   Verify System Profile Logging Feature Configuration
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    logging
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_logging_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.logging is defined %}
  {% set _ = profile_logging_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_logging_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.logging is defined %}

Verify Feature Profiles System Profile {{ profile.name }} Logging Feature {{ profile.logging.name | default(defaults.sdwan.feature_profiles.system_profiles.logging.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_logging_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/logging
    ${system_logging}=    Json Search    ${system_logging_res.json()}    data[0].payload
    Run Keyword If    $system_logging is None    Fail    Feature '{{ profile.logging.name | default(defaults.sdwan.feature_profiles.system_profiles.logging.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_logging}
    Should Be Equal Value Json String    ${system_logging}    name    {{ profile.logging.name | default(defaults.sdwan.feature_profiles.system_profiles.logging.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_logging}    description    {{ profile.logging.description | default('not_defined') | normalize_special_string }}    msg=description
    Should Be Equal Value Json Yaml    ${system_logging}    data.disk.file.diskFileSize    {{ profile.logging.disk_file_size | default('not_defined') }}    {{ profile.logging.disk_file_size_variable | default('not_defined') }}    msg=logging disk_file_size
    Should Be Equal Value Json Yaml    ${system_logging}    data.disk.file.diskFileRotate    {{ profile.logging.disk_file_rotate | default('not_defined') }}    {{ profile.logging.disk_file_rotate_variable| default('not_defined') }}    msg=logging disk_file_rotate

    Should Be Equal Value Json List Length    ${system_logging}    data.tlsProfile    {{ profile.logging.get('tls_profiles', []) | length }}    msg=tls_profiles_count

{% if profile.logging.tls_profiles is defined and profile.logging.get('tls_profiles', [])|length > 0 %}

    Log     === TLS profiles === 

{% for tls_profile in profile.logging.tls_profiles | default([]) %}

    Should Be Equal Value Json Yaml    ${system_logging}    data.tlsProfile[{{ loop.index0 }}].profile    {{ tls_profile.name | default('not_defined') }}    {{ tls_profile.name_variable | default('not_defined') }}    msg=logging profile name
    Should Be Equal Value Json Yaml    ${system_logging}    data.tlsProfile[{{ loop.index0 }}].tlsVersion    {{ tls_profile.tls_version | default('not_defined') }}    {{ tls_profile.tls_version_variable | default('not_defined') }}    msg=logging profile tls_version

    ${logging_tls_profiles_list}=    Create List    {{ tls_profile.get('cipher_suites', [])  | join('   ') }}
    ${logging_tls_profiles_list}=    Set Variable If    ${logging_tls_profiles_list} == []    not_defined    ${logging_tls_profiles_list}

    Should Be Equal Value Json Yaml    ${system_logging}    data.tlsProfile[{{ loop.index0 }}].cipherSuiteList    ${logging_tls_profiles_list}    {{ tls_profile.cipher_suites_variable | default('not_defined') }}    msg=logging profile cipher_suites
{% endfor %}

{% endif %}

    Should Be Equal Value Json List Length    ${system_logging}    data.server    {{ profile.logging.get('ipv4_servers', []) | length }}    msg=logging_ipv4_servers_count

{% if profile.logging.ipv4_servers is defined and profile.logging.get('ipv4_servers', [])|length > 0 %}

    Log     === Ipv4 Servers ===

{% for server in profile.logging.ipv4_servers | default([]) %}
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].name    {{ server.hostname_ip | default('not_defined') }}    {{ server.hostname_ip_variable | default('not_defined') }}    msg=IPv4 server hostname_ip
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].vpn    {{ server.vpn_id | default('not_defined') }}    {{ server.vpn_id_variable | default('not_defined') }}    msg=IPv4 server vpn_id
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].sourceInterface    {{ server.source_interface | default('not_defined') }}    {{ server.source_interface_variable | default('not_defined') }}    msg=IPv4 server source_interface
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].priority    {{ server.severity | default('not_defined') }}    {{ server.severity_variable | default('not_defined') }}    msg=IPv4 server severity
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].tlsEnable    {{ server.tls_enable | default('not_defined') }}    {{ server.tls_enable_variable | default('not_defined') }}    msg=IPv4 server tls_enable
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].tlsPropertiesCustomProfile    {{ server.tls_properties_custom_profile | default('not_defined') }}    {{ server.tls_properties_custom_profile_variable | default('not_defined') }}    msg=IPv4 server tls_properties_custom_profile
    Should Be Equal Value Json Yaml    ${system_logging}    data.server[{{ loop.index0 }}].tlsPropertiesProfile    {{ server.tls_properties_profile | default('not_defined') }}    {{ server.tls_properties_profile_variable | default('not_defined') }}    msg=IPv4 server tls_properties_profile
{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${system_logging}    data.ipv6Server    {{ profile.logging.get('ipv6_servers', []) | length }}    msg=logging_ipv6_servers_count
{% if profile.logging.ipv6_servers is defined and profile.logging.get('ipv6_servers', [])|length > 0 %}

    Log     === Ipv6 Servers ===

{% for server in profile.logging.ipv6_servers | default([]) %}
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].name    {{ server.hostname_ip | default('not_defined') }}    {{ server.hostname_ip_variable | default('not_defined') }}    msg=IPv6 server hostname_ip
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].vpn    {{ server.vpn_id | default('not_defined') }}    {{ server.vpn_id_variable | default('not_defined') }}    msg=IPv6 server vpn_id
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].sourceInterface    {{ server.source_interface | default('not_defined') }}    {{ server.source_interface_variable | default('not_defined') }}    msg=IPv6 server source_interface
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].priority    {{ server.severity | default('not_defined') }}    {{ server.severity_variable | default('not_defined') }}    msg=IPv6 server severity
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].tlsEnable    {{ server.tls_enable | default('not_defined') }}    {{ server.tls_enable_variable | default('not_defined') }}    msg=IPv6 server tls_enable
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].tlsPropertiesCustomProfile    {{ server.tls_properties_custom_profile | default('not_defined') }}    {{ server.tls_properties_custom_profile_variable | default('not_defined') }}    msg=IPv6 server tls_properties_custom_profile
    Should Be Equal Value Json Yaml    ${system_logging}    data.ipv6Server[{{ loop.index0 }}].tlsPropertiesProfile    {{ server.tls_properties_profile | default('not_defined') }}    {{ server.tls_properties_profile_variable | default('not_defined') }}    msg=IPv6 server tls_properties_profile
{% endfor %}
{% endif %}


{% endif %}
{% endfor %}

{% endif %}

{% endif %}