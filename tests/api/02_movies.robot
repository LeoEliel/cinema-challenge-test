*** Settings ***
Documentation    Suíte de testes de API para a feature de Filmes (Movies).
...              Cobre casos de teste das US-MOVIE-001 e US-MOVIE-002.

Resource    ../../resources/common.resource

Test Setup       API Test Setup
Test Teardown    API Test Teardown For Movie Collection

*** Variables ***
${MOVIE_FIXTURES}            ../../fixtures/movies.json
${MOVIE_SCHEMA_LIST}         list_movies_response.schema.json
${MOVIE_SCHEMA_DETAIL}       get_movie_details_response.schema.json
${MOVIE_NOT_FOUND_SCHEMA}    movie_not_found_error.schema.json
${MOVIE_CREATE_SCHEMA}       create_movie_response.schema.json     # Nome do novo schema
${NON_EXISTENT_MOVIE_ID}     111111111111111111111111     # Um ObjectId válido, mas garantido (esperamos) que não exista

*** Test Cases ***

CTC-010_API (API): Listar filmes com sucesso (filtrando pelos criados no teste)
    [Tags]    API    Smoke    US-MOVIE-001    CTC-010_API
    [Documentation]
    ...              Dado que filmes específicos foram criados para este teste
    ...              Quando envio uma requisição GET para "/movies" com filtros para esses filmes
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter os filmes criados
    # Setup específico para este teste: cria 3 filmes e define @{MOVIE_ID_LIST} para o Teardown
    [Setup]    Setup Movies For Test    three_base_valid_movies

    # Define os query params para buscar especificamente os filmes criados no setup
    ${QUERY_PARAMS}=    Create Dictionary
    ...    title=Fixture Movie Title Out Of Three         # Busca por parte do título comum
    ...    genre=Three Movies Genre             # Busca pelo gênero comum
    ...    limit=3                              # Limita aos 3 criados
    ...    page=1

    # Ação: Chama a keyword do movies_service para listar filmes com os parâmetros
    ${response}=    List Movies    params=${QUERY_PARAMS}

    # Validação: Usa a keyword de validação e o nome do schema (a keyword deve encontrá-lo)
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=list_movies_response.schema.json         # Nome do schema

    # Validação Extra: Verifica se retornou EXATAMENTE 3 filmes
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['count']}    3    msg=A contagem total deveria ser 3.
    Length Should Be            ${body['data']}    3    msg=A lista 'data' deveria conter 3 filmes.
    Log    Lista de filmes retornada com ${body['count']} itens no total, conforme esperado.

CTC-012_API (API): Buscar detalhes de filme por ID com sucesso
    [Tags]    API    Smoke    US-MOVIE-002    CTC-012_API
    [Documentation]
    ...              Dado que um filme específico foi criado para este teste
    ...              Quando envio uma requisição GET para "/movies/{id_do_filme}"
    ...              Então a resposta deve ter o status code 200
    ...              E o corpo da resposta deve conter os detalhes completos do filme
    # Setup específico para este teste: cria 1 filme e define @{MOVIE_ID_LIST} para o Teardown
    [Setup]    Setup Movies For Test    base_valid_movie

    # Dado (Given) - Filme existe (criado no Setup)
    # Pega o ID do PRIMEIRO (e único) filme criado na lista @{MOVIE_ID_LIST}
    ${movie_id_to_get}=    Set Variable    ${MOVIE_ID_LIST}[0]
    Should Not Be Empty    ${movie_id_to_get}    msg=ID do filme não foi definido/obtido no Setup deste teste.

    # Ação: Chama a keyword do movies_service usando o ID obtido
    ${response}=    Get Movie By ID    movie_id=${movie_id_to_get}

    # Validação: Usa a keyword de validação com o schema de detalhes
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=get_movie_details_response.schema.json

    # Validações Extras de Valores (comparando com o fixture usado no Setup)
    ${fixture_movie_data}=   Get Fixture From Collection   movies    base_valid_movie
    ${body}=                 Set Variable                  ${response.json()}

    Should Be Equal As Strings    ${body['data']['_id']}          ${movie_id_to_get}     # Confirma o ID
    Should Be Equal As Strings    ${body['data']['title']}        ${fixture_movie_data}[title]
    Should Be Equal As Strings    ${body['data']['director']}     ${fixture_movie_data}[director]

CTC-012_NEGATIVE_NOT_FOUND_API (API): Tentar buscar filme com ID inexistente
    [Tags]    API    Negative    US-MOVIE-002    CTC-012_Negative
    [Documentation]
    ...              Dado que um ID de filme não existe no sistema
    ...              Quando envio uma requisição GET para "/movies/{id_inexistente}"
    ...              Então a resposta deve ter o status code 404
    ...              E o corpo da resposta deve conter a mensagem "Movie not found"

    # Sem filmes para apagar definiremos váriavel de lista de Id de Movies como vazia
    @{MOVIE_ID_LIST}=    Create List
    Set Test Variable    @{MOVIE_ID_LIST}

    # Ação: Chama a keyword do movies_service usando um ID inexistente
    ${response}=    Get Movie By ID    movie_id=${NON_EXISTENT_MOVIE_ID}

    # Validação: Usa a keyword de validação de erro e o schema 404
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${MOVIE_NOT_FOUND_SCHEMA}

CTC-040_API (API): Admin cria novo filme com sucesso
    [Tags]    API    Smoke    AdminOnly    MoviesCRUD    CTC-040_API
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              E tenho um payload válido para um novo filme
    ...              Quando envio POST para "/movies" com payload e token de Admin
    ...              Então a resposta deve ter status 201 Created
    ...              E o corpo da resposta deve conter os dados do filme criado

    # --- SETUP: Gera o Token de Admin ---
    ${fixture}    Get Fixture From Collection    users    admin_user_inserted

    Set Test Variable    ${ADMIN_EMAIL_PARA_TESTE}    ${fixture}[email]
    # Garante que o usuário admin existe (OPCIONAL, mas bom)
    ${admin_id}=    Get User Id by Email    ${ADMIN_EMAIL_PARA_TESTE}
    Should Not Be Equal    ${admin_id}    ${None}    msg=Usuário admin ${ADMIN_EMAIL_PARA_TESTE} não encontrado no DB.

    # Gera o token usando a keyword
    ${admin_token_bearer}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_PARA_TESTE}
    Log    Token de Admin gerado para o teste: ${admin_token_bearer}
    # Monta os headers para a requisição
    &{admin_headers}=       Create Dictionary    Authorization=${admin_token_bearer}
    # --- FIM SETUP ---

    # --- PREPARAÇÃO DA AÇÃO ---
    # Carrega o payload base do filme do fixture
    ${movie_payload}=    Get Fixture From Collection   movies    base_valid_movie
    # Define variável para cleanup (mesmo que a criação falhe, tentaremos limpar pelo título)
    Set Test Variable      @{MOVIE_ID_LIST}     @{EMPTY}     # Inicializa a lista de IDs a limpar
    Set Test Variable      ${MOVIE_TITLE_TO_CLEAN}  ${movie_payload}[title]     # Guarda o título para cleanup via DB se necessário

    # --- AÇÃO: Tenta criar o filme ---
    ${response}=    Create Movie    payload=${movie_payload}    admin_headers=${admin_headers}

    # --- VALIDAÇÃO ---
    # Verifica se a API aceitou o token e criou o filme (Status 201)
    Should Be Equal As Strings    ${response.status_code}    201    msg=Falha ao criar filme. A API não aceitou o token ou houve outro erro. Resposta: ${response.text}

    # Se chegou aqui, o token foi aceito!
    Log    SUCESSO! O token de Admin gerado foi aceito pela API (POST /movies retornou 201).

    # Validação adicional (opcional): Schema da resposta
    Validate Successful API Response    ${response}    201    ${MOVIE_CREATE_SCHEMA}

    # Guarda o ID do filme criado para o Teardown padrão limpar
    ${body}=    Set Variable    ${response.json()}
    ${created_movie_id}=    Set Variable    ${body}[data][_id]
    Append To List    ${MOVIE_ID_LIST}    ${created_movie_id}
    Set Test Variable    @{MOVIE_ID_LIST}

    # Validação Extra de Valores: Compara dados enviados com dados retornados
    Should Be Equal As Strings    ${body['data']['title']}        ${movie_payload}[title]
    Should Be Equal As Strings    ${body['data']['director']}     ${movie_payload}[director]
    Should Be Equal As Strings    ${body['data']['synopsis']}     ${movie_payload}[synopsis]
    Should Be Equal As Strings    ${body['data']['duration']}     ${movie_payload}[duration]
    Should Be Equal As Strings    ${body['data']['genres']}        ${movie_payload}[genres]
    # Adicione mais comparações de campos se desejar (synopsis, duration, genres...)