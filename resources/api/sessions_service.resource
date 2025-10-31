*** Settings ***
Documentation    Keywords de serviço para a API de Sessões (Sessions).
...              Implementa o padrão Service Objects para interagir com os endpoints /sessions.

# Importa o common.resource para ter acesso às keywords genéricas (GET From, POST To, etc.)
Resource    ../common.resource

*** Keywords ***
# --- Leitura (Pública) ---

List Sessions
    [Documentation]    Busca a lista de sessões (GET /sessions), opcionalmente com query params.
    [Arguments]    ${params}=${EMPTY}
    
    # Chama a keyword genérica GET From
    ${response}=    GET From    /sessions    params=${params}
    RETURN    ${response}

Get Session By ID
    [Documentation]    Busca os detalhes de uma sessão específica (GET /sessions/{id}).
    [Arguments]    ${session_id}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /sessions/${session_id}
    # Chama a keyword genérica GET From
    ${response}=    GET From    ${endpoint}
    RETURN    ${response}

# --- Escrita (Admin Only - *!) ---

Create Session
    [Documentation]    Cria uma nova sessão (POST /sessions). Requer token de Admin.
    [Arguments]    ${payload}    ${admin_headers}

    # Chama a keyword genérica POST To
    ${response}=    POST To    /sessions    ${payload}    ${admin_headers}
    RETURN    ${response}

Update Sessions
    [Documentation]    Atualiza uma sessão existente (PUT /sessions/{id}). Requer token de Admin.
    [Arguments]    ${session_id}    ${payload}    ${admin_headers}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /sessions/${session_id}
    # Chama a keyword genérica PUT To
    ${response}=    PUT To    ${endpoint}    ${payload}    ${admin_headers}
    RETURN    ${response}

Delete Session
    [Documentation]    Deleta uma sessão existente (DELETE /sessions/{id}). Requer token de Admin.
    [Arguments]    ${session_id}    ${admin_headers}
    
    # Constrói o endpoint específico
    ${endpoint}=    Set Variable    /sessions/${session_id}
    # Chama a keyword genérica DELETE From
    ${response}=    DELETE From    ${endpoint}    ${admin_headers}
    RETURN    ${response}

Reset Session Seats
    [Documentation]    Reseta todos os assentos de uma sessão (PUT /sessions/{id}/reset-seats). Requer token de Admin.
    [Arguments]    ${session_id}    ${admin_headers}

    ${endpoint}=    Set Variable    /sessions/${session_id}/reset-seats
    # CORRIGIDO para usar PUT To (e enviar payload ${EMPTY})
    ${response}=    PUT To    ${endpoint}    ${EMPTY}    ${admin_headers}
    RETURN    ${response}