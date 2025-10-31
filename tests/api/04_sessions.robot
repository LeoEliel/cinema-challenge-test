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
${SESSION_SCHEMA_LIST}          list_sessions_response.schema.json
${SESSION_SCHEMA_DETAIL}        get_session_details_response.schema.json
${SESSION_NOT_FOUND_SCHEMA}     session_not_found_error.schema.json
${SESSION_CREATE_SCHEMA}        create_session_response.schema.json
${FORBIDDEN_ERROR_SCHEMA}      forbidden_error_response.schema.json
${UNAUTHORIZED_ERROR_SCHEMA}    unauthorized_error_response.schema.json
${SESSION_UPDATE_SCHEMA}        update_session_response.schema.json 


${NON_EXISTENT_SESSION_ID}    111111111111111111111111     # ID que garantidamente não existe
${ADMIN_EMAIL_FIXTURE}        admin@example.com

*** Test Cases ***

CN-92 (API): Buscar detalhes de sessão por ID com sucesso
    [Tags]    API    Smoke    Sessions    US-SESSION-001    CTC-043_API    CN-92
    [Documentation]
    ...              Dado que uma sessão específica existe
    ...              Quando eu envio uma requisição GET para "/sessions/{id_da_sessao}"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter os detalhes completos da sessão
    # Setup específico: Reutiliza o setup que cria 1 Filme, 1 Sala e 1 Sessão
    # Esta keyword define ${CREATED_SESSION_ID}, ${CREATED_MOVIE_ID}, ${CREATED_THEATER_ID}
    [Setup]    Setup Para Teste de Sessão Simples

    # Dado (Given) - ID foi criado no Setup
    Should Not Be Empty    ${CREATED_SESSION_ID}    msg=ID da Sessão não foi criado/definido no Setup.
    Log    Sessão alvo para GET: ${CREATED_SESSION_ID}

    # Ação: Chama a keyword do sessions_service usando o ID obtido
    ${response}=    Get Session By ID    session_id=${CREATED_SESSION_ID}

    # Validação: Usa a keyword de validação padrão (pois a resposta tem wrapper 'success/data')
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${SESSION_SCHEMA_DETAIL}     # Usa o schema de detalhes

    # Validação Extra: Compara campos chave entre a resposta e os dados do setup
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['data']['_id']}         ${CREATED_SESSION_ID}
    Should Be Equal As Strings    ${body['data']['movie']['_id']}       ${CREATED_MOVIE_ID}
    Should Be Equal As Strings    ${body['data']['theater']['_id']}    ${CREATED_THEATER_ID}
CN-34 (API): Listar sessões filtrando por Filme
    [Tags]    API    Filter    Sessions    US-SESSION-001    CTC-013_API    CN-34
    [Documentation]
    ...              Dado que existem sessões para o Filme A e Filme B
    ...              Quando envio GET para "/sessions" filtrando pelo Filme A
    ...              Então a resposta deve ter status 200
    ...              E o corpo da resposta deve conter apenas as sessões do Filme A
    # Setup específico: Usa a sua keyword orquestradora
    [Setup]    Setup Para Teste de Filtro de Sessão

    # Define os query params para buscar APENAS as sessões do Filme A
    ${QUERY_PARAMS}=    Create Dictionary
    ...    movie=${MOVIE_A_ID}    # Filtra pelo ID do Filme A (criado no Setup)
    ...    limit=5

    # Ação
    ${response}=    List Sessions    params=${QUERY_PARAMS}

    # Validação
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${SESSION_SCHEMA_LIST}

    # Validação Extra: Verifica se retornou EXATAMENTE 2 sessões
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['count']}    2     
    ...    msg=A contagem total de sessões para o Filme A deveria ser 2.
    Length Should Be            ${body['data']}    2    msg=A lista 'data' deveria conter 2.

    # Validação profunda: Garante que AMBAS as sessões retornadas são do Filme A
    FOR    ${session}    IN    @{body['data']}
        ${movie_field}=    Run Keyword If    isinstance($session['movie'], dict)
        ...    Set Variable    ${session['movie']['_id']}
        ...    ELSE    Set Variable    ${session['movie']}
        Should Be Equal As Strings    ${movie_field}    ${MOVIE_A_ID}
    END
    Log     Validação concluída: Apenas sessões do Filme A foram retornadas.

CN-93 (API): Buscar detalhes de sessão por ID inexistente (404)
    [Tags]    API    Negative    Sessions    US-SESSION-001    CTC-44    CN-93
    [Documentation]
    ...              Dado que um ID de sessão não existe no sistema
    ...              Quando eu envio uma requisição GET para "/sessions/{id_inexistente}"
    ...              Então a resposta deve ter o status code 404
    ...              E o corpo da resposta deve conter a mensagem "Session not found"
    # Setup: Inicializa as listas de teardown para que o Teardown Completo não falhe
    [Setup]    Run Keywords    
    ...    API Test Setup
    ...    AND
    ...    Initialize Teardown Lists

    # Ação: Chama a keyword do sessions_service usando um ID inexistente
    ${response}=    Get Session By ID    session_id=${NON_EXISTENT_SESSION_ID}

    # Validação: Usa a keyword de validação de erro e o schema 404
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${SESSION_NOT_FOUND_SCHEMA}

CN-94 (API): Admin cria nova sessão com sucesso
    [Tags]    API    AdminOnly    SessionsCRUD    CN-94
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              Quando envio POST para "/sessions" com um payload válido
    ...              Então a resposta deve ter status 201 Created
    # Setup: Cria 1 Filme, 1 Sala E um Token de Admin
    [Setup]    Run Keywords    
    ...    API Test Setup
    ...    AND
    ...    Setup Para Teste de Admin (Sessão)


    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sessão do fixture
    ${session_payload_base}=    Get Fixture From Collection   sessions    base_valid_session
    # Preenche os IDs que foram criados no Setup
    ${payload_final}=    Set To Dictionary    ${session_payload_base}
    ...    movie=${CREATED_MOVIE_ID}
    ...    theater=${CREATED_THEATER_ID}
    
    # Monta os headers com o token de Admin
    &{admin_headers}=      Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sessão
    ${response}=    Create Session    payload=${payload_final}    admin_headers=${admin_headers}

    # --- LOG DE DESCOBERTA ---
    # Loga a resposta real ANTES de tentar validar
    #Log To Console    \n\n--- RESPOSTA REAL (CN-XX POST /sessions) ---\nStatus: ${response.status_code}\nCorpo: ${response.text}\n--------------------------------------\n

    # Validação (TEMPORÁRIA - Apenas Status)
    Should Be Equal As Strings    ${response.status_code}    201

    # Validação do Schema (ESPERAMOS QUE FALHE E MOSTRE O ERRO)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=201
    ...    schema_file=${SESSION_CREATE_SCHEMA}     # Tenta validar contra o schema mockado

    # PREPARA O TEARDOWN (Comentado até o schema ser válido)
    # ${body}=    Set Variable    ${response.json()}
    # ${created_session_id}=    Set Variable    ${body['data']['_id']}
    # Append To List    ${SESSION_ID_LIST}    ${created_session_id}
    # Set Test Variable    @{SESSION_ID_LIST}

CN-95 (API): Tentar criar sessão como usuário normal (Forbidden)
    [Tags]    API    Negative    AdminOnly    SessionsCRUD    CTC-046    CN-95
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e um filme e sala existem
    ...              Quando envio POST para "/sessions" com o token de usuário normal
    ...              Então a resposta deve ter status 403 Forbidden
    # Setup: Cria 1 Filme, 1 Sala E um Token de Usuário Normal
    [Setup]    Setup Para Teste de Permissão (Sessão)

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sessão
    ${session_payload_base}=    Get Fixture From Collection   sessions    base_valid_session
    # Preenche os IDs que foram criados no Setup
    ${payload_final}=    Set To Dictionary    ${session_payload_base}
    ...    movie=${CREATED_MOVIE_ID}
    ...    theater=${CREATED_THEATER_ID}
    
    # Monta os headers com o token de USUÁRIO NORMAL (obtido do Setup)
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${NORMAL_USER_TOKEN_BEARER}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sessão
    ${response}=    Create Session    payload=${payload_final}    admin_headers=${normal_user_headers}

    # Validação: Usa a keyword de validação de erro e o schema 403
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}     # Reutiliza o schema de 403

CN-96 (API): Tentar criar sessão sem autenticação (Unauthorized)
    [Tags]    API    Negative    Security    SessionsCRUD    CTC-047    CN-96
    [Documentation]
    ...              Dado que um filme e uma sala existem
    ...              Quando envio uma requisição POST para "/sessions" sem um token de autenticação
    ...              Então a resposta deve ter o status code 401
    ...              E o corpo da resposta deve conter a mensagem "Not authorized to access this route"
    # Setup: Cria 1 Filme e 1 Sala (mas nenhum token)
    [Setup]    Setup Movie and Theater For Test

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base da sessão
    ${session_payload_base}=    Get Fixture From Collection   sessions    base_valid_session
    # Preenche os IDs que foram criados no Setup
    ${payload_final}=    Set To Dictionary    ${session_payload_base}
    ...    movie=${CREATED_MOVIE_ID}
    ...    theater=${CREATED_THEATER_ID}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta criar a sessão SEM headers (headers=${EMPTY})
    ${response}=    Create Session
    ...    payload=${payload_final}
    ...    admin_headers=${None}     # Envia headers vazios

    # Validação: Usa a keyword de validação de erro e o schema 401
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=401
    ...    schema_file=${UNAUTHORIZED_ERROR_SCHEMA}     # Reutiliza o schema de 401

    # [Teardown]: O 'Teardown Completo' padrão cuidará de limpar
    # o Filme e a Sala criados pelo [Setup].

CN-97 (API): Admin atualiza sessão com sucesso
    [Tags]    API    AdminOnly    SessionsCRUD    CTC-48_API    CN-97
    [Documentation]
    ...              Dado que estou autenticado como Admin e uma sessão existe
    ...              Quando envio PUT para "/sessions/{id_da_sessao}" com dados atualizados
    ...              Então a resposta deve ter status 200 OK
    ...              E o corpo da resposta deve conter os dados da sessão atualizados
    # Setup: Cria 1 Filme, 1 Sala, 1 Sessão E um Token de Admin
    [Setup]    Run Keywords
    ...    Setup Para Teste de Sessão Simples    # Cria as 3 entidades e define ${CREATED_SESSION_ID}, etc.
    ...    AND    Generate Admin Token For Test     # Define ${ADMIN_TOKEN_BEARER}

    # --- PREPARAÇÃO DA AÇÃO ---
    # Define o payload com o novo preço
    ${novo_preco}=         Set Variable    99.99
    &{update_payload}=     Create Dictionary    fullPrice=${novo_preco}
    
    # Monta os headers com o token de Admin
    &{admin_headers}=      Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta atualizar a sessão
    ${response}=    Update Sessions
    ...    session_id=${CREATED_SESSION_ID}
    ...    payload=${update_payload}
    ...    admin_headers=${admin_headers}

    # --- LOG DE DESCOBERTA ---
    # Loga a resposta real ANTES de tentar validar
    Log To Console    \n\n--- RESPOSTA REAL (CN-97 PUT /sessions) ---\nStatus: ${response.status_code}\nCorpo: ${response.text}\n--------------------------------------\n

    # Validação (TEMPORÁRIA - Apenas Status)
    # Esperamos 200 OK
    Should Be Equal As Strings    ${response.status_code}    200

    # Validação do Schema (ESPERAMOS QUE FALHE E MOSTRE O ERRO)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${SESSION_UPDATE_SCHEMA}     # Tenta validar contra o schema mockado

    # PREPARA O TEARDOWN (Comentado até o schema ser válido)
    # ${body}=    Set Variable    ${response.json()}
    # Should Be Equal As Strings    ${body['data']['fullPrice']}    ${novo_preco}

CN-98 (API): Admin tenta atualizar sessão com ID inexistente (404)
    [Tags]    API    Negative    AdminOnly    SessionsCRUD    CTC-049_API    CN-98
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              Quando envio PUT para "/sessions/{id_inexistente}" com dados válidos
    ...              Então a resposta deve ter status 404 Not Found
    ...              E o corpo da resposta deve conter "Session not found"
    # Setup: Gera um token de Admin
    [Setup]    Generate Admin Token For Test

    # Prepara o Teardown: Inicializa listas vazias para o Teardown Completo
    Initialize Teardown Lists

    # --- PREPARAÇÃO DA AÇÃO ---
    # Monta os headers com o token de Admin
    &{admin_headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN_BEARER}
    
    # Prepara um payload de atualização válido (o conteúdo não importa, a API deve falhar no ID)
    ${update_payload}=   Get Fixture From Collection   sessions    base_valid_session
    # (Não precisamos preencher 'movie' ou 'theater' pois a API deve checar o ID da sessão primeiro)
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta atualizar uma sessão usando um ID inexistente
    ${response}=    Update Sessions
    ...    session_id=${NON_EXISTENT_SESSION_ID}
    ...    payload=${update_payload}
    ...    admin_headers=${admin_headers}

    # Validação: Usa a keyword de validação de erro e o schema 404
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${SESSION_NOT_FOUND_SCHEMA}     # Reutiliza o schema de 404

    # [Teardown]: O 'Teardown Completo' padrão rodará, verá as listas vazias
    # (graças ao 'Initialize Teardown Lists') e apenas fechará a sessão HTTP.

CN-99 (API): Tentar atualizar sessão como usuário normal (Forbidden)
    [Tags]    API    Negative    AdminOnly    SessionsCRUD    CTC-050_API    CN-99
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e uma sessão existe
    ...              Quando envio PUT para "/sessions/{id}" com o token de usuário normal
    ...              Então a resposta deve ter status 403 Forbidden
    # Setup: Roda AMBOS os setups:
    # 1. Cria 1 Filme, 1 Sala, 1 Sessão (define ${CREATED_..._ID} e listas de teardown)
    # 2. Cria 1 Usuário Normal (define ${VALID_TOKEN} e ${USER_EMAIL})
    [Setup]    Run Keywords
    ...    Setup Para Teste de Sessão Simples
    ...    AND
    ...    Setup User And Get Valid Token

    # --- PREPARAÇÃO DA AÇÃO ---
    # Monta headers com o token de USUÁRIO NORMAL (obtido do Setup)
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${VALID_TOKEN}
    # Monta um payload de atualização válido (o conteúdo não importa)
    &{update_payload}=    Create Dictionary    fullPrice=1.99
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta atualizar a sessão (ID obtido do Setup)
    ${response}=    Update Sessions
    ...    session_id=${CREATED_SESSION_ID}
    ...    payload=${update_payload}
    ...    admin_headers=${normal_user_headers}     # Passando o token normal

    # Validação: Usa a keyword de validação de erro e o schema 403
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}     # Reutiliza o schema de 403

    # [Teardown]: O 'Teardown Completo' padrão cuidará de limpar
    # as 4 entidades (Sessão, Filme, Sala, Usuário) criadas no [Setup].

CN-100 (API): Tentar atualizar sessão como usuário normal (Forbidden)
    [Tags]    API    Negative    AdminOnly    SessionsCRUD    CTC-051_API    CN-100
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e uma sessão existe
    ...              Quando envio PUT para "/sessions/{id_da_sessao}" com dados atualizados
    ...              Então a resposta deve ter status 403 Forbidden
    # Setup: Cria 1 Filme, 1 Sala, 1 Sessão E um Token de Usuário Normal
    [Setup]    Setup Para Teste de Permissão (Sessão)

    # --- PREPARAÇÃO DA AÇÃO ---
    # Monta os headers com o token de USUÁRIO NORMAL (obtido do setup)
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${NORMAL_USER_TOKEN_BEARER}
    # Monta um payload de atualização válido (o conteúdo não importa)
    &{update_payload}=     Create Dictionary    fullPrice=1.99
    # --- FIM PREPARAÇÃO ---

    # Ação: Tenta atualizar a sessão (ID obtido do setup)
    ${response}=    Update Sessions
    ...    session_id=${CREATED_SESSION_ID}
    ...    payload=${update_payload}
    ...    admin_headers=${normal_user_headers}     # Passando o token normal

    # Validação: Usa a keyword de validação de erro e o schema 403
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}     # Reutiliza o schema de 403

    # [Teardown]: O 'Teardown Completo' padrão cuidará de limpar
    # a Sessão, o Filme, a Sala e o Usuário criados pelo [Setup].


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
    RETURN    ${movie_id}

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
    RETURN    ${theater_id}

Create Test Session
    [Documentation]    Cria 1 Sessão (usando IDs) e prepara para o Teardown. Retorna ID.
    [Arguments]    ${fixture_key}    ${movie_id_str}    ${theater_id_str}
    
    # 1. Carrega o fixture da SESSÃO
    ${session_data}=  Get Fixture From Collection    sessions    ${fixture_key}
    
    # 2. Chama a keyword Python com os IDs corretos (que foram passados pelo Orquestrador)
    ${session_id}=    Insert Session Directly Into DB
    ...    session=${session_data}
    ...    movie_id=${movie_id_str}
    ...    theater_id=${theater_id_str}
    Should Not Be Equal    ${session_id}    ${None}    msg=Falha ao criar Sessão pré-requisito.
    
    # 3. Adiciona à lista de cleanup
    Append To List    ${SESSION_ID_LIST}    ${session_id}
    Set Test Variable    @{SESSION_ID_LIST}
    RETURN    ${session_id}

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

# --- Bloco 3: Keywords Orquestradoras de Setup (Usadas nos Test Cases) ---

Setup Para Teste de Sessão Simples
    [Documentation]    Setup para testes de Sessão. Cria 1 Filme, 1 Sala, 1 Sessão.
    API Test Setup
    Initialize Teardown Lists
    ${movie_id}=      Create Test Movie      base_valid_movie
    ${theater_id}=    Create Test Theater    base_valid_theater
    ${session_id}=    Create Test Session    base_valid_session    ${movie_id}    ${theater_id}
    
    Set Test Variable    ${CREATED_MOVIE_ID}    ${movie_id}
    Set Test Variable    ${CREATED_THEATER_ID}   ${theater_id}
    Set Test Variable    ${CREATED_SESSION_ID}   ${session_id}

Setup Para Teste de Admin (Sessão)
    [Documentation]    Setup para testes de Admin. Cria 1 Filme, 1 Sala, e Token de Admin.
    ...              Define: ${ADMIN_TOKEN_BEARER}, ${CREATED_MOVIE_ID}, ${CREATED_THEATER_ID}
    Initialize Teardown Lists
    
    # 1. Cria Token de Admin (Keyword global)
    Generate Admin Token For Test
    Log    Token de Admin (${ADMIN_TOKEN_BEARER}) gerado.
    
    # 2. Cria Filme (Keyword local)
    ${movie_id}=      Create Test Movie      base_valid_movie
    Set Test Variable    ${CREATED_MOVIE_ID}    ${movie_id}
    
    # 3. Cria Sala (Keyword local)
    ${theater_id}=    Create Test Theater    base_valid_theater
    Set Test Variable    ${CREATED_THEATER_ID}   ${theater_id}
Setup Para Teste de Permissão (Sessão)
    [Documentation]    Setup para testes de permissão (401/403). Cria 1 Filme, 1 Sala, 1 Sessão
    ...              e 1 Usuário Normal com Token.
    ...              Define: ${NORMAL_USER_TOKEN_BEARER}, ${CREATED_SESSION_ID}
    ...              e todas as 4 variáveis de teardown.
    
    API Test Setup
    
    Initialize Teardown Lists
    
    # 1. Cria Token de Usuário Normal (Keyword global de common.resource)
    # (Esta keyword já define ${USER_EMAIL} para o teardown)
    Setup User And Get Valid Token
    Set Test Variable    ${NORMAL_USER_TOKEN_BEARER}    ${VALID_TOKEN}
    
    # 2. Cria Filme (Keyword local de Bloco 2)
    # (Esta keyword já define @{MOVIE_ID_LIST} para o teardown)
    ${movie_id}=      Create Test Movie      base_valid_movie
    
    # 3. Cria Sala (Keyword local de Bloco 2)
    # (Esta keyword já define @{THEATER_ID_LIST} para o teardown)
    ${theater_id}=    Create Test Theater    base_valid_theater
    
    # 4. Cria a Sessão (Keyword local de Bloco 2)
    # (Esta keyword já define @{SESSION_ID_LIST} para o teardown)
    ${session_id}=    Create Test Session    base_valid_session    ${movie_id}    ${theater_id}
    
    # Define variáveis para o Teste
    Set Test Variable    ${CREATED_SESSION_ID}    ${session_id}
    Set Test Variable    ${CREATED_MOVIE_ID}    ${movie_id}
    Set Test Variable    ${CREATED_THEATER_ID}    ${theater_id}
    Log    Setup de permissão completo.

Setup Movie and Theater For Test
    [Documentation]    Setup que cria 1 Filme e 1 Sala.
    ...              Define: ${CREATED_MOVIE_ID}, ${CREATED_THEATER_ID}
    ...              e as variáveis de teardown (@{MOVIE_ID_LIST}, @{THEATER_ID_LIST})
    
    API Test Setup

    Initialize Teardown Lists
    
    # 1. Cria Filme (Keyword local de Bloco 2)
    ${movie_id}=      Create Test Movie      base_valid_movie
    Set Test Variable    ${CREATED_MOVIE_ID}    ${movie_id}
    
    # 2. Cria Sala (Keyword local de Bloco 2)
    ${theater_id}=    Create Test Theater    base_valid_theater
    Set Test Variable    ${CREATED_THEATER_ID}   ${theater_id}

    Log    Setup (Filme/Sala) completo.