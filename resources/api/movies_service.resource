*** Settings ***
Documentation    Keywords de serviço para a API de Filmes (Movies).
...              Implementa o padrão Service Objects para interagir com os endpoints /movies.

Resource    ../common.resource
Library    OperatingSystem

*** Keywords ***
# --- Leitura (Pública) ---

List Movies
    [Documentation]    Busca a lista de filmes (GET /movies), opcionalmente com query params.
    
    # $query_params é um dicionário de query params que esta rota exige
    [Arguments]    ${params}=${EMPTY}
        
    ${response}=    GET From    /movies    params=${params}
    RETURN    ${response}

Get Movie By ID
    [Documentation]    Busca os detalhes de um filme específico pelo ID (GET /movies/{id}).
    [Arguments]    ${movie_id}    ${headers}=${EMPTY}

    ${response}=    GET From    /movies/${movie_id}    headers=${headers}
    RETURN    ${response}

# --- Escrita (Admin Only - *!) ---

Create Movie
    [Documentation]    Cria um novo filme (POST /movies). Requer token de Admin.
    [Arguments]    ${payload}    ${admin_headers}

    ${response}=    POST To    /movies    ${payload}    ${admin_headers}
    RETURN    ${response}

Update Movie
    [Documentation]    Atualiza um filme existente (PUT /movies/{id}). Requer token de Admin.
    [Arguments]    ${movie_id}    ${payload}    ${admin_headers}

    ${endpoint}=    Set Variable    /movies/${MOVIE_ID_LIST}
    ${response}=    PUT To    ${endpoint}    ${payload}    ${admin_headers}
    RETURN    ${response}

Delete Movie
    [Documentation]    Deleta um filme existente (DELETE /movies/{id}). Requer token de Admin.
    [Arguments]    ${movie_id}    ${admin_headers}

    ${endpoint}=    Set Variable    /movies/${MOVIE_ID_LIST}
    ${response}=    DELETE From    ${endpoint}    ${admin_headers}
    RETURN    ${response}

*** Keywords ***
# Setup Query Params To
#     [Documentation]    Keyword para concatenar query params existentes à url
#     [Arguments]        ${endpoint}    ${query_params}

#     FOR    ${key}    ${value}    IN ENUMERATE    ${query_params}
#         ${endpoint}        Catenate    SEPARATOR=    ${key}=${value}
#     END

#     Set Test Variable    ${endpoint}

#     Log    Endpoint com query params: ${endpoint}
    
#     RETURN    ${endpoint}

API Test Teardown For Movie Collection
    #[Arguments]        ${MOVIE_ID_LIST}=${EMPTY}
    [Documentation]    Fecha a sessão de API e remove dados de usuário
    IF    @{MOVIE_ID_LIST}
        FOR    ${index}    ${element}    IN ENUMERATE  @{MOVIE_ID_LIST}
            Log   Removendo Filme >>> ${index}: ${element}
            Remove Movie And Related Data    ${element}
            
        END
    END
    Delete All Sessions