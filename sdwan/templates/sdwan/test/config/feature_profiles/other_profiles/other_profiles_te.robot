*** Settings ***
Documentation   Verify Other Feature Profile Configuration TE
Name            Other Profiles Thousandeyes
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    other_profiles    thousandeyes
Resource        ../../../sdwan_common.resource


{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.other_profiles is defined %}
{% set profile_te_list = [] %}
{% for profile in sdwan.feature_profiles.other_profiles %}
 {% if profile.thousandeyes is defined %}
  {% set _ = profile_te_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_te_list != [] %}

*** Test Cases ***
Get Other Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/other
    Set Suite Variable   ${r}

{% for profile in sdwan.feature_profiles.other_profiles | default([]) %}
{% if profile.thousandeyes is defined %}

Verify Feature Profiles Other Profiles {{ profile.name }} Thousandeyes Feature {{ profile.thousandeyes.name | default(defaults.sdwan.feature_profiles.other_profiles.thousandeyes.name) }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${other_thousandeyes_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/other/${profile_id}/thousandeyes
    ${other_thousandeyes}=    Json Search    ${other_thousandeyes_res.json()}    data[?payload.name=='{{ profile.thousandeyes.name | default(defaults.sdwan.feature_profiles.other_profiles.thousandeyes.name) }}'] | [0].payload
    Run Keyword If    $other_thousandeyes is None    Fail    Feature '{{ profile.thousandeyes.name | default(defaults.sdwan.feature_profiles.other_profiles.thousandeyes.name) }}' expected to be configured within the other profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${other_thousandeyes}
    Should Be Equal Value Json String    ${other_thousandeyes}    name    {{ profile.thousandeyes.name | default(defaults.sdwan.feature_profiles.other_profiles.thousandeyes.name) }}    msg=name
    Should Be Equal Value Json Special_String    ${other_thousandeyes}    description    {{ profile.thousandeyes.description | default('not_defined') | normalize_special_string }}    msg=description
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].token    {{ profile.thousandeyes.account_group_token | default('not_defined') }}    {{ profile.thousandeyes.account_group_token_variable | default('not_defined') }}    msg=account_group_token
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].vpn    {{ profile.thousandeyes.vpn_id | default('not_defined') }}    {{ profile.thousandeyes.vpn_id_variable | default('not_defined') }}    msg=vpn
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].teMgmtIp   {{ profile.thousandeyes.management_ip | default('not_defined') }}    {{ profile.thousandeyes.management_ip_variable | default('not_defined') }}    msg=management_ip
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].teMgmtSubnetMask   {{ profile.thousandeyes.management_subnet_mask | default('not_defined') }}    {{ profile.thousandeyes.management_subnet_mask_variable | default('not_defined') }}    msg=management_subnet_mask
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].teVpgIp    {{ profile.thousandeyes.agent_default_gateway | default('not_defined') }}    {{ profile.thousandeyes.agent_default_gateway_variable | default('not_defined') }}    msg=agent_default_gateway
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].nameServer    {{ profile.thousandeyes.name_server_ip | default('not_defined') }}    {{ profile.thousandeyes.name_server_ip_variable | default('not_defined') }}    msg=name_server_ip
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].hostname    {{ profile.thousandeyes.hostname | default('not_defined') }}    {{ profile.thousandeyes.hostname_variable | default('not_defined') }}    msg=hostname
    Should Be Equal Value Json String    ${other_thousandeyes}    data.virtualApplication[0].proxyConfig.proxyType.value    {{ profile.thousandeyes.proxy_type | default('not_defined') }}    msg=proxy_type
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].proxyConfig.proxyHost    {{ profile.thousandeyes.static_proxy_host | default('not_defined') }}    {{ profile.thousandeyes.static_proxy_host_variable | default('not_defined') }}    msg=static_proxy_host
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].proxyConfig.proxyPort    {{ profile.thousandeyes.static_proxy_port | default('not_defined') }}    {{ profile.thousandeyes.static_proxy_port_variable | default('not_defined') }}    msg=static_proxy_port
    Should Be Equal Value Json Yaml    ${other_thousandeyes}    data.virtualApplication[0].proxyConfig.pacUrl    {{ profile.thousandeyes.pac_proxy_url | default('not_defined') }}    {{ profile.thousandeyes.pac_proxy_url_variable | default('not_defined') }}    msg=pac_proxy_url

{% endif %}
{% endfor %}
{% endif %}

{% endif %}