*** Settings ***
Documentation   Verify System Feature Profile Configuration OMP
Name            System Profiles OMP
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    system_profiles    omp
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_omp_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.omp is defined %}
  {% set _ = profile_omp_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_omp_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.omp is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} OMP Feature {{ profile.omp.name | default(defaults.sdwan.feature_profiles.system_profiles.omp.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId

    ${system_omp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/omp
    ${system_omp}=    Json Search    ${system_omp_res.json()}    data[0].payload
    Run Keyword If    $system_omp is None    Fail    Feature '{{ profile.omp.name | default(defaults.sdwan.feature_profiles.system_profiles.omp.name) }}' expected to be configured within the system profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${system_omp}

    Should Be Equal Value Json String    ${system_omp}    name    {{ profile.omp.name | default(defaults.sdwan.feature_profiles.system_profiles.omp.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${system_omp}    description    {{ profile.omp.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml    ${system_omp}    data.gracefulRestart    {{ profile.omp.graceful_restart | default("not_defined") }}    {{ profile.omp.graceful_restart_variable| default('not_defined') }}    msg=graceful_restart
    Should Be Equal Value Json Yaml    ${system_omp}    data.overlayAs    {{ profile.omp.overlay_as | default("not_defined") }}    {{ profile.omp.overlay_as_variable| default('not_defined') }}    msg=overlay_as
    Should Be Equal Value Json Yaml    ${system_omp}    data.ecmpLimit    {{ profile.omp.ecmp_limit | default('not_defined')  }}    {{ profile.omp.ecmp_limit_variable| default('not_defined') }}    msg=ecmp_limit
    Should Be Equal Value Json Yaml    ${system_omp}    data.sendPathLimit    {{ profile.omp.send_path_limit | default('not_defined')  }}    {{ profile.omp.send_path_limit_variable| default('not_defined') }}    msg=send_path_limit
    Should Be Equal Value Json Yaml    ${system_omp}    data.shutdown    {{ profile.omp.shutdown | default('not_defined')  }}    {{ profile.omp.shutdown_variable| default('not_defined') }}    msg=shutdown
    Should Be Equal Value Json Yaml    ${system_omp}    data.ompAdminDistanceIpv4    {{ profile.omp.omp_admin_distance_ipv4 | default('not_defined')  }}    {{ profile.omp.omp_admin_distance_ipv4_variable| default('not_defined') }}    msg=omp_admin_distance_ipv4
    Should Be Equal Value Json Yaml    ${system_omp}    data.ompAdminDistanceIpv6    {{ profile.omp.omp_admin_distance_ipv6 | default('not_defined')  }}    {{ profile.omp.omp_admin_distance_ipv6_variable| default('not_defined') }}    msg=omp_admin_distance_ipv6
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertisementInterval    {{ profile.omp.advertisement_interval | default('not_defined')  }}    {{ profile.omp.advertisement_interval_variable| default('not_defined') }}    msg=advertisement_interval
    Should Be Equal Value Json Yaml    ${system_omp}    data.aspathAutoTranslation    {{ profile.omp.aspath_auto_translation | default('not_defined')  }}    {{ profile.omp.aspath_auto_translation_variable| default('not_defined') }}    msg=aspath_auto_translation
    Should Be Equal Value Json Yaml    ${system_omp}    data.gracefulRestartTimer    {{ profile.omp.graceful_restart_timer | default('not_defined')  }}    {{ profile.omp.graceful_restart_timer_variable| default('not_defined') }}    msg=graceful_restart_timer
    Should Be Equal Value Json Yaml    ${system_omp}    data.eorTimer    {{ profile.omp.eor_timer | default('not_defined')  }}    {{ profile.omp.eor_timer_variable| default('not_defined') }}    msg=eor_timer
    Should Be Equal Value Json Yaml    ${system_omp}    data.holdtime    {{ profile.omp.holdtime | default('not_defined')  }}    {{ profile.omp.holdtime_variable| default('not_defined') }}    msg=holdtime

    Should Be Equal Value Json Yaml    ${system_omp}    data.ignoreRegionPathLength    {{ profile.omp.ignore_region_path_length | default('not_defined')  }}    {{ profile.omp.ignore_region_path_length_variable| default('not_defined') }}    msg=ignore_region_path_length
    Should Be Equal Value Json Yaml    ${system_omp}    data.transportGateway    {{ profile.omp.transport_gateway | default('not_defined')  }}    {{ profile.omp.transport_gateway_variable| default('not_defined') }}    msg=transport_gateway

    ${site_types_list}=    Create List    {{ profile.omp.get('site_types', []) | join('   ') }}
    ${site_types_list}=    Set Variable If    ${site_types_list} == []    not_defined    ${site_types_list}
    Should Be Equal Value Json Yaml    ${system_omp}    data.siteTypesForTransportGateway    ${site_types_list}    {{ profile.omp.site_types_variable| default('not_defined') }}    msg=site_types

# Check advertise IPv4
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.bgp    {{ profile.omp.advertise_ipv4_bgp | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_bgp_variable| default('not_defined') }}    msg=advertise_ipv4_bgp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.ospf    {{ profile.omp.advertise_ipv4_ospf | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_ospf_variable| default('not_defined') }}    msg=advertise_ipv4_ospf
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.ospfv3    {{ profile.omp.advertise_ipv4_ospf_v3 | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_ospf_v3_variable| default('not_defined') }}    msg=advertise_ipv4_ospf_v3
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.connected    {{ profile.omp.advertise_ipv4_connected | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_connected_variable| default('not_defined') }}    msg=advertise_ipv4_connected
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.static    {{ profile.omp.advertise_ipv4_static | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_static_variable| default('not_defined') }}    msg=advertise_ipv4_static
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.eigrp    {{ profile.omp.advertise_ipv4_eigrp | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_eigrp_variable| default('not_defined') }}    msg=advertise_ipv4_eigrp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.lisp    {{ profile.omp.advertise_ipv4_lisp | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_lisp_variable| default('not_defined') }}    msg=advertise_ipv4_lisp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv4.isis    {{ profile.omp.advertise_ipv4_isis | default('not_defined')  }}    {{ profile.omp.advertise_ipv4_isis_variable| default('not_defined') }}    msg=advertise_ipv4_isis

# Loop over advertise IPv6
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.bgp    {{ profile.omp.advertise_ipv6_bgp | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_bgp_variable| default('not_defined') }}    msg=advertise_ipv6_bgp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.ospf    {{ profile.omp.advertise_ipv6_ospf | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_ospf_variable| default('not_defined') }}    msg=advertise_ipv6_ospf
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.connected    {{ profile.omp.advertise_ipv6_connected | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_connected_variable| default('not_defined') }}    msg=advertise_ipv6_connected
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.static    {{ profile.omp.advertise_ipv6_static | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_static_variable| default('not_defined') }}    msg=advertise_ipv6_static
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.eigrp    {{ profile.omp.advertise_ipv6_eigrp | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_eigrp_variable| default('not_defined') }}    msg=advertise_ipv6_eigrp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.lisp    {{ profile.omp.advertise_ipv6_lisp | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_lisp_variable| default('not_defined') }}    msg=advertise_ipv6_lisp
    Should Be Equal Value Json Yaml    ${system_omp}    data.advertiseIpv6.isis    {{ profile.omp.advertise_ipv6_isis | default('not_defined')  }}    {{ profile.omp.advertise_ipv6_isis_variable| default('not_defined') }}    msg=advertise_ipv6_isis


{% endif %}
{% endfor %}

{% endif %}

{% endif %}
