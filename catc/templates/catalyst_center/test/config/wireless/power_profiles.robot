*** Settings ***
Documentation     Verify Wireless Power Profiles in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   wireless   power_profiles

*** Test Cases ***

Get Wireless Power Profiles
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/wirelessSettings/powerProfiles
    Log     Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for power_profile in catalyst_center.wireless.power_profiles | default([]) %}
Verify Power Profile {{ power_profile.name }}
    ${profile_data}=   Get Value From Json   ${r.json()}   $.response[?(@.profileName=='{{ power_profile.name }}')]
    Run Keyword If   not ${profile_data}   Fail   Power Profile '{{ power_profile.name }}' not found in API response.

    ${profile_entry}=   Set Variable   ${profile_data}[0]
    Log To Console   Extracted Power Profile Entry: ${profile_entry}

    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.profileName   {{ power_profile.name }}

{% if power_profile.description is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${profile_entry}   $.description   {{ power_profile.description }}
{% endif %}

{% if power_profile.rules is defined %}
    ${rules}=   Get Value From Json   ${profile_entry}   $.rules
    ${rules_list}=   Set Variable   ${rules}[0]
    ${rules_count}=   Get Length   ${rules_list}
    Should Be Equal As Integers   ${rules_count}   {{ power_profile.rules | length }}

{% for rule in power_profile.rules %}
    ${rule_entry}=   Set Variable   ${rules_list}[{{ loop.index0 }}]
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rule_entry}   $.interfaceType   {{ rule.interface_type }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rule_entry}   $.interfaceId   {{ rule.interface_id }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rule_entry}   $.parameterType   {{ rule.parameter_type }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${rule_entry}   $.parameterValue   {{ rule.parameter_value }}
{% endfor %}
{% endif %}

{% endfor %}
