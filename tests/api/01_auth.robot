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

CTC-004_API (API): Login com credenciais válidas pela API
    [Tags]    API    Smoke    US-AUTH-002    CTC-004_API
    [Documentation]
    ...              Dado que eu tenho as credenciais de um usuário válido
    ...              Quando eu envio uma requisição POST para o endpoint "/auth/login"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter um "accessToken"
    # [Setup]     # REMOVIDO o [Setup] específico

    # --- SETUP INLINE ---
    # 1. Dado (Given) - Garante que o usuário para login exista
    ${fixture}=    Get Fixture From Collection   users    valid_user_register
    Set Test Variable        ${CLEANUP_EMAIL}     ${fixture}[email]
    
    # Pré-limpeza
    Remove User And Related Data    ${fixture}[email] 

    ${user_id}=    Insert User Directly Into DB    ${fixture}
    
    Should Not Be Equal    ${user_id}    ${None}    msg=Falha ao inserir usuário pré-requisito para login no DB
    
    Log    Usuário pré-requisito para login ${fixture}[email] inserido com ID ${user_id}
    # --- FIM DO SETUP INLINE ---

    # Monta o payload específico para login (apenas email e senha)
    &{login_payload}=    Create Dictionary
    ...    email=${fixture}[email]
    ...    password=${fixture}[password]

    # 2. Quando (When) - Envia a requisição de login
    ${response}=    Login User   ${login_payload}

    # 3. Então (Then) - Valida a resposta de sucesso
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=login_success_response.schema.json

CTC-005_API (API): Tentativa de login com credenciais inválidas pela API
    [Tags]    API    Negative    US-AUTH-002    CTC-005_API
    [Documentation]
    ...              Dado que eu tenho as credenciais de um usuário com senha incorreta
    ...              Quando eu envio uma requisição POST para o endpoint "/auth/login"
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter uma mensagem de "Invalid email or password"

    # --- SETUP INLINE ---
    # Carrega os dados do fixture que será usado como base (usuário válido)
    ${fixture_user_data}=    Get Fixture From Collection   users    valid_user_register
    # Define o e-mail que será limpo pelo Teardown padrão
    Set Test Variable        ${CLEANUP_EMAIL}     ${fixture_user_data}[email]
    # Garante que o usuário de teste exista, limpando qualquer versão anterior
    Remove User And Related Data    ${fixture_user_data}[email]
    # Insere o usuário de teste diretamente no banco de dados
    ${user_id}=    Insert User Directly Into DB    ${fixture_user_data}
    # Verifica se a inserção no banco de dados foi bem-sucedida
    Should Not Be Equal    ${user_id}    ${None}    msg=Falha ao inserir usuário pré-requisito para teste de login inválido no DB
    # Log para registrar a criação do usuário de pré-requisito
    Log    Usuário pré-requisito ${fixture_user_data}[email] inserido com ID ${user_id}
    # --- FIM DO SETUP INLINE ---

    # Monta o payload (credenciais) para a tentativa de login usando o e-mail correto e uma senha inválida
    &{login_credentials}=    Get Fixture From Collection    users    login_invalid_password

    # Envia a requisição de login usando a keyword correta do serviço de autenticação
    ${response}=    Login User    credentials=${login_credentials}

    # Valida a resposta de erro recebida da API
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=login_invalid_credentials_error.schema.json