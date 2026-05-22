*** Settings ***
Documentation     Verify Site Hierarchy Floors
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   site_hierarchy   sites   floors   site_specific

*** Test Cases ***

{% for floor in catalyst_center.sites.floors | default([]) %}
Verify Floor {{ floor.parent_name }}/{{ floor.name }}       Set Log Level    Debug

    # Dynamically construct the nameHierarchy without a leading slash if floor.parent_name is empty
    ${nameHierarchy}=   Evaluate   '{{ floor.parent_name }}/{{ floor.name }}' if '{{ floor.parent_name }}' else '{{ floor.name }}'

    # Check if this site should be skipped based on MANAGED_SITES
    ${should_skip}=   Should Skip Site Validation   ${nameHierarchy}
    Pass Execution If   ${should_skip}   Floor ${nameHierarchy} not managed by this deployment state - skipping validation

    ${sites}=   Get Cached Sites Data
    # Get floor ID from sites data
    ${floor_id_list}=   Get Value From Json   ${sites.json()}   $.response[?(@.nameHierarchy=='${nameHierarchy}')].id
    Run Keyword If   not ${floor_id_list}   Fail   Floor ${nameHierarchy} not found in Catalyst Center - deployment issue
    ${floor_id}=   Set Variable   ${floor_id_list}[0]
    Log To Console   Floor ID for ${nameHierarchy}: ${floor_id}

    # Get floor details with units parameter (if specified in data model)
    {% if floor.units_of_measure is defined %}
    ${r}=   GET With Rate Limit Retry   /dna/intent/api/v2/floors/${floor_id}?_unitsOfMeasure={{ floor.units_of_measure | default(defaults.catalyst_center.sites.floors.units_of_measure) }}
    {% else %}
    ${r}=   GET With Rate Limit Retry   /dna/intent/api/v2/floors/${floor_id}
    {% endif %}
    Log To Console   Floor API Response: ${r.json()}
    ${floor_entry}=   Get From Dictionary   ${r.json()}   response

    # Validate basic attributes
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.name   {{ floor.name }}
    Run Keyword And Continue On Failure   Should Be Equal Value Json Number   ${r.json()}   $.response.floorNumber   {{ floor.floor_number | default(defaults.catalyst_center.sites.floors.floor_number) }}

    # Validate dimensions (if specified in data model) with precision tolerance for floating point errors
    {% if floor.height is defined %}
    ${height_value}=   Get Value From Json   ${r.json()}   $.response.height
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${height_value}[0]   {{ floor.height | default(defaults.catalyst_center.sites.floors.height) }}   precision=3
    {% endif %}
    {% if floor.length is defined %}
    ${length_value}=   Get Value From Json   ${r.json()}   $.response.length
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${length_value}[0]   {{ floor.length | default(defaults.catalyst_center.sites.floors.length) }}   precision=3
    {% endif %}
    {% if floor.width is defined %}
    ${width_value}=   Get Value From Json   ${r.json()}   $.response.width
    Run Keyword And Continue On Failure   Should Be Equal As Numbers   ${width_value}[0]   {{ floor.width | default(defaults.catalyst_center.sites.floors.width) }}   precision=3
    {% endif %}

    # Validate units of measure
    {% if floor.units_of_measure is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.unitsOfMeasure   {{ floor.units_of_measure | default(defaults.catalyst_center.sites.floors.units_of_measure) }}
    {% endif %}

    # Validate RF model
    {% if floor.rf_model is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${r.json()}   $.response.rfModel   {{ floor.rf_model | default(defaults.catalyst_center.sites.floors.rf_model) }}
    {% endif %}

    # Validate parent site exists in cached sites data
    ${parent_id}=   Get Value From Json   ${r.json()}   $.response.parentId
    ${parent_site_data}=   Get Value From Json   ${sites.json()}   $.response[?(@.id=='${parent_id}[0]')]
    # Use nameHierarchy if available, otherwise use name (for Global site)
    ${parent_hierarchy}=   Run Keyword And Return Status   Dictionary Should Contain Key   ${parent_site_data}[0]   nameHierarchy
    ${expected_parent}=   Set Variable   {{ floor.parent_name }}
    Run Keyword If   ${parent_site_data} and ${parent_hierarchy}   Should Be Equal As Strings   ${parent_site_data}[0][nameHierarchy]   ${expected_parent}
    Run Keyword If   ${parent_site_data} and not ${parent_hierarchy}   Should Be Equal As Strings   ${parent_site_data}[0][name]   ${expected_parent}
{% endfor %}
