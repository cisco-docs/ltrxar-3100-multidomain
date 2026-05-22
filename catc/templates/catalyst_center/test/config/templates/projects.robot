*** Settings ***
Documentation     Verify Template Projects in Catalyst Center
Suite Setup       Login CatalystCenter
Resource          ../../catalyst_center_common.resource
Default Tags      config   catalyst_center   templates   projects

*** Test Cases ***

Get Template Projects
    ${r}=   GET On Session   CatalystCenter_Session   /dna/intent/api/v1/template-programmer/template
    Log   Response Status Code: ${r.status_code}
    Log To Console   API Response: ${r.json()}
    Set Suite Variable   ${r}

{% for project in catalyst_center.templates.projects | default([]) %}
Verify Project {{ project.name }}

    # Validate that the project exists in the API response
    ${project_data}=   Get Value From Json   ${r.json()}   $[?(@.projectName=='{{ project.name }}')]
    Run Keyword If   not ${project_data}   Fail   Project {{ project.name }} not found in API response.

    # Validate the project's templates
    {% for template in project.dayn_templates | default([]) %}
    ${template_data}=   Evaluate   [t for t in $r.json() if t.get('name') == '{{ template.name }}' and t.get('projectName') == '{{ project.name }}']
    Run Keyword If   not ${template_data}   Fail   Template {{ template.name }} not found in API response for project {{ project.name }}.

    # Call the reusable keyword to verify the template
    ${device_types}=   Get Value From Json   {{ template.device_types }}   $
    Verify Template   ${template_data}   {{ template }}
    {% endfor %}
{% endfor %}

*** Keywords ***

Verify Template
    [Arguments]   ${template_data}   ${template_source}

    # Extract the first element of the template_data list
    ${template}=   Set Variable   ${template_data}[0]
    ${parsed_template}=   Evaluate   eval("""${template_source}""")
    ${version_info}=   Set Variable   ${template['versionsInfo'][0]}

    # Validate template attributes
    # Check if description exists before validating it
    ${has_description}=   Evaluate   'description' in ${version_info} and 'description' in ${parsed_template}
    IF   ${has_description}
        Should Be Equal As Strings   ${version_info['description']}  ${parsed_template['description']}
    END
    Should Be Equal As Strings   ${template['softwareType']}  ${parsed_template['software_type']}

    # Validate template device types
    ${device_types}=   Evaluate   eval("""${parsed_template['device_types']}""")
    ${dev_types}=   Set Variable   ${template['deviceTypes']}
    FOR   ${device_type}   IN   @{device_types}
        ${filtered_by_family}=   Get Value From Json   ${dev_types}   $[?(@.productFamily=='${device_type["product_family"]}')]

        # Check if product_series exists before filtering by it
        ${has_product_series}=   Evaluate   'product_series' in ${device_type}
        IF   ${has_product_series}
            ${device_type_data}=   Get Value From Json   ${filtered_by_family}   $[?(@.productSeries=='${device_type["product_series"]}')]
            Run Keyword If   not ${device_type_data}   Fail   Device type ${device_type["product_family"]} / ${device_type["product_series"]} not found for template.
        ELSE
            # If no product_series specified, just validate product_family exists
            Run Keyword If   not ${filtered_by_family}   Fail   Device type ${device_type["product_family"]} not found for template.
        END
    END

    # Validate template tags if defined in data model
    ${has_tags}=   Evaluate   'tags' in ${parsed_template} and len(${parsed_template}.get('tags', [])) > 0
    IF   ${has_tags}
        # Get tags from the template (already available in list API response)
        ${api_tags}=   Set Variable   ${template.get('tags', [])}
        ${api_tags_count}=   Get Length   ${api_tags}

        # Validate each expected tag exists in API response
        ${expected_tags}=   Set Variable   ${parsed_template['tags']}
        Run Keyword If   ${api_tags_count} == 0   Fail   Expected tags ${expected_tags} but no tags found in API response

        FOR   ${expected_tag}   IN   @{expected_tags}
            ${tag_found}=   Set Variable   ${False}
            FOR   ${api_tag}   IN   @{api_tags}
                ${tag_name}=   Get From Dictionary   ${api_tag}   name
                ${match}=   Evaluate   '${tag_name}' == '${expected_tag}'
                IF   ${match}
                    ${tag_found}=   Set Variable   ${True}
                END
            END
            Run Keyword If   not ${tag_found}   Fail   Tag '${expected_tag}' not found in template tags. API tags: ${api_tags}
        END
    END
