*** Settings ***
# Import das bibliotecas utilizadas
Library    RequestsLibrary
Library    Browser
Library    FakerLibrary
Library    JSONLibrary
Library    Collections
Library    JSONSchemaLibrary

# Arquivo de gerenciamento da massa de testes dentro do MongoDB
Library    ../lib/data_manager.py

# Importa nossas variáveis de ambiente
Variables    ../variables/env_vars.py

# Importa todas as nossas Page Objects e Service Objects
# (Vamos adicionar mais arquivos aqui conforme criamos)
Resource    api/auth_service.resource
# Resource    api/users_service.resource
# Resource    api/movies_service.resource
# Resource    api/theaters_service.resource
# Resource    api/sessions_service.resource
# Resource    api/reservations_service.resource

# Resource    ui/login_page.resource
# Resource    ui/home_page.resource
# Resource    ui/components/header_component.resource

Resource    validation/api_validation.resource

*** Variables ***
${CLEANUP_EMAIL}


*** Keywords ***
#Keywords de Suite
API Test Setup
    [Documentation]    Cria uma sessão de API para os testes
    Create Session    api    ${API_BASE_URL}


API Test Teardown
    [Documentation]    Fecha a sessão de API
    Remove User And Related Data    ${CLEANUP_EMAIL}
    
    Delete All Sessions

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
    [Arguments]        ${endpoint}    ${payload}    ${headers}=&{EMPTY}
    
    ${response}=    Run Keyword If    ${headers}
    ...    POST On Session    api    url=${endpoint}    json=${payload}    headers=${headers}    expected_status=any
    ...    ELSE
    ...    POST On Session    api    url=${endpoint}    json=${payload}    expected_status=any
    
    RETURN    ${response}

GET From
    [Documentation]    Envia uma requisição GET para o endpoint especificado.
    [Arguments]        ${endpoint}    ${headers}=&{EMPTY}
    
    ${response}=    Run Keyword If    ${headers}
    ...    GET On Session    api    url=${endpoint}    headers=${headers}    expected_status=any
    ...    ELSE
    ...    GET On Session    api    url=${endpoint}    expected_status=any
    
    RETURN    ${response}

PUT To
    [Documentation]    Envia uma requisição PUT para o endpoint especificado.
    [Arguments]        ${endpoint}    ${payload}    ${headers}=&{EMPTY}
    
    ${response}=    Run Keyword If    ${headers}
    ...    PUT On Session    api    url=${endpoint}    json=${payload}    headers=${headers}    expected_status=any
    ...    ELSE
    ...    PUT On Session    api    url=${endpoint}    json=${payload}    expected_status=any
    
    RETURN    ${response}

PATCH To
    [Documentation]    Envia uma requisição PATCH para o endpoint especificado.
    [Arguments]        ${endpoint}    ${payload}    ${headers}=&{EMPTY}
    
    ${response}=    Run Keyword If    ${headers}
    ...    PATCH On Session    api    url=${endpoint}    json=${payload}    headers=${headers}    expected_status=any
    ...    ELSE
    ...    PATCH On Session    api    url=${endpoint}    json=${payload}    expected_status=any
    
    RETURN    ${response}

DELETE From
    [Documentation]    Envia uma requisição DELETE para o endpoint especificado.
    [Arguments]        ${endpoint}    ${headers}=&{EMPTY}
    
    ${response}=    Run Keyword If    ${headers}
    ...    DELETE On Session    api    url=${endpoint}    headers=${headers}    expected_status=any
    ...    ELSE
    ...    DELETE On Session    api    url=${endpoint}    expected_status=any
    
    RETURN    ${response}