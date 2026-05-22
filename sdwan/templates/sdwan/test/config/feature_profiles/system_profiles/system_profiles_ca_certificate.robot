*** Settings ***
Documentation   Verify System Feature Profile Configuration CA Certificate
Name            System Profiles CA Certificate
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_profiles     system_profiles   ca_certificate
Resource        ../../../sdwan_common.resource

{% if sdwan.feature_profiles is defined and sdwan.feature_profiles.system_profiles is defined %}
{% set profile_ca_cert_list = [] %}
{% for profile in sdwan.feature_profiles.system_profiles %}
 {% if profile.ca_certificate is defined %}
  {% set _ = profile_ca_cert_list.append(profile.name) %}
 {% endif %}
{% endfor %}

{% if profile_ca_cert_list != [] %}

*** Test Cases ***
Get System Profiles
    ${r}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system
    Set Suite Variable    ${r}

{% for profile in sdwan.feature_profiles.system_profiles | default([]) %}
{% if profile.ca_certificate is defined %}

Verify Feature Profiles System Profiles {{ profile.name }} CA Certificate Feature {{ profile.ca_certificate.name }}
    ${profile}=    Json Search    ${r.json()}    [?profileName=='{{ profile.name }}'] | [0]
    Run Keyword If    $profile is None    Fail    Feature Profile '{{profile.name}}' should be present on the Manager
    ${profile_id}=    Json Search String    ${profile}    profileId
    ${system_api_res}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/
    ${system_ca_cert_id}=    Json Search    ${system_api_res.json()}    associatedProfileParcels[?parcelType=='ca-cert'] | [0].parcelId
    Run Keyword If    $system_ca_cert_id is None    Fail    Feature '{{ profile.ca_certificate.name }}' expected to be configured within the system profile '{{profile.name}}' on the Manager
    Set Suite Variable    ${system_ca_cert_id}

    ${system_ca_certificate}=    GET On Session With Retry    sdwan_manager    /dataservice/v1/feature-profile/sdwan/system/${profile_id}/ca-cert/${system_ca_cert_id}
    Set Suite Variable    ${system_ca_certificate}
   
    Should Be Equal Value Json String    ${system_ca_certificate.json()}    payload.name    {{ profile.ca_certificate.name }}    msg=name
    Should Be Equal Value Json String    ${system_ca_certificate.json()}    payload.description    {{ profile.ca_certificate.description | default('') }}    msg=description

{% for certificate in profile.ca_certificate.certificates | default([]) %}
    Should Be Equal Value Json String    ${system_ca_certificate.json()}    payload.data.certificates[?trustPointName.value=='{{ certificate.trustpoint_name }}'] | [0].certificateUUID.value    {{ certificate.certificate_id }}    msg=Fails if certificate ID mismatches for trustpoint {{ certificate.trustpoint_name }}
{% endfor %}

{% endif %}
{% endfor %}

{% endif %}

{% endif %}