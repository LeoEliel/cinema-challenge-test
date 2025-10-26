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