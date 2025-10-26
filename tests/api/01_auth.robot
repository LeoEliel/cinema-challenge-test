*** Settings ***
Documentation    Suíte de testes de API para a feature de Autenticação.
...              Cobre os casos de teste da US-AUTH-001 (Registro).
...              Testes de API são marcados com a tag 'API'.
...              --kz
...              Dado que eu possuo dados válidos de um novo usuário (nome, e-mail único, senha)
...              Quando eu envio uma requisição POST para o endpoint "/auth/register" com esses dados
...              Então a resposta deve ter o status code 201
...              E o corpo da resposta deve conter os dados do usuário criado (sem a senha)

Resource    ../../resources/common.resource 

Test Setup       API Test Setup
Test Teardown     API Test Teardown

*** Test Cases ***
CTC-001_API (API): Registro de novo usuário com sucesso pela API
    [Tags]    API    Smoke    US-AUTH-001    
        
    ${fixture}        Get Fixture From Collection   users    valid_user_register
    ${endpoint}            Set Variable    /auth/register
    
    Set Global Variable    ${CLEANUP_EMAIL}    ${fixture}[email]

    # 3. Registra o usuário
    ${response}=        POST On Session    
    ...    alias=api
    ...    url=${endpoint}
    ...    json=${fixture}

    # 4. Valida
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_file=users_valid_user_register.schema.json

    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body}[data][name]      ${fixture}[name]
    Should Be Equal As Strings    ${body}[data][email]     ${fixture}[email]