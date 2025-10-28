*** Settings ***
Documentation    Keywords de serviço para a API de Autenticação (Auth)
...
...    Este resource implementa o padrão Service Objects.
...    Ele contém keywords para interagir com os endpoints de autenticação.

Resource    ../common.resource

*** Keywords ***
# AUTH SERVICE OBJECTS - Específicos do domínio de Autenticação

Register User
    [Documentation]    Registra um novo usuário no sistema.
    [Arguments]        ${user_data}=&{EMPTY}
    
    ${response}=    POST To    endpoint=/auth/register    json=${user_data}
    RETURN    ${response}

Login User
    [Documentation]    Autentica um usuário no sistema.
    [Arguments]        ${credentials}=&{EMPTY}
    
    ${response}=    POST To    endpoint=/auth/login    json=${credentials}
    RETURN    ${response}


# Logout User
#     [Documentation]    Faz logout do usuário.
#     [Arguments]        ${headers}=&{EMPTY}
    
#     ${response}=    POST To    endpoint=/auth/logout    headers=${headers}
#     RETURN    ${response}

Get User Profile
    [Documentation]    Retorna profile do usuário atualmente logado.
    [Arguments]    ${headers}

    ${response}=    GET From    endpoint=/auth/me    headers=${headers}
    RETURN    ${response}

Update User Profile
    [Documentation]    Atualiza os dados do perfil do usuário autenticado (PUT /auth/profile).
    [Arguments]    ${payload}    ${headers}

    ${response}=    PUT To    endpoint=/auth/profile    json=${payload}    headers=${headers}
    RETURN    ${response}

Setup User And Get Valid Token
    [Documentation]    Garante que um usuário exista, faz login via API 
    ...                e armazena o token válido na variável de teste em $VALID_TOKEN.

    #Cria a sessão sem passar pelo Setup padrão
    API Test Setup

    # Carrega os dados do usuário base do arquivo de fixtures JSON
    ${fixture_user_data}=    Get Fixture From Collection   users    valid_user_register
    
    Set Test Variable    ${fixture_user_data}
    # Define o e-mail que será usado pelo Teardown padrão para limpar este usuário
    
    Set Test Variable        ${MOVIE_ID_LIST}     ${fixture_user_data}[email]
    # Garante um estado limpo removendo qualquer usuário preexistente com este e-mail
    
    Remove User And Related Data    ${MOVIE_ID_LIST}
    # Insere o usuário diretamente no banco de dados usando a keyword Python
    
    ${user_id}=    Insert User Directly Into DB    ${fixture_user_data}
    Set Test Variable    ${user_id}
    
    # Verifica se a inserção no banco de dados realmente ocorreu
    Should Not Be Equal    ${user_id}    ${EMPTY}    msg=Falha ao inserir usuário pré-requisito no DB

    # Log para registrar a criação bem-sucedida do usuário
    Log    Usuário pré-requisito ${fixture_user_data}[email] inserido com ID ${user_id}

    # Prepara as credenciais (email e senha original) para fazer o login via API
    &{login_credentials}=    Create Dictionary
    ...    email=${fixture_user_data}[email]
    ...    password=${fixture_user_data}[password]

    # Realiza o login usando a keyword do serviço de autenticação para obter um token válido
    ${login_response}=    Login User    credentials=${login_credentials}

    # Valida se a resposta do login foi bem-sucedida (Status 200 e Schema correto)
    Validate Successful API Response    ${login_response}    200    login_success_response.schema.json

    # Extrai o token JWT ('accessToken') da resposta JSON do login
    ${token}=    Set Variable    ${login_response.json()}[data][token]

    # Armazena o token extraído em uma variável de TESTE (${VALID_TOKEN})
    # Esta variável fica disponível para o Test Case que chamou este Setup
    Set Test Variable    ${VALID_TOKEN}    ${token}

    # Log para registrar o token válido que foi obtido
    Log    Token válido obtido para o teste: ${VALID_TOKEN}

# TEARDOWN KEYWORDS ESPECÍFICAS PARA AUTENTICAÇÃO

API Test Teardown For User Collection
    [Arguments]        ${CLEANUP_EMAIL}=${EMPTY}
    [Documentation]    Fecha a sessão de API e remove dados de usuário
    Run Keyword If   '${MOVIE_ID_LIST}' != '${EMPTY}'
    ...    Remove User And Related Data    ${MOVIE_ID_LIST}
    
    Delete All Sessions
