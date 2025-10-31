*** Settings ***
Documentation    Suíte de testes de API para a feature de Sessões (Sessions).
...              Cobre casos de teste públicos (US-SESSION-001) e de admin.

# Importa resources globais (libs, keywords genéricas, keywords de DB)
Resource    ../../resources/common.resource
# Importa keywords de API específicas (List Sessions, Create Session, etc.)
Resource    ../../resources/api/sessions_service.resource
# Precisamos dos service objects de Movie e Theater para os teardowns
Resource    ../../resources/api/movies_service.resource
Resource    ../../resources/api/theaters_service.resource

# --- Setup/Teardown PADRÃO para cada teste ---
# Configura a sessão API ANTES de cada teste
Test Setup        API Test Setup
# Limpa TODAS as entidades (Sessão, Filme, Sala, Usuário) DEPOIS de cada teste
Test Teardown     Teardown Completo (Sessão, Filme, Sala, Usuário)

*** Variables ***
${SESSION_FIXTURES}       ../../fixtures/sessions.json
${MOVIE_FIXTURES}         ../../fixtures/movies.json
${THEATER_FIXTURES}       ../../fixtures/theaters.json
${USER_FIXTURES}          ../../fixtures/users.json

# Schemas (Nomes dos arquivos que estarão em /schemas)
${SESSION_SCHEMA_LIST}    list_sessions_response.schema.json

*** Test Cases ***
CN-34 (CTC-13_API): Listar sessões filtrando por Filme
    [Tags]    API    Smoke    Sessions    US-SESSION-001    CTC-013_API    CN-34
    [Documentation]
    ...              Dado que existem sessões para o Filme A e Filme B
    ...              Quando envio GET para "/sessions" filtrando pelo Filme A
    ...              Então a resposta deve ter status 200
    ...              E o corpo da resposta deve conter apenas as sessões do Filme A
    # Setup específico: Usa a nova keyword orquestradora
    [Setup]    Setup Para Teste de Filtro de Sessão

    # --- DICIONÁRIO DE QUERY PARAMS COESO ---
    # Define os query params para buscar APENAS as sessões do Filme A
    # (O ID ${MOVIE_A_ID} foi criado e definido no [Setup])
    ${QUERY_PARAMS}=    Create Dictionary
    ...    movie=${MOVIE_A_ID}    # Filtra pelo ID do Filme A
    ...    limit=5              # Garante que pegamos todos (setup cria 2)

    # Ação: Chama a keyword do sessions_service com os parâmetros de filtro
    ${response}=    List Sessions    params=${QUERY_PARAMS}

    # Validação
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${SESSION_SCHEMA_LIST}     # Valida a estrutura geral da resposta

    # Validação Extra (Coesão): Verifica se o filtro funcionou
    ${body}=    Set Variable    ${response.json()}
    # Esperamos que o 'count' (total no DB para esse filtro) seja 2
    Should Be Equal As Strings    ${body['count']}    2    msg=A contagem total de sessões para o Filme A deveria ser 2.
    # Esperamos que a 'data' (lista na página) tenha 2 itens
    Length Should Be            ${body['data']}    2    msg=A lista 'data' deveria conter 2 sessões.

    # Validação profunda: Garante que AMBAS as sessões retornadas são do Filme A
    FOR    ${session}    IN    @{body['data']}
        ${movie_field}=    Run Keyword If    isinstance($session['movie'], dict)
        ...    Set Variable    ${session['movie']['_id']}
        ...    ELSE    Set Variable    ${session['movie']}
        Should Be Equal As Strings    ${movie_field}    ${MOVIE_A_ID}
    END
    Log    Validação concluída: Apenas sessões do Filme A foram retornadas.

*** Keywords ***
# --- Bloco 1: Keywords de Teardown (Limpam listas) ---
# (O Test Teardown global chama estas)

Initialize Teardown Lists
    [Documentation]    Cria as listas vazias que o Teardown espera.
    @{empty_list}=    Create List
    Set Test Variable    @{SESSION_ID_LIST}    @{empty_list}
    Set Test Variable    @{MOVIE_ID_LIST}      @{empty_list}
    Set Test Variable    @{THEATER_ID_LIST}    @{empty_list}
    Set Test Variable    ${USER_EMAIL}         ${None}

Teardown Sessions
    [Documentation]    Limpa as sessões criadas (lê @{SESSION_ID_LIST}).
    ${list_exists}=    Run Keyword And Return Status    Variable Should Exist    @{SESSION_ID_LIST}
    IF    ${list_exists} and @{SESSION_ID_LIST}
        FOR    ${session_id}    IN    @{SESSION_ID_LIST}
            Log    Removendo Sessão ID: ${session_id} ...
            Remove Session And Related Data    ${session_id}
        END
    END

Teardown Movies
    [Documentation]    Limpa os filmes criados (lê @{MOVIE_ID_LIST}).
    ${list_exists}=    Run Keyword And Return Status    Variable Should Exist    @{MOVIE_ID_LIST}
    IF    ${list_exists} and @{MOVIE_ID_LIST}
        FOR    ${movie_id}    IN    @{MOVIE_ID_LIST}
            Log    Removendo Filme ID: ${movie_id} ...
            Remove Movie And Related Data    ${movie_id}
        END
    END

Teardown Theaters
    [Documentation]    Limpa as salas criadas (lê @{THEATER_ID_LIST}).
    ${list_exists}=    Run Keyword And Return Status    Variable Should Exist    @{THEATER_ID_LIST}
    IF    ${list_exists} and @{THEATER_ID_LIST}
        FOR    ${theater_id}    IN    @{THEATER_ID_LIST}
            Log    Removendo Sala ID: ${theater_id} ...
            Remove Theater And Related Data    ${theater_id}
        END
    END
    Delete All Sessions    # Fecha sessão HTTP no final

Teardown Completo (Sessão, Filme, Sala, Usuário)
    [Documentation]    Limpa todas as entidades que podem ter sido criadas por um teste.
    Teardown Sessions
    Teardown Movies
    Teardown Theaters
    API Test Teardown For User Collection     # Limpa ${USER_EMAIL} (de common.resource)

# --- Bloco 2: Keywords de Criação (Blocos de Construção) ---

Create Test Movie
    [Documentation]    Cria 1 Filme (dinâmico) e prepara para o Teardown. Retorna ID.
    [Arguments]    ${fixture_key}
    ${movie_data}=    Get Fixture From Collection    movies    ${fixture_key}
    ${suffix}=        Generate Random String    4    [LOWER]
    ${movie_data}=    Set To Dictionary    ${movie_data}    title=${movie_data}[title] - ${suffix}
    
    ${existing_id}=    Get Movie Id By Title    ${movie_data}[title]
    Run Keyword If    '${existing_id}' != '${None}'    Remove Movie And Related Data    ${existing_id}
    
    ${movie_id}=      Insert Movie Directly Into DB    ${movie_data}
    Should Not Be Equal    ${movie_id}    ${None}    msg=Falha ao criar Filme pré-requisito.
    
    Append To List    ${MOVIE_ID_LIST}    ${movie_id}
    Set Test Variable    @{MOVIE_ID_LIST}
    [Return]    ${movie_id}

Create Test Theater
    [Documentation]    Cria 1 Sala (dinâmica) e prepara para o Teardown. Retorna ID.
    [Arguments]    ${fixture_key}
    ${theater_data}=  Get Fixture From Collection    theaters  ${fixture_key}
    ${suffix}=        Generate Random String    4    [LOWER]
    ${theater_data}=  Set To Dictionary    ${theater_data}  name=${theater_data}[name] - ${suffix}

    ${existing_id}=   Get Theater Id By Name    ${theater_data}[name]
    Run Keyword If    '${existing_id}' != '${None}'    Remove Theater And Related Data    ${existing_id}
    
    ${theater_id}=    Insert Theater Directly Into DB    ${theater_data}
    Should Not Be Equal    ${theater_id}    ${None}    msg=Falha ao criar Sala pré-requisito.
    
    Append To List    ${THEATER_ID_LIST}    ${theater_id}
    Set Test Variable    @{THEATER_ID_LIST}
    [Return]    ${theater_id}

Create Test Session
    [Documentation]    Cria 1 Sessão (usando IDs) e prepara para o Teardown. Retorna ID.
    [Arguments]    ${fixture_key}    ${movie_id_str}    ${theater_id_str}
    
    ${session_data}=  Get Fixture From Collection    sessions    ${fixture_key}
    
    ${session_id}=    Insert Session Directly Into DB
    ...    session=${session_data}
    ...    movie_id=${movie_id_str}
    ...    theater_id=${theater_id_str}
    Should Not Be Equal    ${session_id}    ${None}    msg=Falha ao criar Sessão pré-requisito.
    
    Append To List    ${SESSION_ID_LIST}    ${session_id}
    Set Test Variable    @{SESSION_ID_LIST}
    [Return]    ${session_id}

# --- Bloco 3: Keywords Orquestradoras de Setup (Usadas nos Test Cases) ---

Setup Para Teste de Filtro de Sessão
    [Documentation]    Setup para CN-34. Cria 2 Filmes (A, B), 1 Sala (A), e 3 Sessões (2 para A, 1 para B).
    Initialize Teardown Lists     # Garante que as listas @{..._ID_LIST} estejam vazias
    API Test Setup
    # Cria dependências
    ${movie_A_id}=      Create Test Movie      base_valid_movie
    ${movie_B_id}=      Create Test Movie      base_valid_movie     # Usa o mesmo fixture, mas cria outro filme dinâmico
    ${theater_A_id}=    Create Test Theater    base_valid_theater
    
    # Cria Sessões
    Create Test Session    base_valid_session    ${movie_A_id}    ${theater_A_id}
    
    # Altera o datetime da segunda sessão para ser diferente
    ${session_data_2}=  Get Fixture From Collection    sessions    base_valid_session
    ${session_data_2}=  Set To Dictionary    ${session_data_2}    datetime=2025-12-01T22:00:00.000Z
    # Chama a keyword Python diretamente para a segunda sessão (pois Create Test Session não foi refatorada para aceitar dict)
    ${session_2_id}=    Insert Session Directly Into DB    ${session_data_2}    ${movie_A_id}    ${theater_A_id}
    Append To List    ${SESSION_ID_LIST}    ${session_2_id}
    Set Test Variable    @{SESSION_ID_LIST}

    # Cria sessão do Filme B
    ${session_data_3}=  Get Fixture From Collection    sessions    base_valid_session
    ${session_data_3}=  Set To Dictionary    ${session_data_3}    datetime=2025-12-01T21:00:00.000Z
    ${session_3_id}=    Insert Session Directly Into DB    ${session_data_3}    ${movie_B_id}    ${theater_A_id}
    Append To List    ${SESSION_ID_LIST}    ${session_3_id}
    Set Test Variable    @{SESSION_ID_LIST}

    # Define variáveis para o Teste
    Set Test Variable    ${MOVIE_A_ID}    ${movie_A_id}
    Set Test Variable    ${MOVIE_B_ID}    ${movie_B_id}