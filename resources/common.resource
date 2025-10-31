*** Settings ***
# Import das bibliotecas utilizadas
Library    RequestsLibrary
Library    Browser
Library    FakerLibrary
Library    JSONLibrary
Library    Collections
Library    JSONSchemaLibrary
Library    String

# Arquivo de gerenciamento da massa de testes dentro do MongoDB
Library    ../lib/data_manager.py

# Importa nossas variáveis de ambiente
Variables    ../variables/env_vars.py

# Importa todas as nossas Page Objects e Service Objects
# (Vamos adicionar mais arquivos aqui conforme criamos)
Resource    api/auth_service.resource
# Resource    api/users_service.resource
Resource    api/movies_service.resource
Resource    api/theaters_service.resource
Resource    api/sessions_service.resource
# Resource    api/reservations_service.resource

# Resource    ui/login_page.resource
# Resource    ui/home_page.resource
# Resource    ui/components/header_component.resource

Resource    validation/api_validation.resource

*** Variables ***

${SESSION_ALIAS}        api

*** Keywords ***
#Keywords de Suite
API Test Setup
    [Documentation]    Cria uma sessão de API para os testes
    Create Sessions    ${SESSION_ALIAS}    ${API_BASE_URL}

#Keywords de Teste    
UI Test Setup
    [Documentation]    Abre o navegador na página inicial
    New Page    ${UI_BASE_URL}
    # Exemplo de como setar a resolução
    # Set Viewport Size    1440    900

UI Test Teardown
    [Documentation]    Fecha o navegador
    Take Screenshot
    Close Page

Get Fixture From Collection
    [Documentation]    Pega o arquivo de fixtures desejado na /fixtures + o contexto de teste
    [Arguments]        ${collection_name}    ${context}
    
    ${file_path}=       Set Variable    ${EXECDIR}/fixtures/${collection_name}.json
    ${json_data}=       Load Json From File    ${file_path}    encoding=UTF-8
    
    RETURN        ${json_data}[${context}]

# HTTP KEYWORDS GENÉRICAS - Infraestrutura

POST To
    [Documentation]    Envia uma requisição POST para o endpoint especificado.
    [Arguments]        ${endpoint}    ${json}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}    
    ...    json=${json}    
    ...    headers=${headers}    
    ...    params=${params}

    ${response}=    POST On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}

GET From
    [Documentation]    Envia uma requisição GET para o endpoint especificado.
    [Arguments]        ${endpoint}    ${json}=&{EMPTY}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}
    ...    headers=${headers}
    ...    params=${params}

    ${response}=    GET On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}
PUT To
    [Documentation]    Envia uma requisição PUT para o endpoint especificado.
    [Arguments]        ${endpoint}    ${json}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}    
    ...    json=${json}    
    ...    headers=${headers}    
    ...    params=${params}
    
    ${response}=    PUT On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}


PATCH To
    [Documentation]    Envia uma requisição PATCH para o endpoint especificado.
    [Arguments]        ${endpoint}    ${json}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}    
    ...    json=${json}    
    ...    headers=${headers}    
    ...    params=${params}
    
    ${response}=    PATCH On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}

DELETE From
    [Documentation]    Envia uma requisição DELETE para o endpoint especificado.
    [Arguments]        ${endpoint}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}    
    ...    headers=${headers}    
    ...    params=${params}
    
    ${response}=    DELETE On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}

DELETE With Empty Headers From
    [Documentation]    Envia uma requisição DELETE para o endpoint especificado.
    [Arguments]        ${endpoint}    ${params}=&{EMPTY}
    
    &{kwargs}    Setup Keyword Args For Generic Request    
    ...    endpoint=${endpoint}    
    ...    params=${params}
    
    ${response}=    DELETE On Session    ${SESSION_ALIAS}    &{kwargs}
    RETURN    ${response}

Setup Keyword Args For Generic Request
    [Documentation]    Keyword Genérica Para Preparar Keywords Arguments para lidar com variação de requests
    [Arguments]        ${endpoint}    ${json}=&{EMPTY}    ${headers}=&{EMPTY}    ${params}=&{EMPTY}
    
    &{kwargs}=    Create Dictionary    url=${endpoint}    expected_status=any

    Run Keyword If    ${headers}    Set To Dictionary    ${kwargs}    headers=${headers}
    Log    Keyword Args After Headers: &{kwargs}

    Run Keyword If    ${params}     Set To Dictionary    ${kwargs}    params=${params}
    Log    Keyword Args After Params: &{kwargs}
    
    Run Keyword If    ${json}    Set To Dictionary    ${kwargs}    json=${json}
    Log    Keyword Args After JSON: &{kwargs}

    RETURN    &{kwargs}

Generate Admin Token For Test
    [Documentation]    Garante que usuário admin exista (via fixtures) e gera token na variável de teste ${ADMIN_TOKEN_BEARER}.
    # Define o email do admin. Poderia ser passado como argumento se tivéssemos múltiplos admins.
    API Test Setup
    ${ADMIN_EMAIL_FIXTURE}=    Set Variable    admin@example.com     # <-- Ou carrega de ${USER_FIXTURES}
    
    # Garante que o usuário admin existe
    ${admin_id}=    Get User Id by Email    ${ADMIN_EMAIL_FIXTURE}
    Should Not Be Equal    ${admin_id}    ${None}    msg=Usuário admin ${ADMIN_EMAIL_FIXTURE} não encontrado no DB.

    # Gera o token usando a keyword do data_manager
    ${admin_token}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_FIXTURE}
    # Guarda o token para o Test Case usar
    Set Test Variable    ${ADMIN_TOKEN_BEARER}    ${admin_token}
    Log    Token de Admin gerado para o teste: ${ADMIN_TOKEN_BEARER}

Setup User And Get Valid Token
    [Documentation]    Garante que um usuário exista, faz login via API 
    ...                e armazena o token válido na variável de teste em $VALID_TOKEN.
    ...                e cria $USER_EMAIL para teardown posterior

    #Cria a sessão sem passar pelo Setup padrão
    API Test Setup

    # Carrega os dados do usuário base do arquivo de fixtures JSON
    ${fixture_user_data}=    Get Fixture From Collection   users    valid_user_register
    
    Set Test Variable    ${fixture_user_data}
    # Define o e-mail que será usado pelo Teardown padrão para limpar este usuário
    Set Test Variable        ${USER_EMAIL}     ${fixture_user_data}[email]
    # Garante um estado limpo removendo qualquer usuário preexistente com este e-mail
    
    Remove User And Related Data    ${USER_EMAIL}
    # Insere o usuário diretamente no banco de dados usando a keyword Python
    
    ${USER_ID}=    Insert User Directly Into DB    ${fixture_user_data}
    Set Test Variable    ${USER_ID}
    
    # Verifica se a inserção no banco de dados realmente ocorreu
    Should Not Be Equal    ${USER_ID}    ${EMPTY}    msg=Falha ao inserir usuário pré-requisito no DB

    # Log para registrar a criação bem-sucedida do usuário
    Log    Usuário pré-requisito ${USER_EMAIL} inserido com ID ${USER_ID}

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

API Test Teardown For User Collection
    [Documentation]    Fecha a sessão de API e remove dados de usuário
    Run Keyword If   '${USER_EMAIL}' != '${EMPTY}'
    ...    Remove User And Related Data    ${USER_EMAIL}
    
    Delete All Sessions

Verificar Geração de Token de Admin
    [Documentation]    Chama Generate Admin Token e verifica se retorna um token válido (formato Bearer ...).
    [Tags]    Utils    Token

    # Garante que o admin exista (OPCIONAL, mas mais robusto)
    # Poderia usar Insert User Directly aqui se quisesse garantir,
    # mas por agora, vamos assumir que ele existe (como no seu DB).

    ${fixture}    Get Fixture From Collection    users    admin_user_inserted

    Set Test Variable    ${ADMIN_EMAIL_PARA_TESTE}    ${fixture}[email]
    ${admin_id}=    Get User Id by Email    ${ADMIN_EMAIL_PARA_TESTE}
    Should Not Be Equal    ${admin_id}    
    ...    ${None}    msg=Usuário admin ${ADMIN_EMAIL_PARA_TESTE} não encontrado no DB. Setup necessário.

    # Ação: Chama a keyword para gerar o token
    ${admin_token}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_PARA_TESTE}

    # Validações Básicas:
    # 1. Verifica se não é vazio
    Should Not Be Empty    ${admin_token}
    # 2. Verifica se começa com "Bearer "
    Should Start With    ${admin_token}    Bearer
    # 3. Verifica se tem mais do que apenas "Bearer " (um token real)
    ${token_part}=    Split String    ${admin_token}    ${SPACE}    max_split=1
    Should Not Be Empty    ${token_part}[1]
    # 4. Verifica se o token tem um comprimento razoável (JWTs são longos)
    ${token_length}=    Get Length    ${token_part}[1]
    Should Be True    ${token_length} > 50 
    # Um valor arbitrário, JWTs são geralmente > 100 caracteres

    Log    Token de Admin gerado com sucesso: ${admin_token}
    # Guarda para ver no log
    Set Suite Variable    ${GENERATED_ADMIN_TOKEN_FOR_DEBUG}    ${admin_token}     


