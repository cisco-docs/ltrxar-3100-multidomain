*** Settings ***
Documentation   Verify Site Hierarchy Areas
Suite Setup     Login CatalystCenter
Resource        ../../catalyst_center_common.resource
Default Tags    config   catalyst_center   site_hierarchy   sites   areas   site_specific

*** Test Cases ***

Check Areas Configuration in Data Model
    ${has_areas}=   Evaluate   {{ 'True' if catalyst_center.sites is defined and catalyst_center.sites.areas is defined and catalyst_center.sites.areas | length > 0 else 'False' }}
    Pass Execution If   not ${has_areas}   No areas configured in data model, skipping area tests

{% for area in catalyst_center.sites.areas | default([]) %}
{% if area.name != "Global" %}
Verify Area {{ area.parent_name | default(defaults.catalyst_center.sites.areas.parent_name) }}/{{ area.name }}
    # Dynamically construct the nameHierarchy without a leading slash if area.parent_name is empty
    ${nameHierarchy}=   Evaluate   '{{ area.parent_name | default(defaults.catalyst_center.sites.areas.parent_name) }}/{{ area.name }}' if '{{ area.parent_name | default(defaults.catalyst_center.sites.areas.parent_name) }}' else '{{ area.name }}'

    # Check if this site should be skipped based on MANAGED_SITES
    ${should_skip}=   Should Skip Site Validation   ${nameHierarchy}
    Pass Execution If   ${should_skip}   Area ${nameHierarchy} not managed by this deployment state - skipping validation

    ${r}=   Get Cached Sites Data
    Log To Console   Looking for area with nameHierarchy: ${nameHierarchy}

    # Check if area exists in API response
    ${area_data}=   Get Value From Json   ${r.json()}   $.response[?(@.nameHierarchy=='${nameHierarchy}')]
    ${area_exists}=   Evaluate   len(${area_data}) > 0
    Run Keyword If   not ${area_exists}   Fail   Area ${nameHierarchy} not found in Catalyst Center - deployment issue
    
    Should Be Equal Value Json String   ${r.json()}   $.response[?(@.nameHierarchy=='${nameHierarchy}')].name  {{ area.name }}
    ${parent_id}=   Get Value From Json   ${r.json()}   $.response[?(@.nameHierarchy=='${nameHierarchy}')].parentId
    
    Run Keyword If   not ${parent_id} or len(${parent_id}) == 0   Pass Execution   Skipping further steps as parent_id is empty

    # Validate parent site exists in cached sites data
    ${parent_site_data}=   Get Value From Json   ${r.json()}   $.response[?(@.id=='${parent_id}[0]')]
    # Use nameHierarchy if available, otherwise use name (for Global site)
    ${parent_hierarchy}=   Run Keyword And Return Status   Dictionary Should Contain Key   ${parent_site_data}[0]   nameHierarchy
    ${expected_parent}=   Set Variable   {{ area.parent_name | default(defaults.catalyst_center.sites.areas.parent_name) }}
    Run Keyword If   ${parent_site_data} and ${parent_hierarchy}   Should Be Equal As Strings   ${parent_site_data}[0][nameHierarchy]   ${expected_parent}
    Run Keyword If   ${parent_site_data} and not ${parent_hierarchy}   Should Be Equal As Strings   ${parent_site_data}[0][name]   ${expected_parent}
{% endif %}
{% endfor %}
