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
    [Documentation]    Valida o status code e opcionalmente uma mensagem de erro.
    [Arguments]    ${response}    ${expected_status_code}    ${expected_error_message}=${None}

    # 1. Valida o Status Code
    Should Be Equal As Strings    ${response.status_code}    ${expected_status_code}

    # 2. Valida a mensagem de erro (se fornecida)
    ${body}=    Set Variable    ${response.json()}
    Run Keyword If    '${expected_error_message}' != '${None}' and 'message' in ${body}
    ...    Should Be Equal As Strings    ${body['message']}    ${expected_error_message}

    # 3. (Opcional) Poderia validar o campo 'success' como False
    Run Keyword If    'success' in ${body}    Should Be Equal    ${body['success']}    ${False}