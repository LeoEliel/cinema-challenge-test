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
# Resource    api/sessions_service.resource
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
    Create Session    ${SESSION_ALIAS}    ${API_BASE_URL}

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
    ${ADMIN_EMAIL_FIXTURE}=    Set Variable    admin@example.com     # <-- Ou carrega de ${USER_FIXTURES}
    
    # Garante que o usuário admin existe
    ${admin_id}=    Get User Id by Email    ${ADMIN_EMAIL_FIXTURE}
    Should Not Be Equal    ${admin_id}    ${None}    msg=Usuário admin ${ADMIN_EMAIL_FIXTURE} não encontrado no DB.

    # Gera o token usando a keyword do data_manager
    ${admin_token}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_FIXTURE}
    # Guarda o token para o Test Case usar
    Set Test Variable    ${ADMIN_TOKEN_BEARER}    ${admin_token}
    Log    Token de Admin gerado para o teste: ${ADMIN_TOKEN_BEARER}