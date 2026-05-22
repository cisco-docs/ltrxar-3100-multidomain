*** Settings ***
Library   pabot.PabotLib
Library   RequestsLibrary
Library   JMESPathLibrary
Library   Collections
Library   OperatingSystem
Library   String
Library   packaging.version
Library   myutils.py

*** Variables ***
&{login_json}=   j_username=%{SDWAN_USERNAME}   j_password=%{SDWAN_PASSWORD}
&{headers}=   content-type=application/x-www-form-urlencoded

*** Keywords ***
Get SDWAN Manager Token
   Create Session   login   %{SDWAN_URL}   verify=${False}   disable_warnings=1   headers=${headers}
   ${log_level}=   Set Log Level   NONE
   ${response}=   Wait Until Keyword Succeeds   6x   10s   POST On Session   login   /j_security_check   data=${login_json}
   Set Log Level   ${log_level}
   ${r_token}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   login   /dataservice/client/token
   ${cookie}=   Get from dictionary   ${response.headers}   set-cookie
   ${r_cookie}=   Split string   ${cookie}   separator=;
   Set Parallel Value For Key   manager_token   ${r_token.text}
   Set Parallel Value For Key   manager_cookie   ${r_cookie[0]}

Get SDWAN Manager Version
   ${response}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   sdwan_manager   /dataservice/system/device/controllers   params=model=vmanage
   ${r_version}=   Json Search String   ${response.json()}   data[0].version
   Set Parallel Value For Key   manager_version   ${r_version}

Login SDWAN Manager
   Run Only Once   Get SDWAN Manager Token
   ${manager_token}=   Get Parallel Value For Key   manager_token
   ${manager_cookie}=   Get Parallel Value For Key   manager_cookie
   ${m_headers}=   Create Dictionary   X-XSRF-TOKEN=${manager_token}   Cookie=${manager_cookie}   accept=application/json
   Create Session   sdwan_manager   %{SDWAN_URL}   headers=${m_headers}
   Run Only Once   Get SDWAN Manager Version

Logout SDWAN Manager
   ${manager_cookie}=   Get Parallel Value For Key   manager_cookie
   ${m_headers}=   Create Dictionary   Cookie=${manager_cookie}   accept=*/*
   ${manager_version}=   Get Parallel Value For Key   manager_version
   ${version_check}=   Evaluate   packaging.version.Version('${manager_version}') >= packaging.version.Version('20.12')
   IF   ${version_check}
       ${response}=   Wait Until Keyword Succeeds   6x   10s   POST On Session   sdwan_manager   /logout   headers=${m_headers}
   ELSE
       ${response}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   sdwan_manager   /logout   headers=${m_headers}
   END

GET On Session With Retry
   [Arguments]   ${session}   ${url}   ${params}=${None}   ${headers}=${None}
   [Documentation]   Wrapper for GET On Session with automatic retry (for example on 429 errors observed)
   ${result}=   Wait Until Keyword Succeeds   5x   2s   GET On Session   ${session}   ${url}   params=${params}   headers=${headers}
   RETURN   ${result}

Should Be Equal Value Json String
   [Arguments]   ${json}   ${jmes_path}   ${expected_value}=${EMPTY}   ${msg}=${EMPTY}   ${ignore_case}=${False}
   ${actual_value}=   Json Search String   ${json}   ${jmes_path}
   # Convert empty string to "not_defined" only when expected value is "not_defined"
   ${actual_value}=   Set Variable If   $actual_value == '' and $expected_value == 'not_defined'   not_defined   ${actual_value}
   Should Be Equal As Strings   ${expected_value}   ${actual_value}   values=False   ignore_case=${ignore_case}   msg=${msg} expected: '${expected_value}' and got: '${actual_value}'  

Should Be Equal Value Json List
   [Arguments]   ${json}   ${jmes_path}   ${expected_value}=${None}   ${msg}=${EMPTY}
   ${actual_value}=   Json Search List   ${json}   ${jmes_path}
   Lists Should Be Equal   ${expected_value}   ${actual_value}   ignore_order=True   values=False   msg=${msg} expected: '${expected_value}' and got: '${actual_value}'    

Should Be Equal Value Json List Length
   [Arguments]   ${json}   ${jmes_path}   ${expected_length}=${None}   ${msg}=${EMPTY}
   ${actual_value}=   Json Search List   ${json}   ${jmes_path}
   ${actual_length}=   Get Length   ${actual_value}
   Should Be Equal As Integers   ${expected_length}   ${actual_length}   values=False   msg=${msg} expected '${expected_length}' items and got: '${actual_length}' 

Convert String To List If Needed
   [Arguments]    ${value}
   ${is_list_string}=    Run Keyword And Return Status    Should Match Regexp    ${value}    ^\\[.*\\]$
   IF    $is_list_string and not isinstance($value, list)
      # Convert input value string to list
      ${value}=    Evaluate    json.loads(r'''${value}'''.replace("'", '"'))    modules=json
   END
   RETURN    ${value}

Extract Json List Value
   [Arguments]    ${json}    ${json_path}
   # Extract value from JSON using JMESPath
   ${json_value}=    Json Search List    ${json}    ${json_path}.vipValue
   ${length}=    Get Length    ${json_value}
   IF    ${length} == 0
      ${json_list}=    Set Variable    not_defined
   ELSE IF    ${length} > 1
      # Multiple values: ['val1', 'val2', 'val3'] -> return as is
      ${json_list}=    Set Variable    ${json_value}
   ELSE
      # Length is exactly 1 - check the single element
      IF    isinstance($json_value[0], list)
         # Single value that is itself a list (nested): extract it
         ${json_list}=    Set Variable    ${json_value[0]}
      ELSE IF    isinstance($json_value[0], str) and ',' in $json_value[0]
         # Single value that is a comma-separated string: split it
         ${json_list}=    Split String    ${json_value[0]}    separator=,
      ELSE
         # Single value that is already proper (string, int, etc): return as-is
         ${json_list}=    Set Variable    ${json_value}
      END
   END
   RETURN    ${json_list}

Extract Json String Value
   [Arguments]    ${json}    ${json_path}
   # Extract value from JSON using JMESPath
   ${json_value}=    Json Search List    ${json}    ${json_path}.vipValue
   # If its list with one element and data model is using string, extract this element from json list to string
   IF    len($json_value) == 1 and isinstance($json_value[0], list)
      ${json_value}=    Set Variable    ${json_value[0][0]}
   ELSE
      ${json_value}=    Set Variable If    ${json_value} == []    not_defined    ${json_value[0]}
   END
   RETURN    ${json_value}

Should Be Equal Value Json Yaml UX1
   [Arguments]    ${json}    ${json_path}    ${value}    ${var_value}    ${msg}
   ${vip_type}=    Json Search String    ${json}    ${json_path}.vipType
   IF    $vip_type == 'constant'
      # Verify global value
      ${value}=    Convert String To List If Needed    ${value}
      IF    isinstance($value, list)
         # Verify list value
         ${json_list}=    Extract Json List Value    ${json}    ${json_path}
         Lists Should Be Equal    ${json_list}    ${value}    ignore_order=True    values=False    msg=${msg} expected: '${value}' and got: '${json_list}'
      ELSE
         # Verify non-list value (int, str, bool)
         IF    $value in ["True", "False"]
            # Bool values represented by string needs to be converted to lowercase
            ${value}=    Set Variable    ${value.lower()}
         END
         # Extract value from JSON
         ${json_value}=    Extract Json String Value    ${json}    ${json_path}
         Should Be Equal As Strings    ${json_value}    ${value}    values=False    msg=${msg} expected: '${value}' and got: '${json_value}'
      END
   ELSE IF    $vip_type == 'variableName'
      # Verify variable value
      Should Be Equal Value Json String    ${json}    ${json_path}.vipVariableName    ${var_value}    msg=${msg}_variable
   ELSE
      # Verify default/ignore value
      Should Be Equal As Strings    not_defined    ${value}    msg=${msg} expected: '${value}' and got: 'not_defined'
   END

Should Be Equal Value Json Yaml
   [Arguments]    ${json}    ${json_path}    ${value}    ${var_value}    ${msg}
   ${opt_type}=    Json Search String    ${json}    ${json_path}.optionType
   IF    $opt_type == 'global'
      # Convert string representation of list to actual list if needed
      ${value}=    Convert String To List If Needed    ${value}
      ${type_check}=    Evaluate    type($value).__name__
      IF    '${type_check}' == 'list'
         ${actual_list}=    Json Search List    ${json}    ${json_path}.value
         ${actual_list}=    Evaluate    [str(x) for x in $actual_list]
         ${expected_list}=    Evaluate    [str(x) for x in $value]
         Lists Should Be Equal    ${expected_list}    ${actual_list}    ignore_order=True    msg=${msg} expected: '${value}' and got: '${actual_list}'
      ELSE
         ${actual}=    Json Search String    ${json}    ${json_path}.value
         # Convert empty string to "not_defined" only when expected value is "not_defined"
         ${actual}=    Set Variable If    $actual == '' and $value == 'not_defined'    not_defined    ${actual}
         Should Be Equal As Strings    ${value}    ${actual}    msg=${msg} expected: '${value}' and got: '${actual}'
      END
   ELSE IF    $opt_type == 'variable'
      ${actual}=    Json Search String    ${json}    ${json_path}.value
      # In JSON API payload the variables are in format {% raw %}"{{var_name}}"{% endraw %}. We need to extract "var_name"
      ${cleaned}=    Evaluate    '${actual}'.strip('{}')
      # Convert empty string to "not_defined" only when expected value is "not_defined"
      ${cleaned}=    Set Variable If    '${cleaned}' == '' and '${var_value}' == 'not_defined'    not_defined    ${cleaned}
      Should Be Equal As Strings    ${var_value}    ${cleaned}    msg=${msg}_variable expected: '${var_value}' and got: '${cleaned}'
   ELSE
      Should Be Equal As Strings    not_defined    ${value}    msg=${msg} expected: '${value}' and got: 'not_defined'
      Should Be Equal As Strings    not_defined    ${var_value}    msg=${msg}_variable expected: '${var_value}' and got: 'not_defined'
   END

# This keyword is same as "Should Be Equal Value Json String" but it normalizes the special characters and spaces for robot evaluation
Should Be Equal Value Json Special_String
   [Arguments]   ${json}   ${jmes_path}   ${expected_value}=${EMPTY}   ${msg}=${EMPTY}
   ${actual_value}=   Json Search String   ${json}   ${jmes_path}
   ${actual_value}=   Set Variable If   $actual_value == '' and $expected_value == 'not_defined'   not_defined   ${actual_value}
   ${actual_value}=   normalize escapes spaces    text=${actual_value}
   ${expected_value}=   normalize escapes spaces    text=${expected_value}
   Should Be Equal As Strings   ${expected_value}   ${actual_value}   msg=${msg} expected: '${expected_value}' and got: '${actual_value}'

# This keyword verifies that a UX 2.0 referenced object (by refId) has the expected name
Should Be Equal Referenced Object Name
   [Arguments]    ${json}    ${refid_path}    ${reference_list_json}    ${expected_value}    ${msg}
   ${refid}=    Json Search String    ${json}    ${refid_path}
   ${actual_name}=    Json Search String    ${reference_list_json}    data[?parcelId=='${refid}'] | [0].payload.name
   # Convert empty string to "not_defined" only when expected value is "not_defined"
   ${actual_name}=    Set Variable If    $actual_name == '' and $expected_value == 'not_defined'    not_defined    ${actual_name}
   Should Be Equal As Strings    ${expected_value}    ${actual_name}    msg=${msg} expected: '${expected_value}' and got: '${actual_name}'
