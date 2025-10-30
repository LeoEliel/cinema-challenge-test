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
    [Arguments]    ${movie_id}

    ${response}=    GET From    /movies/${movie_id}
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

    ${endpoint}=    Set Variable    /movies/${movie_id}
    ${response}=    PUT To    ${endpoint}    ${payload}    ${admin_headers}
    RETURN    ${response}

Delete Movie
    [Documentation]    Deleta um filme existente (DELETE /movies/{id}). Requer token de Admin.
    [Arguments]    ${movie_id}    ${admin_headers}

    ${endpoint}=    Set Variable    /movies/${movie_id}
    ${response}=    DELETE From    ${endpoint}    ${admin_headers}
    RETURN    ${response}

*** Keywords ***

Setup Movies For Test
    [Documentation]    Carrega dados do fixture, limpa dados antigos, insere filme(s) via DB
    ...              e armazena os IDs criados na variável de teste @MOVIE_ID_LIST.
    [Arguments]    ${fixture_key}
    
    API Test Setup

    # Carrega os dados do fixture (pode ser um dict ou uma lista de dicts)
    ${fixture_data}=    Get Fixture From Collection    movies    ${fixture_key}

    # Transforma em lista, mesmo se for um único dict, para facilitar o loop
    @{data_list}=    Run Keyword If    isinstance($fixture_data, list)
    ...    Set Variable    @{fixture_data}
    ...    ELSE
    ...    Create List    ${fixture_data}

    Log    Dados carregados para setup: @{data_list}

    # Garante limpeza prévia para os títulos específicos que vamos criar
    FOR    ${element}    IN    @{data_list}
        ${existing_id}=    Get Movie Id By Title    ${element}[title]
        Run Keyword If    '${existing_id}' != '${None}'    Remove Movie And Related Data    ${existing_id}
    END

    # Cria a lista para guardar os IDs criados neste setup
    @{ids_created_in_setup}=    Create List

    # Insere os filmes via DB e guarda os IDs
    FOR    ${element}    IN    @{data_list}
        Log    Inserindo Filme no DB: ${element}[title]
        ${id_movie}=    Insert Movie Directly Into DB    ${element}     # Keyword do database_manager
        Should Not Be Equal    ${id_movie}    ${None}    msg=Falha ao inserir filme '${element}[title]' no DB
        Append To List    ${ids_created_in_setup}    ${id_movie}
    END

    # Define a lista de IDs como VARIÁVEL DE TESTE para ser usada pelo Test Teardown
    Set Test Variable    @{MOVIE_ID_LIST}    @{ids_created_in_setup}
    Log    IDs dos filmes criados para este teste (@{MOVIE_ID_LIST}): @{ids_created_in_setup}

    # 1. Cria o token de Admin -> ${GENERATED_ADMIN_TOKEN_FOR_DEBUG}
    Verificar Geração de Token de Admin
    Log    Token de Admin gerado.


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