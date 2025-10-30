*** Settings ***
Documentation    Keywords reutilizáveis para validações comuns de API.


Resource        ../common.resource

*** Keywords ***
Validate Successful API Response
    [Documentation]    Valida o status code, o schema e o campo 'success'.
    [Arguments]    ${response}    ${expected_status_code}    ${schema_file}

    ${body}=    Set Variable    ${response.json()}
    ${stringified_body}    Convert Json To String    ${body}
    # 1. Valida o Status Code
    Should Be Equal As Strings    ${response.status_code}    ${expected_status_code}

    # 2. Valida o campo 'success' (se existir)
        
    Run Keyword If    'success' in ${body}    Should Be Equal    ${body['success']}    ${True}

    # 3. Valida o Schema JSON
    Validate Json
    ...    ${schema_file}
    ...    ${body}

Validate Error API Response
    [Documentation]    Validates status code, optionally a top-level message,
    ...    optionally nested field errors, and optionally a schema.
    [Arguments]    ${response}
    ...            ${expected_status_code}
    ...            ${expected_error_message}=${EMPTY} 
    ...            ${expected_errors_dict}=${EMPTY}
    ...            ${schema_file}=${EMPTY}        # Schema file path

    # 1. Valida o Status Code
    Should Be Equal As Strings    ${response.status_code}    ${expected_status_code}

    ${body}=    Set Variable    ${response.json()}

    # 2. Valida a mensagem de erro de nível superior (se fornecida)
    Run Keyword If    '${expected_error_message}' != '${EMPTY}' and 'message' in ${body}
    ...    Should Be Equal As Strings    ${body['message']}    ${expected_error_message}

    # 3. Valida erros de campo aninhados (NOVO!)
    Run Keyword And Ignore Error
    ...    Run Keyword If    '${expected_errors_dict}' != '${EMPTY}' and 'errors' in ${body}
    ...    Dictionary Should Contain Sub Dictionary    ${body['errors']}    ${expected_errors_dict}

    # 4. Valida o schema JSON (se fornecido)
    Run Keyword If    '${schema_file}' != '${EMPTY}'
    ...    Validate Json    
    ...    ${schema_file}
    ...    ${body}

    # 5. Valida 'success' como False (se existir)
    Run Keyword If    'success' in ${body}    
    ...    Should Not Be True    ${body['success']}