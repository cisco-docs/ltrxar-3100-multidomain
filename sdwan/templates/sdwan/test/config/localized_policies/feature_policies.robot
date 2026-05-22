*** Settings ***
Documentation   Verify Feature Policies
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    localized_policies
Resource        ../../sdwan_common.resource

{% if sdwan.localized_policies.feature_policies is defined %}

*** Test Cases ***
Get Feature Policies
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/vedge
    Set Suite Variable    ${r}

{% for feature_policy in sdwan.localized_policies.feature_policies | default([]) %}

Verify Localized Policies Feature Policies {{ feature_policy.name }}
    ${policy_id}=    Json Search String    ${r.json()}    data[?policyName=='{{feature_policy.name }}'] | [0].policyId
    ${r_id}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/vedge/definition/${policy_id}

    Should Be Equal Value Json String    ${r_id.json()}    policyName    {{ feature_policy.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    policyDescription    {{ feature_policy.description | normalize_special_string }}    msg=description
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.implicitAclLogging    {{ feature_policy.implicit_acl_logging | default(defaults.sdwan.localized_policies.feature_policies.implicit_acl_logging) }}    msg=implicit acl logging
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.appVisibility    {{ feature_policy.ipv4_application_visibility | default(defaults.sdwan.localized_policies.feature_policies.ipv4_application_visibility) }}    msg=ipv4 application visibility
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.flowVisibility    {{ feature_policy.ipv4_flow_visibility | default(defaults.sdwan.localized_policies.feature_policies.ipv4_flow_visibility) }}    msg=ipv4 flow visibility
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.ipVisibilityCacheEntries    {{ feature_policy.ipv4_visibility_cache_entries | default("not_defined") }}    msg=ipv4 visibility cache entries
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.appVisibilityIPv6    {{ feature_policy.ipv6_application_visibility | default(defaults.sdwan.localized_policies.feature_policies.ipv6_application_visibility) }}    msg=ipv6 application visibility
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.flowVisibilityIPv6    {{ feature_policy.ipv6_flow_visibility | default(defaults.sdwan.localized_policies.feature_policies.ipv6_flow_visibility) }}    msg=ipv6 flow visibility
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.ipV6VisibilityCacheEntries    {{ feature_policy.ipv6_visibility_cache_entries | default("not_defined") }}    msg=ipv6 visibility cache entries
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.logFrequency    {{ feature_policy.log_frequency | default("not_defined") }}    msg=log frequency
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.cloudQos    {{ feature_policy.cloud_qos | default(defaults.sdwan.localized_policies.feature_policies.cloud_qos) }}    msg=cloud qos
    Should Be Equal Value Json String    ${r_id.json()}    policyDefinition.settings.cloudQosServiceSide    {{ feature_policy.cloud_qos_service_side | default(defaults.sdwan.localized_policies.feature_policies.cloud_qos_service_side) }}    msg=cloud qos service side

    ${temp_res_list}=    Create List
    ${route_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='vedgeRoute'].definitionId
    ${route_id_length}=    Get Length    ${route_id}
    Should Be Equal As Integers    ${route_id_length}    {{ feature_policy.definitions.route_policies | default([]) | length }}    msg=route policies
    ${exp_route_policies}=    Create List    {{ feature_policy.definitions.route_policies | default([]) | join('   ') }}

    FOR    ${id}    IN    @{route_id}
        ${route_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/vedgeroute/${id}
        ${route_name}=    Json Search String    ${route_det.json()}    name
        Append To List    ${temp_res_list}    ${route_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_route_policies}    ignore_order=True    msg=route policies

    ${temp_res_list}=    Create List
    ${acl_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='acl'].definitionId
    ${acl_id_length}=    Get Length    ${acl_id}
    Should Be Equal As Integers    ${acl_id_length}    {{ feature_policy.definitions.ipv4_access_control_lists | default([]) | length }}    msg=ipv4 access control lists
    ${exp_acl_list}=    Create List    {{ feature_policy.definitions.ipv4_access_control_lists | default([]) | join('   ') }}

    FOR    ${id}    IN    @{acl_id}
        ${acl_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/acl/${id}
        ${acl_name}=    Json Search String    ${acl_det.json()}    name
        Append To List    ${temp_res_list}    ${acl_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_acl_list}    ignore_order=True    msg=ipv4 access control lists

    ${temp_res_list}=    Create List
    ${device_acl_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='deviceAccessPolicy'].definitionId
    ${device_acl_id_length}=    Get Length    ${device_acl_id}
    Should Be Equal As Integers    ${device_acl_id_length}    {{ feature_policy.definitions.ipv4_device_access_policies | default([]) | length }}    msg=ipv4 device access policies
    ${exp_device_acl_list}=    Create List    {{ feature_policy.definitions.ipv4_device_access_policies | default([]) | join('   ') }}

    FOR    ${id}    IN    @{device_acl_id}
        ${device_acl_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/deviceaccesspolicy/${id}
        ${device_acl_name}=    Json Search String    ${device_acl_det.json()}    name
        Append To List    ${temp_res_list}    ${device_acl_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_device_acl_list}    ignore_order=True    msg=ipv4 device access policies

    ${temp_res_list}=    Create List
    ${ipv6_acl_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='aclv6'].definitionId
    ${ipv6_acl_id_length}=    Get Length    ${ipv6_acl_id}
    Should Be Equal As Integers    ${ipv6_acl_id_length}    {{ feature_policy.definitions.ipv6_access_control_lists | default([]) | length }}    msg=ipv6 access control lists
    ${exp_ipv6_acl_list}=    Create List    {{ feature_policy.definitions.ipv6_access_control_lists | default([]) | join('   ') }}

    FOR    ${id}    IN    @{ipv6_acl_id}
        ${ipv6_acl_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/aclv6/${id}
        ${ipv6_acl_name}=    Json Search String    ${ipv6_acl_det.json()}    name
        Append To List    ${temp_res_list}    ${ipv6_acl_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_ipv6_acl_list}    ignore_order=True    msg=ipv6 access control lists

    ${temp_res_list}=    Create List
    ${ipv6_device_acl_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='deviceAccessPolicyv6'].definitionId
    ${ipv6_device_acl_id_length}=    Get Length    ${ipv6_device_acl_id}
    Should Be Equal As Integers    ${ipv6_device_acl_id_length}    {{ feature_policy.definitions.ipv6_device_access_policies | default([]) | length }}    msg=ipv6 device access policies
    ${exp_ipv6_device_acl_list}=    Create List    {{ feature_policy.definitions.ipv6_device_access_policies | default([]) | join('   ') }}

    FOR    ${id}    IN    @{ipv6_device_acl_id}
        ${ipv6_device_acl_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/deviceaccesspolicyv6/${id}
        ${ipv6_device_acl_name}=    Json Search String    ${ipv6_device_acl_det.json()}    name
        Append To List    ${temp_res_list}    ${ipv6_device_acl_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_ipv6_device_acl_list}    ignore_order=True    msg=ipv6 device access policies

    ${temp_res_list}=    Create List
    ${rewrite_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='rewriteRule'].definitionId
    ${rewrite_id_length}=    Get Length    ${rewrite_id}
    Should Be Equal As Integers    ${rewrite_id_length}    {{ feature_policy.definitions.rewrite_rules | default([]) | length }}    msg=rewrite rules
    ${exp_rewrite_list}=    Create List    {{ feature_policy.definitions.rewrite_rules | default([]) | join('   ') }}

    FOR    ${id}    IN    @{rewrite_id}
        ${rewrite_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/rewriterule/${id}
        ${rewrite_name}=    Json Search String    ${rewrite_det.json()}    name
        Append To List    ${temp_res_list}    ${rewrite_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_rewrite_list}    ignore_order=True    msg=rewrite rules

    ${temp_res_list}=    Create List
    ${qos_id}=    Json Search List    ${r_id.json()}    policyDefinition.assembly[?type=='qosMap'].definitionId
    ${qos_id_length}=    Get Length    ${qos_id}
    Should Be Equal As Integers    ${qos_id_length}    {{ feature_policy.definitions.qos_maps | default([]) | length }}    msg=qos maps
    ${exp_qos_list}=    Create List    {{ feature_policy.definitions.qos_maps | default([]) | join('   ') }}

    FOR    ${id}    IN    @{qos_id}
        ${qos_det}=    GET On Session With Retry    sdwan_manager    /dataservice/template/policy/definition/qosmap/${id}
        ${qos_name}=    Json Search String    ${qos_det.json()}    name
        Append To List    ${temp_res_list}    ${qos_name}
    END
    Lists Should Be Equal    ${temp_res_list}    ${exp_qos_list}    ignore_order=True    msg=qos maps

{% endfor %}

{% endif %}
