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
${MOVIE_CREATE_SCHEMA}       create_movie_response.schema.json
${MOVIE_UPDATE_SCHEMA}       update_movie_response.schema.json
${MOVIE_DELETE_SCHEMA}       delete_movie_response.schema.json
${FORBIDDEN_ERROR_SCHEMA}    forbidden_error_response.schema.json
${ADMIN_EMAIL_FIXTURE}       admin@example.com
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
    [Tags]    API    Smoke    AdminOnly    MoviesCRUD    CTC-040_API    CN-84
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

CTC-041_API (API): Admin atualiza filme existente com sucesso
    [Tags]    API    AdminOnly    MoviesCRUD    CTC-041_API    CN-85
    [Documentation]
    ...              Dado que estou autenticado como Admin e um filme existe
    ...              Quando envio PUT para "/movies/{id}" com dados atualizados
    ...              Então a resposta deve ter status 200 OK
    ...              E o corpo da resposta deve conter os dados do filme atualizados
    # [Setup] REMOVIDO

    # --- SETUP INLINE ---
    # 1. Gera Token de Admin
    ${admin_fixture}=    Get Fixture From Collection    users    admin_user_inserted
    ${admin_email}=      Set Variable                   ${admin_fixture}[email]
    ${admin_id_check}=   Get User Id by Email           ${admin_email}
    Should Not Be Equal    ${admin_id_check}    ${None}    msg=Usuário admin ${admin_email} não encontrado no DB.
    ${admin_token_bearer}=    Generate Admin Token    admin_email=${admin_email}
    Log    Token de Admin gerado para o teste: ${admin_token_bearer}
    &{admin_headers}=         Create Dictionary    Authorization=${admin_token_bearer}

    # 2. Cria Filme pré-requisito
    ${fixture_movie_data}=    Get Fixture From Collection   movies    base_valid_movie
    # Define variáveis para cleanup (lista e título)
    Set Test Variable      @{MOVIE_ID_LIST}     @{EMPTY}
    Set Test Variable      ${MOVIE_TITLE_TO_CLEAN}  ${fixture_movie_data}[title]
    # Garante limpeza prévia
    ${existing_id}=   Get Movie Id By Title    ${fixture_movie_data}[title]
    Run Keyword If    '${existing_id}' != '${None}'    Remove Movie And Related Data    ${existing_id}
    # Insere o filme via DB
    ${movie_id_to_update}=    Insert Movie Directly Into DB    ${fixture_movie_data}
    Should Not Be Equal    ${movie_id_to_update}    ${None}    msg=Falha ao inserir filme pré-requisito no DB
    Log    Filme pré-requisito '${fixture_movie_data}[title]' inserido com ID ${movie_id_to_update}
    # Adiciona o ID à lista para o Teardown padrão limpar
    Append To List    ${MOVIE_ID_LIST}    ${movie_id_to_update}
    Set Test Variable    @{MOVIE_ID_LIST}
    # --- FIM SETUP INLINE ---

    # --- PREPARAÇÃO DA AÇÃO ---
    # Define o payload com os dados de ATUALIZAÇÃO
    ${novo_titulo}=    FakerLibrary.Catch Phrase
    ${nova_sinopse}=   FakerLibrary.Catch Phrase
    &{update_payload}=    Create Dictionary
    ...    title=${novo_titulo}
    ...    synopsis=${nova_sinopse}
    # --- FIM PREPARAÇÃO ---

    # Ação: Chama a keyword (corrigida) do service
    ${response}=    Update Movie
    ...    movie_id=${movie_id_to_update}     # Usa o ID criado no Setup Inline
    ...    payload=${update_payload}
    ...    admin_headers=${admin_headers}

    # Validação Principal: Status 200 e Schema
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${MOVIE_UPDATE_SCHEMA}

    # Validação Extra: Verifica se os dados foram realmente atualizados
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Strings    ${body['data']['title']}        ${novo_titulo}
    Should Be Equal As Strings    ${body['data']['synopsis']}     ${nova_sinopse}
    # Confirma que o ID não mudou
    Should Be Equal As Strings    ${body['data']['_id']}          ${movie_id_to_update}

CTC-041_API (API): Admin deleta filme existente com sucesso
    [Tags]    API    AdminOnly    MoviesCRUD    CN-86    US-MOVIE-Admin # Tag para a US de admin de filmes
    [Documentation]
    ...              Dado que estou autenticado como Admin e um filme existe
    ...              Quando envio DELETE para "/movies/{id}" com token de Admin
    ...              Então a resposta deve ter status 200 OK
    ...              E o corpo da resposta deve ser "Movie removed"
    ...              E o filme não deve mais ser encontrado (404)
    # Setup: Cria um filme (${CREATED_MOVIE_ID_FOR_TEST})
    # E gera um token de Admin (${ADMIN_TOKEN_BEARER})
    [Setup]    Setup Movies For Test    base_valid_movie

    # --- PREPARAÇÃO DA AÇÃO ---
    # Headers de Admin e ID do filme já estão disponíveis do [Setup]
    &{admin_headers}=    Create Dictionary    Authorization=${GENERATED_ADMIN_TOKEN_FOR_DEBUG}
    ${movie_id_string}=    Convert To String    ${MOVIE_ID_LIST}[0]
    Log    Filme a ser deletado: ${movie_id_string}    INFO
    # --- FIM PREPARAÇÃO ---

    # --- AÇÃO: Deleta o filme ---
    # Chama a keyword (corrigida) do service
    ${response}=    Delete Movie
    ...    movie_id=${movie_id_string}
    ...    admin_headers=${admin_headers}

    # --- VALIDAÇÃO (PARTE 1): Resposta do DELETE ---
    # Valida se o status é 200 (OK) e o schema/mensagem estão corretos
    Validate Successful API Response
    ...    response=${response}
    ...    expected_status_code=200
    ...    schema_file=${MOVIE_DELETE_SCHEMA}

    # --- VALIDAÇÃO (PARTE 2): Verifica se o filme FOI deletado ---
    Log    Validando se o filme ${movie_id_string} foi realmente deletado...    INFO
    # Tenta buscar o filme que acabou de ser deletado
    ${response_after}=    Get Movie By ID    movie_id=${movie_id_string}

    # Valida se a resposta agora é 404 Not Found
    Validate Error API Response
    ...    response=${response_after}
    ...    expected_status_code=404
    ...    schema_file=${MOVIE_NOT_FOUND_SCHEMA}

    # --- LIMPEZA ---
    # Limpa a variável @{movie_id_string} para que o Teardown padrão não tente deletar de novo
    # (O Teardown ainda fechará a sessão HTTP)
    @{empty_list}=    Create List
    Set Test Variable    @{MOVIE_ID_LIST}    @{empty_list}
    Log    ID do filme removido da lista de cleanup do Teardown.

CTC-042_NEGATIVE_NOT_FOUND_API (API): Admin tenta deletar filme com ID inexistente
    [Tags]    API    Negative    AdminOnly    MoviesCRUD    CTC-042_Negative    CN-87
    [Documentation]
    ...              Dado que estou autenticado como Admin
    ...              Quando envio DELETE para "/movies/{id_inexistente}"
    ...              Então a resposta deve ter status 404 Not Found
    ...              E o corpo da resposta deve estar vazio
    # Setup: Gera um token de Admin
    ${admin_token_bearer}=    Generate Admin Token    admin_email=${ADMIN_EMAIL_FIXTURE}

    # Cria uma lista vazia para a variável de teardown
    # (Necessário para o 'API Test Teardown For Movie Collection' rodar sem erros)
    @{MOVIE_ID_LIST}=    Create List
    Set Test Variable    @{MOVIE_ID_LIST}

    # Monta os headers com o token de Admin obtido no Setup
    &{admin_headers}=    Create Dictionary    Authorization=${admin_token_bearer}

    # Ação: Tenta deletar um filme usando um ID inexistente
    ${response}=    Delete Movie
    ...    movie_id=${NON_EXISTENT_MOVIE_ID}
    ...    admin_headers=${admin_headers}
    
    # Validação: Usa a keyword padrão 'Validate Error API Response'
    # Reutiliza o schema 'movie_not_found_error.schema.json'
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=404
    ...    schema_file=${MOVIE_NOT_FOUND_SCHEMA}     # Valida a estrutura E a mensagem via schema

CTC-043_API (API): Tentar deletar filme como usuário normal (Forbidden)
    [Tags]    API    Negative    AdminOnly    MoviesCRUD    CTC-043_Negative # Adicione ID Jira
    [Documentation]
    ...              Dado que estou autenticado como usuário NORMAL e um filme existe
    ...              Quando envio DELETE para "/movies/{id}" com token de usuário normal
    ...              Então a resposta deve ter status 403 Forbidden
    
    [Setup]
        Run Keywords
        ...    API Test Setup
        ...  AND
        ...    Setup User And Get Valid Token
        ...  AND
        ...  Setup Movies For Test    base_valid_movie 
    
    # Monta headers com o token de USUÁRIO NORMAL (obtido do setup)
    &{normal_user_headers}=    Create Dictionary    Authorization=Bearer ${VALID_TOKEN}

    # Ação: Tenta deletar o filme usando o token de usuário normal
    ${response}=    Delete Movie
    ...    movie_id=${MOVIE_ID_LIST}
    ...    admin_headers=${normal_user_headers}     # Passando o token normal

    # Validação (ESPERAMOS QUE FALHE AQUI E MOSTRE O ERRO REAL)
    # Tenta validar contra o schema mockado
    Validate Error API Response
    ...    response=${response}
    ...    expected_status_code=403
    ...    schema_file=${FORBIDDEN_ERROR_SCHEMA}
    
    [Teardown]
    Run Keywords
    ...    API Test Teardown For User Collection
    ...  AND
    ...    API Test Teardown For Movie Collection