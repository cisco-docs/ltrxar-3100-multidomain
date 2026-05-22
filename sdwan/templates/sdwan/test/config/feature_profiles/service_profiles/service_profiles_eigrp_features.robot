*** Settings ***
Documentation   Verify Service Feature Profile Configuration EIGRP Feature
Name            Service Profiles EIGRP Feature
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles    service_profiles    eigrp
Resource        ../../../sdwan_common.resource


{% set profile_eigrp_list = [] %}
{% for profile in sdwan.get('feature_profiles', {}).get('service_profiles', {}) %}
 {% if profile.eigrp_features is defined %}
  {% set _ = profile_eigrp_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_eigrp_list != [] %}

*** Test Cases ***
Get Service Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service
    Set Suite Variable    ${r}


{% for profile in sdwan.feature_profiles.service_profiles | default([]) %}
{% if profile.eigrp_features is defined %}

Verify Feature Profiles Service Profiles {{ profile.name }} EIGRP Feature
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{ profile.name }}' should be present on the Manager
    Set Suite Variable    ${profile}
    ${profile_id}=    Json Search String    ${profile}    profileId

    Set Suite Variable    ${profile_id}
    ${service_eigrp_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/routing/eigrp
    Set Suite Variable    ${service_eigrp_res}
    ${service_eigrp}=    Json Search List    ${service_eigrp_res.json()}    data[].payload
    Run Keyword If    $service_eigrp == []    Fail    EIGRP feature(s) expected to be configured within the service profile '{{ profile.name }}' on the Manager
    Set Suite Variable    ${service_eigrp}

    # Extract route policies since they might be used in EIGRP
    ${route_policies_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/service/${profile_id}/route-policy
    Set Suite Variable    ${route_policies_res}

{% for eigrp in profile.eigrp_features | default([]) %}
    Log     === EIGRP: {{ eigrp.name }} ===

    # for each eigrp find the corresponding one in the json and check parameters:
    ${eigrp_feature}=    Json Search    ${service_eigrp}    [?name=='{{ eigrp.name }}'] | [0]
    Run Keyword If    $eigrp_feature is None    Fail    EIGRP feature '{{ eigrp.name }}' expected in service profile '{{ profile.name }}'

    Should Be Equal Value Json String     ${eigrp_feature}             name            {{ eigrp.name }}    msg=name
    Should Be Equal Value Json Special_String     ${eigrp_feature}     description    {{ eigrp.description | default('not_defined') | normalize_special_string }}    msg=description

    Should Be Equal Value Json Yaml           ${eigrp_feature}    data.asNum                         {{ eigrp.autonomous_system_id | default('not_defined') }}    {{ eigrp.autonomous_system_id_variable | default('not_defined') }}    msg=autonomous_system_id
    Should Be Equal Value Json Yaml           ${eigrp_feature}    data.authentication.type           {{ eigrp.authentication_type | default('not_defined') }}        {{ eigrp.authentication_type_variable | default('not_defined') }}        msg=authentication_type
    Should Be Equal Value Json Yaml           ${eigrp_feature}    data.authentication.authKey        {{ eigrp.hmac_authentication_key | default('not_defined') }}    {{ eigrp.hmac_authentication_key_variable | default('not_defined') }}    msg=hmac_authentication_key

    Should Be Equal Value Json List Length    ${eigrp_feature}    data.authentication.key            {{ eigrp.get('md5_keys', []) | length }}    msg=md5_keys length
{% if eigrp.get('md5_keys', []) | length > 0 %}
    Log     === MD5 Keys List ===
{% for md5_key in eigrp.md5_keys | default([]) %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.authentication.key[{{ loop.index0 }}].keyId      {{ md5_key.key_id | default('not_defined') }}      {{ md5_key.key_id_variable | default('not_defined') }}     msg=key_id
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Should Be Equal Value Json Yaml    ${eigrp_feature}    data.authentication.key[{{ loop.index0 }}].keystring    {{ md5_key.key_string | default('not_defined') }}    {{ md5_key.key_string_variable | default('not_defined') }}    msg=key_string

{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.helloInterval        {{ eigrp.hello_interval | default('not_defined') }}    {{ eigrp.hello_interval_variable | default('not_defined') }}    msg=hello_interval
    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.holdTime        {{ eigrp.hold_time | default('not_defined') }}    {{ eigrp.hold_time_variable | default('not_defined') }}    msg=hold_time

    Should Be Equal Value Json List Length    ${eigrp_feature}    data.addressFamily.network    {{ eigrp.get('networks', []) | length }}    msg=networks length
{% if eigrp.get('networks', []) | length > 0 %}
    Log     === Networks List ===
{% for network in eigrp.networks | default([]) %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.addressFamily.network[{{ loop.index0 }}].prefix.address      {{ network.network_address | default('not_defined') }}      {{ network.network_address_variable | default('not_defined') }}     msg=network_address
    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.addressFamily.network[{{ loop.index0 }}].prefix.mask         {{ network.subnet_mask | default('not_defined') }}    {{ network.subnet_mask_variable | default('not_defined') }}    msg=subnet_mask

{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${eigrp_feature}    data.addressFamily.redistribute    {{ eigrp.get('redistributes', []) | length }}    msg=redistributes length
{% if eigrp.get('redistributes', []) | length > 0 %}
    Log     === Redistributes List ===
{% for redistribute in eigrp.redistributes | default([]) %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].protocol      {{ redistribute.protocol | default('not_defined') }}      {{ redistribute.protocol_variable | default('not_defined') }}     msg=protocol
    # Redistribute Route policy
    Should Be Equal Referenced Object Name    ${eigrp_feature}    data.addressFamily.redistribute[{{ loop.index0 }}].routePolicy.refId.value    ${route_policies_res.json()}    {{ redistribute.route_policy | default('not_defined') }}    eigrp.redistribute.route_policy

{% endfor %}
{% endif %}

    Should Be Equal Value Json List Length    ${eigrp_feature}    data.afInterface    {{ eigrp.get('interfaces', []) | length }}    msg=interfaces length
{% if eigrp.get('interfaces', []) | length > 0 %}
    Log     === Interfaces List ===
{% for interface in eigrp.interfaces | default([]) %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.afInterface[{{ loop.index0 }}].name      {{ interface.name | default('not_defined') }}      {{ interface.name_variable | default('not_defined') }}     msg=name
    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.afInterface[{{ loop.index0 }}].shutdown      {{ interface.shutdown | default('not_defined') }}      {{ interface.shutdown_variable | default('not_defined') }}     msg=shutdown

    ${outer_loop_index}=    Set Variable    {{ loop.index0 }}
    Should Be Equal Value Json List Length    ${eigrp_feature}   data.afInterface[{{ loop.index0 }}].summaryAddress    {{ interface.summary_addresses | length }}    msg=summary_addresses length
{% for summary_address in interface.summary_addresses | default([]) %}

    Should Be Equal Value Json Yaml       ${eigrp_feature}     data.afInterface[${outer_loop_index}].summaryAddress[{{ loop.index0 }}].prefix.address          {{ summary_address.network_address | default("not_defined") }}         {{ summary_address.network_address_variable | default("not_defined") }}      msg=network_address
    Should Be Equal Value Json Yaml       ${eigrp_feature}     data.afInterface[${outer_loop_index}].summaryAddress[{{ loop.index0 }}].prefix.mask             {{ summary_address.subnet_mask | default("not_defined") }}            {{ summary_address.subnet_mask_variable | default("not_defined") }}         msg=subnet_mask

{% endfor %}

{% endfor %}
{% endif %}

    Should Be Equal Value Json Yaml    ${eigrp_feature}    data.tableMap.filter        {{ eigrp.filter | default('not_defined') }}    {{ eigrp.filter_variable | default('not_defined') }}    msg=filter
    # Route policy
    Should Be Equal Referenced Object Name    ${eigrp_feature}    data.tableMap.name.refId.value    ${route_policies_res.json()}    {{ eigrp.route_policy | default('not_defined') }}    eigrp.route_policy

{% endfor %}

{% endif %}

{% endfor %}

{% endif %}