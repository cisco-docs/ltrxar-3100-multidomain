*** Settings ***
Documentation     Verify Template Tags in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   templates   tags

*** Test Cases ***

{% if catalyst_center.templates is defined and catalyst_center.templates.tags is defined and catalyst_center.templates.tags | length > 0 %}
Get Template Tags
    ${r}=   GET On Session   CatalystCenter_Session   url=/dna/intent/api/v1/tag
    Log   Response Status Code: ${r.status_code}
    Log To Console   Tags API Response: ${r.json()}
    Set Suite Variable   ${r}
{% endif %}

{% for tag in catalyst_center.templates.tags | default([]) %}
Verify Tag {{ tag.name }}
    # Validate that the tag exists in the API response
    ${tag_data}=   Get Value From Json   ${r.json()}   $.response[?(@.name=='{{ tag.name }}')]
    Run Keyword If   not ${tag_data}   Fail   Tag {{ tag.name }} not found in API response.

    # Extract the first matching tag from the API response
    ${tag_entry}=   Set Variable   ${tag_data}[0]
    Log To Console   Extracted Tag Entry: ${tag_entry}

    # Validate tag name
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.name   {{ tag.name }}

    # Validate tag description if defined
    {% if tag.description is defined %}
    Run Keyword And Continue On Failure   Should Be Equal Value Json String   ${tag_entry}   $.description   {{ tag.description }}
    {% endif %}

{% endfor %}
