*** Settings ***
Documentation    Suíte de testes de API para a feature de Autenticação.
...              Cobre os casos de teste da US-AUTH-001 (Registro).
...              Testes de API são marcados com a tag 'API'.

Resource    ../../resources/common.resource 

Test Setup       API Test Setup
Test Teardown     API Test Teardown    ${CLEANUP_EMAIL}

*** Test Cases ***
CTC-001_API (API): Registro de novo usuário com sucesso pela API
    [Tags]    API    Smoke    US-AUTH-001    CTC-001_API
    [Documentation]
...              Dado que eu possuo dados válidos de um novo usuário (nome, e-mail único, senha)
...              Quando eu envio uma requisição POST para o endpoint "/auth/register" com esses dados
...              Então a resposta deve ter o status code 201
...              E o corpo da resposta deve conter os dados do usuário criado (sem a senha)

    ${fixture}        Get Fixture From Collection   users    valid_user_register
    ${endpoint}            Set Variable    /auth/register
    
    Set Test Variable    ${CLEANUP_EMAIL}    ${fixture}[email]
    
    # Garante que usuário a ser inserido não existe
    Remove User And Related Data    ${CLEANUP_EMAIL}

    # 3. Registra o usuário
    ${response}    Register User    ${fixture}

    # 4. Valida
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_file=users_valid_user_register.schema.json

    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body}[data][name]      ${fixture}[name]
    Should Be Equal As Strings    ${body}[data][email]     ${fixture}[email]

CTC-002_API (API): Tentativa de registro com e-mail já existente
    [Tags]    API    Negative    US-AUTH-001    CTC-002_API
    [Documentation]
    ...              Dado que o e-mail "duplicado.static@test.cinema.com" já está cadastrado
    ...              Quando eu envio uma requisição POST para "/auth/register" com o mesmo e-mail
    ...              Então a resposta deve ter o status code 400 (ou 409)
    ...              E o corpo da resposta deve conter a mensagem "User already exists"

    # Carrega os dados do fixture para a *tentativa* de registro
    ${fixture}        Get Fixture From Collection   users    user_for_duplicate_email_test
    
    # 1. Dado (Given) - Usuário duplicado existe (feito abaixo Setup)
    Set Test Variable    ${CLEANUP_EMAIL}    ${fixture}[email]
    Remove User And Related Data    ${CLEANUP_EMAIL}
    ${user_id}        Insert User Directly Into DB    ${fixture}
    Should Not Be Equal    ${user_id}    ${None}

    # 2. Quando (When) - Tenta registrar novamente com o mesmo email
    ${response}=    Register User    ${fixture}

    # 3. Então (Then) - Valida o erro
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=400
    ...    schema_file=register_duplicate_email_error.schema.json

CTC-003_API (API): Tentativa de registro com formato de e-mail inválido
    [Tags]    API    Negative    US-AUTH-001    CTC-003_API
    [Documentation]
    ...              Dado que eu tenho um payload de registro com email mal formatado
    ...              Quando eu envio uma requisição POST para "/auth/register"
    ...              Então a resposta deve ter o status code 400
    ...              E o corpo da resposta deve conter uma mensagem de erro sobre o formato do e-mail
    
    # 1. Dado (Given) - Carrega os dados do fixture com email inválido
    ${fixture}        Get Fixture From Collection   users    user_with_invalid_email_format

    Set Test Variable    ${CLEANUP_EMAIL}    ${None}

    # 2. Quando (When) - Tenta registrar com o payload inválido
    ${response}=    Register User    ${fixture}
    
    ${expected_errors_dict}        Create Dictionary    email=Please provide a valid email

    # 3. Então (Then) - Valida o erro 400
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=400
    ...    expected_error_message=Validation failed
    ...    expected_errors_dict=${expected_errors_dict}
    ...    schema_file=register_invalid_email_error.schema.json