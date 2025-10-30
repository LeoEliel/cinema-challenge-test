*** Settings ***
Documentation    Keywords de serviço para a API de Salas (Theaters).
...              Implementa o padrão Service Objects para interagir com os endpoints /theaters.

Resource    ../common.resource

*** Keywords ***
# --- Leitura (Pública) ---

List Theaters
    [Documentation]    Busca a lista de salas (GET /theaters), opcionalmente com query params.
    [Arguments]    ${params}=${EMPTY}
    
    # Chama a keyword genérica GET From (de common.resource)
    ${response}=    GET From    /theaters    params=${params}
    RETURN    ${response}

Get Theater By ID
    [Documentation]    Busca os detalhes de uma sala específica pelo ID (GET /theaters/{id}).
    [Arguments]    ${theater_id}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /theaters/${theater_id}
    # Chama a keyword genérica GET From
    ${response}=    GET From    ${endpoint}
    RETURN    ${response}

# --- Escrita (Admin Only - *!) ---

Create Theater
    [Documentation]    Cria uma nova sala (POST /theaters). Requer token de Admin.
    [Arguments]    ${payload}    ${admin_headers}

    # Chama a keyword genérica POST To
    ${response}=    POST To    /theaters    ${payload}    ${admin_headers}
    RETURN    ${response}

Update Theater
    [Documentation]    Atualiza uma sala existente (PUT /theaters/{id}). Requer token de Admin.
    [Arguments]    ${theater_id}    ${payload}    ${admin_headers}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /theaters/${theater_id}
    # Chama a keyword genérica PUT To
    ${response}=    PUT To    ${endpoint}    ${payload}    ${admin_headers}
    RETURN    ${response}

Delete Theater
    [Documentation]    Deleta uma sala existente (DELETE /theaters/{id}). Requer token de Admin.
    [Arguments]    ${theater_id}    ${admin_headers}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /theaters/${theater_id}
    # Chama a keyword genérica DELETE From
    ${response}=    DELETE From    ${endpoint}    ${admin_headers}
    RETURN    ${response}